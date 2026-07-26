-- =====================================================================
-- MUBASHER FUND SUPPORTER - Complete Supabase Database Schema & Seed
-- Run this in Supabase SQL Editor (https://app.supabase.com -> SQL Editor)
-- =====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Clean drop of existing tables to avoid column mismatch errors from older runs
DROP TABLE IF EXISTS public.wishlist CASCADE;
DROP TABLE IF EXISTS public.portfolio_transactions CASCADE;
DROP TABLE IF EXISTS public.portfolio_items CASCADE;
DROP TABLE IF EXISTS public.portfolios CASCADE;
DROP TABLE IF EXISTS public.funds CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- =====================================================================
-- 1. FUNDS TABLE (Investment Funds Data)
-- Supports all app repository query variants and full EIMA report data
-- =====================================================================
CREATE TABLE public.funds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_ar TEXT,
    name_en TEXT,
    manager_name TEXT NOT NULL DEFAULT 'مباشر كابيتال',
    manager TEXT DEFAULT 'مباشر كابيتال',
    description_ar TEXT,
    description_en TEXT,
    inception_date TEXT,
    initial_value NUMERIC(12, 4) DEFAULT 100.0000,
    current_nav NUMERIC(12, 4) NOT NULL DEFAULT 100.0000,
    nav_date TEXT DEFAULT '09/07/26',
    
    -- Returns (%)
    weekly_return NUMERIC(8, 2) DEFAULT 0.00,
    four_weeks_return NUMERIC(8, 2) DEFAULT 0.00,
    ytd_return NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    last_12m_return NUMERIC(8, 2) DEFAULT 0.00,
    return_2y NUMERIC(8, 2) DEFAULT 0.00,
    return_3y NUMERIC(8, 2) DEFAULT 0.00,
    return_4y NUMERIC(8, 2) DEFAULT 0.00,
    return_5y NUMERIC(8, 2) DEFAULT 0.00,
    return_6y NUMERIC(8, 2) DEFAULT 0.00,
    daily_change NUMERIC(8, 2) NOT NULL DEFAULT 0.00,

    -- Rankings
    weekly_rank INTEGER,
    four_weeks_rank INTEGER,
    ytd_rank INTEGER,
    last_12m_rank INTEGER,
    rank_2y INTEGER,
    rank_3y INTEGER,
    rank_4y INTEGER,
    rank_5y INTEGER,
    rank_6y INTEGER,
    rank INTEGER,

    -- Metadata
    currency TEXT NOT NULL DEFAULT 'EGP',
    risk_level TEXT NOT NULL DEFAULT 'Medium' CHECK (risk_level IN ('Low', 'Medium', 'High')),
    category TEXT NOT NULL DEFAULT 'Equity',
    sub_category TEXT,
    fund_type TEXT DEFAULT 'Equity',
    logo_url TEXT,
    is_recommended BOOLEAN DEFAULT false,
    is_top_performing BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies for Funds
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to funds" ON public.funds FOR SELECT USING (true);
CREATE POLICY "Allow public all access to funds" ON public.funds FOR ALL USING (true);

-- =====================================================================
-- 2. USER PROFILES TABLE
-- =====================================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    phone_number TEXT,
    risk_tolerance TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies for Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow users to view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow users to update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Allow users to insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- =====================================================================
-- 3. PORTFOLIOS TABLE (User Portfolios)
-- =====================================================================
CREATE TABLE public.portfolios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'محفظتي الاستثمارية',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies for Portfolios
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow users access to their own portfolios" ON public.portfolios FOR ALL USING (auth.uid() = user_id);

-- =====================================================================
-- 4. PORTFOLIO ITEMS TABLE (Assets inside Portfolio)
-- =====================================================================
CREATE TABLE public.portfolio_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    portfolio_id UUID NOT NULL REFERENCES public.portfolios(id) ON DELETE CASCADE,
    fund_id UUID REFERENCES public.funds(id) ON DELETE SET NULL,
    fund_name TEXT NOT NULL,
    category TEXT NOT NULL,
    units NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    purchase_price NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    current_nav NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies for Portfolio Items
ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow users to manage portfolio items" ON public.portfolio_items FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE public.portfolios.id = public.portfolio_items.portfolio_id
        AND public.portfolios.user_id = auth.uid()
    )
);

-- =====================================================================
-- 5. PORTFOLIO TRANSACTIONS TABLE
-- =====================================================================
CREATE TABLE public.portfolio_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id UUID NOT NULL REFERENCES public.funds(id) ON DELETE CASCADE,
    units NUMERIC(14, 4) NOT NULL,
    purchase_price NUMERIC(12, 4) NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies for Portfolio Transactions
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow users to view own transactions" ON public.portfolio_transactions FOR ALL USING (auth.uid() = user_id);

-- =====================================================================
-- 6. WISHLIST TABLE (Saved Funds)
-- =====================================================================
CREATE TABLE public.wishlist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id UUID NOT NULL REFERENCES public.funds(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, fund_id)
);

-- RLS Policies for Wishlist
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow users to manage wishlist" ON public.wishlist FOR ALL USING (auth.uid() = user_id);

-- =====================================================================
-- 7. AUTOMATIC PROFILE CREATION TRIGGER ON SIGN UP
-- =====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

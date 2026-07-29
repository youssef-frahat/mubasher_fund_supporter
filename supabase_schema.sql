-- =====================================================================
-- MUBASHER FUND SUPPORTER - MASTER SUPABASE DATABASE FIX & MIGRATION SCRIPT
-- Run this in Supabase SQL Editor (https://app.supabase.com -> SQL Editor)
-- =====================================================================

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- 2. CREATE / ALTER PROFILES TABLE (With all required fields)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    phone_number TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT true,
    risk_tolerance TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Ensure all columns exist even if profiles table was created earlier
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT true;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS risk_tolerance TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());

-- =====================================================================
-- 3. CREATE / ALTER PORTFOLIOS TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.portfolios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'محفظتي الاستثمارية',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 4. CREATE / ALTER PORTFOLIO ITEMS TABLE
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.portfolio_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    portfolio_id UUID NOT NULL REFERENCES public.portfolios(id) ON DELETE CASCADE,
    fund_id TEXT,
    fund_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'عام',
    units NUMERIC(15, 4) NOT NULL DEFAULT 0.0000,
    purchase_price NUMERIC(15, 4) NOT NULL DEFAULT 0.0000,
    current_nav NUMERIC(15, 4) NOT NULL DEFAULT 0.0000,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS fund_id TEXT;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS fund_name TEXT;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'عام';
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS units NUMERIC(15, 4) DEFAULT 0;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS purchase_price NUMERIC(15, 4) DEFAULT 0;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS current_nav NUMERIC(15, 4) DEFAULT 0;

-- =====================================================================
-- 5. CREATE / ALTER TRANSACTIONS & WISHLIST TABLES
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.portfolio_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id TEXT NOT NULL,
    units NUMERIC(15, 4) NOT NULL,
    purchase_price NUMERIC(15, 4) NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.wishlist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, fund_id)
);

-- =====================================================================
-- 6. DISABLE STRICT RLS / ADD UNRESTRICTED PERMISSIONS FOR ADMIN & APP
-- =====================================================================

-- Profiles RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Profiles" ON public.profiles;
CREATE POLICY "Allow_All_Profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

-- Portfolios RLS Policies
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolios" ON public.portfolios;
CREATE POLICY "Allow_All_Portfolios" ON public.portfolios FOR ALL USING (true) WITH CHECK (true);

-- Portfolio Items RLS Policies
ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolio_Items" ON public.portfolio_items;
CREATE POLICY "Allow_All_Portfolio_Items" ON public.portfolio_items FOR ALL USING (true) WITH CHECK (true);

-- Transactions RLS Policies
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Transactions" ON public.portfolio_transactions;
CREATE POLICY "Allow_All_Transactions" ON public.portfolio_transactions FOR ALL USING (true) WITH CHECK (true);

-- Wishlist RLS Policies
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Wishlist" ON public.wishlist;
CREATE POLICY "Allow_All_Wishlist" ON public.wishlist FOR ALL USING (true) WITH CHECK (true);

-- Grant privileges to anon and authenticated roles
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- =====================================================================
-- 7. SAFE AUTOMATIC PROFILE AND DEFAULT PORTFOLIO TRIGGER ON SIGN UP
-- =====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- 1. Create or Update Profile seamlessly
  INSERT INTO public.profiles (id, full_name, phone, phone_number, email, avatar_url, is_verified)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, new.email),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, new.email),
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    phone_number = EXCLUDED.phone_number,
    avatar_url = EXCLUDED.avatar_url,
    updated_at = timezone('utc'::text, now());

  -- 2. Automatically Create Default Portfolio for New User (if none exists)
  IF NOT EXISTS (SELECT 1 FROM public.portfolios WHERE user_id = new.id) THEN
    INSERT INTO public.portfolios (id, user_id, name)
    VALUES (
      uuid_generate_v4(),
      new.id,
      'المحفظة الرئيسية'
    );
  END IF;

  RETURN new;
EXCEPTION
  WHEN OTHERS THEN
    -- Prevent trigger failure from blocking Auth Sign Up
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply Trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

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

-- In-App Transactions Sheet Log (Used by fund_transaction_history_sheet)
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_name TEXT NOT NULL,
    category TEXT,
    type TEXT NOT NULL DEFAULT 'BUY',
    units NUMERIC(14, 4) NOT NULL DEFAULT 0,
    purchase_price NUMERIC(12, 4) NOT NULL DEFAULT 0,
    current_nav NUMERIC(12, 4),
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
-- 5.1. CREATE FUND NAV HISTORY TABLE (Real Technical Financial Chart Prices)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.fund_nav_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fund_id TEXT NOT NULL,
    nav NUMERIC(15, 4) NOT NULL,
    recorded_date DATE NOT NULL,
    daily_change NUMERIC(7, 4) DEFAULT 0.0000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(fund_id, recorded_date)
);
CREATE INDEX IF NOT EXISTS idx_fund_nav_history_lookup ON public.fund_nav_history(fund_id, recorded_date DESC);

-- =====================================================================
-- 6. ROBO-ADVISOR CONFIGURATIONS TABLE (Custom Admin Recommendations per Goal)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.robo_advisor_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_key TEXT NOT NULL UNIQUE,
    goal_title_ar TEXT NOT NULL,
    expected_roi NUMERIC(5, 2) NOT NULL DEFAULT 25.00,
    description_ar TEXT,
    fund1_name TEXT NOT NULL,
    fund1_category_ar TEXT NOT NULL DEFAULT 'صناديق الذهب',
    fund1_percentage NUMERIC(5, 2) NOT NULL DEFAULT 50.00,
    fund1_badge_ar TEXT DEFAULT 'الملاذ الأول',
    fund2_name TEXT NOT NULL,
    fund2_category_ar TEXT NOT NULL DEFAULT 'معادن ومسبوكات',
    fund2_percentage NUMERIC(5, 2) NOT NULL DEFAULT 30.00,
    fund2_badge_ar TEXT DEFAULT 'نمو مرتفع',
    fund3_name TEXT NOT NULL,
    fund3_category_ar TEXT NOT NULL DEFAULT 'أدوات مركبة ومشتقات',
    fund3_percentage NUMERIC(5, 2) NOT NULL DEFAULT 20.00,
    fund3_badge_ar TEXT DEFAULT 'فرص مضاعفة',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 7. PRODUCTION HARDENED ROLE-BASED ACCESS CONTROL (RBAC) & RLS
-- =====================================================================

-- Role Enum Definition
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM ('super_admin', 'admin', 'compliance_auditor', 'support_agent', 'investor');
    END IF;
END $$;

-- Normalized user roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.app_role NOT NULL DEFAULT 'investor',
    assigned_by UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_role UNIQUE (user_id, role)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- Security Definer Role Checker
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- User Roles Table Security
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_Read_Own_Role" ON public.user_roles;
DROP POLICY IF EXISTS "Super_Admin_Manage_Roles" ON public.user_roles;

CREATE POLICY "Allow_Read_Own_Role" ON public.user_roles
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Super_Admin_Manage_Roles" ON public.user_roles
FOR ALL USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());

-- Profiles RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow_Read_Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users_Insert_Own_Profile" ON public.profiles;
DROP POLICY IF EXISTS "Users_Update_Own_Profile" ON public.profiles;

CREATE POLICY "Allow_Read_Profiles" ON public.profiles
FOR SELECT USING (true);

CREATE POLICY "Users_Insert_Own_Profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users_Update_Own_Profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Portfolios RLS Policies
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users_Manage_Own_Portfolios" ON public.portfolios;

CREATE POLICY "Users_Manage_Own_Portfolios" ON public.portfolios
FOR ALL USING (
    auth.uid() = user_id OR public.is_admin()
) WITH CHECK (
    auth.uid() = user_id OR public.is_admin()
);

-- Portfolio Items RLS Policies
ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolio_Items" ON public.portfolio_items;
DROP POLICY IF EXISTS "Users_Manage_Own_Portfolio_Items" ON public.portfolio_items;

CREATE POLICY "Users_Manage_Own_Portfolio_Items" ON public.portfolio_items
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_items.portfolio_id
        AND (portfolios.user_id = auth.uid() OR public.is_admin())
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_items.portfolio_id
        AND (portfolios.user_id = auth.uid() OR public.is_admin())
    )
);

-- Transactions RLS Policies
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Transactions" ON public.portfolio_transactions;
DROP POLICY IF EXISTS "Users_Manage_Own_Transactions" ON public.portfolio_transactions;

CREATE POLICY "Users_Manage_Own_Transactions" ON public.portfolio_transactions
FOR ALL USING (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_transactions.portfolio_id
        AND (portfolios.user_id = auth.uid() OR public.is_admin())
    )
) WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_transactions.portfolio_id
        AND (portfolios.user_id = auth.uid() OR public.is_admin())
    )
);

-- Wishlist RLS Policies
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Users_Manage_Own_Wishlist" ON public.wishlist;

CREATE POLICY "Users_Manage_Own_Wishlist" ON public.wishlist
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Transactions Sheet RLS Policies
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Transactions_Sheet" ON public.transactions;
DROP POLICY IF EXISTS "Users_Manage_Own_Transactions_Sheet" ON public.transactions;

CREATE POLICY "Users_Manage_Own_Transactions_Sheet" ON public.transactions
FOR ALL USING (auth.uid() = user_id OR public.is_admin()) WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Robo Advisor Configs RLS Policies
ALTER TABLE public.robo_advisor_configs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Robo_Configs" ON public.robo_advisor_configs;
DROP POLICY IF EXISTS "Allow_Read_Robo_Configs" ON public.robo_advisor_configs;

CREATE POLICY "Allow_Read_Robo_Configs" ON public.robo_advisor_configs
FOR SELECT USING (true);

-- Grant privileges to anon and authenticated roles
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON public.portfolios, public.portfolio_items, public.portfolio_transactions, public.transactions, public.wishlist, public.profiles TO authenticated;

-- Seed Initial Default Recommendations into robo_advisor_configs
INSERT INTO public.robo_advisor_configs (
    goal_key, goal_title_ar, expected_roi, description_ar,
    fund1_name, fund1_category_ar, fund1_percentage, fund1_badge_ar,
    fund2_name, fund2_category_ar, fund2_percentage, fund2_badge_ar,
    fund3_name, fund3_category_ar, fund3_percentage, fund3_badge_ar
) VALUES 
(
    'goldHedging', 'تحوط وحماية رأس المال (الذهب والفضة)', 27.50,
    'محفظة مخصصة لحماية الأموال من موجات التضخم وانخفاض العملة.',
    'صندوق أزموت الذهب (Azimut Gold)', 'صناديق الذهب', 50.00, 'الملاذ الآمن الأول',
    'صندوق إي جولد لسبائك الذهب', 'معادن ومسبوكات', 30.00, 'نمو مرتفع',
    'صندوق بلتون للنمو الاستثماري', 'أدوات مركبة ومشتقات', 20.00, 'فرص مضاعفة'
),
(
    'islamicSharia', 'استثمار متوافق مع الشريعة الإسلامية', 24.00,
    'محفظة نموذجية إسلامية 100% موزعة بين المرابحة النقدية والأسهم النقية.',
    'صندوق فيصل الإسلامي للأسهم', 'أسهم شريعة', 45.00, 'نمو شرعي',
    'صندوق البركة الإسلامي اليومي', 'سيولة مرابحة', 35.00, 'أمان واستقرار',
    'صندوق الذهب أزموت الإسلامي', 'تحوط ذهبي', 20.00, 'حفظ القوة الشرائية'
),
(
    'capitalPreservation', 'أمان مرتفع وحفظ رأس المال', 22.00,
    'محفظة عالية الأمان تركز على العائد اليومي التراكمي وأذون الخزانة.',
    'صندوق البنك الأهلي الرابع اليومي', 'سيولة نقدية', 60.00, 'عائد يومي آمن',
    'صندوق أذون الخزانة المصرية', 'أدوات حكومية', 25.00, 'ضمان حكومي',
    'صندوق الذهب أزموت', 'تحوط ذهبي', 15.00, 'حفظ القوة الشرائية'
),
(
    'balancedGrowth', 'نمو متوازن (المحفظة الذكية النموذجية)', 26.50,
    'محفظة متوازنة تجمع بين أمان السيولة، نمو الأسهم، وتحوط الذهب.',
    'صندوق مباشر اليومي للسيولة', 'سيولة وتوفير', 40.00, 'أمان وسحب فوري',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ضد التضخم', 30.00, 'استقرار الأصول',
    'صندوق سي أي كابيتال للأسهم', 'أسهم ومستقبل', 30.00, 'نمو رأس المال'
)
ON CONFLICT (goal_key) DO UPDATE SET
    fund1_name = EXCLUDED.fund1_name,
    fund2_name = EXCLUDED.fund2_name,
    fund3_name = EXCLUDED.fund3_name,
    expected_roi = EXCLUDED.expected_roi,
    updated_at = timezone('utc'::text, now());

-- =====================================================================
-- 8. SAFE AUTOMATIC PROFILE AND DEFAULT PORTFOLIO TRIGGER ON SIGN UP
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

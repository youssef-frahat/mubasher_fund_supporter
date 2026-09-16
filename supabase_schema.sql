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
    goal_key TEXT NOT NULL,
    duration_key TEXT NOT NULL DEFAULT 'mediumTerm',
    goal_title_ar TEXT NOT NULL,
    goal_title_en TEXT,
    expected_roi NUMERIC(5, 2) NOT NULL DEFAULT 25.00,
    description_ar TEXT,
    description_en TEXT,
    fund1_name TEXT,
    fund1_category_ar TEXT DEFAULT 'صناديق الذهب',
    fund1_percentage NUMERIC(5, 2) DEFAULT 50.00,
    fund1_badge_ar TEXT DEFAULT 'الملاذ الأول',
    fund2_name TEXT,
    fund2_category_ar TEXT DEFAULT 'معادن ومسبوكات',
    fund2_percentage NUMERIC(5, 2) DEFAULT 30.00,
    fund2_badge_ar TEXT DEFAULT 'نمو مرتفع',
    fund3_name TEXT,
    fund3_category_ar TEXT DEFAULT 'أدوات مركبة ومشتقات',
    fund3_percentage NUMERIC(5, 2) DEFAULT 20.00,
    fund3_badge_ar TEXT DEFAULT 'فرص مضاعفة',
    fund4_name TEXT,
    fund4_category_ar TEXT,
    fund4_percentage NUMERIC(5, 2),
    fund4_badge_ar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT robo_advisor_configs_goal_duration_unique UNIQUE (goal_key, duration_key)
);

ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS duration_key TEXT NOT NULL DEFAULT 'mediumTerm';
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS goal_title_en TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS description_en TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_name TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_category_ar TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_percentage NUMERIC(5, 2);
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_badge_ar TEXT;

ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund1_name DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund1_category_ar DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund1_percentage DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund2_name DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund2_category_ar DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund2_percentage DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund3_name DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund3_category_ar DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund3_percentage DROP NOT NULL;

DO $$
BEGIN
    ALTER TABLE public.robo_advisor_configs DROP CONSTRAINT IF EXISTS robo_advisor_configs_goal_key_key;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'robo_advisor_configs_goal_duration_unique'
    ) THEN
        ALTER TABLE public.robo_advisor_configs ADD CONSTRAINT robo_advisor_configs_goal_duration_unique UNIQUE (goal_key, duration_key);
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

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

-- Seed Initial Default Recommendations into robo_advisor_configs (15 Duration-Aware Combos)
INSERT INTO public.robo_advisor_configs (
    goal_key, duration_key, goal_title_ar, goal_title_en, expected_roi, 
    description_ar, description_en,
    fund1_name, fund1_category_ar, fund1_percentage, fund1_badge_ar,
    fund2_name, fund2_category_ar, fund2_percentage, fund2_badge_ar,
    fund3_name, fund3_category_ar, fund3_percentage, fund3_badge_ar,
    fund4_name, fund4_category_ar, fund4_percentage, fund4_badge_ar
) VALUES 
-- 🪙 goldHedging × 3 durations
(
    'goldHedging', 'shortTerm',
    'تحوط بالذهب والمعادن الثمينة (قصير الأجل)',
    'Gold & Precious Metals Hedge (Short Term)',
    22.00,
    'محفظة مخصصة 100% لصناديق الذهب والسبائك المضمونة — حماية فورية ضد تقلبات العملة والتضخم.',
    '100% gold & bullion portfolio for immediate currency and inflation hedging.',
    'صندوق أزموت الذهب (Azimut Gold)', 'صناديق الذهب المباشرة', 70.00, 'ذهب نقي 24 قيراط 🪙',
    'صندوق إي جولد لسبائك الذهب', 'سبائك ومعادن ثمينة', 30.00, 'سبائك مضمونة 🪙',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL
),
(
    'goldHedging', 'mediumTerm',
    'تحوط بالذهب والمعادن الثمينة (متوسط الأجل)',
    'Gold & Precious Metals Hedge (Medium Term)',
    26.00,
    'استثمار متين في صناديق الذهب والمعادن الثمينة — تنويع بين صناديق الذهب المباشرة وسبائك المعادن.',
    'Robust gold & precious metals investment diversified across gold funds and bullion.',
    'صندوق أزموت الذهب (Azimut Gold)', 'صناديق الذهب', 60.00, 'الملاذ الآمن الأول 🪙',
    'صندوق إي جولد لسبائك الذهب والمعادن', 'معادن ومسبوكات', 40.00, 'نمو المعادن الثمينة 🪙',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL
),
(
    'goldHedging', 'longTerm',
    'تحوط بالذهب والمعادن الثمينة (طويل الأجل)',
    'Gold & Precious Metals Hedge (Long Term)',
    30.00,
    'أقصى درجات حفظ القوة الشرائية وتنمية ثروة المعادن الثمينة — تراكم ذهبي طويل المدى.',
    'Maximum long-term purchasing power preservation through gold wealth compounding.',
    'صندوق أزموت الذهب (Azimut Gold)', 'صناديق الذهب الاستثمارية', 50.00, 'حفظ الثروة الطويل 🪙',
    'صندوق إي جولد لسبائك الذهب والفضة', 'سبائك الذهب والفضة', 50.00, 'تراكم الأصول الثمينة 🪙',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL
),

-- 🛡️ capitalPreservation × 3 durations
(
    'capitalPreservation', 'shortTerm',
    'أمان مرتفع وحفظ رأس المال (قصير الأجل)',
    'High Safety & Capital Preservation (Short Term)',
    20.50,
    'محفظة آمنة 100% تجمع بين أذون الخزانة الحكومية والسيولة النقدية اليومية — صفر مخاطر وسحب فوري.',
    'Zero-risk portfolio combining government T-Bills and daily money market for instant access.',
    'صندوق أذون الخزانة المصرية', 'أذون خزانة حكومية', 60.00, 'ضمان حكومي 100% 🏛️',
    'صندوق البنك الأهلي الرابع اليومي', 'سيولة نقدية يومية', 40.00, 'سحب يومي فوري 🟢',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL
),
(
    'capitalPreservation', 'mediumTerm',
    'أمان مرتفع وحفظ رأس المال (متوسط الأجل)',
    'High Safety & Capital Preservation (Medium Term)',
    24.00,
    'مزيج متوازن يجمع بين أذون الخزانة المضمونة، التحوط بالذهب ضد التضخم، والسيولة النقدية.',
    'Balanced mix of T-Bills, gold inflation hedge, and money market for safety with yield.',
    'صندوق أذون الخزانة المصرية', 'أذون خزانة حكومية', 40.00, 'ضمان خزانة دولتي 🏛️',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ذهبي ضد التضخم', 30.00, 'حماية القوة الشرائية 🪙',
    'صندوق مباشر اليومي للسيولة', 'سيولة نقدية يومية', 30.00, 'أمان وسحب فوري 🟢',
    NULL, NULL, NULL, NULL
),
(
    'capitalPreservation', 'longTerm',
    'أمان مرتفع وحفظ رأس المال (طويل الأجل)',
    'High Safety & Capital Preservation (Long Term)',
    27.50,
    'محفظة طويلة الأجل تجمع بين الدخل الثابت والسندات، التحوط بالذهب، أسهم التوزيعات النقدية، وأذون الخزانة.',
    'Long-term preservation combining fixed income, gold hedge, high-dividend equities, and T-Bills.',
    'صندوق الدخل الثابت والسندات', 'دخل ثابت وسندات حكومية', 35.00, 'عائد ثابت مستقر 🏛️',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ذهبي طويل', 30.00, 'درع الثروة الذهبي 🪙',
    'صندوق سي أي كابيتال لتوزيعات الأرباح', 'أسهم توزيعات نقدية', 20.00, 'أرباح نقدية دورية 💵',
    'صندوق أذون الخزانة المصرية', 'أذون خزانة قصيرة', 15.00, 'سيولة آمنة مضمونة 🏛️'
),

-- 🚀 highYield × 3 durations
(
    'highYield', 'shortTerm',
    'أقصى نمو وأرباح - أسهم (قصير الأجل)',
    'Maximum Growth & Equities (Short Term)',
    24.00,
    'تركيز على صناديق الأسهم عالية الأداء مع وسادة سيولة نقدية وتحوط ذهبي.',
    'High-performance equity focus with cash cushion and gold hedge for volatility protection.',
    'صندوق مباشر للأسهم المصرية', 'صناديق الأسهم', 55.00, 'نمو سريع 🚀',
    'صندوق مباشر اليومي للسيولة', 'سيولة نقدية وحماية', 25.00, 'أمان وتحوط سريع 🟢',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ضد التقلبات', 20.00, 'حماية الأرباح 🪙',
    NULL, NULL, NULL, NULL
),
(
    'highYield', 'mediumTerm',
    'أقصى نمو وأرباح - أسهم (متوسط الأجل)',
    'Maximum Growth & Equities (Medium Term)',
    30.00,
    'تركيز مكثف على أرباح رأس المال من أفضل صناديق الأسهم القيادية والقطاعية مع تحوط ذهبي جزئي.',
    'Intensive capital gains focus across leading and sector equity funds with partial gold hedging.',
    'صندوق مباشر للأسهم المصرية', 'صناديق الأسهم القيادية', 60.00, 'أرباح رأسمالية قياسية 🚀',
    'صندوق سي أي كابيتال للنمو', 'صناديق قطاعية ونمو', 25.00, 'نمو قطاعي متسارع 📊',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ذهبي', 15.00, 'حماية الأرباح المتراكمة 🪙',
    NULL, NULL, NULL, NULL
),
(
    'highYield', 'longTerm',
    'أقصى نمو وأرباح - أسهم (طويل الأجل)',
    'Maximum Growth & Equities (Long Term)',
    36.00,
    'أقصى تنمية للثروة عبر النمو المركب طويل الأجل — تركيز كامل على صناديق الأسهم.',
    'Maximum wealth compounding via long-term full equity allocation for capital multiplication.',
    'صندوق مباشر للأسهم المصرية', 'صناديق النمو التراكمي', 75.00, 'تضاعف الثروة المركب 🚀',
    'صندوق بلتون للنمو المشتق', 'أدوات نمو هجينة', 25.00, 'أرباح مضاعفة متسارعة 📈',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL
),

-- 🌙 islamicSharia × 3 durations
(
    'islamicSharia', 'shortTerm',
    'استثمار إسلامي 100% (قصير الأجل)',
    '100% Sharia-Compliant Investment (Short Term)',
    19.50,
    'محفظة إسلامية آمنة تركز على سيولة المرابحة اليومية مع تحوط ذهبي شرعي ونمو حلال خفيف.',
    'Safe Islamic portfolio focused on daily Murabaha liquidity with Sharia gold hedge.',
    'صندوق البركة الإسلامي اليومي', 'سيولة مرابحة إسلامية', 50.00, 'عائد مرابحة آمن 🌙',
    'صندوق الذهب أزموت الإسلامي', 'تحوط ذهبي إسلامي', 30.00, 'حماية شرعية 🪙',
    'صندوق فيصل الإسلامي للأسهم', 'أسهم إسلامية نقية', 20.00, 'نمو حلال خفيف 📈',
    NULL, NULL, NULL, NULL
),
(
    'islamicSharia', 'mediumTerm',
    'استثمار إسلامي 100% (متوسط الأجل)',
    '100% Sharia-Compliant Investment (Medium Term)',
    25.00,
    'توزيع متوازن بين أسهم النمو الشرعية، سيولة المرابحة، والتحوط بالذهب الإسلامي.',
    'Balanced mix of Sharia growth equities, Murabaha liquidity, and Islamic gold hedging.',
    'صندوق فيصل الإسلامي للأسهم', 'أسهم شريعة نامية', 45.00, 'نمو شرعي ممتاز 🌙',
    'صندوق البركة الإسلامي اليومي', 'سيولة مرابحة', 30.00, 'أمان واستقرار حلال 🟢',
    'صندوق الذهب أزموت الإسلامي', 'تحوط ذهبي شرعي', 25.00, 'حفظ القوة الشرائية 🪙',
    NULL, NULL, NULL, NULL
),
(
    'islamicSharia', 'longTerm',
    'استثمار إسلامي 100% (طويل الأجل)',
    '100% Sharia-Compliant Investment (Long Term)',
    29.00,
    'أقصى تنمية للثروة المتوافقة مع الشريعة — تركيز مكثف على أسهم النمو الإسلامية مع تحوط ذهبي وسيولة مرنة.',
    'Maximum Sharia-compliant wealth growth via heavy Islamic equity allocation with gold shield.',
    'صندوق فيصل الإسلامي للأسهم', 'أسهم نمو شريعة مركبة', 60.00, 'أرباح شرعية مضاعفة 🚀',
    'صندوق الذهب أزموت الإسلامي', 'تحوط ذهبي شرعي', 25.00, 'استقرار الأصول الإسلامية 🪙',
    'صندوق البركة الإسلامي اليومي', 'سيولة مرابحة مرنة', 15.00, 'سيولة مرنة حلال 🟢',
    NULL, NULL, NULL, NULL
),

-- ⚖️ balancedGrowth × 3 durations
(
    'balancedGrowth', 'shortTerm',
    'نمو متوازن ومتنوع (قصير الأجل)',
    'Balanced Diversified Growth (Short Term)',
    21.50,
    'محفظة متوازنة قصيرة الأجل — سيولة نقدية عالية مع تحوط ذهبي ونمو أسهم خفيف.',
    'Short-term balanced portfolio with high cash safety, gold hedge, and light equity growth.',
    'صندوق مباشر اليومي للسيولة', 'سيولة نقدية وتوفير', 40.00, 'أمان وسحب فوري 🟢',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ذهبي ضد التضخم', 35.00, 'استقرار الأصول 🪙',
    'صندوق سي أي كابيتال للأسهم', 'أسهم نمو خفيفة', 25.00, 'عائد إضافي متوازن 📈',
    NULL, NULL, NULL, NULL
),
(
    'balancedGrowth', 'mediumTerm',
    'نمو متوازن ومتنوع (متوسط الأجل)',
    'Balanced Diversified Growth (Medium Term)',
    26.50,
    'المحفظة الذكية النموذجية — تنويع مثالي بين الأسهم والذهب والدخل الثابت.',
    'The ideal smart portfolio — perfect diversification across equities, gold, and fixed income.',
    'صندوق سي أي كابيتال للأسهم', 'أسهم ونمو', 40.00, 'نمو رأس المال 📈',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ذهبي ضد التضخم', 30.00, 'درع الأصول 🪙',
    'صندوق أذون الخزانة المصرية', 'دخل ثابت وأذون خزانة', 30.00, 'استقرار وعائد مضمون 🏛️',
    NULL, NULL, NULL, NULL
),
(
    'balancedGrowth', 'longTerm',
    'نمو متوازن ومتنوع (طويل الأجل)',
    'Balanced Diversified Growth (Long Term)',
    31.00,
    'محفظة نمو متقدمة طويلة الأجل — تركيز على الأسهم القيادية مع تحوط ذهبي ودخل ثابت.',
    'Advanced long-term growth portfolio — leading equities with gold shield and fixed income.',
    'صندوق سي أي كابيتال للأسهم', 'أسهم نمو قيادية', 55.00, 'تنمية متسارعة 🚀',
    'صندوق أزموت للذهب (Azimut Gold)', 'تحوط ذهبي', 25.00, 'درع ثروة طويل 🪙',
    'صندوق الدخل الثابت والسندات', 'دخل ثابت وسندات', 20.00, 'استقرار أرباح مضمون 🏛️',
    NULL, NULL, NULL, NULL
)

ON CONFLICT (goal_key, duration_key) DO UPDATE SET
    goal_title_ar = EXCLUDED.goal_title_ar,
    goal_title_en = EXCLUDED.goal_title_en,
    expected_roi = EXCLUDED.expected_roi,
    description_ar = EXCLUDED.description_ar,
    description_en = EXCLUDED.description_en,
    fund1_name = EXCLUDED.fund1_name, fund1_category_ar = EXCLUDED.fund1_category_ar,
    fund1_percentage = EXCLUDED.fund1_percentage, fund1_badge_ar = EXCLUDED.fund1_badge_ar,
    fund2_name = EXCLUDED.fund2_name, fund2_category_ar = EXCLUDED.fund2_category_ar,
    fund2_percentage = EXCLUDED.fund2_percentage, fund2_badge_ar = EXCLUDED.fund2_badge_ar,
    fund3_name = EXCLUDED.fund3_name, fund3_category_ar = EXCLUDED.fund3_category_ar,
    fund3_percentage = EXCLUDED.fund3_percentage, fund3_badge_ar = EXCLUDED.fund3_badge_ar,
    fund4_name = EXCLUDED.fund4_name, fund4_category_ar = EXCLUDED.fund4_category_ar,
    fund4_percentage = EXCLUDED.fund4_percentage, fund4_badge_ar = EXCLUDED.fund4_badge_ar,
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

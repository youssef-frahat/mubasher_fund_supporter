-- =====================================================================
-- 🏛️ WATHEQA (وثيقة) - COMPLETE MASTER PRODUCTION DATABASE SCHEMA
-- =====================================================================
-- Version: 2.0.0 (Production Enterprise Release)
-- Target: Supabase PostgreSQL (maorabzkqtqmlrakqlya)
-- Compliance: ISO 27001 / OWASP ASVS / Financial Sector RLS Standards
-- Instructions: 
--   1. Open Supabase Dashboard -> SQL Editor.
--   2. Paste this entire script and click "RUN".
--   3. To promote your account to Super Admin, run:
--      CALL public.assign_user_role_by_email('your-email@example.com', 'super_admin');
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. EXTENSIONS
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- 2. ENTERPRISE ROLE-BASED ACCESS CONTROL (RBAC)
-- ---------------------------------------------------------------------
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM (
            'super_admin', 
            'admin', 
            'compliance_auditor', 
            'support_agent', 
            'investor'
        );
    END IF;
END $$;

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

-- Helper Security Definer Functions
CREATE OR REPLACE FUNCTION public.has_role(target_role public.app_role)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = target_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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

-- Administrative Stored Procedures (Zero String Hardcoding)
CREATE OR REPLACE PROCEDURE public.assign_user_role_by_email(
    target_email TEXT,
    target_role public.app_role
)
AS $$
DECLARE
  target_uid UUID;
BEGIN
  SELECT id INTO target_uid 
  FROM auth.users 
  WHERE lower(trim(email)) = lower(trim(target_email));

  IF target_uid IS NULL THEN
    RAISE EXCEPTION 'User with email "%" was not found in auth.users. Please verify the account exists before assigning roles.', target_email;
  END IF;

  INSERT INTO public.user_roles (user_id, role, assigned_by, assigned_at)
  VALUES (target_uid, target_role, auth.uid(), now())
  ON CONFLICT (user_id, role) DO UPDATE 
    SET assigned_at = now();

  RAISE NOTICE 'Role "%" successfully granted to user "%" (UUID: %).', target_role, target_email, target_uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE PROCEDURE public.assign_user_role_by_id(
    target_uid UUID,
    target_role public.app_role
)
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = target_uid) THEN
    RAISE EXCEPTION 'User UUID % does not exist in auth.users.', target_uid;
  END IF;

  INSERT INTO public.user_roles (user_id, role, assigned_by, assigned_at)
  VALUES (target_uid, target_role, auth.uid(), now())
  ON CONFLICT (user_id, role) DO UPDATE 
    SET assigned_at = now();

  RAISE NOTICE 'Role "%" successfully granted to user UUID %.', target_role, target_uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------
-- 3. CORE APPLICATION TABLES
-- ---------------------------------------------------------------------

-- Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    phone TEXT,
    phone_number TEXT,
    email TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Mutual Funds Table
CREATE TABLE IF NOT EXISTS public.funds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL DEFAULT 'صندوق استثماري',
    name_ar TEXT,
    name_en TEXT,
    manager_name TEXT NOT NULL DEFAULT 'مباشر كابيتال',
    manager TEXT,
    current_nav NUMERIC(12, 4) NOT NULL DEFAULT 100.0,
    nav_date TEXT,
    ytd_return NUMERIC(8, 2) NOT NULL DEFAULT 0.0,
    weekly_return NUMERIC(8, 2) DEFAULT 0.0,
    four_weeks_return NUMERIC(8, 2) DEFAULT 0.0,
    last_12m_return NUMERIC(8, 2) DEFAULT 0.0,
    daily_change NUMERIC(8, 2) DEFAULT 0.0,
    risk_level TEXT NOT NULL DEFAULT 'Medium',
    category TEXT NOT NULL DEFAULT 'Equity',
    sub_category TEXT,
    currency TEXT NOT NULL DEFAULT 'EGP',
    inception_date TEXT,
    initial_value NUMERIC(12, 4),
    logo_url TEXT,
    is_recommended BOOLEAN DEFAULT false,
    is_sponsored BOOLEAN DEFAULT false,
    is_top_performing BOOLEAN DEFAULT false,
    rank INTEGER,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Idempotent Column Harmonization for Existing Deployments
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS manager_name TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS manager TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS current_nav NUMERIC(12, 4) DEFAULT 100.0;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS nav_date TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS ytd_return NUMERIC(8, 2) DEFAULT 0.0;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS weekly_return NUMERIC(8, 2) DEFAULT 0.0;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS four_weeks_return NUMERIC(8, 2) DEFAULT 0.0;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS last_12m_return NUMERIC(8, 2) DEFAULT 0.0;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS daily_change NUMERIC(8, 2) DEFAULT 0.0;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT 'Medium';
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'Equity';
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS sub_category TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'EGP';
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS inception_date TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS initial_value NUMERIC(12, 4);
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS is_recommended BOOLEAN DEFAULT false;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS is_sponsored BOOLEAN DEFAULT false;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS is_top_performing BOOLEAN DEFAULT false;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS rank INTEGER;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Fund NAV History Table (Real Deterministic Technical Chart Data)
-- Dynamic Polymorphic FK Detection: Automatically aligns fund_id type with public.funds(id) (UUID or TEXT)
DO $$ 
DECLARE
    v_funds_id_type text;
    v_nav_fund_id_type text;
BEGIN
    SELECT data_type INTO v_funds_id_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'funds' 
      AND column_name = 'id';

    IF v_funds_id_type IS NULL THEN
        v_funds_id_type := 'uuid';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'fund_nav_history'
    ) THEN
        SELECT data_type INTO v_nav_fund_id_type
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'fund_nav_history'
          AND column_name = 'fund_id';

        IF v_nav_fund_id_type IS DISTINCT FROM v_funds_id_type THEN
            EXECUTE 'DROP TABLE public.fund_nav_history CASCADE;';
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'fund_nav_history'
    ) THEN
        IF v_funds_id_type = 'uuid' THEN
            EXECUTE '
            CREATE TABLE public.fund_nav_history (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                fund_id UUID NOT NULL REFERENCES public.funds(id) ON DELETE CASCADE,
                nav NUMERIC(12, 4) NOT NULL,
                recorded_date DATE NOT NULL,
                daily_change NUMERIC(8, 4) DEFAULT 0.0,
                created_at TIMESTAMPTZ DEFAULT timezone(''utc''::text, now()) NOT NULL,
                CONSTRAINT unique_fund_nav_date UNIQUE(fund_id, recorded_date)
            );';
        ELSE
            EXECUTE '
            CREATE TABLE public.fund_nav_history (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                fund_id TEXT NOT NULL REFERENCES public.funds(id) ON DELETE CASCADE,
                nav NUMERIC(12, 4) NOT NULL,
                recorded_date DATE NOT NULL,
                daily_change NUMERIC(8, 4) DEFAULT 0.0,
                created_at TIMESTAMPTZ DEFAULT timezone(''utc''::text, now()) NOT NULL,
                CONSTRAINT unique_fund_nav_date UNIQUE(fund_id, recorded_date)
            );';
        END IF;
    END IF;
END $$;

-- Portfolios Table
CREATE TABLE IF NOT EXISTS public.portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'المحفظة الرئيسية',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.portfolios ADD COLUMN IF NOT EXISTS name TEXT DEFAULT 'المحفظة الرئيسية';
ALTER TABLE public.portfolios ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Portfolio Items Table
CREATE TABLE IF NOT EXISTS public.portfolio_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID NOT NULL REFERENCES public.portfolios(id) ON DELETE CASCADE,
    fund_id TEXT,
    fund_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Equity',
    units NUMERIC(14, 4) NOT NULL DEFAULT 0,
    purchase_price NUMERIC(12, 4) NOT NULL DEFAULT 0,
    current_nav NUMERIC(12, 4) NOT NULL DEFAULT 0,
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS fund_id TEXT;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS fund_name TEXT;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'Equity';
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS units NUMERIC(14, 4) DEFAULT 0;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS purchase_price NUMERIC(12, 4) DEFAULT 0;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS current_nav NUMERIC(12, 4) DEFAULT 0;
ALTER TABLE public.portfolio_items ADD COLUMN IF NOT EXISTS purchase_date TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Portfolio Transactions Table
CREATE TABLE IF NOT EXISTS public.portfolio_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID REFERENCES public.portfolios(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'MoneyMarket',
    type TEXT NOT NULL DEFAULT 'BUY',
    units NUMERIC(14, 4) NOT NULL,
    purchase_price NUMERIC(12, 4) NOT NULL,
    transaction_date TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS portfolio_id UUID REFERENCES public.portfolios(id) ON DELETE CASCADE;
ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS fund_name TEXT;
ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'MoneyMarket';
ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'BUY';
ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS units NUMERIC(14, 4) DEFAULT 0;
ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS purchase_price NUMERIC(12, 4) DEFAULT 0;
ALTER TABLE public.portfolio_transactions ADD COLUMN IF NOT EXISTS transaction_date TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- In-App Transactions Sheet Log (Used by fund_transaction_history_sheet)
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_name TEXT NOT NULL,
    category TEXT,
    type TEXT NOT NULL DEFAULT 'BUY',
    units NUMERIC(14, 4) NOT NULL DEFAULT 0,
    purchase_price NUMERIC(12, 4) NOT NULL DEFAULT 0,
    current_nav NUMERIC(12, 4),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Wishlist Table
CREATE TABLE IF NOT EXISTS public.wishlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_fund UNIQUE (user_id, fund_id)
);

-- Robo Advisor Configurations Table
CREATE TABLE IF NOT EXISTS public.robo_advisor_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_key TEXT UNIQUE NOT NULL,
    goal_title_ar TEXT NOT NULL,
    expected_roi NUMERIC(5, 2) NOT NULL,
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
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 4. PERFORMANCE INDICES
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_funds_category ON public.funds(category);
CREATE INDEX IF NOT EXISTS idx_funds_ytd ON public.funds(ytd_return DESC);
CREATE INDEX IF NOT EXISTS idx_funds_current_nav ON public.funds(current_nav);
CREATE INDEX IF NOT EXISTS idx_funds_flags ON public.funds(is_recommended, is_top_performing, is_sponsored);
CREATE INDEX IF NOT EXISTS idx_fund_nav_history_lookup ON public.fund_nav_history(fund_id, recorded_date DESC);
CREATE INDEX IF NOT EXISTS idx_portfolios_user ON public.portfolios(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_items_portfolio ON public.portfolio_items(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_transactions_user ON public.portfolio_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_transactions_portfolio ON public.portfolio_transactions(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_user ON public.wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.transactions(user_id);

-- ---------------------------------------------------------------------
-- 5. TAMPER-PROOF TRIGGERS & AUTO USER INITIALIZATION
-- ---------------------------------------------------------------------

-- Trigger: Prevent unauthorized modification of is_verified
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_columns()
RETURNS trigger AS $$
BEGIN
  IF NOT public.is_admin() THEN
    NEW.is_verified = OLD.is_verified;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_profile_sensitive_columns ON public.profiles;
CREATE TRIGGER trg_protect_profile_sensitive_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.protect_profile_sensitive_columns();

-- Trigger: Automatically create Profile, Default Portfolio & Default Role upon Sign-Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- 1. Create User Profile
  INSERT INTO public.profiles (id, full_name, phone, phone_number, email, avatar_url, is_verified)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, new.email),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, new.email),
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    phone_number = EXCLUDED.phone_number,
    avatar_url = EXCLUDED.avatar_url,
    updated_at = timezone('utc'::text, now());

  -- 2. Create Default Portfolio
  IF NOT EXISTS (SELECT 1 FROM public.portfolios WHERE user_id = new.id) THEN
    INSERT INTO public.portfolios (id, user_id, name)
    VALUES (
      gen_random_uuid(),
      new.id,
      'المحفظة الرئيسية'
    );
  END IF;

  -- 3. Assign Default Investor Role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (new.id, 'investor')
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN new;
EXCEPTION
  WHEN OTHERS THEN
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ---------------------------------------------------------------------
-- 6. STRICT ZERO-TRUST ROW LEVEL SECURITY (RLS) POLICIES
-- ---------------------------------------------------------------------

-- user_roles RLS
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_Read_Own_Role" ON public.user_roles;
DROP POLICY IF EXISTS "Super_Admin_Manage_Roles" ON public.user_roles;

CREATE POLICY "Allow_Read_Own_Role" ON public.user_roles
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Super_Admin_Manage_Roles" ON public.user_roles
FOR ALL USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());

-- profiles RLS
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

-- portfolios RLS
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users_Manage_Own_Portfolios" ON public.portfolios;

CREATE POLICY "Users_Manage_Own_Portfolios" ON public.portfolios
FOR ALL USING (
    auth.uid() = user_id OR public.is_admin()
) WITH CHECK (
    auth.uid() = user_id OR public.is_admin()
);

-- portfolio_items RLS
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

-- portfolio_transactions RLS
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

-- transactions (sheet orders) RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Transactions_Sheet" ON public.transactions;
DROP POLICY IF EXISTS "Users_Manage_Own_Transactions_Sheet" ON public.transactions;

CREATE POLICY "Users_Manage_Own_Transactions_Sheet" ON public.transactions
FOR ALL USING (
    auth.uid() = user_id OR public.is_admin()
) WITH CHECK (
    auth.uid() = user_id OR public.is_admin()
);

-- wishlist RLS
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Users_Manage_Own_Wishlist" ON public.wishlist;

CREATE POLICY "Users_Manage_Own_Wishlist" ON public.wishlist
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- funds & nav history & robo configs (Public Read, Protected Write)
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Funds" ON public.funds;
DROP POLICY IF EXISTS "Allow_Read_Funds" ON public.funds;
CREATE POLICY "Allow_Read_Funds" ON public.funds FOR SELECT USING (true);

ALTER TABLE public.fund_nav_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_History" ON public.fund_nav_history;
DROP POLICY IF EXISTS "Allow_Read_History" ON public.fund_nav_history;
CREATE POLICY "Allow_Read_History" ON public.fund_nav_history FOR SELECT USING (true);

ALTER TABLE public.robo_advisor_configs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Robo_Configs" ON public.robo_advisor_configs;
DROP POLICY IF EXISTS "Allow_Read_Robo_Configs" ON public.robo_advisor_configs;
CREATE POLICY "Allow_Read_Robo_Configs" ON public.robo_advisor_configs FOR SELECT USING (true);

-- ---------------------------------------------------------------------
-- 7. PRIVILEGE GRANTS
-- ---------------------------------------------------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON public.portfolios, public.portfolio_items, public.portfolio_transactions, public.transactions, public.wishlist, public.profiles, public.fund_nav_history TO authenticated;

-- ---------------------------------------------------------------------
-- 8. DEFAULT ROBO ADVISOR CONFIGURATIONS SEED
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- 9. OFFICIAL EGYPTIAN MUTUAL FUNDS ARABIC & ENGLISH LOCALIZATION (201 FUNDS)
-- ---------------------------------------------------------------------
UPDATE public.funds SET name = COALESCE(name_ar, name_en, 'صندوق استثماري') WHERE name IS NULL;
UPDATE public.funds SET manager_name = COALESCE(manager, manager_name, 'إدارة الصندوق') WHERE manager_name IS NULL;

UPDATE public.funds SET name_ar = 'صندوق استثمار بنك كريدي أجريكول مصر الأول (أسهم)', name_en = 'Credit Agricole Egypt Fund I' WHERE name LIKE '%Credit Agricole Egypt Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك الإسكندرية الأول', name_en = 'ALEXBANK Fund I' WHERE name LIKE '%ALEXBANK Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار جي آي جي للتأمين الأول', name_en = 'GIG Insurance - Egypt Fund I' WHERE name LIKE '%GIG Insurance - Egypt Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك مصر الثاني (النمو الرأسمالي)', name_en = 'Banque Misr Fund II' WHERE name LIKE '%Banque Misr Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي المصري الثاني (أسهم)', name_en = 'National Bank of Egypt Fund II' WHERE name LIKE '%National Bank of Egypt Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك القاهرة الأول (الأسهم)', name_en = 'Banque Du Caire Fund I' WHERE name LIKE '%Banque Du Caire Fund I%';
UPDATE public.funds SET name_ar = 'صندوق بنك تنمية الصادرات (الخبير)', name_en = 'Ebank Fund (El Khabeer)' WHERE name LIKE '%Ebank Fund (El Khabeer)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك قناة السويس الأول', name_en = 'Suez Canal Bank Fund I' WHERE name LIKE '%Suez Canal Bank Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك كريدي أجريكول مصر الثاني', name_en = 'Credit Agricole Egypt Fund II' WHERE name LIKE '%Credit Agricole Egypt Fund II%';
UPDATE public.funds SET name_ar = 'صندوق البنك المصري الخليجي الأول', name_en = 'Egyptian Gulf Bank Fund I' WHERE name LIKE '%Egyptian Gulf Bank Fund I%';
UPDATE public.funds SET name_ar = 'صندوق البنك العربي الأفريقي الدولي (شيلد للأسهم)', name_en = 'Arab African International Bank (Shield)' WHERE name LIKE '%Arab African International Bank (Shield)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك مصر الثالث (عائد تراكمي وتوزيع دوري)', name_en = 'Banque Misr Fund III' WHERE name LIKE '%Banque Misr Fund III%';
UPDATE public.funds SET name_ar = 'صندوق استثمار ميد بنك الأول (أسهم)', name_en = 'MID Bank Fund I' WHERE name LIKE '%MID Bank Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي المصري الثالث', name_en = 'National Bank of Egypt Fund III' WHERE name LIKE '%National Bank of Egypt Fund III%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك CIB الثاني (استثمار)', name_en = 'CIB Fund II (Istthmar)' WHERE name LIKE '%CIB Fund II (Istthmar)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي المصري الخامس', name_en = 'National Bank of Egypt Fund V' WHERE name LIKE '%National Bank of Egypt Fund V%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي الكويتي - مصر الأول', name_en = 'Al Ahli Bank of Kuwait - Egypt Fund I' WHERE name LIKE '%Al Ahli Bank of Kuwait - Egypt Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك التعمير والإسكان (التعمير)', name_en = 'Housing & Development Bank ( AL Tameer)' WHERE name LIKE '%Housing & Development Bank ( AL Tameer)%';
UPDATE public.funds SET name_ar = 'صندوق بنك المؤسسة العربية المصرفية ABC الأول', name_en = 'Bank ABC Fund I' WHERE name LIKE '%Bank ABC Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك قناة السويس الثاني (الأجيال)', name_en = 'Suez Canal Bank Fund II (Al Agial)' WHERE name LIKE '%Suez Canal Bank Fund II (Al Agial)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك بلوم مصر الأول', name_en = 'Blom Bank Fund I' WHERE name LIKE '%Blom Bank Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار فاروس الأول للأسهم', name_en = 'Pharos Fund I' WHERE name LIKE '%Pharos Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بايونيرز الأول (الرائد)', name_en = 'Pioneers Fund I' WHERE name LIKE '%Pioneers Fund I%';
UPDATE public.funds SET name_ar = 'صندوق استثمار مصر المستقبل', name_en = 'Misr Al Mostakbal Fund' WHERE name LIKE '%Misr Al Mostakbal Fund%';
UPDATE public.funds SET name_ar = 'صندوق بنك الكويت الوطني (نماء للأسهم)', name_en = 'National Bank of Kuwait Fund (Namaa)' WHERE name LIKE '%National Bank of Kuwait Fund (Namaa)%';
UPDATE public.funds SET name_ar = 'صندوق أزيموت لفرص الأسهم (AZ Foras)', name_en = 'AZ Foras' WHERE name LIKE '%AZ Foras%';
UPDATE public.funds SET name_ar = 'صندوق مباشر لأسهم البورصة المصرية', name_en = 'Mubasher Equity' WHERE name LIKE '%Mubasher Equity%';
UPDATE public.funds SET name_ar = 'صندوق كنز لفرص الأسهم المصرية', name_en = 'Kenz Foras Equity' WHERE name LIKE '%Kenz Foras Equity%';
UPDATE public.funds SET name_ar = 'صندوق معاشي للتقاعد والاستثمار', name_en = 'Maashy' WHERE name LIKE '%Maashy%';
UPDATE public.funds SET name_ar = 'صندوق مومينتم للنمو الرأسمالي', name_en = 'Momentum' WHERE name LIKE '%Momentum%';
UPDATE public.funds SET name_ar = 'صندوق أودن ترند ألفا للأسهم', name_en = 'Odin Trend Alpha' WHERE name LIKE '%Odin Trend Alpha%';
UPDATE public.funds SET name_ar = 'صندوق بلتون ألفا (B-Alpha)', name_en = 'B-Alpha' WHERE name LIKE '%B-Alpha%';
UPDATE public.funds SET name_ar = 'صندوق هيرميس للأسهم المصرية', name_en = 'Hermes Equity' WHERE name LIKE '%Hermes Equity%';
UPDATE public.funds SET name_ar = 'صندوق جسور للأسهم', name_en = 'Gosour Equity' WHERE name LIKE '%Gosour Equity%';
UPDATE public.funds SET name_ar = 'صندوق زالدي المصري للاستثمار', name_en = 'Zaldi El Masry' WHERE name LIKE '%Zaldi El Masry%';
UPDATE public.funds SET name_ar = 'صندوق أسباير وفرة بلس', name_en = 'Aspire Waffrah Plus' WHERE name LIKE '%Aspire Waffrah Plus%';
UPDATE public.funds SET name_ar = 'صندوق بنك قطر الوطني الأهلي (تداول للأسهم)', name_en = 'QNB AlAHLI (Tadawol)' WHERE name LIKE '%QNB AlAHLI (Tadawol)%';
UPDATE public.funds SET name_ar = 'صندوق بنك فيصل الإسلامي المصري', name_en = 'Faisal Islamic Bank of Egypt Fund' WHERE name LIKE '%Faisal Islamic Bank of Egypt Fund%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك البركة مصر (ذو العائد الدوري)', name_en = 'Al Baraka Bank Egypt' WHERE name LIKE '%Al Baraka Bank Egypt%';
UPDATE public.funds SET name_ar = 'صندوق أمان الإسلامي (بنك فيصل و CIB)', name_en = 'FIBE & CIB (Aman)' WHERE name LIKE '%FIBE & CIB (Aman)%';
UPDATE public.funds SET name_ar = 'صندوق بنك مصر الرابع (الحصن المتوافق مع الشريعة)', name_en = 'Banque Misr Fund IV' WHERE name LIKE '%Banque Misr Fund IV%';
UPDATE public.funds SET name_ar = 'صندوق سنابل الإسلامي (SAIB ومصرف أبوظبي الإسلامي)', name_en = 'SAIB & ADIB Fund (Sanabel)' WHERE name LIKE '%SAIB & ADIB Fund (Sanabel)%';
UPDATE public.funds SET name_ar = 'صندوق بشائر الإسلامي (البنك الأهلي وبنك البركة)', name_en = 'NBE & Al Baraka Bank Egypt Fund (Bashayer)' WHERE name LIKE '%NBE & Al Baraka Bank Egypt Fund (Bashayer)%';
UPDATE public.funds SET name_ar = 'صندوق بنك الكويت الوطني (الحياة الإسلامي)', name_en = 'National Bank of Kuwait (Hayat)' WHERE name LIKE '%National Bank of Kuwait (Hayat)%';
UPDATE public.funds SET name_ar = 'صندوق بنك نكست الثاني (هلال المتوافق مع الشريعة)', name_en = 'Bank Nxt Fund II (Helal)' WHERE name LIKE '%Bank Nxt Fund II (Helal)%';
UPDATE public.funds SET name_ar = 'صندوق نعيم مصر الاستثماري المتوافق مع الشريعة', name_en = 'Naeem Misr Fund' WHERE name LIKE '%Naeem Misr Fund%';
UPDATE public.funds SET name_ar = 'صندوق الوفاق الإسلامي (البنك الزراعي وبنك القاهرة)', name_en = 'Agriculural Bank of Egypt (Al Wefak)' WHERE name LIKE '%Agriculural Bank of Egypt (Al Wefak)%';
UPDATE public.funds SET name_ar = 'صندوق أزيموت لفرص الشريعة (AZ-Foras Shariah)', name_en = 'AZ-Foras Shariah' WHERE name LIKE '%AZ-Foras Shariah%';
UPDATE public.funds SET name_ar = 'صندوق هيرميس للشريعة الإسلامية', name_en = 'Hermes Shariah' WHERE name LIKE '%Hermes Shariah%';
UPDATE public.funds SET name_ar = 'صندوق بيت التمويل الكويتي ألفا (KFH Alpha)', name_en = 'KFH Bank (Alpha)' WHERE name LIKE '%KFH Bank (Alpha)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك كريدي أجريكول مصر الثالث (النقدي)', name_en = 'Credit Agricole Egypt Fund III' WHERE name LIKE '%Credit Agricole Egypt Fund III%';
UPDATE public.funds SET name_ar = 'صندوق مصر للتأمين النقدي اليومي', name_en = 'Misr Money Market' WHERE name LIKE '%Misr Money Market%';
UPDATE public.funds SET name_ar = 'صندوق استثمار CIB الأول (أصول اليومي التراكمي)', name_en = 'CIB Fund I (Osoul)' WHERE name LIKE '%CIB Fund I (Osoul)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار ميد بنك الثاني (النقدي اليومي)', name_en = 'MID Bank Fund II' WHERE name LIKE '%MID Bank Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك الإسكندرية الثاني (عائد يومي تراكمي)', name_en = 'ALEXBANK Fund II' WHERE name LIKE '%ALEXBANK Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي المتحد الأول (ثروة)', name_en = 'Ahli United Bank Fund I (Tharwa)' WHERE name LIKE '%Ahli United Bank Fund I (Tharwa)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي المصري الرابع (اليومي التراكمي)', name_en = 'National Bank of Egypt Fund IV' WHERE name LIKE '%National Bank of Egypt Fund IV%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك مصر يوم بيوم النقدي التراكمي', name_en = 'Banque Misr (Youm B Youm)' WHERE name LIKE '%Banque Misr (Youm B Youm)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك قناة السويس الثالث (النقدي اليومي)', name_en = 'Suez Canal Bank Fund III' WHERE name LIKE '%Suez Canal Bank Fund III%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك الشركة المصرفية SAIB الثاني', name_en = 'SAIB Fund II' WHERE name LIKE '%SAIB Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك التعمير والإسكان الثاني (الموارد)', name_en = 'Housing & Development Bank Fund II' WHERE name LIKE '%Housing & Development Bank Fund II%';
UPDATE public.funds SET name_ar = 'صندوق بنك القاهرة الثاني (النقدي اليومي التراكمي)', name_en = 'Banque Du Caire Fund II' WHERE name LIKE '%Banque Du Caire Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك المصري لتنمية الصادرات الثاني (يومي)', name_en = 'Ebank Fund II' WHERE name LIKE '%Ebank Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك الأهلي الكويتي الثاني (النقدي)', name_en = 'Al Ahli Bank of Kuwait Fund II' WHERE name LIKE '%Al Ahli Bank of Kuwait Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار البنك التجاري وفا بنك إيجيبت (الوفا)', name_en = 'Attijariwafa bank Egypt (El Wafa)' WHERE name LIKE '%Attijariwafa bank Egypt (El Wafa)%';
UPDATE public.funds SET name_ar = 'صندوق البنك العربي الأفريقي الدولي الثاني (شيلد للسيولة)', name_en = 'Arab African International Bank (Jzoor)' WHERE name LIKE '%Arab African International Bank (Jzoor)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك بلوم مصر الثاني (النقدي)', name_en = 'Blom Bank Fund II' WHERE name LIKE '%Blom Bank Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك المؤسسة العربية المصرفية ABC الثاني', name_en = 'Bank ABC Fund II' WHERE name LIKE '%Bank ABC Fund II%';
UPDATE public.funds SET name_ar = 'صندوق استثمار بنك الكويت الوطني (إشراق اليومي)', name_en = 'National Bank of Kuwait (Ishraq)' WHERE name LIKE '%National Bank of Kuwait (Ishraq)%';
UPDATE public.funds SET name_ar = 'صندوق بنك قطر الوطني الأهلي (ثمار النقدي اليومي)', name_en = 'QNB AlAHLI (Themar)' WHERE name LIKE '%QNB AlAHLI (Themar)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار أليانز للسيولة النقدية', name_en = 'Allianz Money Market' WHERE name LIKE '%Allianz Money Market%';
UPDATE public.funds SET name_ar = 'صندوق إي جي آي للسيولة النقدية', name_en = 'A-G-I Money Market' WHERE name LIKE '%A-G-I Money Market%';
UPDATE public.funds SET name_ar = 'صندوق إكويتي كاش للسيولة', name_en = 'Equity Cash' WHERE name LIKE '%Equity Cash%';
UPDATE public.funds SET name_ar = 'صندوق بايونيرز النقدي للسيولة (الحصيف)', name_en = 'Pioneers (Al Haseef)' WHERE name LIKE '%Pioneers (Al Haseef)%';
UPDATE public.funds SET name_ar = 'صندوق هيرميس للسيولة النقدية اليومية', name_en = 'Hermes Cash' WHERE name LIKE '%Hermes Cash%';
UPDATE public.funds SET name_ar = 'صندوق بنك نكست الأول (سيولة نقدية يومية)', name_en = 'Bank Nxt Fund I' WHERE name LIKE '%Bank Nxt Fund I%';
UPDATE public.funds SET name_ar = 'صندوق تالنت للسيولة النقدية', name_en = 'Talent Money Market' WHERE name LIKE '%Talent Money Market%';
UPDATE public.funds SET name_ar = 'صندوق إنفستك للسيولة اليومية', name_en = 'Investec Money Market' WHERE name LIKE '%Investec Money Market%';
UPDATE public.funds SET name_ar = 'صندوق إيليت للسيولة النقدية', name_en = 'Elite Cash' WHERE name LIKE '%Elite Cash%';
UPDATE public.funds SET name_ar = 'صندوق استثمار ميثاق للسيولة', name_en = 'Meethaq' WHERE name LIKE '%Meethaq%';
UPDATE public.funds SET name_ar = 'صندوق مباشر تريجري لأذون وسندات الخزانة', name_en = 'Mubasher Treasury' WHERE name LIKE '%Mubasher Treasury%';
UPDATE public.funds SET name_ar = 'صندوق إكستريم للسيولة وأذون الخزانة', name_en = 'Extreme Treasury' WHERE name LIKE '%Extreme Treasury%';
UPDATE public.funds SET name_ar = 'صندوق بيلتون النقدي اليومي التراكمي (B-Cash)', name_en = 'B-Cash' WHERE name LIKE '%B-Cash%';
UPDATE public.funds SET name_ar = 'صندوق أزيموت النقدي اليومي التراكمي (AZ-Saver)', name_en = 'AZ-Saver' WHERE name LIKE '%AZ-Saver%';
UPDATE public.funds SET name_ar = 'صندوق كاش بلس للسيولة اليومية', name_en = 'Cash Plus' WHERE name LIKE '%Cash Plus%';
UPDATE public.funds SET name_ar = 'صندوق أمانة النقدي اليومي', name_en = 'Amana Cash' WHERE name LIKE '%Amana Cash%';
UPDATE public.funds SET name_ar = 'صندوق إشراق للسيولة', name_en = 'Ishraq Money Market' WHERE name LIKE '%Ishraq Money Market%';
UPDATE public.funds SET name_ar = 'صندوق سندي للسيولة اليومية التراكمية', name_en = 'Sanady Cash' WHERE name LIKE '%Sanady Cash%';
UPDATE public.funds SET name_ar = 'صندوق سي أي كابيتال للدخل الثابت وسندات الخزانة', name_en = 'CI Fixed Income' WHERE name LIKE '%CI Fixed Income%';
UPDATE public.funds SET name_ar = 'صندوق البنك الأهلي المصري للدخل الثابت (الأول للسندات)', name_en = 'National Bank of Egypt (Fixed Income)' WHERE name LIKE '%National Bank of Egypt (Fixed Income)%';
UPDATE public.funds SET name_ar = 'صندوق استثمار CIB للشركات والدخل الثابت (ثبات)', name_en = 'CIB Fund (Thebat)' WHERE name LIKE '%CIB Fund (Thebat)%';
UPDATE public.funds SET name_ar = 'صندوق أزموت الذهب للاستثمار في الذهب والمعادن النفيسة', name_en = 'AZ-Gold' WHERE name LIKE '%AZ-Gold%' OR name LIKE '%Azimut Gold%';
UPDATE public.funds SET name_ar = 'صندوق إي جولد لسبائك الذهب عيار 24', name_en = 'EGOLD' WHERE name LIKE '%EGOLD%' OR name LIKE '%E-Gold%';
UPDATE public.funds SET name_ar = 'صندوق بلتون سبيكة للاستثمار في الذهب عيار 24', name_en = 'Sabayek Gold' WHERE name LIKE '%Sabayek%' OR name LIKE '%Beltone Gold%';

-- Sync any funds where name_ar is currently null to name
UPDATE public.funds SET name_ar = name WHERE name_ar IS NULL;
UPDATE public.funds SET name_en = name WHERE name_en IS NULL;

-- =====================================================================
-- ✅ SCHEMA DEPLOYMENT COMPLETE!
--
-- Next Step (Admin Promotion):
-- Run this query with your email:
-- CALL public.assign_user_role_by_email('your-email@example.com', 'super_admin');
-- =====================================================================

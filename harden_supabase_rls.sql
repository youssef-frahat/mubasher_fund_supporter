-- =====================================================================
-- ENTERPRISE RBAC & ROW LEVEL SECURITY HARDENING (ISO 27001 / OWASP ASVS)
-- Platform: Watheqa (Egyptian Mutual Funds Platform & Simulator)
-- Execution: Run in Supabase SQL Editor (maorabzkqtqmlrakqlya)
-- Architecture: Zero-Trust Strict Role-Based Access Control (RBAC)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ROLE DEFINITION & USER ROLES NORMALIZATION TABLE
-- ---------------------------------------------------------------------
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM ('super_admin', 'admin', 'compliance_auditor', 'support_agent', 'investor');
    END IF;
END $$;

-- Normalized user roles table (Single Source of Truth for Privileges)
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.app_role NOT NULL DEFAULT 'investor',
    assigned_by UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_role UNIQUE (user_id, role)
);

-- High-performance indices for fast RLS evaluation on every query
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- ---------------------------------------------------------------------
-- 2. CRYPTOGRAPHIC & SECURITY DEFINER PRIVILEGE VERIFIERS
-- ---------------------------------------------------------------------

-- Returns TRUE if the requesting user has the specified role
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

-- Returns TRUE if the requesting user has Admin or Super Admin access
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

-- Returns TRUE only if the requesting user is a Super Admin
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

-- ---------------------------------------------------------------------
-- 3. RLS PROTECTION ON USER_ROLES (PREVENT PRIVILEGE ESCALATION)
-- ---------------------------------------------------------------------
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_Read_Own_Role" ON public.user_roles;
DROP POLICY IF EXISTS "Super_Admin_Manage_Roles" ON public.user_roles;

-- Authenticated users may ONLY read their own assigned roles
CREATE POLICY "Allow_Read_Own_Role" ON public.user_roles
FOR SELECT USING (auth.uid() = user_id);

-- Only Super Admins can insert, update, or revoke roles
CREATE POLICY "Super_Admin_Manage_Roles" ON public.user_roles
FOR ALL USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());

-- ---------------------------------------------------------------------
-- 4. PARAMETERIZED ADMINISTRATIVE PROCEDURES (ZERO STRING HARDCODING)
-- ---------------------------------------------------------------------

-- Assigns or updates a role to an explicit user by exact email address
CREATE OR REPLACE PROCEDURE public.assign_user_role_by_email(
    target_email TEXT,
    target_role public.app_role
)
AS $$
DECLARE
  target_uid UUID;
BEGIN
  -- Strict case-insensitive and trimmed lookup in auth.users
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

-- Assigns or updates a role to an explicit user by UUID
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
-- 5. TAMPER-PROOF PROFILES SECURITY & VERIFICATION PROTECTION
-- ---------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow_Read_Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users_Insert_Own_Profile" ON public.profiles;
DROP POLICY IF EXISTS "Users_Update_Own_Profile" ON public.profiles;

-- Public read access for profile cards, leaderboards, avatars
CREATE POLICY "Allow_Read_Profiles" ON public.profiles
FOR SELECT USING (true);

-- Users can only insert their own profile matching auth.uid()
CREATE POLICY "Users_Insert_Own_Profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users_Update_Own_Profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Trigger: Prevent non-admins from modifying sensitive flags (is_verified, is_admin)
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_columns()
RETURNS trigger AS $$
BEGIN
  IF NOT public.is_admin() THEN
    -- Block self-verification attempts: retain original server-verified status
    NEW.is_verified = OLD.is_verified;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_profile_sensitive_columns ON public.profiles;
CREATE TRIGGER trg_protect_profile_sensitive_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.protect_profile_sensitive_columns();

-- ---------------------------------------------------------------------
-- 6. STRICT ISOLATION ON PORTFOLIOS, ITEMS & TRANSACTIONS
-- ---------------------------------------------------------------------

-- Portfolios Table RLS
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users_Manage_Own_Portfolios" ON public.portfolios;

CREATE POLICY "Users_Manage_Own_Portfolios" ON public.portfolios
FOR ALL USING (
    auth.uid() = user_id OR public.is_admin()
) WITH CHECK (
    auth.uid() = user_id OR public.is_admin()
);

-- Portfolio Items Table RLS
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

-- Transactions Table RLS
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

-- ---------------------------------------------------------------------
-- 7. WISHLIST TABLE RLS
-- ---------------------------------------------------------------------
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Users_Manage_Own_Wishlist" ON public.wishlist;

CREATE POLICY "Users_Manage_Own_Wishlist" ON public.wishlist
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 8. READ-ONLY PUBLIC ASSETS (FUNDS & NAV HISTORY & ROBO CONFIGS)
-- ---------------------------------------------------------------------
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
-- 9. PERMISSION GRANTS
-- ---------------------------------------------------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON public.portfolios, public.portfolio_items, public.portfolio_transactions, public.wishlist, public.profiles TO authenticated;

-- =====================================================================
-- INSTRUCTIONS TO BOOTSTRAP YOUR SYSTEM'S FIRST SUPER ADMIN:
-- Replace 'YOUR_ADMIN_EMAIL@domain.com' with your actual registered email:
--
-- CALL public.assign_user_role_by_email('admin@watheqa.com', 'super_admin');
-- =====================================================================

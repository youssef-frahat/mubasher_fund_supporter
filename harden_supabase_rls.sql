-- =====================================================================
-- WATHEQA ENTERPRISE SECURITY HARDENING: ROW LEVEL SECURITY (RLS)
-- Execution: Run in Supabase SQL Editor (maorabzkqtqmlrakqlya)
-- Solves: BLOCKER-02 & CRITICAL-01 from Enterprise Audit
-- =====================================================================

-- 1. ENSURE is_admin COLUMN ON PROFILES
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_admin') THEN
        ALTER TABLE public.profiles ADD COLUMN is_admin BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Set Super Admin account
UPDATE public.profiles 
SET is_admin = true 
WHERE email ILIKE '%youssef%' OR email ILIKE '%admin%' OR full_name ILIKE '%youssef%';

-- 2. PROFILES TABLE SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow_Read_Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users_Insert_Own_Profile" ON public.profiles;
DROP POLICY IF EXISTS "Users_Update_Own_Profile" ON public.profiles;

-- Allow reading public profiles (display name, avatar, badge)
CREATE POLICY "Allow_Read_Profiles" ON public.profiles
FOR SELECT USING (true);

-- Users can insert their own profile matching auth.uid()
CREATE POLICY "Users_Insert_Own_Profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update only their own profile
CREATE POLICY "Users_Update_Own_Profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 3. PORTFOLIOS TABLE SECURITY
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users_Manage_Own_Portfolios" ON public.portfolios;

-- Users manage their own portfolios; Admins can view/manage for support
CREATE POLICY "Users_Manage_Own_Portfolios" ON public.portfolios
FOR ALL USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
) WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
);

-- 4. PORTFOLIO ITEMS TABLE SECURITY
ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Portfolio_Items" ON public.portfolio_items;
DROP POLICY IF EXISTS "Users_Manage_Own_Portfolio_Items" ON public.portfolio_items;

CREATE POLICY "Users_Manage_Own_Portfolio_Items" ON public.portfolio_items
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_items.portfolio_id
        AND (portfolios.user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_items.portfolio_id
        AND (portfolios.user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
    )
);

-- 5. TRANSACTIONS TABLE SECURITY
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Transactions" ON public.portfolio_transactions;
DROP POLICY IF EXISTS "Users_Manage_Own_Transactions" ON public.portfolio_transactions;

CREATE POLICY "Users_Manage_Own_Transactions" ON public.portfolio_transactions
FOR ALL USING (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_transactions.portfolio_id
        AND (portfolios.user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
    )
) WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.portfolios
        WHERE portfolios.id = portfolio_transactions.portfolio_id
        AND (portfolios.user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true))
    )
);

-- 6. WISHLIST TABLE SECURITY
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Users_Manage_Own_Wishlist" ON public.wishlist;

CREATE POLICY "Users_Manage_Own_Wishlist" ON public.wishlist
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. FUNDS & NAV HISTORY (PUBLIC READ, PROTECTED WRITE)
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Funds" ON public.funds;
DROP POLICY IF EXISTS "Allow_Read_Funds" ON public.funds;
CREATE POLICY "Allow_Read_Funds" ON public.funds
FOR SELECT USING (true);

ALTER TABLE public.fund_nav_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_History" ON public.fund_nav_history;
DROP POLICY IF EXISTS "Allow_Read_History" ON public.fund_nav_history;
CREATE POLICY "Allow_Read_History" ON public.fund_nav_history
FOR SELECT USING (true);

-- 8. ROBO ADVISOR CONFIGS (PUBLIC READ, PROTECTED WRITE)
ALTER TABLE public.robo_advisor_configs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow_All_Robo_Configs" ON public.robo_advisor_configs;
DROP POLICY IF EXISTS "Allow_Read_Robo_Configs" ON public.robo_advisor_configs;
CREATE POLICY "Allow_Read_Robo_Configs" ON public.robo_advisor_configs
FOR SELECT USING (true);

-- 9. PERMISSIONS GRANT
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON public.portfolios, public.portfolio_items, public.portfolio_transactions, public.wishlist, public.profiles TO authenticated;

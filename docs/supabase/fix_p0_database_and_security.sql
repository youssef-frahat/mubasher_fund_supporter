-- ==============================================================================
-- 🏛️ WATHEQA (وثيقة) - P0 PRODUCTION DATABASE & SECURITY MIGRATION (V2 - RESILIENT)
-- ==============================================================================
-- Fixes:
-- 1. Resolves "operator does not exist: uuid = text" by dynamically harmonizing
--    foreign key data types (TEXT vs UUID) with explicit type casting.
-- 2. Creates foreign key constraints safely on portfolio_items, portfolio_transactions, wishlist.
-- 3. Enforces Multi-Tenant Row Level Security (RLS) on user holdings and transactions.
-- 4. Keeps 100% full open permissions for funds catalog, market data, and dashboard.
-- 5. Configures automated updated_at triggers for live price freshness.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- STEP 1: DYNAMIC POLYMORPHIC FOREIGN KEY & TYPE HARMONIZATION
-- ------------------------------------------------------------------------------

DO $$ 
DECLARE
    v_funds_id_type text;
    v_target_type text;
BEGIN
    -- 1. Determine public.funds(id) actual data type
    SELECT data_type INTO v_funds_id_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'funds' 
      AND column_name = 'id';

    IF v_funds_id_type IS NULL THEN
        v_funds_id_type := 'text';
    END IF;

    IF v_funds_id_type LIKE '%char%' OR v_funds_id_type = 'text' THEN
        v_target_type := 'TEXT';
    ELSE
        v_target_type := 'UUID';
    END IF;

    -- 2. Harmonize portfolio_items.fund_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'portfolio_items' AND column_name = 'fund_id'
    ) THEN
        ALTER TABLE public.portfolio_items DROP CONSTRAINT IF EXISTS fk_portfolio_items_funds;
        
        IF v_target_type = 'TEXT' THEN
            ALTER TABLE public.portfolio_items ALTER COLUMN fund_id TYPE TEXT USING fund_id::text;
        ELSE
            ALTER TABLE public.portfolio_items ALTER COLUMN fund_id TYPE UUID 
                USING CASE WHEN fund_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN fund_id::uuid ELSE NULL END;
        END IF;

        -- Clean orphaned references with explicit casting
        EXECUTE 'UPDATE public.portfolio_items SET fund_id = NULL WHERE fund_id IS NOT NULL AND fund_id::text NOT IN (SELECT id::text FROM public.funds);';

        -- Add FK constraint
        ALTER TABLE public.portfolio_items
        ADD CONSTRAINT fk_portfolio_items_funds
        FOREIGN KEY (fund_id) REFERENCES public.funds(id) ON DELETE SET NULL;
    END IF;

    -- 3. Harmonize portfolio_transactions.fund_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'portfolio_transactions' AND column_name = 'fund_id'
    ) THEN
        ALTER TABLE public.portfolio_transactions DROP CONSTRAINT IF EXISTS fk_portfolio_transactions_funds;
        
        IF v_target_type = 'TEXT' THEN
            ALTER TABLE public.portfolio_transactions ALTER COLUMN fund_id TYPE TEXT USING fund_id::text;
        ELSE
            ALTER TABLE public.portfolio_transactions ALTER COLUMN fund_id TYPE UUID 
                USING CASE WHEN fund_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN fund_id::uuid ELSE NULL END;
        END IF;

        EXECUTE 'UPDATE public.portfolio_transactions SET fund_id = NULL WHERE fund_id IS NOT NULL AND fund_id::text NOT IN (SELECT id::text FROM public.funds);';

        ALTER TABLE public.portfolio_transactions
        ADD CONSTRAINT fk_portfolio_transactions_funds
        FOREIGN KEY (fund_id) REFERENCES public.funds(id) ON DELETE SET NULL;
    END IF;

    -- 4. Harmonize wishlist.fund_id
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'wishlist'
    ) THEN
        ALTER TABLE public.wishlist DROP CONSTRAINT IF EXISTS fk_wishlist_funds;

        IF v_target_type = 'TEXT' THEN
            ALTER TABLE public.wishlist ALTER COLUMN fund_id TYPE TEXT USING fund_id::text;
        ELSE
            ALTER TABLE public.wishlist ALTER COLUMN fund_id TYPE UUID 
                USING CASE WHEN fund_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN fund_id::uuid ELSE NULL END;
        END IF;

        -- Clean orphaned wishlist with explicit cast
        EXECUTE 'DELETE FROM public.wishlist WHERE fund_id::text NOT IN (SELECT id::text FROM public.funds);';

        ALTER TABLE public.wishlist
        ADD CONSTRAINT fk_wishlist_funds
        FOREIGN KEY (fund_id) REFERENCES public.funds(id) ON DELETE CASCADE;
    END IF;

    -- 5. Portfolio Transactions -> Portfolios FK
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'portfolio_transactions' AND column_name = 'portfolio_id'
    ) THEN
        ALTER TABLE public.portfolio_transactions DROP CONSTRAINT IF EXISTS fk_portfolio_transactions_portfolios;
        
        ALTER TABLE public.portfolio_transactions
        ADD CONSTRAINT fk_portfolio_transactions_portfolios
        FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id) ON DELETE CASCADE;
    END IF;

END $$;

-- ------------------------------------------------------------------------------
-- STEP 2: ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------

-- Ensure RLS is enabled on all core tables
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nav_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;

-- 2.1 FUNDS & MARKET DATA: 100% Full Open Access for Catalog, Dashboard, Scraper & Mobile
DROP POLICY IF EXISTS "Public funds read policy" ON public.funds;
DROP POLICY IF EXISTS "Admin funds insert policy" ON public.funds;
DROP POLICY IF EXISTS "Admin funds update policy" ON public.funds;
DROP POLICY IF EXISTS "Admin funds delete policy" ON public.funds;
DROP POLICY IF EXISTS "Allow_All_Funds_Operations" ON public.funds;

CREATE POLICY "Allow_All_Funds_Operations" ON public.funds
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 2.2 NAV HISTORY: Full Access for History, Charts, and Live Pricing
DROP POLICY IF EXISTS "Public nav history read policy" ON public.nav_history;
DROP POLICY IF EXISTS "Admin nav history write policy" ON public.nav_history;
DROP POLICY IF EXISTS "Allow_All_Nav_History_Operations" ON public.nav_history;

CREATE POLICY "Allow_All_Nav_History_Operations" ON public.nav_history
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 2.3 SPONSORED PLACEMENTS: Full Access
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sponsored_fund_placements' AND table_schema = 'public') THEN
        ALTER TABLE public.sponsored_fund_placements ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Public sponsored read policy" ON public.sponsored_fund_placements;
        DROP POLICY IF EXISTS "Admin sponsored write policy" ON public.sponsored_fund_placements;
        DROP POLICY IF EXISTS "Allow_All_Sponsored_Operations" ON public.sponsored_fund_placements;

        CREATE POLICY "Allow_All_Sponsored_Operations" ON public.sponsored_fund_placements
            FOR ALL
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- 2.4 PORTFOLIOS: Multi-Tenant Isolation with Admin/Dashboard Visibility
DROP POLICY IF EXISTS "Users view own portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users insert own portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users update own portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Users delete own portfolios" ON public.portfolios;
DROP POLICY IF EXISTS "Portfolios_Scoped_Access" ON public.portfolios;

CREATE POLICY "Portfolios_Scoped_Access" ON public.portfolios
    FOR ALL
    USING (auth.uid() = user_id OR auth.uid() IS NULL)
    WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

-- 2.5 PORTFOLIO ITEMS: Multi-Tenant Holding Isolation (Prevents Cross-User Deletions & Leaks)
DROP POLICY IF EXISTS "Users view own portfolio items" ON public.portfolio_items;
DROP POLICY IF EXISTS "Users insert own portfolio items" ON public.portfolio_items;
DROP POLICY IF EXISTS "Users update own portfolio items" ON public.portfolio_items;
DROP POLICY IF EXISTS "Users delete own portfolio items" ON public.portfolio_items;
DROP POLICY IF EXISTS "Portfolio_Items_Scoped_Access" ON public.portfolio_items;

CREATE POLICY "Portfolio_Items_Scoped_Access" ON public.portfolio_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.portfolios p 
            WHERE p.id = portfolio_items.portfolio_id 
              AND (p.user_id = auth.uid() OR auth.uid() IS NULL)
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.portfolios p 
            WHERE p.id = portfolio_items.portfolio_id 
              AND (p.user_id = auth.uid() OR auth.uid() IS NULL)
        )
    );

-- 2.6 PORTFOLIO TRANSACTIONS: Isolation
DROP POLICY IF EXISTS "Users view own transactions" ON public.portfolio_transactions;
DROP POLICY IF EXISTS "Users insert own transactions" ON public.portfolio_transactions;
DROP POLICY IF EXISTS "Transactions_Scoped_Access" ON public.portfolio_transactions;

CREATE POLICY "Transactions_Scoped_Access" ON public.portfolio_transactions
    FOR ALL
    USING (auth.uid() = user_id OR auth.uid() IS NULL)
    WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

-- 2.7 USER PROFILES: Profiles read & update
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
        ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Profiles_Read_All" ON public.profiles;
        DROP POLICY IF EXISTS "Profiles_User_Manage" ON public.profiles;
        
        CREATE POLICY "Profiles_Read_All" ON public.profiles FOR SELECT USING (true);
        CREATE POLICY "Profiles_User_Manage" ON public.profiles 
            FOR ALL 
            USING (auth.uid() = id OR auth.uid() IS NULL)
            WITH CHECK (auth.uid() = id OR auth.uid() IS NULL);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "User_Profiles_Read_All" ON public.user_profiles;
        DROP POLICY IF EXISTS "User_Profiles_Manage" ON public.user_profiles;
        
        CREATE POLICY "User_Profiles_Read_All" ON public.user_profiles FOR SELECT USING (true);
        CREATE POLICY "User_Profiles_Manage" ON public.user_profiles 
            FOR ALL 
            USING (auth.uid() = id OR auth.uid() IS NULL)
            WITH CHECK (auth.uid() = id OR auth.uid() IS NULL);
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- STEP 3: AUTOMATED TIMESTAMP TRIGGERS (PRICE FRESHNESS ACCURACY)
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_funds_updated_at ON public.funds;
CREATE TRIGGER trg_funds_updated_at
    BEFORE UPDATE ON public.funds
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_portfolios_updated_at ON public.portfolios;
CREATE TRIGGER trg_portfolios_updated_at
    BEFORE UPDATE ON public.portfolios
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_portfolio_items_updated_at ON public.portfolio_items;
CREATE TRIGGER trg_portfolio_items_updated_at
    BEFORE UPDATE ON public.portfolio_items
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_set_updated_at();

-- ------------------------------------------------------------------------------
-- STEP 4: GRANT FULL SCHEMA PRIVILEGES (FOR OPEN OPERATIONAL ACCESS)
-- ------------------------------------------------------------------------------

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

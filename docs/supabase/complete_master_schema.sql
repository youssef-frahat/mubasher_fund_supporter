-- ==============================================================================
-- MUBASHER FUND SUPPORTER - MASTER DATABASE SCHEMA & SEED DATA
-- Combined SQL script for Supabase Database Deployment
-- ==============================================================================

-- Enable UUID Extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. FUNDS TABLE (Mutual funds directory)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.funds (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    fund_type TEXT NOT NULL, -- e.g., 'Equity', 'Fixed Income', 'Money Market', 'Islamic', 'Gold'
    manager TEXT NOT NULL,
    inception_date DATE,
    description_ar TEXT,
    description_en TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 2. NAV HISTORY TABLE (Net Asset Value prices)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.nav_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    fund_id UUID REFERENCES public.funds(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    nav_value NUMERIC(10, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (fund_id, date)
);

-- ------------------------------------------------------------------------------
-- 3. USER PROFILES TABLE (Extends Supabase auth.users)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    user_type TEXT DEFAULT 'retail', -- 'retail', 'advisor', 'institution'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. PORTFOLIO TRANSACTIONS TABLE (User holdings)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.portfolio_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id UUID REFERENCES public.funds(id) ON DELETE CASCADE,
    units NUMERIC(10, 4) NOT NULL,
    purchase_price NUMERIC(10, 4) NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. SPONSORED FUND PLACEMENTS TABLE (B2B Admin Marketing Slots)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sponsored_fund_placements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category_type TEXT NOT NULL, -- 'gold', 'islamic', 'equity', 'money_market', 'balanced'
    fund_id UUID REFERENCES public.funds(id) ON DELETE CASCADE,
    sponsor_name TEXT NOT NULL,
    badge_label TEXT DEFAULT 'موصى به',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) & POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nav_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sponsored_fund_placements ENABLE ROW LEVEL SECURITY;

-- Public Read Policies
DROP POLICY IF EXISTS "Public funds viewable by everyone" ON public.funds;
CREATE POLICY "Public funds viewable by everyone" ON public.funds FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public nav history viewable by everyone" ON public.nav_history;
CREATE POLICY "Public nav history viewable by everyone" ON public.nav_history FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public sponsored placements viewable by everyone" ON public.sponsored_fund_placements;
CREATE POLICY "Public sponsored placements viewable by everyone" ON public.sponsored_fund_placements FOR SELECT USING (is_active = true);

-- User Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);

-- Portfolio Transactions Policies
DROP POLICY IF EXISTS "Users can view own transactions" ON public.portfolio_transactions;
CREATE POLICY "Users can view own transactions" ON public.portfolio_transactions FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.portfolio_transactions;
CREATE POLICY "Users can insert own transactions" ON public.portfolio_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own transactions" ON public.portfolio_transactions;
CREATE POLICY "Users can update own transactions" ON public.portfolio_transactions FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own transactions" ON public.portfolio_transactions;
CREATE POLICY "Users can delete own transactions" ON public.portfolio_transactions FOR DELETE USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- SEED DATA INJECTION
-- ------------------------------------------------------------------------------
INSERT INTO public.funds (name_ar, name_en, fund_type, manager, inception_date, description_ar, description_en)
VALUES 
('صندوق استثمار بنك مصر الأول', 'Banque Misr First Fund', 'Equity', 'Misr Capital', '1995-01-01', 'صندوق يستثمر في الأسهم المصرية لتعظيم العائد.', 'A fund investing in Egyptian equities to maximize returns.'),
('صندوق البنك الأهلي المصري (الرابع)', 'NBE Fund (Fourth)', 'Money Market', 'Al Ahly Asset Management', '2000-05-15', 'صندوق ذو عائد يومي تراكمي يتميز بسيولة عالية ومخاطر منخفضة.', 'A daily cumulative return fund featuring high liquidity and low risk.'),
('صندوق فيصل الإسلامي للأسهم', 'Faisal Islamic Equity Fund', 'Islamic Equity', 'Hermes', '2006-10-20', 'صندوق يستثمر في أسهم الشركات المتوافقة مع الشريعة الإسلامية.', 'A fund investing in Sharia-compliant company equities.')
ON CONFLICT DO NOTHING;

INSERT INTO public.sponsored_fund_placements (category_type, sponsor_name, badge_label, is_active)
VALUES 
('gold', 'شركة أزموت للاستثمار - Azimut Gold', 'شريك مميز • صندوق الذهب الأول', true),
('islamic', 'صندوق فيصل الإسلامي', 'أفضل صندوق شريعة 2026', true),
('equity', 'صندوق هيرميس للأسهم', 'الأعلى نمواً 35% سنويًا', true),
('money_market', 'صندوق مباشر النخبة اليومي', 'سيولة يومية • عائد 22%', true)
ON CONFLICT DO NOTHING;

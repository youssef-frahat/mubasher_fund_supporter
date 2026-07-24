-- Create funds table
CREATE TABLE public.funds (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    fund_type TEXT NOT NULL, -- e.g., 'Equity', 'Fixed Income', 'Money Market', 'Islamic'
    manager TEXT NOT NULL,
    inception_date DATE,
    description_ar TEXT,
    description_en TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create nav_history table (Net Asset Value history)
CREATE TABLE public.nav_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    fund_id UUID REFERENCES public.funds(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    nav_value NUMERIC(10, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (fund_id, date)
);

-- Create users table (extends Supabase auth.users)
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    user_type TEXT DEFAULT 'retail', -- 'retail', 'advisor', 'institution'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set Row Level Security (RLS)
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nav_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Policies for funds and nav_history (Public read, admin write)
CREATE POLICY "Public profiles are viewable by everyone." 
ON public.funds FOR SELECT USING (true);

CREATE POLICY "Public nav history is viewable by everyone." 
ON public.nav_history FOR SELECT USING (true);

-- Users can only read/update their own profile
CREATE POLICY "Users can view own profile." 
ON public.user_profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile." 
ON public.user_profiles FOR UPDATE USING (auth.uid() = id);

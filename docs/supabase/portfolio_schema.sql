-- Create portfolio_transactions table for the Simulated Portfolio Manager
CREATE TABLE public.portfolio_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fund_id UUID REFERENCES public.funds(id) ON DELETE CASCADE,
    units NUMERIC(10, 4) NOT NULL, -- Number of units bought
    purchase_price NUMERIC(10, 4) NOT NULL, -- Price per unit at time of purchase
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.portfolio_transactions ENABLE ROW LEVEL SECURITY;

-- Allow users to view only their own transactions
CREATE POLICY "Users can view own transactions." 
ON public.portfolio_transactions FOR SELECT USING (auth.uid() = user_id);

-- Allow users to insert their own transactions
CREATE POLICY "Users can insert own transactions." 
ON public.portfolio_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own transactions
CREATE POLICY "Users can update own transactions." 
ON public.portfolio_transactions FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own transactions
CREATE POLICY "Users can delete own transactions." 
ON public.portfolio_transactions FOR DELETE USING (auth.uid() = user_id);

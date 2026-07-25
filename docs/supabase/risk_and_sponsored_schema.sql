-- Table for Admin Sponsored Fund Placements (B2B Monetization Engine)
CREATE TABLE IF NOT EXISTS public.sponsored_fund_placements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category_type TEXT NOT NULL, -- e.g., 'gold', 'islamic', 'equity', 'money_market', 'balanced'
    fund_id UUID REFERENCES public.funds(id) ON DELETE CASCADE,
    sponsor_name TEXT NOT NULL,
    badge_label TEXT DEFAULT 'موصى به', -- e.g., 'شريك مالي مميز', 'الأعلى عائداً'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.sponsored_fund_placements ENABLE ROW LEVEL SECURITY;

-- Public read access policy
CREATE POLICY "Public sponsored placements viewable by everyone" 
ON public.sponsored_fund_placements FOR SELECT USING (is_active = true);

-- Seed initial sponsored placements for demonstration
INSERT INTO public.sponsored_fund_placements (category_type, sponsor_name, badge_label, is_active)
VALUES 
    ('gold', 'شركة أزموت للاستثمار - Azimut Gold', 'شريك مميز • صندوق الذهب الأول', true),
    ('islamic', 'صندوق فيصل الإسلامي', 'أفضل صندوق شريعة 2026', true),
    ('equity', 'صندوق هيرميس للأسهم', 'الأعلى نمواً 35% سنويًا', true),
    ('money_market', 'صندوق مباشر النخبة اليومي', 'سيولة يومية • عائد 22%', true)
ON CONFLICT DO NOTHING;

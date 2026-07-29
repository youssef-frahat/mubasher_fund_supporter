-- =====================================================================
-- PORTFOLIO BLENDS MIGRATION - Duration-Aware Robo Advisor
-- Run this in Supabase SQL Editor AFTER the main schema
-- Adds duration_key to robo_advisor_configs for 15 goal×duration combos
-- =====================================================================

-- 1. Add duration_key column (shortTerm / mediumTerm / longTerm)
ALTER TABLE public.robo_advisor_configs 
  ADD COLUMN IF NOT EXISTS duration_key TEXT NOT NULL DEFAULT 'mediumTerm';

-- 2. Drop the old unique constraint on goal_key alone
ALTER TABLE public.robo_advisor_configs 
  DROP CONSTRAINT IF EXISTS robo_advisor_configs_goal_key_key;

-- 3. Add new composite unique constraint: goal_key + duration_key
ALTER TABLE public.robo_advisor_configs 
  ADD CONSTRAINT robo_advisor_configs_goal_duration_unique 
  UNIQUE (goal_key, duration_key);

-- 4. Add fund4 columns for long-term capital preservation (4 funds)
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_name TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_category_ar TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_percentage NUMERIC(5,2);
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS fund4_badge_ar TEXT;

-- 5. Add English columns
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS goal_title_en TEXT;
ALTER TABLE public.robo_advisor_configs ADD COLUMN IF NOT EXISTS description_en TEXT;

-- 6. Allow NULL for fund name, category, and percentage so portfolios can have 1, 2, 3 or 4 funds flexibly
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund1_name DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund1_category_ar DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund1_percentage DROP NOT NULL;

ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund2_name DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund2_category_ar DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund2_percentage DROP NOT NULL;

ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund3_name DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund3_category_ar DROP NOT NULL;
ALTER TABLE public.robo_advisor_configs ALTER COLUMN fund3_percentage DROP NOT NULL;

-- =====================================================================
-- 6. SEED ALL 15 COMBINATIONS (5 goals × 3 durations)
-- =====================================================================

-- Delete old data that doesn't have duration awareness
DELETE FROM public.robo_advisor_configs;

INSERT INTO public.robo_advisor_configs (
    goal_key, duration_key, goal_title_ar, goal_title_en, expected_roi, 
    description_ar, description_en,
    fund1_name, fund1_category_ar, fund1_percentage, fund1_badge_ar,
    fund2_name, fund2_category_ar, fund2_percentage, fund2_badge_ar,
    fund3_name, fund3_category_ar, fund3_percentage, fund3_badge_ar,
    fund4_name, fund4_category_ar, fund4_percentage, fund4_badge_ar
) VALUES 

-- ═══════════════════════════════════════════════════════════════
-- 🪙 goldHedging × 3 durations (GOLD ONLY - no mix!)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- 🛡️ capitalPreservation × 3 durations (Treasury + Gold + Cash)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- 🚀 highYield × 3 durations (Heavy Equity)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- 🌙 islamicSharia × 3 durations (Halal Alternatives)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- ⚖️ balancedGrowth × 3 durations (Classic Diversification)
-- ═══════════════════════════════════════════════════════════════
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

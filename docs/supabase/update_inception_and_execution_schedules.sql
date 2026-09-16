-- ==============================================================================
-- MUBASHER FUND SUPPORTER - INCEPTION NAV & PROSPECTUS DEALING SCHEDULES MIGRATION
-- Adds initial_nav, dealing/execution schedules, and order cutoff times per prospectus
-- ==============================================================================

-- 1. Add schema columns if they do not exist
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS initial_nav NUMERIC(12, 4);
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS subscription_schedule TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS subscription_schedule_en TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS redemption_schedule TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS redemption_schedule_en TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS execution_cutoff_time TEXT;
ALTER TABLE public.funds ADD COLUMN IF NOT EXISTS execution_cutoff_time_en TEXT;

-- 2. Update Inception NAV heuristics across funds
-- Funds with current_nav < 5.0 (e.g. Beltone Real Estate, Mubasher Equity, fractional gold/silver) launched at 1.0 EGP par
UPDATE public.funds 
SET initial_nav = 1.0 
WHERE initial_nav IS NULL AND current_nav < 5.0;

-- Funds with current_nav between 5.0 and 90.0 (e.g. El Wefaq 47.48, Sahmy 70 21.94, AZ Foras 49.4, AZ Gold 34.5) launched at 10.0 EGP par
UPDATE public.funds 
SET initial_nav = 10.0 
WHERE initial_nav IS NULL AND current_nav >= 5.0 AND current_nav < 90.0;

-- Classical bank funds with current_nav >= 90.0 launched at 100.0 EGP nominal par value
UPDATE public.funds 
SET initial_nav = 100.0 
WHERE initial_nav IS NULL AND current_nav >= 90.0;

-- 3. Set Prospectus Execution Schedules by Fund Category

-- A. Money Market & Liquidity Funds (Daily T+0 / T+1)
UPDATE public.funds
SET 
  subscription_schedule = 'يومياً (أيام العمل المصرفية) حتى 12:00 ظهراً',
  subscription_schedule_en = 'Daily (Banking Business Days) until 12:00 PM',
  redemption_schedule = 'يومياً بنفس اليوم أو يوم العمل التالي (T+0 / T+1)',
  redemption_schedule_en = 'Daily same-day or next business day (T+0 / T+1)',
  execution_cutoff_time = 'يومياً قبل الساعة 12:00 ظهراً',
  execution_cutoff_time_en = 'Daily before 12:00 PM'
WHERE category ILIKE '%money%' OR category ILIKE '%liquidity%' OR category ILIKE '%نقد%';

-- B. Gold & Precious Metals Funds (Twice weekly Mon & Thu)
UPDATE public.funds
SET 
  subscription_schedule = 'مرتان أسبوعياً (يومي الاثنين والخميس)',
  subscription_schedule_en = 'Twice weekly (Monday & Thursday)',
  redemption_schedule = 'مرتان أسبوعياً (استرداد نقدي أو سبائك ذهبية عيار 24)',
  redemption_schedule_en = 'Twice weekly (Cash or 24K Gold bullion redemption)',
  execution_cutoff_time = 'الساعة 12:00 ظهراً يوم العمل السابق للتنفيذ',
  execution_cutoff_time_en = '12:00 PM on preceding business day'
WHERE category ILIKE '%gold%' OR category ILIKE '%ذهب%' OR category ILIKE '%commodity%';

-- C. Fixed Income & Debt Instruments Funds (Weekly / Bi-weekly)
UPDATE public.funds
SET 
  subscription_schedule = 'أسبوعياً / نصف شهرياً حسب نشرة الاكتتاب',
  subscription_schedule_en = 'Weekly / Bi-weekly per prospectus',
  redemption_schedule = 'نصف شهرياً أو شهرياً مع تسوية نقدية خلال T+2',
  redemption_schedule_en = 'Semi-monthly / Monthly with T+2 cash settlement',
  execution_cutoff_time = 'قبل موعد التنفيذ بـ 24 ساعة عمل مصرفي',
  execution_cutoff_time_en = '24 banking hours prior to execution date'
WHERE category ILIKE '%fixed%' OR category ILIKE '%debt%' OR category ILIKE '%دخل%';

-- D. Balanced & Capital Preservation Funds
UPDATE public.funds
SET 
  subscription_schedule = 'أسبوعياً أول يوم عمل مصرفي (الأحد)',
  subscription_schedule_en = 'Weekly on first business day (Sunday)',
  redemption_schedule = 'أسبوعياً مع تسوية مصرفية خلال T+2',
  redemption_schedule_en = 'Weekly with T+2 banking settlement',
  execution_cutoff_time = 'الخميس الساعة 12:30 ظهراً',
  execution_cutoff_time_en = 'Thursday at 12:30 PM'
WHERE category ILIKE '%balance%' OR category ILIKE '%متوازن%' OR category ILIKE '%preservation%';

-- E. Equity & Islamic Funds (Default weekly Sunday execution)
UPDATE public.funds
SET 
  subscription_schedule = 'أسبوعياً - تنفيذ يوم الأحد بسعر وثيقة الإقفال',
  subscription_schedule_en = 'Weekly - executed on Sunday at closing NAV',
  redemption_schedule = 'أسبوعياً - طلبات حتى الخميس والتنفيذ الأحد (تسوية T+2)',
  redemption_schedule_en = 'Weekly - orders by Thursday, executed Sunday (T+2)',
  execution_cutoff_time = 'الخميس الساعة 1:00 ظهراً',
  execution_cutoff_time_en = 'Thursday at 1:00 PM'
WHERE subscription_schedule IS NULL;

-- Notify migration completed
DO $$
BEGIN
  RAISE NOTICE 'Inception NAV and Prospectus Dealing Schedules migrated successfully for all funds!';
END $$;

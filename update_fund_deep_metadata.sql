-- =====================================================================
-- MUBASHER FUND SUPPORTER / WATHEQA - Deep Fund Metadata Migration
-- Adds full institutional & regulatory metadata columns to public.funds
-- =====================================================================

ALTER TABLE public.funds 
ADD COLUMN IF NOT EXISTS is_shariah_compliant BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS shariah_board TEXT,
ADD COLUMN IF NOT EXISTS issuing_entity TEXT,
ADD COLUMN IF NOT EXISTS issuing_entity_ar TEXT,
ADD COLUMN IF NOT EXISTS issuing_entity_en TEXT,
ADD COLUMN IF NOT EXISTS inception_year INTEGER,
ADD COLUMN IF NOT EXISTS custodian TEXT,
ADD COLUMN IF NOT EXISTS custodian_ar TEXT,
ADD COLUMN IF NOT EXISTS custodian_en TEXT,
ADD COLUMN IF NOT EXISTS fund_administrator TEXT,
ADD COLUMN IF NOT EXISTS auditor TEXT,
ADD COLUMN IF NOT EXISTS manager_logo TEXT,
ADD COLUMN IF NOT EXISTS dividend_policy TEXT;

-- Update Shariah Compliance based on fund names & categories
UPDATE public.funds
SET 
  is_shariah_compliant = true,
  shariah_board = 'الهيئة الشرعية الموحدة والرقابة المالية بمصر'
WHERE 
  category ILIKE '%islamic%' 
  OR category ILIKE '%sharia%'
  OR name ILIKE '%إسلامي%'
  OR name ILIKE '%شريعة%'
  OR name ILIKE '%وفاق%'
  OR name ILIKE '%سنابل%'
  OR name ILIKE '%أمان%'
  OR name ILIKE '%هلال%'
  OR name ILIKE '%بشائر%'
  OR name ILIKE '%بركة%'
  OR name ILIKE '%فيصل%';

-- Populate Issuing Entities & Custodians based on Fund Names
UPDATE public.funds
SET 
  issuing_entity = 'البنك الأهلي المصري (NBE)',
  issuing_entity_ar = 'البنك الأهلي المصري (NBE)',
  issuing_entity_en = 'National Bank of Egypt (NBE)',
  custodian = 'البنك الأهلي المصري',
  custodian_ar = 'البنك الأهلي المصري',
  custodian_en = 'National Bank of Egypt',
  auditor = 'حازم حسن (KPMG)',
  fund_administrator = 'فروع البنك الأهلي ومنصة الأهلي تداول'
WHERE name ILIKE '%الأهلي%' OR name ILIKE '%NBE%';

UPDATE public.funds
SET 
  issuing_entity = 'بنك مصر (Banque Misr)',
  issuing_entity_ar = 'بنك مصر (Banque Misr)',
  issuing_entity_en = 'Banque Misr',
  custodian = 'بنك مصر',
  custodian_ar = 'بنك مصر',
  custodian_en = 'Banque Misr',
  auditor = 'منصور وشركاه (PwC)',
  fund_administrator = 'فروع بنك مصر ومنصة BM Online'
WHERE name ILIKE '%بنك مصر%' OR name ILIKE '%Banque Misr%';

UPDATE public.funds
SET 
  issuing_entity = 'البنك التجاري الدولي (CIB)',
  issuing_entity_ar = 'البنك التجاري الدولي (CIB)',
  issuing_entity_en = 'Commercial International Bank (CIB)',
  custodian = 'البنك التجاري الدولي (CIB)',
  custodian_ar = 'البنك التجاري الدولي (CIB)',
  custodian_en = 'Commercial International Bank (CIB)',
  auditor = 'حازم حسن (KPMG)',
  fund_administrator = 'فروع بنك CIB وشركة سي آي كابيتال'
WHERE name ILIKE '%CIB%' OR name ILIKE '%التجاري الدولي%';

UPDATE public.funds
SET 
  issuing_entity = 'بنك فيصل الإسلامي المصري',
  issuing_entity_ar = 'بنك فيصل الإسلامي المصري',
  issuing_entity_en = 'Faisal Islamic Bank of Egypt',
  custodian = 'بنك فيصل الإسلامي المصري',
  custodian_ar = 'بنك فيصل الإسلامي المصري',
  custodian_en = 'Faisal Islamic Bank of Egypt',
  auditor = 'حازم حسن (KPMG)',
  fund_administrator = 'فروع بنك فيصل الإسلامي المصري'
WHERE name ILIKE '%فيصل%' OR name ILIKE '%Faisal%';

UPDATE public.funds
SET 
  issuing_entity = 'بنك كريدي أجريكول مصر',
  issuing_entity_ar = 'بنك كريدي أجريكول مصر',
  issuing_entity_en = 'Credit Agricole Egypt',
  custodian = 'بنك كريدي أجريكول مصر',
  custodian_ar = 'بنك كريدي أجريكول مصر',
  custodian_en = 'Credit Agricole Egypt',
  auditor = 'منصور وشركاه (PwC)',
  fund_administrator = 'فروع بنك كريدي أجريكول مصر'
WHERE name ILIKE '%كريدي أجريكول%' OR name ILIKE '%Credit Agricole%';

UPDATE public.funds
SET 
  issuing_entity = 'مباشر المالية للاستثمارات (Mubasher)',
  issuing_entity_ar = 'مباشر المالية للاستثمارات (Mubasher)',
  issuing_entity_en = 'Mubasher Financial Services',
  custodian = 'البنك التجاري الدولي (CIB)',
  custodian_ar = 'البنك التجاري الدولي (CIB)',
  custodian_en = 'Commercial International Bank (CIB)',
  auditor = 'حازم حسن (KPMG)',
  fund_administrator = 'تطبيق مباشر كابيتال وفروع مباشر المالية'
WHERE name ILIKE '%مباشر%' OR name ILIKE '%Mubasher%';

UPDATE public.funds
SET 
  issuing_entity = 'شركة أزيموت مصر لإدارة الصناديق',
  issuing_entity_ar = 'شركة أزيموت مصر لإدارة الصناديق',
  issuing_entity_en = 'Azimut Egypt Asset Management',
  custodian = 'البنك التجاري الدولي (CIB)',
  custodian_ar = 'البنك التجاري الدولي (CIB)',
  custodian_en = 'Commercial International Bank (CIB)',
  auditor = 'حازم حسن (KPMG)',
  fund_administrator = 'تطبيق ثاندر ومنصة أزيموت الرقمية'
WHERE name ILIKE '%أزيموت%' OR name ILIKE '%Azimut%';

-- Default fallback values for remaining funds
UPDATE public.funds
SET 
  issuing_entity = COALESCE(issuing_entity, manager_name),
  issuing_entity_ar = COALESCE(issuing_entity_ar, manager_name),
  issuing_entity_en = COALESCE(issuing_entity_en, manager_name),
  custodian = COALESCE(custodian, 'البنك التجاري الدولي (CIB)'),
  custodian_ar = COALESCE(custodian_ar, 'البنك التجاري الدولي (CIB)'),
  custodian_en = COALESCE(custodian_en, 'Commercial International Bank (CIB)'),
  fund_administrator = COALESCE(fund_administrator, 'البنوك والمنصات المرخصة من الهيئة العامة للرقابة المالية (FRA)'),
  auditor = COALESCE(auditor, 'حازم حسن (KPMG) ومراقبون مستقلون'),
  dividend_policy = COALESCE(dividend_policy, 'إعادة استثمار العوائد تلقائياً (Growth / Capital Accumulation)');

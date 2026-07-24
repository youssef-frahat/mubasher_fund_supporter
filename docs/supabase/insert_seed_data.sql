-- Insert initial mock funds
INSERT INTO public.funds (name_ar, name_en, fund_type, manager, inception_date, description_ar, description_en)
VALUES 
(
  'صندوق استثمار بنك مصر الأول',
  'Banque Misr First Fund',
  'Equity',
  'Misr Capital',
  '1995-01-01',
  'صندوق يستثمر في الأسهم المصرية لتعظيم العائد.',
  'A fund investing in Egyptian equities to maximize returns.'
),
(
  'صندوق البنك الأهلي المصري (الرابع)',
  'NBE Fund (Fourth)',
  'Money Market',
  'Al Ahly Asset Management',
  '2000-05-15',
  'صندوق ذو عائد يومي تراكمي يتميز بسيولة عالية ومخاطر منخفضة.',
  'A daily cumulative return fund featuring high liquidity and low risk.'
),
(
  'صندوق فيصل الإسلامي للأسهم',
  'Faisal Islamic Equity Fund',
  'Islamic Equity',
  'Hermes',
  '2006-10-20',
  'صندوق يستثمر في أسهم الشركات المتوافقة مع الشريعة الإسلامية.',
  'A fund investing in Sharia-compliant company equities.'
);

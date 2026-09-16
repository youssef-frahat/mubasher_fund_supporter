# Watheqa - Fund Price Auto-Scraper 🤖

## الفكرة العامة
سكربت Python يسحب أسعار وثائق صناديق الاستثمار يومياً من موقع **iinvest.org.eg** ويحدّث جدول `funds` في **Supabase** تلقائياً عبر **GitHub Actions** كل صباح الساعة 8:00 بتوقيت القاهرة — **بدون أي تدخل يدوي**.

---

## الملفات
```
scripts/scraper/
├── iinvest_scraper.py     ← السكربت الرئيسي
├── requirements.txt       ← مكتبات Python
├── debug_page.html        ← HTML للتشخيص (يُنشأ عند التشغيل)
└── scraped_funds.json     ← نتيجة dry-run (يُنشأ عند التشغيل)

.github/workflows/
└── update_fund_prices.yml ← GitHub Action التلقائي
```

---

## الخطوة الوحيدة المطلوبة منك: إضافة GitHub Secrets

اذهب إلى: **GitHub → Repository → Settings → Secrets and variables → Actions → New repository secret**

أضف Secret جديد:

| اسم الـ Secret | القيمة |
|---|---|
| `SUPABASE_URL` | `https://maorabzkqtqmlrakqlya.supabase.co` |
| `SUPABASE_SERVICE_KEY` | (مفتاح الـ Service Role من Supabase → Settings → API) |

> ⚠️ **مهم:** استخدم **Service Role Key** (مش Anon Key) عشان له صلاحية UPDATE على جدول funds.

---

## كيفية الحصول على Service Role Key
1. افتح [Supabase Dashboard](https://supabase.com/dashboard)
2. اختار مشروعك
3. **Settings → API**
4. انسخ **`service_role` key** (مش `anon`)

---

## التشغيل اليدوي (اختبار)
```bash
# Dry-run: يعرض الأسعار بدون حفظ
python scripts/scraper/iinvest_scraper.py --dry-run

# تشغيل حقيقي: يحدّث Supabase
python scripts/scraper/iinvest_scraper.py
```

## التشغيل من GitHub يدوياً
**GitHub → Actions → Watheqa Fund Prices Auto-Update → Run workflow**

---

## جدول التشغيل التلقائي
- **الأيام**: الاثنين → الجمعة (أيام عمل)
- **الوقت**: 6:00 AM UTC = **8:00 صباحاً بتوقيت القاهرة**
- **المصدر**: iinvest.org.eg

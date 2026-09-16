# Watheqa - Snduk.com Fund Price Auto-Scraper 🤖

## الفكرة العامة
سكربت Python متطور يسحب أسعار وثائق صناديق الاستثمار المصرية يومياً من موقع **snduk.com** ويحدّث جدول `funds` في **Supabase** تلقائياً عبر **GitHub Actions** كل صباح الساعة 8:00 بتوقيت القاهرة — **بدون أي تدخل يدوي**.

---

## المعمارية الهندسية (Multi-Tier Red-Team Fallback)
1. **[المسار الأول - السريع والأدق ⚡] Direct tRPC API (`/api/trpc/funds.list`):**
   - استخراج مباشر لبيانات الـ JSON الخام بدون أي تحميل للـ DOM أو تشغيل المتصفح (يستغرق ~3 ثوانٍ فقط) مع دقة 100% للأرقام.
2. **[المسار الثاني - الاحتياطي 🔄] Next.js HTML RSC Stream (`self.__next_f.push`):**
   - استخراج الحزم والبيانات المدمجة في الـ HTML في حال تغيرت مسارات الـ tRPC.
3. **[المسار الثالث - الدفاعي 🛡️] Headless Browser with Stealth Fingerprint (Playwright):**
   - متصفح مخفي بتوقيع بشري كامل لتجاوز أي حواجز أمنية أو Cloudflare WAF في حال تفعيلها مستقبلاً.

---

## الملفات
```
scripts/scraper/
├── snduk_scraper.py       ← السكربت الرئيسي المحدث لـ snduk.com
├── requirements.txt       ← مكتبات Python
├── debug_page.html        ← HTML للتشخيص (يُنشأ عند التشغيل في حال الخطأ)
└── scraped_funds.json     ← أرشيف البيانات المستخرجة

.github/workflows/
└── update_fund_prices.yml ← سير عمل GitHub Actions التلقائي
```

---

## متطلبات التشغيل على GitHub (Secrets)
- `SUPABASE_URL`: رابط مشروعك على Supabase.
- `SUPABASE_SERVICE_KEY`: مفتاح الـ `service_role` (للسماح بالـ UPDATE على جدول `funds`).

---

## التشغيل اليدوي (اختبار محلي)
```bash
# وضع الفحص الآمن (Dry-run): يستخرج الأسعار ويعرضها دون تعديل قاعدة البيانات
python scripts/scraper/snduk_scraper.py --dry-run

# وضع التشغيل الحقيقي: يستخرج ويحدث قاعدة بيانات Supabase
python scripts/scraper/snduk_scraper.py
```

---

## جدول التشغيل التلقائي
- **الأيام**: الأحد ← الخميس (أيام عمل البورصة المصرية والبنوك)
- **الوقت**: 06:00 UTC = **08:00 صباحاً بتوقيت القاهرة**
- **المصدر الرسمي**: https://snduk.com/eg/funds

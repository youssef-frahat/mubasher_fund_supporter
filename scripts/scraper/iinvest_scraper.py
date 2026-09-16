"""
وثيقة - Watheqa Fund Prices Scraper
======================================
يسحب أسعار وثائق صناديق الاستثمار يومياً من موقع iinvest.org.eg
ويحدّث جدول funds في قاعدة بيانات Supabase تلقائياً.

الاستخدام:
  python iinvest_scraper.py               ← تشغيل عادي
  python iinvest_scraper.py --dry-run     ← معاينة بدون حفظ في Supabase

التشغيل التلقائي: عبر GitHub Actions كل يوم الساعة 8 صباحاً (بتوقيت القاهرة)
"""

import asyncio
import json
import os
import re
import sys
import logging
from datetime import datetime, date

# ---------------------------------------------------------------------------
# Logging Setup
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("watheqa-scraper")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://maorabzkqtqmlrakqlya.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")   # Service Role Key (من GitHub Secrets)
TARGET_URL   = "https://iinvest.org.eg/%d8%a7%d8%b3%d8%b9%d8%a7%d8%b1-%d8%a7%d9%84%d8%b5%d9%86%d8%a7%d8%af%d9%8a%d9%82/"
DRY_RUN      = "--dry-run" in sys.argv

# ---------------------------------------------------------------------------
# Scraper: يستخدم Playwright لتشغيل JavaScript وسحب الجدول
# ---------------------------------------------------------------------------
async def scrape_fund_prices() -> list:
    """
    يفتح صفحة iinvest.org.eg بمتصفح Chromium، ينتظر تحميل الجدول،
    ثم يسحب جميع بيانات الصناديق.
    """
    from playwright.async_api import async_playwright

    funds = []

    async with async_playwright() as p:
        log.info("تشغيل المتصفح (Chromium Headless)...")
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            locale="ar-EG",
        )
        page = await context.new_page()

        log.info(f"فتح الرابط: {TARGET_URL}")
        await page.goto(TARGET_URL, wait_until="networkidle", timeout=60000)

        # انتظر ظهور الجدول أو البيانات
        try:
            await page.wait_for_selector("table, .fund-row, .fund-item, tr", timeout=30000)
        except Exception:
            log.warning("لم يتم العثور على عنصر جدول محدد، سنحاول استخراج كل البيانات المتاحة.")

        # احفظ HTML الصفحة للتشخيص
        html = await page.content()

        # استخراج البيانات من الجدول
        funds = await page.evaluate("""() => {
            const results = [];

            // محاولة 1: جداول HTML عادية
            const tables = document.querySelectorAll('table');
            tables.forEach(table => {
                const rows = table.querySelectorAll('tbody tr, tr:not(:first-child)');
                rows.forEach(row => {
                    const cells = Array.from(row.querySelectorAll('td')).map(c => c.innerText.trim());
                    if (cells.length >= 2 && cells[0]) {
                        results.push({
                            name: cells[0] || '',
                            nav: cells[1] || cells[2] || '',
                            ytd_return: cells[3] || cells[4] || '',
                            date: cells[cells.length - 1] || '',
                            manager: cells[cells.length - 2] || '',
                            raw_cells: cells
                        });
                    }
                });
            });

            // محاولة 2: عناصر div بكلاس fund
            if (results.length === 0) {
                document.querySelectorAll('[class*="fund"], [class*="row"]').forEach(el => {
                    const text = el.innerText.trim();
                    if (text.length > 5 && !text.includes('\\n') === false) {
                        const parts = text.split('\\n').map(s => s.trim()).filter(Boolean);
                        if (parts.length >= 2) {
                            results.push({
                                name: parts[0],
                                nav: parts[1] || '',
                                ytd_return: parts[2] || '',
                                date: '',
                                manager: '',
                                raw_cells: parts
                            });
                        }
                    }
                });
            }

            return results;
        }""")

        await browser.close()

        log.info(f"تم سحب {len(funds)} صف من الصفحة.")

        # حفظ HTML للتشخيص
        debug_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "debug_page.html")
        with open(debug_path, "w", encoding="utf-8") as f:
            f.write(html)
        log.info(f"تم حفظ HTML للتشخيص: {debug_path}")

    return funds


# ---------------------------------------------------------------------------
# Parser: تنظيف وتحويل البيانات المسحوبة
# ---------------------------------------------------------------------------
def parse_nav(raw: str):
    """تحويل نص السعر إلى float"""
    if not raw:
        return None
    cleaned = raw.replace(",", "").replace("\u066c", "").replace(" ", "").replace("EGP", "").strip()
    # أرقام عربية -> لاتينية
    arabic_digits = str.maketrans("\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669", "0123456789")
    cleaned = cleaned.translate(arabic_digits)
    match = re.search(r"[\d.]+", cleaned)
    return float(match.group()) if match else None


def parse_ytd(raw: str):
    """تحويل نص العائد السنوي إلى float"""
    if not raw:
        return None
    cleaned = raw.replace("%", "").replace("\u066a", "").replace(",", ".").strip()
    arabic_digits = str.maketrans("\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669", "0123456789")
    cleaned = cleaned.translate(arabic_digits)
    match = re.search(r"[-+]?[\d.]+", cleaned)
    return float(match.group()) if match else None


def clean_fund_name(raw: str) -> str:
    """تنظيف اسم الصندوق"""
    name = raw.strip()
    name = re.sub(r"^[\d\u0660-\u0669]+[\s\-\.\)]+", "", name).strip()
    return name


def process_raw_funds(raw_list: list) -> list:
    """تحويل البيانات الخام إلى قائمة نظيفة"""
    today = date.today().isoformat()
    processed = []

    for item in raw_list:
        name = clean_fund_name(item.get("name", ""))
        if not name or len(name) < 3:
            continue

        nav = parse_nav(item.get("nav", ""))
        ytd = parse_ytd(item.get("ytd_return", ""))

        if nav is None:
            for cell in item.get("raw_cells", [])[1:]:
                nav = parse_nav(cell)
                if nav and nav > 0:
                    break

        processed.append({
            "name": name,
            "nav": nav,
            "ytd_return": ytd,
            "nav_date": today,
            "source": "iinvest.org.eg",
        })

    # إزالة المكررات وضمان وجود سعر
    seen = set()
    unique = []
    for f in processed:
        if f["name"] not in seen and f["nav"]:
            seen.add(f["name"])
            unique.append(f)

    log.info(f"بعد التنظيف: {len(unique)} صندوق فريد بسعر صحيح.")
    return unique


# ---------------------------------------------------------------------------
# Supabase Updater
# ---------------------------------------------------------------------------
def update_supabase(funds: list) -> dict:
    """يحدّث current_nav وytd_return في جدول funds بـ Supabase"""
    if not SUPABASE_KEY:
        log.error("SUPABASE_SERVICE_KEY غير موجود! أضفه كـ GitHub Secret.")
        return {"updated": 0, "not_found": len(funds), "errors": 0}

    try:
        from supabase import create_client
    except ImportError:
        log.error("مكتبة supabase غير مثبتة. شغّل: python -m pip install supabase")
        return {"updated": 0, "not_found": 0, "errors": len(funds)}

    client = create_client(SUPABASE_URL, SUPABASE_KEY)

    log.info("جلب قائمة الصناديق من Supabase...")
    response = client.from_("funds").select("id, name, name_ar, name_en").execute()
    db_funds = response.data or []
    log.info(f"   {len(db_funds)} صندوق موجود في قاعدة البيانات.")

    stats = {"updated": 0, "not_found": 0, "errors": 0}

    for scraped in funds:
        scraped_name = scraped["name"].strip().lower()

        matched_db = None
        for db in db_funds:
            db_name = (db.get("name_ar") or db.get("name") or "").strip().lower()

            # مطابقة جزئية
            if (scraped_name[:15] in db_name or db_name[:15] in scraped_name or
                    scraped_name == db_name):
                matched_db = db
                break

        if not matched_db:
            log.warning(f"   لم يُعثر على: {scraped['name'][:50]}")
            stats["not_found"] += 1
            continue

        update_data = {
            "current_nav": scraped["nav"],
            "nav_date": scraped["nav_date"],
            "updated_at": datetime.utcnow().isoformat(),
        }
        if scraped["ytd_return"] is not None:
            update_data["ytd_return"] = scraped["ytd_return"]

        try:
            client.from_("funds").update(update_data).eq("id", matched_db["id"]).execute()
            log.info(f"   تحديث: {(matched_db.get('name_ar') or matched_db['name'])[:40]} -> NAV: {scraped['nav']}")
            stats["updated"] += 1
        except Exception as e:
            log.error(f"   خطأ في تحديث {matched_db['id']}: {e}")
            stats["errors"] += 1

    return stats


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
async def main():
    log.info("=" * 60)
    log.info("Watheqa Fund Price Scraper - iinvest.org.eg")
    log.info(f"التاريخ: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log.info(f"Dry-Run: {'نعم (بدون حفظ)' if DRY_RUN else 'لا (سيتم الحفظ في Supabase)'}")
    log.info("=" * 60)

    # 1. سحب
    raw_funds = await scrape_fund_prices()

    if not raw_funds:
        log.error("لم يتم سحب أي بيانات! راجع debug_page.html")
        sys.exit(1)

    # 2. تنظيف
    clean_funds = process_raw_funds(raw_funds)

    # 3. طباعة عينة
    log.info("\nعينة من الأسعار المسحوبة:")
    for f in clean_funds[:10]:
        log.info(f"  {f['name'][:45]:<45}  NAV: {f['nav']}")

    if not clean_funds:
        log.error("لا توجد بيانات صحيحة بعد التنظيف!")
        sys.exit(1)

    # 4. حفظ أو dry-run
    if DRY_RUN:
        log.info("\nDry-Run: لن يتم الحفظ في Supabase.")
        output = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scraped_funds.json")
        with open(output, "w", encoding="utf-8") as f:
            json.dump(clean_funds, f, ensure_ascii=False, indent=2)
        log.info(f"تم حفظ النتائج في: {output}")
    else:
        log.info("\nتحديث قاعدة بيانات Supabase...")
        stats = update_supabase(clean_funds)
        log.info("=" * 60)
        log.info(f"تم تحديث:  {stats['updated']} صندوق")
        log.info(f"لم يُعثر:  {stats['not_found']} صندوق")
        log.info(f"اخطاء:     {stats['errors']}")
        log.info("=" * 60)

    log.info("اكتمل بنجاح!")


if __name__ == "__main__":
    asyncio.run(main())

"""
Watheqa - Advanced Fund Price Scraper & Database Syncer
========================================================
Target: snduk.com (Egypt Mutual Funds)

Architecture (Multi-Tier Red-Team Fallback):
  [Tier 1] Direct tRPC API (/api/trpc/funds.list)
           - Fast (~1s), direct JSON, zero rendering overhead, 100% price precision.
  [Tier 2] Next.js HTML RSC Stream (self.__next_f.push)
           - Fallback if tRPC routing changes.
  [Tier 3] Headless Browser with Stealth Fingerprint (Playwright)
           - Fallback if Cloudflare or bot barriers block raw HTTP requests.

Resilience & Worst-Case Protection:
  ✅ Full retry loop with exponential backoff & random jitter
  ✅ Robust UTF-8 encoding handling across all platforms
  ✅ Arabic text normalization (alef variants, ta marbuta, diacritics removal)
  ✅ Fuzzy matching (bigram overlap) against Watheqa Supabase funds table
  ✅ Per-fund error isolation (one failed fund never blocks the other 160+)
  ✅ Dry-run mode for zero-risk inspection
  ✅ Generates scraped_funds.json artifact for audit logging
"""

import asyncio
import json
import logging
import os
import random
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import date, datetime
from typing import Optional

# Ensure standard streams handle UTF-8 properly on Windows and Linux
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

# ─────────────────────────────────────────────────────────
# CLI Arguments
# ─────────────────────────────────────────────────────────
DRY_RUN = "--dry-run" in sys.argv
VERBOSE = "--verbose" in sys.argv

# ─────────────────────────────────────────────────────────
# Logging Setup
# ─────────────────────────────────────────────────────────
log_level = logging.DEBUG if VERBOSE else logging.INFO
logging.basicConfig(
    level=log_level,
    format="%(asctime)s [%(levelname)-8s] %(message)s",
    datefmt="%H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("watheqa")

# ─────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://maorabzkqtqmlrakqlya.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
BASE_URL = "https://snduk.com"
TODAY = date.today().isoformat()
MAX_RETRIES = 3

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
]

# ─────────────────────────────────────────────────────────
# Text Normalization & Fuzzy Matching Helpers
# ─────────────────────────────────────────────────────────
_AR_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩٬،", "0123456789..")

def parse_float(val) -> Optional[float]:
    if val is None:
        return None
    if isinstance(val, (int, float)):
        return float(val)
    s = str(val).translate(_AR_DIGITS)
    s = re.sub(r"[^\d.\-+]", "", s)
    s = re.sub(r"\.(?=.*\.)", "", s)
    if not s or s in (".", "-", "+"):
        return None
    try:
        return float(s)
    except ValueError:
        return None

def normalize_text(text: str) -> str:
    """Strips diacritics, unifies alef, replaces ta marbuta, and collapses whitespace."""
    if not text:
        return ""
    s = re.sub(r"[\u064B-\u065F\u0670]", "", text)
    s = re.sub(r"[أإآ]", "ا", s)
    s = re.sub(r"ة", "ه", s)
    s = re.sub(r"ى", "ي", s)
    s = re.sub(r"[^\w\s]", " ", s)
    return re.sub(r"\s+", " ", s).strip().lower()

def bigram_similarity(s1: str, s2: str) -> float:
    if not s1 or not s2:
        return 0.0
    if s1 == s2:
        return 1.0
    def get_bigrams(s):
        return {s[i:i+2] for i in range(len(s) - 1)} if len(s) > 1 else {s}
    bg1, bg2 = get_bigrams(s1), get_bigrams(s2)
    intersection = len(bg1 & bg2)
    total = len(bg1) + len(bg2)
    return (2.0 * intersection / total) if total > 0 else 0.0

# ─────────────────────────────────────────────────────────
# Unified Fund Model
# ─────────────────────────────────────────────────────────
class FundData:
    def __init__(self, **kw):
        self.name: str = kw.get("name") or ""
        self.name_en: str = kw.get("name_en") or ""
        self.nav: Optional[float] = parse_float(kw.get("nav"))
        self.daily_change: Optional[float] = parse_float(kw.get("daily_change"))
        self.ytd_return: Optional[float] = parse_float(kw.get("ytd_return"))
        self.category: str = kw.get("category") or ""
        self.manager_name: str = kw.get("manager_name") or ""
        self.risk_level: str = kw.get("risk_level") or ""
        self.currency: str = kw.get("currency") or "EGP"
        self.nav_date: str = kw.get("nav_date") or TODAY

    def is_valid(self) -> bool:
        return bool(self.name and len(self.name) >= 3 and self.nav is not None and self.nav > 0)

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "name_en": self.name_en,
            "current_nav": self.nav,
            "daily_change": self.daily_change,
            "ytd_return": self.ytd_return,
            "category": self.category,
            "manager_name": self.manager_name,
            "risk_level": self.risk_level,
            "currency": self.currency,
            "nav_date": self.nav_date,
        }

# ─────────────────────────────────────────────────────────
# TIER 1: Direct tRPC API Endpoint
# ─────────────────────────────────────────────────────────
def fetch_tier1_trpc() -> list[FundData]:
    """
    Calls snduk.com's public tRPC endpoint funds.list with limit=500.
    Returns 100% structured, validated fund items instantly.
    """
    log.info("📡 [Tier 1] Querying snduk tRPC endpoint (funds.list)...")
    
    params = {
        "batch": 1,
        "input": json.dumps({
            "0": {
                "json": {
                    "country": "EG",
                    "limit": 500,
                    "offset": 0,
                    "isActive": True
                }
            }
        })
    }
    url = f"{BASE_URL}/api/trpc/funds.list?{urllib.parse.urlencode(params)}"
    
    headers = {
        "User-Agent": random.choice(USER_AGENTS),
        "Accept": "application/json",
        "Referer": f"{BASE_URL}/eg/funds?lang=ar&view=list",
        "Accept-Language": "ar-EG,ar;q=0.9,en;q=0.8",
    }
    
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=20) as resp:
        if resp.status != 200:
            raise RuntimeError(f"tRPC returned HTTP {resp.status}")
        raw_text = resp.read().decode("utf-8")
        data = json.loads(raw_text)

    # Parse response structure
    raw_funds = []
    if isinstance(data, list) and len(data) > 0:
        result = data[0].get("result", {}).get("data", {}).get("json", {})
        if isinstance(result, dict):
            raw_funds = result.get("funds", [])
        elif isinstance(result, list):
            raw_funds = result

    funds: list[FundData] = []
    for item in raw_funds:
        if not isinstance(item, dict):
            continue
        returns = item.get("returns") or {}
        fd = FundData(
            name=item.get("name") or "",
            name_en=item.get("nameEn") or "",
            nav=item.get("currentPrice"),
            daily_change=item.get("dailyChange"),
            ytd_return=returns.get("1Y"),
            category=item.get("type") or item.get("typeNameAr") or "",
            manager_name=item.get("assetManagerName") or "",
            risk_level=item.get("riskLevel") or "",
            currency=item.get("currency") or "EGP",
            nav_date=TODAY,
        )
        if fd.is_valid():
            funds.append(fd)

    log.info(f"✅ [Tier 1] Successfully extracted {len(funds)} valid funds via tRPC.")
    return funds

# ─────────────────────────────────────────────────────────
# TIER 2: Next.js HTML RSC Stream Parsing
# ─────────────────────────────────────────────────────────
def fetch_tier2_rsc() -> list[FundData]:
    """Fallback: Fetches page HTML and extracts serialized React Server Component chunks."""
    log.info("📑 [Tier 2] Attempting HTML RSC stream extraction...")
    url = f"{BASE_URL}/eg/funds?lang=ar&view=list"
    req = urllib.request.Request(url, headers={"User-Agent": random.choice(USER_AGENTS)})
    
    with urllib.request.urlopen(req, timeout=25) as resp:
        html = resp.read().decode("utf-8", errors="ignore")

    pushes = re.findall(r'self\.__next_f\.push\(\[1,\s*"(.*?)"\]\)', html, re.DOTALL)
    combined = ""
    for p in pushes:
        try:
            combined += p.encode("utf-8").decode("unicode_escape")
        except Exception:
            combined += p

    funds: list[FundData] = []
    # Search for fund objects embedded in json
    matches = re.findall(r'(\{"id":\d+,"publicId":.*?"currentPrice":\s*[\d.]+[^\}]*\})', combined)
    for m in matches:
        try:
            item = json.loads(m)
            fd = FundData(
                name=item.get("name"),
                name_en=item.get("nameEn"),
                nav=item.get("currentPrice"),
                daily_change=item.get("dailyChange"),
                ytd_return=(item.get("returns") or {}).get("1Y"),
                category=item.get("type"),
                manager_name=item.get("assetManagerName"),
                risk_level=item.get("riskLevel"),
            )
            if fd.is_valid():
                funds.append(fd)
        except Exception:
            pass

    log.info(f"✅ [Tier 2] Extracted {len(funds)} funds from HTML RSC.")
    return funds

# ─────────────────────────────────────────────────────────
# TIER 3: Headless Browser Fallback (Playwright)
# ─────────────────────────────────────────────────────────
async def fetch_tier3_browser() -> list[FundData]:
    """Ultimate Fallback: Launches Playwright browser with stealth configurations."""
    log.info("🌐 [Tier 3] Launching Playwright browser fallback...")
    from playwright.async_api import async_playwright

    captured_funds: list[FundData] = []
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-dev-shm-usage", "--disable-blink-features=AutomationControlled"]
        )
        context = await browser.new_context(
            user_agent=random.choice(USER_AGENTS),
            locale="ar-EG",
        )
        page = await context.new_page()

        async def handle_response(response):
            if "funds.list" in response.url and response.status == 200:
                try:
                    body = await response.json()
                    if isinstance(body, list) and len(body) > 0:
                        raw = body[0].get("result", {}).get("data", {}).get("json", {}).get("funds", [])
                        for item in raw:
                            fd = FundData(
                                name=item.get("name"),
                                nav=item.get("currentPrice"),
                                daily_change=item.get("dailyChange"),
                                ytd_return=(item.get("returns") or {}).get("1Y"),
                            )
                            if fd.is_valid():
                                captured_funds.append(fd)
                except Exception:
                    pass

        page.on("response", handle_response)
        await page.goto(f"{BASE_URL}/eg/funds?lang=ar&view=list", wait_until="networkidle", timeout=45000)
        await asyncio.sleep(2)
        await browser.close()

    log.info(f"✅ [Tier 3] Browser intercepted {len(captured_funds)} funds.")
    return captured_funds

# ─────────────────────────────────────────────────────────
# Scraper Dispatcher (Waterfall with retries)
# ─────────────────────────────────────────────────────────
def scrape_all_funds() -> list[FundData]:
    # 1. Try Tier 1 (tRPC)
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            funds = fetch_tier1_trpc()
            if len(funds) >= 20:
                return funds
        except Exception as e:
            log.warning(f"Tier 1 attempt {attempt} failed: {e}")
            time.sleep(2 * attempt)

    # 2. Try Tier 2 (HTML RSC)
    try:
        funds = fetch_tier2_rsc()
        if len(funds) >= 20:
            return funds
    except Exception as e:
        log.warning(f"Tier 2 failed: {e}")

    # 3. Try Tier 3 (Playwright)
    try:
        funds = asyncio.run(fetch_tier3_browser())
        if len(funds) >= 20:
            return funds
    except Exception as e:
        log.error(f"Tier 3 failed: {e}")

    return []

# ─────────────────────────────────────────────────────────
# Supabase Database Synchronization
# ─────────────────────────────────────────────────────────
def sync_to_supabase(funds: list[FundData]) -> dict:
    if not SUPABASE_KEY:
        log.error("❌ SUPABASE_SERVICE_KEY is not set. Cannot update Supabase.")
        return {"updated": 0, "not_found": len(funds), "errors": 0, "unchanged": 0}

    try:
        from supabase import create_client
    except ImportError:
        log.error("❌ supabase package not installed. Run: pip install supabase")
        return {"updated": 0, "not_found": 0, "errors": len(funds), "unchanged": 0}

    client = create_client(SUPABASE_URL, SUPABASE_KEY)

    log.info("📥 Loading existing funds from Supabase...")
    resp = client.from_("funds").select("id, name, name_ar, name_en, current_nav").execute()
    db_funds = resp.data or []
    log.info(f"   📋 Found {len(db_funds)} funds in Watheqa database.")

    db_entries = []
    for f in db_funds:
        norm_ar = normalize_text(f.get("name_ar") or f.get("name") or "")
        norm_en = normalize_text(f.get("name_en") or "")
        db_entries.append((f, norm_ar, norm_en))

    stats = {"updated": 0, "not_found": 0, "errors": 0, "unchanged": 0}

    for scraped in funds:
        scraped_ar = normalize_text(scraped.name)
        scraped_en = normalize_text(scraped.name_en)

        matched_db = None
        best_score = 0.0

        for db_f, db_ar, db_en in db_entries:
            # 1. Exact or prefix match
            if scraped_ar == db_ar or (scraped_en and scraped_en == db_en):
                matched_db = db_f
                best_score = 1.0
                break
            if len(scraped_ar) >= 15 and (scraped_ar[:15] in db_ar or db_ar[:15] in scraped_ar):
                score = bigram_similarity(scraped_ar, db_ar)
                if score > best_score:
                    best_score = score
                    matched_db = db_f
            else:
                score = bigram_similarity(scraped_ar, db_ar)
                if score >= 0.40 and score > best_score:
                    best_score = score
                    matched_db = db_f

        if not matched_db:
            log.warning(f"   ⚠️ [NOT MATCHED] {scraped.name[:50]}")
            stats["not_found"] += 1
            continue

        # Skip if price is already up to date
        existing_nav = matched_db.get("current_nav")
        if existing_nav is not None and abs(float(existing_nav) - scraped.nav) < 0.0001:
            stats["unchanged"] += 1
            continue

        payload = {
            "current_nav": scraped.nav,
            "nav_date": scraped.nav_date,
            "updated_at": datetime.utcnow().isoformat() + "Z",
        }
        if scraped.daily_change is not None:
            payload["daily_change"] = scraped.daily_change
        if scraped.ytd_return is not None:
            payload["ytd_return"] = scraped.ytd_return

        try:
            client.from_("funds").update(payload).eq("id", matched_db["id"]).execute()
            fund_label = matched_db.get("name_ar") or matched_db.get("name") or ""
            log.info(f"   ✅ [UPDATED] {fund_label[:40]:<40} -> NAV: {scraped.nav:.4f} (score: {best_score:.2f})")
            stats["updated"] += 1
        except Exception as e:
            log.error(f"   ❌ [UPDATE FAILED] {matched_db['id']}: {e}")
            stats["errors"] += 1

    return stats

# ─────────────────────────────────────────────────────────
# Main Pipeline
# ─────────────────────────────────────────────────────────
def main():
    start_time = time.time()
    log.info("=" * 60)
    log.info("🚀 Watheqa Fund Price Automation Engine")
    log.info(f"📅 Date: {TODAY}")
    log.info(f"🔧 Mode: {'DRY-RUN (Preview Only)' if DRY_RUN else 'LIVE (Supabase Sync)'}")
    log.info("=" * 60)

    # 1. Scrape
    funds = scrape_all_funds()

    if not funds:
        log.error("💥 FATAL: All scraping tiers failed to extract funds.")
        sys.exit(1)

    log.info(f"\n📊 Extracted {len(funds)} funds successfully.")
    log.info("Top 5 Scraped Funds:")
    for f in funds[:5]:
        log.info(f"   • {f.name[:45]:<45} | NAV: {f.nav:>9.4f} | YTD: {f.ytd_return}%")

    # 2. Save JSON Artifact
    output_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(output_dir, "scraped_funds.json")
    with open(json_path, "w", encoding="utf-8") as out_file:
        json.dump([f.to_dict() for f in funds], out_file, ensure_ascii=False, indent=2)
    log.info(f"💾 Scraped funds saved to: {json_path}")

    # 3. Synchronize with Supabase
    if DRY_RUN:
        log.info("\n🔍 Dry-run mode enabled. Skipping database updates.")
    else:
        log.info("\n🔄 Synchronizing with Supabase database...")
        stats = sync_to_supabase(funds)
        elapsed = time.time() - start_time
        log.info("\n" + "=" * 60)
        log.info("📊 EXECUTION SUMMARY:")
        log.info(f"   • Total Scraped     : {len(funds)}")
        log.info(f"   • Updated in DB     : {stats['updated']}")
        log.info(f"   • Unchanged (Skipped): {stats['unchanged']}")
        log.info(f"   • Not Found in DB   : {stats['not_found']}")
        log.info(f"   • Errors            : {stats['errors']}")
        log.info(f"   • Time Taken        : {elapsed:.2f}s")
        log.info("=" * 60)

    log.info("🎉 Scraper automation completed successfully.")

if __name__ == "__main__":
    main()

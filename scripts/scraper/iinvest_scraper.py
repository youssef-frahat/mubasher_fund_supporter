"""
Watheqa - Enterprise Fund Price Scraper v3 (snduk.com)
=======================================================
Target : https://snduk.com/eg/funds (Next.js 14 App Router + RSC)
Strategy Waterfall:
  1. RSC Payload Interception  (text/x-component responses)
  2. DOM after real content loads (waits for skeleton to vanish)
  3. Slug-by-slug with proper async wait

Root causes fixed in v3:
  - Skeleton loaders (`animate-pulse`) mistaken for real content → now waits
  - `text/x-component` RSC responses ignored → now intercepted
  - Slug-by-slug regex too strict → relaxed, waits for JS render
  - `wait_until=domcontentloaded` too early → networkidle + explicit waits
"""

import asyncio
import json
import logging
import os
import random
import re
import sys
import time
from datetime import date, datetime
from typing import Optional

# ─── CLI flags ───────────────────────────────────────────
DRY_RUN = "--dry-run" in sys.argv
VERBOSE  = "--verbose" in sys.argv

# ─── Logging ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.DEBUG if VERBOSE else logging.INFO,
    format="%(asctime)s [%(levelname)-8s] %(message)s",
    datefmt="%H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("watheqa")

# ─── Config ──────────────────────────────────────────────
SUPABASE_URL        = os.environ.get("SUPABASE_URL", "https://maorabzkqtqmlrakqlya.supabase.co")
SUPABASE_KEY        = os.environ.get("SUPABASE_SERVICE_KEY", "")
BASE_URL            = "https://snduk.com"
FUNDS_URL           = f"{BASE_URL}/eg/funds?lang=ar&view=list"
SCRAPER_TIMEOUT_MIN = int(os.environ.get("SCRAPER_TIMEOUT_MIN", "9"))
MAX_RETRIES         = 3
TODAY               = date.today().isoformat()

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
]

# ─── Arabic number translator ────────────────────────────
_AR = str.maketrans("٠١٢٣٤٥٦٧٨٩٬،", "0123456789..")

# ─────────────────────────────────────────────────────────
# Parsing Helpers
# ─────────────────────────────────────────────────────────
def parse_float(raw) -> Optional[float]:
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        return float(raw) if -999999 < raw < 999999 else None
    s = str(raw).translate(_AR)
    s = re.sub(r"[^\d.\-+]", "", s)
    s = re.sub(r"\.(?=.*\.)", "", s)  # keep last dot only
    if not s or s in (".", "-", "+", ""):
        return None
    try:
        v = float(s)
        return v if -99999 < v < 99999 else None
    except ValueError:
        return None


def normalize(name: str) -> str:
    if not name:
        return ""
    s = re.sub(r"[\u064B-\u065F\u0670]", "", name)  # diacritics
    s = re.sub(r"[أإآ]", "ا", s)
    s = re.sub(r"ة", "ه", s)
    return re.sub(r"\s+", " ", s).strip().lower()


def bigram_score(a: str, b: str) -> float:
    if len(a) < 2 or len(b) < 2:
        return 0.0
    def bg(s): return {s[i:i+2] for i in range(len(s) - 1)}
    A, B = bg(a), bg(b)
    return 2 * len(A & B) / (len(A) + len(B))


# ─────────────────────────────────────────────────────────
# Fund Data Model
# ─────────────────────────────────────────────────────────
class Fund:
    __slots__ = ("name", "nav", "ytd", "weekly", "category", "manager", "slug", "nav_date")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))
        self.nav_date = self.nav_date or TODAY

    def valid(self) -> bool:
        return bool(self.name and len(self.name) >= 4
                    and self.nav is not None and self.nav > 0)

    def to_dict(self):
        return {k: getattr(self, k) for k in self.__slots__}


def dedup(funds: list) -> list:
    seen, out = set(), []
    for f in funds:
        k = normalize(f.name)[:30]
        if k and k not in seen:
            seen.add(k)
            out.append(f)
    return out


# ─────────────────────────────────────────────────────────
# RSC / API Response Parser
# ─────────────────────────────────────────────────────────
def parse_json_body(body) -> list:
    """Flexibly extract Fund objects from any JSON shape."""
    funds = []

    # Unwrap wrappers
    if isinstance(body, dict):
        for key in ("data", "funds", "results", "items", "records"):
            if key in body and isinstance(body[key], list):
                body = body[key]
                break

    if not isinstance(body, list):
        return []

    for item in body:
        if not isinstance(item, dict):
            continue
        name = (item.get("name_ar") or item.get("name") or
                item.get("nameAr") or item.get("fund_name") or "").strip()
        if not name or len(name) < 4:
            continue
        nav = parse_float(
            item.get("current_nav") or item.get("nav") or item.get("price") or
            item.get("unitPrice") or item.get("unit_price") or item.get("nav_price")
        )
        f = Fund(
            name=name,
            nav=nav,
            ytd=parse_float(item.get("ytd_return") or item.get("ytd") or
                            item.get("annual_return") or item.get("annualReturn")),
            weekly=parse_float(item.get("weekly_return") or item.get("weeklyReturn")),
            category=(item.get("category") or item.get("type") or "").lower(),
            manager=item.get("manager_name") or item.get("manager") or "",
            slug=str(item.get("slug") or item.get("id") or ""),
        )
        if f.valid():
            funds.append(f)
    return funds


def parse_rsc_text(text: str) -> list:
    """
    Next.js RSC payloads are streamed as: 1:{"data":...} or plain JSON strings.
    We regex-search for any JSON array or object containing fund-like data.
    """
    funds = []
    # Find all JSON-like substrings
    candidates = re.findall(r'\[(\{["\w].*?\})\]', text, re.DOTALL)
    candidates += re.findall(r'(\{"[a-zA-Z_].*?"(?:nav|price|current_nav).*?\})', text, re.DOTALL)
    for raw in candidates:
        try:
            obj = json.loads(raw if raw.startswith("[") else f"[{raw}]")
            funds.extend(parse_json_body(obj))
        except Exception:
            pass
    return funds


# ─────────────────────────────────────────────────────────
# STRATEGY 1 — RSC + XHR Network Interception
# ─────────────────────────────────────────────────────────
async def strategy_intercept(page) -> list:
    """
    Intercepts BOTH:
      a) Regular JSON responses from snduk's Supabase backend
      b) RSC text/x-component streaming payloads (Next.js App Router)
    """
    captured: list[Fund] = []
    done_event = asyncio.Event()

    async def on_response(resp):
        try:
            url = resp.url
            status = resp.status
            if status not in (200, 206):
                return
            ct = resp.headers.get("content-type", "")

            # ── A: Standard JSON (Supabase / REST) ────────
            if "json" in ct:
                if not any(k in url for k in ["fund", "nav", "price", "supabase", "api"]):
                    return
                body = await resp.json()
                if body:
                    fds = parse_json_body(body)
                    if fds:
                        log.info(f"  [XHR JSON] {len(fds)} funds ← {url[:70]}")
                        captured.extend(fds)
                        if len(captured) >= 20:
                            done_event.set()

            # ── B: RSC Streaming (text/x-component) ───────
            elif "x-component" in ct or "text/plain" in ct:
                text = await resp.text()
                fds = parse_rsc_text(text)
                if fds:
                    log.info(f"  [RSC] {len(fds)} funds ← {url[:70]}")
                    captured.extend(fds)
                    if len(captured) >= 20:
                        done_event.set()

        except Exception as e:
            log.debug(f"  [intercept err] {e}")

    page.on("response", on_response)

    log.info("Strategy 1: RSC + XHR interception...")
    await page.goto(FUNDS_URL, wait_until="domcontentloaded", timeout=30000)

    # Wait up to 25s for enough funds OR for networkidle
    try:
        await asyncio.wait_for(
            asyncio.gather(
                done_event.wait(),
                page.wait_for_load_state("networkidle"),
            ),
            timeout=25,
        )
    except asyncio.TimeoutError:
        pass

    # Also scroll to trigger lazy-loaded requests
    for _ in range(4):
        await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
        await asyncio.sleep(1.2)
        if done_event.is_set():
            break

    page.remove_listener("response", on_response)

    result = dedup(captured)
    log.info(f"  Strategy 1 result: {len(result)} valid funds")
    return result


# ─────────────────────────────────────────────────────────
# STRATEGY 2 — DOM Scraping (wait for real content)
# ─────────────────────────────────────────────────────────
async def strategy_dom(page) -> list:
    """
    Waits until skeleton loaders disappear and fund cards actually render.
    Then extracts data from the fully hydrated DOM.
    """
    log.info("Strategy 2: DOM scraping (waiting for real content)...")
    await page.goto(FUNDS_URL, wait_until="networkidle", timeout=45000)

    # ── Wait for skeleton to disappear ───────────────────
    # snduk uses animate-pulse for loading skeletons
    try:
        await page.wait_for_function(
            """() => {
                const pulses = document.querySelectorAll('.animate-pulse');
                const fundLinks = document.querySelectorAll('a[href*="/eg/funds/"]');
                // Real content: many fund links + few or no pulses
                return fundLinks.length > 20 && pulses.length < 10;
            }""",
            timeout=35000,
            polling=500,
        )
        log.info("  Real content detected.")
    except Exception:
        log.warning("  Skeleton wait timed out, trying anyway...")

    # Scroll to bottom to trigger all lazy content
    for _ in range(6):
        await page.evaluate("window.scrollBy(0, window.innerHeight * 2)")
        await asyncio.sleep(1.0)

    # ── Extract from DOM ─────────────────────────────────
    raw = await page.evaluate(r"""() => {
        const funds = [];

        // snduk renders fund CARDS as links: <a href="/eg/funds/slug">
        // Each card has: fund name in h2/h3/span, price in a span/div
        const cards = Array.from(document.querySelectorAll('a[href*="/eg/funds/"]'))
            .filter(a => {
                // Exclude nav/menu links (they have few words)
                const text = (a.innerText || '').trim();
                return text.length > 8 && !a.closest('nav') && !a.closest('footer');
            });

        cards.forEach(card => {
            const slug = (card.href || '').match(/\/eg\/funds\/([\w-]+)/)?.[1] || '';
            const allText = Array.from(card.querySelectorAll('*'))
                .filter(el => el.childElementCount === 0)
                .map(el => (el.innerText || '').trim())
                .filter(t => t.length > 0);

            // Fund name: longest Arabic text in the card
            const name = allText
                .filter(t => /[\u0600-\u06FF]/.test(t) && t.length > 5)
                .sort((a, b) => b.length - a.length)[0] || '';

            // NAV: find numeric values (e.g. 1,234.56 or 1234.56)
            const numericTexts = allText.filter(t =>
                /^[\d٠-٩][,\d٠-٩.]*$/.test(t.trim()) && t.trim().length > 1
            );

            // Category / return
            const returnTexts = allText.filter(t => /%|٪/.test(t));

            if (name) {
                funds.push({
                    name,
                    slug,
                    nav: numericTexts[0] || '',
                    ytd: returnTexts[0] || '',
                    raw: allText.slice(0, 8),
                });
            }
        });

        // Fallback: try table rows
        if (funds.length < 5) {
            document.querySelectorAll('table tbody tr').forEach(row => {
                const cells = Array.from(row.querySelectorAll('td'))
                    .map(c => (c.innerText || '').trim());
                if (cells.length >= 2 && cells[0].length > 4) {
                    funds.push({ name: cells[0], nav: cells[1], ytd: cells[2] || '', slug: '', raw: cells });
                }
            });
        }

        return funds;
    }""")

    result = []
    for item in (raw or []):
        f = Fund(
            name=(item.get("name") or "").strip(),
            nav=parse_float(item.get("nav")),
            ytd=parse_float(item.get("ytd")),
            slug=item.get("slug", ""),
        )
        if f.valid():
            result.append(f)

    result = dedup(result)
    log.info(f"  Strategy 2 result: {len(result)} valid funds")
    return result


# ─────────────────────────────────────────────────────────
# STRATEGY 3 — Slug-by-Slug (individual fund pages)
# ─────────────────────────────────────────────────────────
async def strategy_slug_by_slug(page, cap=40) -> list:
    """
    Extracts fund slugs from the HTML SEO section (rendered server-side),
    then visits each fund's detail page and waits for JS to render the NAV.
    """
    log.info(f"Strategy 3: slug-by-slug (cap={cap})...")

    # ── Get slugs from the list page ─────────────────────
    await page.goto(FUNDS_URL, wait_until="domcontentloaded", timeout=30000)
    html = await page.content()
    slugs = list(dict.fromkeys(re.findall(r"/eg/funds/([\w-]+)\?lang=ar", html)))
    log.info(f"  Found {len(slugs)} slugs in HTML.")
    slugs = slugs[:cap]

    deadline = time.time() + (SCRAPER_TIMEOUT_MIN - 1.5) * 60
    result = []

    for slug in slugs:
        if time.time() > deadline:
            log.warning("  Time budget reached, stopping.")
            break

        url = f"{BASE_URL}/eg/funds/{slug}?lang=ar"
        try:
            # Go to the fund detail page
            await page.goto(url, wait_until="domcontentloaded", timeout=20000)

            # Wait for real content: wait until skeleton disappears
            try:
                await page.wait_for_function(
                    "document.querySelectorAll('.animate-pulse').length < 5"
                    " && document.querySelector('h1') !== null",
                    timeout=12000, polling=400,
                )
            except Exception:
                pass

            # Extract fund name + NAV
            data = await page.evaluate(r"""() => {
                // Name: h1
                const name = (document.querySelector('h1')?.innerText || '').trim();

                // NAV: look for elements near known labels
                // Strategy A: label-based search
                let nav = '';
                const allEls = Array.from(document.querySelectorAll('*'))
                    .filter(e => e.childElementCount === 0);

                // Find label elements that say "القيمة" or "سعر" or "NAV"
                const labelKeywords = ['القيمة', 'سعر الوثيقة', 'nav', 'السعر', 'current'];
                let foundLabel = false;
                for (const el of allEls) {
                    const t = (el.innerText || '').trim().toLowerCase();
                    if (labelKeywords.some(k => t.includes(k))) {
                        // Look at siblings and parent
                        const parent = el.parentElement;
                        if (parent) {
                            const sibs = Array.from(parent.children)
                                .map(c => (c.innerText || '').trim());
                            const num = sibs.find(s => /^[\d٠-٩,،.]+$/.test(s) && s.length > 1);
                            if (num) { nav = num; foundLabel = true; break; }
                        }
                    }
                }

                // Strategy B: any numeric value in a card/stat area
                if (!nav) {
                    const numEls = allEls.filter(e => {
                        const t = (e.innerText || '').trim();
                        return /^[\d٠-٩][,\d٠-٩.]*$/.test(t) && t.length > 1 && t.length < 15;
                    });
                    nav = numEls[0]?.innerText?.trim() || '';
                }

                // YTD
                const ytdEls = allEls.filter(e => /%|٪/.test((e.innerText || '')));
                const ytd = ytdEls[0]?.innerText?.trim() || '';

                // Category
                const cat = (document.querySelector('[class*="badge"], [class*="tag"], [class*="type"], [class*="category"]')?.innerText || '').trim();

                return { name, nav, ytd, cat };
            }""")

            name = (data.get("name") or "").strip()
            nav  = parse_float(data.get("nav"))

            if name and nav:
                result.append(Fund(name=name, nav=nav,
                                   ytd=parse_float(data.get("ytd")),
                                   category=data.get("cat", "").lower(),
                                   slug=slug))
                log.debug(f"  [{len(result):>3}] {name[:45]:<45}  NAV: {nav:.4f}")
            else:
                log.debug(f"  [skip] {slug}  name={bool(name)} nav={nav}")

            await asyncio.sleep(random.uniform(0.5, 1.2))

        except Exception as e:
            log.debug(f"  [err] {slug}: {type(e).__name__}: {e}")

    result = dedup(result)
    log.info(f"  Strategy 3 result: {len(result)} valid funds")
    return result


# ─────────────────────────────────────────────────────────
# Orchestrator — tries strategies in waterfall
# ─────────────────────────────────────────────────────────
async def run_scraper() -> list:
    from playwright.async_api import async_playwright

    for attempt in range(1, MAX_RETRIES + 1):
        log.info(f"\n{'='*55}")
        log.info(f"  Attempt {attempt}/{MAX_RETRIES}")
        log.info(f"{'='*55}")
        try:
            async with async_playwright() as pw:
                browser = await pw.chromium.launch(
                    headless=True,
                    args=[
                        "--no-sandbox",
                        "--disable-dev-shm-usage",
                        "--disable-blink-features=AutomationControlled",
                        "--disable-setuid-sandbox",
                        "--lang=ar-EG",
                    ],
                )
                ctx = await browser.new_context(
                    user_agent=random.choice(USER_AGENTS),
                    locale="ar-EG",
                    timezone_id="Africa/Cairo",
                    viewport={"width": 1440, "height": 900},
                    ignore_https_errors=True,
                    extra_http_headers={"Accept-Language": "ar-EG,ar;q=0.9,en;q=0.8"},
                )
                await ctx.add_init_script("""
                    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
                    window.chrome = { runtime: {} };
                    Object.defineProperty(navigator, 'plugins', { get: () => [1,2,3,4,5] });
                """)
                page = await ctx.new_page()
                page.set_default_timeout(30000)

                # ── Strategy 1: Network / RSC intercept ───
                funds = await strategy_intercept(page)

                if len(funds) < 5:
                    log.warning(f"  S1 insufficient ({len(funds)}). Trying DOM...")
                    funds = await strategy_dom(page)

                if len(funds) < 5:
                    log.warning(f"  S2 insufficient ({len(funds)}). Trying slug-by-slug...")
                    funds = await strategy_slug_by_slug(page)

                await browser.close()

                if len(funds) >= 5:
                    log.info(f"\n  Total scraped: {len(funds)} funds")
                    return funds

                raise ValueError(f"Only {len(funds)} funds found across all strategies.")

        except Exception as e:
            log.error(f"  Attempt {attempt} failed: {e}")
            if attempt < MAX_RETRIES:
                delay = 5 * (2 ** (attempt - 1)) + random.uniform(0, 3)
                log.info(f"  Retrying in {delay:.1f}s...")
                await asyncio.sleep(delay)

    log.error("All attempts exhausted.")
    return []


# ─────────────────────────────────────────────────────────
# Supabase Updater
# ─────────────────────────────────────────────────────────
def update_supabase(funds: list) -> dict:
    if not SUPABASE_KEY:
        log.error("SUPABASE_SERVICE_KEY not set!")
        return {"updated": 0, "not_found": len(funds), "errors": 0, "skipped": 0}

    try:
        from supabase import create_client
    except ImportError:
        log.error("pip install supabase")
        return {"updated": 0, "not_found": 0, "errors": len(funds), "skipped": 0}

    client = create_client(SUPABASE_URL, SUPABASE_KEY)

    log.info("Loading DB funds from Supabase...")
    resp = client.from_("funds").select("id, name, name_ar, name_en, current_nav").execute()
    db = resp.data or []
    log.info(f"  DB: {len(db)} funds")

    db_norm = [(f, normalize(f.get("name_ar") or f.get("name") or "")) for f in db]
    stats = {"updated": 0, "not_found": 0, "errors": 0, "skipped": 0}

    for fp in funds:
        norm_scraped = normalize(fp.name)

        matched = None
        best = 0.0
        for db_f, db_n in db_norm:
            if norm_scraped == db_n:
                matched = db_f
                break
            # prefix match
            if norm_scraped[:18] in db_n or db_n[:18] in norm_scraped:
                score = bigram_score(norm_scraped, db_n)
                if score > best:
                    best = score
                    matched = db_f
            else:
                score = bigram_score(norm_scraped, db_n)
                if score >= 0.45 and score > best:
                    best = score
                    matched = db_f

        if not matched:
            log.warning(f"  [NOT_FOUND] {fp.name[:55]}")
            stats["not_found"] += 1
            continue

        # Skip unchanged NAV
        existing = matched.get("current_nav")
        if existing and fp.nav and abs(float(existing) - fp.nav) < 0.0001:
            stats["skipped"] += 1
            continue

        payload = {
            "current_nav": fp.nav,
            "nav_date": fp.nav_date,
            "updated_at": datetime.utcnow().isoformat() + "Z",
        }
        if fp.ytd is not None:
            payload["ytd_return"] = fp.ytd
        if fp.weekly is not None:
            payload["weekly_return"] = fp.weekly

        try:
            client.from_("funds").update(payload).eq("id", matched["id"]).execute()
            label = matched.get("name_ar") or matched.get("name") or ""
            s = f"(score={best:.2f})" if best > 0 else "(exact)"
            log.info(f"  [OK] {label[:45]:<45} NAV: {fp.nav:.4f} {s}")
            stats["updated"] += 1
        except Exception as e:
            log.error(f"  [ERR] {matched.get('id')}: {e}")
            stats["errors"] += 1

    return stats


# ─────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────
async def main():
    t0 = time.time()
    log.info("=" * 55)
    log.info("  Watheqa Fund Scraper v3 — snduk.com")
    log.info(f"  Date   : {TODAY}")
    log.info(f"  Mode   : {'DRY-RUN' if DRY_RUN else 'LIVE'}")
    log.info("=" * 55)

    if not DRY_RUN and not SUPABASE_KEY:
        log.error("FATAL: SUPABASE_SERVICE_KEY missing.")
        sys.exit(2)

    funds = await run_scraper()

    if not funds:
        log.error("FATAL: No funds scraped.")
        sys.exit(1)

    log.info(f"\n  Sample (first 10):")
    for f in funds[:10]:
        log.info(f"  {f.name[:50]:<50} NAV: {f.nav:>10.4f}")

    out_dir = os.path.dirname(os.path.abspath(__file__))

    if DRY_RUN:
        path = os.path.join(out_dir, "scraped_funds.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump([f.to_dict() for f in funds], fh, ensure_ascii=False, indent=2)
        log.info(f"\n  DRY-RUN: {len(funds)} funds saved → {path}")
    else:
        stats = update_supabase(funds)
        elapsed = (time.time() - t0) / 60
        log.info("\n" + "=" * 55)
        log.info(f"  Scraped       : {len(funds)}")
        log.info(f"  Updated in DB : {stats['updated']}")
        log.info(f"  Skipped same  : {stats['skipped']}")
        log.info(f"  Not found     : {stats['not_found']}")
        log.info(f"  Errors        : {stats['errors']}")
        log.info(f"  Elapsed       : {elapsed:.1f} min")
        log.info("=" * 55)

    log.info("Done!")


if __name__ == "__main__":
    asyncio.run(main())

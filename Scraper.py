import os
import time
import random
import requests
from bs4 import BeautifulSoup
from markdownify import markdownify as md

API_URL = "https://warcraft.wiki.gg/api.php"
BASE_PAGE = "Patch_12.0.0/API_changes"
OUTPUT_DIR = "warcraft_api_markdown"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Track total 429 errors across the entire run
total_429_count = 0

# ---------------------------------------------------------
# FETCH PAGE HTML VIA MEDIAWIKI API (WITH COOLDOWN)
# ---------------------------------------------------------
def fetch_page_html(page_title, retries=5):
    global total_429_count

    params = {
        "action": "parse",
        "page": page_title,
        "prop": "text",
        "format": "json",
        "formatversion": "2",
    }

    for attempt in range(retries):
        try:
            print(f"Fetching page via API: {page_title}")
            response = requests.get(API_URL, params=params)

            # Handle rate limiting
            if response.status_code == 429:
                total_429_count += 1
                print(f"429 Too Many Requests (total so far: {total_429_count})")

                # If more than 5 total 429s → wait 30 minutes
                if total_429_count > 5:
                    print("Hit more than 5 total 429s. Cooling down for 30 minutes...")
                    time.sleep(30 * 60)  # 30 minutes
                    total_429_count = 0  # reset after cooldown

                wait = random.uniform(4, 8)
                print(f"Waiting {wait:.1f} seconds before retrying...")
                time.sleep(wait)
                continue

            # Handle temporary server overload
            if response.status_code == 503:
                wait = random.uniform(4, 8)
                print(f"503 Service Unavailable. Waiting {wait:.1f} seconds...")
                time.sleep(wait)
                continue

            response.raise_for_status()
            data = response.json()

            if "error" in data:
                print(f"API error for page '{page_title}': {data['error']}")
                return None

            html = data["parse"]["text"]

            # Normal polite delay
            time.sleep(random.uniform(2, 4))
            return html

        except requests.exceptions.RequestException as e:
            wait = random.uniform(4, 8)
            print(f"Error fetching page '{page_title}': {e}. Retrying in {wait:.1f} seconds...")
            time.sleep(wait)

    print(f"FAILED to fetch page '{page_title}' after {retries} attempts. Skipping.")
    return None

# ---------------------------------------------------------
# HELPERS
# ---------------------------------------------------------
def sanitize_filename_from_href(href: str) -> str:
    path = href.split("?", 1)[0].split("#", 1)[0]
    name = path.replace("/wiki/", "").strip("/")
    if not name:
        name = "index"
    return name + ".md"

def strip_navigation(soup):
    selectors = [
        "#mw-navigation",
        "#mw-panel",
        ".vector-header-container",
        ".vector-sticky-header",
        ".vector-page-toolbar",
        ".vector-page-titlebar",
        ".vector-footer",
        ".catlinks",
        ".printfooter",
        ".mw-editsection"
    ]
    for sel in selectors:
        for tag in soup.select(sel):
            tag.decompose()

def rewrite_internal_links(soup):
    for a in soup.find_all("a", href=True):
        href = a["href"]
        if href.startswith("/wiki/"):
            filename = sanitize_filename_from_href(href)
            a["href"] = filename

def extract_api_content(soup):
    content = []

    for table in soup.select("table"):
        content.append(str(table))

    for pre in soup.select("pre, code"):
        content.append(str(pre))

    for ul in soup.select("ul, dl"):
        content.append(str(ul))

    for p in soup.find_all("p"):
        if "API" in p.text or "function" in p.text or "C_" in p.text:
            content.append(str(p))

    return "\n".join(content)

def save_markdown(html, filename):
    markdown = md(html, heading_style="ATX")
    with open(os.path.join(OUTPUT_DIR, filename), "w", encoding="utf-8") as f:
        f.write(markdown)

# ---------------------------------------------------------
# MAIN SCRAPER USING MEDIAWIKI API
# ---------------------------------------------------------

# 1. Fetch main API changes page via API
main_html = fetch_page_html(BASE_PAGE)
if main_html is None:
    raise SystemExit("Could not fetch main API changes page via API. Exiting.")

main_soup = BeautifulSoup(main_html, "html.parser")

# 2. Find Global API section and its links
header = main_soup.find(id="Global_API")
if not header:
    raise Exception("Could not find the Global API section in main page HTML.")

section = header.find_next(["ul", "div"])
links = section.find_all("a", href=True)

# 3. Save main page content
main_soup_md = BeautifulSoup(main_html, "html.parser")
strip_navigation(main_soup_md)
rewrite_internal_links(main_soup_md)
api_html = extract_api_content(main_soup_md)
save_markdown(api_html, "API_changes.md")

# 4. Crawl linked pages via API
downloaded = set()

for link in links:
    href = link["href"]

    if href.startswith("/wiki/"):
        filename = sanitize_filename_from_href(href)
        filepath = os.path.join(OUTPUT_DIR, filename)

        # Skip if already cached
        if os.path.exists(filepath):
            print(f"Already scraped {filename}, skipping.")
            continue

        # Extract page title for API call
        page_title = href.replace("/wiki/", "").replace("_", " ").strip()

        if not page_title:
            continue

        if page_title in downloaded:
            continue
        downloaded.add(page_title)

        print(f"Downloading page via API: {page_title}")

        html = fetch_page_html(page_title)
        if html is None:
            print(f"Skipping broken or unreachable page: {page_title}")
            continue

        soup_md = BeautifulSoup(html, "html.parser")
        strip_navigation(soup_md)
        rewrite_internal_links(soup_md)
        api_html = extract_api_content(soup_md)

        save_markdown(api_html, filename)

print("Done! Markdown files saved in:", OUTPUT_DIR)

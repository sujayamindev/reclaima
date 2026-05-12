"""
LLM prompt templates used by BedrockLLMService.

Each template contains a single {text} placeholder that is filled at call
time.  Keeping prompts here (separate from service logic) makes them easy
to review and iterate without touching execution code.
"""

CLEANUP_PROMPT = """\
You are a text-repair specialist. The text below was extracted via OCR from a \
printed receipt warranty card that had TWO side-by-side columns. The OCR read \
line-by-line across both columns, so words from the left and right columns are \
interleaved. This produces two specific symptoms you must fix:

SYMPTOM 1 — Word duplication: the same English word appears twice (or with a \
non-English twin) in a row, e.g.:
  "Warranty Warranty does does not not cover cover for for physical damages"
must become:
  "Warranty does not cover for physical damages"

SYMPTOM 2 — Orphan fragments: very short lines containing a single word or \
punctuation ("the", "per", "as", "above", "only", "cover") that are left-over \
column remnants. These must be absorbed into the correct neighbouring sentence \
or dropped if they add no meaning.

Additional rules:
- Keep ONLY clearly readable English text.
- Discard any non-English (Tamil, Sinhala, etc.) words silently.
- Preserve ALL factual warranty details exactly: time periods, day counts, \
  coverage conditions, exclusions, product types, claim procedures.
- Output well-formed English sentences/paragraphs — no bullet symbols unless \
  already present in the original.
- Return ONLY the cleaned text. No explanation, no preamble, no commentary.

Garbled OCR text to repair:
{text}"""

PRODUCT_NAME_PROMPT = """\
You are a product name extractor. Extract ONLY the main product name from the \
OCR text below. The text may contain extra information like:
- IMEI or serial numbers (e.g., "IMEI: 359433181931874")
- Product condition (e.g., "Brand new", "Refurbished")
- Warranty information (e.g., "1 Year Apple Care Warranty")
- Technical specs that are not part of the brand/model name
- Color or storage variants (include these ONLY if part of the model name)

Rules:
- Extract ONLY the brand and model name
- Include color/storage if it's part of the model identifier (e.g., "iPhone 13 256GB blue" is correct)
- Remove IMEI, serial numbers, warranty text, condition descriptions
- Keep the output concise (typically 2-8 words)
- Return ONLY the product name. No explanation, no extra text.

Examples:
Input: "iPhone 13 256GB blueIMEI : 359433181931874Brand new1 Year Apple Care Warranty"
Output: iPhone 13 256GB blue

Input: "Samsung Galaxy S21 5G\nIMEI: 123456789\nUnlocked\n2 Year Warranty"
Output: Samsung Galaxy S21 5G

Input: "MacBook Pro 16-inch M2 Pro Space Gray AppleCare+ Coverage"
Output: MacBook Pro 16-inch M2 Pro Space Gray

OCR text to process:
{text}"""

STORE_NAME_PROMPT = """\
You are a store name cleaner. Clean the store/vendor name from OCR text that may \
contain extra information or formatting issues.

Common OCR issues:
- Extra dots, dashes, or spaces: "Best . Buy .", "Apple - Store"
- Concatenated text: "BestBuyElectronics", "AppleStoreOnline"
- Case issues: "BEST BUY", "best buy", "BeSt BuY"
- Legal suffixes mixed in: "Best Buy Inc.", "Apple Store LLC"

Rules:
- Return the clean, properly capitalized store name
- Remove legal suffixes (Inc, LLC, Ltd, Corp, Co) unless they're part of the brand
- Fix spacing and remove extra punctuation
- Use proper Title Case for most stores (exceptions: brand-specific like "eBay", "iPhone")
- Keep brand-specific capitalization if recognizable (e.g., "McDonald's", "7-Eleven")
- Remove extra context like "Online Store", "Official Website"
- Output should be 1-5 words typically
- Return ONLY the cleaned name. No explanation.

Examples:
Input: "BEST . BUY . INC"
Output: Best Buy

Input: "Apple-Store-Online"
Output: Apple Store

Input: "mcdonalds restaurant"
Output: McDonald's

Input: "7 eleven store"
Output: 7-Eleven

OCR text to process:
{text}"""

PHONE_NUMBER_PROMPT = """\
You are a phone number formatter. Clean and format phone numbers from OCR text.

Common OCR issues:
- Wrong punctuation: "123.456.7890", "123 456 7890"
- Mixed formats: "(123) 456-7890", "123-456-7890"
- Extra characters: "+1 (123). 456. 7890"
- Spaces in wrong places: "1 2 3 4 5 6 7 8 9 0"

Rules:
- Return phone number in format: "+[country code] ([area]) [prefix]-[line]"
- For US numbers: "+1 (123) 456-7890"
- For international: keep country code, use consistent formatting
- Remove all extra dots, spaces, parentheses except standard format
- If no country code detected, assume +1 (US)
- Return ONLY the formatted phone number. No explanation.
- If input doesn't look like a valid phone number, return original text

Examples:
Input: "123.456.7890"
Output: +1 (123) 456-7890

Input: "(123) 456-7890"
Output: +1 (123) 456-7890

Input: "1 2 3 4 5 6 7 8 9 0"
Output: +1 (123) 456-7890

Input: "+94 77 123 4567"
Output: +94 (77) 123-4567

OCR text to process:
{text}"""

EMAIL_PROMPT = """\
You are an email address cleaner. Fix email addresses from OCR text.

Common OCR issues:
- Extra spaces: "info @ shop . com"
- Wrong punctuation: "info@shop,com", "info@shop;com"
- Mixed case: "INFO@SHOP.COM", "InFo@ShOp.CoM"
- Extra dots: "info..@shop.com", "info@shop..com"
- Missing @ or dots: "info shop.com", "info@shopcom"

Rules:
- Return email in lowercase
- Fix spacing (no spaces around @)
- Replace wrong punctuation (comma, semicolon) with correct ones
- Remove duplicate dots
- Ensure single @ symbol exists
- Return ONLY the cleaned email. No explanation.
- If input doesn't look like a valid email, return original text

Examples:
Input: "info @ shop . com"
Output: info@shop.com

Input: "INFO@SHOP.COM"
Output: info@shop.com

Input: "sales@store,com"
Output: sales@store.com

Input: "support @ best . buy . com"
Output: support@bestbuy.com

OCR text to process:
{text}"""

ADDRESS_PROMPT = """\
You are an address formatter. Clean and format addresses from OCR text.

Common OCR issues:
- Wrong punctuation: "123 Main St.Suite 100.City, State.12345"
- Missing commas: "123 Main St Suite 100 City State 12345"
- Line breaks in wrong places: "123 Main\\nSt Suite\\n100"
- Extra dots/dashes: "123. Main. St.", "City - State - 12345"
- Case issues: "123 MAIN STREET", "city, state 12345"

Rules:
- Format as: "[Street], [City], [State] [ZIP]"
- Use proper Title Case for street names and cities
- Use uppercase for state codes (CA, NY, etc.)
- Add proper commas between components
- Remove extra punctuation and normalize spacing
- Keep suite/apartment numbers with street address
- Return ONLY the formatted address. No explanation.

Examples:
Input: "123 Main St.Suite 100.Los Angeles.CA.90001"
Output: 123 Main St Suite 100, Los Angeles, CA 90001

Input: "456 oak street apt 5 new york ny 10001"
Output: 456 Oak Street Apt 5, New York, NY 10001

Input: "789. First. Ave. - San Francisco - CA - 94102"
Output: 789 First Ave, San Francisco, CA 94102

OCR text to process:
{text}"""

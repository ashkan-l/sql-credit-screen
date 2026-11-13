# Agribusiness Credit Screen (SQL)

Credit screen of 12 agribusiness and food companies using SEC financial statement data and MySQL.

> **Status:** In progress. Data loaded and cleaned, peer group selected, latest 10-K identified, financials pivoted (Steps 1-6); ratio analysis next.

## Data source

[SEC Financial Statement Data Sets](https://www.sec.gov/data-research/sec-markets-data/financial-statement-data-sets): quarterly, tab-delimited extracts of the XBRL financial data in every 10-K and 10-Q filed with the SEC. Each quarter has:

- `sub.txt`: one row per filing (company, form type, fiscal period, filing date)
- `num.txt`: one row per reported number (XBRL tag, date, value)

Quarters used: **2025q4, 2026q1, 2026q2, 2026q3**. The raw files are excluded from the repo (`data/` is in `.gitignore`) because of their size.

## Tools

- **MySQL 9.3** (Community Server) with **MySQL Workbench 8.0** for all SQL
- **GitHub Desktop** for version control
- **VS Code** for documentation

## Pipeline

| Script | What it does |
|---|---|
| `sql/01_tables.sql` | Creates the raw landing tables `raw_sub` and `raw_num` (all text, so no value can break the load) |
| `sql/02_load.sql` | Loads each quarter with `LOAD DATA LOCAL INFILE` and tags every row with `src_quarter` |
| `sql/03_clean.sql` | Builds typed tables `sub` (10-K and 10-K/A filings only, real dates) and `num` (USD values, company-wide totals only, numbers as `DECIMAL(28,4)`), with indexes on the join keys |
| `sql/04_peers.sql` | Finds candidate companies with a `REGEXP` name search, then hard-codes the verified 12-company peer group in `peers` (keyed by SEC CIK) |
| `sql/05_latest.sql` | View `latest_10k`: each company's most recent 10-K, picked with `ROW_NUMBER() OVER (PARTITION BY cik ORDER BY period DESC, filed DESC)` |
| `sql/06_facts.sql` | Views `facts_long` and `facts`: pivots XBRL tags from long format (one row per number) to wide format (one row per company and date) with conditional aggregation (`MAX(CASE WHEN ...)`); `COALESCE` picks the first available tag when companies report the same item under different names |

## Peer group

12 U.S.-listed companies across the agribusiness and food value chain, from farm inputs to the grocery shelf:

| Segment | Companies (ticker, SEC CIK) |
|---|---|
| Seeds & crop protection | Corteva (CTVA, 1755672) |
| Fertilizer | CF Industries (CF, 1324404), Mosaic (MOS, 1285785) |
| Ag equipment | Deere & Co (DE, 315189) |
| Grain & processing | Archer-Daniels-Midland (ADM, 7084), Bunge Global (BG, 1996862) |
| Food ingredients | Ingredion (INGR, 1046257) |
| Protein | Tyson Foods (TSN, 100493), Hormel Foods (HRL, 48465) |
| Packaged food | General Mills (GIS, 40704), Kraft Heinz (KHC, 1637459), Conagra Brands (CAG, 23217) |

**How the peers were selected:** a name search on the 10-K filings returned 14 candidates, which were checked by hand and matched by CIK rather than name. Two false matches were excluded:

- **John Deere Capital Corp** (CIK 27673): Deere's captive finance subsidiary, which files its own 10-K. Including it would double-count Deere's financing debt.
- **Mosaic ImmunoEngineering** (CIK 836564): an unrelated biotech company that shares the "Mosaic" name.

### Latest annual report used

All 12 companies have a 10-K in the loaded quarters. Fiscal year-ends differ, so the screen compares each company's most recent full fiscal year rather than one calendar date:

| Ticker | Fiscal year ended | 10-K filed |
|---|---|---|
| ADM | 2025-12-31 | 2026-02-17 |
| BG | 2025-12-31 | 2026-02-19 |
| CAG | 2026-05-31 | 2026-07-15 |
| CF | 2025-12-31 | 2026-02-25 |
| CTVA | 2025-12-31 | 2026-02-12 |
| DE | 2025-10-31 | 2025-12-18 |
| GIS | 2026-05-31 | 2026-07-01 |
| HRL | 2025-10-31 | 2025-12-05 |
| INGR | 2025-12-31 | 2026-02-17 |
| KHC | 2025-12-31 | 2026-02-12 |
| MOS | 2025-12-31 | 2026-02-27 |
| TSN | 2025-09-30 | 2025-11-10 |

## Load validation

Row counts in MySQL after loading, checked against the line counts of the source files (minus the header row):

| Quarter | raw_sub | raw_num |
|---|---:|---:|
| 2025q4 | 6,304 | 3,832,977 |
| 2026q1 | 6,169 | 3,690,955 |
| 2026q2 | 7,714 | 3,608,711 |
| 2026q3 | 6,516 | 3,905,397 |
| **Total** | **26,703** | **15,038,040** |

After cleaning (`sql/03_clean.sql`):

| Table | Rows | What was kept |
|---|---:|---|
| `sub` | 5,709 | Annual reports (10-K, 10-K/A) out of 26,703 filings |
| `num` | 1,293,397 | USD values from those filings, excluding segment and co-registrant breakdowns (from 15,038,040 raw rows) |

## Data notes

- SEC `num.txt` files for 2026q2 and 2026q3 contain 34 rows (from 3 investment-fund filings) with a stray tab inside the `segments` field. MySQL truncated these rows on load (warning 1262). They stay in `raw_num` and are removed in `sql/03_clean.sql`, which keeps only rows with an empty `segments` value (company-wide totals). None belong to the companies in the screen.
- 2025q4 `sub.txt` was accidentally loaded more than once, so `raw_sub` held duplicate filings. The duplicates were caught when adding the primary key on `adsh` to `sub` (MySQL error 1062, duplicate entry). The fix: delete that quarter (`DELETE FROM raw_sub WHERE src_quarter = '2025q4'`), reload it once, recheck the row counts against the source files, then rebuild `sub` and `num`. The primary key now guarantees one row per filing.

- **Tag coverage after the first pivot (`06_facts.sql`):** for the latest fiscal year, several fields are blank because companies report them under tags not yet mapped. Blank: EBIT for ADM, BG, CTVA and DE; interest expense for CAG, CTVA, GIS, INGR and MOS; revenue for HRL and KHC; D&A for HRL and TSN; equity for ADM and CAG; net income and cash for CF; non-current long-term debt for 6 of 12; current assets and liabilities for DE (Deere does not present a classified balance sheet). These are investigated and mapped in `sql/07_qa.sql`.

## Lessons learned

- **Validate every load against the source.** Comparing row counts with the files' line counts is what made the duplicate load easy to diagnose and confirm fixed.
- **Let constraints catch errors.** The primary key on `sub` stopped duplicate data before it could double-count any figures in the ratios.
- **Match entities by ID, not by name.** A name search is a starting point; the CIK is the reliable key. Two of the 14 name matches were the wrong companies.
- **A typo in a filter is silent.** A misspelled XBRL tag matches nothing and returns NULL instead of an error, so every pivoted column is checked for gaps before ratios are calculated.
- **Make loads safe to rerun.** Running `LOAD DATA` twice appends a second copy. Delete a quarter's rows (by `src_quarter`) before reloading it.

## How to reproduce

1. Download the four quarterly ZIPs from the SEC link above and unzip each into its own folder: `data/2025q4/`, `data/2026q1/`, and so on.
2. In MySQL Workbench, create a schema `credit_screen`, enable `local_infile`, and add `OPT_LOCAL_INFILE=1` to the connection's Advanced settings.
3. Open and run the scripts in `sql/` in numerical order. Each one runs top to bottom with Cmd+Shift+Enter.
4. Compare your row counts with the Load validation table.

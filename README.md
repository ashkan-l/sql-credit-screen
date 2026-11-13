# Agribusiness Credit Screen (SQL)

Credit screen of 12 agribusiness and food companies using SEC financial statement data and MySQL.

> **Status:** In progress. Pipeline complete through the peer screen and CSV export (Steps 1-10). Results are provisional until the remaining XBRL tags are mapped in `06_facts.sql`; the credit memo comes after that.

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
| `sql/07_qa.sql` | Data quality checks: counts missing fields per company (`SUM(column IS NULL)`) and lists the tags a company actually uses (`LIKE` search on `facts_long`), so missing tags can be added to `06_facts.sql` |
| `sql/08_ratios.sql` | View `ratios`: a CTE (`WITH base AS ...`) derives total debt and EBITDA, then calculates eight credit ratios; `NULLIF(x, 0)` turns a zero denominator into NULL so no ratio divides by zero |
| `sql/09_screen.sql` | View `screen`: one row per company for its latest fiscal year. `LAG()` with a named `WINDOW` gives revenue growth and the change in leverage, peer medians are calculated by hand with `ROW_NUMBER()` and `COUNT(*) OVER ()`, `RANK()` and `NTILE(4)` rank the peers, and a `CASE` expression assigns a red, amber or green credit flag |
| `sql/10_export.sql` | Segment summary (average leverage and coverage by segment, `GROUP BY segment`), and the queries whose results are exported to `output/` |

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

## Credit ratios

Defined in `sql/08_ratios.sql`, calculated for every company and fiscal year:

| Ratio | Formula | What it shows |
|---|---|---|
| Current ratio | current assets / current liabilities | Short-term liquidity |
| Debt / equity | total debt / equity | Balance-sheet leverage |
| Debt / EBITDA | total debt / EBITDA | Years of earnings needed to repay debt |
| Net debt / EBITDA | (total debt - cash) / EBITDA | The same, after using cash on hand |
| Interest coverage | EBIT / interest expense | How easily earnings pay interest |
| EBITDA margin | EBITDA / revenue | Operating profitability |
| ROE | net income / equity | Return to shareholders |
| CFO / debt | operating cash flow / total debt | Cash generation relative to debt |

Total debt = non-current long-term debt + current portion of long-term debt + short-term borrowings. EBITDA = EBIT + depreciation and amortization.

## Peer screen

`sql/09_screen.sql` compares each company's latest fiscal year with the peer group:

- **Trend:** revenue growth and the change in Debt/EBITDA versus the prior year, using `LAG()`.
- **Peer medians** for Debt/EBITDA and interest coverage. MySQL has no `MEDIAN()` function, so the values are numbered in order and the median is the average of the middle one or two rows (`FLOOR` and `CEIL` of `(count + 1) / 2`).
- **Rankings:** `leverage_rank` (1 = most levered) and `coverage_quartile` (1 = weakest coverage).
- **Credit flag**, using thresholds common in bank loan covenants:

| Flag | Rule |
|---|---|
| RED - negative EBITDA | EBITDA is zero or negative (checked first, because a negative Debt/EBITDA would otherwise look like low leverage) |
| GREY - insufficient data | Debt/EBITDA or interest coverage is missing |
| RED - likely covenant pressure | Debt/EBITDA above 4.0x, or interest coverage below 2.0x |
| AMBER - watch list | Debt/EBITDA above 3.0x, or interest coverage below 4.0x |
| GREEN - comfortable | None of the above |

### First results (provisional)

From `output/credit_screen_latest.csv`. Peer medians: Debt/EBITDA 0.44x, interest coverage 5.83x.

| Ticker | Fiscal year | Revenue growth | Debt/EBITDA | Interest coverage | Flag |
|---|---|---:|---:|---:|---|
| HRL | 2025-10-31 | – | 3.98x | 9.21x | AMBER |
| TSN | 2025-09-30 | 2.1% | 0.83x | 2.45x | AMBER |
| CF | 2025-12-31 | 19.3% | 1.01x | 14.84x | GREEN |
| KHC | 2025-12-31 | – | 0.00x | -4.93x | RED (negative EBITDA) |
| CAG | 2026-05-31 | -2.9% | -0.03x | – | RED (negative EBITDA) |
| INGR, GIS, MOS, ADM, BG, CTVA, DE | | | | | GREY |

These are not yet a credit view. Seven of 12 companies are GREY, and the medians are pulled down by debt that is not mapped yet (Kraft Heinz and Mosaic show 0.00x). The screen updates automatically once the tags in Data notes are added to `06_facts.sql`, because every later step is a view.

## Validation

Spot-check of the `facts` view against the filed 10-Ks on SEC EDGAR, for the latest fiscal year ($ millions):

| Company | Line item (as printed in the 10-K) | 10-K | `facts` view | Match |
|---|---|---:|---:|:---:|
| ADM (FY ended 2025-12-31, [10-K](https://www.sec.gov/Archives/edgar/data/7084/000000708426000011/)) | Revenues | 80,269 | 80,269 | ✓ |
| | Net Earnings Attributable to Controlling Interests | 1,078 | 1,078 | ✓ |
| | Total Assets | 52,389 | 52,389 | ✓ |
| Deere (FY ended 2025-11-02, [10-K](https://www.sec.gov/Archives/edgar/data/315189/000110465925122321/)) | Net sales and revenues | 45,684 | 45,684 | ✓ |
| | Net Income Attributable to Deere & Company | 5,027 | 5,027 | ✓ |
| | Total Assets | 105,996 | 105,996 | ✓ |

What the check showed:

- **Net income is the parent's share.** The `NetIncomeLoss` tag is net income attributable to the company, not the total including non-controlling interests. For Deere the total is $4,998M and the parent's share is $5,027M; the screen uses the parent's share.
- **SEC rounds dates to month-end.** Deere's fiscal year ended on November 2, 2025 (a 52/53-week year), but the data sets store it as `20251031`.
- **A blank can hide a reported number.** ADM's balance sheet shows Total Shareholders' Equity of $22,740M, yet `equity` is NULL for ADM, because ADM tags it under a different element (equity including non-controlling interests). Gaps like this are mapped in `sql/07_qa.sql`.

## Data notes

- SEC `num.txt` files for 2026q2 and 2026q3 contain 34 rows (from 3 investment-fund filings) with a stray tab inside the `segments` field. MySQL truncated these rows on load (warning 1262). They stay in `raw_num` and are removed in `sql/03_clean.sql`, which keeps only rows with an empty `segments` value (company-wide totals). None belong to the companies in the screen.
- 2025q4 `sub.txt` was accidentally loaded more than once, so `raw_sub` held duplicate filings. The duplicates were caught when adding the primary key on `adsh` to `sub` (MySQL error 1062, duplicate entry). The fix: delete that quarter (`DELETE FROM raw_sub WHERE src_quarter = '2025q4'`), reload it once, recheck the row counts against the source files, then rebuild `sub` and `num`. The primary key now guarantees one row per filing.

- **Tag coverage after the first pivot (`06_facts.sql`):** for the latest fiscal year, several fields are blank because companies report them under tags not yet mapped. Blank: EBIT for ADM, BG, CTVA and DE; interest expense for CAG, CTVA, GIS, INGR and MOS; revenue for HRL and KHC; D&A for HRL and TSN; equity for ADM and CAG; net income and cash for CF; non-current long-term debt for 6 of 12; current assets and liabilities for DE (Deere does not present a classified balance sheet). These are investigated and mapped in `sql/07_qa.sql`.

- **Ratios are provisional until the tags are mapped.** The first run of `ratios` showed why: `total_debt` adds its parts with `COALESCE(x, 0)`, so a debt tag that is not mapped counts as zero instead of NULL. Kraft Heinz and Mosaic came out with zero debt, although their 10-Ks report $19.3B and $4.3B of long-term debt. Interest coverage, debt/EBITDA and EBITDA margin were also blank for ADM, BG, CTVA and DE, because their EBIT is not mapped yet. The tags each company actually uses were found with the `07_qa.sql` queries:

  | Field | Unmapped tag found | Companies |
  |---|---|---|
  | revenue | `RevenueFromContractWithCustomerIncludingAssessedTax` | HRL, KHC |
  | ebit | `IncomeLossFromContinuingOperationsBeforeIncomeTaxes...` (pre-tax income, a proxy) | ADM, BG, CTVA, DE |
  | interest_expense | `InterestAndDebtExpense`; `InterestIncomeExpenseNet` / `...NonoperatingNet` (net, sign reversed); `FinancingCostsNet` | CTVA; CAG, MOS, GIS; INGR |
  | d_and_a | `Depreciation` + `AdjustmentForAmortization` | HRL, TSN |
  | net_income | `ProfitLoss` less `NetIncomeLossAttributableToNoncontrollingInterest` | CF |
  | equity | `StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest` | ADM, CAG |
  | cash | `CashCashEquivalentsRestrictedCashAndRestrictedCashEquivalents` | CF |
  | ltd_noncurrent | `LongTermDebtAndCapitalLeaseObligations`; `LongTermDebtAndFinanceLeasesNoncurrent`; `SeniorLongTermNotes` | CTVA, GIS, KHC, MOS, TSN; DE; CAG |
  | ltd_current | `LongTermDebtAndCapitalLeaseObligationsCurrent` | CAG, GIS, KHC, MOS |

- **First run of the screen: two logic problems found and fixed** (the SQL ran without errors, so both were found by checking the output):
  - **Wrong "latest year" for some companies.** A 10-K contains numbers for dates other than the fiscal year-ends, such as quarterly figures and subsequent events. Corteva's latest row was 2026-01-31, a date after its fiscal year with almost no data. For General Mills, Ingredion, Bunge and Kraft Heinz, the "prior year" used by `LAG()` was a quarter-end, so revenue growth came out blank. Fixed by keeping only the fiscal year-end and the two years before it in `facts_long`: `WHERE n.ddate IN (l.period, l.period - INTERVAL 1 YEAR, l.period - INTERVAL 2 YEAR)`. `ratios` now has 36 rows (12 companies x 3 years) instead of 75, and every company's latest year matches its 10-K.
  - **Missing data was flagged GREEN.** A comparison with NULL is neither true nor false, so a company with no Debt/EBITDA or interest coverage fell through to the `ELSE` branch. ADM, Bunge, Corteva and Deere were GREEN only because their ratios were blank, and Conagra's negative EBITDA gave a negative Debt/EBITDA that passed as low leverage. Fixed with two new branches at the top of the `CASE`: RED for EBITDA zero or below, and GREY when either ratio is missing.
- **The oldest year is incomplete.** A 10-K shows three years of income statement but only two balance sheets, so the earliest year in `ratios` has no balance sheet values (for example, ADM 2023 shows total debt 0). Only the latest year and the change from the prior year are used in the screen.

## Lessons learned

- **Validate every load against the source.** Comparing row counts with the files' line counts is what made the duplicate load easy to diagnose and confirm fixed.
- **Let constraints catch errors.** The primary key on `sub` stopped duplicate data before it could double-count any figures in the ratios.
- **Match entities by ID, not by name.** A name search is a starting point; the CIK is the reliable key. Two of the 14 name matches were the wrong companies.
- **A typo in a filter is silent.** A misspelled XBRL tag matches nothing and returns NULL instead of an error, so every pivoted column is checked for gaps before ratios are calculated.
- **Zero is not the same as unknown.** `COALESCE(x, 0)` is right for adding optional pieces of a total, but it turns a missing value into a believable wrong number (zero debt). Missing inputs should stay NULL until they are mapped.
- **No error does not mean a correct result.** Several of the worst mistakes in this project ran without an error: a misspelled tag, a missing value counted as zero, a NULL that fell through to GREEN. Each result was checked against the source data or the filings.
- **Make loads safe to rerun.** Running `LOAD DATA` twice appends a second copy. Delete a quarter's rows (by `src_quarter`) before reloading it.

## How to reproduce

1. Download the four quarterly ZIPs from the SEC link above and unzip each into its own folder: `data/2025q4/`, `data/2026q1/`, and so on.
2. In MySQL Workbench, create a schema `credit_screen`, enable `local_infile`, and add `OPT_LOCAL_INFILE=1` to the connection's Advanced settings.
3. Open and run the scripts in `sql/` in numerical order. Each one runs top to bottom with Cmd+Shift+Enter.
4. Compare your row counts with the Load validation table.
5. Export the `screen` and `ratios` views from the result grid (Export button, CSV) to `output/credit_screen_latest.csv` and `output/ratios_all_years.csv`.

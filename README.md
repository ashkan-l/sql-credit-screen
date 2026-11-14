# Agribusiness Credit Screen (SQL)

A credit screen of 12 U.S. agribusiness and food companies, from fertilizer and seeds to packaged food, built in MySQL from the SEC's raw XBRL financial statement data. It loads 15 million rows of SEC data, pivots each company's latest 10-K into a financial table, calculates eight credit ratios, and flags each company red, amber or green against loan-covenant thresholds.

> **Status:** SQL pipeline complete (Steps 1-10). Credit memo in progress (`memo/`).

## Key findings

Latest fiscal year for each company. Peer medians: **Debt/EBITDA 2.81x**, **interest coverage 2.25x**.

| Rank | Company | Segment | Revenue growth | Debt/EBITDA | Interest coverage | Current ratio | Flag |
|---:|---|---|---:|---:|---:|---:|---|
| 1 | General Mills (GIS) | Packaged food | -5.4% | 9.39x | 1.64x | 0.68 | RED - covenant pressure |
| 2 | Bunge (BG) | Grain & processing | +32.4% | 7.65x | 1.81x | 1.61 | RED - covenant pressure |
| 3 | Deere (DE) | Ag equipment | -11.7% | 6.76x | 1.97x | – | RED - covenant pressure |
| 4 | Tyson Foods (TSN) | Protein | +2.1% | 3.59x | 2.45x | 1.55 | AMBER |
| 5 | ADM | Grain & processing | -6.2% | 3.45x | 2.05x | 1.37 | AMBER |
| 6 | Hormel Foods (HRL) | Protein | +1.6% | 2.91x | 9.21x | 2.47 | GREEN |
| 7 | Mosaic (MOS) | Fertilizer | +8.4% | 2.70x | 4.38x | 1.32 | GREEN |
| 8 | Ingredion (INGR) | Food ingredients | -2.8% | 1.45x | 27.46x | 2.66 | GREEN |
| 9 | CF Industries (CF) | Fertilizer | +19.3% | 1.01x | 14.84x | 3.37 | GREEN |
| 10 | Corteva (CTVA) | Seeds & crop protection | +2.9% | 0.89x | 9.38x | 1.43 | GREEN |
| – | Kraft Heinz (KHC) | Packaged food | -3.5% | n/m | -4.93x | 1.15 | RED - negative EBITDA |
| – | Conagra (CAG) | Packaged food | -2.9% | n/m | -4.26x | 0.90 | RED - negative EBITDA |

Rank 1 = most levered. n/m = not meaningful (EBITDA is negative). Full output: [`output/credit_screen_latest.csv`](output/credit_screen_latest.csv) and, for all three years, [`output/ratios_all_years.csv`](output/ratios_all_years.csv).

**What the numbers say, and where they need judgement:**

- **Packaged food is under the most pressure.** All three packaged-food companies are RED. Kraft Heinz and Conagra show negative EBITDA, and General Mills has the highest leverage in the group. Much of this comes from **non-cash write-downs** of goodwill and brand values: $9.3B at Kraft Heinz, $3.0B at Conagra, and $2.9B of restructuring and impairment charges at General Mills (from the XBRL impairment tags). Adding these back, as credit analysts usually do, gives Debt/EBITDA of about 3.8x for Kraft Heinz, 4.2x for Conagra and 3.1x for General Mills. That is still the most levered segment, but not distressed. The write-downs signal that these brands are worth less than was paid for them, which is a real credit concern in itself.
- **Bunge's leverage jumped from about 3.1x to 7.7x in one year.** Revenue grew 32% and Bunge spent $4.2B on acquisitions, so the debt arrived before a full year of the acquired earnings.
- **Deere's ratio overstates its risk.** Most of Deere's $57B of debt funds John Deere Financial, which lends to customers buying Deere equipment. That debt is backed by loans to customers, not by Deere's own operating earnings, so analysts assess Deere's equipment business separately. Deere also has no current ratio, because it does not split its balance sheet into current and non-current.
- **Fertilizer and seeds are the strongest.** CF Industries, Corteva and Ingredion have leverage near 1x and interest covered 9-27 times over.

### By segment

From `sql/10_export.sql`. Negative-EBITDA companies are left out of the leverage average.

| Segment | Companies | Avg Debt/EBITDA | Avg interest coverage |
|---|---:|---:|---:|
| Packaged food | 3 | 9.39x (GIS only) | -2.5x |
| Ag equipment | 1 | 6.76x | 2.0x |
| Grain & processing | 2 | 5.55x | 1.9x |
| Protein | 2 | 3.25x | 5.8x |
| Fertilizer | 2 | 1.86x | 9.6x |
| Food ingredients | 1 | 1.45x | 27.5x |
| Seeds & crop protection | 1 | 0.89x | 9.4x |

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

| Script | What it does | SQL techniques |
|---|---|---|
| `sql/01_tables.sql` | Creates the raw landing tables `raw_sub` and `raw_num`, all text so no value can break the load | DDL |
| `sql/02_load.sql` | Loads each quarter and tags every row with `src_quarter` | `LOAD DATA LOCAL INFILE` |
| `sql/03_clean.sql` | Builds typed tables `sub` (10-K and 10-K/A only, real dates) and `num` (USD, company-wide totals only, `DECIMAL(28,4)`), with a primary key and indexes on the join keys | `CREATE TABLE ... AS SELECT`, `STR_TO_DATE`, constraints |
| `sql/04_peers.sql` | Finds candidate companies by name, then hard-codes the verified 12-company peer group, keyed by SEC CIK | `REGEXP` |
| `sql/05_latest.sql` | View `latest_10k`: each company's most recent 10-K | `ROW_NUMBER() OVER (PARTITION BY ...)` |
| `sql/06_facts.sql` | Views `facts_long` and `facts`: pivot from one row per number to one row per company and year, keeping the fiscal year-end and the two years before it | Conditional aggregation (`MAX(CASE WHEN ...)`), `COALESCE` across alternative tags, date arithmetic |
| `sql/07_qa.sql` | Data quality checks: missing fields per company, and the tags a company actually uses | `SUM(column IS NULL)`, `LIKE` |
| `sql/08_ratios.sql` | View `ratios`: total debt, EBITDA and eight credit ratios for every company and year | CTE, `NULLIF` to avoid division by zero |
| `sql/09_screen.sql` | View `screen`: latest year per company, trend, peer medians, rankings and credit flag | `LAG()` with a named `WINDOW`, hand-built median, `RANK()`, `NTILE()`, `CASE` |
| `sql/10_export.sql` | Segment summary and the queries exported to `output/` | `GROUP BY`, conditional `AVG` and `COUNT` |

## Peer group

| Segment | Companies (ticker, SEC CIK) |
|---|---|
| Seeds & crop protection | Corteva (CTVA, 1755672) |
| Fertilizer | CF Industries (CF, 1324404), Mosaic (MOS, 1285785) |
| Ag equipment | Deere & Co (DE, 315189) |
| Grain & processing | Archer-Daniels-Midland (ADM, 7084), Bunge Global (BG, 1996862) |
| Food ingredients | Ingredion (INGR, 1046257) |
| Protein | Tyson Foods (TSN, 100493), Hormel Foods (HRL, 48465) |
| Packaged food | General Mills (GIS, 40704), Kraft Heinz (KHC, 1637459), Conagra Brands (CAG, 23217) |

**How the peers were selected:** a name search on the 10-K filings returned 14 candidates, which were checked by hand and matched by CIK rather than by name. Two were excluded:

- **John Deere Capital Corp** (CIK 27673): Deere's finance subsidiary, which files its own 10-K. Including it would count Deere's financing debt twice.
- **Mosaic ImmunoEngineering** (CIK 836564): an unrelated biotech company that shares the "Mosaic" name.

### Latest annual report used

Fiscal year-ends differ, so the screen compares each company's most recent full fiscal year rather than one calendar date:

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

## Method

### Credit ratios (`08_ratios.sql`)

| Ratio | Formula | What it shows |
|---|---|---|
| Current ratio | current assets / current liabilities | Can the company pay bills due within a year? |
| Debt / equity | total debt / equity | Balance-sheet leverage |
| Debt / EBITDA | total debt / EBITDA | Roughly how many years of earnings it would take to repay the debt |
| Net debt / EBITDA | (total debt - cash) / EBITDA | The same, after using cash on hand |
| Interest coverage | EBIT / interest expense | How many times earnings cover the interest bill |
| EBITDA margin | EBITDA / revenue | Operating profitability |
| ROE | net income / equity | Return to shareholders |
| CFO / debt | operating cash flow / total debt | Cash generation relative to debt |

- Total debt = non-current long-term debt + current portion of long-term debt + short-term borrowings.
- EBITDA = EBIT + depreciation and amortization.
- For ADM, Bunge, Corteva and Deere, which report no operating income line, EBIT is **pre-tax income**. This is conservative: pre-tax income is after interest, so their EBITDA and interest coverage are slightly understated.

### Peer screen (`09_screen.sql`)

- **Trend:** revenue growth and the change in Debt/EBITDA versus the prior year, using `LAG()`.
- **Peer medians:** MySQL has no `MEDIAN()` function, so the values are numbered in order and the median is the average of the middle one or two rows (`FLOOR` and `CEIL` of `(count + 1) / 2`).
- **Rankings:** `leverage_rank` (1 = most levered) and `coverage_quartile` (1 = weakest coverage).
- **Credit flag:** thresholds common in bank loan covenants, checked in this order:

| Flag | Rule |
|---|---|
| RED - negative EBITDA | EBITDA is zero or negative. Checked first, because a negative Debt/EBITDA would otherwise look like low leverage |
| GREY - insufficient data | Debt/EBITDA or interest coverage is missing |
| RED - likely covenant pressure | Debt/EBITDA above 4.0x, or interest coverage below 2.0x |
| AMBER - watch list | Debt/EBITDA above 3.0x, or interest coverage below 4.0x |
| GREEN - comfortable | None of the above |

## Validation

### Load and cleaning

Row counts in MySQL after loading, checked against the line counts of the source files (minus the header row):

| Quarter | raw_sub | raw_num |
|---|---:|---:|
| 2025q4 | 6,304 | 3,832,977 |
| 2026q1 | 6,169 | 3,690,955 |
| 2026q2 | 7,714 | 3,608,711 |
| 2026q3 | 6,516 | 3,905,397 |
| **Total** | **26,703** | **15,038,040** |

| Table after cleaning | Rows | What was kept |
|---|---:|---|
| `sub` | 5,709 | Annual reports (10-K, 10-K/A) out of 26,703 filings |
| `num` | 1,293,397 | USD values from those filings, excluding segment and co-registrant breakdowns |

### Against the filed 10-Ks

Spot-check of the `facts` view against the 10-Ks on SEC EDGAR, latest fiscal year, $ millions:

| Company | Line item (as printed in the 10-K) | 10-K | `facts` view | Match |
|---|---|---:|---:|:---:|
| ADM (FY ended 2025-12-31, [10-K](https://www.sec.gov/Archives/edgar/data/7084/000000708426000011/)) | Revenues | 80,269 | 80,269 | ✓ |
| | Net Earnings Attributable to Controlling Interests | 1,078 | 1,078 | ✓ |
| | Total Assets | 52,389 | 52,389 | ✓ |
| Deere (FY ended 2025-11-02, [10-K](https://www.sec.gov/Archives/edgar/data/315189/000110465925122321/)) | Net sales and revenues | 45,684 | 45,684 | ✓ |
| | Net Income Attributable to Deere & Company | 5,027 | 5,027 | ✓ |
| | Total Assets | 105,996 | 105,996 | ✓ |

- **Net income is the parent company's share.** For Deere, total net income is $4,998M and the parent's share is $5,027M; the screen uses the parent's share.
- **SEC rounds dates to month-end.** Deere's fiscal year ended on November 2, 2025 (a 52/53-week year), but the data sets store it as `20251031`.

### Completeness

After tag mapping, `07_qa.sql` shows no missing revenue, interest expense or D&A for any company. The only blank long-term debt is each company's oldest year, as expected: a 10-K has three years of income statements but only two balance sheets. Every company gets a credit flag (no GREY). The remaining NULLs are real absences, such as companies with no short-term borrowings.

## Problems found and fixed

Most of these ran **without an error** and were found only by checking the output.

| Problem | How it showed up | Fix |
|---|---|---|
| Stray tabs in 34 investment-fund rows (2026q2, 2026q3) | Warning 1262 (row truncated) on load | Left in `raw_num`, removed by the `segments` filter in `03_clean.sql`. None belong to the peer companies |
| 2025q4 `sub.txt` loaded more than once | Error 1062 (duplicate entry) when adding the primary key to `sub` | Deleted that quarter by `src_quarter`, reloaded once, rechecked counts, rebuilt `sub` and `num` |
| Same item reported under different XBRL tags | Many NULLs in `facts`. Kraft Heinz and Mosaic showed **zero debt**, because `COALESCE(x, 0)` in the total-debt sum turned a missing tag into 0 | Found each company's tags with `07_qa.sql` and added them to the `COALESCE` lists in `06_facts.sql` (table below) |
| A 10-K contains quarter-end and later dates, not just fiscal year-ends | Corteva's "latest year" was 2026-01-31, a single number after year-end. `LAG()` compared some companies with a quarter instead of the prior year | `facts_long` keeps only the fiscal year-end and the two years before it. `ratios` went from 75 rows to 36 (12 companies x 3 years) |
| Missing ratios fell through to GREEN | ADM, Bunge, Corteva and Deere were GREEN with no data, because a comparison with NULL is never true | Added GREY for missing data to the `CASE`, before the other rules |
| Negative EBITDA looked like low leverage | Conagra's negative Debt/EBITDA passed as GREEN | Added RED for EBITDA at or below zero, checked first |
| Inconsistent segment name for Bunge | Segment summary listed Grain & processing twice | Corrected the name in `peers` and `04_peers.sql` |

**Tags mapped in `06_facts.sql`**, beyond the common defaults:

| Field | Tag | Companies |
|---|---|---|
| revenue | `RevenueFromContractWithCustomerIncludingAssessedTax` | HRL, KHC |
| ebit | `IncomeLossFromContinuingOperationsBeforeIncomeTaxes...` (pre-tax income, a proxy) | ADM, BG, CTVA, DE |
| interest_expense | `InterestAndDebtExpense` | CTVA |
| | `InterestIncomeExpenseNet`, `InterestIncomeExpenseNonoperatingNet` (net figures, sign reversed) | CAG, MOS, GIS |
| | `FinancingCostsNet` | INGR |
| d_and_a | `Depreciation` + `AdjustmentForAmortization` | HRL, TSN |
| net_income | `ProfitLoss` minus `NetIncomeLossAttributableToNoncontrollingInterest` | CF |
| equity | `StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest` | ADM, CAG |
| cash | `CashCashEquivalentsRestrictedCashAndRestrictedCashEquivalents` | CF |
| ltd_noncurrent | `LongTermDebtAndCapitalLeaseObligations` | CTVA, GIS, KHC, MOS, TSN |
| | `LongTermDebtAndFinanceLeasesNoncurrent` | DE |
| | `SeniorLongTermNotes` | CAG |
| ltd_current | `LongTermDebtAndCapitalLeaseObligationsCurrent` | CAG, GIS, KHC, MOS |
| short_term_debt | `OtherShortTermBorrowings`, `ShortTermBankLoansAndNotesPayable` | MOS |

## Lessons learned

- **No error does not mean a correct result.** The most damaging mistakes in this project ran cleanly: a misspelled tag, a missing value counted as zero, a NULL that fell through to GREEN. Every result was checked against the source files or the filings.
- **Zero is not the same as unknown.** `COALESCE(x, 0)` is right for adding optional parts of a total, but it can turn a missing value into a believable wrong number. Kraft Heinz briefly looked debt-free.
- **Validate every load against the source.** Comparing row counts with the files' line counts made the duplicate load easy to diagnose and to confirm fixed.
- **Let constraints catch errors.** The primary key on `sub` stopped duplicate data before it could double-count anything in the ratios.
- **Match entities by ID, not by name.** Two of the 14 name matches were the wrong companies; the CIK is the reliable key.
- **Standardized data still needs mapping.** XBRL is a standard, but companies choose among many tags for the same item. Twelve companies needed 19 extra tags.
- **Ratios need context.** Deere's finance arm and the packaged-food write-downs show that a screen identifies who needs a closer look, not the final credit view.
- **Make loads safe to rerun.** Running `LOAD DATA` twice appends a second copy. Delete a quarter's rows (by `src_quarter`) before reloading it.

## How to reproduce

1. Download the four quarterly ZIPs from the SEC link above and unzip each into its own folder: `data/2025q4/`, `data/2026q1/`, and so on.
2. In MySQL Workbench, create a schema `credit_screen`, enable `local_infile`, and add `OPT_LOCAL_INFILE=1` to the connection's Advanced settings.
3. Open and run the scripts in `sql/` in numerical order, each top to bottom with Cmd+Shift+Enter.
4. Compare your row counts with the Load and cleaning tables above.
5. Export the `screen` and `ratios` results from `10_export.sql` with the result grid's Export button, to `output/credit_screen_latest.csv` and `output/ratios_all_years.csv`.

## Repository structure

```
sql/      01_tables.sql ... 10_export.sql
output/   credit_screen_latest.csv, ratios_all_years.csv
memo/     credit_memo.md
data/     raw SEC files (not in the repo)
```

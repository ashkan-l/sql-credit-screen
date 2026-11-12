# Agribusiness Credit Screen (SQL)

Credit screen of 12 agribusiness and food companies using SEC financial statement data and MySQL.

> **Status:** In progress. Data loaded (Steps 1-2); cleaning and ratio analysis next.

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

## Load validation

Row counts in MySQL after loading, checked against the line counts of the source files (minus the header row):

| Quarter | raw_sub | raw_num |
|---|---:|---:|
| 2025q4 | 6,304 | 3,832,977 |
| 2026q1 | 6,169 | 3,690,955 |
| 2026q2 | 7,714 | 3,608,711 |
| 2026q3 | 6,516 | 3,905,397 |
| **Total** | **26,703** | **15,038,040** |

## Data notes

- SEC `num.txt` files for 2026q2 and 2026q3 contain 34 rows (from 3 investment-fund filings) with a stray tab inside the `segments` field. MySQL truncated these rows on load (warning 1262). They stay in `raw_num` and are removed in `sql/03_clean.sql`, which keeps only rows with an empty `segments` value (company-wide totals). None belong to the companies in the screen.

## How to reproduce

1. Download the four quarterly ZIPs from the SEC link above and unzip each into its own folder: `data/2025q4/`, `data/2026q1/`, and so on.
2. In MySQL Workbench, create a schema `credit_screen`, enable `local_infile`, and add `OPT_LOCAL_INFILE=1` to the connection's Advanced settings.
3. Open and run the scripts in `sql/` in numerical order. Each one runs top to bottom with Cmd+Shift+Enter.
4. Compare your row counts with the Load validation table.

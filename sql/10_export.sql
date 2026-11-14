-- Step 10: segment summary and export

-- Which part of the farm-to-shelf chain is most levered?
-- Negative-EBITDA companies are left out of the leverage average (their Debt/EBITDA
-- has no meaning); COUNT(column) shows how many companies are behind each average.
SELECT segment,
		COUNT(*)							AS companies,
		COUNT(CASE WHEN credit_flag NOT LIKE 'RED - negative%'
				THEN debt_to_ebitda END)	AS in_leverage_avg,
		ROUND(AVG(CASE WHEN credit_flag NOT LIKE 'RED - negative%'
				THEN debt_to_ebitda END), 2)	AS avg_leverage,
		ROUND(AVG(interest_coverage), 1)	AS avg_coverage
FROM screen GROUP BY segment ORDER BY avg_leverage DESC;

-- Export each result grid with the Export button (CSV):
SELECT * FROM screen;	-- output/credit_screen_latest.csv
SELECT * FROM ratios ORDER BY ticker, fiscal_year_end DESC;	-- output/ratios_all_years.csv

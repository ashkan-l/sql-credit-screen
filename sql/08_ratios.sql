CREATE OR REPLACE VIEW ratios AS
WITH base AS (
	SELECT f.*,
		COALESCE(ltd_noncurrent,0) + COALESCE(ltd_current,0)
			+ COALESCE(short_term_debt,0)	AS total_debt,
		ebit + COALESCE(d_and_a, 0)			AS ebitda
	FROM facts f
)
SELECT ticker, segment, fiscal_year_end, revenue, ebitda, total_debt, net_income,
	ROUND(current_assets / NULLIF(current_liabilities,0), 2) 	AS current_ratio,
    ROUND(total_debt / NULLIF(equity,0), 2)						AS debt_to_equity,
    ROUND(total_debt / NULLIF(ebitda,0), 2)						AS debt_to_ebitda,
    ROUND((total_debt - COALESCE(cash,0)) / NULLIF(ebitda,0), 2) AS net_debt_to_ebitda,
    ROUND(ebit / NULLIF(interest_expense,0), 2)					AS interest_coverage,
    ROUND(100 * ebitda / NULLIF(revenue,0), 1)					AS ebitda_margin_pct,
    ROUND(100 * net_income / NULLIF(equity,0), 1)				AS roe_pct,
	ROUND(cfo / NULLIF(total_debt,0), 2)						AS cfo_to_debt
FROM base;
SELECT * FROM ratios ORDER BY ticker, fiscal_year_end DESC;
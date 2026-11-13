CREATE OR REPLACE VIEW screen AS
WITH trended AS (
	SELECT r.*,
		LAG(revenue) 		OVER w							AS prev_revenue,
        debt_to_ebitda - LAG(debt_to_ebitda) OVER w			AS leverage_change,
        ROW_NUMBER() OVER (PARTITION BY ticker
							ORDER BY fiscal_year_end DESC)	AS yr_rank
	FROM ratios r
    WINDOW w AS (PARTITION BY ticker ORDER BY fiscal_year_end)
),
latest AS (SELECT * FROM trended WHERE yr_rank = 1),
lev_sorted AS (				-- median Debt/EBITDA, done by hand
	SELECT debt_to_ebitda,
			ROW_NUMBER() OVER (ORDER BY debt_to_ebitda) AS rn,
            COUNT(*) 	 OVER ()						AS cnt
	FROM latest WHERE debt_to_ebitda IS NOT NULL
),
cov_sorted AS (				-- median interest coverage, same pattern
	SELECT interest_coverage,
		ROW_NUMBER() OVER (ORDER BY interest_coverage)  AS rn,
        COUNT(*) 	 OVER () 							AS cnt
	FROM latest WHERE interest_coverage IS NOT NULL
),
medians AS (
	SELECT 
    (SELECT AVG(debt_to_ebitda) FROM lev_sorted
		WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2)))	AS peer_median_leverage,
	(SELECT AVG(interest_coverage) FROM cov_sorted
		WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2)))	AS peer_median_coverage
)
SELECT l.ticker, l.segment, l.fiscal_year_end,
	ROUND(100 * (l.revenue / NULLIF(l.prev_revenue,0) - 1), 1) 		AS revenue_growth_pct,
    l.debt_to_ebitda, l.leverage_change, l.interest_coverage, l.current_ratio,
    m.peer_median_leverage, m.peer_median_coverage,
    -- leverage_rank: 1 = most levered
	RANK() OVER (ORDER BY l.debt_to_ebitda DESC)					AS leverage_rank,
    NTILE(4) OVER (ORDER BY l.interest_coverage)					AS coverage_quartile,
    CASE
	  WHEN l.ebitda <= 0 THEN 'RED - negative EBITDA'
      WHEN l.debt_to_ebitda IS NULL OR l.interest_coverage IS NULL
		THEN 'GREY - insufficient data'
	  WHEN l.debt_to_ebitda > 4.0 OR l.interest_coverage < 2.0
		THEN 'RED - likely covenant pressure'
	  WHEN l.debt_to_ebitda >3.0 OR l.interest_coverage < 4.0 THEN 'AMBER - watch list'
      ELSE 'GREEN - comfortable'
	END																AS credit_flag
FROM latest l
CROSS JOIN medians m
ORDER BY leverage_rank;
SELECT * FROM screen;
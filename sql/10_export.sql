-- Which part of the farm-to-shelf chain is most levered?
SELECT segment,
		COUNT(*) 							AS companies,
        ROUND(AVG(debt_to_ebitda), 2)		AS avg_leverage,
        ROUND(AVG(interest_coverage), 1)	AS avg_coverage
FROM screen GROUP BY segment ORDER BY avg_leverage DESC;

SET SQL_SAFE_UPDATES = 0;
UPDATE peers SET segment = 'Grain & processing' WHERE cik = 1996862;
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM screen;
SELECT * FROM ratios;
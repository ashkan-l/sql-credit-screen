-- Which fields are missing, by company?
SELECT ticker,
	SUM(revenue IS NULL)	AS no_revenue,
    SUM(interest_expense IS NULL)	AS no_interest,
    SUM(d_and_a IS NULL)	AS no_da,
    SUM(ltd_noncurrent IS NULL)	AS no_ltd
FROM facts GROUP BY ticker ORDER BY ticker;

-- Which tags does a company with gaps actually use? (then add them to step 6)
SELECT DISTINCT tag FROM facts_long
WHERE ticker ='DE' AND (tag LIKE '%Interest%' OR tag LIKE '%Debt%')
ORDER BY tag;
-- Keep only annual reports (10-K, 10-K/A), with real dates instead of text.
DROP TABLE IF EXISTS sub;
CREATE TABLE sub AS
SELECT adsh,
		CAST(cik AS UNSIGNED)			AS cik,
        name, sic, form, fy, fp,
        STR_TO_DATE(period, '%Y%m%d')	AS period,
        STR_TO_DATE(filed, '%Y%m%d')	AS filed
FROM raw_sub
WHERE form IN ('10-K', '10-K/A');
ALTER TABLE sub ADD PRIMARY KEY (adsh), ADD INDEX idx_cik (cik);

-- Keep only 10-K numbers, in USD, for the whole company (no segment splits).
DROP TABLE IF EXISTS num;
CREATE TABLE num AS
SELECT n.adsh, n.tag,
	STR_TO_DATE(n.ddate, '%Y%m%d') 		AS ddate,
    CAST(n.qtrs AS UNSIGNED)			AS qtrs,
    CAST(NULLIF(n.value, '') AS DECIMAL(28,4)) 	AS value
FROM raw_num n
JOIN sub s ON s.adsh = n.adsh
WHERE n.uom = 'USD'
	AND COALESCE(n.segments, '') = ''
    AND COALESCE(n.coreg, '') 	= '';
ALTER TABLE num ADD INDEX idx_adsh_tag (adsh, tag);

SELECT COUNT(*) FROM sub;
SELECT COUNT(*) FROM num;
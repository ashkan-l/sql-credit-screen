-- Find candidate companies by name; results are checked by hand (expect 14 rows)
SELECT DISTINCT cik, name, sic
FROM sub
WHERE name REGEXP 'ARCHER.DANIELS|BUNGE|DEER|TYSON|CORTEVA|CF INDUSTRIES|MOSAIC|GENERAL MILLS|KRAFT HEINZ|CONAGRA|HORMEL|INGSREDION'
ORDER BY name;

-- Verified peer group, keyed by CIK.
-- Excluded: John Deere Capital Corp (27673, Deere's finance arm) and
-- Mosaic ImmunoEngineering (836564, unrelated biotech).
DROP TABLE IF EXISTS peers;
CREATE TABLE peers (cik INT UNSIGNED PRIMARY KEY, ticker VARCHAR(10), segment VARCHAR(60));
INSERT INTO peers VALUES
	(7084,		'ADM',	'Grain & processing'),
    (315189,	'DE',	'Ag equipment'),
    (1996862,	'BG',	'Grain & Processing'),
    (1755672,	'CTVA',	'Seeds & crop protection'),
    (1324404, 'CF',   'Fertilizer'),
	(1285785, 'MOS',  'Fertilizer'),
	(100493,  'TSN',  'Protein'),
	(48465,   'HRL',  'Protein'),
	(1046257, 'INGR', 'Food ingredients'),
	(40704,   'GIS',  'Packaged food'),
	(1637459, 'KHC',  'Packaged food'),
	(23217,   'CAG',  'Packaged food');

SELECT * FROM peers;	-- expect 12 rows

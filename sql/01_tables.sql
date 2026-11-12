USE credit_screen;
DROP TABLE IF EXISTS raw_sub;
CREATE TABLE raw_sub (
	adsh VARCHAR(20), cik VARCHAR(10), name VARCHAR(200), sic VARCHAR(4), countryba TEXT, stprna TEXT, cityba TEXT, zipba TEXT, 
	bas1 TEXT, bas2 TEXT, baph TEXT, countryma TEXT, stprma TEXT, cityma TEXT, zipma TEXT, mas1 TEXT, mas2 TEXT, countryinc TEXT, 
    stprinc TEXT, ein TEXT, former TEXT, changed TEXT, afs TEXT, wksi TEXT, fype VARCHAR(4), form VARCHAR(20), period VARCHAR(8),
    fy VARCHAR(4), fp VARCHAR(4), filled VARCHAR(8), accepted TEXT, prevrpt TEXT, instance TEXT, nciks TEXT, aciks TEXT,
    src_quarter VARCHAR(6)
);
DROP TABLE IF EXISTS raw_num;
CREATE TABLE raw_num (
	adsh VARCHAR(20), tag VARCHAR(256), version VARCHAR(20), ddate VARCHAR(8), qtrs VARCHAR(8), uom VARCHAR(40), 
    segments TEXT, coreg TEXT, value VARCHAR(40), footnote TEXT, src_quarter VARCHAR(6)
);
SHOW COLUMNS FROM raw_sub;
ALTER TABLE raw_sub
	RENAME COLUMN basl TO bas1,
	RENAME COLUMN masl TO mas1;
SHOW COLUMNS FROM raw_sub;
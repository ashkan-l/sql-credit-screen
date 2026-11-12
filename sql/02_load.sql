LOAD DATA LOCAL INFILE
	'/Users/ashkanl/Projects/sql-credit-screen/data/2025q4/sub.txt'
INTO TABLE raw_sub
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (adsh, cik, name, sic, countryba, stprba, cityba, zipba, bas1, bas2, baph, countryma, stprma, cityma, zipma, mas1, mas2, countryinc,
    stprinc, ein, former, changed, afs, wksi, fye, form, period, fy, fp, filed, accepted, prevrpt, detail, instance, nciks, aciks)
SET src_quarter = '2025q4';

LOAD DATA LOCAL INFILE 
	'/Users/ashkanl/Projects/sql-credit-screen/data/2025q4/num.txt'
INTO TABLE raw_num
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (adsh, tag, version, ddate, qtrs, uom, segments, coreg, value, footnote)
    SET src_quarter = '2025q4';
LOAD DATA LOCAL INFILE 
	'/Users/ashkanl/Projects/sql-credit-screen/data/2026q1/sub.txt'
INTO TABLE raw_sub
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (adsh, cik, name, sic, countryba, stprba, cityba, zipba, bas1, bas2, baph, countryma, stprma, cityma, zipma, mas1, mas2, countryinc,
    stprinc, ein, former, changed, afs, wksi, fye, form, period, fy, fp, filed, accepted, prevrpt, detail, instance, nciks, aciks)
SET src_quarter = '2026q1';
LOAD DATA LOCAL INFILE
	'/Users/ashkanl/Projects/sql-credit-screen/data/2026q1/num.txt'
INTO TABLE raw_num
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
	(adsh, tag, version, ddate, qtrs, uom, segments, coreg, value, footnote)
SET src_quarter = '2026q1';
LOAD DATA LOCAL INFILE
	'/Users/ashkanl/Projects/sql-credit-screen/data/2026q2/sub.txt'
INTO TABLE raw_sub
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (adsh, cik, name, sic, countryba, stprba, cityba, zipba, bas1, bas2, baph, countryma, stprma, cityma, zipma, mas1, mas2, countryinc,
    stprinc, ein, former, changed, afs, wksi, fye, form, period, fy, fp, filed, accepted, prevrpt, detail, instance, nciks, aciks)
SET src_quarter = '2026q2';
LOAD DATA LOCAL INFILE 
	'/Users/ashkanl/Projects/sql-credit-screen/data/2026q2/num.txt'
INTO TABLE raw_num
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES 
    (adsh, tag, version, ddate, qtrs, uom, segments, coreg, value, footnote)
SET src_quarter = '2026q2';
LOAD DATA LOCAL INFILE
	'/Users/ashkanl/Projects/sql-credit-screen/data/2026q3/sub.txt'
INTO TABLE raw_sub
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES 
    (adsh, cik, name, sic, countryba, stprba, cityba, zipba, bas1, bas2, baph, countryma, stprma, cityma, zipma, mas1, mas2, countryinc,
    stprinc, ein, former, changed, afs, wksi, fye, form, period, fy, fp, filed, accepted, prevrpt, detail, instance, nciks, aciks)
SET src_quarter = '2026q3';
LOAD DATA LOCAL INFILE
	'/Users/ashkanl/Projects/sql-credit-screen/data/2026q3/num.txt'
INTO TABLE raw_num
	CHARACTER SET utf8mb4
    FIELDS TERMINATED BY '\t' ESCAPED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (adsh, tag, version, ddate, qtrs, uom, segments, coreg, value, footnote)
SET src_quarter = '2026q3';
SELECT src_quarter, COUNT(*) FROM raw_sub GROUP BY src_quarter;
SELECT src_quarter, COUNT(*) FROM raw_num GROUP BY src_quarter;
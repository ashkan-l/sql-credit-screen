CREATE OR REPLACE VIEW latest_10k AS
SELECT *
FROM (
	SELECT s.*, p.ticker, p.segment,
		ROW_NUMBER() OVER (PARTITION BY s.cik
							ORDER BY s.period DESC, s.filed DESC) AS rn
	FROM sub s
    JOIN peers p ON p.cik = s.cik
) AS t
WHERE rn = 1;
SELECT ticker, name, period, filed FROM latest_10k ORDER BY ticker;
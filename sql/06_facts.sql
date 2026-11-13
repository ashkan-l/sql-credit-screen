CREATE OR REPLACE VIEW facts_long AS
SELECT l.ticker, l.segment, n.ddate, n.tag, n.qtrs, n.value
FROM latest_10k l
JOIN num n ON n.adsh = l.adsh
WHERE n.ddate IN (l.period, l.period - INTERVAL 1 YEAR, l.period - INTERVAL 2 YEAR);

CREATE OR REPLACE VIEW facts AS
SELECT ticker, segment, ddate AS fiscal_year_end,
	-- income statement & cash flow: full-year flows (qtrs=4)
	COALESCE (
		MAX(CASE WHEN tag = 'Revenues' AND qtrs = 4 THEN value END),
        MAX(CASE WHEN tag = 'RevenueFromContractWithCustomerExcludingAssessedTax'
				AND qtrs = 4 THEN value END))		AS revenue,
	MAX(CASE WHEN tag = 'OperatingIncomeLoss' AND qtrs = 4 THEN value END) AS ebit,
    COALESCE(
		MAX(CASE WHEN tag = 'InterestExpense' AND qtrs = 4 THEN value END),
        MAX(CASE WHEN tag = 'InterestExpenseNonoperating' AND qtrs = 4 THEN value END),
        MAX(CASE WHEN tag = 'InterestExpenseDebt' AND qtrs = 4 THEN value END))
																		AS interest_expense,
	COALESCE(
		MAX(CASE WHEN tag = 'DepreciationDepletionAndAmortization' AND qtrs = 4 THEN value END),
        MAX(CASE WHEN tag = 'DepreciationAndAmortization' AND qtrs = 4 THEN value END),
        MAX(CASE WHEN tag = 'DepreciationAmortizationAndAccretionNet' AND qtrs = 4 THEN value END))
																			AS d_and_a,
	MAX(CASE WHEN tag = 'NetIncomeLoss' AND qtrs = 4 THEN value END) AS net_income,
    MAX(CASE WHEN tag = 'NetCashProvidedByUsedInOperatingActivities'
				AND qtrs = 4 THEN value END)								AS cfo,
-- Balance sheet: point in time (qtrs = 0)
	MAX(CASE WHEN tag = 'AssetsCurrent' AND qtrs = 0 THEN value END)	AS current_assets,
    MAX(CASE WHEN tag = 'LiabilitiesCurrent' AND qtrs = 0 THEN value END) AS current_liabilities,
    MAX(CASE WHEN tag = 'Assets' AND qtrs = 0 THEN value END) AS total_assets,
    MAX(CASE WHEN tag = 'StockholdersEquity' AND qtrs = 0 THEN value END) AS equity,
    MAX(CASE WHEN tag = 'CashAndCashEquivalentsAtCarryingValue' AND qtrs = 0 THEN value END)	AS cash,
    MAX(CASE WHEN tag = 'LongTermDebtNoncurrent' AND qtrs = 0 THEN value END) AS ltd_noncurrent,
    MAX(CASE WHEN tag IN ('LongTermDebtCurrent', 'DebtCurrent') AND qtrs = 0 THEN value END) AS ltd_current,
    MAX(CASE WHEN tag IN ('ShortTermBorrowings', 'CommercialPaper') AND qtrs = 0 THEN value END) AS short_term_debt
FROM facts_long
GROUP BY ticker, segment, ddate;
SELECT * FROM facts;
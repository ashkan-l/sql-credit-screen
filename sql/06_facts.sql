-- Step 6: pivot XBRL facts from long format (one row per number) to wide format
-- (one row per company and fiscal year).

-- Long format: every number in each company's latest 10-K, limited to the fiscal
-- year-end and the two years before it (a 10-K also contains quarter-end and
-- subsequent-event dates, which would break the year-over-year comparison).
CREATE OR REPLACE VIEW facts_long AS
SELECT l.ticker, l.segment, n.ddate, n.tag, n.qtrs, n.value
FROM latest_10k l
JOIN num n ON n.adsh = l.adsh
WHERE n.ddate IN (l.period, l.period - INTERVAL 1 YEAR, l.period - INTERVAL 2 YEAR);

-- Wide format. Companies report the same item under different tags, so COALESCE
-- takes the first tag that has a value. Tags were found with the queries in 07_qa.sql.
CREATE OR REPLACE VIEW facts AS
SELECT ticker, segment, ddate AS fiscal_year_end,
	-- Income statement and cash flow: full-year flows (qtrs = 4)
	COALESCE(
		MAX(CASE WHEN tag = 'Revenues' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'RevenueFromContractWithCustomerExcludingAssessedTax' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'RevenueFromContractWithCustomerIncludingAssessedTax' AND qtrs = 4 THEN value END)
	)																	AS revenue,
	COALESCE(
		MAX(CASE WHEN tag = 'OperatingIncomeLoss' AND qtrs = 4 THEN value END),
		-- No operating income line (ADM, BG, CTVA, DE): pre-tax income as a proxy
		MAX(CASE WHEN tag = 'IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest'
				AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'IncomeLossFromContinuingOperationsBeforeIncomeTaxesMinorityInterestAndIncomeLossFromEquityMethodInvestments'
				AND qtrs = 4 THEN value END)
	)																	AS ebit,
	COALESCE(
		MAX(CASE WHEN tag = 'InterestExpense' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'InterestExpenseNonoperating' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'InterestExpenseDebt' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'InterestAndDebtExpense' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'FinancingCostsNet' AND qtrs = 4 THEN value END),
		-- Reported net of interest income, negative = expense: flip the sign
		-1 * MAX(CASE WHEN tag = 'InterestIncomeExpenseNet' AND qtrs = 4 THEN value END),
		-1 * MAX(CASE WHEN tag = 'InterestIncomeExpenseNonoperatingNet' AND qtrs = 4 THEN value END)
	)																	AS interest_expense,
	COALESCE(
		MAX(CASE WHEN tag = 'DepreciationDepletionAndAmortization' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'DepreciationAndAmortization' AND qtrs = 4 THEN value END),
		MAX(CASE WHEN tag = 'DepreciationAmortizationAndAccretionNet' AND qtrs = 4 THEN value END),
		-- Reported separately (HRL, TSN): depreciation + amortization
		MAX(CASE WHEN tag = 'Depreciation' AND qtrs = 4 THEN value END)
			+ COALESCE(MAX(CASE WHEN tag = 'AdjustmentForAmortization' AND qtrs = 4 THEN value END), 0)
	)																	AS d_and_a,
	COALESCE(
		MAX(CASE WHEN tag = 'NetIncomeLoss' AND qtrs = 4 THEN value END),
		-- Total profit minus the minority owners' share (CF)
		MAX(CASE WHEN tag = 'ProfitLoss' AND qtrs = 4 THEN value END)
			- COALESCE(MAX(CASE WHEN tag = 'NetIncomeLossAttributableToNoncontrollingInterest'
							AND qtrs = 4 THEN value END), 0)
	)																	AS net_income,
	MAX(CASE WHEN tag = 'NetCashProvidedByUsedInOperatingActivities' AND qtrs = 4 THEN value END) AS cfo,

	-- Balance sheet: point in time (qtrs = 0)
	MAX(CASE WHEN tag = 'AssetsCurrent' AND qtrs = 0 THEN value END)		AS current_assets,
	MAX(CASE WHEN tag = 'LiabilitiesCurrent' AND qtrs = 0 THEN value END)	AS current_liabilities,
	MAX(CASE WHEN tag = 'Assets' AND qtrs = 0 THEN value END)				AS total_assets,
	COALESCE(
		MAX(CASE WHEN tag = 'StockholdersEquity' AND qtrs = 0 THEN value END),
		MAX(CASE WHEN tag = 'StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest'
				AND qtrs = 0 THEN value END)
	)																	AS equity,
	COALESCE(
		MAX(CASE WHEN tag = 'CashAndCashEquivalentsAtCarryingValue' AND qtrs = 0 THEN value END),
		MAX(CASE WHEN tag = 'CashCashEquivalentsRestrictedCashAndRestrictedCashEquivalents'
				AND qtrs = 0 THEN value END)
	)																	AS cash,
	COALESCE(
		MAX(CASE WHEN tag = 'LongTermDebtNoncurrent' AND qtrs = 0 THEN value END),
		MAX(CASE WHEN tag = 'LongTermDebtAndCapitalLeaseObligations' AND qtrs = 0 THEN value END),
		MAX(CASE WHEN tag = 'LongTermDebtAndFinanceLeasesNoncurrent' AND qtrs = 0 THEN value END),
		MAX(CASE WHEN tag = 'SeniorLongTermNotes' AND qtrs = 0 THEN value END)
	)																	AS ltd_noncurrent,
	COALESCE(
		MAX(CASE WHEN tag IN ('LongTermDebtCurrent', 'DebtCurrent') AND qtrs = 0 THEN value END),
		MAX(CASE WHEN tag = 'LongTermDebtAndCapitalLeaseObligationsCurrent' AND qtrs = 0 THEN value END)
	)																	AS ltd_current,
	MAX(CASE WHEN tag IN ('ShortTermBorrowings', 'CommercialPaper', 'OtherShortTermBorrowings',
						'ShortTermBankLoansAndNotesPayable') AND qtrs = 0 THEN value END) AS short_term_debt
FROM facts_long
GROUP BY ticker, segment, ddate;

SELECT * FROM facts ORDER BY ticker, fiscal_year_end DESC;

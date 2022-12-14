USE [hpa_tb]
GO
/****** Object:  StoredProcedure [dbo].[Get_FiscalYearPeriod]    Script Date: 8/19/2022 2:36:46 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO



-----------------------------------------------------------------
--	Author: Pham Thi Thu Hien 
--	Created date: Apr-17-2007
--	Purpose: get fiscal year period
--			Input:		year
--			Output:		fiscal year start/end
-- 	Modify history:
-----------------------------------------------------------------
ALTER             PROCEDURE [dbo].[Get_FiscalYearPeriod] 
	@Year 				smallint
	,@FiscalYearStart	datetime OUTPUT
	,@FiscalYearStop	datetime OUTPUT
AS
BEGIN
	DECLARE		@DiffYear	int

	SET	@FiscalYearStart = (SELECT cast(value as datetime) from tblParameter where code = 'START_FINANCE_YEAR') -- 1/1/2006
	SET @DiffYear = @Year-YEAR(@FiscalYearStart) 
	SET @FiscalYearStart = DATEADD(yy,@DiffYear,@FiscalYearStart)		
	SET	@FiscalYearStop	= DATEADD(dd,-1,DATEADD(yy,1,@FiscalYearStart))
	
--print '@FiscalYearStart=' + cast(@FiscalYearStart as varchar)
--print '@FiscalYearStop=' + cast(@FiscalYearStop as varchar)
END







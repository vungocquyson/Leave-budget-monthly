USE [hpa_tb]
GO
/****** Object:  StoredProcedure [dbo].[HR_EmpAnnual_CalculateALPlus]    Script Date: 8/16/2022 10:17:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*********************************************************************/
--Function: HR_EmpAnnual_CalculateALPlus
--Purpose: Calculate plus AL days each employee (for example: 1 days for each 5 years)
--History:
--Created by Hienpt - on Jul 2nd, 2007
/*********************************************************************/


ALTER	PROCEDURE  [dbo].[HR_EmpAnnual_CalculateALPlus]
(
	@EmployeeID 		varchar(20)
	,@JoinDate			datetime
	,@EmployeeStatusID	int
	,@TerminateDate		datetime
	,@ForFiscalYear		smallint -- fiscal year input
	,@ForMonth			int --Thang tinh tham nien
	,@ALPlus			float OUTPUT	--So ngay phep duoc cong them
)

AS 
	DECLARE	@LastMonthOfPreviousYear datetime
		,@FiscalYearFrom	datetime
		,@FiscalYearTo		datetime
		,@AL_DURATION		float
		,@AL_INCREMENTED_BY	float
		,@ALUnit			float
		,@ToDate			datetime

BEGIN
--select 'alp1',@ALPlus
	------------------Determine the fiscal year period----------------------
	EXEC	Get_FiscalYearPeriod
			@ForFiscalYear
			,@FiscalYearFrom	OUTPUT
			,@FiscalYearTo		OUTPUT
	


	------------------Remove error (if anny)------------------------------
	IF @JoinDate > @FiscalYearFrom
	BEGIN
		SET @ALPlus = 0 
		RETURN
	END

	IF (@EmployeeStatusID >= 20) AND (@TerminateDate IS NOT NULL) AND (@TerminateDate-1 < @FiscalYearFrom)
	BEGIN
		SET @ALPlus = 0 
		RETURN
	END


	------------------Now calculate AL Plus as normal-------------------------
	SET @AL_DURATION = (SELECT CAST(Value as float) FROM tblParameter WHERE Code = 'AL_DURATION')
	--select 'i0',@AL_INCREMENTED_BY == null
	SET @AL_INCREMENTED_BY = (SELECT CAST(Value as float) FROM tblParameter WHERE Code = 'AL_INCREMENTED_BY')
	--select 'i1',@AL_INCREMENTED_BY =1 làm đủ or hơn 5 năm

	--ThinhVV: Byokane yeu cau thay doi: tinh tham nien den thang tinh phep
	declare @Month varchar(2)
	if @ForMonth = 0
		set @Month = CAST(Month(@JoinDate) as varchar)
	else
		set @Month = cast(@ForMonth as varchar)

	--End ThinhVV

	--Determine @ToDate: 
	--tinh nam du? ke tu ngay JoinDate (vd: Join 11/2/2000, phep dc cong cho nam tai chinh 2007(Jan 2007 - Dec 2007) -> chi tinh tu 11/2/2000 den 11/2/2006, khong tinh phan le 2/2006 den 12/2006 vi chua du 1 nam)
	
	-- Cap nhat ngay @ToDate: Tranh truong hop thang co it ngay, ko co ngay Day(@JoinDate). Vi du thang 2, co 28 ngay, trong khi Day(@JoinDate) la 30
	 	
	SET @ToDate = CAST(CAST(@ForFiscalYear as varchar) + '-' + @Month + '-1' as datetime)
	select @ToDate as ToDatecast
	set @ToDate = dateadd(dd,-1,dateadd(MM,1,@ToDate))
	select @ToDate as ToDatecast2

	If Day(@ToDate) > Day(@JoinDate)
		begin
		SET @ToDate = CAST(CAST(@ForFiscalYear as varchar) + '-' + @Month +'-' + CAST(DAY(@JoinDate) as varchar) as datetime)
		End
	--ThinhVV: Hide
	--SET @ToDate = CAST(CAST(@ForFiscalYear as varchar) + '-' + CAST(Month(@JoinDate) as varchar) +'-' + CAST(DAY(@JoinDate) as varchar) as datetime)
	--	IF @ToDate > @FiscalYearFrom
	--		SET @ToDate = DATEADD(yy,-1,@ToDate)
	--select @ForMonth,@Month , 'ThinhVV'

	--select ISNULL(@AL_DURATION,0) as ISNULL_AL_DURATION == 8
	IF ISNULL(@AL_DURATION,0) =  0
	BEGIN
		SET @ALUnit = 0
	END
	ELSE --tranh loi chia cho 0
	BEGIN
		--select 'au0',@ALUnit == null
		select @JoinDate as joindate,@ToDate as todate
		SET @ALUnit = FLOOR(DATEDIFF(mm,@JoinDate,@ToDate)/12/@AL_DURATION)
		--select 'au1',@ALUnit == null
	END
	--select 'alp2',@ALPlus
	SET @ALPlus = @ALUnit * @AL_INCREMENTED_BY 
	--select 'alp3',@ALPlus
	
END








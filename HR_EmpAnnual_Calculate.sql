USE [hpa_tb]
GO
/****** Object:  StoredProcedure [dbo].[HR_EmpAnnual_Calculate]    Script Date: 8/16/2022 10:08:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*********************************************************************/
--Function: HR_EmpAnnual_Calculate
--Purpose: Calculate AL days for each employee
--History:
--Created by Hienptt - Jul 2nd, 2007
/*********************************************************************/


ALTER	PROCEDURE  [dbo].[HR_EmpAnnual_Calculate]
(
	@EmployeeID 		varchar(20)
	,@ToDate			datetime 	--calculate budget of AL days upto @ToDate -- fiscalyearto
	,@ForMonth			int --Thang tinh tham nien
	,@Method			int			--0: tinh tu JoinDate, 1: chi tinh tu dau nam tai chinh
	,@TotalALDays		float OUTPUT
	,@ALPlus			float OUTPUT	--So ngay duoc cong them (VD: cu 5 nam duoc cong them 1 ngay phep)
)
AS 
BEGIN
	DECLARE
		@JoinDate			datetime
		,@EmployeeStatusID	int
		,@TerminateDate		datetime

		,@FiscalYear		smallint
		,@FiscalYearFrom	datetime
		,@FiscalYearTo		datetime
		,@FromDate			datetime
		,@ALForFirstMonth	float
	
	------------------Get employee status-------------------------------
	EXEC Get_EmployeeStatus
		@EmployeeID
		,@JoinDate			OUTPUT
		,@EmployeeStatusID	OUTPUT
		,@TerminateDate		OUTPUT


	------------------Get fiscal year-----------------------------------
	EXEC Get_FiscalYear
		@ToDate
		,@FiscalYear 	OUTPUT


	------------------Get fiscal year period----------------------------
	EXEC Get_FiscalYearPeriod
		@FiscalYear
		,@FiscalYearFrom	OUTPUT
		,@FiscalYearTo		OUTPUT


	------------------Remove abnormal case------------------------------
	--Neu da nghi roi, khong lam viec trong nam tai chinh nay nua thi thoi
	IF @TerminateDate IS NOT NULL AND @TerminateDate <= @FiscalYearFrom -- ngày kết thúc trước năm tài chính
	BEGIN
		SET @TotalALDays = 0
		SET @ALPlus = 0
		RETURN
	END
	--Neu join vao cty sau nam tai chinh nay, thi cung thoi :)
	IF @JoinDate > @FiscalYearTo -- ngày vào sau năm tài chính
	BEGIN
		SET @TotalALDays = 0
		SET @ALPlus = 0
		RETURN
	END
	
	select  @TotalALDays as TotalALDays 

	-------------------Determine FromDate--------------------------------
	IF @FiscalYearFrom < @JoinDate --join vao c.ty trong nam tai chinh
	BEGIN
		SET @FromDate = @JoinDate --thi tinh tu ngay join vao c.ty
	END
	ELSE --join vao c.ty tu nam truoc
	BEGIN
		IF @Method = 1 --tinh tu dau nam tai chinh
			SET @FromDate = @FiscalYearFrom
		ELSE	-- tinh tu ngay vao c.ty
			SET @FromDate = @JoinDate
	END


--  	------------------Determine ToDate: must be in the fiscal year-----------------
--comment doan code duoi, vi khi nao thanh toan phep thi moi tinh lai den t/diem Terminate
-- 	IF @EmployeeStatusID >=20 AND @TerminateDate IS NOT NULL 
-- 		AND DATEDIFF(dd,@ToDate,@TerminateDate-1)<0 
-- 	BEGIN
-- 		SET @ToDate = @TerminateDate - 1 --and cannot after terminate date,
-- 	END


	--------------------------------------------------------
	--Calucate AL days in normal
	--------------------------------------------------------
-- 	SET @ALForFirstMonth = (DATEDIFF(dd,@JoinDate,DATEADD(dd,-1,DATEADD(mm,1,CAST(cast(Year(@JoinDate) as varchar) + '-' + cast(month(@JoinDate) as varchar) + '-01' as datetime)))) + 1)/(365.0/12)
-- 	IF @ALForFirstMonth IS NULL SET @ALForFirstMonth = 0
	SET @ALForFirstMonth = 1 --Voi Matsuo, vao ngay nao trong thang cung dc huong 1 ngay AL

	SET 	@TotalALDays = DATEDIFF(mm,@FromDate,@ToDate) + @ALForFirstMonth -- datediff(fromdate,todate)

	select  @TotalALDays as TotalALDays2
	select 'DATEDIFF' ,DATEDIFF(mm,@FromDate,@ToDate) 
	
	----------------------------------------------------------- 
	--Calculate AL days with plus
	-----------------------------------------------------------
	select 'EmployeeID',@EmployeeID
	select 'JoinDate',@JoinDate
	select 'EmployeeStatusID',@EmployeeStatusID
	select 'TerminateDate',@TerminateDate
	select 'FiscalYear',@FiscalYear
	select 'ForMonth',@ForMonth
	select 'ALPlus',@ALPlus

	EXEC HR_EmpAnnual_CalculateALPlus
		@EmployeeID
		,@JoinDate
		,@EmployeeStatusID
		,@TerminateDate
		,@FiscalYear
		,@ForMonth
		,@ALPlus	OUTPUT
		select 'ALPlusOUTPUT' ,@ALPlus
		
	IF @ALPlus IS NULL SET @ALPlus = 0
	SET @TotalALDays = @TotalALDays + @ALPlus

	select 'TotalALDays3' ,@TotalALDays
	
print '@JoinDate = ' + cast(@JoinDate as varchar)
print '@TerminateDate = ' + cast(@TerminateDate as varchar)
print '@FiscalYear=' + cast(@FiscalYear as varchar)
print '@FromDate=' + cast(@FromDate as varchar)
print '@ToDate=' + cast(@ToDate as varchar)
print '@TotalALDays =' + cast(@TotalALDays as varchar)
print '@ALPlus=' + cast(@ALPlus as varchar)
END







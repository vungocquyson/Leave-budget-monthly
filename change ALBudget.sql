USE [hpa_tb]
GO
/****** Object:  StoredProcedure [dbo].[HR_LeaveBudget_Initialization_Monthly]    Script Date: 8/9/2022 11:41:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER	PROCEDURE	[dbo].[HR_LeaveBudget_Initialization_Monthly] --chỉnh sửa procedure
		@FiscalYear	smallint -- kiểu int lưu được từ -32,767 đến 32,767
		,@FiscalMonth smallint
		,@EmployeeID	varchar(20) --kiểu char có độ dài thay đổi được lưu cả số và chữ
		,@LeaveCode		varchar(20)
		,@Overwrite		bit
AS
	DECLARE	
			@BudgetValue	float 
			,@NeedBudget	bit
			,@LeaveCategory	bit
			,@AL			varchar(20)
			,@Taken			float
			,@Remain		float
			,@FiscalYearFrom	datetime 
			,@FiscalYearTo		datetime
			,@SecHazAL		varchar(50)--sonlh add 2022.05.24
			,@HireDate		datetime--sonlh add 2022.05.24
			,@TerminateDate	datetime--sonlh add 2022.05.24
			,@HazLeaveBudget	float--sonlh add 2022.05.24
BEGIN
	-----------------Get paramters------------------------------------------
	select @LeaveCategory as LeaveCategory
	select @BudgetValue as BudgetValue
	select @NeedBudget as NeedBudget
	-----------------------------------------
	SET @AL = (SELECT Cast([Value] as varchar(20)) FROM tblParameter WHERE Code = 'LEAVE_CODE_ANNUAL') --@AL lưu dữ liệu leavecode kiểu 'L'
	
	SET @SecHazAL = (SELECT Cast([Value] as varchar(50)) FROM tblParameter WHERE Code = 'SEC_HAVE_HAZARD_AL')--sonlh add 2022.05.24

	SET @HazLeaveBudget = (SELECT Cast([Value] as FLOAT) FROM tblParameter WHERE Code = 'HARD_LEAVE_BUDGET')--sonlh add 2022.05.24 -- = 2

	--sonlh add 2022.05.24
	DECLARE  @TableSectionHazAL TABLE (
			SectionID		int
		)

	DECLARE		@Index	INT
				,@SectionCode  VARCHAR(20)
	SET	@SecHazAL = LTRIM(RTRIM(@SecHazAL)) 
	SET	@SecHazAL = @SecHazAL + ','

		

	SET	@Index = CHARINDEX(',', @SecHazAL) 

	WHILE (@Index > 0) 
	BEGIN
		SET @SectionCode = SUBSTRING(@SecHazAL,1,@Index-1) 
		
		SET @SecHazAL= SUBSTRING(@SecHazAL,@Index+1,LEN(@SecHazAL)-@Index)
		
		SET @Index = CHARINDEX(',',@SecHazAL)
		
		IF EXISTS (SELECT 1 FROM tblSection t WHERE t.SectionCode = @SectionCode)
		BEGIN
			INSERT INTO @TableSectionHazAL
			SELECT t.SectionID FROM tblSection t
			WHERE t.SectionCode = @SectionCode
		END

	END	
	--------------------------------------------------------
	-- cắt các chuỗi kí tự vài insert vào biến @TableSectionHazAL sectionid từ bảng tblSection khi mà cái sectioncode = sectioncode vừa cắt được
	-------------------------------------------------------

	--end
	--select * from @TableSectionHazAL
	----------------Calculate the fiscal year period------------------------
	EXEC	Get_FiscalYearPeriod -- thực thi store Get_FiscalYearPeriod tính ra ngày đầu năm và cuối năm tài chính đang xét
				@FiscalYear
				,@FiscalYearFrom	OUTPUT
				,@FiscalYearTo		OUTPUT

				
				

--select '4'
	----------------Check and process------------------------
	IF @Overwrite = 0 
		AND EXISTS(SELECT 1 FROM tblEmployeeAnnualMonth WHERE CYear = @FiscalYear 
														AND CMonth=@FiscalMonth
														AND EmployeeID = @EmployeeID
														AND LeaveCode = @LeaveCode
					)
	BEGIN
		RETURN 0
	END
	ELSE
	BEGIN
		--select '6' 
		IF EXISTS (SELECT 1 FROM tblEmployeeAnnual
					WHERE CYear = @FiscalYear AND EmployeeID = @EmployeeID AND LeaveCode = @LeaveCode AND ISNULL(CarryFlag,0) = 1
														
					)
		BEGIN
		  --select '10'
			RETURN -1 --bao cho user biet nam tai chinh nay da duoc carry sang nam sau nen khong the khoi tao lai
		END

		------------------In case need to initialize budget------------------------
		--Delete existed data (if any)
		DELETE FROM tblEmployeeAnnualMonth WHERE CYear = @FiscalYear 
											AND CMonth=@FiscalMonth  
											AND EmployeeID = @EmployeeID
											AND LeaveCode = @LeaveCode


		SELECT @BudgetValue = ISNULL(MaxNumber,0) --max = 12 trong trường hợp được xét
				,@NeedBudget = ISNULL(NeedBudget,0)
				,@LeaveCategory = ISNULL(LeaveCategory,0)
		FROM tblLeaveType WHERE LeaveCode = @LeaveCode

		SELECT @BudgetValue as BudgetValue_leavetype

--select '9'
		IF @LeaveCategory = 0 -- nếu @LeaveCategory = 0 thì không xét 2 trường hợp =0 là đi công tác và quên quẹt thẻ
			RETURN
		IF @NeedBudget = 0 -- @NeedBudget=1 có nghỉ phép cưới và tang ma
			SET @BudgetValue = -1 


--select '8'
		--Check if Annual leave, then must re-calculate based on method of AL budget calculation
		DECLARE @ALPrior				float

		IF @LeaveCode = @AL -- nếu @LeaveCode = @AL thì thực thi begin ("L")
		BEGIN
			DECLARE	@JoinDate			datetime 
					,@ALBudget			float  
					,@ALPlus			float
					,@ALCarryForward	float

			SET @JoinDate = (SELECT HireDate FROM tblEmployee WHERE EmployeeID = @EmployeeID)
			 
			--select @EmployeeID as employeeID
			--select @FiscalYearTo as FiscalYearTo
			--select @FiscalMonth as FiscalMonth
			--select @ALBudget as ALBudget
			--select @ALPlus as ALPlus

			EXEC	HR_EmpAnnual_Calculate 
					@EmployeeID
					,@FiscalYearTo
					,@FiscalMonth --Thang tinh tham nien
					,1 --calculate form the begining of fiscal year
					,@ALBudget	OUTPUT
					,@ALPlus	OUTPUT
					
					

			select @ALBudget as ALbudget		
			IF @ALBudget IS NULL SET @ALBudget = 0 
			SET	@BudgetValue = @ALBudget  --đặt	@BudgetValue = @ALBudget là tổng số tháng từ lúc vào đến cuối năm tài chính
			--select 'butget01', @BudgetValue


			--select @ALBudget,@ALPlus,'Debug_Thinhvv'
			--Den doan nay : tinh xong budget cua nam tai chinh
			--Tru di so thang con lai trong nam
			SET @BudgetValue = @BudgetValue-(12- @FiscalMonth)--đặt @BudgetValue = @BudgetValue-(12- tháng nhập vào)
			select @BudgetValue as BudgetValue_12_fiscal
			--tong so phep lm vc tinh den cuoi nam tai chinh - so phep con lai trong nam
			-- ra so phep da lam tu luc vao tinh den thang hien tai 


	--select 'butget02',@BudgetValue

			--select @BudgetValue,'Debug_Thinhvv1'
			--Some AL days can be carried forward from the previous year to this year, so must include
			
			--sonvnq modify 2022.09.06
			IF EXISTS(SELECT * FROM tblEmployeeAnnual WHERE EmployeeID = @EmployeeID AND CYear = @FiscalYear -1 AND LeaveCode = @AL AND CarryFlag = 0)
			BEGIN
				SET @ALCarryForward = (SELECT ForwardDay FROM tblAnnualLeavemanagement WHERE EmployeeID = @EmployeeID AND CYear = @FiscalYear - 1)
				SET @ALPrior = @ALCarryForward
				SET @BudgetValue = @BudgetValue + ISNULL(@ALCarryForward,0)
			END
			select @BudgetValue as BudgetValue_lastyear
			--end sonvnq 2022.09.06
			
--select @BudgetValue,'Debug_Thinhvv2'
		END--end begin 'L'

		--sonlh add 2022.05.24
		SELECT 
			@HireDate = HireDate,
			@TerminateDate = TerminateDate
		FROM tblEmployee
		WHERE EmployeeID = @EmployeeID
		AND SectionID IN (SELECT * FROM @TableSectionHazAL)


		IF(DATEDIFF(MONTH,@HireDate,@FiscalYearTo) > 5 AND @TerminateDate IS NULL) -- tong so thang >5 va dang lm vc
			SET @BudgetValue = @BudgetValue + @HazLeaveBudget
			
		IF(DATEDIFF(MONTH,@HireDate,@FiscalYearTo) < 5 AND @TerminateDate IS NULL)
			SET @BudgetValue = @BudgetValue + @HazLeaveBudget/2


		IF((@HireDate >= @FiscalYearFrom) AND @TerminateDate IS NOT NULL AND DATEDIFF(MONTH,@HireDate,@TerminateDate) > 5)
			SET @BudgetValue = @BudgetValue + @HazLeaveBudget

		IF((@HireDate >= @FiscalYearFrom) AND @TerminateDate IS NOT NULL AND DATEDIFF(MONTH,@HireDate,@TerminateDate) < 5)
			SET @BudgetValue = @BudgetValue + @HazLeaveBudget/2

		IF((@HireDate <= @FiscalYearFrom) AND @TerminateDate IS NOT NULL AND DATEDIFF(MONTH,@FiscalYearFrom,@TerminateDate) > 5)
			SET @BudgetValue = @BudgetValue + @HazLeaveBudget

		IF((@HireDate <= @FiscalYearFrom) AND @TerminateDate IS NOT NULL AND DATEDIFF(MONTH,@FiscalYearFrom,@TerminateDate) < 5)
			SET @BudgetValue = @BudgetValue + @HazLeaveBudget/2
		--end
		--select @HazLeaveBudget as HazLeaveBudget
		--select @BudgetValue as BudgetValue
		

	--select '7'
--Get leave taken value in previous months

		--sonvnq modify 2022.09.06
		DECLARE @OldTaken float
				,@OldTaken6 float
				,@OldTakenRemain float  -- OldTaken trong tháng 7-FiscalMonth
				,@ALPriorRemain float	-- Phép của t7 trở đi

		SET @OldTaken = (SELECT SUM(CASE
									WHEN LeaveStatus = 3 THEN 1		
									ELSE 0.5
								END)
						FROM	tblLvHistory
						WHERE	EmployeeID = @EmployeeID
								AND DATEDIFF(dd,LeaveDate,@FiscalYearFrom)<=0
								AND DATEDIFF(dd,LeaveDate,@FiscalYearTo)>=0
								AND LeaveCode = @LeaveCode
								AND MONTH(LeaveDate) < @FiscalMonth
					)

		SET @OldTaken6 = (SELECT SUM(CASE
									WHEN LeaveStatus = 3 THEN 1 
									ELSE 0.5
								END)
						FROM	tblLvHistory
						WHERE	EmployeeID = @EmployeeID
								AND DATEDIFF(dd,LeaveDate,@FiscalYearFrom)<=0
								AND DATEDIFF(dd,LeaveDate,@FiscalYearTo)>=0
								AND LeaveCode = @LeaveCode
								AND MONTH(LeaveDate) <= 6
					)

		SET @OldTaken6 = ISNULL(@OldTaken6,0)			-- so lan nghi trong thang 1-6
		SET @OldTaken = ISNULL(@OldTaken,0)				-- tong so lan nghi
		SET @ALPrior = ISNULL(@ALPrior,0)				-- so phep uu tien nam ngoai t1-6
		SET @OldTakenRemain = @OldTaken - @OldTaken6	-- so lan nghi cua t7 tro di
		------------

		IF @FiscalMonth > 6
		BEGIN
			IF @ALPrior - @OldTaken6 < 0
				SET @ALPriorRemain = @ALPrior - @OldTaken6
			ELSE
				SET @ALPriorRemain = 0
		END
		------------

		IF @FiscalMonth > 6 AND @OldTaken6 is not null	-- nghỉ trong tháng 1-6
			SET @BudgetValue = @BudgetValue - @ALPrior + @ALPriorRemain
		IF @FiscalMonth > 6								-- nghỉ từ tháng 7 trở đi & nghỉ hỗn hợp
			SET @BudgetValue = @BudgetValue - @OldTakenRemain
		ELSE											-- nghỉ các th các tháng <=6 
			SET @BudgetValue = @BudgetValue - @OldTaken

		--select @BudgetValue,@OldTaken 'oldtaken','Debug_Thinhvv3'
		--Get leave taken value in month

		SET @Taken = (SELECT SUM(CASE
									WHEN LeaveStatus = 3 THEN 1 --khi LeaveStatus = 3 gán dòng =1 các trường hơp khác gán bằng 0.5
									ELSE 0.5
								END)
						FROM	tblLvHistory
						WHERE	EmployeeID = @EmployeeID
								AND DATEDIFF(dd,LeaveDate,@FiscalYearFrom)<=0
								AND DATEDIFF(dd,LeaveDate,@FiscalYearTo)>=0
								AND LeaveCode = @LeaveCode
								AND MONTH(LeaveDate) = @FiscalMonth
					)
		
		IF @NeedBudget = 1
				SET @Remain = @BudgetValue - ISNULL(@Taken,0)
		ELSE
			BEGIN
				SET @Remain = -1
				SET @BudgetValue=-1
			END
		--end sonvnq 2022.09.06

		--@Taken lấy ra số lần nghỉ trong năm 2022 với kiểu nghỉ xác định và tháng rời đi trong tháng tài chính 
		-- @Remain là biến lưu trữ số lượng phép còn lại sau khi trừ đi số lần nghỉ trong tháng đang xét
		-- @BudgetValue là số lượng phép còn lại chưa tính đến tháng đang xét
		select @Remain as BudgetValue_final
--debug
--select 'debug,@EmployeeID,@FiscalYear,@FiscalMonth,@LeaveCode,@BudgetValue,@Taken,@Remain', @EmployeeID,@FiscalYear,@FiscalMonth,@LeaveCode,@BudgetValue,@Taken,@Remain
		--select '3'
		
		--thêm vào bảng tblEmployeeAnnualMonth có các cột (EmployeeID,CYear,CMonth,LeaveCode,ThisYear,Taken,Remain,CarryFlag)
		-- các giá trị tương ứng là (@EmployeeID,@FiscalYear,@FiscalMonth,@LeaveCode,@BudgetValue,@Taken,@Remain,0)

		INSERT INTO tblEmployeeAnnualMonth(EmployeeID,CYear,CMonth,LeaveCode,ThisYear,Taken,Remain,CarryFlag) --this year == budgetvalue
		VALUES(	@EmployeeID,@FiscalYear,@FiscalMonth,@LeaveCode,@BudgetValue,@Taken,@Remain,0)

--select '2'
		RETURN 0 -- RETURN 0 thống báo kết thúc chương trình
	--select '1'	
	END
END
-- 'TBV2647' 'L' 7 2022
-- thay đổi tính phép forward phép sang năm sau dùng đến tháng 6 số phép từ năm trước sang năm sau được ưu tiên trước hết tháng 6 thì phép forward sẽ mất
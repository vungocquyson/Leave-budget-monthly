exec [dbo].[HR_LeaveBudget_Initialization_Monthly] --chỉnh sửa procedure
		@FiscalYear	= 2017 -- kiểu int lưu được từ -32,767 đến 32,767
		,@FiscalMonth = 7
		,@EmployeeID = 'DHS1932' --kiểu char có độ dài thay đổi được lưu cả số và chữ
		,@LeaveCode	= 'L'
		,@Overwrite	= 1	--kiểu nhị phân 0 & 1

select * FROM tblSection

select * FROM tblEmployeeAnnualMonth

select * FROM tblLeaveType 
where LeaveCode = 'L'

select * FROM tblEmployeeAnnual

select * FROM tblParameter 
WHERE Code = 'SEC_HAVE_HAZARD_AL'
	--@AL lưu trữ trạng thái nghỉ
	--@SecHazAL lưu chuỗi kí tự

select * FROM tblEmployee
WHERE EmployeeID = 'DHS1930'

select * from tblLvHistory
WHERE	EmployeeID = 'DHS1932'

select * FROM tblAnnualLeavemanagement

EXEC sp_describe_first_result_set
      @tsql=N'SELECT * FROM [dbo].[tblEmployeeAnnual];'
    , @params = NULL
    , @browse_information_mode = 1;

-- đang set carryflag = 0

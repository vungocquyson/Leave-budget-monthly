USE [hpa_tb]
GO
/****** Object:  StoredProcedure [dbo].[Get_EmployeeStatus]    Script Date: 8/17/2022 4:14:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Get_EmployeeStatus]
(
	@EmployeeID		varchar(20)
	,@JoinDate		datetime OUTPUT
	,@EmployeeStatusID	int OUTPUT
	,@TerminateDate		datetime OUTPUT
)
AS
BEGIN
	SELECT
		@JoinDate = HireDate
		,@EmployeeStatusID = EmployeeStatusID
		,@TerminateDate = TerminateDate
	FROM tblEmployee
	WHERE	EmployeeID = @EmployeeID

--	select @JoinDate as JoinDate2,@EmployeeID as id

END


SET QUOTED_IDENTIFIER OFF 


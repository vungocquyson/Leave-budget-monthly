EXEC sp_describe_first_result_set
      @tsql=N'SELECT * FROM dbo.tblEmployee;'
    , @params = NULL
    , @browse_information_mode = 1;
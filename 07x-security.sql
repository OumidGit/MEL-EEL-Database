USE MEL_EEL_Automation_Dev;
GO

DECLARE @DbUser SYSNAME;

SELECT TOP (1) @DbUser = dp.name
FROM sys.database_principals dp
WHERE dp.sid = SUSER_SID()
  AND dp.type IN ('S','U','G','E','X');

IF @DbUser IS NULL
BEGIN
    -- Create a DB user for the current login only if none exists
    DECLARE @Login SYSNAME = SUSER_SNAME();
    DECLARE @sql NVARCHAR(MAX) =
      N'CREATE USER ' + QUOTENAME(@Login) + N' FOR LOGIN ' + QUOTENAME(@Login) + N';';
    EXEC (@sql);
    SET @DbUser = @Login;
END

-- Grants needed for the VBA test upload
DECLARE @g NVARCHAR(MAX);

SET @g = N'GRANT INSERT, SELECT ON stg.csv_raw_kv TO ' + QUOTENAME(@DbUser) + N';';
EXEC (@g);

SET @g = N'GRANT EXECUTE ON OBJECT::audit.sp_next_file_id TO ' + QUOTENAME(@DbUser) + N';';
EXEC (@g);
GO

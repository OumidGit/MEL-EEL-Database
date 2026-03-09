-- Enable CDC on database (only once)
IF NOT EXISTS (
    SELECT 1 FROM sys.databases
    WHERE name = 'MEL_EEL_Automation_Dev'
    AND is_cdc_enabled = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_db;
END
GO

-- Enable CDC on database (only once)
IF NOT EXISTS (
    SELECT 1 FROM sys.databases
    WHERE name = 'MEL_EEL_Automation_Dev'
    AND is_cdc_enabled = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_db;
END
GO
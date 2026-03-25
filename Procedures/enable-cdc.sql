USE MEL_EEL_Automation_Dev;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = 'core',
    @source_name   = 'MEL',
    @role_name     = NULL;  -- or specify a role
GO
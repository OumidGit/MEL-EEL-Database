USE MEL_EEL_Automation_Dev;
GO

/* 1) Create roles only if missing */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'etl_runner' AND type = 'R')
    CREATE ROLE etl_runner;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_editor' AND type = 'R')
    CREATE ROLE app_editor;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'report_reader' AND type = 'R')
    CREATE ROLE report_reader;
GO

/* 2) Grant rights (include stg/audit/out execute for KV pipeline) */
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::stg   TO etl_runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core  TO etl_runner;

GRANT EXECUTE ON SCHEMA::stg   TO etl_runner;   -- needed for stg.sp_transform_mel_rawkv_to_mech
GRANT EXECUTE ON SCHEMA::audit TO etl_runner;   -- needed for audit.sp_run_mel_from_rawkv
GRANT EXECUTE ON SCHEMA::core  TO etl_runner;   -- core upsert
GRANT EXECUTE ON SCHEMA::out   TO etl_runner;   -- snapshot proc

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core  TO app_editor;
GRANT SELECT ON SCHEMA::out TO report_reader;
GO

/* 3) Map your current Windows user into the DB (if not present) */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'DRAGLOBAL\aman.azad')
    CREATE USER [DRAGLOBAL\aman.azad] FOR LOGIN [DRAGLOBAL\aman.azad];
GO

/* 4) Add your user to the etl_runner role */
EXEC sp_addrolemember N'etl_runner', N'DRAGLOBAL\aman.azad';
GO

USE MEL_EEL_Automation_Dev;
GO
CREATE ROLE etl_runner;
CREATE ROLE app_editor;
CREATE ROLE report_reader;

-- Grant minimal rights
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::stg   TO etl_runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core  TO etl_runner;
GRANT EXECUTE ON SCHEMA::core TO etl_runner;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core  TO app_editor;
GRANT SELECT ON SCHEMA::out TO report_reader;

-- Map AD principals (replace with your real ones)
CREATE USER [DRA\svc-mel-eel] FOR LOGIN [DRA\svc-mel-eel];
EXEC sp_addrolemember N'etl_runner',    N'DRA\svc-mel-eel';

CREATE USER [DRA-MEL-Editors] FROM LOGIN [DRA-MEL-Editors];
EXEC sp_addrolemember N'app_editor',    N'DRA-MEL-Editors';

CREATE USER [DRA-MEL-Viewers] FROM LOGIN [DRA-MEL-Viewers];
EXEC sp_addrolemember N'report_reader', N'DRA-MEL-Viewers';
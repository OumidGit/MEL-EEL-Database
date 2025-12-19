USE MEL_EEL_Automation_Dev;
GO

IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg;');
GO

IF OBJECT_ID('stg.mel_raw_kv','U') IS NULL
BEGIN
    CREATE TABLE stg.mel_raw_kv
    (
        project_code  NVARCHAR(50)  NOT NULL,
        file_id       BIGINT        NOT NULL,         -- tie to audit.files.file_id (recommended)
        row_idx       INT           NOT NULL,         -- Excel row index (or sequential row number)
        alias_name    NVARCHAR(200) NOT NULL,         -- header exactly as seen (e.g. 'TagID')
        value_text    NVARCHAR(MAX) NULL,             -- raw cell value as text
        source_file   NVARCHAR(512) NULL,             -- optional: CSV file name/path for traceability
        loaded_utc    DATETIME2(3)  NOT NULL CONSTRAINT DF_mel_raw_kv_loaded DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_mel_raw_kv PRIMARY KEY (project_code, file_id, sheet_name, row_idx, alias_name)
    );
END
GO



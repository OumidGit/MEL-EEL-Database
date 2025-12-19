USE MEL_EEL_Automation_Dev;
GO 

IF OBJECT_ID('audit.files','U') IS NOT NULL
    DROP TABLE audit.files;
GO

IF OBJECT_ID('audit.etl_runs','U') IS NOT NULL
    DROP TABLE audit.etl_runs;
GO

IF OBJECT_ID('audit.etl_row_errors','U') IS NOT NULL
    DROP TABLE audit.etl_row_errors;
GO


CREATE TABLE audit.files(
    file_id        BIGINT IDENTITY PRIMARY KEY,
    project_code   NVARCHAR(50) NOT NULL,
    sp_item_id     NVARCHAR(100) NULL,
    path           NVARCHAR(400) NULL,
    filename       NVARCHAR(200) NOT NULL,
    file_hash      VARBINARY(32) NULL,       -- SHA-256
    last_seen_utc  DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_active      BIT NOT NULL DEFAULT 1
);

CREATE TABLE audit.etl_runs(
    run_id        BIGINT IDENTITY PRIMARY KEY,
    trigger_source NVARCHAR(50) NOT NULL,    -- 'Flow','Function','Manual'
    project_code   NVARCHAR(50) NOT NULL,
    file_id        BIGINT NULL,
    start_ts       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    end_ts         DATETIME2(3) NULL,
    status         NVARCHAR(20) NULL,        -- 'Succeeded','Failed','Partial'
    error_text     NVARCHAR(MAX) NULL
);

CREATE TABLE audit.etl_row_errors(
    run_id     BIGINT NOT NULL,
    file_id    BIGINT NULL,
    sheet      NVARCHAR(128) NULL,
    row_idx    INT NULL,
    reason     NVARCHAR(4000) NOT NULL,
    raw_payload NVARCHAR(MAX) NULL
);

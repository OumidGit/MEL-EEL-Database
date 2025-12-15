USE MEL_EEL_Automation_Dev;
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

-- Staging (parsed rows)
CREATE TABLE stg.equipment_mech(
    project_code      NVARCHAR(50) NOT NULL,
    file_id           BIGINT NULL,
    equipment_tag     NVARCHAR(100) NULL,
    description       NVARCHAR(400) NULL,
    eq_type           NVARCHAR(100) NULL,
    connected_load_kw DECIMAL(18,4) NULL,
    voltage_v         DECIMAL(18,4) NULL,
    power_factor_pf   DECIMAL(9,6) NULL,
    starter_type      NVARCHAR(100) NULL,
    location          NVARCHAR(200) NULL,
    raw_row_json      NVARCHAR(MAX) NULL
);

CREATE TABLE stg.equipment_elec(
    project_code  NVARCHAR(50) NOT NULL,
    file_id       BIGINT NULL,
    equipment_tag NVARCHAR(100) NULL,
    cable_tag     NVARCHAR(100) NULL,
    cores         INT NULL,
    size_mm2      DECIMAL(18,4) NULL,
    length_m      DECIMAL(18,4) NULL,
    route         NVARCHAR(200) NULL,
    voltage_v     DECIMAL(18,4) NULL,
    raw_row_json  NVARCHAR(MAX) NULL
);

CREATE TABLE core.equipment_mech(
    project_code      NVARCHAR(50) NOT NULL,
    equipment_tag     NVARCHAR(100) NOT NULL,
    description       NVARCHAR(400) NULL,
    eq_type           NVARCHAR(100) NULL,
    connected_load_kw DECIMAL(18,4) NULL,
    voltage_v         DECIMAL(18,4) NULL,
    power_factor_pf   DECIMAL(9,6) NULL,
    starter_type      NVARCHAR(100) NULL,
    location          NVARCHAR(200) NULL,
    last_modified_utc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    rowversion        ROWVERSION,
    CONSTRAINT PK_core_mech PRIMARY KEY(project_code, equipment_tag)
);

CREATE TABLE core.equipment_elec(
    project_code      NVARCHAR(50) NOT NULL,
    equipment_tag     NVARCHAR(100) NOT NULL,
    cable_tag         NVARCHAR(100) NULL,
    cores             INT NULL,
    size_mm2          DECIMAL(18,4) NULL,
    length_m          DECIMAL(18,4) NULL,
    route             NVARCHAR(200) NULL,
    voltage_v         DECIMAL(18,4) NULL,
    last_modified_utc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    rowversion        ROWVERSION,
    CONSTRAINT PK_core_elec PRIMARY KEY(project_code, equipment_tag)
);
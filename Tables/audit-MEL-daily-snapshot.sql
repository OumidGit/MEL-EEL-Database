USE MEL_EEL_Automation_Dev;
GO

CREATE TABLE audit.MEL_daily_snapshot
(
    snapshot_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    snapshot_date DATE NOT NULL,
    snapshot_time DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),

    project_code NVARCHAR(50) NOT NULL,
    project_DB_ID NVARCHAR(100) NOT NULL,

    batch_id UNIQUEIDENTIFIER NULL,
    file_id NVARCHAR(100) NULL,
    eq_status NVARCHAR(100) NULL,
    Area NVARCHAR(100) NULL,
    eq_type NVARCHAR(100) NULL,
    code NVARCHAR(100) NULL,
    eq_tag NVARCHAR(100) NULL,
    eq_desc NVARCHAR(400) NULL,
    rev NVARCHAR(400) NULL,
    qty NVARCHAR(400) NULL,
    nameplate_power_kw NVARCHAR(100) NULL,
    nameplate_power_hp NVARCHAR(400) NULL,
    absorbed_power_kw NVARCHAR(400) NULL,
    utilization_factor NVARCHAR(100) NULL,
    starter_type NVARCHAR(400) NULL,
    load_type NVARCHAR(400) NULL,
    duty NVARCHAR(400) NULL,
    emergency_load NVARCHAR(400) NULL,
    poles NVARCHAR(100) NULL,

    forced_duty NVARCHAR(400) NULL,
    duty_type NVARCHAR(100) NULL,
    demand_factor NVARCHAR(100) NULL,
    power_factor NVARCHAR(100) NULL,
    efficiency NVARCHAR(100) NULL,
    voltage_v NVARCHAR(100) NULL,
    phase NVARCHAR(100) NULL,
    eroom NVARCHAR(100) NULL,
    transformer NVARCHAR(100) NULL,
    mcc_switchgear NVARCHAR(100) NULL,
    forced_nameplate_power NVARCHAR(100) NULL,
    bucket_size NVARCHAR(100) NULL,
    forced_starter_type NVARCHAR(100) NULL,

    installed_kw NVARCHAR(100) NULL,
    installed_kvar NVARCHAR(100) NULL,
    installed_kva NVARCHAR(100) NULL,
    peak_kw NVARCHAR(100) NULL,
    peak_kvar NVARCHAR(100) NULL,
    peak_kva NVARCHAR(100) NULL,
    average_kw NVARCHAR(100) NULL,
    average_kvar NVARCHAR(100) NULL,
    average_kva NVARCHAR(100) NULL,
    annual_load_mwh NVARCHAR(100) NULL,
    fla NVARCHAR(100) NULL,
    current_draw NVARCHAR(100) NULL,
    fla_125pct NVARCHAR(100) NULL,
    remarks NVARCHAR(MAX) NULL,

    location NVARCHAR(400) NULL,
    raw_row_json NVARCHAR(MAX) NULL
);
GO

CREATE UNIQUE INDEX UX_MEL_daily_snapshot
ON audit.MEL_daily_snapshot(snapshot_date, project_code, project_DB_ID);
GO
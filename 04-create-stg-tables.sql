USE MEL_EEL_Automation_Dev;
GO 

CREATE TABLE stg.MEL(
    -- Mechanical Section
    project_code           NVARCHAR(50) NOT NULL,
    file_id                BIGINT NULL,
    Area                   NVARCHAR(100) NULL,
    eq_type                NVARCHAR(100) NULL,
    code                   NVARCHAR(100) NULL,
    equipment_tag          NVARCHAR(100) NULL,
    description            NVARCHAR(400) NULL,
    rev                    NVARCHAR(400) NULL,
    qty                    NVARCHAR(400) NULL,
    nameplate_power        DECIMAL(18,4) NULL,
    nameplate_power_unit   NVARCHAR(400) NULL,
    utilization_factor     DECIMAL(18,4) NULL,
    standby                NVARCHAR(400) NULL,
    starter_type           NVARCHAR(400) NULL,
    load_type              NVARCHAR(400) NULL,
    duty                   NVARCHAR(400) NULL,
    emergency_load         NVARCHAR(400) NULL,
    poles                  NVARCHAR(400) NULL,
    -- Electrical Section
    forced_duty            NVARCHAR(100) NULL,
    duty_type              NVARCHAR(100) NULL,
    demand_factor          DECIMAL(18,4) NULL,
    power_factor           DECIMAL(9,6) NULL,
    efficiency             DECIMAL(9,6) NULL,
    voltage_v              DECIMAL(18,4) NULL,
    phase                  DECIMAL(18,4) NULL
    eroom                  NVARCHAR(100) NULL,
    transformer            NVARCHAR(100) NULL,
    mcc_switchgear         NVARCHAR(100) NULL,
    forced_nameplate_power DECIMAL(18,4) NULL,
    bucket_size            NVARCHAR(100) NULL,
    forced_starter_type    NVARCHAR(100) NULL,
    installed_kw           DECIMAL(18,4) NULL,
    installed_kvar         DECIMAL(18,4) NULL,
    installed_kva          DECIMAL(18,4) NULL,
    peak_kw                DECIMAL(18,4) NULL,
    peak_kvar              DECIMAL(18,4) NULL,
    peak_kva               DECIMAL(18,4) NULL,
    average_kw             DECIMAL(18,4) NULL,
    average_kvar           DECIMAL(18,4) NULL,
    average_kva            DECIMAL(18,4) NULL,
    annual_load_mwh        DECIMAL(18,4) NULL,
    fla                    DECIMAL(18,4) NULL,
    current_draw           DECIMAL(18,4) NULL,
    fla_125%               DECIMAL(18,4) NULL,
    -- Misc 
    location               NVARCHAR(200) NULL,
    raw_row_json           NVARCHAR(MAX) NULL
);

CREATE TABLE stg.EEL(
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

CREATE TABLE core.MEL(
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

CREATE TABLE core.EEL(
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


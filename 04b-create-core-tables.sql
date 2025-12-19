USE MEL_EEL_Automation_Dev;
GO 

IF OBJECT_ID('core.equipment_mech','U') IS NOT NULL
    DROP TABLE core.equipment_mech;
GO

IF OBJECT_ID('core.equipment_elec','U') IS NOT NULL
    DROP TABLE core.equipment_elec;
GO

CREATE TABLE core.equipment_mech(
    project_code        NVARCHAR(50)  NOT NULL,
    equipment_tag       NVARCHAR(100) NOT NULL,  -- TagID

    -- MEL headers (Row 5)
    status              NVARCHAR(50)  NULL,
    area                NVARCHAR(100) NULL,
    eq_type             NVARCHAR(100) NULL,      -- Type
    code                NVARCHAR(50)  NULL,
    eq_num              NVARCHAR(50)  NULL,
    description         NVARCHAR(400) NULL,      -- Duty Description
    revision            NVARCHAR(50)  NULL,      -- Rev

    supplied_by         NVARCHAR(200) NULL,
    installed_by        NVARCHAR(200) NULL,
    connected_by        NVARCHAR(200) NULL,
    model               NVARCHAR(200) NULL,

    dimension_l         DECIMAL(18,4) NULL,
    dimension_w         DECIMAL(18,4) NULL,
    dimension_h         DECIMAL(18,4) NULL,

    specifications      NVARCHAR(MAX) NULL,
    comments            NVARCHAR(MAX) NULL,

    plant_section       NVARCHAR(100) NULL,
    pfd                 NVARCHAR(100) NULL,
    p_id                NVARCHAR(100) NULL,      -- P+ID
    responsible_eqlist  NVARCHAR(200) NULL,      -- Reponsible EqList
    package             NVARCHAR(200) NULL,
    package_engineer    NVARCHAR(200) NULL,

    demand_factor       DECIMAL(6,3)  NULL,
    poles               INT           NULL,      -- No. of Poles
    utilization_factor  DECIMAL(6,3)  NULL,
    motor_kw            DECIMAL(18,4) NULL,      -- Motor (kW)
    total_load_kw       DECIMAL(18,4) NULL,      -- Total Load (kW)

    drive_type          NVARCHAR(100) NULL,
    duty_type           NVARCHAR(100) NULL,
    load_type           NVARCHAR(100) NULL,
    emergency_load      NVARCHAR(50)  NULL,
    absorbed_power_kw   DECIMAL(18,4) NULL,
    mp                  NVARCHAR(50)  NULL,
    mass_bal            NVARCHAR(50)  NULL,

    -- Existing canonical columns used by current pipeline (kept for compatibility)
    connected_load_kw   DECIMAL(18,4) NULL,
    voltage_v           DECIMAL(18,4) NULL,
    power_factor_pf     DECIMAL(9,6)  NULL,
    starter_type        NVARCHAR(100) NULL,
    location            NVARCHAR(200) NULL,

    last_modified_utc   DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    rowversion          ROWVERSION,

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
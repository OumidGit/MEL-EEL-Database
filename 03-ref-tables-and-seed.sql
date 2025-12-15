/* ==========================================================
   A) Create reference tables (IF NOT EXISTS)
   ========================================================== */
USE MEL_EEL_Automation_Dev;
GO

IF OBJECT_ID('ref.column_aliases','U') IS NULL
CREATE TABLE ref.column_aliases(
    alias_name        NVARCHAR(200) NOT NULL,
    canonical_name    NVARCHAR(200) NOT NULL,
    source_scope      NVARCHAR(50)  NULL,     -- 'MEL','EEL','LOAD' (where you expect it)
    confidence        DECIMAL(4,2)  NULL,
    CONSTRAINT PK_column_aliases PRIMARY KEY(alias_name, canonical_name)
);
GO

IF OBJECT_ID('ref.units_dictionary','U') IS NULL
CREATE TABLE ref.units_dictionary(
    from_unit NVARCHAR(50) NOT NULL,
    to_unit   NVARCHAR(50) NOT NULL,
    factor    DECIMAL(18,8) NOT NULL,  -- multiply, then add offset
    offset    DECIMAL(18,8) NOT NULL DEFAULT (0),
    CONSTRAINT PK_units_dictionary PRIMARY KEY(from_unit, to_unit)
);
GO


-- Demand factor reference (example; tailor per project or equipment type)
IF OBJECT_ID('ref.demand_factors','U') IS NULL
BEGIN
    CREATE TABLE ref.demand_factors(
        project_code  NVARCHAR(50) NOT NULL CONSTRAINT DF_demand_proj DEFAULT(''),
        eq_type       NVARCHAR(100) NOT NULL,
        demand_factor DECIMAL(6,3)  NOT NULL,
        CONSTRAINT PK_demand_factors PRIMARY KEY (project_code, eq_type)
    );
END
GO


-- 1) Units: common electrical/mechanical basics
MERGE ref.units_dictionary AS tgt
USING (VALUES
    (N'kW', N'kW', 1.0, 0.0),
    (N'W',  N'kW', 0.001, 0.0),
    (N'MW', N'kW', 1000.0, 0.0),

    (N'V',  N'V',  1.0, 0.0),
    (N'kV', N'V',  1000.0, 0.0),

    (N'A',  N'A',  1.0, 0.0),

    (N'm',  N'm',  1.0, 0.0),
    (N'km', N'm',  1000.0, 0.0),

    (N'mm2',N'mm2',1.0, 0.0),   -- cross-section area
    (N'AWG',N'AWG',1.0, 0.0)    -- if you later add a mapping table AWG<->mm², keep this placeholder
) AS src(from_unit,to_unit,factor,offset)
ON (tgt.from_unit = src.from_unit AND tgt.to_unit = src.to_unit)
WHEN NOT MATCHED THEN
  INSERT(from_unit,to_unit,factor,offset) VALUES(src.from_unit,src.to_unit,src.factor,src.offset);

-- 2) Demand factors: starter set (customize later)
MERGE ref.demand_factors AS tgt
USING (VALUES
    (N'', N'Pump',      0.90),
    (N'', N'Crusher',   1.00),
    (N'', N'Conveyor',  0.80),
    (N'', N'Fans',      0.75),
    (N'', N'HVAC',      0.70),
    (N'', N'Lighting',  0.60)
) AS src(project_code, eq_type, demand_factor)
ON (ISNULL(tgt.project_code,'') = ISNULL(src.project_code,'') AND tgt.eq_type = src.eq_type)
WHEN NOT MATCHED THEN
  INSERT(project_code,eq_type,demand_factor) VALUES(src.project_code,src.eq_type,src.demand_factor);

-- 3) Column aliases:
-- Replace the CANONICAL names below to match YOUR normalized headers.
-- The left side are potential Excel headers from the field. The right side is your standard.

MERGE ref.column_aliases AS tgt
USING (VALUES
    /* MEL common */
    (N'Load',           N'connected_load_kw', N'MEL', 0.95),
    (N'Power',          N'connected_load_kw', N'MEL', 0.85),
    (N'Duty (kW)',      N'connected_load_kw', N'MEL', 0.90),
    (N'kW',             N'connected_load_kw', N'MEL', 0.80),

    (N'Voltage',        N'voltage_v',         N'MEL', 1.00),
    (N'V',              N'voltage_v',         N'MEL', 0.85),
    (N'kV',             N'voltage_v',         N'MEL', 0.85),

    (N'PF',             N'power_factor_pf',   N'MEL', 0.95),
    (N'Power Factor',   N'power_factor_pf',   N'MEL', 0.95),

    (N'Starter',        N'starter_type',      N'MEL', 0.90),
    (N'Starter Type',   N'starter_type',      N'MEL', 0.95),

    (N'Equip Tag',      N'equipment_tag',     N'MEL', 0.95),
    (N'Equipment Tag',  N'equipment_tag',     N'MEL', 0.95),
    (N'Tag',            N'equipment_tag',     N'MEL', 0.80),

    (N'Description',    N'description',       N'MEL', 0.95),
    (N'Location',       N'location',          N'MEL', 0.95),
    (N'Equipment Type', N'eq_type',           N'MEL', 0.95),

    /* EEL common */
    (N'Cable Tag',      N'cable_tag',         N'EEL', 0.95),
    (N'Cores',          N'cores',             N'EEL', 0.95),
    (N'Conductor Size', N'size_mm2',          N'EEL', 0.90),
    (N'Size (mm2)',     N'size_mm2',          N'EEL', 0.90),
    (N'Length (m)',     N'length_m',          N'EEL', 0.95),
    (N'Route',          N'route',             N'EEL', 0.95),

    /* Load List common (if any inputs/outputs use headers later) */
    (N'Demand (kW)',    N'demand_kw',         N'LOAD', 0.95),
    (N'kVA',            N'kva',               N'LOAD',  0.95)

) AS src(alias_name, canonical_name, source_scope, confidence)
ON (tgt.alias_name = src.alias_name AND tgt.canonical_name = src.canonical_name)
WHEN NOT MATCHED THEN
  INSERT(alias_name, canonical_name, source_scope, confidence)
  VALUES(src.alias_name, src.canonical_name, src.source_scope, src.confidence);
GO

/* ==========================================================
   C) Verify the inserts
   ========================================================== */
SELECT TOP 50 * FROM ref.units_dictionary ORDER BY from_unit, to_unit;
SELECT TOP 50 * FROM ref.demand_factors ORDER BY project_code, eq_type;
SELECT TOP 50 * FROM ref.column_aliases ORDER BY source_scope, canonical_name, alias_name;






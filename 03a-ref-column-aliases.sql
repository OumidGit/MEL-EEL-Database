/* ==========================================================
   A) Create reference tables (IF NOT EXISTS)
   ========================================================== */
USE MEL_EEL_Automation_Dev;
GO

IF OBJECT_ID('ref.column_aliases','U') IS NULL
BEGIN
    CREATE TABLE ref.column_aliases(
        alias_name        NVARCHAR(200) NOT NULL,
        canonical_name    NVARCHAR(200) NOT NULL,
        source_scope      NVARCHAR(50)  NULL,     -- 'MEL','EEL','LOAD' (where you expect it)
        confidence        DECIMAL(4,2)  NULL,
        CONSTRAINT PK_column_aliases PRIMARY KEY(alias_name, canonical_name)
    );
END
GO

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

    (N'PF',             N'power_fac tor_pf',   N'MEL', 0.95),
    (N'Power Factor',   N'power_factor_pf',   N'MEL', 0.95),

    (N'Starter',        N'starter_type',      N'MEL', 0.90),
    (N'Starter Type',   N'starter_type',      N'MEL', 0.95),

    (N'Equip Tag',      N'equipment_tag',     N'MEL', 0.95),
    (N'Equipment Tag',  N'equipment_tag',     N'MEL', 0.95),
    (N'Tag',            N'equipment_tag',     N'MEL', 0.80),

    (N'Description',    N'description',       N'MEL', 0.95),
    (N'Location',       N'location',          N'MEL', 0.95),
    (N'Equipment Type', N'eq_type',           N'MEL', 0.95),


    /* MEL headers (Standardized Lists Examples - MEL updated.xlsx, header row 5) */
    (N'Status', N'status', N'MEL', 1.00),

    (N'TagID', N'equipment_tag', N'MEL', 1.00),
    
    (N'Area', N'area', N'MEL', 1.00),
    
    (N'Type', N'eq_type', N'MEL', 1.00),
    
    (N'Code', N'code', N'MEL', 1.00),
    
    (N'EqNum', N'eq_num', N'MEL', 1.00),
    
    (N'Duty Description', N'description', N'MEL', 1.00),
    
    (N'Rev', N'revision', N'MEL', 1.00),
    
    (N'Supplied By', N'supplied_by', N'MEL', 1.00),
    
    (N'Installed By', N'installed_by', N'MEL', 1.00),
    
    (N'Connected By', N'connected_by', N'MEL', 1.00),
    
    (N'Model', N'model', N'MEL', 1.00),
    
    (N'Dimension (L)', N'dimension_l', N'MEL', 1.00),
    (N'Length',        N'dimension_l', N'MEL', 1.00),

    (N'Dimension (W)', N'dimension_w', N'MEL', 1.00),
    (N'Width',         N'dimension_w', N'MEL', 1.00),

    (N'Dimension (H)', N'dimension_h', N'MEL', 1.00),
    (N'Height',        N'dimension_h', N'MEL', 1.00),
    
    (N'Specifications', N'specifications', N'MEL', 1.00),
    
    (N'Comments', N'comments', N'MEL', 1.00),
    
    (N'Plant Section', N'plant_section', N'MEL', 1.00),
    
    (N'PFD', N'pfd', N'MEL', 1.00),
    
    (N'P+ID', N'p_id', N'MEL', 1.00),
    
    (N'Reponsible EqList', N'responsible_eqlist', N'MEL', 1.00),
    
    (N'Package', N'package', N'MEL', 1.00),
    
    (N'Package Engineer', N'package_engineer', N'MEL', 1.00),
    
    (N'Demand Factor', N'demand_factor', N'MEL', 1.00),
    
    (N'No. of Poles', N'poles', N'MEL', 1.00),
    
    (N'Utilization Factor', N'utilization_factor', N'MEL', 1.00),
    
    (N'Motor (kW)', N'motor_kw', N'MEL', 1.00),
    
    (N'Total Load (kW)', N'total_load_kw', N'MEL', 1.00),
    
    (N'Drive type', N'drive_type', N'MEL', 1.00),
    
    (N'Duty type', N'duty_type', N'MEL', 1.00),
    
    (N'Load Type', N'load_type', N'MEL', 1.00),
    
    (N'Emergency Load', N'emergency_load', N'MEL', 1.00),
    
    (N'Absorbed Power (kW)', N'absorbed_power_kw', N'MEL', 1.00),
    
    (N'MP', N'mp', N'MEL', 1.00),
    
    (N'MassBal', N'mass_bal', N'MEL', 1.00),

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
   ========================================================== 
SELECT TOP 50 * FROM ref.units_dictionary ORDER BY from_unit, to_unit;
SELECT TOP 50 * FROM ref.demand_factors ORDER BY project_code, eq_type;
SELECT TOP 50 * FROM ref.column_aliases ORDER BY source_scope, canonical_name, alias_name;
*/
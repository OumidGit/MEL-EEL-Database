USE MEL_EEL_Automation_Dev;
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


/*
SELECT TOP 50 * FROM ref.units_dictionary ORDER BY from_unit, to_unit;
SELECT TOP 50 * FROM ref.demand_factors ORDER BY project_code, eq_type;
SELECT TOP 50 * FROM ref.column_aliases ORDER BY source_scope, canonical_name, alias_name;
*/

/* ==========================================================
   A) Create reference tables (IF NOT EXISTS)
   ========================================================== */
USE MEL_EEL_Automation_Dev;
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
    (N'AWG',N'AWG',1.0, 0.0)    -- if you later add a mapping table AWG<->mm�, keep this placeholder
) AS src(from_unit,to_unit,factor,offset)
ON (tgt.from_unit = src.from_unit AND tgt.to_unit = src.to_unit)
WHEN NOT MATCHED THEN
  INSERT(from_unit,to_unit,factor,offset) VALUES(src.from_unit,src.to_unit,src.factor,src.offset);

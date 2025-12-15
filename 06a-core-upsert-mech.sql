USE MEL_EEL_Automation_Dev;
GO
CREATE OR ALTER PROCEDURE core.sp_upsert_equipment_mech @project_code NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  MERGE core.equipment_mech AS tgt
  USING (
    SELECT project_code, equipment_tag, description, eq_type,
           connected_load_kw, voltage_v, power_factor_pf, starter_type, location
    FROM stg.equipment_mech
    WHERE project_code = @project_code
  ) AS src
  ON (tgt.project_code = src.project_code AND tgt.equipment_tag = src.equipment_tag)
  WHEN MATCHED THEN UPDATE SET
    description       = src.description,
    eq_type           = src.eq_type,
    connected_load_kw = src.connected_load_kw,
    voltage_v         = src.voltage_v,
    power_factor_pf   = src.power_factor_pf,
    starter_type      = src.starter_type,
    location          = src.location,
    last_modified_utc = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (project_code, equipment_tag, description, eq_type,
            connected_load_kw, voltage_v, power_factor_pf, starter_type, location)
    VALUES (src.project_code, src.equipment_tag, src.description, src.eq_type,
            src.connected_load_kw, src.voltage_v, src.power_factor_pf, src.starter_type, src.location);
END;
GO

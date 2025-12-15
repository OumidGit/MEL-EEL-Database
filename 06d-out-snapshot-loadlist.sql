USE MEL_EEL_Automation_Dev;
GO
IF OBJECT_ID('out.load_list','U') IS NULL
BEGIN
  CREATE TABLE out.load_list(
    project_code      NVARCHAR(50) NOT NULL,
    equipment_tag     NVARCHAR(100) NOT NULL,
    connected_load_kw DECIMAL(18,4) NULL,
    demand_kw         DECIMAL(18,4) NULL,
    kVA               DECIMAL(18,4) NULL,
    voltage_v         DECIMAL(18,4) NULL,
    last_refresh_utc  DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_out_load_list PRIMARY KEY (project_code, equipment_tag)
  );
END
GO
CREATE OR ALTER PROCEDURE out.sp_snapshot_load_list @project_code NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM out.load_list WHERE project_code = @project_code;
  INSERT out.load_list(project_code, equipment_tag, connected_load_kw, demand_kw, kVA, voltage_v, last_refresh_utc)
  SELECT project_code, equipment_tag, connected_load_kw, demand_kw, kVA, voltage_v, SYSUTCDATETIME()
  FROM calc.vw_load_inputs
  WHERE project_code = @project_code;
END;
GO
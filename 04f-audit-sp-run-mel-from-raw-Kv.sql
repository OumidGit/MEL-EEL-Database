USE MEL_EEL_Automation_Dev;
GO
CREATE OR ALTER PROCEDURE audit.sp_run_mel_from_rawkv
  @project_code NVARCHAR(50),
  @file_id BIGINT,
  @sheet_name NVARCHAR(128) = N'Mechanical equipment List'
AS
BEGIN
  SET NOCOUNT ON;

  EXEC stg.sp_transform_mel_rawkv_to_mech
    @project_code=@project_code,
    @file_id=@file_id,
    @sheet_name=@sheet_name,
    @replace_stage=1;

  EXEC core.sp_upsert_equipment_mech @project_code=@project_code;
  EXEC out.sp_snapshot_load_list @project_code=@project_code;
END
GO

SELECT OBJECT_ID('stg.mel_raw_kv')      AS mel_raw_kv;
SELECT OBJECT_ID('stg.sp_transform_mel_rawkv_to_mech') AS transform_proc;
SELECT OBJECT_ID('audit.sp_run_mel_from_rawkv')        AS runner_proc;
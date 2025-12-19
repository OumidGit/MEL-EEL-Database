USE MEL_EEL_Automation_Dev;
GO
CREATE OR ALTER PROCEDURE stg.sp_transform_mel_rawkv_to_mech
  @project_code NVARCHAR(50),
  @file_id BIGINT,
  @sheet_name NVARCHAR(128) = N'Mechanical equipment List',
  @replace_stage BIT = 1
AS
BEGIN
  SET NOCOUNT ON;

  IF @replace_stage = 1
  BEGIN
    DELETE FROM stg.equipment_mech
    WHERE project_code=@project_code AND file_id=@file_id;
  END

  ;WITH mapped AS (
    SELECT r.row_idx, a.canonical_name, r.value_text, a.confidence
    FROM stg.mel_raw_kv r
    JOIN ref.column_aliases a
      ON LTRIM(RTRIM(a.alias_name)) = LTRIM(RTRIM(r.alias_name))
     AND a.source_scope = N'MEL'
    WHERE r.project_code=@project_code
      AND r.file_id=@file_id
      AND r.sheet_name=@sheet_name
  ),
  ranked AS (
    SELECT row_idx, canonical_name, value_text,
           ROW_NUMBER() OVER(
             PARTITION BY row_idx, canonical_name
             ORDER BY confidence DESC,
                      CASE WHEN value_text IS NULL OR LTRIM(RTRIM(value_text))='' THEN 1 ELSE 0 END
           ) rn
    FROM mapped
  ),
  chosen AS (
    SELECT row_idx, canonical_name, value_text
    FROM ranked WHERE rn=1
  )
  INSERT INTO stg.equipment_mech(project_code,file_id,equipment_tag)
  SELECT @project_code, @file_id,
         MAX(CASE WHEN canonical_name=N'equipment_tag' THEN value_text END)
  FROM chosen
  GROUP BY row_idx;
END
GO


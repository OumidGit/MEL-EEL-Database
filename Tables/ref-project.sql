USE MEL_EEL_Automation_Dev;
GO

-- Project Table Creation (Define list of all existing projects)
IF OBJECT_ID('ref.project','U') IS NULL
BEGIN
    CREATE TABLE ref.project(
        project_id       NVARCHAR(100) NOT NULL,
        project_name     NVARCHAR(100)  NOT NULL,
        CONSTRAINT PK_project PRIMARY KEY (project_id)
    );
END
GO

-- 2) Duty Types Definition
MERGE ref.project AS tgt
USING (VALUES
    (N'9334', N'Torngat Strange Lake FS'),
    (N'9353', N'Valentine Gold Mine'),
    (N'9753', N'Spring Valley EP'),
    (N'9754', N'Hudbay DE')
) AS src(project_id, project_name)
ON (tgt.project_id = src.project_id)
WHEN MATCHED THEN
  UPDATE SET project_name=src.project_name
WHEN NOT MATCHED THEN
  INSERT(project_id,project_name) VALUES(src.project_id,src.project_name);
USE MEL_EEL_Automation_Dev;
GO

-- Defines links between an employee and a project, in order to define who can access what
IF OBJECT_ID('ref.access','U') IS NULL
BEGIN
    CREATE TABLE ref.access (
        employee_id  NVARCHAR(100) NOT NULL,
        project_id   NVARCHAR(100) NOT NULL,

        CONSTRAINT PK_access
            PRIMARY KEY (employee_id, project_id),

        CONSTRAINT FK_access_employee 
            FOREIGN KEY (employee_id) 
            REFERENCES ref.employee(employee_id),

        CONSTRAINT FK_access_project 
            FOREIGN KEY (project_id) 
            REFERENCES ref.project(project_id)
    );
END
GO

--Define access here:
MERGE ref.access AS tgt
USING (SELECT DISTINCT employee_id, project_id
    FROM (VALUES
    (N'1', N'9334'),
    (N'1', N'9353'),
    (N'2', N'9753'),
    (N'2', N'9754'),
    (N'1', N'9753')
    )AS v(employee_id, project_id)
) AS src
ON tgt.employee_id = src.employee_id
AND tgt.project_id = src.project_id
WHEN NOT MATCHED THEN
    INSERT (employee_id, project_id)
    VALUES (src.employee_id, src.project_id);
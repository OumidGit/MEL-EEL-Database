USE MEL_EEL_Automation_Dev;
GO

-- Employee Table Creation (Define list of employees)
IF OBJECT_ID('ref.employee','U') IS NULL
BEGIN
    CREATE TABLE ref.employee(
        employee_id       NVARCHAR(100)  NOT NULL,
        employee_name     NVARCHAR(100)  NOT NULL,
        CONSTRAINT PK_employee PRIMARY KEY (employee_id)
    );
END
GO

-- 2) Duty Types Definition
MERGE ref.employee AS tgt
USING (VALUES
    (N'1', N'mohamed-amine.oumid'),
    (N'2', N'kevin.reeves'),
    (N'3', N'jason,gaulton'),
    (N'4', N'alexis.desjardins')
) AS src(employee_id, employee_name)
ON (tgt.employee_id = src.employee_id)
WHEN MATCHED THEN
  UPDATE SET employee_name=src.employee_name
WHEN NOT MATCHED THEN
  INSERT(employee_id,employee_name) VALUES(src.employee_id,src.employee_name);
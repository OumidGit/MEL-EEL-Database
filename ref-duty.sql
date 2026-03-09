USE MEL_EEL_Automation_Dev;
GO

-- Duty reference Table Creation (Define a duty type for each duty possible)
IF OBJECT_ID('ref.duty','U') IS NULL
BEGIN
    CREATE TABLE ref.duty(
        duty       NVARCHAR(100) NOT NULL,
        duty_type DECIMAL(6,3)  NOT NULL,
        CONSTRAINT PK_duty PRIMARY KEY (duty)
    );
END
GO

-- 2) Duty Types Definition
MERGE ref.duty AS tgt
USING (VALUES
    (N'Duty', 1.00),
    (N'Intermittent 1', 0.50),
    (N'Intermittent 2', 0.20),
    (N'Standby', 0.00)
) AS src(duty, duty_type)
ON (tgt.duty = src.duty)
WHEN MATCHED THEN
  UPDATE SET duty_type=src.duty_type
WHEN NOT MATCHED THEN
  INSERT(duty,duty_type) VALUES(src.duty,src.duty_type);
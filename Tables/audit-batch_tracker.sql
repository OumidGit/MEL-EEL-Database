USE MEL_EEL_Automation_Dev;
GO

-- Batch Tracker Table Creation (List of Batches pushed onto server/database)
IF OBJECT_ID('audit.batch_tracker','U') IS NULL
BEGIN
    CREATE TABLE audit.batch_tracker(
        batch_id          UNIQUEIDENTIFIER NOT NULL,
        employee_name     NVARCHAR(100)  NOT NULL,
        project_id        NVARCHAR(100)  NOT NULL,
        status            NVARCHAR(100)  NOT NULL,
        push_time         DATETIME NOT NULL,
        CONSTRAINT PK_batch_tracker PRIMARY KEY (batch_id)
    );
END
GO
USE MEL_EEL_Automation_Dev;
GO

CREATE OR ALTER PROCEDURE audit.calculate_MEL_project_completion
    @project_code NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @total_rows BIGINT;
    DECLARE @total_columns BIGINT;
    DECLARE @total_cells BIGINT;
    DECLARE @filled_cells BIGINT;
    DECLARE @empty_cells BIGINT;
    DECLARE @completion_percentage DECIMAL(9,4);
    DECLARE @values_list NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    ------------------------------------------------------------
    -- Guardrail: project exists
    ------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
        FROM core.MEL
        WHERE project_code = @project_code
    )
        RAISERROR('No rows found in core.MEL for this project_code.', 16, 1);

    ------------------------------------------------------------
    -- Get columns to include in calculation
    -- Exclude technical/tracking columns
    ------------------------------------------------------------
    SELECT @total_columns = COUNT(*)
    FROM sys.columns
    WHERE object_id = OBJECT_ID('core.MEL')
      AND name NOT IN (
            'project_code',
            'project_DB_ID',
            'batch_id',
            'file_id',
            'raw_row_json'
      );

    IF @total_columns = 0
        RAISERROR('No columns available for completion calculation.', 16, 1);

    ------------------------------------------------------------
    -- Build dynamic VALUES list:
    -- each included column becomes one cell to check
    ------------------------------------------------------------
    SELECT @values_list =
        STRING_AGG(
            CAST(
                '(CONVERT(NVARCHAR(MAX), m.' + QUOTENAME(name) + '))'
                AS NVARCHAR(MAX)
            ),
            ',' + CHAR(13) + CHAR(10)
        )
    FROM sys.columns
    WHERE object_id = OBJECT_ID('core.MEL')
      AND name NOT IN (
            'project_code',
            'project_DB_ID',
            'batch_id',
            'file_id',
            'raw_row_json'
      );

    ------------------------------------------------------------
    -- Calculate completion
    ------------------------------------------------------------
    SET @sql = N'
        SELECT
            @total_rows_out = COUNT(DISTINCT m.project_DB_ID),
            @total_cells_out = COUNT_BIG(*),
            @filled_cells_out = SUM(
                CASE
                    WHEN v.cell_value IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(v.cell_value)), '''') IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            )
        FROM core.MEL m
        CROSS APPLY
        (
            VALUES
            ' + @values_list + N'
        ) v(cell_value)
        WHERE m.project_code = @project_code_in;
    ';

    EXEC sp_executesql
        @sql,
        N'
            @project_code_in NVARCHAR(50),
            @total_rows_out BIGINT OUTPUT,
            @total_cells_out BIGINT OUTPUT,
            @filled_cells_out BIGINT OUTPUT
        ',
        @project_code_in = @project_code,
        @total_rows_out = @total_rows OUTPUT,
        @total_cells_out = @total_cells OUTPUT,
        @filled_cells_out = @filled_cells OUTPUT;

    SET @empty_cells = @total_cells - @filled_cells;

    SET @completion_percentage =
        CASE
            WHEN @total_cells = 0 THEN 0
            ELSE CAST((@filled_cells * 100.0 / @total_cells) AS DECIMAL(9,4))
        END;

    ------------------------------------------------------------
    -- Return result
    ------------------------------------------------------------
    SELECT
        @project_code AS project_code,
        @total_rows AS total_rows,
        @total_columns AS total_columns,
        @total_cells AS total_cells,
        @filled_cells AS filled_cells,
        @empty_cells AS empty_cells,
        @completion_percentage AS completion_percentage;
END;
GO
USE MEL_EEL_Automation_Dev;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='calc') EXEC('CREATE SCHEMA calc AUTHORIZATION dbo;');
GO
CREATE OR ALTER FUNCTION calc.fn_resolve_demand_factor(@project_code NVARCHAR(50), @eq_type NVARCHAR(100))
RETURNS DECIMAL(6,3)
AS
BEGIN
  DECLARE @df DECIMAL(6,3);
  SELECT TOP (1) @df = df.demand_factor
  FROM ref.demand_factors df
  WHERE df.eq_type = @eq_type
    AND (df.project_code = @project_code OR ISNULL(df.project_code,'') = '')
  ORDER BY CASE WHEN df.project_code = @project_code THEN 1 ELSE 2 END;
  RETURN ISNULL(@df, 1.0);
END;
GO
CREATE OR ALTER FUNCTION calc.fn_compute_kva(@kw DECIMAL(18,4), @pf DECIMAL(9,6))
RETURNS DECIMAL(18,4)
AS
BEGIN
  IF @pf IS NULL OR @pf = 0 RETURN NULL;
  RETURN CAST(@kw / @pf AS DECIMAL(18,4));
END;
GO
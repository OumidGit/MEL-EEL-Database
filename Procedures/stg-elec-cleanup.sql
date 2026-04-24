USE MEL_EEL_Automation_Dev;
GO

CREATE OR ALTER PROCEDURE stg.elec_cleanup
    @batch_id UNIQUEIDENTIFIER,
    @default_absorbed_kw DECIMAL(18,6) = NULL

AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        ------------------------------------------------------------
        -- 0) Guardrail
        ------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM stg.MEL WHERE batch_id = @batch_id)
            RAISERROR('stg.elec_cleanup: No rows found in stg.MEL for this batch_id.', 16, 1);

        ------------------------------------------------------------
        -- 1) Cleanup: TRIM + empty => NULL (keep it light)
        ------------------------------------------------------------
        UPDATE m
        SET
            project_code           = NULLIF(LTRIM(RTRIM(project_code)), ''),
            project_DB_ID          = NULLIF(LTRIM(RTRIM(project_DB_ID)), ''),
            eq_tag                 = NULLIF(LTRIM(RTRIM(eq_tag)), ''),
            duty                   = NULLIF(LTRIM(RTRIM(duty)), ''),
            forced_duty            = NULLIF(LTRIM(RTRIM(forced_duty)), ''),
            duty_type              = NULLIF(LTRIM(RTRIM(duty_type)), ''),
            qty                    = NULLIF(LTRIM(RTRIM(qty)), ''),
            nameplate_power_kw     = NULLIF(LTRIM(RTRIM(nameplate_power_kw)), ''),
            forced_nameplate_power = NULLIF(LTRIM(RTRIM(forced_nameplate_power)), ''),
            absorbed_power_kw      = NULLIF(LTRIM(RTRIM(absorbed_power_kw)), ''),
            utilization_factor     = NULLIF(LTRIM(RTRIM(utilization_factor)), ''),
            starter_type           = NULLIF(LTRIM(RTRIM(starter_type)), ''),
            forced_starter_type    = NULLIF(LTRIM(RTRIM(forced_starter_type)), ''),
            load_type              = NULLIF(LTRIM(RTRIM(load_type)), ''),
            voltage_v              = NULLIF(LTRIM(RTRIM(voltage_v)), ''),
            power_factor           = NULLIF(LTRIM(RTRIM(power_factor)), ''),
            efficiency             = NULLIF(LTRIM(RTRIM(efficiency)), ''),
            demand_factor          = NULLIF(LTRIM(RTRIM(demand_factor)), '')
        FROM stg.MEL m
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 2) Delete junk rows (missing keys)
        ------------------------------------------------------------
        DELETE FROM stg.MEL
        WHERE batch_id = @batch_id
          AND (project_code IS NULL OR project_DB_ID IS NULL);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH

END
GO
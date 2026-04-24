CREATE OR ALTER PROCEDURE audit.take_MEL_daily_snapshot
    @snapshot_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @snapshot_date IS NULL
        SET @snapshot_date = CONVERT(DATE, GETDATE());

    BEGIN TRY
        BEGIN TRAN;

        DELETE FROM audit.MEL_daily_snapshot
        WHERE snapshot_date = @snapshot_date;

        INSERT INTO audit.MEL_daily_snapshot
        (
            snapshot_date,
            project_code, project_DB_ID, batch_id, file_id, eq_status, Area, eq_type, code, eq_tag,
            eq_desc, rev, qty, nameplate_power_kw, nameplate_power_hp, absorbed_power_kw,
            utilization_factor, starter_type, load_type, duty, emergency_load, poles,
            forced_duty, duty_type, demand_factor, power_factor, efficiency, voltage_v,
            phase, eroom, transformer, mcc_switchgear, forced_nameplate_power,
            bucket_size, forced_starter_type, installed_kw, installed_kvar, installed_kva,
            peak_kw, peak_kvar, peak_kva, average_kw, average_kvar, average_kva,
            annual_load_mwh, fla, current_draw, fla_125pct, remarks, location, raw_row_json
        )
        SELECT
            @snapshot_date,
            project_code, project_DB_ID, batch_id, file_id, eq_status, Area, eq_type, code, eq_tag,
            eq_desc, rev, qty, nameplate_power_kw, nameplate_power_hp, absorbed_power_kw,
            utilization_factor, starter_type, load_type, duty, emergency_load, poles,
            forced_duty, duty_type, demand_factor, power_factor, efficiency, voltage_v,
            phase, eroom, transformer, mcc_switchgear, forced_nameplate_power,
            bucket_size, forced_starter_type, installed_kw, installed_kvar, installed_kva,
            peak_kw, peak_kvar, peak_kva, average_kw, average_kvar, average_kva,
            annual_load_mwh, fla, current_draw, fla_125pct, remarks, location, raw_row_json
        FROM core.MEL;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
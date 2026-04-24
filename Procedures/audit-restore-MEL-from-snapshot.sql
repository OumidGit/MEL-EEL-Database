CREATE OR ALTER PROCEDURE audit.restore_MEL_from_snapshot
    @snapshot_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM audit.MEL_daily_snapshot
        WHERE snapshot_date = @snapshot_date
    )
        RAISERROR('No MEL snapshot exists for the requested snapshot_date.', 16, 1);

    BEGIN TRY
        BEGIN TRAN;

        DELETE FROM core.MEL;

        INSERT INTO core.MEL
        (
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
            project_code, project_DB_ID, batch_id, file_id, eq_status, Area, eq_type, code, eq_tag,
            eq_desc, rev, qty, nameplate_power_kw, nameplate_power_hp, absorbed_power_kw,
            utilization_factor, starter_type, load_type, duty, emergency_load, poles,
            forced_duty, duty_type, demand_factor, power_factor, efficiency, voltage_v,
            phase, eroom, transformer, mcc_switchgear, forced_nameplate_power,
            bucket_size, forced_starter_type, installed_kw, installed_kvar, installed_kva,
            peak_kw, peak_kvar, peak_kva, average_kw, average_kva, average_kva,
            annual_load_mwh, fla, current_draw, fla_125pct, remarks, location, raw_row_json
        FROM audit.MEL_daily_snapshot
        WHERE snapshot_date = @snapshot_date;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
USE MEL_EEL_Automation_Dev;
GO

CREATE OR ALTER PROCEDURE stg.elec_push_core
    @batch_id UNIQUEIDENTIFIER,
    @default_absorbed_kw DECIMAL(18,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (SELECT 1 FROM stg.MEL WHERE batch_id = @batch_id)
            RAISERROR('stg.elec_push_core: No rows found in stg.MEL for this batch_id.', 16, 1);

        IF EXISTS (
            SELECT 1
            FROM stg.MEL
            WHERE batch_id = @batch_id
              AND NULLIF(LTRIM(RTRIM(project_DB_ID)), '') IS NULL
        )
            RAISERROR('stg.elec_push_core: project_DB_ID is blank for one or more rows. Cannot merge into core.MEL.', 16, 1);

        IF EXISTS (
            SELECT 1
            FROM stg.MEL
            WHERE batch_id = @batch_id
            GROUP BY project_code, project_DB_ID
            HAVING COUNT(*) > 1
        )
            RAISERROR('stg.elec_push_core: Duplicate project_code + project_DB_ID found in stg.MEL for this batch_id.', 16, 1);

        ;MERGE core.MEL AS tgt
        USING (
            SELECT *
            FROM stg.MEL
            WHERE batch_id = @batch_id
        ) AS src
        ON  tgt.project_code  = src.project_code
        AND tgt.project_DB_ID = src.project_DB_ID

        WHEN MATCHED THEN
            UPDATE SET
                tgt.batch_id =
                    CASE
                        WHEN ISNULL(tgt.file_id,'')                 <> ISNULL(src.file_id,'')
                          OR ISNULL(tgt.eq_status,'')              <> ISNULL(src.eq_status,'')
                          OR ISNULL(tgt.Area,'')                   <> ISNULL(src.Area,'')
                          OR ISNULL(tgt.eq_type,'')                <> ISNULL(src.eq_type,'')
                          OR ISNULL(tgt.code,'')                   <> ISNULL(src.code,'')
                          OR ISNULL(tgt.eq_tag,'')                 <> ISNULL(src.eq_tag,'')
                          OR ISNULL(tgt.eq_desc,'')                <> ISNULL(src.eq_desc,'')
                          OR ISNULL(tgt.rev,'')                    <> ISNULL(src.rev,'')
                          OR ISNULL(tgt.qty,'')                    <> ISNULL(src.qty,'')
                          OR ISNULL(tgt.nameplate_power_kw,'')     <> ISNULL(src.nameplate_power_kw,'')
                          OR ISNULL(tgt.nameplate_power_hp,'')     <> ISNULL(src.nameplate_power_hp,'')
                          OR ISNULL(tgt.absorbed_power_kw,'')      <> ISNULL(src.absorbed_power_kw,'')
                          OR ISNULL(tgt.utilization_factor,'')     <> ISNULL(src.utilization_factor,'')
                          OR ISNULL(tgt.starter_type,'')           <> ISNULL(src.starter_type,'')
                          OR ISNULL(tgt.load_type,'')              <> ISNULL(src.load_type,'')
                          OR ISNULL(tgt.duty,'')                   <> ISNULL(src.duty,'')
                          OR ISNULL(tgt.emergency_load,'')         <> ISNULL(src.emergency_load,'')
                          OR ISNULL(tgt.poles,'')                  <> ISNULL(src.poles,'')
                          OR ISNULL(tgt.forced_duty,'')            <> ISNULL(src.forced_duty,'')
                          OR ISNULL(tgt.duty_type,'')              <> ISNULL(src.duty_type,'')
                          OR ISNULL(tgt.demand_factor,'')          <> ISNULL(src.demand_factor,'')
                          OR ISNULL(tgt.power_factor,'')           <> ISNULL(src.power_factor,'')
                          OR ISNULL(tgt.efficiency,'')             <> ISNULL(src.efficiency,'')
                          OR ISNULL(tgt.voltage_v,'')              <> ISNULL(src.voltage_v,'')
                          OR ISNULL(tgt.phase,'')                  <> ISNULL(src.phase,'')
                          OR ISNULL(tgt.eroom,'')                  <> ISNULL(src.eroom,'')
                          OR ISNULL(tgt.transformer,'')            <> ISNULL(src.transformer,'')
                          OR ISNULL(tgt.mcc_switchgear,'')         <> ISNULL(src.mcc_switchgear,'')
                          OR ISNULL(tgt.forced_nameplate_power,'') <> ISNULL(src.forced_nameplate_power,'')
                          OR ISNULL(tgt.bucket_size,'')            <> ISNULL(src.bucket_size,'')
                          OR ISNULL(tgt.forced_starter_type,'')    <> ISNULL(src.forced_starter_type,'')
                          OR ISNULL(tgt.installed_kw,'')           <> ISNULL(src.installed_kw,'')
                          OR ISNULL(tgt.installed_kvar,'')         <> ISNULL(src.installed_kvar,'')
                          OR ISNULL(tgt.installed_kva,'')          <> ISNULL(src.installed_kva,'')
                          OR ISNULL(tgt.peak_kw,'')                <> ISNULL(src.peak_kw,'')
                          OR ISNULL(tgt.peak_kvar,'')              <> ISNULL(src.peak_kvar,'')
                          OR ISNULL(tgt.peak_kva,'')               <> ISNULL(src.peak_kva,'')
                          OR ISNULL(tgt.average_kw,'')             <> ISNULL(src.average_kw,'')
                          OR ISNULL(tgt.average_kvar,'')           <> ISNULL(src.average_kvar,'')
                          OR ISNULL(tgt.average_kva,'')            <> ISNULL(src.average_kva,'')
                          OR ISNULL(tgt.annual_load_mwh,'')        <> ISNULL(src.annual_load_mwh,'')
                          OR ISNULL(tgt.fla,'')                    <> ISNULL(src.fla,'')
                          OR ISNULL(tgt.current_draw,'')           <> ISNULL(src.current_draw,'')
                          OR ISNULL(tgt.fla_125pct,'')             <> ISNULL(src.fla_125pct,'')
                          OR ISNULL(tgt.remarks,'')                <> ISNULL(src.remarks,'')
                          OR ISNULL(tgt.location,'')               <> ISNULL(src.location,'')
                          OR ISNULL(tgt.raw_row_json,'')           <> ISNULL(src.raw_row_json,'')
                        THEN src.batch_id
                        ELSE tgt.batch_id
                    END,

                tgt.file_id                = src.file_id,
                tgt.eq_status              = src.eq_status,
                tgt.Area                   = src.Area,
                tgt.eq_type                = src.eq_type,
                tgt.code                   = src.code,
                tgt.eq_tag                 = src.eq_tag,
                tgt.eq_desc                = src.eq_desc,
                tgt.rev                    = src.rev,
                tgt.qty                    = src.qty,
                tgt.nameplate_power_kw     = src.nameplate_power_kw,
                tgt.nameplate_power_hp     = src.nameplate_power_hp,
                tgt.absorbed_power_kw      = src.absorbed_power_kw,
                tgt.utilization_factor     = src.utilization_factor,
                tgt.starter_type           = src.starter_type,
                tgt.load_type              = src.load_type,
                tgt.duty                   = src.duty,
                tgt.emergency_load         = src.emergency_load,
                tgt.poles                  = src.poles,
                tgt.forced_duty            = src.forced_duty,
                tgt.duty_type              = src.duty_type,
                tgt.demand_factor          = src.demand_factor,
                tgt.power_factor           = src.power_factor,
                tgt.efficiency             = src.efficiency,
                tgt.voltage_v              = src.voltage_v,
                tgt.phase                  = src.phase,
                tgt.eroom                  = src.eroom,
                tgt.transformer            = src.transformer,
                tgt.mcc_switchgear         = src.mcc_switchgear,
                tgt.forced_nameplate_power = src.forced_nameplate_power,
                tgt.bucket_size            = src.bucket_size,
                tgt.forced_starter_type    = src.forced_starter_type,
                tgt.installed_kw           = src.installed_kw,
                tgt.installed_kvar         = src.installed_kvar,
                tgt.installed_kva          = src.installed_kva,
                tgt.peak_kw                = src.peak_kw,
                tgt.peak_kvar              = src.peak_kvar,
                tgt.peak_kva               = src.peak_kva,
                tgt.average_kw             = src.average_kw,
                tgt.average_kvar           = src.average_kvar,
                tgt.average_kva            = src.average_kva,
                tgt.annual_load_mwh        = src.annual_load_mwh,
                tgt.fla                    = src.fla,
                tgt.current_draw           = src.current_draw,
                tgt.fla_125pct             = src.fla_125pct,
                tgt.remarks                = src.remarks,
                tgt.location               = src.location,
                tgt.raw_row_json           = src.raw_row_json

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                project_code, project_DB_ID, batch_id, file_id, eq_status, Area, eq_type, code, eq_tag, eq_desc, rev, qty,
                nameplate_power_kw, nameplate_power_hp, absorbed_power_kw, utilization_factor,
                starter_type, load_type, duty, emergency_load, poles,
                forced_duty, duty_type, demand_factor, power_factor, efficiency, voltage_v, phase, eroom, transformer, mcc_switchgear,
                forced_nameplate_power, bucket_size, forced_starter_type,
                installed_kw, installed_kvar, installed_kva, peak_kw, peak_kvar, peak_kva, average_kw, average_kvar, average_kva,
                annual_load_mwh, fla, current_draw, fla_125pct, remarks,
                location, raw_row_json
            )
            VALUES (
                src.project_code, src.project_DB_ID, src.batch_id, src.file_id, src.eq_status, src.Area, src.eq_type, src.code, src.eq_tag, src.eq_desc, src.rev, src.qty,
                src.nameplate_power_kw, src.nameplate_power_hp, src.absorbed_power_kw, src.utilization_factor,
                src.starter_type, src.load_type, src.duty, src.emergency_load, src.poles,
                src.forced_duty, src.duty_type, src.demand_factor, src.power_factor, src.efficiency, src.voltage_v, src.phase, src.eroom, src.transformer, src.mcc_switchgear,
                src.forced_nameplate_power, src.bucket_size, src.forced_starter_type,
                src.installed_kw, src.installed_kvar, src.installed_kva, src.peak_kw, src.peak_kvar, src.peak_kva, src.average_kw, src.average_kvar, src.average_kva,
                src.annual_load_mwh, src.fla, src.current_draw, src.fla_125pct, src.remarks,
                src.location, src.raw_row_json
            );

        DELETE FROM stg.MEL
        WHERE batch_id = @batch_id;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
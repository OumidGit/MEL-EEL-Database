USE MEL_EEL_Automation_Dev;
GO

CREATE OR ALTER PROCEDURE stg.sp_transform_mel_rawkv_to_mech
    @project_code NVARCHAR(50),
    @file_id      BIGINT,
    @sheet_name   NVARCHAR(128) = N'Mechanical equipment List',  -- adjust to your workbook
    @replace_stage BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @replace_stage = 1
    BEGIN
        DELETE FROM stg.equipment_mech
        WHERE project_code = @project_code
          AND file_id = @file_id;
    END
    
    /*
      1) mapped: join raw KV to ref.column_aliases (MEL scope)
      2) ranked: for each row_idx + canonical_name, pick the best candidate by confidence
      3) chosen: keep only rn=1 (the winner)
      4) final insert: conditional aggregation into stg.equipment_mech columns
    */

    ;WITH mapped AS (
        SELECT
            r.project_code,
            r.file_id,
            r.sheet_name,
            r.row_idx,
            a.canonical_name,
            r.value_text,
            a.confidence
        FROM stg.mel_raw_kv r
        JOIN ref.column_aliases a
          ON LTRIM(RTRIM(a.alias_name)) = LTRIM(RTRIM(r.alias_name))
         AND a.source_scope = N'MEL'
        WHERE r.project_code = @project_code
          AND r.file_id = @file_id
          AND r.sheet_name = @sheet_name
    ),
    ranked AS (
        SELECT
            project_code, file_id, sheet_name, row_idx, canonical_name, value_text,
            ROW_NUMBER() OVER (
                PARTITION BY project_code, file_id, sheet_name, row_idx, canonical_name
                ORDER BY confidence DESC,
                         CASE WHEN value_text IS NULL OR LTRIM(RTRIM(value_text)) = '' THEN 1 ELSE 0 END
            ) AS rn
        FROM mapped
    ),
    chosen AS (
        SELECT project_code, file_id, sheet_name, row_idx, canonical_name, value_text
        FROM ranked
        WHERE rn = 1
    )
    INSERT INTO stg.equipment_mech
    (
        project_code,
        file_id,

        -- canonical columns (must exist in stg.equipment_mech)
        status,
        equipment_tag,
        area,
        eq_type,
        code,
        eq_num,
        description,
        revision,
        supplied_by,
        installed_by,
        connected_by,
        model,
        dimension_l,
        dimension_w,
        dimension_h,
        specifications,
        comments,
        plant_section,
        pfd,
        p_id,
        responsible_eqlist,
        package,
        package_engineer,
        demand_factor,
        poles,
        utilization_factor,
        motor_kw,
        total_load_kw,
        drive_type,
        duty_type,
        load_type,
        emergency_load,
        absorbed_power_kw,
        mp,
        mass_bal,

        -- compatibility fields (if present in chosen, they’ll be set; else remain NULL)
        connected_load_kw,
        voltage_v,
        power_factor_pf,
        starter_type,
        location,

        raw_row_json
    )
    SELECT
        @project_code AS project_code,
        @file_id      AS file_id,

        MAX(CASE WHEN canonical_name = N'status'             THEN value_text END) AS status,
        MAX(CASE WHEN canonical_name = N'equipment_tag'      THEN value_text END) AS equipment_tag,
        MAX(CASE WHEN canonical_name = N'area'               THEN value_text END) AS area,
        MAX(CASE WHEN canonical_name = N'eq_type'            THEN value_text END) AS eq_type,
        MAX(CASE WHEN canonical_name = N'code'               THEN value_text END) AS code,
        MAX(CASE WHEN canonical_name = N'eq_num'             THEN value_text END) AS eq_num,
        MAX(CASE WHEN canonical_name = N'description'        THEN value_text END) AS description,
        MAX(CASE WHEN canonical_name = N'revision'           THEN value_text END) AS revision,
        MAX(CASE WHEN canonical_name = N'supplied_by'        THEN value_text END) AS supplied_by,
        MAX(CASE WHEN canonical_name = N'installed_by'       THEN value_text END) AS installed_by,
        MAX(CASE WHEN canonical_name = N'connected_by'       THEN value_text END) AS connected_by,
        MAX(CASE WHEN canonical_name = N'model'              THEN value_text END) AS model,

        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'dimension_l' THEN value_text END)) AS dimension_l,
        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'dimension_w' THEN value_text END)) AS dimension_w,
        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'dimension_h' THEN value_text END)) AS dimension_h,

        MAX(CASE WHEN canonical_name = N'specifications'      THEN value_text END) AS specifications,
        MAX(CASE WHEN canonical_name = N'comments'            THEN value_text END) AS comments,
        MAX(CASE WHEN canonical_name = N'plant_section'       THEN value_text END) AS plant_section,
        MAX(CASE WHEN canonical_name = N'pfd'                 THEN value_text END) AS pfd,
        MAX(CASE WHEN canonical_name = N'p_id'                THEN value_text END) AS p_id,
        MAX(CASE WHEN canonical_name = N'responsible_eqlist'  THEN value_text END) AS responsible_eqlist,
        MAX(CASE WHEN canonical_name = N'package'             THEN value_text END) AS package,
        MAX(CASE WHEN canonical_name = N'package_engineer'    THEN value_text END) AS package_engineer,

        TRY_CONVERT(DECIMAL(6,3),  MAX(CASE WHEN canonical_name = N'demand_factor'      THEN value_text END)) AS demand_factor,
        TRY_CONVERT(INT,           MAX(CASE WHEN canonical_name = N'poles'              THEN value_text END)) AS poles,
        TRY_CONVERT(DECIMAL(6,3),  MAX(CASE WHEN canonical_name = N'utilization_factor' THEN value_text END)) AS utilization_factor,
        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'motor_kw'           THEN value_text END)) AS motor_kw,
        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'total_load_kw'      THEN value_text END)) AS total_load_kw,

        MAX(CASE WHEN canonical_name = N'drive_type'          THEN value_text END) AS drive_type,
        MAX(CASE WHEN canonical_name = N'duty_type'           THEN value_text END) AS duty_type,
        MAX(CASE WHEN canonical_name = N'load_type'           THEN value_text END) AS load_type,
        MAX(CASE WHEN canonical_name = N'emergency_load'      THEN value_text END) AS emergency_load,
        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'absorbed_power_kw'  THEN value_text END)) AS absorbed_power_kw,
        MAX(CASE WHEN canonical_name = N'mp'                  THEN value_text END) AS mp,
        MAX(CASE WHEN canonical_name = N'mass_bal'            THEN value_text END) AS mass_bal,

        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'connected_load_kw' THEN value_text END)) AS connected_load_kw,
        TRY_CONVERT(DECIMAL(18,4), MAX(CASE WHEN canonical_name = N'voltage_v'         THEN value_text END)) AS voltage_v,
        TRY_CONVERT(DECIMAL(9,6),  MAX(CASE WHEN canonical_name = N'power_factor_pf'   THEN value_text END)) AS power_factor_pf,
        MAX(CASE WHEN canonical_name = N'starter_type'        THEN value_text END) AS starter_type,
        MAX(CASE WHEN canonical_name = N'location'            THEN value_text END) AS location,

        NULL AS raw_row_json
    FROM chosen
    GROUP BY row_idx;

END;
GO
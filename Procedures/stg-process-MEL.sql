USE MEL_EEL_Automation_Dev;
GO

CREATE OR ALTER PROCEDURE stg.process_MEL
    @batch_id UNIQUEIDENTIFIER,
    @default_absorbed_kw DECIMAL(18,6) = NULL,  -- optional Excel $T$4 equivalent
    @delete_staging_after BIT = 0
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
            RAISERROR('stg.process_MEL: No rows found in stg.MEL for this batch_id.', 16, 1);

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
          AND (project_code IS NULL OR eq_tag IS NULL);

        ------------------------------------------------------------
        -- 3) DUTY_TYPE (Correct)
        --    forced_duty if present else duty -> ref.duty.duty -> ref.duty.duty_type
        --    Case/space tolerant
        ------------------------------------------------------------
        UPDATE m
        SET m.duty_type = CONVERT(NVARCHAR(100), d.duty_type)
        FROM stg.MEL m
        LEFT JOIN ref.duty d
          ON UPPER(LTRIM(RTRIM(d.duty))) =
             UPPER(LTRIM(RTRIM(COALESCE(NULLIF(m.forced_duty,''), NULLIF(m.duty,'')))))
        WHERE m.batch_id = @batch_id
          AND m.duty_type IS NULL;

        ------------------------------------------------------------
        -- 4) Calc cache (#calc) to avoid Msg 8632 expression limit
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#calc') IS NOT NULL DROP TABLE #calc;

        CREATE TABLE #calc
        (
            project_code NVARCHAR(50)  NOT NULL,
            eq_tag       NVARCHAR(100) NOT NULL,

            qty_n        DECIMAL(18,6) NULL,
            np_kw        DECIMAL(18,6) NULL,
            abs_kw_used  DECIMAL(18,6) NULL,
            uf_n         DECIMAL(18,6) NULL,
            v_n          DECIMAL(18,6) NULL,

            duty_type_n  DECIMAL(18,6) NULL,
            df_num       DECIMAL(18,6) NULL,
            band_sel     INT           NULL,   -- 50/75/100

            pf_num       DECIMAL(18,6) NULL,
            eff_num      DECIMAL(18,6) NULL,
            mot_fla      DECIMAL(18,6) NULL,

            load_type_norm NVARCHAR(20) NULL
        );

        -- FIXED: columns count matches SELECT count (14 each)
        INSERT INTO #calc
        (
            project_code, eq_tag,
            qty_n, np_kw, abs_kw_used, uf_n, v_n,
            duty_type_n, df_num, band_sel,
            pf_num, eff_num, mot_fla,
            load_type_norm
        )
        SELECT
            m.project_code,
            m.eq_tag,

            TRY_CONVERT(DECIMAL(18,6), REPLACE(m.qty, ',', '')),

            CASE
                WHEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.forced_nameplate_power, ',', '')) IS NOT NULL
                 AND TRY_CONVERT(DECIMAL(18,6), REPLACE(m.forced_nameplate_power, ',', '')) <> 0
                THEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.forced_nameplate_power, ',', ''))
                ELSE TRY_CONVERT(DECIMAL(18,6), REPLACE(m.nameplate_power_kw, ',', ''))
            END,

            COALESCE(TRY_CONVERT(DECIMAL(18,6), REPLACE(m.absorbed_power_kw, ',', '')), @default_absorbed_kw),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(m.utilization_factor, ',', '')),
            TRY_CONVERT(DECIMAL(18,6), REPLACE(m.voltage_v, ',', '')),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(m.duty_type, ',', '')),

            CASE
                WHEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.demand_factor, ',', '')) IS NOT NULL
                THEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.demand_factor, ',', ''))
                ELSE NULL
            END,

            NULL, -- band_sel
            NULL, -- pf_num
            NULL, -- eff_num
            NULL, -- mot_fla

            UPPER(COALESCE(NULLIF(m.load_type,''),''))
        FROM stg.MEL m
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 5) demand_factor if NULL: abs_kw_used / np_kw
        ------------------------------------------------------------
        UPDATE c
        SET c.df_num =
            CASE
                WHEN c.df_num IS NOT NULL THEN c.df_num
                WHEN c.abs_kw_used IS NULL THEN NULL
                WHEN c.np_kw IS NULL OR c.np_kw = 0 THEN NULL
                ELSE c.abs_kw_used / c.np_kw
            END
        FROM #calc c;

        ------------------------------------------------------------
        -- 6) band selection (50/75/100) based on demand_factor
        ------------------------------------------------------------
        UPDATE c
        SET c.band_sel =
            CASE
                WHEN c.df_num IS NULL THEN 100
                WHEN ABS(c.df_num - 0.50) <= ABS(c.df_num - 0.75)
                 AND ABS(c.df_num - 0.50) <= ABS(c.df_num - 1.00) THEN 50
                WHEN ABS(c.df_num - 0.75) <= ABS(c.df_num - 1.00) THEN 75
                ELSE 100
            END
        FROM #calc c;

        ------------------------------------------------------------
        -- 7) PF / Eff / Motor FLA (VFD/VSD override else ref.motor)
        ------------------------------------------------------------
        UPDATE c
        SET
            c.pf_num =
                CASE
                    WHEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.power_factor, ',', '')) IS NOT NULL
                        THEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.power_factor, ',', ''))
                    WHEN UPPER(COALESCE(NULLIF(m.forced_starter_type,''), NULLIF(m.starter_type,''))) IN ('VFD','VSD')
                        THEN 0.97
                    ELSE
                        CASE c.band_sel
                            WHEN 50 THEN TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.PF_50, mx.PF_50))
                            WHEN 75 THEN TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.PF_75, mx.PF_75))
                            ELSE      TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.PF_100, mx.PF_100))
                        END
                END,

            c.eff_num =
                CASE
                    WHEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.efficiency, ',', '')) IS NOT NULL
                        THEN TRY_CONVERT(DECIMAL(18,6), REPLACE(m.efficiency, ',', ''))
                    WHEN UPPER(COALESCE(NULLIF(m.forced_starter_type,''), NULLIF(m.starter_type,''))) IN ('VFD','VSD')
                        THEN 0.96
                    ELSE
                        CASE c.band_sel
                            WHEN 50 THEN TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.Eff_50, mx.Eff_50))
                            WHEN 75 THEN TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.Eff_75, mx.Eff_75))
                            ELSE      TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.Eff_100, mx.Eff_100))
                        END
                END,

            c.mot_fla = TRY_CONVERT(DECIMAL(18,6), COALESCE(mot.FLA, mx.FLA))
        FROM #calc c
        JOIN stg.MEL m
          ON m.batch_id = @batch_id
         AND m.project_code = c.project_code
         AND m.eq_tag = c.eq_tag
        OUTER APPLY (
            SELECT TOP (1) *
            FROM ref.motor rm
            WHERE c.np_kw IS NOT NULL AND rm.KW >= c.np_kw
            ORDER BY rm.KW ASC
        ) mot
        OUTER APPLY (
            SELECT TOP (1) *
            FROM ref.motor rm
            ORDER BY rm.KW DESC
        ) mx;

        ------------------------------------------------------------
        -- 8) Write df/pf/eff into stg (only if NULL)
        ------------------------------------------------------------
        UPDATE m
        SET
            m.demand_factor = COALESCE(m.demand_factor, CONVERT(NVARCHAR(100), CAST(ROUND(c.df_num, 6) AS DECIMAL(18,6)))),
            m.power_factor  = COALESCE(m.power_factor,  CONVERT(NVARCHAR(100), CAST(ROUND(c.pf_num, 6) AS DECIMAL(18,6)))),
            m.efficiency    = COALESCE(m.efficiency,    CONVERT(NVARCHAR(100), CAST(ROUND(c.eff_num, 6) AS DECIMAL(18,6))))
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 9) Installed (kw/kva/kvar)
        ------------------------------------------------------------
        UPDATE m
        SET
            installed_kw =
                COALESCE(m.installed_kw,
                    CONVERT(NVARCHAR(100), CAST(ROUND(c.qty_n * c.np_kw / NULLIF(c.eff_num,0), 6) AS DECIMAL(18,6)))
                ),
            installed_kva =
                COALESCE(m.installed_kva,
                    CONVERT(NVARCHAR(100), CAST(ROUND((c.qty_n * c.np_kw / NULLIF(c.eff_num,0)) / NULLIF(c.pf_num,0), 6) AS DECIMAL(18,6)))
                )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        WHERE m.batch_id = @batch_id;

        UPDATE m
        SET installed_kvar =
            COALESCE(m.installed_kvar,
                CONVERT(NVARCHAR(100), CAST(ROUND(
                    SQRT(CASE WHEN (kva*kva - kw*kw) < 0 THEN 0 ELSE (kva*kva - kw*kw) END)
                , 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT
                kw  = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.installed_kw, ',', '')),
                kva = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.installed_kva, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.installed_kvar IS NULL
          AND x.kw IS NOT NULL AND x.kva IS NOT NULL;

        ------------------------------------------------------------
        -- 10) Peak (kw/kva/kvar)
        ------------------------------------------------------------
        UPDATE m
        SET peak_kw =
            COALESCE(m.peak_kw,
                CONVERT(NVARCHAR(100), CAST(ROUND(ikw * c.df_num * c.duty_type_n, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT ikw = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.installed_kw, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.peak_kw IS NULL
          AND x.ikw IS NOT NULL
          AND c.df_num IS NOT NULL
          AND c.duty_type_n IS NOT NULL;

        UPDATE m
        SET peak_kva =
            COALESCE(m.peak_kva,
                CONVERT(NVARCHAR(100), CAST(ROUND(pkw / NULLIF(c.pf_num,0), 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT pkw = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.peak_kw, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.peak_kva IS NULL
          AND x.pkw IS NOT NULL
          AND c.pf_num IS NOT NULL;

        UPDATE m
        SET peak_kvar =
            COALESCE(m.peak_kvar,
                CONVERT(NVARCHAR(100), CAST(ROUND(
                    SQRT(CASE WHEN (pkva*pkva - pkw*pkw) < 0 THEN 0 ELSE (pkva*pkva - pkw*pkw) END)
                , 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT
                pkw  = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.peak_kw, ',', '')),
                pkva = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.peak_kva, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.peak_kvar IS NULL
          AND x.pkw IS NOT NULL AND x.pkva IS NOT NULL;

        ------------------------------------------------------------
        -- 11) Average + Annual
        ------------------------------------------------------------
        UPDATE m
        SET average_kw =
            COALESCE(m.average_kw,
                CONVERT(NVARCHAR(100), CAST(ROUND(pkw * c.uf_n, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT pkw = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.peak_kw, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.average_kw IS NULL
          AND x.pkw IS NOT NULL
          AND c.uf_n IS NOT NULL;

        UPDATE m
        SET average_kva =
            COALESCE(m.average_kva,
                CONVERT(NVARCHAR(100), CAST(ROUND(akw / NULLIF(c.pf_num,0), 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT akw = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.average_kw, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.average_kva IS NULL
          AND x.akw IS NOT NULL
          AND c.pf_num IS NOT NULL;

        UPDATE m
        SET average_kvar =
            COALESCE(m.average_kvar,
                CONVERT(NVARCHAR(100), CAST(ROUND(
                    SQRT(CASE WHEN (akva*akva - akw*akw) < 0 THEN 0 ELSE (akva*akva - akw*akw) END)
                , 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT
                akw  = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.average_kw, ',', '')),
                akva = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.average_kva, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.average_kvar IS NULL
          AND x.akw IS NOT NULL AND x.akva IS NOT NULL;

        UPDATE m
        SET annual_load_mwh =
            COALESCE(m.annual_load_mwh,
                CONVERT(NVARCHAR(100), CAST(ROUND(akva * 365.0 * 24.0 / 1000.0, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT akva = TRY_CONVERT(DECIMAL(18,6), REPLACE(m.average_kva, ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND m.annual_load_mwh IS NULL
          AND x.akva IS NOT NULL;

        ------------------------------------------------------------
        -- 12) FLA, current_draw, fla_125pct
        ------------------------------------------------------------
        UPDATE m
        SET m.fla =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.fla)), ''),
                CASE
                    -- Non-motor: kW*1000 / (sqrt(3)*V*PF)
                    WHEN UPPER(LTRIM(RTRIM(COALESCE(NULLIF(m.load_type,''), '')))) <> 'MOTOR' THEN
                        CASE
                            WHEN x_np.kw IS NULL THEN NULL
                            WHEN x_v.v  IS NULL OR x_v.v  = 0 THEN NULL
                            WHEN x_pf.pf IS NULL OR x_pf.pf = 0 THEN NULL
                            ELSE CONVERT(NVARCHAR(100),
                                CAST(ROUND(
                                    (x_np.kw * 1000.0) / (1.7320508075688772 * x_v.v * x_pf.pf)
                                , 6) AS DECIMAL(18,6))
                            )
                        END

                    -- Motor: use ref.motor FLA chosen earlier into #calc (mot_fla)
                    ELSE
                        CASE
                            WHEN c.mot_fla IS NULL THEN NULL
                            ELSE CONVERT(NVARCHAR(100), CAST(ROUND(c.mot_fla, 6) AS DECIMAL(18,6)))
                        END
                END
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag       = m.eq_tag
        OUTER APPLY (
            SELECT kw = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.forced_nameplate_power)),''), ',', ''))
        ) f_np
        OUTER APPLY (
            SELECT kw = COALESCE(
                CASE WHEN f_np.kw IS NOT NULL AND f_np.kw <> 0 THEN f_np.kw END,
                TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.nameplate_power_kw)),''), ',', ''))
            )
        ) x_np
        OUTER APPLY (
            SELECT v = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.voltage_v)),''), ',', ''))
        ) x_v
        OUTER APPLY (
            SELECT pf = COALESCE(
                TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.power_factor)),''), ',', '')),
                c.pf_num
            )
        ) x_pf
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.fla)), '') IS NULL;


        -- 12B) current_draw = peak_kva*1000/(sqrt(3)*V*PF*Eff)
        UPDATE m
        SET m.current_draw =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.current_draw)), ''),
                CASE
                    WHEN x_pkva.pkva IS NULL THEN NULL
                    WHEN x_v.v IS NULL OR x_v.v = 0 THEN NULL
                    WHEN x_pf.pf IS NULL OR x_pf.pf = 0 THEN NULL
                    WHEN x_eff.eff IS NULL OR x_eff.eff = 0 THEN NULL
                    ELSE CONVERT(NVARCHAR(100),
                        CAST(ROUND(
                            (x_pkva.pkva * 1000.0) / (1.7320508075688772 * x_v.v * x_pf.pf * x_eff.eff)
                        , 6) AS DECIMAL(18,6))
                    )
                END
            )
        FROM stg.MEL m
        JOIN #calc c
        ON c.project_code = m.project_code
        AND c.eq_tag       = m.eq_tag
        OUTER APPLY (
            SELECT pkva = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.peak_kva)),''), ',', ''))
        ) x_pkva
        OUTER APPLY (
            SELECT v = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.voltage_v)),''), ',', ''))
        ) x_v
        OUTER APPLY (
            SELECT pf = COALESCE(
                TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.power_factor)),''), ',', '')),
                c.pf_num
            )
        ) x_pf
        OUTER APPLY (
            SELECT eff = COALESCE(
                TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.efficiency)),''), ',', '')),
                c.eff_num
            )
        ) x_eff
        WHERE m.batch_id = @batch_id
        AND NULLIF(LTRIM(RTRIM(m.current_draw)), '') IS NULL;


        -- 12C) fla_125pct = fla * 1.25
        UPDATE m
        SET m.fla_125pct =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.fla_125pct)), ''),
                CASE
                   WHEN x_fla.fla IS NULL THEN NULL
                    ELSE CONVERT(NVARCHAR(100), CAST(ROUND(x_fla.fla * 1.25, 6) AS DECIMAL(18,6)))
                END
            )
        FROM stg.MEL m
        OUTER APPLY (
            SELECT fla = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.fla)),''), ',', ''))
        ) x_fla
        WHERE m.batch_id = @batch_id
        AND NULLIF(LTRIM(RTRIM(m.fla_125pct)), '') IS NULL;

        ------------------------------------------------------------
        -- 13) MERGE into core.MEL (unchanged)
        ------------------------------------------------------------
        ;MERGE core.MEL AS tgt
        USING (SELECT * FROM stg.MEL WHERE batch_id = @batch_id) AS src
        ON  tgt.project_code = src.project_code
        AND tgt.eq_tag       = src.eq_tag
        WHEN MATCHED THEN
            UPDATE SET
                tgt.project_DB_ID          = src.project_DB_ID,
                tgt.batch_id               = src.batch_id,
                tgt.file_id                = src.file_id,
                tgt.eq_status              = src.eq_status,
                tgt.Area                   = src.Area,
                tgt.eq_type                = src.eq_type,
                tgt.code                   = src.code,
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
                annual_load_mwh, fla, current_draw, fla_125pct,
                location, raw_row_json
            )
            VALUES (
                src.project_code, src.project_DB_ID, src.batch_id, src.file_id, src.eq_status, src.Area, src.eq_type, src.code, src.eq_tag, src.eq_desc, src.rev, src.qty,
                src.nameplate_power_kw, src.nameplate_power_hp, src.absorbed_power_kw, src.utilization_factor,
                src.starter_type, src.load_type, src.duty, src.emergency_load, src.poles,
                src.forced_duty, src.duty_type, src.demand_factor, src.power_factor, src.efficiency, src.voltage_v, src.phase, src.eroom, src.transformer, src.mcc_switchgear,
                src.forced_nameplate_power, src.bucket_size, src.forced_starter_type,
                src.installed_kw, src.installed_kvar, src.installed_kva, src.peak_kw, src.peak_kvar, src.peak_kva, src.average_kw, src.average_kvar, src.average_kva,
                src.annual_load_mwh, src.fla, src.current_draw, src.fla_125pct,
                src.location, src.raw_row_json
            );

        ------------------------------------------------------------
        -- 14) Optional: delete staging rows
        ------------------------------------------------------------
        IF @delete_staging_after = 1
        BEGIN
            DELETE FROM stg.MEL WHERE batch_id = @batch_id;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

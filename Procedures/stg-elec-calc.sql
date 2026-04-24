USE MEL_EEL_Automation_Dev;
GO

CREATE OR ALTER PROCEDURE stg.elec_calc
    @batch_id UNIQUEIDENTIFIER,
    @default_absorbed_kw DECIMAL(18,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (SELECT 1 FROM stg.MEL WHERE batch_id = @batch_id)
            RAISERROR('stg.elec_calc: No rows found in stg.MEL for this batch_id.', 16, 1);

        ------------------------------------------------------------
        -- 1) Duty type lookup
        -- forced_duty if present, else duty
        ------------------------------------------------------------
        UPDATE m
        SET m.duty_type = CONVERT(NVARCHAR(100), d.duty_type)
        FROM stg.MEL m
        LEFT JOIN ref.duty d
          ON UPPER(LTRIM(RTRIM(d.duty))) =
             UPPER(LTRIM(RTRIM(COALESCE(NULLIF(m.forced_duty,''), NULLIF(m.duty,'')))))
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 2) Calc cache
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#calc') IS NOT NULL DROP TABLE #calc;

        CREATE TABLE #calc
        (
            project_code NVARCHAR(50)  NOT NULL,
            eq_tag       NVARCHAR(100) NOT NULL,

            qty_n        DECIMAL(18,6) NULL,
            np_kw        DECIMAL(18,6) NULL,
            forced_np_kw DECIMAL(18,6) NULL,
            used_np_kw   DECIMAL(18,6) NULL,
            abs_kw_used  DECIMAL(18,6) NULL,
            uf_n         DECIMAL(18,6) NULL,
            v_n          DECIMAL(18,6) NULL,

            duty_type_n  DECIMAL(18,6) NULL,
            df_num       DECIMAL(18,6) NULL,
            band_sel     INT NULL,

            pf_num       DECIMAL(18,6) NULL,
            eff_num      DECIMAL(18,6) NULL,
            mot_fla      DECIMAL(18,6) NULL,

            used_starter_type NVARCHAR(100) NULL,
            load_type_norm    NVARCHAR(20) NULL
        );

        INSERT INTO #calc
        (
            project_code, eq_tag,
            qty_n, np_kw, forced_np_kw, used_np_kw, abs_kw_used, uf_n, v_n,
            duty_type_n, df_num, band_sel,
            pf_num, eff_num, mot_fla,
            used_starter_type,
            load_type_norm
        )
        SELECT
            m.project_code,
            m.eq_tag,

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.qty,''), ',', '')),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.nameplate_power_kw,''), ',', '')),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.forced_nameplate_power,''), ',', '')),

            COALESCE(
                TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.forced_nameplate_power,''), ',', '')),
                TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.nameplate_power_kw,''), ',', ''))
            ),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.absorbed_power_kw,''), ',', '')),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.utilization_factor,''), ',', '')),
            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.voltage_v,''), ',', '')),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.duty_type,''), ',', '')),

            TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.demand_factor,''), ',', '')),

            NULL,
            NULL,
            NULL,
            NULL,

            UPPER(LTRIM(RTRIM(COALESCE(NULLIF(m.forced_starter_type,''), NULLIF(m.starter_type,''), '')))),

            UPPER(LTRIM(RTRIM(COALESCE(NULLIF(m.load_type,''), ''))))
        FROM stg.MEL m
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 3) Demand factor
        -- if absorbed_power_kw is null => 0.7
        -- else absorbed / forced_nameplate if present, else absorbed / nameplate
        ------------------------------------------------------------
        UPDATE c
        SET c.df_num =
            CASE
                WHEN c.df_num IS NOT NULL THEN c.df_num
                WHEN c.abs_kw_used IS NULL THEN 0.7
                WHEN c.used_np_kw IS NULL OR c.used_np_kw = 0 THEN NULL
                ELSE c.abs_kw_used / c.used_np_kw
            END
        FROM #calc c;

        ------------------------------------------------------------
        -- 4) Band selection
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
        -- 5) PF / Eff / Motor FLA
        ------------------------------------------------------------
        UPDATE c
        SET
            c.pf_num =
                CASE
                    WHEN TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.power_factor,''), ',', '')) IS NOT NULL
                        THEN TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.power_factor,''), ',', ''))

                    WHEN c.used_starter_type = '' THEN NULL

                    WHEN c.used_starter_type IN ('VFD','VSD','SS')
                        THEN COALESCE(
                            CASE c.band_sel
                                WHEN 50 THEN TRY_CONVERT(DECIMAL(18,6), mot.PF_50)
                                WHEN 75 THEN TRY_CONVERT(DECIMAL(18,6), mot.PF_75)
                                ELSE      TRY_CONVERT(DECIMAL(18,6), mot.PF_100)
                            END,
                            0.85
                        ) * 0.96

                    WHEN c.used_starter_type = 'FDR'
                        THEN 0.96

                    ELSE COALESCE(
                        CASE c.band_sel
                            WHEN 50 THEN TRY_CONVERT(DECIMAL(18,6), mot.PF_50)
                            WHEN 75 THEN TRY_CONVERT(DECIMAL(18,6), mot.PF_75)
                            ELSE      TRY_CONVERT(DECIMAL(18,6), mot.PF_100)
                        END,
                        0.85
                    )
                END,

            c.eff_num =
                CASE
                    WHEN TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.efficiency,''), ',', '')) IS NOT NULL
                        THEN TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(m.efficiency,''), ',', ''))

                    WHEN c.used_starter_type = '' THEN NULL

                    WHEN c.used_starter_type IN ('VFD','VSD','SS')
                        THEN COALESCE(
                            CASE c.band_sel
                                WHEN 50 THEN TRY_CONVERT(DECIMAL(18,6), mot.Eff_50)
                                WHEN 75 THEN TRY_CONVERT(DECIMAL(18,6), mot.Eff_75)
                                ELSE      TRY_CONVERT(DECIMAL(18,6), mot.Eff_100)
                            END,
                            0.96
                        ) * 0.96

                    WHEN c.used_starter_type = 'FDR'
                        THEN 0.96

                    ELSE COALESCE(
                        CASE c.band_sel
                            WHEN 50 THEN TRY_CONVERT(DECIMAL(18,6), mot.Eff_50)
                            WHEN 75 THEN TRY_CONVERT(DECIMAL(18,6), mot.Eff_75)
                            ELSE      TRY_CONVERT(DECIMAL(18,6), mot.Eff_100)
                        END,
                        0.96
                    )
                END,

            c.mot_fla = TRY_CONVERT(DECIMAL(18,6), mot.FLA)
        FROM #calc c
        JOIN stg.MEL m
          ON m.batch_id = @batch_id
         AND m.project_code = c.project_code
         AND m.eq_tag = c.eq_tag
        OUTER APPLY (
            SELECT TOP (1) *
            FROM ref.motor rm
            WHERE c.used_np_kw IS NOT NULL
              AND rm.KW >= c.used_np_kw
            ORDER BY rm.KW ASC
        ) mot;

        ------------------------------------------------------------
        -- 6) Write demand_factor / PF / Eff to stg
        ------------------------------------------------------------
        UPDATE m
        SET
            m.demand_factor = COALESCE(
                NULLIF(LTRIM(RTRIM(m.demand_factor)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(c.df_num, 6) AS DECIMAL(18,6)))
            ),
            m.power_factor = COALESCE(
                NULLIF(LTRIM(RTRIM(m.power_factor)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(c.pf_num, 6) AS DECIMAL(18,6)))
            ),
            m.efficiency = COALESCE(
                NULLIF(LTRIM(RTRIM(m.efficiency)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(c.eff_num, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 7) Installed kW / kVA
        ------------------------------------------------------------
        UPDATE m
        SET
            installed_kw =
                COALESCE(
                    NULLIF(LTRIM(RTRIM(m.installed_kw)), ''),
                    CONVERT(NVARCHAR(100), CAST(ROUND(c.qty_n * c.used_np_kw / NULLIF(c.eff_num,0), 6) AS DECIMAL(18,6)))
                ),
            installed_kva =
                COALESCE(
                    NULLIF(LTRIM(RTRIM(m.installed_kva)), ''),
                    CONVERT(NVARCHAR(100), CAST(ROUND((c.qty_n * c.used_np_kw / NULLIF(c.eff_num,0)) / NULLIF(c.pf_num,0), 6) AS DECIMAL(18,6)))
                )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        WHERE m.batch_id = @batch_id;

        ------------------------------------------------------------
        -- 8) Installed kVAr
        ------------------------------------------------------------
        UPDATE m
        SET installed_kvar =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.installed_kvar)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(
                    SQRT(CASE WHEN (x.kva * x.kva - x.kw * x.kw) < 0 THEN 0 ELSE (x.kva * x.kva - x.kw * x.kw) END)
                , 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT
                kw  = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.installed_kw)),''), ',', '')),
                kva = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.installed_kva)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.installed_kvar)), '') IS NULL
          AND x.kw IS NOT NULL
          AND x.kva IS NOT NULL;

        ------------------------------------------------------------
        -- 9) Peak kW / kVA / kVAr
        ------------------------------------------------------------
        UPDATE m
        SET peak_kw =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.peak_kw)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(x.ikw * c.df_num * c.duty_type_n, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT ikw = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.installed_kw)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.peak_kw)), '') IS NULL
          AND x.ikw IS NOT NULL
          AND c.df_num IS NOT NULL
          AND c.duty_type_n IS NOT NULL;

        UPDATE m
        SET peak_kva =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.peak_kva)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(x.pkw / NULLIF(c.pf_num,0), 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT pkw = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.peak_kw)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.peak_kva)), '') IS NULL
          AND x.pkw IS NOT NULL
          AND c.pf_num IS NOT NULL;

        UPDATE m
        SET peak_kvar =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.peak_kvar)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(
                    SQRT(CASE WHEN (x.pkva * x.pkva - x.pkw * x.pkw) < 0 THEN 0 ELSE (x.pkva * x.pkva - x.pkw * x.pkw) END)
                , 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT
                pkw  = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.peak_kw)),''), ',', '')),
                pkva = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.peak_kva)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.peak_kvar)), '') IS NULL
          AND x.pkw IS NOT NULL
          AND x.pkva IS NOT NULL;

        ------------------------------------------------------------
        -- 10) Average kW / kVA / kVAr
        ------------------------------------------------------------
        UPDATE m
        SET average_kw =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.average_kw)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(x.pkw * c.uf_n, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT pkw = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.peak_kw)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.average_kw)), '') IS NULL
          AND x.pkw IS NOT NULL
          AND c.uf_n IS NOT NULL;

        UPDATE m
        SET average_kva =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.average_kva)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(x.akw / NULLIF(c.pf_num,0), 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        JOIN #calc c
          ON c.project_code = m.project_code
         AND c.eq_tag = m.eq_tag
        CROSS APPLY (
            SELECT akw = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.average_kw)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.average_kva)), '') IS NULL
          AND x.akw IS NOT NULL
          AND c.pf_num IS NOT NULL;

        UPDATE m
        SET average_kvar =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.average_kvar)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(
                    SQRT(CASE WHEN (x.akva * x.akva - x.akw * x.akw) < 0 THEN 0 ELSE (x.akva * x.akva - x.akw * x.akw) END)
                , 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT
                akw  = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.average_kw)),''), ',', '')),
                akva = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.average_kva)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.average_kvar)), '') IS NULL
          AND x.akw IS NOT NULL
          AND x.akva IS NOT NULL;

        ------------------------------------------------------------
        -- 11) Annual load
        ------------------------------------------------------------
        UPDATE m
        SET annual_load_mwh =
            COALESCE(
                NULLIF(LTRIM(RTRIM(m.annual_load_mwh)), ''),
                CONVERT(NVARCHAR(100), CAST(ROUND(x.akva * 365.0 * 24.0 / 1000.0, 6) AS DECIMAL(18,6)))
            )
        FROM stg.MEL m
        CROSS APPLY (
            SELECT akva = TRY_CONVERT(DECIMAL(18,6), REPLACE(NULLIF(LTRIM(RTRIM(m.average_kva)),''), ',', ''))
        ) x
        WHERE m.batch_id = @batch_id
          AND NULLIF(LTRIM(RTRIM(m.annual_load_mwh)), '') IS NULL
          AND x.akva IS NOT NULL;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
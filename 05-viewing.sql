USE MEL_EEL_Automation_Dev;
GO

IF OBJECT_ID('core.vw_mel_editable','V') IS NOT NULL
    DROP VIEW core.vw_mel_editable;
GO

CREATE VIEW core.vw_mel_editable
AS
SELECT
    project_code,
    equipment_tag,
    description,
    eq_type,
    connected_load_kw,
    voltage_v,
    power_factor_pf,
    starter_type,
    location,
    rowversion
FROM core.equipment_mech;
GO
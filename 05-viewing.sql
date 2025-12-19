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
    status,
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
    connected_load_kw,
    voltage_v,
    power_factor_pf,
    starter_type,
    location,
    rowversion
FROM core.equipment_mech;
GO
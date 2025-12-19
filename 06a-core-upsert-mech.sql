USE MEL_EEL_Automation_Dev;
GO
CREATE OR ALTER PROCEDURE core.sp_upsert_equipment_mech @project_code NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  MERGE core.equipment_mech AS tgt
  USING (
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

      -- canonical fields (may be populated by your loader OR inferred below)
      connected_load_kw,
      voltage_v,
      power_factor_pf,
      starter_type,
      location
    FROM stg.equipment_mech
    WHERE project_code = @project_code
  ) AS src
  ON (tgt.project_code = src.project_code AND tgt.equipment_tag = src.equipment_tag)
  WHEN MATCHED THEN UPDATE SET
    status             = src.status,
    area               = src.area,
    eq_type            = src.eq_type,
    code               = src.code,
    eq_num             = src.eq_num,
    description        = src.description,
    revision           = src.revision,
    supplied_by        = src.supplied_by,
    installed_by       = src.installed_by,
    connected_by       = src.connected_by,
    model              = src.model,
    dimension_l        = src.dimension_l,
    dimension_w        = src.dimension_w,
    dimension_h        = src.dimension_h,
    specifications     = src.specifications,
    comments           = src.comments,
    plant_section      = src.plant_section,
    pfd                = src.pfd,
    p_id               = src.p_id,
    responsible_eqlist = src.responsible_eqlist,
    package            = src.package,
    package_engineer   = src.package_engineer,
    demand_factor      = src.demand_factor,
    poles              = src.poles,
    utilization_factor = src.utilization_factor,
    motor_kw           = src.motor_kw,
    total_load_kw      = src.total_load_kw,
    drive_type         = src.drive_type,
    duty_type          = src.duty_type,
    load_type          = src.load_type,
    emergency_load     = src.emergency_load,
    absorbed_power_kw  = src.absorbed_power_kw,
    mp                 = src.mp,
    mass_bal           = src.mass_bal,

    -- ensure connected_load_kw stays usable for the existing calc/load-list pipeline
    connected_load_kw  = COALESCE(src.connected_load_kw, src.total_load_kw, src.motor_kw),
    voltage_v          = src.voltage_v,
    power_factor_pf    = src.power_factor_pf,
    starter_type       = src.starter_type,
    location           = src.location,

    last_modified_utc  = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (
      project_code, equipment_tag,
      status, area, eq_type, code, eq_num, description, revision,
      supplied_by, installed_by, connected_by, model,
      dimension_l, dimension_w, dimension_h,
      specifications, comments,
      plant_section, pfd, p_id,
      responsible_eqlist, package, package_engineer,
      demand_factor, poles, utilization_factor,
      motor_kw, total_load_kw,
      drive_type, duty_type, load_type, emergency_load,
      absorbed_power_kw, mp, mass_bal,
      connected_load_kw, voltage_v, power_factor_pf, starter_type, location
    )
    VALUES (
      src.project_code, src.equipment_tag,
      src.status, src.area, src.eq_type, src.code, src.eq_num, src.description, src.revision,
      src.supplied_by, src.installed_by, src.connected_by, src.model,
      src.dimension_l, src.dimension_w, src.dimension_h,
      src.specifications, src.comments,
      src.plant_section, src.pfd, src.p_id,
      src.responsible_eqlist, src.package, src.package_engineer,
      src.demand_factor, src.poles, src.utilization_factor,
      src.motor_kw, src.total_load_kw,
      src.drive_type, src.duty_type, src.load_type, src.emergency_load,
      src.absorbed_power_kw, src.mp, src.mass_bal,
      COALESCE(src.connected_load_kw, src.total_load_kw, src.motor_kw),
      src.voltage_v, src.power_factor_pf, src.starter_type, src.location
    );
END;
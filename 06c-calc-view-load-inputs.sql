USE MEL_EEL_Automation_Dev;
GO
CREATE OR ALTER VIEW calc.vw_load_inputs AS
SELECT
  m.project_code,
  m.equipment_tag,
  m.eq_type,
  m.connected_load_kw,
  m.voltage_v,
  m.power_factor_pf,
  calc.fn_resolve_demand_factor(m.project_code, m.eq_type) AS demand_factor,
  CAST(m.connected_load_kw * calc.fn_resolve_demand_factor(m.project_code, m.eq_type) AS DECIMAL(18,4)) AS demand_kw,
  calc.fn_compute_kva(m.connected_load_kw, m.power_factor_pf) AS kVA
FROM core.equipment_mech AS m;
GO
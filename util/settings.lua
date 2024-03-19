

logistica.settings = {}

local function L(str) return "logistica_"..str end

local function get_bool (key, default)
  return minetest.settings:get_bool(L(key), default)
end

local function get_int(key, default, min, max)
  local val = minetest.settings:get(L(key)) or default
  local result = tonumber(val)
  if min then result = math.max(min, result) end
  if max then result = math.min(max, result) end
  return result
end

local function get_cable_size_from_settings()
  local val = string.lower(minetest.settings:get(L("cable_size")) or "medium")
  if val == "medium" then return 1/12
  elseif val == "large" then return 1/8
  elseif val =="xlarge" then return 1/4
  else return 1/16 end
end

--------------------------------
-- Settings
--------------------------------

logistica.settings.wap_max_range = get_int("wap_max_range", 64000, 1, 64000)

logistica.settings.wap_upgrade_step = get_int("wap_upgrade_step", 250, 10, 5000)

logistica.settings.wifi_upgrader_hard_mode = get_bool("wifi_upgrader_hard_mode", false)

logistica.settings.cable_size = get_cable_size_from_settings()

logistica.settings.large_liquid_tank_enabled = get_bool("enable_large_liquid_tank", true)

logistica.settings.pump_max_range = get_int("pump_max_range", 5, 1, 10)

logistica.settings.pump_max_depth = get_int("pump_max_depth", 5, 1, 32)

logistica.settings.network_node_limit = get_int("network_node_limit", 4000, 100, 1000000)

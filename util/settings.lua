

logistica.settings = {}

local function L(str) return "logistica_"..str end

local function get_bool (key, default)
  return minetest.settings:get_bool(L(key), default)
end

local function get_int (key, default)
  local val = minetest.settings:get(L(key)) or default
  return tonumber(val)
end

local function get_cable_size_from_settings()
  local val = string.lower(minetest.settings:get(L("cable_size")) or "medium")
  if val == "medium" then return 1/12
  elseif val == "large" then return 1/8
  elseif val =="xlarge" then return 1/4
  else return 1/16 end -- the "Small" is default
end

--------------------------------
-- Settings
--------------------------------

logistica.settings.wap_max_range = get_int("wap_max_range", 64000)

logistica.settings.wap_upgrade_step = get_int("wap_upgrade_step", 250)

logistica.settings.wifi_upgrader_hard_mode = get_bool("wifi_upgrader_hard_mode", false)

logistica.settings.cable_size = get_cable_size_from_settings()

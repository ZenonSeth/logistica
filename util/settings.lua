

logistica.settings = {}

local function L(str) return "logistica_"..str end

local function get_bool (key, default)
  return minetest.settings:get_bool(L(key), default)
end

local function get_int (key, default)
  if minetest.settings:has(key) then
    return tonumber(minetest.settings:get(L(key)))
  else
    return default
  end
end

--------------------------------
-- Settings
--------------------------------

logistica.settings.wap_max_range = get_int("wap_max_range", 64000)

logistica.settings.wap_upgrade_step = get_int("wap_upgrade_step", 250)

logistica.settings.wifi_upgrader_hard_mode = get_bool("wifi_upgrader_hard_mode", false)


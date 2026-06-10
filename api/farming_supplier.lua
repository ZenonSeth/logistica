local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logistica_farming_supplier"
local ON_OFF_BUTTON = "on_off_btn"
local META_RADIUS = "farm_radius"
local META_HEIGHT_MODE = "farm_height_mode"
local MIN_RADIUS = 1
local MAX_RADIUS = logistica.settings.farming_supplier_max_radius
local INV_UPGRADE = "upgrade"
local SPRINKLER_UPGRADE = "logistica:sprinkler_upgrade"

-- MODE_ABOVE (1) exists in logic but is not selectable; only these two are shown
local HEIGHT_MODE_NAMES = {
  FS("Farm At Level"),
  FS("Farm Below"),
}

local HEIGHT_MODE_DESCS = {
  FS("At Level: Scans at the same height as this node.\nPlace node at same level as plants."),
  FS("Below: Scans 2 nodes below this node.\nPlace node above crops."),
}

-- maps dropdown index (1,2) to the mode constant stored in meta (2=LEVEL, 3=BELOW)
local DROPDOWN_MODES = {2, 3}

local function mode_to_dropdown_idx(mode)
  if mode == 3 then return 2 end
  return 1 -- MODE_ABOVE or MODE_LEVEL both show as Farm At Level
end

local function get_radius(pos)
  local r = minetest.get_meta(pos):get_int(META_RADIUS)
  if r < MIN_RADIUS then return 3 end
  return r
end

local function get_height_mode(pos)
  local m = minetest.get_meta(pos):get_int(META_HEIGHT_MODE)
  if m < 1 or m > 3 then return 1 end
  return m
end

local LAVA_MAX = 1000

local FSTATUS_NO_LAVA = 1
local FSTATUS_NO_WATER = 2

local function get_status_line(pos, x, y)
  local s = logistica.farming_supplier_get_status(pos)
  if s == FSTATUS_NO_LAVA then
    return "label["..x..","..y..";"..minetest.colorize("#FF6666", FS("Halted: no lava in network")).."]"
  elseif s == FSTATUS_NO_WATER then
    return "label["..x..","..y..";"..minetest.colorize("#44DDDD", FS("Sprinkler: no water in network")).."]"
  end
  return "label["..x..","..y..";"..FS("Requires Lava in the Network to function").."]"
end

local function get_lava_indicator(pos, x, y, h)
  local lava = logistica.farming_supplier_get_lava(pos)
  local pct = logistica.round(lava / LAVA_MAX * 100)
  local img
  if pct > 0 then
    img = "image["..x..","..y..";0.8,"..h..
      ";logistica_lava_furnace_tank_bg.png^[lowpart:"..pct..":logistica_lava_furnace_tank.png]"
  else
    img = "image["..x..","..y..";0.8,"..h..";logistica_lava_furnace_tank_bg.png]"
  end
  return "label["..x..","..(y - 0.35)..";"..FS("Lava").."]"..
    img..
    "tooltip["..x..","..y..";0.8,"..h..";"..FS("Lava reserve: ")..(lava).."/"..LAVA_MAX.."\nTaken From Network\nUses 1/1000th per harvest or watering cycle]"
end

local forms = {}

local function get_farming_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)
  local radius = get_radius(pos)
  local height_mode = get_height_mode(pos)
  local dropdown_idx = mode_to_dropdown_idx(height_mode)
  local mode_desc = HEIGHT_MODE_DESCS[dropdown_idx]

  return "formspec_version[4]" ..
    "size["..logistica.inv_size(10.5, 13.2).."]" ..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.3;"..FS("Harvests nearby fully-grown crops\nand supplies them to the network.").."]"..
    "list["..posForm..";main;0.4,1.2;7,2;0]"..
    logistica.ui.on_off_btn(isOn, 7.5, 5.7, ON_OFF_BUTTON, FS("Enable"))..
    "label[6.8,4.0;"..FS("Sprnkler Upgrade").."]"..
    "list["..posForm..";"..INV_UPGRADE..";7.5,4.2;1,1;0]"..
    "label[0.6,4.05;"..FS("Hor. Range:").."]"..
    "button[2.8,3.75;0.65,0.65;range_dec;-]"..
    "label[3.65,4.05;"..tostring(radius).."]"..
    "button[4.0,3.75;0.65,0.65;range_inc;+]"..
    "label[0.5,5.0;"..FS("Height Mode:").."]"..
    "dropdown[2.5,4.55;4.0;height_mode;"..
      table.concat(HEIGHT_MODE_NAMES, ",")..";"..dropdown_idx.."]"..
    "label[0.5,5.85;"..mode_desc.."]"..
    get_lava_indicator(pos, 9.3, 1.0, 5.8)..
    get_status_line(pos, 2.5, 7.0)..
    logistica.player_inv_formspec(0.4, 7.3)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"
end

local function show_farming_formspec(playerName, pos)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_farming_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_farming_formspec(playerName, pos)
  elseif fields.range_inc or fields.range_dec then
    local delta = fields.range_inc and 1 or -1
    local new_radius = logistica.clamp(get_radius(pos) + delta, MIN_RADIUS, MAX_RADIUS)
    minetest.get_meta(pos):set_int(META_RADIUS, new_radius)
    logistica.farming_supplier_show_scan_area(pos)
    show_farming_formspec(playerName, pos)
  elseif fields.height_mode then
    for i, name in ipairs(HEIGHT_MODE_NAMES) do
      if fields.height_mode == name then
        minetest.get_meta(pos):set_int(META_HEIGHT_MODE, DROPDOWN_MODES[i])
        break
      end
    end
    logistica.farming_supplier_show_scan_area(pos)
    show_farming_formspec(playerName, pos)
  end
  return true
end

local function on_farming_rightclick(pos, _node, clicker, _itemstack, _pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  show_farming_formspec(clicker:get_player_name(), pos)
end

local function on_farming_punch(pos, _node, puncher, _pointed_thing)
  if not puncher or not puncher:is_player() then return end
  if puncher:get_player_control().sneak then
    logistica.farming_supplier_show_scan_area(pos)
  end
end

local function after_place_farming(pos, _placer, _itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size("main", logistica.get_supplier_inv_size(pos))
  inv:set_size(INV_UPGRADE, 1)
  meta:set_int(META_HEIGHT_MODE, 3) -- default to Farm Below
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
  logistica.farming_supplier_show_scan_area(pos)
end

local function allow_farming_inv_put(pos, listname, _, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == INV_UPGRADE then
    if stack:get_name() ~= SPRINKLER_UPGRADE then return 0 end
    return 1
  end
  return 0 -- main list is output-only
end

local function allow_farming_inv_take(pos, _, _, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_farming_inv_move(pos, _, _, _, _, count, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  return count
end

local function on_farming_inv_put(pos, _, _, _, _)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function on_farming_inv_take(pos, _, _, _, _)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function can_dig_farming(pos, _)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty("main") and inv:is_empty(INV_UPGRADE)
end

local function on_farming_power(pos, power)
  logistica.farming_supplier_on_power(pos, power)
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, _timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_farming_supplier(desc, name, inventorySize, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local node_name = "logistica:"..lname
  logistica.GROUPS.farming_suppliers.register(node_name)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1}
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "nodebox",
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5,   0.0,     -0.5,   0.5,   0.5,     0.5},    -- main body (top half)
        {-0.125, -0.4375, -0.125, 0.125, 0.0,     0.125},  -- neck
        {-0.5,   -0.5,    -0.5,   0.5,   -0.4375, 0.5},    -- base plate (1/16 thick)
      }
    },
    tiles = tiles,
    paramtype = "light",
    is_ground_content = false,
    groups = grps,
    drop = node_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_farming,
    after_dig_node = logistica.on_supplier_change,
    on_punch = on_farming_punch,
    on_rightclick = on_farming_rightclick,
    allow_metadata_inventory_put = allow_farming_inv_put,
    allow_metadata_inventory_take = allow_farming_inv_take,
    allow_metadata_inventory_move = allow_farming_inv_move,
    on_metadata_inventory_put = on_farming_inv_put,
    on_metadata_inventory_take = on_farming_inv_take,
    on_timer = logistica.farming_supplier_on_timer,
    can_dig = can_dig_farming,
    logistica = {
      inventory_size = inventorySize,
      on_power = on_farming_power,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(node_name, def)
  logistica.register_non_pushable(node_name)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = {oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, handy = 1, pickaxey = 1, axey = 1, not_in_creative_inventory = 1}
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(node_name.."_disabled", def_disabled)
end

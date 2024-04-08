local S = logistica.TRANSLATOR

local PUMP_MAX_RANGE = logistica.settings.pump_max_range
local PUMP_MAX_DEPTH = logistica.settings.pump_max_depth

local META_OWNER = "pumpowner"

local FORMSPEC_NAME = "logistica_pump"
local INV_INPUT = "input"
local INV_MAIN = "main"

local ON_OFF_BTN = "onffbtn"
local INC_1_BTN = "i1b"
local INC_10_BTN = "i10b"
local DEC_1_BTN = "d1b"
local DEC_10_BTN = "d10b"

local forms = {}

--------------------------------
-- Formspec
--------------------------------

local function get_pump_formspec(pos, _isOn)
  local isOn = _isOn
  -- local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  if isOn == nil then isOn = logistica.is_machine_on(pos) end
  local maxLevel = logistica.pump_get_max_network_level(pos)
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.5, 5.0).."]" ..
    logistica.ui.background..
    "label[0.4,0.4;"..S("Pumps liquids directly into neighbouring reservoirs (one on each side)").."]"..
    "label[0.4,0.8;"..S("Or if there are none, or are full, pumps into any network reservoirs").."]"..
    "label[0.4,1.2;"..S("Max horizontal range, on each side of pump: ")..tostring(PUMP_MAX_RANGE).."]"..
    "label[0.4,1.6;"..S("Max vertical range, starting below the pump: ")..tostring(PUMP_MAX_DEPTH).."]"..
    "label[0.4,2.0;"..S("MUST be placed directly above liquid surface, without gaps to liquid").."]"..
    logistica.ui.on_off_btn(isOn, 0.4, 3.0, ON_OFF_BTN, S("Enable"))..
    "label[3.8,2.6;"..S("Max Network Amount: If Network has more than\nthis amount of liquid, don't pump any more.\nSet to 0 to ALWAYS pump into network.\nOnly applies to pumping into network.").."]"..
    "label[2.4,3.6;"..S("Max: ")..maxLevel.."]"..
    "image_button[1.7,2.4;1.0,0.8;logistica_icon_highlight.png;"..INC_1_BTN..";+1]"..
    "image_button[2.7,2.4;1.0,0.8;logistica_icon_highlight.png;"..INC_10_BTN..";+10]"..
    "image_button[1.7,3.9;1.0,0.8;logistica_icon_highlight.png;"..DEC_1_BTN..";-1]"..
    "image_button[2.7,3.9;1.0,0.8;logistica_icon_highlight.png;"..DEC_10_BTN..";-10]"
end

local function show_pump_formspec(playerName, pos)
  if not forms[playerName] then forms[playerName] = {position = pos} end
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_pump_formspec(pos))
end

--------------------------------
-- Callbacks
--------------------------------

local function pump_after_place(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_INPUT, 24)
  inv:set_size(INV_MAIN, 4)
  if placer and placer:is_player() then
    meta:set_string(META_OWNER, placer:get_player_name())
  end
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_pump_change(pos)
end

local function pump_can_dig(pos)
  return true
end

local function pump_allow_metadata_inv_put(pos, listname, index, stack, player)
  return stack:get_count()
end

local function pump_allow_metadata_inv_take(pos, listname, index, stack, player)
  return stack:get_count()
end

local function pump_allow_metadata_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return count
end

local function pump_on_inv_change(pos)
end

local function on_pump_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_pump_formspec(clicker:get_player_name(), pos)
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[ON_OFF_BTN] then
    logistica.toggle_machine_on_off(pos)
    show_pump_formspec(playerName, pos)
  elseif fields[INC_1_BTN] then
    logistica.pump_change_max_network_level(pos, 1)
    show_pump_formspec(playerName, pos)
  elseif fields[INC_10_BTN] then
    logistica.pump_change_max_network_level(pos, 10)
    show_pump_formspec(playerName, pos)
  elseif fields[DEC_1_BTN] then
    logistica.pump_change_max_network_level(pos, -1)
    show_pump_formspec(playerName, pos)
  elseif fields[DEC_10_BTN] then
    logistica.pump_change_max_network_level(pos, -10)
    show_pump_formspec(playerName, pos)
  end
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, _)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

--------------------------------
-- Public API
--------------------------------

function logistica.register_pump(desc, name, tiles, tilesOn)
  local lname = name:gsub("%s", "_"):lower()
  local pump_name = "logistica:"..lname
  local pump_name_on = pump_name.."_on"

  logistica.GROUPS.pumps.register(pump_name)
  logistica.GROUPS.pumps.register(pump_name_on)

  local def = {
    description = S(desc),
    tiles = tiles,
    paramtype2 = "facedir",
    groups = { cracky= 2, pickaxey = 2, [logistica.TIER_ALL] = 1 },
    is_ground_content = false,
    sounds = logistica.node_sound_metallic(),
    can_dig = pump_can_dig,
    drop = pump_name,
    on_timer = logistica.on_timer_powered(logistica.pump_timer),
    after_place_node = pump_after_place,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_pump_rightclick,
    on_metadata_inventory_move = pump_on_inv_change,
    on_metadata_inventory_put = pump_on_inv_change,
    on_metadata_inventory_take = pump_on_inv_change,
    allow_metadata_inventory_put = pump_allow_metadata_inv_put,
    allow_metadata_inventory_move = pump_allow_metadata_inv_move,
    allow_metadata_inventory_take = pump_allow_metadata_inv_take,
    logistica = {
      on_power = logistica.pump_on_power,
      on_connect_to_network = function(pos, networkId)
        logistica.start_node_timer(pos, 1)
      end,
    },
    _mcl_hardness = 3,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(pump_name, def)
  logistica.register_non_pushable(pump_name)

  local def_on = table.copy(def)
  def_on.tiles = tilesOn
  def_on.groups.not_in_creative_inventory = 1

  minetest.register_node(pump_name_on, def_on)
  logistica.register_non_pushable(pump_name_on)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, axey = 1, handy = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(pump_name.."_disabled", def_disabled)
end

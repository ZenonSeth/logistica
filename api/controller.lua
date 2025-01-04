local S = logistica.TRANSLATOR
local FS = logistica.FTRANSLATOR

local SET_BUTTON = "logsetbtn"
local NAME_FIELD = "namef"
local FORMSPEC_NAME = "logconren"
local MAX_NETWORK_NAME_LENGTH = 30
local controllerForms = {}

local function get_controller_formspec(pos)
  local name = minetest.formspec_escape(logistica.get_network_name_or_nil(pos) or "<ERROR>")
  return "formspec_version[4]" ..
    "size[10.5,2]" ..
    logistica.ui.background..
    "field[2.5,0.6;3,0.8;"..NAME_FIELD..";"..FS("Network Name")..";"..name.."]" ..
    "button[5.6,0.6;3,0.8;"..SET_BUTTON..";"..FS("Set").."]"
end

local function show_controller_formspec(pos, playerName)
  controllerForms[playerName] = {position = pos}
  logistica.on_controller_timer(pos, 1) -- to ensure net is initialized
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_controller_formspec(pos))
end

local function on_controller_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  local pos = controllerForms[playerName].position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit and not fields.key_enter_field then
    controllerForms[playerName] = nil
  elseif (fields[SET_BUTTON] or fields.key_enter_field) and fields[NAME_FIELD] then
    local newNetworkName = fields[NAME_FIELD]
    if #newNetworkName > MAX_NETWORK_NAME_LENGTH then
      newNetworkName = string.sub(newNetworkName, 1, MAX_NETWORK_NAME_LENGTH)
    end
    logistica.rename_network(minetest.hash_node_position(pos), newNetworkName)
    local readNetworkName = logistica.get_network_name_or_nil(pos) or newNetworkName
    local meta = minetest.get_meta(pos)
    meta:set_string("infotext", S("Controller of Network: ")..readNetworkName)
    meta:set_string("name", readNetworkName)
    if readNetworkName ~= newNetworkName then
      show_controller_formspec(pos, playerName)
    end
  end
  return true
end

local function after_controller_place(pos)
  logistica.start_controller_timer(pos)
end

----------------------------------------------------------------
-- registration stuff
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_controller_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    controllerForms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

--[[
  The definition table will get the fololwing fields overriden (and currently originals are not called):
  - on_construct
  - after_place_node
  - after_destruct
  - on_timer
  - on_rightclick
  - drop

  simpleName is used for the node registration, and will, if necessary, be converted 
  to lowerspace and all spaces replaced with _

  tier may be `nil` which will result in the controller connecting to everything
]]
function logistica.register_controller(name, def)
  local controller_group = logistica.TIER_ALL
  local tier = logistica.TIER_ALL
  local controller_name = "logistica:" .. string.lower(name:gsub(" ", "_"))
  logistica.GROUPS.controllers.register(controller_name)

  local on_construct = function(pos)
      logistica.start_controller_timer(pos)
      logistica.on_controller_change(pos, nil)
  end

  if not def.groups then
    def.groups = {}
  end
  def.groups[controller_group] = 1
  def.on_timer = logistica.on_controller_timer
  def.on_construct = on_construct
  def.after_dig_node = logistica.on_controller_change
  def.after_place_node = after_controller_place
  def.drop = controller_name
  def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if clicker and clicker:is_player() then
      show_controller_formspec(pos, clicker:get_player_name())
      logistica.start_controller_timer(pos)
    end
  end
  def._mcl_hardness = 1.5
  def._mcl_blast_resistance = 10

  minetest.register_node(controller_name, def)
  logistica.register_non_pushable(controller_name)

  local def_disabled = table.copy(def)
  local tiles_disabled = def.tiles_disabled
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_timer = nil
  def_disabled.on_rightclick = nil

  minetest.register_node(controller_name.."_disabled", def_disabled)
end

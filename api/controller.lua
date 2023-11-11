local SET_BUTTON = "logsetbtn"
local NAME_FIELD = "namef"
local FORMSPEC_NAME = "logconren"
local controllerForms = {}

local function get_controller_formspec(pos)
  local name = logistica.get_network_name_or_nil(pos) or "<ERROR>"
  return "formspec_version[6]" ..
    "size[10.5,2]" ..
    logistica.ui.background..
    "field[2.5,0.6;3,0.8;"..NAME_FIELD..";Network Name;"..name.."]" ..
    "button[5.6,0.6;3,0.8;"..SET_BUTTON..";Set]"
end

local function show_controller_formspec(pos, playerName)
  controllerForms[playerName] = {position = pos}
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
    logistica.rename_network(minetest.hash_node_position(pos), newNetworkName)
    local meta = minetest.get_meta(pos)
    meta:set_string("infotext", "Controller of Network: "..newNetworkName)
    meta:set_string("name", newNetworkName)
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
function logistica.register_controller(name, def, tier)
  local controller_group = nil
  if not tier then
    tier = logistica.TIER_ALL
    controller_group = logistica.TIER_ALL
  else
    local ltier = string.lower(tier)
    logistica.tiers[ltier] = true
    controller_group = logistica.get_machine_group(ltier)
  end
   local controller_name = "logistica:" .. string.lower(name:gsub(" ", "_"))
  logistica.controllers[controller_name] = tier

  local on_construct = function(pos)
      logistica.start_controller_timer(pos)
      logistica.on_controller_change(pos, nil)
  end
  local after_destruct = logistica.on_controller_change

  if not def.groups then
    def.groups = {}
  end
  def.groups[controller_group] = 1
  def.groups[logistica.TIER_CONTROLLER] = 1
  def.on_timer = logistica.on_controller_timer
  def.on_construct = on_construct
  def.after_destruct = after_destruct
  def.after_place_node = after_controller_place
  def.drop = controller_name
  def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if clicker and clicker:is_player() then
      show_controller_formspec(pos, clicker:get_player_name())
    end
  end

  minetest.register_node(controller_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_destruct = nil
  def_disabled.on_timer = nil
  def_disabled.on_rightclick = nil

  minetest.register_node(controller_name.."_disabled", def_disabled)
end

logistica.register_controller("simple_controller", {
  description = "Simple Controller",
  tiles = { "logistica_silver_cable.png" },
  groups = {
    oddly_breakable_by_hand = 1, cracky = 2,
  },
  sounds = logistica.node_sound_metallic(),
  paramtype = "light",
  sunlight_propagates = false,
  drawtype = "normal",
  node_box = { type = "regular"},
})

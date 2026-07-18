local S = logistica.TRANSLATOR
local FS = logistica.FTRANSLATOR

local SET_BUTTON = "logsetbtn"
local NAME_FIELD = "namef"
local ACCESS_PLAYERS_FIELD = "access_players"
local HIDE_PROTECTION_CHECKBOX = "hide_with_protection"
local FORMSPEC_NAME = "logconren"
local MAX_NETWORK_NAME_LENGTH = 30
local controllerForms = {}

local function get_controller_formspec(pos)
  local meta = minetest.get_meta(pos)
  local name = minetest.formspec_escape(logistica.get_network_name_or_nil(pos) or "<ERROR>")
  local accessPlayers = minetest.formspec_escape(meta:get_string("access_players"))
  local hideProtection = meta:get_int("hide_with_protection") == 1
  local owner = meta:get_string("owner")
  local ownerLabel
  if owner == "" then
    ownerLabel = "label[0.5,4.6;" ..
      minetest.colorize("#FF4444", FS("Owner not set - dig up network controller and place it to set it!")) .. "]"
  else
    ownerLabel = "label[0.5,4.6;" .. FS("Owner: ") .. minetest.formspec_escape(owner) .. "]"
  end
  return "formspec_version[4]" ..
    "size[10.5,5.5]" ..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "field[0.5,0.6;7,0.8;"..NAME_FIELD..";"..FS("Network Name")..";"..name.."]" ..
    "button[7.6,0.6;2.5,0.8;"..SET_BUTTON..";"..FS("Set").."]" ..
    "field[0.5,2.0;9.5,0.8;"..ACCESS_PLAYERS_FIELD..";"..FS("Give Access To (comma-separated names, use <ALL> for everyone)")..";"..accessPlayers.."]" ..
    "checkbox[0.5,3.4;"..HIDE_PROTECTION_CHECKBOX..";"..FS("Hide network content based on area protection")..";"..tostring(hideProtection).."]" ..
    ownerLabel
end

local function show_controller_formspec(pos, playerName)
  controllerForms[playerName] = {position = pos}
  logistica.on_controller_timer(pos, 0) -- to ensure net is initialized, 0 elapsed so it doesn't also generate
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_controller_formspec(pos))
end

local function on_controller_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  local pos = (controllerForms[playerName] or {}).position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  -- checkbox fires immediately and does not resend on button press
  if fields[HIDE_PROTECTION_CHECKBOX] ~= nil then
    minetest.get_meta(pos):set_int("hide_with_protection", fields[HIDE_PROTECTION_CHECKBOX] == "true" and 1 or 0)
  end
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
    if fields[ACCESS_PLAYERS_FIELD] then
      meta:set_string("access_players", fields[ACCESS_PLAYERS_FIELD])
    end
    if readNetworkName ~= newNetworkName then
      show_controller_formspec(pos, playerName)
    end
  end
  return true
end

local function after_controller_place(pos, placer)
  if placer and placer:is_player() then
    minetest.get_meta(pos):set_string("owner", placer:get_player_name())
  end
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


local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "logistica_supplier"
local ON_OFF_BUTTON = "on_off_btn"

local supplierForms = {}

local function get_supplier_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)

  return "formspec_version[4]" ..
    "size["..(logistica.inv_width + 2.5)..",10.5]" ..
    logistica.ui.background..
    logistica.ui.on_off_btn(isOn, 7.0, 0.5, ON_OFF_BUTTON, S("Allow Storing from Network"))..
    "label[0.6,1.0;"..S("Passive Supplier: Items become available to network requests.").."]"..
    "list["..posForm..";main;0.4,1.4;8,2;0]"..
    logistica.inventory_formspec(0.4,4.5)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"
end

local function show_supplier_formspec(playerName, pos)
  supplierForms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_supplier_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not supplierForms[playerName] then return false end
  local pos = supplierForms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    supplierForms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_supplier_formspec(player:get_player_name(), pos)
  end
  return true
end

local function on_supplier_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_supplier_formspec(clicker:get_player_name(), pos)
end

local function after_place_supplier(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size("main", logistica.get_supplier_inv_size(pos))
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function allow_supplier_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_supplier_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_supplier_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return count
end

local function on_suppler_inventory_put(pos, listname, index, stack, player)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function on_suppler_inventory_take(pos, listname, index, stack, player)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function can_dig_supplier(pos, player)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty("main")
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    supplierForms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
-- `inventorySize` should be 16 at max
function logistica.register_supplier(desc, name, inventorySize, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local supplier_name = "logistica:"..lname
  logistica.suppliers[supplier_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = supplier_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_supplier,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_supplier_rightclick,
    allow_metadata_inventory_put = allow_supplier_storage_inv_put,
    allow_metadata_inventory_take = allow_supplier_inv_take,
    allow_metadata_inventory_move = allow_supplier_inv_move,
    on_metadata_inventory_put = on_suppler_inventory_put,
    on_metadata_inventory_take = on_suppler_inventory_take,
    can_dig = can_dig_supplier,
    logistica = {
      inventory_size = inventorySize,
      on_power = function(pos, power) logistica.set_node_tooltip_from_state(pos, nil, power) end,
      supplierMayAccept = true,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(supplier_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, handy = 1, pickaxey = 1, axey = 1, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(supplier_name.."_disabled", def_disabled)

end

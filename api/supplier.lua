local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logistica_supplier"
local BTN_ALLOW_MACHINES = "allow_machines_btn"
local BTN_ALLOW_AP       = "allow_ap_btn"
local META_ALLOW_MACHINES = "supplier_allow_machines"
local META_ALLOW_AP       = "supplier_allow_ap"
local FILTER_LIST = "filter"
local NUM_FILTER_SLOTS = 8

local supplierForms = {}

local function supplier_has_filter(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  local filterList = inv:get_list(FILTER_LIST)
  if not filterList then return false end
  for _, stack in ipairs(filterList) do
    if not stack:is_empty() then return true end
  end
  return false
end

local function get_supplier_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local meta = minetest.get_meta(pos)
  local allowMachines = meta:get_string(META_ALLOW_MACHINES) ~= "0"
  local allowAp       = meta:get_string(META_ALLOW_AP) ~= "0"
  local hasFilter = supplier_has_filter(pos)

  local depositBtn = ""
  if hasFilter then
    depositBtn = "button[7.75,8.2;2,0.75;deposit;"..FS("Desposit").."]"..
      "tooltip[deposit;Deposit all filtered items from inventory into supplier]"
  end

  return "formspec_version[4]" ..
    "size["..logistica.inv_size(10.5, 14.25).."]" ..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.6,0.4;"..FS("Passive Supplier\nItems become available to network requests.").."]"..
    "list["..posForm..";main;0.4,1.3;8,4;0]"..
    "label[0.4,6.3;"..FS("Items allowed to be stored (if empty, then all accepted):").."]"..
    "list["..posForm..";filter;0.4,6.5;8,1;0]"..
    logistica.ui.on_off_btn(allowMachines, 0.4,  7.85, BTN_ALLOW_MACHINES, FS("Allow Storing from Machines"))..
    logistica.ui.on_off_btn(allowAp,       4.6,  7.85, BTN_ALLOW_AP,       FS("Allow Storing from Access Point"))..
    depositBtn..
    logistica.player_inv_formspec(0.4, 9.05)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"
end

local function show_supplier_formspec(playerName, pos)
  supplierForms[playerName] = {position = pos}
  local meta = minetest.get_meta(pos)
  -- resize inventory for existing chests placed before the size increase
  local inv = meta:get_inventory()
  if inv:get_size("main") < logistica.get_supplier_inv_size(pos) then
    inv:set_size("main", logistica.get_supplier_inv_size(pos))
  end
  if inv:get_size(FILTER_LIST) < NUM_FILTER_SLOTS then
    inv:set_size(FILTER_LIST, NUM_FILTER_SLOTS)
  end
  -- migrate from old power-based toggle: power is no longer used for suppliers
  if logistica.is_machine_on(pos) then
    logistica.toggle_machine_on_off(pos)
  end
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_supplier_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not supplierForms[playerName] then return false end
  local pos = supplierForms[playerName].position
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    supplierForms[playerName] = nil
  elseif fields[BTN_ALLOW_MACHINES] then
    local meta = minetest.get_meta(pos)
    local current = meta:get_string(META_ALLOW_MACHINES) ~= "0"
    meta:set_string(META_ALLOW_MACHINES, current and "0" or "1")
    show_supplier_formspec(playerName, pos)
  elseif fields[BTN_ALLOW_AP] then
    local meta = minetest.get_meta(pos)
    local current = meta:get_string(META_ALLOW_AP) ~= "0"
    meta:set_string(META_ALLOW_AP, current and "0" or "1")
    show_supplier_formspec(playerName, pos)
  elseif fields.deposit then
    logistica.supplier_deposit_from_player(pos, playerName)
    show_supplier_formspec(playerName, pos)
  end
  return true
end

local function on_supplier_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  show_supplier_formspec(clicker:get_player_name(), pos)
end

local function after_place_supplier(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size("main", logistica.get_supplier_inv_size(pos))
  inv:set_size(FILTER_LIST, NUM_FILTER_SLOTS)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function allow_supplier_storage_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == FILTER_LIST then
    local inv = minetest.get_meta(pos):get_inventory()
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    inv:set_stack(FILTER_LIST, index, copyStack)
    show_supplier_formspec(player:get_player_name(), pos)
    return 0
  end
  return stack:get_count()
end

local function allow_supplier_inv_take(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == FILTER_LIST then
    local inv = minetest.get_meta(pos):get_inventory()
    inv:set_stack(FILTER_LIST, index, ItemStack(""))
    show_supplier_formspec(player:get_player_name(), pos)
    return 0
  end
  return stack:get_count()
end

local function allow_supplier_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if from_list == FILTER_LIST or to_list == FILTER_LIST then return 0 end
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
-- `inventorySize` is the number of inventory slots
function logistica.register_supplier(desc, name, inventorySize, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local supplier_name = "logistica:"..lname
  logistica.GROUPS.suppliers.register(supplier_name)
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
      supplierMayAccept = true,
      automatable = true,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(supplier_name, def)
  logistica.register_non_pushable(supplier_name)

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

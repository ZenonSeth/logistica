
local NUM_SUPPLY_SLOTS = 8
local PULL_LIST_PICKER = "pull_pick"
local ON_OFF_BUTTON = "on_off_btn"
local FORMSPEC_NAME = "logistica_supplier"

local supplierForms = {}

local function get_supplier_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local pushPos = logistica.get_supplier_target(pos)
  local meta = minetest.get_meta(pos)
  local selectedList = meta:get_string("suptarlist")
  local isOn = logistica.is_machine_on(pos)
  return "formspec_version[4]" ..
    "size[10.6,8]" ..
    logistica.ui.background..
    logistica.ui.pull_list_picker(PULL_LIST_PICKER, 6.7, 0.7, pushPos, selectedList, "Take from:")..
    logistica.ui.on_off_btn(isOn, 9.3, 0.5, ON_OFF_BUTTON, "Enable")..
    "label[0.6,1.2;Items to Supply (if empty nothing will be taken)]"..
    "list["..posForm..";filter;0.5,1.5;"..NUM_SUPPLY_SLOTS..",1;0]"..
    "list[current_player;main;0.5,3;8,4;0]"
end

local function show_supplier_formspec(playerName, pos)
  local pInfo = {}
  pInfo.position = pos
  supplierForms[playerName] = pInfo
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_supplier_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not supplierForms[playerName] then return false end
  if fields.quit then
    supplierForms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    local pos = supplierForms[playerName].position
    if not pos then return false end
    logistica.toggle_machine_on_off(pos)
    show_supplier_formspec(player:get_player_name(), pos)
  elseif fields[PULL_LIST_PICKER] then
    local selected = fields[PULL_LIST_PICKER]
    if logistica.is_allowed_pull_list(selected) then
      local pos = supplierForms[playerName].position
      if not pos then return false end
      logistica.set_supplier_target_list(pos, selected)
    end
  end
  return true
end

local function on_supplier_punch(pos, node, puncher, pointed_thing)
  local targetPos = logistica.get_supplier_target(pos)
  if targetPos and puncher:is_player() and puncher:get_player_control().sneak then
    minetest.add_entity(targetPos, "logistica:output_entity")
  end
end

local function on_supplier_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  show_supplier_formspec(clicker:get_player_name(), pos)
end

local function after_place_supplier(pos, placer, itemstack, numDemandSlots)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
	  meta:set_string("owner", placer:get_player_name())
  end
  logistica.toggle_machine_on_off(pos)
  meta:set_string("suptarlist", "dst")
	local inv = meta:get_inventory()
	inv:set_size("filter", numDemandSlots)
  logistica.on_supplier_change(pos)
end

local function allow_supplier_storage_inv_put(pos, listname, index, stack, player)
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local newStack = ItemStack(stack)
  newStack:set_count(1)
  inv:set_stack(listname, index, newStack)
  logistica.update_supplier_on_item_added(pos)
  return 0
end

local function allow_supplier_inv_take(pos, listname, index, stack, player)
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local slotStack = inv:get_stack(listname, index)
  slotStack:take_item(stack:get_count())
  inv:set_stack(listname, index, slotStack)
  return 0
end

local function allow_supplier_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
-- `maxTransferRate` indicates how many nodes at a time this supplier can take when asked
function logistica.register_supplier(simpleName, maxTransferRate)
  local lname = string.lower(simpleName:gsub(" ", "_"))
  local supplier_name = "logistica:supplier_"..lname
  logistica.suppliers[supplier_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = simpleName.." Supplier",
    drawtype = "normal",
    tiles = {
      "logistica_"..lname.."_supplier_side.png^[transformR270",
      "logistica_"..lname.."_supplier_side.png^[transformR90",
      "logistica_"..lname.."_supplier_side.png^[transformR180",
      "logistica_"..lname.."_supplier_side.png",
      "logistica_"..lname.."_supplier_back.png",
      "logistica_"..lname.."_supplier_front.png",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = supplier_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = function (pos, placer, itemstack)
      after_place_supplier(pos, placer, itemstack, NUM_SUPPLY_SLOTS)
    end,
    on_punch = on_supplier_punch,
    on_rightclick = on_supplier_rightclick,
    allow_metadata_inventory_put = allow_supplier_storage_inv_put,
    allow_metadata_inventory_take = allow_supplier_inv_take,
    allow_metadata_inventory_move = allow_supplier_inv_move,
    logistica = {
      supplier_transfer_rate = maxTransferRate
    }
  }

  minetest.register_node(supplier_name, def)

	local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_desctruct = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

	minetest.register_node(supplier_name.."_disabled", def_disabled)

end

logistica.register_supplier("Item", 1)
logistica.register_supplier("Stack", 99)

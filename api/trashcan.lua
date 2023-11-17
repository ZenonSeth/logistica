local S = logistica.TRANSLATOR

local INV_FILT = "filt"
local INV_MAIN = "main"
local INV_UNDO = "dst"

local function get_trashcan_formspec()
  return "formspec_version[4]" ..
    "size[10.6,9.2]" ..
    logistica.ui.background..
    "label[0.5,0.4;"..S("List of Items to delete, if they can't be put elsewhere in the Network.").."]"..
    "label[0.5,0.8;"..S("If list is empty, it will delete all excess items.").."]"..
    "list[context;"..INV_FILT..";0.5,1.1;8,1;0]"..
    "label[3.0,2.6;"..S("Trash slot").."]" ..
    "list[context;"..INV_MAIN..";3.0,2.8;1,1;0]"..
    "label[6.75,2.6;"..S("Last deleted item").."]"..
    "list[context;"..INV_UNDO..";6.75,2.8;1,1;0]"..
    "list[current_player;main;0.5,4.2;8,4;0]"..
    "listring[current_player;main]"..
    "listring[context;"..INV_MAIN.."]"
end

local function after_place_trashcan(pos, _, _)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_FILT, 8)
  inv:set_size(INV_MAIN, 1)
  inv:set_size(INV_UNDO, 1)
  meta:set_string("formspec", get_trashcan_formspec())
  logistica.on_trashcan_change(pos)
end

local function allow_trashcan_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_UNDO then return 0 end
  if listname == INV_FILT then
    local inv = minetest.get_meta(pos):get_inventory()
    local copyStack = ItemStack(stack) ; copyStack:set_count(1)
    inv:set_stack(listname, index, copyStack)
    return 0
  end
  return stack:get_count()
end

local function allow_trashcan_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if  listname == INV_FILT then
    local inv = minetest.get_meta(pos):get_inventory()
    inv:set_stack(listname, index, ItemStack(""))
    return 0
  end
  return stack:get_count()
end

local function allow_trashcan_inv_move(_, _, _, _, _, _, _)
  return 0
end

local function on_trashcan_inventory_put (pos, listname, index, _, _)
  if listname == INV_MAIN then
    local inv = minetest.get_meta(pos):get_inventory()
    local stack = inv:get_stack(listname, index)
    inv:set_stack(listname, index, ItemStack(""))
    inv:set_stack(INV_UNDO, 1, stack)
  end
end

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
function logistica.register_trashcan(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local trashcan_name = "logistica:"..lname
  logistica.trashcans[trashcan_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "none",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = trashcan_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_trashcan,
    after_destruct = logistica.on_trashcan_change,
    allow_metadata_inventory_put = allow_trashcan_inv_put,
    allow_metadata_inventory_take = allow_trashcan_inv_take,
    allow_metadata_inventory_move = allow_trashcan_inv_move,
    on_metadata_inventory_put = on_trashcan_inventory_put,
    logistica = { },
  }

  minetest.register_node(trashcan_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_destruct = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(trashcan_name.."_disabled", def_disabled)

end

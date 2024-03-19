
local function after_place_access_point(pos, placer, itemstack, numSlots, numUpgradeSlots)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  logistica.access_point_after_place(pos, meta)
  logistica.on_access_point_change(pos)
end

local function allow_access_point_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return logistica.access_point_allow_put(pos, listname, index, stack, player)
end

local function allow_access_point_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return logistica.access_point_allow_take(pos, listname, index, stack, player)
end

local function allow_access_point_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return logistica.access_point_allow_move(pos, from_list, from_index, to_list, to_index, count, player)
end

local function on_access_point_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  logistica.access_point_on_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
end

local function on_access_point_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  logistica.access_point_on_put(pos, listname, index, stack, player)
end

local function on_access_point_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  logistica.access_point_on_take(pos, listname, index, stack, player)
end

local function on_access_point_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  logistica.access_point_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
end

local function after_dig_access_point(pos, oldnode, oldmeta, digger)
  logistica.on_access_point_change(pos, oldnode, oldmeta)
  logistica.access_point_on_dug(pos)
end

local function can_dig_access_point(pos, player)
  return true
end

----------------------------------------------------------------
-- registration calls
----------------------------------------------------------------

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    logistica.access_point_on_player_leave(objRef:get_player_name())
  end
end)

minetest.register_on_player_receive_fields(logistica.on_receive_access_point_formspec)

----------------------------------------------------------------
-- public api 
----------------------------------------------------------------

-- `simpleName` is used for the description and for the name (can contain spaces)
function logistica.register_access_point(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local access_point_name = "logistica:"..lname
  logistica.GROUPS.misc_machines.register(access_point_name)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1, [logistica.TIER_ACCESS_POINT] = 1 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "nodebox",
    tiles = tiles,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
        {-0.4375, -0.5, -0.4375, 0.4375, -0.375, -0.1875},
        {-0.125, -0.5, -0.0625, 0.125, 0.1875, 0.0625},
        {-0.5, -0.3125, -0.125, 0.5, 0.5, -0.0625},
      },
    },
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = access_point_name,
    sounds = logistica.node_sound_metallic(),
    can_dig = can_dig_access_point,
    connect_sides = {"top", "bottom", "left", "back", "right" },
    after_place_node = after_place_access_point,
    after_dig_node = after_dig_access_point,
    on_rightclick = on_access_point_rightclick,
    -- on_metadata_inventory_move = on_access_point_inv_move,
    -- on_metadata_inventory_put = on_access_point_inv_put,
    -- on_metadata_inventory_take = on_access_point_inv_take,
    -- allow_metadata_inventory_put = allow_access_point_inv_put,
    -- allow_metadata_inventory_take = allow_access_point_inv_take,
    -- allow_metadata_inventory_move = allow_access_point_inv_move,
    logistica = {},
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(access_point_name, def)

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

  minetest.register_node(access_point_name.."_disabled", def_disabled)

end

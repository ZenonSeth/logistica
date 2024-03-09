
--------------------------------
-- callbacks
--------------------------------

local function on_rightclick_sync(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  logistica.sync_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
end

local function after_place_sync(pos, placer, itemstack)
  logistica.sync_after_place(pos, placer, itemstack)
end

local function allow_storage_inv_put_sync(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return logistica.sync_allow_storage_inv_put(pos, listname, index, stack, player)
end

local function allow_inv_take_sync(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return logistica.sync_allow_inv_take(pos, listname, index, stack, player)
end

local function allow_inv_move_sync(_, _, _, _, _, _, _)
  return 0
end


----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

-- `simpleName` is used for the description and for the name (can contain spaces)
function logistica.register_synchronizer(description, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local syncName = "logistica:"..lname

  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1 }
  local def = {
    description = description,
    drawtype = "normal",
    tiles = tiles,
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = syncName,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_sync,
    on_rightclick = on_rightclick_sync,
    can_dig = logistica.sync_can_dig,
    allow_metadata_inventory_put = allow_storage_inv_put_sync,
    allow_metadata_inventory_take = allow_inv_take_sync,
    allow_metadata_inventory_move = allow_inv_move_sync,
    -- on_metadata_inventory_move = logistica.sync_on_inv_move,
    on_metadata_inventory_put = logistica.sync_on_inv_put,
    on_metadata_inventory_take = logistica.sync_on_inv_take,
    logistica = {},
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(syncName, def)
end


local META_SUPPLIER_LISTNAME = "suptarlist"

function logistica.get_supplier_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local shift = logistica.get_rot_directions(node.param2).backward
  if not shift then return nil end
  return {x = (pos.x + shift.x),
          y = (pos.y + shift.y),
          z = (pos.z + shift.z)}
end

function logistica.get_supplier_target_list(pos)
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  return meta:get_string(META_SUPPLIER_LISTNAME)
end

function logistica.set_supplier_target_list(pos, listName)
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string(META_SUPPLIER_LISTNAME, listName)
end

function logistica.get_supplier_max_item_transfer(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return 0 end
  local def = minetest.registered_nodes[node.name]
  if def and def.logistica and def.logistica.supplier_transfer_rate then
    return def.logistica.supplier_transfer_rate
  else
    return 0
  end
end

-- returns an ItemStack of how many items were taken
function logistica.take_item_from_supplier(pos, stack)
  logistica.load_position(pos)
  if not logistica.is_machine_on(pos) then return ItemStack("") end
  local meta = minetest.get_meta(pos)
  local canTake = math.min(stack:get_count(), logistica.get_supplier_max_item_transfer(pos))
  local copyStack = ItemStack(stack)
  copyStack:set_count(canTake)

  local targetListName = meta:get_string(META_SUPPLIER_LISTNAME)
  local targetPos = logistica.get_supplier_target(pos)
  logistica.load_position(targetPos)
  local targetInv = minetest.get_meta(targetPos):get_inventory()
  local targetList = targetInv:get_list(targetListName)
  if not targetList then copyStack:set_count(0); return copyStack end
  return targetInv:remove_item(targetListName, copyStack)
end

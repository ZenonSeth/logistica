
local META_SUPPLIER_LIST = "main"

function logistica.get_supplier_inv_size(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return 0 end
  local def = minetest.registered_nodes[node.name]
  if def and def.logistica and def.logistica.inventory_size then
    return def.logistica.inventory_size
  else
    return 0
  end
end

-- returns an ItemStack of how many items were taken
function logistica.take_item_from_supplier(pos, stack)
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:remove_item(META_SUPPLIER_LIST, stack)
end


-- tries to put the given item in this supplier, returns what's leftover
function logistica.put_item_in_supplier(pos, stack)
  local nodeName = minetest.get_node(pos).name
  if not logistica.is_supplier(nodeName) then return stack end
  -- only insert if its enabled
  if not logistica.is_machine_on(pos) then return stack end
  local origCount = stack:get_count()
  local inv = minetest.get_meta(pos):get_inventory()
  local leftover = inv:add_item(META_SUPPLIER_LIST, stack)
  if leftover:get_count() < origCount then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end
  return leftover
end
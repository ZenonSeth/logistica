
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
  if not logistica.is_machine_on(pos) then return ItemStack("") end
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  return inv:remove_item(META_SUPPLIER_LIST, stack)
end

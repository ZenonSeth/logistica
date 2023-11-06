
function logistica.get_supplier_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local shift = logistica.get_rot_directions(node.param2).backward
  if not shift then return nil end
  return {x = (pos.x + shift.x),
          y = (pos.y + shift.y),
          z = (pos.z + shift.z)}
end

function logistica.get_supplier_max_item_transfer(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return 0 end
  local def = minetest.registered_nodes[node]
  if def and def.logistica and def.logistica.supplier_transfer_rate then
    return def.logistica.supplier_transfer_rate
  else
    return 0
  end
end

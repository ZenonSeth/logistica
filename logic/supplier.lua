
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
function logistica.take_item_from_supplier_simple(pos, stack)
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local removed = inv:remove_item(META_SUPPLIER_LIST, stack)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  return removed
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

-- returns the number of items remaining to be fulfilled, or 0 if entire request was fulfilled
function logistica.take_item_from_supplier(supplierPos, stackToTake, network, collectorFunc, useMetadata, dryRun, optIgnorePosition)
  if optIgnorePosition == nil then optIgnorePosition = -1 end
  local eq = function(s1, s2) return s1:get_name() == s2:get_name() end
  if stackToTake:get_stack_max() == 1 and useMetadata then eq = function(s1, s2) return s1:equals(s2) end end
  logistica.load_position(supplierPos)
  local remaining = stackToTake:get_count()

  local supplierInv = minetest.get_meta(supplierPos):get_inventory()
  local supplyList = supplierInv:get_list(META_SUPPLIER_LIST)
  for i, supplyStack in ipairs(supplyList) do
  if i ~= optIgnorePosition and eq(supplyStack, stackToTake) then
    local supplyCount = supplyStack:get_count()
    if supplyCount >= remaining then -- enough to fulfil requested
      local toSend = ItemStack(supplyStack) ; toSend:set_count(remaining)
      local leftover = collectorFunc(toSend)
      local newSupplyCount = supplyCount - remaining + leftover
      supplyStack:set_count(newSupplyCount)
      if not dryRun then
        supplierInv:set_stack(META_SUPPLIER_LIST, i, supplyStack)
        if newSupplyCount <= 0 then
          logistica.update_cache_at_pos(supplierPos, LOG_CACHE_SUPPLIER, network)
        end
      end
      return 0
    else -- not enough to fulfil requested
      local toSend = ItemStack(supplyStack)
      local leftover = collectorFunc(toSend)
      remaining = remaining - (supplyCount - leftover)
      supplyStack:set_count(leftover)
      if leftover > 0 then -- for some reason we could not insert all - exit early
        if not dryRun then
          supplierInv:set_stack(META_SUPPLIER_LIST, i, supplyStack)
        end
        return 0
      end
    end
  end
  end
  -- if we get there, we did not fulfil the request from this supplier
  -- but some items still may have been inserted
  if not dryRun then
    logistica.update_cache_at_pos(supplierPos, LOG_CACHE_SUPPLIER, network)
  end
  return remaining
end

local S = logistica.TRANSLATOR

local META_SUPPLIER_LIST  = "main"
local META_ALLOW_MACHINES = "supplier_allow_machines"
local META_ALLOW_AP       = "supplier_allow_ap"

local function ret(remaining, optError)
  return { remaining = remaining, error = optError and S(optError) or nil }
end

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

-- true only for supplier-type nodes players can deposit into directly (passive supplier chests),
-- as opposed to generator/crafting/cooking/farming suppliers which fill themselves
function logistica.is_passive_supplier_node(nodeName)
  local def = minetest.registered_nodes[nodeName]
  return def ~= nil and def.logistica ~= nil and def.logistica.supplierMayAccept == true
end

-- merges same-name stacks (respecting stack_max) and sorts them by the given criteria
-- (one of LOG_SORT_NAME_AZ, LOG_SORT_MOD_AZ, etc. from util/inv_list_sorting.lua; defaults
-- to LOG_SORT_NAME_AZ); unstackable items (tools etc.) are kept as separate entries
function logistica.sort_supplier_inventory(pos, criteria)
  criteria = criteria or LOG_SORT_NAME_AZ
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local size = inv:get_size(META_SUPPLIER_LIST)
  if size == 0 then return end

  local totals = {}    -- itemName -> total count
  local nameOrder = {} -- first-seen order of stackable item names
  local singles = {}   -- unstackable stacks, kept as-is

  for _, stack in ipairs(logistica.get_list(inv, META_SUPPLIER_LIST)) do
    if not stack:is_empty() then
      if stack:get_stack_max() <= 1 then
        singles[#singles + 1] = ItemStack(stack)
      else
        local name = stack:get_name()
        if not totals[name] then
          totals[name] = 0
          nameOrder[#nameOrder + 1] = name
        end
        totals[name] = totals[name] + stack:get_count()
      end
    end
  end

  local merged = {}
  for _, name in ipairs(nameOrder) do
    local remaining = totals[name]
    local maxCount = ItemStack(name):get_stack_max()
    while remaining > 0 do
      local stack = ItemStack(name)
      local take = math.min(remaining, maxCount)
      stack:set_count(take)
      merged[#merged + 1] = stack
      remaining = remaining - take
    end
  end
  for _, stack in ipairs(singles) do merged[#merged + 1] = stack end

  local sorted = logistica.sort_list_by(merged, criteria) or {}
  while #sorted < size do sorted[#sorted + 1] = ItemStack("") end
  for i = size + 1, #sorted do sorted[i] = nil end

  inv:set_list(META_SUPPLIER_LIST, sorted)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

-- tries to put the given item in this supplier, returns what's leftover
-- isAutomated: true if called by a machine, false if called by a user (access point)
function logistica.put_item_in_supplier(pos, stack, isAutomated)
  local nodeName = minetest.get_node(pos).name
  if not logistica.GROUPS.suppliers.is(nodeName) then return stack end
  local nodeDef = minetest.registered_nodes[nodeName]
  if not nodeDef or not nodeDef.logistica then return stack end
  if not nodeDef.logistica.supplierMayAccept then return stack end
  -- check per-source allow flags
  local meta = minetest.get_meta(pos)
  if isAutomated then
    if meta:get_string(META_ALLOW_MACHINES) == "0" then return stack end
  else
    if meta:get_string(META_ALLOW_AP) == "0" then return stack end
  end
  local inv = meta:get_inventory()
  local filterList = inv:get_list("filter")
  if filterList then
    local hasAnyFilter = false
    local itemAllowed = false
    local itemName = stack:get_name()
    for _, filterStack in ipairs(filterList) do
      if not filterStack:is_empty() then
        hasAnyFilter = true
        if filterStack:get_name() == itemName then
          itemAllowed = true
          break
        end
      end
    end
    if hasAnyFilter and not itemAllowed then return stack end
  end
  local origCount = stack:get_count()
  local leftover = inv:add_item(META_SUPPLIER_LIST, stack)
  if leftover:get_count() < origCount then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end
  return leftover
end

-- returns table { remaining = # (how many items remain unfulfiled, 0 if full successful), error = "Error msg"/nil }
function logistica.take_item_from_supplier(supplierPos, stackToTake, network, collectorFunc, useMetadata, dryRun, optIgnorePosition)
  if optIgnorePosition == nil then optIgnorePosition = -1 end
  local eq = function(s1, s2) return s1:get_name() == s2:get_name() end
  if stackToTake:get_stack_max() == 1 and useMetadata then eq = function(s1, s2) return s1:equals(s2) end end
  logistica.load_position(supplierPos)
  local remaining = stackToTake:get_count()
  local isInfinite = logistica.is_pos_infinite(supplierPos)

  local supplierInv = minetest.get_meta(supplierPos):get_inventory()
  local supplyList = logistica.get_list(supplierInv, META_SUPPLIER_LIST)
  for i, supplyStack in ipairs(supplyList) do
  if i ~= optIgnorePosition and eq(supplyStack, stackToTake) then
    local supplyCount = supplyStack:get_count()
    if isInfinite then supplyCount = remaining end
    if supplyCount >= remaining then -- enough to fulfil requested
      local toSend = ItemStack(supplyStack) ; toSend:set_count(remaining)
      local leftover = collectorFunc(toSend)
      if not isInfinite then
        local newSupplyCount = supplyCount - remaining + leftover
        supplyStack:set_count(newSupplyCount)
        if not dryRun then
          supplierInv:set_stack(META_SUPPLIER_LIST, i, supplyStack)
          if newSupplyCount <= 0 then
            logistica.update_cache_at_pos(supplierPos, LOG_CACHE_SUPPLIER, network)
          end
        end
      end
      return ret(0)
    else -- not enough to fulfil requested
      local toSend = ItemStack(supplyStack)
      local leftover = collectorFunc(toSend)
      remaining = remaining - (supplyCount - leftover)
      supplyStack:set_count(leftover)
      if not dryRun then
        supplierInv:set_stack(META_SUPPLIER_LIST, i, supplyStack)
      end
      if leftover > 0 then -- for some reason we could not insert all - exit early
        return ret(remaining, "Could not fulfil entire request: requester did not accept all items")
      end
    end
  end
  end
  -- if we get there, we did not fulfil the request from this supplier
  -- but some items still may have been inserted
  if not dryRun then
    logistica.update_cache_at_pos(supplierPos, LOG_CACHE_SUPPLIER, network)
  end

  return ret(remaining, "Not enough items to fulfil entire request")
end

function logistica.supplier_deposit_from_player(pos, playerName)
  local player = minetest.get_player_by_name(playerName)
  if not player then return end
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local filterList = inv:get_list("filter")
  if not filterList then return end
  local allowedItems = {}
  for _, fStack in ipairs(filterList) do
    if not fStack:is_empty() then
      allowedItems[fStack:get_name()] = true
    end
  end
  if not next(allowedItems) then return end
  local playerInv = player:get_inventory()
  local changed = false
  for i = 1, playerInv:get_size("main") do
    local pStack = playerInv:get_stack("main", i)
    if not pStack:is_empty() and allowedItems[pStack:get_name()] then
      local leftover = inv:add_item(META_SUPPLIER_LIST, pStack)
      if leftover:get_count() < pStack:get_count() then
        playerInv:set_stack("main", i, leftover)
        changed = true
      end
    end
  end
  if changed then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end
end

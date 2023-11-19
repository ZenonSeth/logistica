
local MASS_STORAGE_LIST_NAME = "storage"
local ITEM_STORAGE_LIST_NAME = "main"

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

-- tries to take a stack from the network locations
-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- note that it may be called multiple times as the itemstack is gathered from mass storage
-- `isAutomatedRequest` is optional, assumed to be false if not set
-- `useMetaData` is optional, assume false if not set - only applies to items with stack_max = 1
function logistica.take_stack_from_network(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun)
  if not network then return false end
  -- first check suppliers
  if logistica.take_stack_from_suppliers(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun) then
    return
  end
  -- then check storages
  if stackToTake:get_stack_max() <= 1 then
    logistica.take_stack_from_item_storage(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun)
  else
    logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc, isAutomatedRequest, dryRun)
  end
end

-- tries to take the given stack from the passive suppliers on the network
-- calls the collectorFunc with the stack when necessary
-- note that it may be called multiple times as the itemstack is gathered from mass storage
function logistica.take_stack_from_suppliers(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun)
  local takeStack = ItemStack(stackToTake)
  local requestedAmount = stackToTake:get_count()
  local remaining = requestedAmount
  local stackName = stackToTake:get_name()
  local validSupplers = network.supplier_cache[stackName] or {}
  for hash, _ in pairs(validSupplers) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    local nodeName = minetest.get_node(pos).name
    if logistica.is_supplier(nodeName) or logistica.is_vaccuum_supplier(nodeName) then
      remaining = logistica.take_item_from_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun)
    elseif logistica.is_crafting_supplier(nodeName) then
      remaining = logistica.take_item_from_crafting_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun)
    end
    if remaining <= 0 then
      return true
    end
    takeStack:set_count(remaining)
  end
  return false
end

-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- returns true if item successfully found and given to collector, false otherwise
function logistica.take_stack_from_item_storage(stack, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun)
  local eq = function(s1, s2) return s1:get_name() == s2:get_name() end
  if useMetadata then eq = function(s1, s2) return s1:equals(s2) end end

  for storageHash, _ in pairs(network.item_storage) do
    local storagePos = minetest.get_position_from_hash(storageHash)
    local storageInv = get_meta(storagePos):get_inventory()
    local storageList = storageInv:get_list(ITEM_STORAGE_LIST_NAME) or {}
    for i, storedStack in ipairs(storageList) do
      if (not storedStack:is_empty()) and eq(storedStack, stack) then
        local leftover = collectorFunc(storedStack)
        if leftover == 0 then -- stack max is 1, so just take the whole itemstack out
          storageList[i] = ItemStack("")
          if not dryRun then
            storageInv:set_list(ITEM_STORAGE_LIST_NAME, storageList)
          end
          return true
        else  -- otherwise, the insert failed, don't take stack
          return false
        end
      end -- end check if names equal
    end -- end loop over storageList
  end
  return false
end

-- tries to take a stack from the given network's mass storages
-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- note that it may be called multiple times as the itemstack is gathered from mass storage
-- returns true if item successfully found and given to collector, false otherwise
function logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc, isAutomatedRequest, dryRun)
  local stackToTakeName = stackToTake:get_name()
  local remainingRequest = stackToTake:get_count()
  local massLocations = network.storage_cache[stackToTake:get_name()]
  if stackToTake:get_count() == 0 then return end
  if massLocations == nil then return end
  for storageHash, _ in pairs(massLocations) do
    local storagePos = minetest.get_position_from_hash(storageHash)
    local meta = get_meta(storagePos)
    local storageInv = meta:get_inventory()
    local storageList = storageInv:get_list(MASS_STORAGE_LIST_NAME) or {}
    -- we can't use the usual take/put methods because mass storage exceeds max stack
    for i = #storageList, 1, -1 do -- traverse backwards for taking items
      local storageStack = storageList[i]
      local slotReserve = logistica.get_mass_storage_reserve(meta, i)
      local available = storageStack:get_count()
      if isAutomatedRequest then available = math.max(0, available - slotReserve) end
      if stackToTakeName == storageStack:get_name() and available > 0 then
        local numTaken = math.min(available, remainingRequest)
        local takenStack = ItemStack(stackToTake)
        takenStack:set_count(numTaken)
        local leftover = collectorFunc(takenStack)
        numTaken = numTaken - leftover
        storageStack:set_count(storageStack:get_count() - numTaken)
        remainingRequest = remainingRequest - numTaken
        if remainingRequest <= 0 then
          if not dryRun then
            storageInv:set_list(MASS_STORAGE_LIST_NAME, storageList)
          end
          return true
        end
      end
      i = i - 1
    end
    if not dryRun then
      storageInv:set_list(MASS_STORAGE_LIST_NAME, storageList)
    end
  end
  return false
end

-- try to insert the item into the item storage, returning a stack of remaining items
function logistica.insert_item_into_item_storage(pos, inv, inputStack, dryRun)
  if logistica.is_machine_on(pos) and inputStack:get_stack_max() == 1 and inv:room_for_item("main", inputStack) then
    -- tool storage only takes individual items
    if not dryRun then
      inv:add_item("main", inputStack)
    end
    return ItemStack("")
  else
    return inputStack
  end
end

-- attempts to insert the given itemstack in the network, returns how many items remain
function logistica.insert_item_in_network(itemstack, networkId, dryRun)
  local network = logistica.get_network_by_id_or_nil(networkId)
  if not itemstack or itemstack:is_empty() then return 0 end
  if not network then return itemstack:get_count() end

  local workingStack = ItemStack(itemstack)

  -- check requesters first
  local listOfRequestersInNeedOfItem = network.requester_cache[itemstack:get_name()] or {}
  for hash, _ in pairs(listOfRequestersInNeedOfItem) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    local leftover = logistica.insert_itemstack_for_requester(pos, workingStack, true)
    if leftover <= 0 then return 0 end -- we took all items
    workingStack:set_count(leftover)
  end

  -- check storages
  local storages = {}
  local addFunc = nil
  if itemstack:get_stack_max() <= 1 then
    storages = network.item_storage
    addFunc = logistica.insert_item_into_item_storage
  else
    storages = network.storage_cache[itemstack:get_name()] or {}
    addFunc = logistica.insert_item_into_mass_storage
  end
  for hash, _ in pairs(storages) do
    local pos = minetest.get_position_from_hash(hash)
    local inv = get_meta(pos):get_inventory()
    local remainingStack = addFunc(pos, inv, workingStack, dryRun)
    if remainingStack:is_empty() then return 0 end -- we took all items
    workingStack = remainingStack
  end

  -- try to add to passive suppliers that accept this
  local suppliers = network.suppliers
  for hash, _ in pairs(suppliers) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    local leftover = logistica.put_item_in_supplier(pos, workingStack)
    if leftover:is_empty() then return 0 end
    workingStack = leftover
  end

  -- [Keep this last] delete the item if any trashcan accepts it
  local trashcans = network.trashcans or {}
  for hash, _ in pairs(trashcans) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    workingStack = logistica.trashcan_trash_item(pos, workingStack)
    if workingStack:is_empty() then return 0 end
  end

  return workingStack:get_count()
end
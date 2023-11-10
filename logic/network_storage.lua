
local MASS_STORAGE_LIST_NAME = "storage"
local ITEM_STORAGE_LIST_NAME = "main"
local SUPPLIER_LIST_NAME = "main"

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function updateSupplierCacheFor(supplierPosList)
  for _, pos in ipairs(supplierPosList) do
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end
end

-- tries to take a stack from the network locations
-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- note that it may be called multiple times as the itemstack is gathered from mass storage
function logistica.take_stack_from_network(stackToTake, network, collectorFunc, isAutomatedRequest)
  if not network then return false end
  -- first check suppliers
  if logistica.take_stack_from_suppliers(stackToTake, network, collectorFunc, isAutomatedRequest) then
    return
  end
  -- then check storages
  if stackToTake:get_stack_max() <= 1 then
    logistica.take_stack_from_item_storage(stackToTake, network, collectorFunc, isAutomatedRequest)
  else
    logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc, isAutomatedRequest)
  end
end

-- tries to take the given stack from the passive suppliers on the network
-- calls the collectorFunc with the stack when necessary
-- note that it may be called multiple times as the itemstack is gathered from mass storage
function logistica.take_stack_from_suppliers(stackToTake, network, collectorFunc, isAutomatedRequest)
  local requestedAmount = stackToTake:get_count()
  local remaining = requestedAmount
  local stackName = stackToTake:get_name()
  local validSupplers = network.supplier_cache[stackName] or {}
  local modifiedPos = {}
  for hash, _ in pairs(validSupplers) do
    local supplierPos = minetest.get_position_from_hash(hash)
    local supplierInv = get_meta(supplierPos):get_inventory()
    local machineIsOn = logistica.is_machine_on(supplierPos)
    local supplyList = (machineIsOn and supplierInv:get_list(SUPPLIER_LIST_NAME)) or {}
    for i, supplyStack in ipairs(supplyList) do
    if supplyStack:get_name() == stackName then
      table.insert(modifiedPos, supplierPos)
      local supplyCount = supplyStack:get_count()
      if supplyCount >= remaining then -- enough to fulfil requested
        local toSend = ItemStack(supplyStack) ; toSend:set_count(remaining)
        local leftover = collectorFunc(toSend)
        local newSupplyCount = supplyCount - remaining + leftover
        supplyStack:set_count(newSupplyCount)
        supplierInv:set_stack(SUPPLIER_LIST_NAME, i, supplyStack)
        if newSupplyCount <= 0 then
          updateSupplierCacheFor(modifiedPos)
        end
        return true
      else -- not enough to fulfil requested
        local toSend = ItemStack(supplyStack)
        local leftover = collectorFunc(toSend)
        remaining = remaining - (supplyCount - leftover)
        supplyStack:set_count(leftover)
        if leftover > 0 then -- for some reason we could not insert all - exit early
          supplierInv:set_stack(SUPPLIER_LIST_NAME, i, supplyStack)
          return true
        end
      end
    end
    end
    -- if we get there, we did not fulfil the request from this supplier
    -- but some items still may have been inserted
    if machineIsOn then supplierInv:set_list(SUPPLIER_LIST_NAME, supplyList) end
  end
  updateSupplierCacheFor(modifiedPos)
  return false
end

-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- returns true if item successfully found and given to collector, false otherwise
function logistica.take_stack_from_item_storage(stack, network, collectorFunc, isAutomatedRequest)
  local stackName = stack:get_name()
  for storageHash, _ in pairs(network.item_storage) do
    local storagePos = minetest.get_position_from_hash(storageHash)
    local storageInv = get_meta(storagePos):get_inventory()
    if logistica.is_machine_on(storagePos) then
      local storageList = storageInv:get_list(ITEM_STORAGE_LIST_NAME) or {}
      for i, storedStack in ipairs(storageList) do
        if storedStack:get_name() == stackName then
          local leftover = collectorFunc(storedStack)
          if leftover == 0 then -- stack max is 1, so just take the whole itemstack out
            storageList[i] = ItemStack("")
            storageInv:set_list(ITEM_STORAGE_LIST_NAME, storageList)
            return true
          else  -- otherwise, the insert failed, don't take stack
            return false
          end
        end -- end check if names equal
      end -- end loop over storageList
    end -- end if machine is on
  end
  return false
end

-- tries to take a stack from the given network
-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- note that it may be called multiple times as the itemstack is gathered from mass storage
-- returns true if item successfully found and given to collector, false otherwise
function logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc, isAutomatedRequest)
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
          storageInv:set_list(MASS_STORAGE_LIST_NAME, storageList)
          return true
        end
      end
      i = i - 1
    end
    storageInv:set_list(MASS_STORAGE_LIST_NAME, storageList)
  end
  return false
end

-- try to insert the item into the storage, returning how many items remain
function logistica.try_to_add_item_to_storage(pos, inputStack, dryRun)
  local node = minetest.get_node(pos)
  if not logistica.is_mass_storage(node.name) and not logistica.is_item_storage(node.name) then return 0 end
  local isMassStorage = string.find(node.name, "mass")
  logistica.load_position(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  if isMassStorage then
    local remainingStack = logistica.insert_item_into_mass_storage(pos, inv, inputStack, dryRun)
    return remainingStack:get_count()
  else -- it's not mass storage, must be tool storage
    if inputStack:get_stack_max() == 1 and inv:room_for_item("main", inputStack) then
      -- tool storage only takes individual items
      inv:add_item("main", inputStack)
      return 0
    end
  end
  return inputStack:get_count()
end

-- attempts to insert the given itemstack in the network, returns how many items remain
function logistica.insert_item_in_network(itemstack, networkId)
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
  if itemstack:get_stack_max() <= 1 then
    storages = network.item_storage
  else
    storages = network.mass_storage
  end
  for hash, _ in pairs(storages) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    local remain = logistica.try_to_add_item_to_storage(pos, workingStack)
    if remain <= 0 then return 0 end -- we took all items
    workingStack:set_count(remain)
  end

  return workingStack:get_count()
end

local MASS_STORAGE_LIST_NAME = "storage"
local ITEM_STORAGE_LIST_NAME = "main"
local MAX_NETWORK_DEPTH_SEARCH = 16 -- somewhat arbitrary but prevents stackoverflows

local h2p = minetest.get_position_from_hash

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

--------------------------------
-- public functions
--------------------------------

-- returns the new stack to replace the empty bucket given, or nil if not successful
function logistica.fill_bucket_from_network(network, bucketItemStack, liquidName)
  local lowestReservoirPos = nil
  local lowestReservoirLvl = 999999
  for hash, _ in pairs(network.reservoirs or {}) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    if logistica.reservoir_get_liquid_name(pos) == liquidName then
      local levels = logistica.reservoir_get_liquid_level(pos)
      if levels and levels[1] < lowestReservoirLvl then
        lowestReservoirPos = pos
        lowestReservoirLvl = levels[1]
      end
    end
  end

  if lowestReservoirPos then
    return logistica.reservoir_use_item_on(lowestReservoirPos, bucketItemStack)
  else
    return nil
  end
end

-- returns the new stack to replace the filled bucket given, or nil if not successful
function logistica.empty_bucket_into_network(network, bucketItemStack)
  local bucketName = bucketItemStack:get_name()
  local liquidName = logistica.reservoir_get_liquid_name_for_bucket(bucketName)

  local highestReservoirPos = nil
  local emptyReservoirPos = nil
  local emptyResrvoirMinCap = 999999
  local highestReservoirLvl = 0
  for hash, _ in pairs(network.reservoirs or {}) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    local liquidInReservoir = logistica.reservoir_get_liquid_name(pos)
    if liquidInReservoir == liquidName then
      local levels = logistica.reservoir_get_liquid_level(pos)
      if levels and levels[1] < levels[2] and levels[1] > highestReservoirLvl then
        highestReservoirPos = pos
        highestReservoirLvl = levels[1]
      end
    elseif liquidInReservoir == "" then
      local levels = logistica.reservoir_get_liquid_level(pos)
      if levels and levels[2] < emptyResrvoirMinCap then
        emptyResrvoirMinCap = levels[2]
        emptyReservoirPos = pos
      end
    end
  end

  if highestReservoirPos then
    return logistica.reservoir_use_item_on(highestReservoirPos, bucketItemStack)
  elseif emptyReservoirPos then
    return logistica.reservoir_use_item_on(emptyReservoirPos, bucketItemStack)
  else
    return nil
  end
end

-- tries to take a stack from the network locations
-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- note that it may be called multiple times as the itemstack is gathered from mass storage
-- `isAutomatedRequest` is optional, assumed to be false if not set
-- `useMetaData` is optional, assume false if not set - only applies to items with stack_max = 1
function logistica.take_stack_from_network(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun, depth)
  if not depth then depth = 0 end
  if depth > MAX_NETWORK_DEPTH_SEARCH then return false end
  if not network then return false end
  -- first check suppliers
  if logistica.take_stack_from_suppliers(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun, depth) then
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
function logistica.take_stack_from_suppliers(stackToTake, network, collectorFunc, isAutomatedRequest, useMetadata, dryRun, depth)
  local takeStack = ItemStack(stackToTake)
  local requestedAmount = stackToTake:get_count()
  local remaining = requestedAmount
  local stackName = stackToTake:get_name()
  local validSupplers = network.supplier_cache[stackName] or {}
  for hash, _ in pairs(validSupplers) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    local nodeName = minetest.get_node(pos).name
    if logistica.is_supplier(nodeName) or logistica.is_vaccuum_supplier(nodeName) then
      remaining = logistica.take_item_from_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun)
    elseif logistica.is_crafting_supplier(nodeName) then
      remaining = logistica.take_item_from_crafting_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun, depth)
    elseif logistica.is_bucket_filler(nodeName) then
      local result = logistica.take_item_from_bucket_filler(pos, takeStack, network, collectorFunc, isAutomatedRequest, dryRun, depth)
      remaining = result.remaining
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
    local storagePos = h2p(storageHash)
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
    local storagePos = h2p(storageHash)
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
  if inputStack:get_stack_max() == 1 and inv:room_for_item("main", inputStack) then
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
    local pos = h2p(hash)
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
    local pos = h2p(hash)
    local inv = get_meta(pos):get_inventory()
    local remainingStack = addFunc(pos, inv, workingStack, dryRun)
    if remainingStack:is_empty() then return 0 end -- we took all items
    workingStack = remainingStack
  end

  -- try to add to passive suppliers that accept this
  local suppliers = network.suppliers
  for hash, _ in pairs(suppliers) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    local leftover = logistica.put_item_in_supplier(pos, workingStack)
    if leftover:is_empty() then return 0 end
    workingStack = leftover
  end

  -- [Keep this last] delete the item if any trashcan accepts it
  local trashcans = network.trashcans or {}
  for hash, _ in pairs(trashcans) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    workingStack = logistica.trashcan_trash_item(pos, workingStack)
    if workingStack:is_empty() then return 0 end
  end

  return workingStack:get_count()
end

--[[ returns a natural-indexed list of tables - or empty table if there's no network or no liquids: 
  ```
  [1] = {
    name = "liquid_name", -- name of the liquid or "" if for empty reservoirs
    curr = 0 -- amount of liquid stored in network
    max = 32 -- combined max capacity of the reservoirs occupied by liquid
  },
  [2] = {...}
  ```
]]
function logistica.get_available_liquids_in_network(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return {} end
  local liquidInfo = {}
  for hash, _ in pairs(network.reservoirs or {}) do
    local resPos = h2p(hash)
    local liquidName = logistica.reservoir_get_liquid_name(resPos)
    local liquidLevels = logistica.reservoir_get_liquid_level(resPos)
    if liquidName and liquidLevels then
      local info = liquidInfo[liquidName] or {curr = 0, max = 0}
      info.curr = info.curr + (liquidLevels[1] or 0)
      info.max = info.max + (liquidLevels[2] or 0)
      liquidInfo[liquidName] = info
    end
  end
  return
    logistica.table_to_list_indexed(liquidInfo, function(lName, lInfo)
      return {
        name = lName,
        curr = lInfo.curr,
        max = lInfo.max,
      }
    end)
end

-- Returns a table for the given liquidName {curr = int, max = int}
function logistica.get_liquid_info_in_network(pos, liquidName)
  local network = logistica.get_network_or_nil(pos)
  if not network then return { curr = 0, max = 0 } end
  local available = 0
  local capacity = 0
  for hash, _ in pairs(network.reservoirs or {}) do
    local resPos = h2p(hash)
    local resLiquid = logistica.reservoir_get_liquid_name(resPos)
    local liquidLevels = logistica.reservoir_get_liquid_level(resPos)
    if resLiquid == liquidName and liquidLevels then
      available = available + (liquidLevels[1] or 0)
      capacity = capacity + (liquidLevels[2] or 0)
    end
  end
  return {
    curr = available,
    max = capacity,
  }
end

-- attempts to use, either fill or empty, the given bucket in/from liquid storage on
-- the network.<br>
-- `liquidName` is only used if the bucketItem is a type of empty bucket<br>
-- Otherwise a full bucket will attempt to fill any applicable reservoir on the network.
-- This function attempts to take from the lowest filled reservoir, and insert into the highest filled reservoir first.<br>
-- returns new itemstack to replace the old one, or `nil` if it wasn't changed
function logistica.use_bucket_for_liquid_in_network(pos, bucketItemStack, liquidName)
  local network = logistica.get_network_or_nil(pos)
  if not network then return nil end

  local bucketName = bucketItemStack:get_name()
  local isEmptyBucket = logistica.reservoir_is_empty_bucket(bucketName)
  local isFullBucket = logistica.reservoir_is_full_bucket(bucketName)
  if isEmptyBucket then
    if not liquidName then return nil end
    return logistica.fill_bucket_from_network(network, bucketItemStack, liquidName)
  elseif isFullBucket then
    return logistica.empty_bucket_into_network(network, bucketItemStack)
  end
end

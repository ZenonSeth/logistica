
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
function logistica.take_stack_from_network(stackToTake, network, collectorFunc, isAutomatedRequest)
  if stackToTake:get_stack_max() <= 1 then
    logistica.take_stack_from_item_storage(stackToTake, network, collectorFunc, isAutomatedRequest)
  else
    logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc, isAutomatedRequest)
  end
end

-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- returns true if item successfully found and given to collector, false otherwise
function logistica.take_stack_from_item_storage(filterStack, network, collectorFunc, isAutomatedRequest)
  for storageHash, _ in pairs(network.item_storage) do
    local storagePos = minetest.get_position_from_hash(storageHash)
    local storageInv = get_meta(storagePos):get_inventory()
    if storageInv:contains_item(ITEM_STORAGE_LIST_NAME, filterStack) then
      local leftover = collectorFunc(filterStack)
      if leftover == 0 then -- stack max is 1, so just take the whole itemstack out
        storageInv:remove_item(ITEM_STORAGE_LIST_NAME, filterStack)
        return true
      end -- otherwise, the insert failed for some reason..
    end
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
  local remainingDemand = stackToTake:get_count()
  local massLocations = network.storage_cache[stackToTake:get_name()]
  if massLocations == nil then return end
  for storageHash, _ in pairs(massLocations) do
    if stackToTake:get_count() == 0 then return end
    local storagePos = minetest.get_position_from_hash(storageHash)
    local meta = get_meta(storagePos)
    local storageInv = meta:get_inventory()
    local storageList = storageInv:get_list(MASS_STORAGE_LIST_NAME)
    -- we can't use the usual take/put methods because mass storage exceeds max stack
    for i = #storageList, 1, -1 do -- traverse backwards for taking items
      local storageStack = storageList[i]
      local slotReserve = logistica.get_mass_storage_reserve(meta, i)
      local available = storageStack:get_count()
      if isAutomatedRequest then available = math.max(0, available - slotReserve) end
      if stackToTakeName == storageStack:get_name() and available > 0 then
        local numTaken = math.min(available, remainingDemand)
        local takenStack = ItemStack(stackToTake)
        takenStack:set_count(numTaken)
        local leftover = collectorFunc(takenStack)
        numTaken = numTaken - leftover
        storageStack:set_count(storageStack:get_count() - numTaken)
        remainingDemand = remainingDemand - numTaken
        if remainingDemand <= 0 then
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

-- try to insert the item into the storage, returning how many items were taken
function logistica.try_to_add_item_to_storage(pos, inputStack, dryRun)
  local node = minetest.get_node(pos)
  if not logistica.is_mass_storage(node.name) and not logistica.is_item_storage(node.name) then return 0 end
  local isMassStorage = string.find(node.name, "mass")
  logistica.load_position(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  if isMassStorage then
    local remainingStack = logistica.insert_item_into_mass_storage(pos, inv, inputStack, dryRun)
    return inputStack:get_count() - remainingStack:get_count()
  else -- it's not mass storage, must be tool storage
    if inputStack:get_stack_max() == 1 and inv:room_for_item("main", inputStack) then
      -- tool storage only takes individual items
      inv:add_item("main", inputStack)
      return 1
    end
  end
  return 0
end

-- attempts to insert the given itemstack in the network, returns how many items were inserted
function logistica.insert_item_in_network(itemstack, networkId)
  local network = logistica.networks[networkId]
  if not itemstack or not network then return 0 end

  local workingStack = ItemStack(itemstack)
  -- check demanders first
  for hash, _ in pairs(network.demanders) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    local taken = 0 -- logistica.try_to_give_item_to_demander(pos, workingStack)
    local leftover = workingStack:get_count() - taken
    if leftover <= 0 then return itemstack:get_count() end -- we took all items
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
    local taken = logistica.try_to_add_item_to_storage(pos, workingStack)
    local leftover = workingStack:get_count() - taken
    if leftover <= 0 then return itemstack:get_count() end -- we took all items
    workingStack:set_count(leftover)
  end

  return itemstack:get_count() - workingStack:get_count()
end
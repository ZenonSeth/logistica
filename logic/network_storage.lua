
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
function logistica.take_stack_from_network(stackToTake, network, collectorFunc)
  if stackToTake:get_stack_max() <= 1 then
    logistica.take_stack_from_item_storage(stackToTake, network, collectorFunc)
  else
    logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc)
  end
end


-- calls the collectorFunc with the stack - collectorFunc needs to return how many were left-over<br>
-- `collectorFunc = function(stackToInsert)`<br>
-- returns true if item successfully found and given to collector, false otherwise
function logistica.take_stack_from_item_storage(filterStack, network, collectorFunc)
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
function logistica.take_stack_from_mass_storage(stackToTake, network, collectorFunc)
  local stackToTakeName = stackToTake:get_name()
  local remainingDemand = stackToTake:get_count()
  local massLocations = network.storage_cache[stackToTake:get_name()]
  if massLocations == nil then return end
  for storageHash, _ in pairs(massLocations) do
    if stackToTake:get_count() == 0 then return end
    local storagePos = minetest.get_position_from_hash(storageHash)
    local storageInv = get_meta(storagePos):get_inventory()
    local storageList = storageInv:get_list(MASS_STORAGE_LIST_NAME)
    -- we can't use the usual take/put methods because mass storage exceeds max stack
    for i = #storageList, 1, -1 do -- traverse backwards for taking items
      local storageStack = storageList[i]
      if stackToTakeName == storageStack:get_name() then
        local numTaken = math.min(storageStack:get_count(), remainingDemand)
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
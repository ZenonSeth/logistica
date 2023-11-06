local TIMER_DURATION_SHORT = 2.0
local TIMER_DURATION_LONG = 4.0
local META_DEMANDER_LISTNAME = "demtarlist"
local MASS_STORAGE_LIST_NAME = "storage"
local ITEM_STORAGE_LIST_NAME = "main"
local TARGET_NODES_REQUIRING_TIMER = {}
TARGET_NODES_REQUIRING_TIMER["default:furnace"] = true
TARGET_NODES_REQUIRING_TIMER["gravelsieve:auto_sieve3"] = true

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function get_valid_demander_and_target_inventory(demanderPos)
  local meta = get_meta(demanderPos)
  local targetList = meta:get_string(META_DEMANDER_LISTNAME)
  if not targetList then return end

  local targetPos = logistica.get_demander_target(demanderPos)
  if not targetPos then return end

  -- exclude logistica nodes from this
  if string.find(minetest.get_node(targetPos).name, "logistica:") then return end

  local targetInv = get_meta(targetPos):get_inventory()
  if not targetInv:get_list(targetList) then return end

  return {
    demanderInventory = meta:get_inventory(),
    targetInventory = targetInv,
    targetList = targetList,
    targetPos = targetPos,
  }
end

local function get_actual_demand_for_item(demandStack, storageInv, storageListName)
  local storageList = storageInv:get_list(storageListName)
  local remaining = demandStack:get_count()
    for i,v in ipairs(storageList) do
      local stored = storageList[i]
      if demandStack:get_name() == stored:get_name() then
        remaining = remaining - stored:get_count()
      end
      if remaining <= 0 then return ItemStack("") end
    end
    if remaining > 0 then
      local missingStack = ItemStack(demandStack)
      missingStack:set_count(remaining)
      return missingStack
    else
      return ItemStack("")
    end
end

local function try_to_fulfil_demanded_item_from_network_item_storage(pos, filterStack, network, inventories)
  for storageHash, _ in pairs(network.item_storage) do
    local storagePos = minetest.get_position_from_hash(storageHash)
    local storageInv = get_meta(storagePos):get_inventory()
    if storageInv:contains_item(ITEM_STORAGE_LIST_NAME, filterStack) then
      local leftover = 
        logistica.insert_itemstack_for_demander(pos, filterStack)
      if leftover == 0 then -- stack max is 1, so just take the whole itemstack out
        storageInv:remove_item(ITEM_STORAGE_LIST_NAME, filterStack)
        return true
      end -- otherwise, the insert failed for some reason..
    end
  end
  return false
end

local function try_to_fulfil_demanded_item_from_locations(pos, filterStack, locations, inventories)
  local filterStackName = filterStack:get_name()
  local remainingDemand = filterStack:get_count()
  for storageHash, _ in pairs(locations) do
    if filterStack:get_count() == 0 then return end
    local storagePos = minetest.get_position_from_hash(storageHash)
    local storageInv = get_meta(storagePos):get_inventory()
    local storageList = storageInv:get_list(MASS_STORAGE_LIST_NAME)
    -- we can't use the usual take/put methods because mass storage exceeds max stack
    for i = #storageList, 1, -1 do -- traverse backwards for taking items
      local storageStack = storageList[i]
      if filterStackName == storageStack:get_name() then
        local numTaken = math.min(storageStack:get_count(), remainingDemand)
        local takenStack = ItemStack(filterStack)
        takenStack:set_count(numTaken)
        local leftover =
          logistica.insert_itemstack_for_demander(pos, takenStack)
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

local function take_demanded_items_from_network(pos, network)
  local inventories = get_valid_demander_and_target_inventory(pos)
  if not inventories then return true end
  for _, filterStack in pairs(inventories.demanderInventory:get_list("filter")) do
    local demandStack = 
      get_actual_demand_for_item(filterStack, inventories.targetInventory, inventories.targetList)
    local filterStackName = demandStack:get_name()
    local isTool = demandStack:get_stack_max() <= 1
    if isTool then
      try_to_fulfil_demanded_item_from_network_item_storage(pos, demandStack, network, inventories)
    else -- check chaced mass-storage
      local locations = network.storage_cache[filterStackName]
      if not locations then return true end
      try_to_fulfil_demanded_item_from_locations(pos, demandStack, locations, inventories)
    end
  end

end

----------------------------------------------------------------
-- Storage operation functions
----------------------------------------------------------------

function logistica.start_demander_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_SHORT end
  logistica.start_node_timer(pos, duration)
  logistica.set_logistica_node_infotext(pos, true)
end

function logistica.on_demander_timer(pos, elapsed)
  local network = logistica.get_network_or_nil(pos)
  if not network or not logistica.is_machine_on(pos) then
    logistica.set_logistica_node_infotext(pos, false)
    return false
  end
  take_demanded_items_from_network(pos, network)
  return true
end

function logistica.set_demander_target_list(pos, listName)
  local meta = get_meta(pos)
  meta:set_string(META_DEMANDER_LISTNAME, listName)
end

function logistica.get_demander_target_list(pos)
  local meta = get_meta(pos)
  return meta:get_string(META_DEMANDER_LISTNAME)
end

-- function logistica.update_demander_demand(demanderPos)
--   local meta = get_meta(demanderPos)
--   local inventories = get_valid_demander_and_target_inventory(demanderPos)
--   if not inventories then return end
--   local demandList = logistica.get_demand_based_on_list(
--     inventories.demanderInventory, "filter",
--     inventories.targetInventory, inventories.targetList
--   )
-- end

-- returns a list of ItemStacks tha represent the current demand of this demander
function logistica.get_demander_demand(pos)
  local inv = get_meta(pos):get_inventory()
  local list = inv:get_list("filter")
  if not list then return {} end
  local ret = {}
  for k, v in list do
    ret[k] = ItemStack(v)
  end
  return ret
end

-- returns the demander's target position or nil if the demander isn't loaded
function logistica.get_demander_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local shift = logistica.get_rot_directions(node.param2).backward
  if not shift then return nil end
  return {x = (pos.x + shift.x),
          y = (pos.y + shift.y),
          z = (pos.z + shift.z)}
end

-- returns how many items remain from the itemstack after we attempt to insert it
-- `targetInventory` and `targetList` are optional (tied together), if not passed, it will be looked up
function logistica.insert_itemstack_for_demander(demanderPos, itemstack)
  if not itemstack or itemstack:is_empty() then return 0 end

  local inventories = get_valid_demander_and_target_inventory(demanderPos)
  if not inventories then return itemstack:get_count() end
  local targetInventory = inventories.targetInventory
  local targetList = inventories.targetList

  local leftover = targetInventory:add_item(targetList, itemstack)
  local targetNode = minetest.get_node(inventories.targetPos)
  if leftover:get_count() < itemstack:get_count() and TARGET_NODES_REQUIRING_TIMER[targetNode.name] then
    logistica.start_node_timer(inventories.targetPos, 1)
  end
  return leftover:get_count()
end

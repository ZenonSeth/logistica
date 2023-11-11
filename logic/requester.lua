local TIMER_DURATION_SHORT = 1.0
local TIMER_DURATION_LONG = 3.0
local META_REQUESTER_LISTNAME = "demtarlist"
local TARGET_NODES_REQUIRING_TIMER = {}
TARGET_NODES_REQUIRING_TIMER["default:furnace"] = true
TARGET_NODES_REQUIRING_TIMER["gravelsieve:auto_sieve0"] = true
TARGET_NODES_REQUIRING_TIMER["gravelsieve:auto_sieve1"] = true
TARGET_NODES_REQUIRING_TIMER["gravelsieve:auto_sieve2"] = true
TARGET_NODES_REQUIRING_TIMER["gravelsieve:auto_sieve3"] = true

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function get_max_rate_for_requester(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return 0 end
  local nodeDef = minetest.registered_nodes[node.name]
  if nodeDef and nodeDef.logistica and nodeDef.logistica.requester_transfer_rate then
    if nodeDef.logistica.requester_transfer_rate <= 0 then return 9999
    else return nodeDef.logistica.requester_transfer_rate end
  else
    return 0
  end
end

local function get_valid_requester_and_target_inventory(requesterPos)
  local meta = get_meta(requesterPos)
  local targetList = meta:get_string(META_REQUESTER_LISTNAME)
  if not targetList then return end

  local targetPos = logistica.get_requester_target(requesterPos)
  if not targetPos then return end

  -- exclude logistica nodes from this
  if string.find(minetest.get_node(targetPos).name, "logistica:") then return end

  local targetInv = get_meta(targetPos):get_inventory()
  if not targetInv:get_list(targetList) then return end

  return {
    requesterPos = requesterPos,
    requesterInventory = meta:get_inventory(),
    targetInventory = targetInv,
    targetList = targetList,
    targetPos = targetPos,
  }
end

local function get_target_missing_item_stack(requestStack, invs)
  local storageList = invs.targetInventory:get_list(invs.targetList)
  local remaining = requestStack:get_count()
    for i,_ in ipairs(storageList) do
      local stored = storageList[i]
      if requestStack:get_name() == stored:get_name() then
        remaining = remaining - stored:get_count()
      end
      if remaining <= 0 then return ItemStack("") end
    end
    if remaining > 0 then
      local missingStack = ItemStack(requestStack)
      missingStack:set_count(remaining)
      return missingStack
    else
      return ItemStack("")
    end
end

-- returns:
-- nil: nothing in inventory
-- ItemStack: the next requested item
local function get_next_requested_stack(pos, inventories)
  if not inventories then return nil end
  local nextSlot = logistica.get_next_filled_item_slot(get_meta(pos), "actual")
  if nextSlot <= 0 then return nil end
  return inventories.requesterInventory:get_list("actual")[nextSlot]
end

-- updates the inv list called 'actual' with the latest checked request
local function update_requester_actual_request(pos)
  local inventories = get_valid_requester_and_target_inventory(pos)
  if not inventories then return end
  local requesterInv = inventories.requesterInventory
  local actualRequestList = {}
  local requestStack = nil
  local nextSlot = logistica.get_next_filled_item_slot(get_meta(pos), "filter")
  local startingSlot = nextSlot
  repeat
    if nextSlot <= 0 then return nil end
    local filterStack = requesterInv:get_list("filter")[nextSlot]
    requestStack = get_target_missing_item_stack(filterStack, inventories)
    local demStackCount = requestStack:get_count()
    if demStackCount > 0 then
      local prev = actualRequestList[requestStack:get_name()] or 0
      if demStackCount > prev then
        actualRequestList[requestStack:get_name()] = demStackCount
      end
    end
    nextSlot = logistica.get_next_filled_item_slot(get_meta(pos), "filter")
  until( nextSlot == startingSlot ) -- until we get back to the starting slot
  local newActualRequestList = {}
  for itemname, count in pairs(actualRequestList) do
    table.insert(newActualRequestList, ItemStack(itemname.." "..count))
  end
  requesterInv:set_list("actual", newActualRequestList)
end

local function take_requested_items_from_network(pos, network)
  local requestStack = get_next_requested_stack(pos, get_valid_requester_and_target_inventory(pos))
  if requestStack == nil then return false end
  if requestStack == 0 then return true end -- had items but nothing in request
  -- limiting the number of items requested
  requestStack:set_count(math.min(get_max_rate_for_requester(pos), requestStack:get_count()))
  local collect = function(st) return logistica.insert_itemstack_for_requester(pos, st) end
  logistica.take_stack_from_network(requestStack, network, collect, true)
  return true
end

-- returns 0 if no request, or the count of requested items
local function get_filter_request_for(requesterInventory, itemStackName)
  local actualRequestList = requesterInventory:get_list("actual")
  if not actualRequestList then return 0 end
  for _, v in ipairs(actualRequestList) do
    if v:get_name() == itemStackName then
      return v:get_count()
    end
  end
  return 0
end

----------------------------------------------------------------
-- Storage operation functions
----------------------------------------------------------------

function logistica.start_requester_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_SHORT end
  logistica.start_node_timer(pos, duration)
end

function logistica.on_requester_timer(pos, elapsed)
  local network = logistica.get_network_or_nil(pos)
  if not network then return false end
  local targetPos = logistica.get_requester_target(pos)
  if not targetPos then return true end
  local targetNode = minetest.get_node_or_nil(targetPos)
  if not targetNode or logistica.is_machine(targetNode.name) then
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
    return false
  end
  logistica.set_node_tooltip_from_state(pos)
  update_requester_actual_request(pos)
  if take_requested_items_from_network(pos, network) then
    logistica.start_node_timer(pos, TIMER_DURATION_SHORT)
  else
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
  end
  return false
end

function logistica.set_requester_target_list(pos, listName)
  local meta = get_meta(pos)
  meta:set_string(META_REQUESTER_LISTNAME, listName)
end

function logistica.get_requester_target_list(pos)
  local meta = get_meta(pos)
  return meta:get_string(META_REQUESTER_LISTNAME)
end

-- function logistica.update_requester_request(requesterPos)
--   local meta = get_meta(requesterPos)
--   local inventories = get_valid_requester_and_target_inventory(requesterPos)
--   if not inventories then return end
--   local requestList = logistica.get_request_based_on_list(
--     inventories.requesterInventory, "filter",
--     inventories.targetInventory, inventories.targetList
--   )
-- end

-- returns a list of ItemStacks tha represent the current requests of this requester
function logistica.get_requester_request(pos)
  local inv = get_meta(pos):get_inventory()
  local list = inv:get_list("filter")
  if not list then return {} end
  local ret = {}
  for k, v in list do
    ret[k] = ItemStack(v)
  end
  return ret
end

-- returns the requester's target position or nil if the requester isn't loaded
function logistica.get_requester_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local target = vector.add(pos, logistica.get_rot_directions(node.param2).backward)
  if not minetest.get_node_or_nil(target) then return nil end
  return target
end

-- returns how many items remain from the itemstack after we attempt to insert it
-- `targetInventory` and `targetList` are optional (tied together), if not passed, it will be looked up
-- `limitByRequest` is optional - if set to true, no more items than needed will be inserted
function logistica.insert_itemstack_for_requester(requesterPos, itemstack, limitByRequest)
  if not itemstack or itemstack:is_empty() then return 0 end
  if not logistica.is_machine_on(requesterPos) then return itemstack:get_count() end

  local itemStackCount = itemstack:get_count()
  local itemStackName = itemstack:get_name()
  local inventories = get_valid_requester_and_target_inventory(requesterPos)
  if not inventories then return itemStackCount end
  local targetInventory = inventories.targetInventory
  local targetList = inventories.targetList

  local toInsertStack = ItemStack(itemstack)
  local request = itemStackCount
  if limitByRequest then
    request = get_filter_request_for(inventories.requesterInventory, itemStackName)
    toInsertStack:set_count(request)
    toInsertStack = get_target_missing_item_stack(toInsertStack, inventories)
  end
  if toInsertStack:is_empty() then return itemStackCount end

  local leftover = targetInventory:add_item(targetList, toInsertStack)
  local targetNode = minetest.get_node(inventories.targetPos)
  if leftover:get_count() < toInsertStack:get_count() and TARGET_NODES_REQUIRING_TIMER[targetNode.name] then
    logistica.start_node_timer(inventories.targetPos, 1)
  end
  return leftover:get_count() + itemStackCount - request
end

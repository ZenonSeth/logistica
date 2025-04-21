local TIMER_DURATION_SHORT = 1.0
local TIMER_DURATION_LONG = 3.0
local NUM_REQUEST_SLOTS = 4
local META_REQUESTER_LISTNAME = "demtarlist"
local META_REQUESTER_INF_REQ_ = "infreq"
local INF_REQUEST_COUNT = 999
local TARGET_NODES_REQUIRING_TIMER = {
  ["default:furnace"] = true,
  ["mcl_furnaces:furnace"] = true,
  ["mcl_furnaces:blast_furnace"] = true,
  ["mcl_furnaces:smoker"] = true,
  ["logistica:lava_furnace"] = true,
  ["logistica:bucket_emptier"] = true,
  ["gravelsieve:auto_sieve0"] = true,
  ["gravelsieve:auto_sieve1"] = true,
  ["gravelsieve:auto_sieve2"] = true,
  ["gravelsieve:auto_sieve3"] = true,
  ["techachge:ta2_grinder_pas"] = true,
  ["techachge:ta3_grinder_pas"] = true,
  ["techachge:ta4_grinder_pas"] = true,
  ["techachge:ta2_gravelsieve_pas"] = true,
  ["techachge:ta3_gravelsieve_pas"] = true,
  ["techachge:ta4_gravelsieve_pas"] = true,
  ["tubelub_addons1:grinder"] = true,
}

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function is_prohibited_logistica_machine(name)
  return logistica.is_machine(name) and not logistica.GROUPS.bucket_emptiers.is(name)
end

-- returns true/false if the infinite state for the given slot is enabled
local function get_requester_infinite_state(meta, i)
  return meta:get_int(META_REQUESTER_INF_REQ_..i) > 0
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

  -- exclude logistica machines from this (with exceptions)
  if is_prohibited_logistica_machine(minetest.get_node(targetPos).name) then return end

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
  local storageList = logistica.get_list(invs.targetInventory, invs.targetList)
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
  return logistica.get_list(inventories.requesterInventory, "actual")[nextSlot]
end

-- returns an index of which filter slot contains the named itemstack, or 0 if none do
local function find_filter_slot_for_item(pos, itemstack)
  local meta = get_meta(pos)
  local list = logistica.get_list(meta:get_inventory(), "filter")
  for i, v in ipairs(list) do
    if v and v:get_name() == itemstack:get_name() then return i end
  end
  return 0
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
    local filterStack = logistica.get_list(requesterInv, "filter")[nextSlot]
    if get_requester_infinite_state(get_meta(pos), nextSlot) then
      requestStack = filterStack
    else
      requestStack = get_target_missing_item_stack(filterStack, inventories)
    end
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
  local actualRequestList = logistica.get_list(requesterInventory, "actual")
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

function logistica.start_requester_timer(pos, duration, optAddRandomOffset)
  if duration == nil then duration = TIMER_DURATION_SHORT end
  logistica.start_node_timer(pos, duration, optAddRandomOffset)
end

function logistica.on_requester_timer(pos, elapsed)
  local network = logistica.get_network_or_nil(pos)
  if not network then return false end
  local targetPos = logistica.get_requester_target(pos)
  if not targetPos then return true end
  local targetNode = minetest.get_node_or_nil(targetPos)
  if not targetNode or is_prohibited_logistica_machine(targetNode.name) then
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
  local targetPos = logistica.get_requester_target(pos)
  if not targetPos then return end
  local targetNode = minetest.get_node(targetPos)
  if logistica.is_allowed_push_list(listName, targetNode.name) then
    local meta = get_meta(pos)
    meta:set_string(META_REQUESTER_LISTNAME, listName)
  end
end

function logistica.get_requester_target_list(pos)
  local meta = get_meta(pos)
  return meta:get_string(META_REQUESTER_LISTNAME)
end

function logistica.requester_on_infinite_request_toggle(pos, i, state)
  local meta = get_meta(pos)
  local value = 0 ; if state == true then value = 1 end
  meta:set_int(META_REQUESTER_INF_REQ_..i, value)
end

-- returns a naturally indexed list of true/false, specifying if 'infinite requesting' is enabled for a given slot
function logistica.get_requester_inf_state(pos)
  local vals = {}
  local meta = get_meta(pos)
  for i = 1, NUM_REQUEST_SLOTS do
    vals[i] = get_requester_infinite_state(meta, i)
  end
  return vals
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
  local list = logistica.get_list(inv, "filter")
  local ret = {}
  for k, v in ipairs(list) do
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
  local needed = itemStackCount
  if limitByRequest then
    needed = get_filter_request_for(inventories.requesterInventory, itemStackName)
    toInsertStack:set_count(math.min(needed, itemStackCount))
    if not get_requester_infinite_state(
        get_meta(requesterPos),
        find_filter_slot_for_item(requesterPos, toInsertStack)
      )
    then
      toInsertStack = get_target_missing_item_stack(toInsertStack, inventories)
    end
    toInsertStack:set_count(math.min(needed, toInsertStack:get_count()))
  end
  if toInsertStack:is_empty() then return itemStackCount end

  local leftover = targetInventory:add_item(targetList, toInsertStack)
  local targetNode = minetest.get_node(inventories.targetPos)
  if leftover:get_count() < toInsertStack:get_count() then -- and TARGET_NODES_REQUIRING_TIMER[targetNode.name] then
    logistica.start_node_timer(inventories.targetPos, 1)
  end
  return leftover:get_count() + itemStackCount - needed
end

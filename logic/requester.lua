local TIMER_DURATION_SHORT = 1.0
local TIMER_DURATION_LONG = 3.0
local NUM_REQUEST_SLOTS = 4
local META_REQUESTER_LISTNAME = "demtarlist"
local META_REQUESTER_AMOUNT_ = "reqamt"
local OLD_META_INF_PREFIX = "infreq"
local MAX_REQUEST_AMOUNT = 9999

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function is_prohibited_logistica_machine(name)
  if not logistica.is_machine(name) then return false end
  if logistica.GROUPS.bucket_emptiers.is(name) then return false end
  local def = minetest.registered_nodes[name]
  if def and def.logistica and def.logistica.automatable then return false end
  return true
end

local function get_requester_slot_amount(meta, i)
  return meta:get_int(META_REQUESTER_AMOUNT_..i)
end

local function get_max_rate_for_requester(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return 0 end
  local nodeDef = minetest.registered_nodes[node.name]
  if nodeDef and nodeDef.logistica and nodeDef.logistica.requester_transfer_rate then
    if nodeDef.logistica.requester_transfer_rate <= 0 then return MAX_REQUEST_AMOUNT
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

-- updates the inv list called 'actual' with the latest checked request
local function update_requester_actual_request(pos)
  local inventories = get_valid_requester_and_target_inventory(pos)
  if not inventories then return end
  local requesterInv = inventories.requesterInventory
  local meta = get_meta(pos)
  local newActualRequestList = {}
  for i = 1, NUM_REQUEST_SLOTS do
    local filterStack = requesterInv:get_stack("filter", i)
    local requestStack = ItemStack("")
    if not filterStack:is_empty() then
      local amount = get_requester_slot_amount(meta, i)
      if amount > 0 then
        local targetStack = ItemStack(filterStack)
        targetStack:set_count(amount)
        requestStack = get_target_missing_item_stack(targetStack, inventories)
      end
    end
    newActualRequestList[i] = requestStack
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

local function needs_migration(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  for i = 1, NUM_REQUEST_SLOTS do
    if inv:get_stack("filter", i):get_count() > 1 then return true end
  end
  -- also check for old inf meta
  local meta = minetest.get_meta(pos)
  for i = 1, NUM_REQUEST_SLOTS do
    if meta:get_int(OLD_META_INF_PREFIX..i) > 0 then return true end
  end
  return false
end

function logistica.on_requester_timer(pos, elapsed)
  local network = logistica.get_network_or_nil(pos)
  if not network then return false end
  if needs_migration(pos) then logistica.migrate_requester_slot_amounts(pos) end
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

-- returns a naturally indexed list of amounts (integers) for each slot
function logistica.get_requester_slot_amounts(pos)
  local vals = {}
  local meta = get_meta(pos)
  for i = 1, NUM_REQUEST_SLOTS do
    vals[i] = get_requester_slot_amount(meta, i)
  end
  return vals
end

-- amount is clamped to 0..MAX_REQUEST_AMOUNT; 0 means disabled for that slot
function logistica.set_requester_slot_amount(pos, i, amount)
  amount = math.max(0, math.min(MAX_REQUEST_AMOUNT, math.floor(tonumber(amount) or 0)))
  get_meta(pos):set_int(META_REQUESTER_AMOUNT_..i, amount)
end

-- migrates legacy data to the new per-slot amount fields.
-- 1. Old inf meta set -> amount 9999, clear inf meta.
-- 2. Filter slot count > 1 (old style) -> migrate count to amount field, reset to 1.
-- 3. Occupied slot with no amount set -> default to 1.
function logistica.migrate_requester_slot_amounts(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  for i = 1, NUM_REQUEST_SLOTS do
    local infKey = OLD_META_INF_PREFIX..i
    if meta:get_int(infKey) > 0 then
      meta:set_int(META_REQUESTER_AMOUNT_..i, MAX_REQUEST_AMOUNT)
      meta:set_int(infKey, 0)
    end
    local stack = inv:get_stack("filter", i)
    if not stack:is_empty() then
      local count = stack:get_count()
      local saved = meta:get_int(META_REQUESTER_AMOUNT_..i)
      if count > 1 then
        meta:set_int(META_REQUESTER_AMOUNT_..i, count)
        stack:set_count(1)
        inv:set_stack("filter", i, stack)
      elseif saved == 0 then
        meta:set_int(META_REQUESTER_AMOUNT_..i, 1)
      end
    end
  end
end

-- returns a list of ItemStacks that represent the current requests of this requester
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
    toInsertStack = get_target_missing_item_stack(toInsertStack, inventories)
    toInsertStack:set_count(math.min(needed, toInsertStack:get_count()))
  end
  if toInsertStack:is_empty() then return itemStackCount end

  local leftover = targetInventory:add_item(targetList, toInsertStack)
  if leftover:get_count() < toInsertStack:get_count() then
    logistica.start_node_timer(inventories.targetPos, 1)
  end
  return itemStackCount - (toInsertStack:get_count() - leftover:get_count())
end

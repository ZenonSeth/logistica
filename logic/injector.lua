local META_INJECTOR_LISTNAME = "tarinjlist"
local META_PUT_INTO_PREFIX = "putinto"
local TIMER_DURATION_SHORT = 1
local TIMER_DURATION_LONG = 3

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function get_injector_rate(nodeName)
  local def = minetest.registered_nodes[nodeName]
  if def and def.logistica and def.logistica.injector_transfer_rate then
    return def.logistica.injector_transfer_rate
  end
  return 0
end

local function get_put_into_state(meta, index)
  return meta:get_int(META_PUT_INTO_PREFIX..index) == 0 --check if == 0 because by default we assume all are on
end

local function get_next_injector_filtered_slot(targetMeta, targetList, targetInv, injInv)
  local tmpSlot = logistica.get_next_filled_item_slot(targetMeta, targetList)
  if injInv:is_empty("filter") then return tmpSlot end
  if tmpSlot == 0 then return 0 end
  local startSlot = tmpSlot
  while true do
    local itemCopy = ItemStack(targetInv:get_stack(targetList, tmpSlot)) ; itemCopy:set_count(1)
    if injInv:contains_item("filter", itemCopy) then
      return tmpSlot
    end
    tmpSlot = logistica.get_next_filled_item_slot(targetMeta, targetList)
    if tmpSlot == startSlot then return 0 end
  end
end

-- public functions 

-- returns nil if the injector or its target node isnt loaded
function logistica.get_injector_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local target = vector.add(pos, logistica.get_rot_directions(node.param2).backward)
  if not minetest.get_node_or_nil(target) then return nil end
  return target
end

function logistica.get_injector_target_list(pos)
  local meta = get_meta(pos)
  return meta:get_string(META_INJECTOR_LISTNAME)
end

function logistica.set_injector_target_list(pos, listName)
  local targetPos = logistica.get_injector_target(pos)
  if not targetPos then return end
  local targetNode = minetest.get_node(targetPos)
  if logistica.is_allowed_pull_list(listName, targetNode.name) then
    local meta = get_meta(pos)
    meta:set_string(META_INJECTOR_LISTNAME, listName)
  end
end

function logistica.start_injector_timer(pos, optAddRandomOffset)
  logistica.start_node_timer(pos, TIMER_DURATION_SHORT, optAddRandomOffset)
end

function logistica.on_injector_timer(pos, elapsed)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end

  logistica.set_node_tooltip_from_state(pos)
  local node = minetest.get_node_or_nil(pos)
  local meta = minetest.get_meta(pos)
  if not node then
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
    return false
  end
  local targetList = logistica.get_injector_target_list(pos)
  local targetPos = logistica.get_injector_target(pos)
  if targetPos == nil or logistica.is_machine(minetest.get_node(targetPos).name) then
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
    return false
  end
  local targetMeta = minetest.get_meta(targetPos)
  local targetInv = targetMeta:get_inventory()
  local injInv = meta:get_inventory()
  local targetSlot = get_next_injector_filtered_slot(targetMeta, targetList, targetInv, injInv)

  local maxStack = get_injector_rate(node.name)
  if targetSlot <= 0 or maxStack <= 0 then
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
    return false
  end
  local copyStack = targetInv:get_stack(targetList, targetSlot)
  local targetStackSize = copyStack:get_count()
  local numToTake = math.min(targetStackSize, maxStack)
  copyStack:set_count(numToTake)
  local numRemaining = logistica.insert_item_in_network(
      copyStack,
      networkId,
      false,
      not get_put_into_state(meta, 1),
      not get_put_into_state(meta, 2),
      not get_put_into_state(meta, 3),
      not get_put_into_state(meta, 4)
    )
  numRemaining = targetStackSize - numToTake + numRemaining
  copyStack:set_count(numRemaining)
  targetInv:set_stack(targetList, targetSlot, copyStack)

  logistica.start_node_timer(pos, TIMER_DURATION_SHORT)
  return false
end

-- returns true/false
function logistica.injector_get_put_into_state(pos, index)
  return get_put_into_state(get_meta(pos), index)
end

-- state must be "true"/"false" as a string
function logistica.injector_set_put_into_state(pos, index, state)
  local value = 1 ; if state == "true" then value = 0 end
  return get_meta(pos):set_int(META_PUT_INTO_PREFIX..index, value)
end

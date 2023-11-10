local META_INJECTOR_LISTNAME = "tarinjlist"
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
  local meta = get_meta(pos)
  meta:set_string(META_INJECTOR_LISTNAME, listName)
end

function logistica.start_injector_timer(pos)
  logistica.start_node_timer(pos, TIMER_DURATION_SHORT)
end

function logistica.on_injector_timer(pos, elapsed)
  if not logistica.is_machine_on(pos) then return false end
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
  local numRemaining = logistica.insert_item_in_network(copyStack, networkId)
  numRemaining = targetStackSize - numToTake + numRemaining
  copyStack:set_count(numRemaining)
  targetInv:set_stack(targetList, targetSlot, copyStack)

  logistica.start_node_timer(pos, TIMER_DURATION_SHORT)
  return false
end

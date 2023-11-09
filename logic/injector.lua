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

-- public functions 

function logistica.get_injector_target(pos)
  local node = minetest.get_node(pos)
  if not node then return pos end
  return vector.add(pos, logistica.get_rot_directions(node.param2).backward)
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
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    logistica.set_node_on_off_state(pos, false)
    return false
  end

  local node = minetest.get_node_or_nil(pos)
  local meta = minetest.get_meta(pos)
  if not node then
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
    return false
  end
  local targetList = logistica.get_injector_target_list(pos)
  local targetPos = logistica.get_injector_target(pos)
  local targetMeta = minetest.get_meta(targetPos)
  local targetSlot = logistica.get_next_filled_item_slot(targetMeta, targetList)
  local maxStack = get_injector_rate(node.name)
  if targetSlot <= 0 or maxStack <= 0 then
    logistica.start_node_timer(pos, TIMER_DURATION_LONG)
    return false
  end

  local inv = targetMeta:get_inventory()
  local copyStack = inv:get_stack(targetList, targetSlot)
  local copyStackSize = copyStack:get_count()
  local numRemaining = logistica.insert_item_in_network(copyStack, networkId)
  minetest.chat_send_all("attempted to insert: "..copyStackSize..", remain: "..numRemaining)
  copyStack:set_count(numRemaining)
  inv:set_stack(targetList, targetSlot, copyStack)

  logistica.start_node_timer(pos, TIMER_DURATION_SHORT)
  return false
end

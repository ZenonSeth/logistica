
local NUM_SLOTS = 4
local POLL_INTERVAL = 1.0

local function get_target_pos(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  return vector.add(pos, logistica.get_rot_directions(node.param2).backward)
end

local function get_readable_item_count(targetPos, itemName, listName)
  local node = minetest.get_node_or_nil(targetPos)
  if not node then return 0 end
  if logistica.is_machine(node.name) then return 0 end
  logistica.load_position(targetPos)
  local inv = minetest.get_meta(targetPos):get_inventory()
  if not inv then return 0 end
  local list = inv:get_list(listName)
  if not list then return 0 end
  local total = 0
  for _, stack in ipairs(list) do
    if stack:get_name() == itemName then total = total + stack:get_count() end
  end
  return total
end

-- Target list meta accessors

function logistica.ext_reader_get_target_list(pos)
  return minetest.get_meta(pos):get_string("target_list")
end

function logistica.ext_reader_set_target_list(pos, listName)
  minetest.get_meta(pos):set_string("target_list", listName or "")
end

function logistica.ext_reader_get_target_pos(pos)
  return get_target_pos(pos)
end

-- Per-slot meta accessors

function logistica.ext_reader_get_signal_name(pos, i)
  local v = minetest.get_meta(pos):get_string("signal_name_"..i)
  return (v and v ~= "") and v or ""
end

function logistica.ext_reader_get_threshold(pos, i)
  local v = minetest.get_meta(pos):get_int("threshold_"..i)
  return (v > 0) and v or 1
end

function logistica.ext_reader_get_comparison(pos, i)
  local v = minetest.get_meta(pos):get_string("comparison_"..i)
  return (v == ">=" or v == "<=") and v or ">="
end

function logistica.ext_reader_get_item(pos, i)
  local stack = minetest.get_meta(pos):get_inventory():get_stack("filter", i)
  return stack:get_name()
end

local function target_desc(targetPos)
  if not targetPos then return "nothing" end
  local node = minetest.get_node_or_nil(targetPos)
  if not node or node.name == "air" or node.name == "ignore" then return "nothing" end
  local def = minetest.registered_nodes[node.name]
  local desc = (def and def.short_description ~= "" and def.short_description)
    or (def and def.description ~= "" and def.description)
    or node.name
  if type(desc) ~= "string" then desc = node.name end
  return desc
end

function logistica.ext_reader_update_infotext(pos)
  local targetPos = get_target_pos(pos)
  local targetStr = target_desc(targetPos)
  local runStr = logistica.is_machine_on(pos) and "Running" or "Paused"
  minetest.get_meta(pos):set_string("infotext",
    "Ext. Content Reader -> " .. targetStr .. "\n" .. runStr)
end

local function do_evaluate(pos)
  local targetPos  = get_target_pos(pos)
  local targetList = logistica.ext_reader_get_target_list(pos)
  local networkId  = logistica.get_network_id_or_nil(pos)
  for i = 1, NUM_SLOTS do
    local itemName = logistica.ext_reader_get_item(pos, i)
    local sigName  = logistica.ext_reader_get_signal_name(pos, i)
    if itemName == "" or sigName == "" or targetList == "" then
      if networkId and sigName ~= "" then
        logistica.signal_send(pos, sigName, false)
      end
    else
      local count      = targetPos and get_readable_item_count(targetPos, itemName, targetList) or 0
      local threshold  = logistica.ext_reader_get_threshold(pos, i)
      local comparison = logistica.ext_reader_get_comparison(pos, i)
      local conditionMet = (comparison == ">=") and (count >= threshold)
                        or (comparison == "<=") and (count <= threshold)
      logistica.signal_send(pos, sigName, conditionMet)
    end
  end
  logistica.ext_reader_update_infotext(pos)
end

function logistica.ext_reader_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  do_evaluate(pos)
  return true
end

function logistica.ext_reader_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    minetest.get_node_timer(pos):start(POLL_INTERVAL + math.random(1,4)*0.1)
  end
  logistica.ext_reader_update_infotext(pos)
end

function logistica.ext_reader_on_disconnect(pos, networkId)
  minetest.get_node_timer(pos):stop()
  logistica.signal_remove_sender(pos, networkId)
  logistica.ext_reader_update_infotext(pos)
end

function logistica.ext_reader_on_power(pos, isOn)
  if isOn then
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then
      minetest.get_node_timer(pos):start(POLL_INTERVAL + math.random(1,4)*0.1)
    end
  else
    minetest.get_node_timer(pos):stop()
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then logistica.signal_remove_sender(pos, networkId) end
  end
  logistica.ext_reader_update_infotext(pos)
end

function logistica.ext_reader_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then logistica.signal_remove_sender(pos, networkId) end
  if logistica.is_machine_on(pos) then
    do_evaluate(pos)
  else
    logistica.ext_reader_update_infotext(pos)
  end
end

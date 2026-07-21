
local NUM_SIGNAL_ROWS = 4
local NUM_ROWS = NUM_SIGNAL_ROWS + 1 -- last row is the "no signal" default
local DEFAULT_ROW = NUM_ROWS
local NUM_SLOTS = 8
local META_SIGNAL_PREFIX = "prog_signal"
local META_AMOUNT_PREFIX = "prog_amt"
local META_LAST_ERROR = "last_error"
local ROW_LIST_PREFIX = "row"
local MAX_REQUEST_AMOUNT = 9999

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

function logistica.requester_programmer_row_list_name(row)
  return ROW_LIST_PREFIX..row
end

function logistica.requester_programmer_get_signal_name(pos, row)
  if row < 1 or row > NUM_SIGNAL_ROWS then return "" end
  return get_meta(pos):get_string(META_SIGNAL_PREFIX..row)
end

function logistica.requester_programmer_set_signal_name(pos, row, name)
  if row < 1 or row > NUM_SIGNAL_ROWS then return end
  get_meta(pos):set_string(META_SIGNAL_PREFIX..row, logistica.sanitize_signal_name(name))
end

function logistica.requester_programmer_get_amount(pos, row, slot)
  return get_meta(pos):get_int(META_AMOUNT_PREFIX..row.."_"..slot)
end

function logistica.requester_programmer_set_amount(pos, row, slot, amount)
  amount = math.max(0, math.min(MAX_REQUEST_AMOUNT, math.floor(tonumber(amount) or 0)))
  get_meta(pos):set_int(META_AMOUNT_PREFIX..row.."_"..slot, amount)
end

-- returns the position this programmer targets (the node behind it)
function logistica.requester_programmer_get_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local target = vector.add(pos, logistica.get_rot_directions(node.param2).backward)
  if not minetest.get_node_or_nil(target) then return nil end
  return target
end

local function is_valid_target(targetPos)
  if not targetPos then return false end
  local node = minetest.get_node_or_nil(targetPos)
  if not node then return false end
  return logistica.GROUPS.requesters.is(node.name)
end

local function get_active_row(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then
    for row = 1, NUM_SIGNAL_ROWS do
      local sigName = logistica.requester_programmer_get_signal_name(pos, row)
      if sigName ~= "" and logistica.signal_get_state(networkId, sigName) then
        return row
      end
    end
  end
  return DEFAULT_ROW
end

function logistica.requester_programmer_update_infotext(pos)
  local lastError = get_meta(pos):get_string(META_LAST_ERROR)
  local stateStr
  if lastError == "no_target" then
    stateStr = "Error: not facing a Requester"
  else
    stateStr = "Active row: "..get_active_row(pos)
  end
  get_meta(pos):set_string("infotext", "Requester Programmer\n"..stateStr)
end

-- writes the currently-active row's items/amounts into the target Requester
function logistica.requester_programmer_apply(pos)
  local targetPos = logistica.requester_programmer_get_target(pos)
  local meta = get_meta(pos)
  if not is_valid_target(targetPos) then
    meta:set_string(META_LAST_ERROR, "no_target")
    logistica.requester_programmer_update_infotext(pos)
    return
  end
  meta:set_string(META_LAST_ERROR, "")

  local row = get_active_row(pos)
  local ownInv = meta:get_inventory()
  local listName = logistica.requester_programmer_row_list_name(row)
  for slot = 1, NUM_SLOTS do
    local stack = ownInv:get_stack(listName, slot)
    if not stack:is_empty() then
      local copyStack = ItemStack(stack:get_name())
      copyStack:set_count(1)
      logistica.set_requester_filter_slot(targetPos, slot, copyStack)
      logistica.set_requester_slot_amount(targetPos, slot, logistica.requester_programmer_get_amount(pos, row, slot))
    else
      logistica.set_requester_filter_slot(targetPos, slot, ItemStack(""))
      logistica.set_requester_slot_amount(targetPos, slot, 0)
    end
  end
  logistica.start_requester_timer(targetPos, 1)
  logistica.requester_programmer_update_infotext(pos)
end

function logistica.requester_programmer_on_signal_received(pos, sigName, _sigIsOn)
  for row = 1, NUM_SIGNAL_ROWS do
    if logistica.requester_programmer_get_signal_name(pos, row) == sigName then
      logistica.requester_programmer_apply(pos)
      return
    end
  end
end

function logistica.requester_programmer_on_connect(pos, _networkId)
  logistica.requester_programmer_apply(pos)
end

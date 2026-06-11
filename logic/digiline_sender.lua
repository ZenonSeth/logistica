
local NUM_SLOTS    = 8
local POLL_INTERVAL = 1.0

-- keyed by pos hash; stores last sent message string to avoid redundant sends
local last_sent = {}

local function pos_hash(pos)
  return minetest.hash_node_position(pos)
end

local function parse_signal_list(str)
  local list = {}
  for token in str:gmatch("[^%s,]+") do
    local s = logistica.sanitize_signal_name(token)
    if s and s ~= "" then
      list[#list + 1] = s
    end
  end
  return list
end

local function get_signal_names(pos)
  return minetest.get_meta(pos):get_string("signal_names")
end

local function get_channel(pos)
  return minetest.get_meta(pos):get_string("channel")
end

local function get_message_template(pos)
  return minetest.get_meta(pos):get_string("message")
end

-- Returns resolved message string and a warning string (empty if none).
local function resolve_message(pos, networkId)
  local template = get_message_template(pos)
  local signals  = parse_signal_list(get_signal_names(pos))
  local inv      = minetest.get_meta(pos):get_inventory()
  local network  = networkId and logistica.get_network_by_id_or_nil(networkId)

  local warnings = {}

  local result = template:gsub("%%([si])(%d+)", function(kind, nstr)
    local n = tonumber(nstr)
    if kind == "s" then
      if not n or n < 1 or n > #signals then
        warnings[#warnings + 1] = "%s" .. nstr .. " out of range"
        return "%s" .. nstr
      end
      local sigName = signals[n]
      local isOn = network and logistica.signal_get_state(networkId, sigName) or false
      return isOn and "On" or "Off"
    else -- kind == "i"
      if not n or n < 1 or n > NUM_SLOTS then
        warnings[#warnings + 1] = "%i" .. nstr .. " out of range"
        return "%i" .. nstr
      end
      local stack = inv:get_stack("filter", n)
      if stack:is_empty() then
        warnings[#warnings + 1] = "%i" .. nstr .. " slot is empty"
        return "n/a"
      end
      local count = network
        and logistica.count_items_in_network(stack:get_name(), network, false)
        or 0
      return tostring(count)
    end
  end)

  return result, table.concat(warnings, "; ")
end

-- Validates the template against current config and returns a warning string.
local function validate_template(pos)
  local template = get_message_template(pos)
  local signals  = parse_signal_list(get_signal_names(pos))
  local inv      = minetest.get_meta(pos):get_inventory()
  local warnings = {}

  for kind, nstr in template:gmatch("%%([si])(%d+)") do
    local n = tonumber(nstr)
    if kind == "s" then
      if not n or n < 1 or n > #signals then
        warnings[#warnings + 1] = "%s" .. nstr .. " needs signal " .. nstr .. " but only " .. #signals .. " configured"
      end
    else
      if not n or n < 1 or n > NUM_SLOTS then
        warnings[#warnings + 1] = "%i" .. nstr .. " is out of range (1-" .. NUM_SLOTS .. ")"
      elseif inv:get_stack("filter", n):is_empty() then
        warnings[#warnings + 1] = "%i" .. nstr .. " slot " .. nstr .. " is empty"
      end
    end
  end

  return table.concat(warnings, "; ")
end

function logistica.digiline_sender_update_infotext(pos)
  local isOn = logistica.is_machine_on(pos)
  local channel = get_channel(pos)
  local state = isOn and ("Sending on: " .. (channel ~= "" and channel or "(no channel)")) or "Paused"
  minetest.get_meta(pos):set_string("infotext", "Digiline Sender\n" .. state)
end

function logistica.digiline_sender_after_place(pos, placer)
  local meta = minetest.get_meta(pos)
  meta:get_inventory():set_size("filter", NUM_SLOTS)
  logistica.digiline_sender_update_infotext(pos)
  logistica.on_digiline_sender_change(pos)
  if placer and placer:is_player() then
    logistica.digiline_sender_on_rightclick(pos, nil, placer, nil, nil)
  end
end

function logistica.digiline_sender_after_dig(pos, oldNode, oldMeta, _)
  last_sent[pos_hash(pos)] = nil
  logistica.on_digiline_sender_change(pos, oldNode, oldMeta)
end

function logistica.digiline_sender_on_rightclick(pos, _, player, _, _)
  if not player or not player:is_player() then return end
  local playerName = player:get_player_name()
  if logistica.should_hide_from_player(pos, playerName) then return end
  logistica.digiline_sender_show_formspec(playerName, pos)
end

function logistica.digiline_sender_allow_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local inv_stack = inv:get_stack(listname, index)
  -- We always want exactly one "item" in the filter, only bother changing it if we actually need to.
  if inv_stack:get_name() ~= stack:get_name() then
    -- "imagine" taking at most one item from the stack.
    local single_item_stack = stack:peek_item(1)
    inv:set_stack(listname, index, single_item_stack)
  end

  -- I don't know why tools should be barred? TODO: ask
  -- if stack:get_stack_max() == 1 then return 0 end
  return 0
end

function logistica.digiline_sender_allow_inv_take(pos, listname, index, _stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  -- We want to clear the relevant item slot on attempts to take.
  local inv = minetest.get_meta(pos):get_inventory()
  inv:set_stack(listname, index, "")
  return 0
end

function logistica.digiline_sender_allow_inv_move(_, _, _, _, _, _, _)
  return 0
end

function logistica.digiline_sender_on_inv_change(pos, listname, _index, _stack, player)
  if listname ~= "filter" then return end
  local warn = validate_template(pos)
  minetest.get_meta(pos):set_string("warning", warn)
  logistica.digiline_sender_show_formspec(player:get_player_name(), pos)
end

local function try_parse_as_table(str)
  local s = str:match("^%s*(.-)%s*$")
  if s:sub(1, 6) ~= "return" then s = "return " .. s end
  return minetest.deserialize(s)
end

local function do_send(pos, networkId)
  if not minetest.get_modpath("digilines") then return end
  local channel = get_channel(pos)
  if not channel or channel == "" then return end
  local msg, _ = resolve_message(pos, networkId)
  local hash = pos_hash(pos)
  if last_sent[hash] == msg then return end

  local payload
  if minetest.get_meta(pos):get_string("parse_as_table") == "1" then
    local t = try_parse_as_table(msg)
    if t == nil then
      minetest.get_meta(pos):set_string("warning", "Table parse failed - check message syntax")
      return
    end
    payload = t
  else
    payload = msg
  end

  last_sent[hash] = msg
  digilines.receptor_send(pos, digilines.rules.default, channel, payload)
end

function logistica.digiline_sender_timer(pos)
  if not logistica.is_machine_on(pos) then return false end
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  do_send(pos, networkId)
  minetest.get_node_timer(pos):start(POLL_INTERVAL)
  return false
end

function logistica.digiline_sender_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    local jitter = math.random(0, 9) * 0.1
    minetest.get_node_timer(pos):start(POLL_INTERVAL + jitter)
  end
  logistica.digiline_sender_update_infotext(pos)
end

function logistica.digiline_sender_on_disconnect(pos, _networkId)
  minetest.get_node_timer(pos):stop()
  logistica.digiline_sender_update_infotext(pos)
end

function logistica.digiline_sender_on_power(pos, isOn)
  if isOn then
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then
      minetest.get_node_timer(pos):start(POLL_INTERVAL)
    end
  else
    minetest.get_node_timer(pos):stop()
  end
  logistica.digiline_sender_update_infotext(pos)
end

function logistica.digiline_sender_set_parse_as_table(pos, asTable)
  minetest.get_meta(pos):set_string("parse_as_table", asTable and "1" or "0")
  last_sent[pos_hash(pos)] = nil
end

-- Called from formspec save to re-validate and store warning.
function logistica.digiline_sender_on_save(pos, channel, signal_names, message)
  local meta = minetest.get_meta(pos)
  meta:set_string("channel", channel)
  meta:set_string("signal_names", signal_names)
  meta:set_string("message", message)
  local warn = validate_template(pos)
  meta:set_string("warning", warn)
  -- reset last sent so next tick re-sends with new config
  last_sent[pos_hash(pos)] = nil
  logistica.digiline_sender_update_infotext(pos)
end

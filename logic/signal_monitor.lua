
local p2h = minetest.hash_node_position
local h2p = minetest.get_position_from_hash

-- in-memory state keyed by position hash; cleared on dig
-- { live = {[name]=bool}, snap_base = {[name]=bool}|nil, snap_changed = {[name]=true}|nil }
local node_state = {}

local function get_or_init(hash)
  if not node_state[hash] then
    node_state[hash] = { live = {}, network_id = nil, live_update = false, snap_base = nil, snap_changed = nil }
  end
  return node_state[hash]
end

-- only adds currently ON signals; never removes existing entries
local function seed_live_from_network(pos, state)
  local network = logistica.get_network_or_nil(pos)
  if not network then return end
  for name, senders in pairs(network.signals) do
    if next(senders) then
      state.live[name] = true
    end
  end
end

function logistica.signal_monitor_on_connect(pos, networkId)
  local hash = p2h(pos)
  local state = get_or_init(hash)
  if state.network_id ~= nil and state.network_id ~= networkId then
    state.live = {}
    state.snap_base = nil
    state.snap_changed = nil
  end
  state.network_id = networkId
  seed_live_from_network(pos, state)
  minetest.get_meta(pos):set_string("infotext", "Signal Monitor: connected")
end

function logistica.signal_monitor_on_disconnect(pos, _networkId)
  minetest.get_meta(pos):set_string("infotext", "Signal Monitor: disconnected")
end

function logistica.signal_monitor_on_signal_received(pos, name, isOn)
  local hash = p2h(pos)
  local state = node_state[hash]
  if not state then return end
  state.live[name] = isOn
  if state.snap_base then
    local baseOn = (state.snap_base[name] == true)
    if isOn ~= baseOn then
      state.snap_changed[name] = true
    end
  end
  if state.live_update then
    logistica.signal_monitor_live_refresh(pos)
  end
end

function logistica.signal_monitor_set_live_update(pos, enabled)
  local state = get_or_init(p2h(pos))
  state.live_update = enabled
end

function logistica.signal_monitor_get_live_update(pos)
  local state = node_state[p2h(pos)]
  return state ~= nil and state.live_update == true
end

function logistica.signal_monitor_cleanup(pos)
  node_state[p2h(pos)] = nil
end

-- Clears all seen signals and reseeds from current network state (Reset button)
function logistica.signal_monitor_reset_live(pos)
  local hash = p2h(pos)
  local state = get_or_init(hash)
  state.live = {}
  seed_live_from_network(pos, state)
end

function logistica.signal_monitor_has_snapshot(pos)
  local state = node_state[p2h(pos)]
  return state ~= nil and state.snap_base ~= nil
end

function logistica.signal_monitor_take_snapshot(pos)
  local hash = p2h(pos)
  local state = get_or_init(hash)
  local network = logistica.get_network_or_nil(pos)
  local base = {}
  if network then
    for name, senders in pairs(network.signals) do
      if next(senders) then
        base[name] = true
      end
    end
  end
  state.snap_base = base
  state.snap_changed = {}
end

function logistica.signal_monitor_reset_snapshot(pos)
  local hash = p2h(pos)
  local state = node_state[hash]
  if not state then return end
  state.snap_base = nil
  state.snap_changed = nil
end

-- Returns sorted list of {name, isOn} from live state, optionally filtered
function logistica.signal_monitor_get_live_signals(pos, filter)
  local state = node_state[p2h(pos)]
  if not state then return {} end
  local result = {}
  local lfilter = filter and filter:lower() or ""
  for name, isOn in pairs(state.live) do
    if lfilter == "" or name:lower():find(lfilter, 1, true) then
      result[#result + 1] = { name = name, isOn = isOn }
    end
  end
  table.sort(result, function(a, b) return a.name < b.name end)
  return result
end

-- Returns sorted list of {name, isOn} for signals that changed since snapshot
function logistica.signal_monitor_get_snapshot_changed(pos, filter)
  local state = node_state[p2h(pos)]
  if not state or not state.snap_changed then return {} end
  local network = logistica.get_network_or_nil(pos)
  local result = {}
  local lfilter = filter and filter:lower() or ""
  for name, _ in pairs(state.snap_changed) do
    if lfilter == "" or name:lower():find(lfilter, 1, true) then
      local isOn = false
      if network and network.signals[name] and next(network.signals[name]) then
        isOn = true
      end
      result[#result + 1] = { name = name, isOn = isOn }
    end
  end
  table.sort(result, function(a, b) return a.name < b.name end)
  return result
end

-- Returns list of {desc, pos} for active senders of the named signal
function logistica.signal_monitor_get_senders(pos, signalName)
  if not signalName or signalName == "" then return {} end
  local network = logistica.get_network_or_nil(pos)
  if not network then return {} end
  local senders = network.signals[signalName]
  if not senders or not next(senders) then return {} end
  local result = {}
  for hash, _ in pairs(senders) do
    local senderPos = h2p(hash)
    local nodeName = minetest.get_node(senderPos).name
    local def = minetest.registered_nodes[nodeName]
    local desc = nodeName
    if def then
      local d = def.short_description
      if not d or d == "" then d = def.description end
      if type(d) == "string" and d ~= "" then desc = d end
    end
    result[#result + 1] = { desc = desc, pos = senderPos }
  end
  table.sort(result, function(a, b)
    return minetest.pos_to_string(a.pos) < minetest.pos_to_string(b.pos)
  end)
  return result
end

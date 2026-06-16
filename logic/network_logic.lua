local networks = {}
local HARD_NETWORK_NODE_LIMIT = logistica.settings.network_node_limit -- default is 4000, unless changed by server
local STATUS_OK = 0
local CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK = -1
local CREATE_NETWORK_STATUS_TOO_MANY_NODES = -2
local ON_SUFFIX = "_on"
local DISABLED_SUFFIX = "_disabled"

local META_STORED_NETWORK = "logisticanet"
local CACHED_NETWORK_ID_ALREADY_TRIED = "-"

local p2h = minetest.hash_node_position
local h2p = minetest.get_position_from_hash

local adjacent = {
  vector.new( 1,  0,  0), vector.new( 0,  1,  0), vector.new( 0,  0,  1),
  vector.new(-1,  0,  0), vector.new( 0, -1,  0), vector.new( 0,  0, -1),
}

local function has_machine(network, id)
  if not network then return false end
  for networkGroup, v in pairs(logistica.network_group_get_all()) do
    if network[networkGroup][id] ~= nil then return true end
  end
  return false
end

local function network_contains_hash(network, hash)
  if hash == network.controller then return true end
  if network[logistica.NETWORK_GROUPS.cables][hash] then return true end
  if has_machine(network, hash) then return true end
  return false
end

-- we need this because default tostring(number) function returns scientific representation which loses accuracy
local str = function(anInt) return string.format("%.0f", anInt) end

local function set_cache_network_id(metaForPos, networkId)
  local formattedID = networkId
  if formattedID ~= CACHED_NETWORK_ID_ALREADY_TRIED then
    formattedID = str(formattedID)
  end
  metaForPos:set_string(META_STORED_NETWORK, formattedID)
end

local function get_unchecked_cached_network_id(metaForPos)
  -- if metaForPos comes from after_dig_node, then it's just a table, not a MetaDataRef
  if type(metaForPos) == "table" then
    if metaForPos.fields and metaForPos.fields[META_STORED_NETWORK] then
      return metaForPos.fields[META_STORED_NETWORK]
    end
  else
    return (metaForPos.get_string and metaForPos:get_string(META_STORED_NETWORK)) or ""
  end
end

-- returns a table { network = network/nil, alreadyCacheTried = true/false }
local function get_cached_network_or_nil(posHash, metaForPos)
  local cachedId = get_unchecked_cached_network_id(metaForPos)
  if not cachedId then return { network = nil, alreadyCacheTried = false } end
  if cachedId == CACHED_NETWORK_ID_ALREADY_TRIED then
    return { network = nil, alreadyCacheTried = true }
  end
  local network = networks[tonumber(cachedId)]
  if network and network_contains_hash(network, posHash) then
    return { network = network, alreadyCacheTried = false }
  end
  return { network = nil, alreadyCacheTried = false }
end

function logistica.get_network_by_id_or_nil(networkId)
  return networks[networkId]
end

function logistica.get_network_or_nil(pos, optMeta, withoutModifying)
  local nodeName = minetest.get_node(pos).name
  if logistica.get_network_group_for_node_name(nodeName) == nil
      and not logistica.GROUPS.controllers.is(nodeName) -- controllers don't have a network group, they ARE the network
  then return nil end
  local hash = p2h(pos)
  local meta = minetest.get_meta(pos) -- optMeta or minetest.get_meta(pos)
  local networkLookup = get_cached_network_or_nil(hash, optMeta or meta)
  local possibleNetwork = networkLookup.network
  if possibleNetwork then
    return possibleNetwork
  end
  if not networkLookup.alreadyCacheTried then
    -- otherwise, if we haven't tried before, serach all networks, save it if we find one
    for netHash, network in pairs(networks) do
      if network_contains_hash(network, hash) then
        set_cache_network_id(meta, netHash)
        return network
      end
    end
    if not withoutModifying then
      -- we tried the cache, and then looking up all the networks - it didn't work.
      -- so mark this as already tried, so we don't perform more full-network searches for this node
      -- until something changes (e.g. something connects it to network and sets the cache)
      set_cache_network_id(meta, CACHED_NETWORK_ID_ALREADY_TRIED)
    end
  end
  return nil
end

function logistica.get_network_name_or_nil(pos)
  local network = logistica.get_network_or_nil(pos, nil, true)
  if not network then return nil else return network.name end
end

function logistica.rename_network(networkId, newName)
  local network = networks[networkId]
  if not network then return false end
  if not newName or type(newName) ~= "string" or newName == "" then
    newName = logistica.get_rand_string_for(h2p(network.controller))
  end
  network.name = newName
  --
  for posHash, _ in pairs(network.wireless_transmitters) do
    local trPos = h2p(posHash)
    logistica.wifi_transmitter_set_infotext(trPos, network.name)
  end
  return true
end

function logistica.get_network_id_or_nil(pos)
  local network = logistica.get_network_or_nil(pos, nil, true)
  if not network then return nil else return network.controller end
end

-- Set by rescan_network to suppress on_connect_to_network for nodes that were
-- already on the network before the rescan. Their state has not changed.
local rescan_skip_notify = nil

local function notify_connected(pos, nodeName, networkId)
  -- set the cached network ID first
  set_cache_network_id(minetest.get_meta(pos), networkId)
  if rescan_skip_notify and rescan_skip_notify[p2h(pos)] then return end
  local def = minetest.registered_nodes[nodeName]
  if def and def.logistica and def.logistica.on_connect_to_network then
    def.logistica.on_connect_to_network(pos, networkId)
  end
end

local function notify_disconnected(pos, networkId, oldNodeName)
  local nodeName = oldNodeName or minetest.get_node(pos).name
  local def = minetest.registered_nodes[nodeName]
  if def and def.logistica and def.logistica.on_disconnect_from_network then
    def.logistica.on_disconnect_from_network(pos, networkId)
  end
end

local function notify_signal_receivers(network, name, isOn)
  for rcHash, _ in pairs(network.signal_receivers) do
    local rcPos = h2p(rcHash)
    local nodeName = minetest.get_node(rcPos).name
    local rcDef = minetest.registered_nodes[nodeName]
    if rcDef and rcDef.logistica and rcDef.logistica.on_signal_received then
      if logistica.GROUPS.signal_gates.is(nodeName) then
        local ctx = network._propagation
        if ctx then
          -- deduplicate: only enqueue if this gate+signal pair is not already queued
          if not ctx.queued[rcHash] then ctx.queued[rcHash] = {} end
          if not ctx.queued[rcHash][name] then
            ctx.queued[rcHash][name] = true
            table.insert(ctx.pending, {hash = rcHash, name = name, isOn = isOn})
          end
        end
      else
        rcDef.logistica.on_signal_received(rcPos, name, isOn)
      end
    end
  end
end

-- Runs the BFS gate propagation loop for the given context.
-- Gates should return true from on_signal_received if they actually processed the signal,
-- false/nil if they ignored it (e.g. signal name did not match their input).
-- Cycle detection is per gate+signal-name pair. Entries are deduplicated at enqueue
-- so the same gate+signal can only appear once in pending at a time.
local function run_gate_propagation(network, ctx)
  local head = 1
  while head <= #ctx.pending do
    local entry = ctx.pending[head]
    head = head + 1
    local gatePos = h2p(entry.hash)
    -- clear queued flag so the gate can be re-enqueued if it receives a different signal later
    if ctx.queued[entry.hash] then ctx.queued[entry.hash][entry.name] = nil end
    if not ctx.visited[entry.hash] then ctx.visited[entry.hash] = {} end
    if ctx.visited[entry.hash][entry.name] then
      minetest.get_meta(gatePos):set_string("infotext", "ERROR: Signal loop detected")
      minetest.log("warning", "[logistica] signal loop at " .. minetest.pos_to_string(gatePos))
    else
      local gateDef = minetest.registered_nodes[minetest.get_node(gatePos).name]
      if gateDef and gateDef.logistica and gateDef.logistica.on_signal_received then
        local processed = gateDef.logistica.on_signal_received(gatePos, entry.name, entry.isOn)
        if processed then
          ctx.visited[entry.hash][entry.name] = true
        end
      end
    end
  end
end

-- Removes all signal contributions from hash and notifies receivers.
-- Assumes network._propagation is already set by the caller.
local function remove_sender_signals_bfs(network, hash)
  for name, senders in pairs(network.signals) do
    if senders[hash] then
      senders[hash] = nil
      local signalIsOn = not logistica.table_is_empty(senders)
      if not signalIsOn then
        network.signals[name] = nil
        notify_signal_receivers(network, name, false)
      end
      -- if signalIsOn: other senders keep it alive, state unchanged, no notify needed
    end
  end
end

local function collect_network_hashes(network)
  local hashes = {}
  for netGroup, _ in pairs(logistica.network_group_get_all()) do
    for hash, _ in pairs(network[netGroup]) do
      hashes[hash] = true
    end
  end
  return hashes
end

----------------------------------------------------------------
-- Network operation functions
----------------------------------------------------------------

local function clear_network(networkName, keepWifiConnections)
  local network = networks[networkName]
  if not network then return false end
  -- setting the cached network position to ALREADY_TRIED prevents a lot of full network searches, which are expensive
  local nodeCount = 0
  for netGroup, _ in pairs(logistica.network_group_get_all()) do
    local nodes = network[netGroup]
    for nodeHash, _ in pairs(nodes) do
      local position = h2p(nodeHash)
      set_cache_network_id(minetest.get_meta(position), CACHED_NETWORK_ID_ALREADY_TRIED)
      nodeCount = nodeCount + 1
    end
  end
  if not keepWifiConnections then
    for posHash, _ in pairs(network.wireless_transmitters) do
      local trPos = h2p(posHash)
      logistica.load_position(trPos)
      logistica.wifi_network_disconnect_transmitter(trPos)
      logistica.wifi_transmitter_set_infotext(trPos, nil)
    end
  end
  networks[networkName] = nil
end

local function ends_with(str, ending)
  return str:sub(-#ending) == ending
end

local function break_logistica_node(pos)
  local node = minetest.get_node(pos)
  local nodeName = node.name
  if ends_with(nodeName, DISABLED_SUFFIX) then return end -- already disabled
  if ends_with(nodeName, ON_SUFFIX) then
    -- a little ugly but some nodes (e.g. toggleable cable) have _on/_off and _on_disabled/_off_disabled
    local newNodeName = nodeName:sub(1, #node.name - #ON_SUFFIX)
    if minetest.registered_nodes[newNodeName..DISABLED_SUFFIX] then
      nodeName = newNodeName
    end
  else
    local newNodeName = nodeName .. DISABLED_SUFFIX
    if minetest.registered_nodes[newNodeName] then
      logistica.swap_node(pos, newNodeName)
    end
  end
end

-- Returns 1 for straight insulating cable, 2 for L-shape, 0 for not insulating.
local function get_insul_type(nodeName)
  return minetest.get_item_group(nodeName, "logistica_insulating")
end

local function vec_eq(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

-- Can the cable propagate the scan OUT in this offset direction?
-- Type 1 (straight): forward or backward axis only.
-- Type 2 (L-shape): forward or left only (nodebox arms go -Z and +X at facedir=0).
local function insul_allows_exit(offset, d, insulType)
  if not d then return true end
  if insulType == 1 then
    return vec_eq(offset, d.forward) or vec_eq(offset, d.backward)
  elseif insulType == 2 then
    return vec_eq(offset, d.forward) or vec_eq(offset, d.left)
  end
  return true
end

-- Can the scan enter the cable FROM this offset direction?
-- Entry direction is the negative of the arm direction (approaching from outside the arm end).
-- Type 1 (straight): same as exit (symmetric).
-- Type 2 (L-shape): backward or right (the negative of forward/left).
local function insul_allows_entry(offset, d, insulType)
  if not d then return true end
  if insulType == 1 then
    return vec_eq(offset, d.forward) or vec_eq(offset, d.backward)
  elseif insulType == 2 then
    return vec_eq(offset, d.backward) or vec_eq(offset, d.right)
  end
  return true
end

-- returns a numberOfNetworks (which is 0, 1, 2), networkOrNil
local function find_adjacent_networks(pos)
  local currNetwork = nil
  local selfIsToggler = logistica.GROUPS.signal_togglers.is(minetest.get_node(pos).name)
  for _, adj in pairs(adjacent) do
    local otherPos = vector.add(pos, adj)
    local otherNode = minetest.get_node(otherPos)
    local otherNodeName = otherNode.name
    local isCable = logistica.GROUPS.cables.is(otherNodeName)
    if isCable then
      -- block connecting through an insulating cable on a non-permitted face, same as the full network scan does
      local insulType = get_insul_type(otherNodeName)
      if insulType > 0 and not insul_allows_entry(adj, logistica.get_rot_directions(otherNode.param2), insulType) then
        isCable = false
      end
    end
    -- an ON signal toggler relays the network to whatever it's facing, same as the full network scan does
    local isActiveTogglerRelay = logistica.GROUPS.signal_togglers.is(otherNodeName) and ends_with(otherNodeName, ON_SUFFIX)
    if isActiveTogglerRelay and selfIsToggler then
      -- mirror the scan's one-way gate: block another toggler from entering via the backward (output) face
      local d = logistica.get_rot_directions(otherNode.param2)
      if d and vec_eq(adj, d.forward) then
        isActiveTogglerRelay = false
      end
    end
    if isCable or logistica.GROUPS.controllers.is(otherNodeName) or isActiveTogglerRelay then
      local otherNetwork = logistica.get_network_or_nil(otherPos)
      if otherNetwork ~= nil then
        if currNetwork == nil then currNetwork = otherNetwork
        elseif currNetwork ~= otherNetwork then return 2, nil end
      end
    end
  end
  local numNetworks = 1
  if currNetwork == nil then numNetworks = 0 end
  return numNetworks, currNetwork
end

local function recursive_scan_for_nodes_for_controller(network, positionHashes, numScanned)
  if not numScanned then numScanned = 0 end

  if numScanned > HARD_NETWORK_NODE_LIMIT then
    return CREATE_NETWORK_STATUS_TOO_MANY_NODES
  end

  local connections = {}
  local newToScan = 0
  for posHash, _ in pairs(positionHashes) do
    local pos = h2p(posHash)
    logistica.load_position(pos)
    local posNode = minetest.get_node(pos)
    local posInsulType = get_insul_type(posNode.name)
    local posInsulDirs = (posInsulType > 0) and logistica.get_rot_directions(posNode.param2) or nil
    for _, offset in pairs(adjacent) do
      local otherPos = vector.add(pos, offset)
      logistica.load_position(otherPos)
      local otherNode = minetest.get_node(otherPos)
      local otherName = otherNode.name
      local otherHash = p2h(otherPos)
      -- block approaching a toggler from its backward (output) side — one-way gate
      local blockedToggler = logistica.GROUPS.signal_togglers.is(otherName) and (function()
        local d = logistica.get_rot_directions(otherNode.param2)
        return d ~= nil and offset.x == d.forward.x and offset.y == d.forward.y and offset.z == d.forward.z
      end)()
      -- block propagation out of an insulating cable on a non-permitted face
      local blockedFromInsulating = posInsulType > 0
        and not insul_allows_exit(offset, posInsulDirs, posInsulType)
      -- block entry into an insulating cable from a non-permitted face
      local otherInsulType = get_insul_type(otherName)
      local blockedIntoInsulating = otherInsulType > 0 and (function()
        local d = logistica.get_rot_directions(otherNode.param2)
        return not insul_allows_entry(offset, d, otherInsulType)
      end)()
      if not blockedToggler and not blockedFromInsulating and not blockedIntoInsulating
          and network.controller ~= otherHash
          and logistica.get_network_group_for_node_name(otherName) ~= nil
          and not has_machine(network, otherHash)
          and network[logistica.NETWORK_GROUPS.cables][otherHash] == nil then
        local existingNetwork = logistica.get_network_id_or_nil(otherPos)
        if existingNetwork ~= nil and existingNetwork ~= network then
          return CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK
        end
        local valid = false
        local nodeNetworkGroup = logistica.get_network_group_for_node_name(otherName)
        if nodeNetworkGroup == logistica.NETWORK_GROUPS.cables then -- cables get special treatment
          network[nodeNetworkGroup][otherHash] = true
          connections[otherHash] = true
          valid = true
        elseif nodeNetworkGroup == logistica.NETWORK_GROUPS.wireless_transmitters then
          local posBelow = vector.add(otherPos, vector.new(0,-1,0))
          --transmitters must be on top the controller to work
          if logistica.GROUPS.controllers.is(minetest.get_node(posBelow).name) then
            local connectedRcs = logistica.wifi_network_get_connected_receivers_for_transmitter(otherPos)
            network[nodeNetworkGroup][otherHash] = true
            for _, rcPos in ipairs(connectedRcs) do
              logistica.load_position(rcPos)
              local rcNodeName = minetest.get_node(rcPos).name
              local rcGroup = logistica.get_network_group_for_node_name(rcNodeName)
              if rcGroup and rcGroup == logistica.NETWORK_GROUPS.wireless_receivers then
                local rcHash = p2h(rcPos)
                network[rcGroup][rcHash] = true
                connections[rcHash] = true
                notify_connected(rcPos, rcNodeName, network.controller)
              end
            end
            valid = true
          end
        elseif nodeNetworkGroup == logistica.NETWORK_GROUPS.wireless_receivers then
          -- encountered a wild wireless receiver that wasn't added by a transmitter
          -- this is an invalid config, break the receiver, and don't add it
          break_logistica_node(otherPos)
          minetest.get_meta(otherPos):set_string("infotext", "ERROR: Receiver cannot be placed connecting to existing networks!")
        elseif nodeNetworkGroup ~= nil then
          -- add to all network groups this node belongs to (some nodes, e.g. node digger, are in multiple)
          for grp, _ in pairs(logistica.group_get_all_network_groups_for_node(otherName)) do
            if network[grp] then network[grp][otherHash] = true end
          end
          valid = true
          -- if this is a toggler in ON state, treat it as a relay so the scan continues from it
          if logistica.GROUPS.signal_togglers.is(otherName) and ends_with(otherName, ON_SUFFIX) then
            connections[otherHash] = true
          end
        end

        if valid then
          numScanned = numScanned + 1
          newToScan = newToScan + 1
          set_cache_network_id(minetest.get_meta(otherPos), network.controller)
          notify_connected(otherPos, otherName, network.controller)
        end
      end -- end of general checks
    end -- end inner for loop
  end -- end outer for loop

  -- We have nested loops so we can do tail recursion
  if newToScan <= 0 then network._num_nodes = numScanned return STATUS_OK
  else return recursive_scan_for_nodes_for_controller(network, connections, numScanned) end
end

local function update_all_network_caches(network)
  logistica.update_cache_network(network, LOG_CACHE_MASS_STORAGE)
  logistica.update_cache_network(network, LOG_CACHE_REQUESTER)
  logistica.update_cache_network(network, LOG_CACHE_SUPPLIER)
end

-- initialSignals: optional {name -> {hash -> true}} copied from previous network so that
-- on_connect_to_network callbacks that call signal_get_state see the right state.
-- Stale sender entries are cleaned up via notify_disconnected -> signal_remove_sender.
local function create_network(controllerPosition, oldNetworkName, initialSignals)
  local node = minetest.get_node(controllerPosition)
  if not node.name:find("_controller") or not node.name:find("logistica:") then return false end
  local meta = minetest.get_meta(controllerPosition)
  local controllerHash = p2h(controllerPosition)
  set_cache_network_id(meta, controllerHash)
  local network = {}
  local nameFromMeta = meta:get_string("name")
  if nameFromMeta == "" then nameFromMeta = nil end
  local networkName = oldNetworkName or nameFromMeta or logistica.get_rand_string_for(controllerPosition)
  networks[controllerHash] = network
  meta:set_string("infotext", "Controller of Network: "..networkName)
  network.controller = controllerHash
  network.name = networkName
  for group, _ in pairs(logistica.network_group_get_all()) do
    network[group] = {}
  end
  -- caches aren't groups, so add them manually
  network.storage_cache = {}
  network.supplier_cache = {}
  network.requester_cache = {}
  network.signals = {}  -- {signal_name -> {sender_hash -> true}} for all active ON senders
  if initialSignals then
    for name, senders in pairs(initialSignals) do
      local copy = {}
      for senderHash, _ in pairs(senders) do copy[senderHash] = true end
      if not logistica.table_is_empty(copy) then network.signals[name] = copy end
    end
  end
  network._num_nodes = 0

  local startPos = { [controllerHash] = true }
  local status = recursive_scan_for_nodes_for_controller(network, startPos)
  local errorMsg = nil
  if status == CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK then
    errorMsg = "Cannot create network: Would overlap with another network!"
    break_logistica_node(controllerPosition)
  elseif status == CREATE_NETWORK_STATUS_TOO_MANY_NODES then
    errorMsg = "Controller max nodes limit of "..HARD_NETWORK_NODE_LIMIT.." nodes per network exceeded!"
  elseif status == STATUS_OK then
    -- controller scan skips updating storage cache, do so now
    update_all_network_caches(network)
  end
  if errorMsg ~= nil then
    networks[controllerHash] = nil
    break_logistica_node(controllerPosition)
    meta:set_string("infotext", "ERROR: "..errorMsg)
  end
end

----------------------------------------------------------------
-- worker functions for cable/machine/controllers
----------------------------------------------------------------

local function rescan_network(networkId)
  local network = networks[networkId]
  if not network then return false end
  if not network.controller then return false end
  local conHash = network.controller
  local controllerPosition = h2p(conHash)
  local oldNetworkName = network.name
  local oldHashes = collect_network_hashes(network)
  local oldSignals = network.signals
  clear_network(networkId, true)
  rescan_skip_notify = oldHashes
  create_network(controllerPosition, oldNetworkName, oldSignals)
  rescan_skip_notify = nil
  local newNetwork = networks[conHash]
  for hash, _ in pairs(oldHashes) do
    if not newNetwork or not network_contains_hash(newNetwork, hash) then
      notify_disconnected(h2p(hash), conHash)
    end
  end
end

local function find_cable_connections(pos)
  local connections = {}
  for _, offset in pairs(adjacent) do
    local otherPos = vector.add(pos, offset)
    local otherNode = minetest.get_node_or_nil(otherPos)
    if otherNode and minetest.get_item_group(otherNode.name, logistica.TIER_ALL) > 0 then
      table.insert(connections, otherPos)
    end
  end
  return connections
end

local function try_to_add_network(pos)
  create_network(pos)
end

local function try_to_add_to_network(pos, ops)
  local networkCount, otherNetwork  = find_adjacent_networks(pos)
  if networkCount <= 0 then return STATUS_OK end -- nothing to connect to
  if otherNetwork == nil or networkCount >= 2 then
    break_logistica_node(pos) -- swap out storage node for disabled one 
    minetest.get_meta(pos):set_string("infotext", "ERROR: cannot connect to multiple networks!")
    return CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK
  end
  -- else, we have 1 network
  local newNodeCount = otherNetwork._num_nodes + 1
  if newNodeCount > HARD_NETWORK_NODE_LIMIT then
    break_logistica_node(pos) -- swap out storage node for disabled one
    minetest.get_meta(pos):set_string("infotext", "ERROR: Network exceeds max limit of "..HARD_NETWORK_NODE_LIMIT.." nodes!")
    return CREATE_NETWORK_STATUS_TOO_MANY_NODES
  end
  ops.get_list(otherNetwork)[p2h(pos)] = true
  otherNetwork._num_nodes = otherNetwork._num_nodes + 1
  set_cache_network_id(minetest.get_meta(pos), otherNetwork.controller)
  ops.update_cache_node_added(pos)
end

local function remove_from_network(pos, oldNode, oldMeta, ops)
  local hash = p2h(pos)
  local network = logistica.get_network_or_nil(pos, oldMeta)
  if not network then return end
  local networkId = network.controller
  -- first clear the cache while the position is still counted as being "in-network"
  ops.update_cache_node_removed(pos)
  -- then remove the position from the network
  ops.get_list(network)[hash] = nil
  -- decrement count
  network._num_nodes = network._num_nodes - 1
  notify_disconnected(pos, networkId, oldNode and oldNode.name)
end

local function on_node_change(pos, oldNode, oldMeta, ops)
  local placed = (oldNode == nil) -- if oldNode is nil, we placed a new one
  if placed == true then
    try_to_add_to_network(pos, ops)
  else
    remove_from_network(pos, oldNode, oldMeta, ops)
  end
end

-- returns true/false if adding to network succeeds/fails
local function add_receiver_to_network(network, receiverPos)
  local rcNodeName = minetest.get_node(receiverPos).name
  local rcGroup = logistica.get_network_group_for_node_name(rcNodeName)
  if not rcGroup then return false end

  local rcHash = p2h(receiverPos)
  local networkNumNodes = network._num_nodes
  local startPos = { [rcHash] = true }
  network[rcGroup][rcHash] = true
  local status = recursive_scan_for_nodes_for_controller(network, startPos, networkNumNodes)
  local errorMsg = nil

  if status == CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK then
    errorMsg = "Cannot connect Receiver to network: Would overlap with another network!"
  elseif status == CREATE_NETWORK_STATUS_TOO_MANY_NODES then
    errorMsg = "Max nodes limit of "..HARD_NETWORK_NODE_LIMIT.." nodes per network exceeded!"
  elseif status == STATUS_OK then
    -- update caches
    notify_connected(receiverPos, rcNodeName, network.controller)
    update_all_network_caches(network)
  end
  if errorMsg ~= nil then
    network[rcGroup][rcHash] = nil
    break_logistica_node(receiverPos)
    minetest.get_meta(receiverPos):set_string("infotext", "ERROR: "..errorMsg)
    return false
  end
  return true
end

local function remove_receiver_from_network(receiverPos)
  logistica.try_to_wake_up_network(receiverPos)
  local network = logistica.get_network_or_nil(receiverPos)
  if not network then return end
  rescan_network(network.controller)
end

local MASS_STORAGE_OPS = {
  get_list = function(network) return network.mass_storage end,
  update_cache_node_added = function(pos) logistica.update_cache_at_pos(pos, LOG_CACHE_MASS_STORAGE) end,
  update_cache_node_removed = function(pos) logistica.update_cache_node_removed_at_pos(pos, LOG_CACHE_MASS_STORAGE) end,
}

local REQUESTER_OPS = {
  get_list = function(network) return network.requesters end,
  update_cache_node_added = function(pos) logistica.update_cache_at_pos(pos, LOG_CACHE_REQUESTER) end,
  update_cache_node_removed = function(pos) logistica.update_cache_node_removed_at_pos(pos, LOG_CACHE_REQUESTER) end,
}

local SUPPLIER_OPS = {
  get_list = function(network) return network.suppliers end,
  update_cache_node_added = function(pos) logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER) end,
  update_cache_node_removed = function(pos) logistica.update_cache_node_removed_at_pos(pos, LOG_CACHE_SUPPLIER) end,
}

local INJECTOR_OPS = {
  get_list = function(network) return network.injectors end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local ITEM_STORAGE_OPS = {
  get_list = function(network) return network.item_storage end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local TRASHCAN_OPS = {
  get_list = function(network) return network.trashcans end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local RESERVOIR_OPS = {
  get_list = function(network) return network.reservoirs end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local MISC_OPS = {
  get_list = function(network) return network.misc end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local TRANSMITTER_OPS = {
  get_list = function(network) return network.wireless_transmitters end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local SIGNAL_SENDER_OPS = {
  get_list = function(network) return network.signal_senders end,
  update_cache_node_added = function(_) end,
  update_cache_node_removed = function(_) end,
}

local SIGNAL_RECEIVER_OPS = {
  get_list = function(network) return network.signal_receivers end,
  update_cache_node_added = function(_) end,
  update_cache_node_removed = function(_) end,
}


local function on_signal_toggler_changed(pos, oldNode, oldMeta)
  if oldNode == nil then
    try_to_add_to_network(pos, SIGNAL_RECEIVER_OPS)
    -- notify_connected is not called by try_to_add_to_network, so do it manually
    -- so the toggler can check current signal state via its deferred timer
    local network = logistica.get_network_or_nil(pos)
    if network then
      notify_connected(pos, minetest.get_node(pos).name, network.controller)
    end
  else
    -- rescan rather than simple remove: toggler removal may disconnect the forward side
    local cachedId = get_unchecked_cached_network_id(oldMeta)
    if cachedId and cachedId ~= CACHED_NETWORK_ID_ALREADY_TRIED then
      rescan_network(tonumber(cachedId))
    end
  end
end

local function on_signal_sender_changed(pos, oldNode, oldMeta)
  if oldNode == nil then
    try_to_add_to_network(pos, SIGNAL_SENDER_OPS)
  else
    -- get_network_or_nil checks the current node name which is already "air" after_dig,
    -- so look up the network directly from the cached ID in oldMeta instead
    local cachedId = get_unchecked_cached_network_id(oldMeta)
    local network = cachedId and cachedId ~= CACHED_NETWORK_ID_ALREADY_TRIED
      and networks[tonumber(cachedId)]
    if network then
      local hash = p2h(pos)
      local owned = network._propagation == nil
      if owned then
        network._propagation = { origin_hash = hash, visited = {}, pending = {}, queued = {} }
      end
      remove_sender_signals_bfs(network, hash)
      if owned then
        run_gate_propagation(network, network._propagation)
        network._propagation = nil
      end
    end
    remove_from_network(pos, oldNode, oldMeta, SIGNAL_SENDER_OPS)
  end
end

local function on_signal_receiver_changed(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, SIGNAL_RECEIVER_OPS)
end

local function cable_can_extend_network_from(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return false end
  return
    logistica.GROUPS.cables.is(node.name)
    or logistica.GROUPS.controllers.is(node.name)
    or logistica.GROUPS.wireless_receivers.is(node.name)
end

local function on_wifi_receiver_changed(pos, oldNode, oldMeta, objRef)
  local playerName = ""
  if objRef and objRef:is_player() then playerName = objRef:get_player_name() end
  local added = (oldNode == nil)
  if added then
    for _, offset in ipairs(adjacent) do
      local adjPos = vector.add(pos, offset)
      local adjNet = logistica.get_network_id_or_nil(adjPos)
      if adjNet then -- wifi receiver should NOT be placed next to existing networks
        break_logistica_node(pos)
        minetest.get_meta(pos):set_string("infotext", "ERROR: Receiver cannot be placed connecting to existing networks!")
      end
    end
  else
    local networkId = get_unchecked_cached_network_id(oldMeta)
    if networkId then
      rescan_network(tonumber(networkId))
    end
  end
end

local function on_wifi_transmitter_changed(pos, oldNode, oldMeta, objRef)
  local added = (oldNode == nil)
  if added then
    try_to_add_to_network(pos, TRANSMITTER_OPS)
    -- no need to rescan a network, just placing a transmitter can't result in more nodes immediately being added
  else
    local networkId = get_unchecked_cached_network_id(oldMeta)
    if networkId then
        rescan_network(tonumber(networkId))
    end
  end
end
----------------------------------------------------------------
-- global namespaced functions
----------------------------------------------------------------

-- attempts to 'wake up' - aka load the controller that was last assigned to this position
function logistica.try_to_wake_up_network(pos)
  logistica.load_position(pos)
  if logistica.get_network_or_nil(pos, nil, true) then return end -- it's already awake
  local cachedId = get_unchecked_cached_network_id(minetest.get_meta(pos))
  if not cachedId or cachedId == "" or cachedId == CACHED_NETWORK_ID_ALREADY_TRIED then return end
  local conPos = h2p(cachedId)

  logistica.load_position(conPos)
  local node = minetest.get_node(conPos)
  if logistica.GROUPS.controllers.is(node.name) then
    local nodeDef = minetest.registered_nodes[node.name]
    if nodeDef.on_timer then
      nodeDef.on_timer(conPos, 1)
    end
  end
end

function logistica.on_cable_change(pos, oldNode, optMeta, wasPlacedOverride)
  local placed = wasPlacedOverride
  if placed == nil then
    placed = (oldNode == nil) -- if oldNode is nil, we placed it
  end

  local connections = find_cable_connections(pos)
  if not connections or #connections < 1 then return end -- nothing to update
  local networkEnd = #connections == 1

  if networkEnd then
    if not placed then -- removed a network end
      local network = logistica.get_network_or_nil(pos, optMeta)
      if network then
        network[logistica.NETWORK_GROUPS.cables][p2h(pos)] = nil
        network._num_nodes = network._num_nodes - 1
      end
    elseif cable_can_extend_network_from(connections[1]) then
      local otherNetwork = logistica.get_network_or_nil(connections[1])
      if otherNetwork then
        local newNodeCount = otherNetwork._num_nodes + 1
        if newNodeCount > HARD_NETWORK_NODE_LIMIT then
          break_logistica_node(pos)
          minetest.get_meta(pos):set_string("infotext", "ERROR: Network exceeds max limit of "..HARD_NETWORK_NODE_LIMIT.." nodes!")
        else
          otherNetwork[logistica.NETWORK_GROUPS.cables][p2h(pos)] = true
          set_cache_network_id(minetest.get_meta(pos), otherNetwork.controller)
          otherNetwork._num_nodes = newNodeCount
        end
      end
    end
    return -- was a network end, no need to do anything else
  end

  -- We have more than 1 connected nodes - either cables or machines, something needs recalculating
  local connectedNetworksId = {}
  local tmpNetworkId = "INVALID"
  local allConnectionsHaveSameNetwork = true
  for _, connectedPos in pairs(connections) do
    local otherNetworkId = logistica.get_network_id_or_nil(connectedPos)
    if otherNetworkId then connectedNetworksId[otherNetworkId] = true end
    if tmpNetworkId == "INVALID" then tmpNetworkId = otherNetworkId
    elseif otherNetworkId ~= tmpNetworkId then allConnectionsHaveSameNetwork = false end
  end
  local firstNetworkId = nil
  local numNetworks = 0
  for networkId,_ in pairs(connectedNetworksId) do
    numNetworks = numNetworks + 1
    if firstNetworkId == nil then firstNetworkId = networkId end
  end
  if numNetworks <= 0 then return end -- still nothing to update
  if numNetworks == 1 then
    if placed and allConnectionsHaveSameNetwork then
      local addToNetwork = logistica.get_network_by_id_or_nil(firstNetworkId)
      if addToNetwork then
        addToNetwork[logistica.NETWORK_GROUPS.cables][p2h(pos)] = true
        set_cache_network_id(minetest.get_meta(pos), addToNetwork.controller)
      end
    else
      rescan_network(firstNetworkId)
    end
  else
    -- two or more connected networks (should only happen on place)
    -- this cable can't work here, break it, and nothing to update
    local meta = minetest.get_meta(pos)
    break_logistica_node(pos)
    meta:set_string("infotext", "ERROR: cannot connect to multiple networks!")
  end
end

function logistica.on_controller_change(pos, oldNode)
  local hashPos = p2h(pos)
  local placed = (oldNode == nil) -- if oldNode is nil, we placed a new one
  if placed == true then
    try_to_add_network(pos)
  else
    local network = networks[hashPos]
    if network then
      local allHashes = collect_network_hashes(network)
      for hash, _ in pairs(allHashes) do
        notify_disconnected(h2p(hash), hashPos)
      end
    end
    clear_network(hashPos)
  end
end

-- returns true/false if successfully added receiver to position
function logistica.add_receiver_to_network(network, receiverPos)
  if not network or not receiverPos then return false end
  return add_receiver_to_network(network, receiverPos)
end

function logistica.remove_receiver_from_network(receiverPos)
  remove_receiver_from_network(receiverPos)
end

function logistica.on_mass_storage_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, MASS_STORAGE_OPS)
end

function logistica.on_requester_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, REQUESTER_OPS)
end

function logistica.on_supplier_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, SUPPLIER_OPS)
end

function logistica.on_injector_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, INJECTOR_OPS)
end

function logistica.on_item_storage_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, ITEM_STORAGE_OPS)
end

function logistica.on_access_point_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, MISC_OPS)
end

function logistica.on_trashcan_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, TRASHCAN_OPS)
end

function logistica.on_reservoir_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, RESERVOIR_OPS)
end

function logistica.on_lava_furnace_fueler_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, MISC_OPS)
end

function logistica.on_pump_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, MISC_OPS)
end

function logistica.on_item_monitor_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, MISC_OPS)
end

function logistica.on_digiline_sender_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, MISC_OPS)
end

function logistica.on_wifi_receiver_change(pos, oldNode, oldMeta, objRef)
  on_wifi_receiver_changed(pos, oldNode, oldMeta, objRef)
end

function logistica.on_wifi_transmitter_change(pos, oldNode, oldMeta, objRef)
  on_wifi_transmitter_changed(pos, oldNode, oldMeta, objRef)
end

function logistica.on_signal_toggler_change(pos, oldNode, oldMeta)
  on_signal_toggler_changed(pos, oldNode, oldMeta)
end

function logistica.rescan_network_at_pos(pos)
  local network = logistica.get_network_or_nil(pos)
  if network then rescan_network(network.controller) end
end

function logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  on_signal_sender_changed(pos, oldNode, oldMeta)
end

function logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  on_signal_receiver_changed(pos, oldNode, oldMeta)
end

function logistica.on_cable_insulating_change(pos, oldNode, oldMeta)
  if oldNode then
    -- removed: rescan the network this cable belonged to
    local cachedId = get_unchecked_cached_network_id(oldMeta or minetest.get_meta(pos))
    if cachedId and cachedId ~= CACHED_NETWORK_ID_ALREADY_TRIED then
      rescan_network(tonumber(cachedId))
    end
  else
    -- placed: find any adjacent network and rescan so the cable can be picked up
    for _, offset in ipairs(adjacent) do
      local adjNetwork = logistica.get_network_or_nil(vector.add(pos, offset))
      if adjNetwork then
        rescan_network(adjNetwork.controller)
        return
      end
    end
  end
end

-- Send a named signal ON or OFF from pos. Notifies all receivers on the network.
-- Uses OR semantics: signal is ON as long as any sender has it ON.
-- Gate receivers are processed breadth-first to prevent unbounded recursion.
-- Receivers are only notified when the aggregate signal state actually changes,
-- preventing flip-flop gates from toggling on every poll of a persistent sender.
function logistica.signal_send(pos, name, isOn)
  if not name or name == "" then return end
  local network = logistica.get_network_or_nil(pos)
  if not network then return end
  local hash = p2h(pos)
  if not network.signals[name] then network.signals[name] = {} end
  local prevIsOn = not logistica.table_is_empty(network.signals[name])
  if isOn then
    network.signals[name][hash] = true
  else
    network.signals[name][hash] = nil
    if logistica.table_is_empty(network.signals[name]) then
      network.signals[name] = nil
    end
  end
  local signalIsOn = network.signals[name] ~= nil
  if signalIsOn == prevIsOn then return end
  if network._propagation then
    notify_signal_receivers(network, name, signalIsOn)
    return
  end
  local ctx = { origin_hash = hash, visited = {}, pending = {}, queued = {} }
  network._propagation = ctx
  notify_signal_receivers(network, name, signalIsOn)
  run_gate_propagation(network, ctx)
  network._propagation = nil
end

-- Returns true if the named signal is currently ON in the network, false otherwise.
function logistica.signal_get_state(networkId, name)
  if not name or name == "" then return false end
  local network = networks[networkId]
  if not network then return false end
  return network.signals[name] ~= nil
end

-- Removes all signal contributions from pos. Call this in on_disconnect_from_network
-- for any signal sender node, passing the networkId from the callback argument.
function logistica.signal_remove_sender(pos, networkId)
  local network = networks[networkId]
  if not network then return end
  local hash = p2h(pos)
  if network._propagation then
    remove_sender_signals_bfs(network, hash)
    return
  end
  local ctx = { origin_hash = hash, visited = {}, pending = {}, queued = {} }
  network._propagation = ctx
  remove_sender_signals_bfs(network, hash)
  run_gate_propagation(network, ctx)
  network._propagation = nil
end

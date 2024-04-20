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

function logistica.get_network_or_nil(pos, optMeta, withoutModifying, withoutModifying)
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

local function notify_connected(pos, nodeName, networkId)
  -- set the cached network ID first
  set_cache_network_id(minetest.get_meta(pos), networkId)
  local def = minetest.registered_nodes[nodeName]
  if def and def.logistica and def.logistica.on_connect_to_network then
    def.logistica.on_connect_to_network(pos, networkId)
  end
end

----------------------------------------------------------------
-- Network operation functions
----------------------------------------------------------------

local function clear_network(networkName)
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
  for posHash, _ in pairs(network.wireless_transmitters) do
    local trPos = h2p(posHash)
    logistica.load_position(trPos)
    logistica.wifi_network_disconnect_transmitter(trPos)
    logistica.wifi_transmitter_set_infotext(trPos, nil)
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

-- returns a numberOfNetworks (which is 0, 1, 2), networkOrNil
local function find_adjacent_networks(pos)
  local currNetwork = nil
  for _, adj in pairs(adjacent) do
    local otherPos = vector.add(pos, adj)
    local otherNodeName = minetest.get_node(otherPos).name
    if logistica.GROUPS.cables.is(otherNodeName) or logistica.GROUPS.controllers.is(otherNodeName) then
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
    for _, offset in pairs(adjacent) do
      local otherPos = vector.add(pos, offset)
      logistica.load_position(otherPos)
      local otherName = minetest.get_node(otherPos).name
      local otherHash = p2h(otherPos)
      if network.controller ~= otherHash
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
          -- all machines, except controllers, should be added to network
          network[nodeNetworkGroup][otherHash] = true
          valid = true
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

local function create_network(controllerPosition, oldNetworkName)
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
  clear_network(networkId)
  create_network(controllerPosition, oldNetworkName)
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

local function remove_from_network(pos, oldMeta, ops)
  local hash = p2h(pos)
  local network = logistica.get_network_or_nil(pos, oldMeta)
  if not network then return end
  -- first clear the cache while the position is still counted as being "in-network"
  ops.update_cache_node_removed(pos)
  -- then remove the position from the network
  ops.get_list(network)[hash] = nil
  -- decrement count
  network._num_nodes = network._num_nodes - 1
end

local function on_node_change(pos, oldNode, oldMeta, ops)
  local placed = (oldNode == nil) -- if oldNode is nil, we placed a new one
  if placed == true then
    try_to_add_to_network(pos, ops)
  else
    remove_from_network(pos, oldMeta, ops)
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

function logistica.on_wifi_receiver_change(pos, oldNode, oldMeta, objRef)
  on_wifi_receiver_changed(pos, oldNode, oldMeta, objRef)
end

function logistica.on_wifi_transmitter_change(pos, oldNode, oldMeta, objRef)
  on_wifi_transmitter_changed(pos, oldNode, oldMeta, objRef)
end

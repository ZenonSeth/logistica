local networks = {}
local HARD_NETWORK_NODE_LIMIT = 4000 -- A network cannot consist of more than this many nodes
local STATUS_OK = 0
local CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK = -1
local CREATE_NETWORK_STATUS_TOO_MANY_NODES = -2

local META_STORED_NETWORK = "logisticanet"

local p2h = minetest.hash_node_position
local h2p = minetest.get_position_from_hash

local adjecent = {
  vector.new( 1,  0,  0), vector.new( 0,  1,  0), vector.new( 0,  0,  1),
  vector.new(-1,  0,  0), vector.new( 0, -1,  0), vector.new( 0,  0, -1),
}

local function has_machine(network, id)
  if not network then return false end
  if network.requesters[id]
    or network.suppliers[id]
    or network.mass_storage[id]
    or network.item_storage[id]
    or network.injectors[id]
    or network.misc[id]
    or network.trashcans[id]
  then
    return true
  else
    return false
  end
end

local function network_contains_hash(network, hash)
  if hash == network.controller then return true end
  if network.cables[hash] then return true end
  if has_machine(network, hash) then return true end
  return false
end

-- we need this because default tostring(number) function returns scientific representation which loses accuracy
local str = function(anInt) return string.format("%.0f", anInt) end

local function set_cache_network_id(metaForPos, networkId)
  metaForPos:set_string(META_STORED_NETWORK, str(networkId))
end

local function get_cached_network_or_nil(posHash, metaForPos)
  local cachedId = ""
  -- if metaForPos comes from after_dig_node, then it's just a table, not a MetaDataRef
  if type(metaForPos) == "table" then
    if metaForPos.fields and metaForPos.fields[META_STORED_NETWORK] then
      cachedId = metaForPos.fields[META_STORED_NETWORK]
    end
  else
    cachedId = (metaForPos:contains(META_STORED_NETWORK) and metaForPos:get_string(META_STORED_NETWORK)) or ""
  end
  local network = networks[tonumber(cachedId)]
  if network and network_contains_hash(network, posHash) then
    return network
  end
  return nil
end

function logistica.get_network_by_id_or_nil(networkId)
  return networks[networkId]
end

function logistica.get_network_or_nil(pos, optMeta)
  local hash = p2h(pos)
  local meta = minetest.get_meta(pos) -- optMeta or minetest.get_meta(pos)
  local possibleNetwork = get_cached_network_or_nil(hash, optMeta or meta)
  if possibleNetwork then
    return possibleNetwork
  end
  -- otherwise, serach all networks, save it if we find one
  for netHash, network in pairs(networks) do
    if network_contains_hash(network, hash) then
      set_cache_network_id(meta, netHash)
      return network
    end
  end
  return nil
end

function logistica.get_network_name_or_nil(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return nil else return network.name end
end

function logistica.rename_network(networkId, newName)
  local network = networks[networkId]
  if not network then return false end
  network.name = newName
  return true
end

function logistica.get_network_id_or_nil(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return nil else return network.controller end
end

local function notify_connected(pos, nodeName, networkId)
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
  networks[networkName] = nil
end

local function break_logistica_node(pos)
  local node = minetest.get_node(pos)
  logistica.swap_node(pos, node.name .. "_disabled")
end

-- returns a numberOfNetworks (which is 0, 1, 2), networkOrNil
local function find_adjecent_networks(pos)
  local currNetwork = nil
  for _, adj in pairs(adjecent) do
    local otherPos = vector.add(pos, adj)
    local otherNodeName = minetest.get_node(otherPos).name
    if logistica.is_cable(otherNodeName) or logistica.is_controller(otherNodeName) then
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
    numScanned = numScanned + 1
    logistica.load_position(pos)
    for _, offset in pairs(adjecent) do
      local otherPos = vector.add(pos, offset)
      logistica.load_position(otherPos)
      local otherName = minetest.get_node(otherPos).name
      local otherHash = p2h(otherPos)
      if network.controller ~= otherHash
          and not has_machine(network, otherHash)
          and network.cables[otherHash] == nil then
        local existingNetwork = logistica.get_network_id_or_nil(otherPos)
        if existingNetwork ~= nil and existingNetwork ~= network then
          return CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK
        end
        local valid = false
        if logistica.is_cable(otherName) then
          network.cables[otherHash] = true
          connections[otherHash] = true
          valid = true
        end
        if logistica.is_requester(otherName) then
          network.requesters[otherHash] = true
          valid = true
        end
        if logistica.is_injector(otherName) then
          network.injectors[otherHash] = true
          valid = true
        end
        if logistica.is_supplier(otherName) 
            or logistica.is_crafting_supplier(otherName)
            or logistica.is_vaccuum_supplier(otherName) then
          network.suppliers[otherHash] = true
          valid = true
        end
        if logistica.is_mass_storage(otherName) then
          network.mass_storage[otherHash] = true
          valid = true
        end
        if logistica.is_item_storage(otherName) then
          network.item_storage[otherHash] = true
          valid = true
        end
        if logistica.is_misc(otherName) then
          network.misc[otherHash] = true
          valid = true
        end
        if logistica.is_trashcan(otherName) then
          network.trashcans[otherHash] = true
          valid = true
        end
        if valid then
          newToScan = newToScan + 1
          set_cache_network_id(minetest.get_meta(otherPos), network.controller)
          notify_connected(otherPos, otherName, network.controller)
        end
      end -- end of general checks
    end -- end inner for loop
  end -- end outer for loop

  -- We have nested loops so we can do tail recursion
  if newToScan <= 0 then return STATUS_OK
  else return recursive_scan_for_nodes_for_controller(network, connections, numScanned) end
end

local function create_network(controllerPosition, oldNetworkName)
  local node = minetest.get_node(controllerPosition)
  if not node.name:find("_controller") or not node.name:find("logistica:") then return false end
  local meta = minetest.get_meta(controllerPosition)
  local controllerHash = p2h(controllerPosition)
  local network = {}
  local nameFromMeta = meta:get_string("name")
  if nameFromMeta == "" then nameFromMeta = nil end
  local networkName = oldNetworkName or nameFromMeta or logistica.get_rand_string_for(controllerPosition)
  networks[controllerHash] = network
  meta:set_string("infotext", "Controller of Network: "..networkName)
  network.controller = controllerHash
  network.name = networkName
  network.cables = {}
  network.requesters = {}
  network.injectors = {}
  network.suppliers = {}
  network.mass_storage = {}
  network.item_storage = {}
  network.misc = {}
  network.trashcans = {}
  network.storage_cache = {}
  network.supplier_cache = {}
  network.requester_cache = {}
  local startPos = {}
  startPos[controllerHash] = true
  local status = recursive_scan_for_nodes_for_controller(network, startPos)
  local errorMsg = nil
  if status == CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK then
    errorMsg = "Cannot create network: Would overlap with another network!"
    break_logistica_node(controllerPosition)
  elseif status == CREATE_NETWORK_STATUS_TOO_MANY_NODES then
    errorMsg = "Controller max nodes limit of "..HARD_NETWORK_NODE_LIMIT.." nodes per network exceeded!"
  elseif status == STATUS_OK then
    -- controller scan skips updating storage cache, do so now
    logistica.update_cache_network(network, LOG_CACHE_MASS_STORAGE)
    logistica.update_cache_network(network, LOG_CACHE_REQUESTER)
    logistica.update_cache_network(network, LOG_CACHE_SUPPLIER)
  end
  if errorMsg ~= nil then
    networks[controllerHash] = nil
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
  for _, offset in pairs(adjecent) do
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
  local networkCount, otherNetwork  = find_adjecent_networks(pos)
  if networkCount <= 0 then return STATUS_OK end -- nothing to connect to
  if otherNetwork == nil or networkCount >= 2 then
    break_logistica_node(pos) -- swap out storage node for disabled one 
    minetest.get_meta(pos):set_string("infotext", "ERROR: cannot connect to multiple networks!")
    return CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK
  end
  -- else, we have 1 network, add us to it!
  ops.get_list(otherNetwork)[p2h(pos)] = true
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
end

local function on_node_change(pos, oldNode, oldMeta, ops)
  local placed = (oldNode == nil) -- if oldNode is nil, we placed a new one
  if placed == true then
    try_to_add_to_network(pos, ops)
  else
    remove_from_network(pos, oldMeta, ops)
  end
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

local ACCESS_POINT_OPS = {
  get_list = function(network) return network.misc end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local TRASHCAN_OPS = {
  get_list = function(network) return network.trashcans end,
  update_cache_node_added = function(_)  end,
  update_cache_node_removed = function(_) end,
}

local function cable_can_extend_network_from(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return false end
  return logistica.is_cable(node.name) or logistica.is_controller(node.name)
end

----------------------------------------------------------------
-- global namespaced functions
----------------------------------------------------------------

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
      if network then network.cables[p2h(pos)] = nil end
    elseif cable_can_extend_network_from(connections[1]) then
      local otherNetwork = logistica.get_network_or_nil(connections[1])
      if otherNetwork then
        otherNetwork.cables[p2h(pos)] = true
        set_cache_network_id(minetest.get_meta(pos), otherNetwork.controller)
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
        addToNetwork.cables[p2h(pos)] = true
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
  on_node_change(pos, oldNode, oldMeta, ACCESS_POINT_OPS)
end

function logistica.on_trashcan_change(pos, oldNode, oldMeta)
  on_node_change(pos, oldNode, oldMeta, TRASHCAN_OPS)
end

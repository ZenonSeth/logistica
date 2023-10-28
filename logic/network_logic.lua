local networks = {}
local HARD_NETWORK_NODE_LIMIT = 1000 -- A network cannot consist of more than this many nodes
local CREATE_NETWORK_STATUS_OK = 0
local CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK = -1
local CREATE_NETWORK_STATUS_TOO_MANY_NODES = -2

local adjecent = {
  vector.new( 1,  0,  0),
  vector.new( 0,  1,  0),
  vector.new( 0,  0,  1),
  vector.new(-1,  0,  0),
  vector.new( 0, -1,  0),
  vector.new( 0,  0, -1),
}

function logistica.get_network_name_or_nil(pos)
  local hash = minetest.hash_node_position(pos)
  for nHash, network in pairs(networks) do
    if hash == nHash then return network.name end
    if network.cables[hash] then return network.name end
    if network.machines[hash] then return network.name end
  end
  return nil
end

function logistica.get_network_or_nil(pos)
  local hash = minetest.hash_node_position(pos)
  for nHash, network in pairs(networks) do
    if hash == nHash then return network end
    if network.cables[hash] then return network end
    if network.machines[hash] then return network end
  end
  return nil
end

function logistica.get_network_id_or_nil(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return nil else return network.controller end
end

----------------------------------------------------------------
-- Network operation functions
----------------------------------------------------------------

local function dumb_remove_from_network(networkName, pos)
  local network = networks[networkName]
  if not network then return false end
  local hashedPos = minetest.hash_node_position(pos)
  if network.cables[hashedPos] then
    network.cables[hashedPos] = nil
    return true
  end
  if network.machines[hashedPos] then
    network.machines[hashedPos] = nil
    return true
  end
  if network.controller == hashedPos then
    networks[networkName] = nil -- removing the controller removes the whole network
    return true
  end
  return false
end

local function dumb_add_pos_to_network(networkName, pos)
  local network = networks[networkName]
  if not network then return false end
  local node = minetest.get_node(pos)
  local hashedPos = minetest.hash_node_position(pos)
  if logistica.is_cable(node.name) then
    network.cables[hashedPos] = true
  elseif logistica.is_machine(node.name) then
    network.machines[hashedPos] = true
  else -- can't dumb-add a controller to a network
    return false
  end
  return true
end

local function clear_network(networkName)
  local network = networks[networkName]
  if not network then return false end
  networks[networkName] = nil
end

local function break_cable(pos)
  local node = minetest.get_node_or_nil(pos)
  if node and logistica.is_cable(node.name) then
    logistica.swap_node(pos, node.name .. "_broken")
  end
end

local function recursive_scan_for_nodes_for_controller(network, positions, numScanned)
  if #positions <= 0 then return CREATE_NETWORK_STATUS_OK end
  if not numScanned then numScanned = #positions
  else numScanned = numScanned + #positions end

  if numScanned > HARD_NETWORK_NODE_LIMIT then
    return CREATE_NETWORK_STATUS_TOO_MANY_NODES
  end

  local connections = {}
  for _, pos in pairs(positions) do
    logistica.load_position(pos)
    local tiers = logistica.get_item_tiers(minetest.get_node(pos).name)
    local isAllTier = tiers[logistica.TIER_ALL] == true
    for _, offset in pairs(adjecent) do
      local otherPos = vector.add(pos, offset)
      logistica.load_position(otherPos)
      local otherHash = minetest.hash_node_position(otherPos)
      local tiersMatch = isAllTier
      if tiersMatch ~= true then
        local otherTiers = logistica.get_item_tiers(minetest.get_node(otherPos).name)
        tiersMatch = logistica.do_tiers_match(tiers, otherTiers)
      end
      if tiersMatch
        and network.controller ~= otherHash
        and network.machines[otherHash] == nil
        and network.cables[otherHash]  == nil then
        local otherNode = minetest.get_node(otherPos)
        if logistica.is_cable(otherNode.name) then
          local existingNetwork = logistica.get_network_id_or_nil(otherPos)
          if existingNetwork then
            return CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK
          else
            network.cables[otherHash] = true
            table.insert(connections, otherPos)
          end
        elseif logistica.is_demander(otherNode.name) then
          network.machines[otherHash] = true
          network.demanders[otherHash] = true
        elseif logistica.is_supplier(otherNode.name) then
          network.machines[otherHash] = true
          network.suppliers[otherHash] = true
        elseif logistica.is_storage(otherNode.name) then
          network.machines[otherHash] = true
          network.storage[otherHash] = true
        end
      end
    end -- end inner for loop
  end -- end outer for loop
  -- We have nested loops so we can do tail recursion
  return recursive_scan_for_nodes_for_controller(network, connections, numScanned)
end

local function add_network(controllerPosition)
  local node = minetest.get_node(controllerPosition)
  if not node.name:find("_controller") or not node.name:find("logistica:") then return false end
  local meta = minetest.get_meta(controllerPosition)
  local controllerHash = minetest.hash_node_position(controllerPosition)
  local network = {}
  local networkName = logistica.get_network_name_for(controllerPosition)
  networks[controllerHash] = network
  meta:set_string("infotext", "Controller of Network: "..networkName)
  network.controller = controllerHash
  network.name = networkName
  network.machines = {}
  network.cables = {}
  network.demanders = {}
  network.suppliers = {}
  network.storage = {}
  local status = recursive_scan_for_nodes_for_controller(network, {controllerPosition})
  local errorMsg = nil
  if status == CREATE_NETWORK_STATUS_FAIL_OTHER_NETWORK then
    errorMsg = "Cannot connect to already existing network!"
    logistica.swap_node(controllerPosition, node.name.."_disabled")
  elseif status == CREATE_NETWORK_STATUS_TOO_MANY_NODES then
    errorMsg = "Controller max nodes limit of "..HARD_NETWORK_NODE_LIMIT.." nodes per network exceeded!"
  end
  if errorMsg ~= nil then
    networks[controllerHash] = nil
    meta:set_string("infotext", "ERROR: "..errorMsg)
  end
end

----------------------------------------------------------------
-- worker functions for cable/machine/controllers
----------------------------------------------------------------

local function rescan_network(networkName)
  local network = networks[networkName]
  if not network then return false end
  if not network.controller then return false end
  local conHash = network.controller
  local controllerPosition = minetest.get_position_from_hash(conHash)
  clear_network(networkName)
  add_network(controllerPosition)
end

local function find_cable_connections(pos, node)
  local connections = {}
  for _, offset in pairs(adjecent) do
    local otherPos = vector.add(pos, offset)
    local otherNode = minetest.get_node_or_nil(otherPos)
    if otherNode then
      if otherNode.name == node.name then
        table.insert(connections, otherPos)
      elseif minetest.get_item_group(otherNode, logistica.GROUP_ALL) > 0 then
        table.insert(connections, otherPos)
      else -- check if adjecent node is a machine of same tier
        local nodeTiers = logistica.get_item_tiers(node.name)
        local otherTiers = logistica.get_item_tiers(otherNode.name)
        if logistica.do_tiers_match(nodeTiers, otherTiers) then
          table.insert(connections, otherPos)
        end
      end
    end
  end
  return connections
end

local function try_to_add_network(pos) 
  add_network(pos)
end

local function find_machine_connections(pos, node)

end

----------------------------------------------------------------
-- global namespaced functions
----------------------------------------------------------------

function logistica.on_cable_change(pos, oldNode)
  local node = oldNode or minetest.get_node(pos)
  local meta = minetest.get_meta(pos)
  local placed = (oldNode == nil) -- if oldNode is nil, we placed it

  local connections = find_cable_connections(pos, node)
  if not connections or #connections < 1 then return end -- nothing to update
  local networkEnd = #connections == 1

  if networkEnd then
    if not placed then -- removed a network end
      dumb_remove_from_network(pos)
    else
      local otherNode = minetest.get_node(connections[1])
      if logistica.is_cable(otherNode.name) or logistica.is_controller(otherNode.name) then
        local otherNetwork = logistica.get_network_id_or_nil(connections[1])
        if otherNetwork then
          dumb_add_pos_to_network(otherNetwork, pos)
        end
      end
    end
    return
  end

  -- We have more than 1 connected nodes - either cables or machines, something needs recalculating
  local connectedNetworks = {}
  for _, connectedPos in pairs(connections) do
    local otherNetwork = logistica.get_network_id_or_nil(connectedPos)
    if otherNetwork then
      connectedNetworks[otherNetwork] = true
    end
  end
  local firstNetwork = nil
  local numNetworks = 0
  for k,_ in pairs(connectedNetworks) do
    numNetworks = numNetworks + 1
    if firstNetwork == nil then firstNetwork = k end
  end
  if numNetworks <= 0 then return end -- still nothing to update
  if numNetworks == 1 then
    rescan_network(firstNetwork)
  else
    -- two or more connected networks (should only happen on place)
    -- this cable can't work here, break it, and nothing to update
    break_cable(pos)
  end
end

function logistica.on_controller_change(pos, oldNode)
  local node = oldNode or minetest.get_node(pos)
  local meta = minetest.get_meta(pos)
  local hashPos = minetest.hash_node_position(pos)
  local placed = (oldNode == nil) -- if oldNode is nil, we placed a new one
  if placed == true then
    try_to_add_network(pos)
  else
    clear_network(hashPos)
  end
end
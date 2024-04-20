local S = logistica.TRANSLATOR

local META_OWNER = "owner"
local META_LINKED_TRANSMITTER = "lnktr"
local META_LINKED_RECEIVERS = "lnkrcs"
local LINKED_RECEIVER_SEP = ";"
local MAX_LINKED_RECEIVERS = logistica.settings.max_receivers_per_transmitter

local WIRELESS_TRANSMITTER_MSG = S("Wireless Transmitter for Network: ")

-- stored in format {playerName = {positionHash = true, positionHash = true, ...}, ...}
local playerToTransmitterMap = {}

-- we need this because default tostring(number) function returns scientific representation which loses accuracy
local str = function(anInt) return string.format("%.0f", anInt) end

local p2h = minetest.hash_node_position
local h2p = minetest.get_position_from_hash

-- returns a list of positions(vectors), representing linked receivers
local function get_linked_receivers(transmitterPos, metaTable)
  local posStr = ""
  if metaTable and type(metaTable) == "table" and metaTable.fields and metaTable.fields[META_LINKED_RECEIVERS] then
    posStr = metaTable.fields[META_LINKED_RECEIVERS]
  else
    local meta = minetest.get_meta(transmitterPos)
    posStr = meta:get_string(META_LINKED_RECEIVERS)
  end
  return logistica.table_map(
    string.split(posStr, LINKED_RECEIVER_SEP),
    function(hash) return h2p(hash) end
  )
end

-- listOfReceiverPositions must be a list of positions (vectors)
local function set_linked_receivers(transmitterPos, listOfReceiverPositions)
  local rcsStr = table.concat(
    logistica.table_map(listOfReceiverPositions, function(position) return str(p2h(position)) end),
    LINKED_RECEIVER_SEP
  )
  local meta = minetest.get_meta(transmitterPos)
  meta:set_string(META_LINKED_RECEIVERS, rcsStr)
end

local function connect_receiver_to_transmitter(trPos, rcPos, rcMeta)
  local trHash = p2h(trPos)
  local connectedReceivers = get_linked_receivers(trPos)
  if #connectedReceivers + 1 > MAX_LINKED_RECEIVERS then return false end -- too many connections
  for _, pos in ipairs(connectedReceivers) do
    if vector.equals(rcPos, pos) then
      rcMeta:set_string(META_LINKED_TRANSMITTER, str(trHash)) -- still ensure this is selected in receiver
      return true
    end -- alrady in the list
  end
  table.insert(connectedReceivers, rcPos)
  set_linked_receivers(trPos, connectedReceivers)
  rcMeta:set_string(META_LINKED_TRANSMITTER, str(trHash))
  return true
end

local function disconnect_receiver_from_transmitter(trPos, rcPos)
  local connectedReceivers = get_linked_receivers(trPos)
  local idxToRem = 0
  for i, otherRcPos in ipairs(connectedReceivers) do
    if vector.equals(rcPos, otherRcPos) then idxToRem = i end
  end
  if idxToRem > 0 then
    table.remove(connectedReceivers, idxToRem)
  end
  set_linked_receivers(trPos, connectedReceivers)
end

local function disconnect_transmitter(trPos, metaTable)
  local connectedReceivers = get_linked_receivers(trPos, metaTable)
  for _, rcPos in pairs(connectedReceivers) do
    logistica.load_position(rcPos)
    local rcMeta = minetest.get_meta(rcPos)
    rcMeta:set_string(META_LINKED_TRANSMITTER, nil)
  end
  set_linked_receivers(trPos, {})
end

local function wifi_network_remove_transmitter_for_player(pos, optPlayerName)
  local playerName = optPlayerName
  if not playerName then
    local meta = minetest.get_meta(pos)
    playerName = meta:get_string(META_OWNER)
  end
  if not playerName or type(playerName) ~= "string" or playerName == "" then return end
  local listOfTrForPlayer = playerToTransmitterMap[playerName] or {}
  listOfTrForPlayer[p2h(pos)] = nil
  playerToTransmitterMap[playerName] = listOfTrForPlayer
end

--------------------------------
-- public
--------------------------------

-- place/remove transmitters and receivers

function logistica.wifi_network_after_place_transmitter(pos, playerName)
  if not playerName or type(playerName) ~= "string" or playerName == "" then return end
  local meta = minetest.get_meta(pos)
  meta:set_string(META_OWNER, playerName)
  logistica.wifi_network_register_transmitter_for_player(pos, playerName)
end

function logistica.wifi_network_after_place_receiver(pos, playerName)
  if not playerName or type(playerName) ~= "string" or playerName == "" then return end
  local meta = minetest.get_meta(pos)
  meta:set_string(META_OWNER, playerName)
end

function logistica.wifi_network_after_destroy_receiver(pos, metaDataTable)
  if type(metaDataTable) == "table" and metaDataTable.fields then
    local trHash = tonumber(metaDataTable.fields[META_LINKED_TRANSMITTER])
    if not trHash or trHash == "fail" then return end
    local trPos = h2p(trHash)
    disconnect_receiver_from_transmitter(trPos, pos)
  end
end

function logistica.wifi_network_after_destroy_transmitter(pos, metaDataTable)
  disconnect_transmitter(pos)
  if metaDataTable and metaDataTable.fields and metaDataTable.fields[META_OWNER] then
    wifi_network_remove_transmitter_for_player(pos, metaDataTable.fields[META_OWNER])
  end
end

-- other util functions

function logistica.wifi_network_register_transmitter_for_player(pos, optPlayerName)
  local playerName = optPlayerName
  if not playerName then
    local meta = minetest.get_meta(pos)
    playerName = meta:get_string(META_OWNER)
  end
  if not playerName or type(playerName) ~= "string" or playerName == "" then return end
  local listOfTrForPlayer = playerToTransmitterMap[playerName] or {}
  listOfTrForPlayer[p2h(pos)] = true
  playerToTransmitterMap[playerName] = listOfTrForPlayer
end

function logistica.wifi_network_disconect_receiver_from_current_transmitter(receiverPos)
  local rcNodeName = minetest.get_node(receiverPos).name
  if not logistica.GROUPS.wireless_receivers.is(rcNodeName) then return false end
  local trHash = minetest.get_meta(receiverPos):get_string(META_LINKED_TRANSMITTER)
  if trHash == "" then return end
  trHash = tonumber(trHash)
  if not trHash or trHash == "fail" then return end
  local trPos = h2p(trHash)
  disconnect_receiver_from_transmitter(trPos, receiverPos)
end

function logistica.wifi_network_disconnect_transmitter(transmitterPos)
  local trNodeName = minetest.get_node(transmitterPos).name
  if not logistica.GROUPS.wireless_transmitters.is(trNodeName) then return end
  disconnect_transmitter(transmitterPos, nil)
end

-- returns true/false if connecting receiver to transmitter succeeds/fails
function logistica.wifi_network_connect_receiver_to_transmitter(transmitterPos, receiverPos)
  local trNodeName = minetest.get_node(transmitterPos).name
  if not logistica.GROUPS.wireless_transmitters.is(trNodeName) then return false end
  local rcNodeName = minetest.get_node(receiverPos).name
  if not logistica.GROUPS.wireless_receivers.is(rcNodeName) then return false end

  local trMeta = minetest.get_meta(transmitterPos)
  local trOwner = trMeta:get_string(META_OWNER)
  local rcMeta = minetest.get_meta(receiverPos)
  local rcOwner = rcMeta:get_string(META_OWNER)
  if trOwner ~= rcOwner then return false end

  return connect_receiver_to_transmitter(transmitterPos, receiverPos, rcMeta)
end

-- returns a list of positions (as vectors) representing the connected receivers, or empty list if none
function logistica.wifi_network_get_connected_receivers_for_transmitter(pos)
  local node = minetest.get_node(pos)
  if not logistica.GROUPS.wireless_transmitters.is(node.name) then return {} end
  return get_linked_receivers(pos)
end

-- returns a vector of connected receiver position, or nil if there isn't one
function logistica.wifi_network_get_connected_transmitter_for_receiver(pos)
  local trHash = minetest.get_meta(pos):get_string(META_LINKED_TRANSMITTER)
  if trHash == "" then return nil end
  trHash = tonumber(trHash)
  if not trHash or trHash == "fail" then return nil end
  return h2p(trHash)
end

-- returns a list of tables, each one representing a transmitter in the format:
-- { pos = vector, networkId = networkId or nil }
-- returns an empty table if there are none
function logistica.wifi_network_get_available_transmitters_for_player(playerName)
  local transmitters = {}
  local i = 1
  for posHash, _ in pairs(playerToTransmitterMap[playerName] or {}) do
    local position = h2p(posHash)
    transmitters[i] = {
      pos = position,
      networkId = logistica.get_network_id_or_nil(position),
    }
    i = i + 1
  end
  return transmitters
end

function logistica.wifi_transmitter_set_infotext(pos, networkNameOrNil)
  local infotext
  if not networkNameOrNil or type(networkNameOrNil) ~= "string" then
    infotext = ""
  else
    infotext = WIRELESS_TRANSMITTER_MSG..(networkNameOrNil or "")
  end
  minetest.get_meta(pos):set_string("infotext", infotext)
end

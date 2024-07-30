local S = logistica.TRANSLATOR

local hyperspanner_desc = S("Hyperspanner\nUse on node to see which network it belongs to\nSneak + Use on node to see detailed network info")
local msg_no_connected_network = S("Node has no connected network!")
local ROW_WIDTH = 8
local ROW_HEIGHT = 0.5
local ROW_PADD = 0.3
local FORM_WIDTH = ROW_WIDTH + 2 * ROW_PADD
local FORMSPEC_NAME = "logistica_hypinf"

local NG = logistica.NETWORK_GROUPS
local GROUPS_TO_DISPLAY = {
  NG.cables,
  NG.wireless_transmitters,
  NG.wireless_receivers,
  NG.mass_storage,
  NG.item_storage,
  NG.suppliers,
  NG.injectors,
  NG.requesters,
  NG.reservoirs,
  NG.trashcans,
  NG.misc,
}

local function hyperspanner_basic_use(pos, player)
  local networkName = logistica.get_network_name_or_nil(pos)
  if networkName then
    networkName = S("Network")..": "..networkName
  else
    networkName = msg_no_connected_network
  end
  logistica.show_popup(
    player:get_player_name(),
    "("..pos.x..","..pos.y..","..pos.z..") "..networkName
  )
end

-- rowIndex should start at 0 for top row
local function make_count_row(y, text, count, rowIndex, useBool)
  local yPos = y + ROW_HEIGHT * rowIndex
  local txt = ""
  txt = txt.."image[0.1,"..(yPos + 0.5 * ROW_HEIGHT)..";"..(FORM_WIDTH - 0.2)..",0.03"..";logistica_divider.png]"
  txt = txt.."label["..ROW_PADD..","..yPos..";"..text.."]"
  if useBool then
    if count > 0 then count = "Yes" else count = "No" end
  end
  txt = txt.. "label["..(ROW_PADD + 6)..","..yPos..";"..count.."]"
  return txt
end

local function count_num_machines(network, groupName)
  local groupMachines = network[groupName]
  if not groupMachines or type(groupMachines) ~= "table" then return 0 end
  local count = 0
  for _, _ in pairs(groupMachines) do count = count + 1 end
  return count
end

local function get_counts_rows(network, startX, startY)
  local rows = {}
  local total = 0
  local index = 1
  for i, groupName in ipairs(GROUPS_TO_DISPLAY) do
    local isWirelessTransmitter = groupName == NG.wireless_transmitters
    local groupText = logistica.get_network_group_description(groupName)
    if isWirelessTransmitter then groupText = "Has Wireless Transmitter" end
    local count = count_num_machines(network, groupName)
    if groupName ~= NG.cables then total = total + count end
    rows[index] = make_count_row(startY, groupText, count, i, isWirelessTransmitter)
    index = index + 1
  end
  rows[index] = make_count_row(startY, "Total # of Machines", total, 0, false)
  return table.concat(rows)
end

local function get_network_info_formspec(network, player)
  return
  "formspec_version[4]"..
  "size["..FORM_WIDTH..",7.5]"..
  logistica.ui.background..
  "image_button_exit["..(FORM_WIDTH - 0.8)..",0.3;0.5,0.5;logistica_icon_cancel.png;;;false;false;]"..
  "label["..ROW_PADD..",0.5;"..S("Network info for")..": "..network.name.."]"..
  get_counts_rows(network, 0.3, 1.5)
  -- TODO: advanced listing of machines and positions --
  -- "label["..ROW_PADD..",6.3;Machine Locator And Info]"..
  -- "dropdown["..ROW_PADD..",6.5;3.9,0.8;;Controller,Mass Storages,Item Storages,Injectors,Requesters,Reservoirs,Trashcans,Wireless Receivers;1;false]"..
  -- "image["..ROW_PADD..",7.4;2,2;machine_img]"..
  -- "button["..ROW_PADD..",9.9;1,0.8;prev_machine;<]"..
  -- "button["..(ROW_PADD + 1)..",9.9;1,0.8;next_machine;>]"..
  -- "label["..(2 * ROW_PADD)..",9.7;101 / 128]"..
  -- "label["..(ROW_PADD + 2.1)..",7.6;Machine Name: Logistic Network Controller]"..
  -- "label["..(ROW_PADD + 2.1)..",8.1;Position: 4535\\, -2535\\, 2455]"..
  -- "label["..(ROW_PADD + 2.1)..",8.6;Approximate Distance: 4153]"
end

-- NOTE: For display purposes, this needs to be kept in sync with the logistica.NETWORK_GROUPS code
local function hyperspanner_advanced_use(pos, player)
  local network = logistica.get_network_or_nil(pos)
  if not network then
    logistica.show_popup(
      player:get_player_name(),
      "("..pos.x..","..pos.y..","..pos.z..") "..msg_no_connected_network
    )
  else
    minetest.show_formspec(player:get_player_name(), FORMSPEC_NAME, get_network_info_formspec(network, player))
  end
end

minetest.register_tool("logistica:hyperspanner",{
  description = hyperspanner_desc,
  short_description = hyperspanner_desc,
  inventory_image = "logistica_hyperspanner.png",
  wield_image = "logistica_hyperspanner.png",
  stack_max = 1,
  on_place = function(itemstack, placer, pointed_thing)
    local pos = pointed_thing.under
    if not placer or not pos or not placer:is_player() then return end
    local node = minetest.get_node_or_nil(pos)
    if not node or not (logistica.is_machine(node.name) or logistica.GROUPS.cables.is(node.name)) then return end
    if placer:get_player_control().sneak then
      hyperspanner_advanced_use(pos, placer)
    else
      hyperspanner_basic_use(pos, placer)
    end
  end
})



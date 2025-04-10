local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "accesspoint_formspec"
-- local LOCK_BTN = "on_off"
local NEXT_BTN = "next"
local PREV_BTN = "prev"
local FRST_BTN = "frst"
local LAST_BTN = "last"
local SEARCH_BTN = "search"
local CLEAR_BTN = "clear"
local FILTER_ALL_BTN = "filter_all"
local FILTER_NODES_BTN = "filter_blk"
local FILTER_CRFTITM_BTN = "filter_cft"
local FILTER_TOOLS_BTN = "filter_tol"
local FILTER_LIGHTS_BTN = "filter_lig"
local SORT_NAME_BTN = "sort_name"
local SORT_MOD_BTN = "sort_mod"
local SORT_COUNT_BTN = "sort_cnt"
local SORT_WEAR_BTN = "sort_wer"
local SEARCH_FIELD = "srch_fld"
local USE_META_BTN = "tgl_meta"
local LIQUID_NEXT_BTN = "liq_nxt"
local LIQUID_PREV_BTN = "liq_prv"

local INV_FAKE = "fake"
local INV_INSERT = "isert"
local INV_LIQUID = "liqd"
local FAKE_INV_W = 12
local FAKE_INV_H = 4
local FAKE_INV_SIZE = FAKE_INV_W * FAKE_INV_H

local IMG_HIGHLGIHT = "logistica_icon_highlight.png"
local IMG_BLANK = "logistica_blank.png"
local IMG_SORT_NAME = "logistica_icon_sort_name_az.png"
local IMG_SORT_MOD = "logistica_icon_sort_mod_az.png"
local IMG_SORT_COUNT = "logistica_icon_sort_count_99_1.png"
local IMG_SORT_WEAR = "logistica_icon_sort_wear_0_100.png"
local IMG_FILT_ALL = "logistica_icon_all.png"
local IMG_FILT_NODE = "logistica_icon_node.png"
local IMG_FILT_ITEM = "logistica_icon_craftitem.png"
local IMG_FILT_TOOL = "logistica_icon_tool.png"
local IMG_FILT_LIGHT = "logistica_icon_torch.png"

local STR_METADATA_DESC = S("Applies to Tools only:\nON = Differentiate items using metadata\nOFF = Group items only by name, ignore metadata")
local STR_ALL_DESC = S("Show All items")
local STR_NODES_DESC = S("Show Nodes only")
local STR_CRAFT_DESC = S("Show Craft items only")
local STR_TOOLS_DESC = S("Show Tools only")
local STR_LIGHT_DESC = S("Show Light sources only")
local STR_SERCH_DESC = S("Search by text\nUse group:some_group to find items belongong to some_group")
local STR_CLEAR_DESC = S("Clear search")

local detachedInventories = {}
local accessPointForms = {}

-- creates the inv and returns the inv name
local function get_or_create_detached_inventory(pos, playerName)
  local posHash = logistica.get_rand_string_for(pos)
  if detachedInventories[posHash] and detachedInventories[posHash][playerName] then
    return detachedInventories[posHash][playerName]
  end
  local invName = "Logistica_AP_"..posHash..playerName
  local inv = minetest.create_detached_inventory(invName, {
    allow_move = logistica.access_point_allow_move,
    allow_put = logistica.access_point_allow_put,
    allow_take = logistica.access_point_allow_take,
    on_move = logistica.access_point_on_inv_move,
    on_put = logistica.access_point_on_put,
    on_take = logistica.access_point_on_take,
  }, playerName)
  inv:set_size(INV_FAKE, FAKE_INV_SIZE)
  inv:set_size(INV_INSERT, 1)
  inv:set_size(INV_LIQUID, 1)
  if not detachedInventories[posHash] then detachedInventories[posHash] = {} end
  detachedInventories[posHash][playerName] = invName
  return invName
end

local function get_curr_pos(player)
    if not player or not player:is_player() then return end
  local playerName = player:get_player_name()
  if not accessPointForms[playerName] or not accessPointForms[playerName].position then return end
  return accessPointForms[playerName].position
end

----------------------------------------------------------------
-- formspec
----------------------------------------------------------------

local function get_listrings(invName) return
  "listring[current_player;main]"..
  "listring[detached:"..invName..";"..INV_INSERT.."]"..
  "listring[current_player;main]"..
  "listring[detached:"..invName..";"..INV_FAKE.."]"..
  "listring[current_player;main]"..
  "listring[current_player;craft]"..
  "listring[current_player;main]"..
  "listring[current_player;craftpreview]"..
  "listring[current_player;main]"..
  "listring[detached:"..invName..";"..INV_LIQUID.."]"
end

local function get_tooltips() return
    "tooltip["..USE_META_BTN..";"..STR_METADATA_DESC.."]"..
    "tooltip["..FILTER_ALL_BTN..";"..STR_ALL_DESC.."]"..
    "tooltip["..FILTER_NODES_BTN..";"..STR_NODES_DESC.."]"..
    "tooltip["..FILTER_CRFTITM_BTN..";"..STR_CRAFT_DESC.."]"..
    "tooltip["..FILTER_TOOLS_BTN..";"..STR_TOOLS_DESC.."]"..
    "tooltip["..FILTER_LIGHTS_BTN..";"..STR_LIGHT_DESC.."]"
end

local function get_filter_section(usesMetaStr, filterHighImg) return
    "button[1.4,5.2;2.6,0.6;"..USE_META_BTN..";"..usesMetaStr.."]"..
    "label[4.3,5.5;"..S("Filter").."]"..
    "image[5.1,5;1,1;"..filterHighImg.all.."]"..
    "image[6.0,5;1,1;"..filterHighImg.node.."]"..
    "image[6.9,5;1,1;"..filterHighImg.craftitem.."]"..
    "image[7.8,5;1,1;"..filterHighImg.tools.."]"..
    "image[8.7,5;1,1;"..filterHighImg.lights.."]"..
    "image_button[5.2,5.1;0.8,0.8;"..IMG_FILT_ALL..";"..FILTER_ALL_BTN..";;false;false;]"..
    "image_button[6.1,5.1;0.8,0.8;"..IMG_FILT_NODE..";"..FILTER_NODES_BTN..";;false;false;]"..
    "image_button[7.0,5.1;0.8,0.8;"..IMG_FILT_ITEM..";"..FILTER_CRFTITM_BTN..";;false;false;]"..
    "image_button[7.9,5.1;0.8,0.8;"..IMG_FILT_TOOL..";"..FILTER_TOOLS_BTN..";;false;false;]"..
    "image_button[8.8,5.1;0.8,0.8;"..IMG_FILT_LIGHT..";"..FILTER_LIGHTS_BTN..";;false;false;]"
end

local function get_sort_section(sortHighImg) return
  "label[10.4,5.5;"..S("Sort").."]"..
  "image[11.0,5;1,1;"..sortHighImg.name.."]"..
  "image[11.9,5;1,1;"..sortHighImg.mod.."]"..
  "image[12.8,5;1,1;"..sortHighImg.count.."]"..
  "image[13.7,5;1,1;"..sortHighImg.wear.."]"..
  "image_button[11.1,5.1;0.8,0.8;"..IMG_SORT_NAME..";"..SORT_NAME_BTN..";;false;false;]"..
  "image_button[12.0,5.1;0.8,0.8;"..IMG_SORT_MOD..";"..SORT_MOD_BTN..";;false;false;]"..
  "image_button[12.9,5.1;0.8,0.8;"..IMG_SORT_COUNT..";"..SORT_COUNT_BTN..";;false;false;]"..
  "image_button[13.8,5.1;0.8,0.8;"..IMG_SORT_WEAR..";"..SORT_WEAR_BTN..";;false;false;]"
end

local function get_search_and_page_section(searchTerm, pageInfo) return
  "field[5.2,6.5;2.8,0.8;"..SEARCH_FIELD..";;"..searchTerm.."]"..
  "field_close_on_enter["..SEARCH_FIELD..";false]"..
  "image_button[8.1,6.5;0.8,0.8;logistica_icon_search.png;"..SEARCH_BTN..";;false;false;]"..
  "image_button[9.2,6.5;0.8,0.8;logistica_icon_cancel.png;"..CLEAR_BTN..";;false;false;]"..
  "tooltip["..SEARCH_BTN..";"..STR_SERCH_DESC .."]"..
  "tooltip["..CLEAR_BTN..";"..STR_CLEAR_DESC.."]"..
  "label[12.0,6.3;"..S("Page")..": "..pageInfo.curr.." / "..pageInfo.max.."]"..
  "image_button[10.6,6.5;0.8,0.8;logistica_icon_first.png;"..FRST_BTN..";;false;false;]"..
  "image_button[11.7,6.5;0.8,0.8;logistica_icon_prev.png;"..PREV_BTN..";;false;false;]"..
  "image_button[12.8,6.5;0.8,0.8;logistica_icon_next.png;"..NEXT_BTN..";;false;false;]"..
  "image_button[13.9,6.5;0.8,0.8;logistica_icon_last.png;"..LAST_BTN..";;false;false;]"
end

local function get_liquid_section(invName, meta, playerName)
  local currInfo = logistica.access_point_get_current_liquid_display_info(meta, playerName)

  return
    "list[detached:"..invName..";"..INV_LIQUID..";0.95,7.1;1,1;0]"..
    "image[1.05,5.8;0.8,0.8;"..currInfo.texture.."]"..
    "label[0.75,6.9;"..currInfo.description.." "..currInfo.capacity.."]"..
    "image_button[0.45,5.8;0.6,0.8;logistica_icon_prev.png;"..LIQUID_PREV_BTN..";;false;false]"..
    "image_button[1.85,5.8;0.6,0.8;logistica_icon_next.png;"..LIQUID_NEXT_BTN..";;false;false]"
end

local function get_error_display(x, y, errorMsg)
  local img = "" ; if errorMsg and errorMsg ~= "" then img = "logistica_disabled.png" end
  return 
    "image["..x..","..(y - 0.2)..";0.4,0.4;"..img.."]"..
    "label["..(x + 0.5)..","..y..";"..errorMsg.."]"
end

local function get_access_point_formspec(pos, invName, optMeta, playerName, optError)
  if not optError then optError = "" end
  --local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local meta = optMeta or minetest.get_meta(pos)
  local currentNetwork = logistica.get_network_name_or_nil(pos) or S("<NONE>")
  local filterHighImg = logistica.access_point_get_filter_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
  local sortHighImg = logistica.access_point_get_sort_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
  local pageInfo = logistica.access_point_get_current_page_info(pos, playerName, FAKE_INV_SIZE, meta)
  local usesMetadata = logistica.access_point_is_set_to_use_metadata(pos)
  local searchTerm = minetest.formspec_escape(logistica.access_point_get_current_search_term(meta))
  local usesMetaStr = usesMetadata and S("Metadata: ON") or S("Metadata: OFF")
  return "formspec_version[4]"..
    "size["..logistica.inv_size(15.2, 13.25).."]" ..
    logistica.ui.background..
    "list[detached:"..invName..";"..INV_FAKE..";0.2,0.2;"..FAKE_INV_W..","..FAKE_INV_H..";0]"..
    "image[3.2,6.5;0.8,0.8;logistica_icon_input.png]"..
    "list[detached:"..invName..";"..INV_INSERT..";4.0,6.4;1,1;0]"..
    get_error_display(5.2, 7.6, optError)..
    logistica.player_inv_formspec(5.2, 8.0)..
    "label[1.4,12.7;"..S("Crafting").."]"..
    "list[current_player;craft;0.2,9.0;3,3;]"..
    "list[current_player;craftpreview;3.9,9.0;1,1;]"..
    get_liquid_section(invName, meta, playerName)..
    get_listrings(invName)..
    get_filter_section(usesMetaStr, filterHighImg)..
    get_tooltips()..
    get_sort_section(sortHighImg)..
    "label[5.3,6.3;"..S("Network: ")..currentNetwork.."]"..
    get_search_and_page_section(searchTerm, pageInfo)
end

local function show_access_point_formspec(pos, playerName, optError)
  if minetest.get_modpath("mcl_core") then
    local player = minetest.get_player_by_name(playerName)
    if not player then return end
    local inv = player:get_inventory()
    if inv then
      inv:set_width("craft", 3)
      inv:set_size("craft", 9)
    end
  end
  local meta = minetest.get_meta(pos)
  local invName = get_or_create_detached_inventory(pos, playerName)
  accessPointForms[playerName] = {
    position = pos,
    invName = invName,
  }
  logistica.access_point_refresh_fake_inv(pos, invName, INV_FAKE, FAKE_INV_SIZE, playerName)
  logistica.access_point_refresh_liquids(pos, playerName)
  minetest.show_formspec(
    playerName,
    FORMSPEC_NAME,
    get_access_point_formspec(pos, invName, meta, playerName, optError and S("Error: ")..optError or "")
  )
end

local function give_to_player(player, stack)
  local inv = player:get_inventory()
  local leftover = inv:add_item("main", stack)
  if leftover and not leftover:is_empty() then
    minetest.item_drop(leftover, player, player:get_pos())
  end
end

----------------------------------------------------------------
-- callbacks
----------------------------------------------------------------

function logistica.on_receive_access_point_formspec(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  if not accessPointForms[playerName] then return true end
  local pos = accessPointForms[playerName].position
  if not pos or minetest.is_protected(pos, playerName) then return true end

  if fields.quit and not fields.key_enter_field then
    return true
  elseif fields[FRST_BTN] then
    if not logistica.access_point_change_page(pos, -2, playerName, FAKE_INV_SIZE) then return true end
  elseif fields[PREV_BTN] then
    if not logistica.access_point_change_page(pos, -1, playerName, FAKE_INV_SIZE) then return true end
  elseif fields[NEXT_BTN] then
    if not logistica.access_point_change_page(pos, 1, playerName, FAKE_INV_SIZE) then return true end
  elseif fields[LAST_BTN] then
    if not logistica.access_point_change_page(pos, 2, playerName, FAKE_INV_SIZE) then return true end
  elseif fields[USE_META_BTN] then
    logistica.access_point_toggle_use_metadata(pos)
  elseif fields[FILTER_ALL_BTN] then
    logistica.access_point_set_filter_method(pos, playerName, 1)
  elseif fields[FILTER_NODES_BTN] then
    logistica.access_point_set_filter_method(pos, playerName, 2)
  elseif fields[FILTER_CRFTITM_BTN] then
    logistica.access_point_set_filter_method(pos, playerName, 3)
  elseif fields[FILTER_TOOLS_BTN] then
    logistica.access_point_set_filter_method(pos, playerName, 4)
  elseif fields[FILTER_LIGHTS_BTN] then
    logistica.access_point_set_filter_method(pos, playerName, 5)
  elseif fields[SORT_NAME_BTN] then
    logistica.access_point_set_sort_method(pos, playerName, 1)
  elseif fields[SORT_MOD_BTN] then
    logistica.access_point_set_sort_method(pos, playerName, 2)
  elseif fields[SORT_COUNT_BTN] then
    logistica.access_point_set_sort_method(pos, playerName, 3)
  elseif fields[SORT_WEAR_BTN] then
    logistica.access_point_set_sort_method(pos, playerName, 4)
  elseif fields[CLEAR_BTN] then
    logistica.access_point_on_search_clear(pos)
  elseif fields[SEARCH_BTN] or fields.key_enter_field then
    logistica.access_point_on_search_change(pos, fields[SEARCH_FIELD])
  elseif fields[LIQUID_PREV_BTN] then
    if not logistica.access_point_change_liquid(minetest.get_meta(pos),-1, playerName) then return true end
  elseif fields[LIQUID_NEXT_BTN] then
    if not logistica.access_point_change_liquid(minetest.get_meta(pos), 1, playerName) then return true end
  end
  show_access_point_formspec(pos, playerName)
  return true
end

function logistica.access_point_after_place(pos, meta)
  meta:set_string("infotext", S("Access Point"))
end

function logistica.access_point_allow_put(inv, listname, index, stack, player)
  if listname == INV_FAKE then return 0 end

  local pos = get_curr_pos(player)
  if not pos then return 0 end
  if not logistica.get_network_or_nil(pos) then return 0 end
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end

  if listname == INV_LIQUID then
    if logistica.reservoir_is_known_bucket(stack:get_name()) then
      local currStack = inv:get_stack(listname, index)
      if currStack:is_empty() then return 1 else return 0 end
    else return 0 end
  end

  return stack:get_count()
end

function logistica.access_point_allow_take(inv, listname, index, _stack, player)
  local stack = ItemStack(_stack)
  local pos = get_curr_pos(player)
  if not pos then return 0 end
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end

  logistica.load_position(pos)
  if listname == INV_FAKE then
    local network = logistica.get_network_or_nil(pos)
    if not network then
      show_access_point_formspec(pos, player:get_player_name())
      return 0
    end
    local stackMax = stack:get_stack_max()
    -- either way, only allow taking up to stack max
    stack:set_count(math.min(stack:get_count(), stackMax))
    if stackMax > 1 then
      local taken = ItemStack("")
      local acceptTaken = function(st) taken:add_item(st); return 0 end

      local takeResult = logistica.take_stack_from_network(stack, network, acceptTaken, false, false, true)
      local error = nil ; if not takeResult.success then error = takeResult.error end

      if not taken or taken:is_empty() then
        show_access_point_formspec(pos, player:get_player_name(), error)
        return 0
      end
      -- remove the sometimes manually added count display - and set the stack in the inventory slot
      taken:get_meta():set_string("count_meta", nil)
      inv:set_stack(listname, index, taken)
      return math.min(taken:get_count(), stackMax)
    else -- individual items are trickier 
      -- we want to take the actual item, so place it in the slot before its taken
      local useMetadata = logistica.access_point_is_set_to_use_metadata(pos)
      local taken = nil
      local acceptTaken = function(st) taken = st; return 0 end

      -- for the rare case where two items got stacked despite using metadata
      local takeResult = logistica.take_stack_from_network(stack, network, acceptTaken, false, useMetadata, true)
      local error = nil ; if not takeResult.success then error = takeResult.error end

      if not taken or taken:is_empty() then
        show_access_point_formspec(pos, player:get_player_name(), error)
        return 0
      end
      -- remove the sometimes manually added count display - and set the stack in the inventory slot
      taken:get_meta():set_string("count_meta", nil)
      inv:set_stack(listname, index, taken)
      return taken:get_count()
    end
  end
  return stack:get_count()
end

function logistica.access_point_allow_move(inv, from_list, from_index, to_list, to_index, count, player)
  if from_list == INV_FAKE or to_list == INV_FAKE then return 0 end
  if to_list == INV_INSERT then return 0 end
  if to_list == INV_LIQUID then return 0 end
  return count
end

function logistica.access_point_on_inv_move(inv, from_list, from_index, to_list, to_index, count, player)
end

function logistica.access_point_on_put(inv, listname, index, stack, player)
  local pos = get_curr_pos(player)
  if not pos then return 0 end
  logistica.load_position(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    show_access_point_formspec(pos, player:get_player_name(), S("Access Point not connected to any network"))
    return
  end
  if listname == INV_INSERT then
    local stackToAdd = inv:get_stack(listname, index)
    local leftover = logistica.insert_item_in_network(stackToAdd, networkId, false, false, false, false, true)
    stack:set_count(leftover)
    local error = nil
    if not stack:is_empty() then
      give_to_player(player, stack)
      error = S("Not enough space or allocated mass storage slots in network for item")
    end
    inv:set_stack(listname, index, ItemStack(""))
    show_access_point_formspec(pos, player:get_player_name(), error)
  elseif listname == INV_LIQUID then
    local currLiquid = logistica.access_point_get_current_liquid_name(minetest.get_meta(pos), player:get_player_name())
    local newStack = logistica.use_bucket_for_liquid_in_network(pos, stack, currLiquid)
    if newStack then
      inv:set_stack(listname, index, newStack)
      show_access_point_formspec(pos, player:get_player_name())
    end
  end
end

function logistica.access_point_on_take(inv, listname, index, stack, player)
  if listname == INV_FAKE then
    local pos = get_curr_pos(player)
    if not pos then return 0 end
    local network = logistica.get_network_or_nil(pos)
    if not network then return 0 end -- this isn't good, but nothing we can do at this point unforunately

    local acceptTaken = function(st) return 0 end
    logistica.load_position(pos)
    if stack:get_stack_max() > 1 then
      logistica.take_stack_from_network(stack, network, acceptTaken, false, false, false)
    else
      -- we want to take the actual item, with exact metadata, always
      -- because the allow_take method should have placed the exact item in the slot already
      logistica.take_stack_from_network(stack, network, acceptTaken, false, true, false)
    end
    -- refresh the page in case we had to swap out a fake item or a stack is gone
    show_access_point_formspec(pos, player:get_player_name())
  end
  -- remove the sometimes manually added count display
  stack:get_meta():set_string("count_meta", nil)
  stack:set_count(stack:get_count())
end

function logistica.access_point_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
  logistica.try_to_wake_up_network(pos)
  show_access_point_formspec(pos, clicker:get_player_name())
end

function logistica.access_point_on_player_leave(playerName)
  local info = accessPointForms[playerName]
  if info and info.invName then
    local onlyRef = true
    for _, otherInfo in pairs(accessPointForms) do
      if otherInfo.invName == info.invName then onlyRef = false end
    end
    if onlyRef then
      local toRemForPlayer = {}
      for posHash, tbl in pairs(detachedInventories) do
        if tbl[playerName] then
          toRemForPlayer[posHash] = true
          minetest.remove_detached_inventory(info.invName)
        end
      end
      for posHash, _ in pairs(toRemForPlayer) do
        detachedInventories[posHash][playerName] = nil
      end
    end
  end
  accessPointForms[playerName] = nil
  logistica.access_point_on_player_close(playerName)
end

function logistica.access_point_on_dug(pos)
  local removeForPlayers = {}
  local i =0
  for playerName, info in pairs(accessPointForms) do
    if info.position and vector.equals(pos, info.position) then
      i = i + 1
      removeForPlayers[i] = playerName
    end
  end
  for _, playerName in ipairs(removeForPlayers) do
    logistica.access_point_on_player_leave(playerName)
  end
end

function logistica.access_point_is_player_using_ap(playerName)
  return accessPointForms[playerName] ~= nil
end

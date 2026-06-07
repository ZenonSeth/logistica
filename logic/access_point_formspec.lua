local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "accesspoint_formspec"
local TAB_BTN = "ap_tab"
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
local STOR_PREV_BTN = "stor_prev"
local STOR_NEXT_BTN = "stor_next"

local INV_FAKE = "fake"
local INV_INSERT = "isert"
local INV_LIQUID = "liqd"
local INV_STOR_FILTER = "stor_filter"
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

-- height added at the top for the tab header row
local TAB_Y = 0.8
local AP_FORM_H = 14.05   -- 13.25 + TAB_Y
local AP_PLAYER_INV_X = 5.2
local AP_PLAYER_INV_Y = 8.8  -- 8.0 + TAB_Y

local STOR_PER_PAGE = 2
local STOR_BLOCK_H  = 3.0   -- vertical space per mass-storage block
local STOR_START_Y  = 1.75  -- y where first block begins

local detachedInventories = {}
local accessPointForms = {}
-- per-player detached inventories mirroring the visible mass-storage filter slots
local storFilterInventories = {}  -- [playerName] = invName

local function get_or_create_storage_filter_inv(playerName)
  if storFilterInventories[playerName] then
    return storFilterInventories[playerName]
  end
  local invName = "Logistica_AP_SF_"..playerName
  local inv = minetest.create_detached_inventory(invName, {
    allow_move = function() return 0 end,
    on_move    = function() end,
    allow_put  = function(sinv, listname, index, stack, player)
      local pName = player:get_player_name()
      if pName ~= playerName then return 0 end
      local data = accessPointForms[pName]
      if not data or not data.storMapping then return 0 end
      local mapping = data.storMapping[index]
      if not mapping then return 0 end
      local msPos, msSlot = mapping.pos, mapping.slot
      if minetest.is_protected(msPos, pName) then return 0 end
      if stack:get_stack_max() == 1 then return 0 end  -- tools not assignable
      logistica.load_position(msPos)
      local msInv = minetest.get_meta(msPos):get_inventory()
      if not msInv:get_stack("storage", msSlot):is_empty() then return 0 end
      local copy = ItemStack(stack:get_name())
      copy:set_count(1)
      msInv:set_stack("filter", msSlot, copy)
      sinv:set_stack(listname, index, copy)
      logistica.update_cache_at_pos(msPos, LOG_CACHE_MASS_STORAGE)
      return 0
    end,
    allow_take = function(sinv, listname, index, stack, player)
      local pName = player:get_player_name()
      if pName ~= playerName then return 0 end
      local data = accessPointForms[pName]
      if not data or not data.storMapping then return 0 end
      local mapping = data.storMapping[index]
      if not mapping then return 0 end
      local msPos, msSlot = mapping.pos, mapping.slot
      if minetest.is_protected(msPos, pName) then return 0 end
      logistica.load_position(msPos)
      local msInv = minetest.get_meta(msPos):get_inventory()
      if not msInv:get_stack("storage", msSlot):is_empty() then return 0 end
      msInv:set_stack("filter", msSlot, ItemStack(""))
      sinv:set_stack(listname, index, ItemStack(""))
      logistica.update_cache_at_pos(msPos, LOG_CACHE_MASS_STORAGE)
      return 0
    end,
    on_put  = function() end,
    on_take = function() end,
  }, playerName)
  inv:set_size(INV_STOR_FILTER, STOR_PER_PAGE * 8)
  storFilterInventories[playerName] = invName
  return invName
end

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
-- formspec helpers (items tab) -- all accept yOff so they can be
-- shifted down by TAB_Y without duplicating coordinate literals
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

local function get_filter_section(usesMetaStr, filterHighImg, yOff) return
    "button[1.4,"..(5.2+yOff)..";2.6,0.6;"..USE_META_BTN..";"..usesMetaStr.."]"..
    "label[4.3,"..(5.5+yOff)..";"..S("Filter").."]"..
    "image[5.1,"..(5.0+yOff)..";1,1;"..filterHighImg.all.."]"..
    "image[6.0,"..(5.0+yOff)..";1,1;"..filterHighImg.node.."]"..
    "image[6.9,"..(5.0+yOff)..";1,1;"..filterHighImg.craftitem.."]"..
    "image[7.8,"..(5.0+yOff)..";1,1;"..filterHighImg.tools.."]"..
    "image[8.7,"..(5.0+yOff)..";1,1;"..filterHighImg.lights.."]"..
    "image_button[5.2,"..(5.1+yOff)..";0.8,0.8;"..IMG_FILT_ALL..";"..FILTER_ALL_BTN..";;false;false;]"..
    "image_button[6.1,"..(5.1+yOff)..";0.8,0.8;"..IMG_FILT_NODE..";"..FILTER_NODES_BTN..";;false;false;]"..
    "image_button[7.0,"..(5.1+yOff)..";0.8,0.8;"..IMG_FILT_ITEM..";"..FILTER_CRFTITM_BTN..";;false;false;]"..
    "image_button[7.9,"..(5.1+yOff)..";0.8,0.8;"..IMG_FILT_TOOL..";"..FILTER_TOOLS_BTN..";;false;false;]"..
    "image_button[8.8,"..(5.1+yOff)..";0.8,0.8;"..IMG_FILT_LIGHT..";"..FILTER_LIGHTS_BTN..";;false;false;]"
end

local function get_sort_section(sortHighImg, yOff) return
  "label[10.4,"..(5.5+yOff)..";"..S("Sort").."]"..
  "image[11.0,"..(5.0+yOff)..";1,1;"..sortHighImg.name.."]"..
  "image[11.9,"..(5.0+yOff)..";1,1;"..sortHighImg.mod.."]"..
  "image[12.8,"..(5.0+yOff)..";1,1;"..sortHighImg.count.."]"..
  "image[13.7,"..(5.0+yOff)..";1,1;"..sortHighImg.wear.."]"..
  "image_button[11.1,"..(5.1+yOff)..";0.8,0.8;"..IMG_SORT_NAME..";"..SORT_NAME_BTN..";;false;false;]"..
  "image_button[12.0,"..(5.1+yOff)..";0.8,0.8;"..IMG_SORT_MOD..";"..SORT_MOD_BTN..";;false;false;]"..
  "image_button[12.9,"..(5.1+yOff)..";0.8,0.8;"..IMG_SORT_COUNT..";"..SORT_COUNT_BTN..";;false;false;]"..
  "image_button[13.8,"..(5.1+yOff)..";0.8,0.8;"..IMG_SORT_WEAR..";"..SORT_WEAR_BTN..";;false;false;]"
end

local function get_search_and_page_section(searchTerm, pageInfo, yOff) return
  "field[5.2,"..(6.5+yOff)..";2.8,0.8;"..SEARCH_FIELD..";;"..searchTerm.."]"..
  "field_close_on_enter["..SEARCH_FIELD..";false]"..
  "image_button[8.1,"..(6.5+yOff)..";0.8,0.8;logistica_icon_search.png;"..SEARCH_BTN..";;false;false;]"..
  "image_button[9.2,"..(6.5+yOff)..";0.8,0.8;logistica_icon_cancel.png;"..CLEAR_BTN..";;false;false;]"..
  "tooltip["..SEARCH_BTN..";"..STR_SERCH_DESC .."]"..
  "tooltip["..CLEAR_BTN..";"..STR_CLEAR_DESC.."]"..
  "label[12.0,"..(6.3+yOff)..";"..S("Page")..": "..pageInfo.curr.." / "..pageInfo.max.."]"..
  "image_button[10.6,"..(6.5+yOff)..";0.8,0.8;logistica_icon_first.png;"..FRST_BTN..";;false;false;]"..
  "image_button[11.7,"..(6.5+yOff)..";0.8,0.8;logistica_icon_prev.png;"..PREV_BTN..";;false;false;]"..
  "image_button[12.8,"..(6.5+yOff)..";0.8,0.8;logistica_icon_next.png;"..NEXT_BTN..";;false;false;]"..
  "image_button[13.9,"..(6.5+yOff)..";0.8,0.8;logistica_icon_last.png;"..LAST_BTN..";;false;false;]"
end

local function get_liquid_section(invName, meta, playerName, yOff)
  local currInfo = logistica.access_point_get_current_liquid_display_info(meta, playerName)
  return
    "list[detached:"..invName..";"..INV_LIQUID..";0.95,"..(7.1+yOff)..";1,1;0]"..
    "image[1.05,"..(5.8+yOff)..";0.8,0.8;"..currInfo.texture.."]"..
    "label[0.75,"..(6.9+yOff)..";"..currInfo.description.." "..currInfo.capacity.."]"..
    "image_button[0.45,"..(5.8+yOff)..";0.6,0.8;logistica_icon_prev.png;"..LIQUID_PREV_BTN..";;false;false]"..
    "image_button[1.85,"..(5.8+yOff)..";0.6,0.8;logistica_icon_next.png;"..LIQUID_NEXT_BTN..";;false;false]"
end

local function get_error_display(x, y, errorMsg)
  local img = "" ; if errorMsg and errorMsg ~= "" then img = "logistica_disabled.png" end
  return
    "image["..x..","..(y - 0.2)..";0.4,0.4;"..img.."]"..
    "label["..(x + 0.5)..","..y..";"..errorMsg.."]"
end

----------------------------------------------------------------
-- storage tab
----------------------------------------------------------------

local function get_sorted_mass_storage_list(network)
  local list = {}
  for hash, _ in pairs(network.mass_storage) do
    table.insert(list, minetest.get_position_from_hash(hash))
  end
  table.sort(list, function(a, b)
    if a.x ~= b.x then return a.x < b.x end
    if a.y ~= b.y then return a.y < b.y end
    return a.z < b.z
  end)
  return list
end

local function get_storage_tab_content(pos, playerName)
  local data = accessPointForms[playerName]
  local sfInvName = data.storFilterInvName
  local sfInv = minetest.get_inventory({type = "detached", name = sfInvName})

  local result =
    "label[0.2,0.5;"..S("Mass Storage Management").."]"..
    "label[0.2,0.85;"..S("Allocate an empty slot by dragging an item in it").."]"..
    "label[0.2,1.2;"..S("De-allocate a slot (only if there's 0 items stored) by removing the item from that slot").."]"..
    "image_button[9.8,7.8;0.8,0.8;logistica_icon_prev.png;"..STOR_PREV_BTN..";;false;false;]"..
    "image_button[13.4,7.8;0.8,0.8;logistica_icon_next.png;"..STOR_NEXT_BTN..";;false;false;]"

  local network = logistica.get_network_or_nil(pos)
  if not network then
    return result.."label[0.2,2.0;"..S("No network connected.").."]"
  end

  local storages = get_sorted_mass_storage_list(network)
  local totalPages = math.max(1, math.ceil(#storages / STOR_PER_PAGE))
  local page = logistica.clamp(data.storPage or 1, 1, totalPages)
  data.storPage = page

  result = result.."label[11.25,8.2;"..S("Page").." "..page.." / "..totalPages.."]"

  -- clear all mirror slots before repopulating
  if sfInv then
    for i = 1, STOR_PER_PAGE * 8 do
      sfInv:set_stack(INV_STOR_FILTER, i, ItemStack(""))
    end
  end
  data.storMapping = {}

  if #storages == 0 then
    return result.."label[0.2,2.0;"..S("No Mass Storages on this network.").."]"
  end

  local startIdx = (page - 1) * STOR_PER_PAGE + 1
  local y = STOR_START_Y

  for i = startIdx, math.min(startIdx + STOR_PER_PAGE - 1, #storages) do
    local msPos = storages[i]
    logistica.load_position(msPos)
    local msNode = minetest.get_node(msPos)
    local msDef = minetest.registered_nodes[msNode.name]
    local msDesc = (msDef and msDef.description) or msNode.name
    msDesc = msDesc:match("^([^\n]+)") or msDesc
    local maxSize = logistica.get_mass_storage_max_size(msPos)
    local msInv   = minetest.get_meta(msPos):get_inventory()

    -- slot offset within the detached filter inv for this storage (0-based for formspec)
    local invOffset = (i - startIdx) * 8

    -- mirror filter slots into the detached inv and build the slot mapping
    for slot = 1, 8 do
      local sfSlot = invOffset + slot  -- 1-indexed in the detached inv
      if sfInv then
        sfInv:set_stack(INV_STOR_FILTER, sfSlot, msInv:get_stack("filter", slot))
      end
      data.storMapping[sfSlot] = {pos = msPos, slot = slot}
    end

    -- name and position labels above the filter slots
    result = result..
      "label[1.4,"..(y + 0.25)..";"..minetest.formspec_escape(msDesc).."]"..
      "label[1.4,"..(y + 0.65)..";"..
        "@ "..msPos.x..", "..msPos.y..", "..msPos.z..
        "  |  "..S("Slot cap: ")..maxSize.."]"

    -- filter slots from the detached mirror inv
    local slotsY = y + 1.05
    result = result..
      "list[detached:"..sfInvName..";"..INV_STOR_FILTER..";1.45,"..slotsY..";8,1;"..invOffset.."]"

    -- per-slot stored-count labels: show count whenever filter is assigned (even 0)
    local countY = slotsY + 1.33
    for slot = 1, 8 do
      if not msInv:get_stack("filter", slot):is_empty() then
        local count = msInv:get_stack("storage", slot):get_count()
        local lx = 1.45 + (slot - 1) * 1.25 + 0.3
        result = result.."label["..lx..","..countY..";"..count.."]"
      end
    end

    y = y + STOR_BLOCK_H
  end

  return result
end

----------------------------------------------------------------
-- main formspec builder
----------------------------------------------------------------

local function get_access_point_formspec(pos, invName, optMeta, playerName, optError, tab)
  if not optError then optError = "" end
  if not tab then tab = 1 end
  local meta = optMeta or minetest.get_meta(pos)
  local currentNetwork = logistica.get_network_name_or_nil(pos) or S("<NONE>")

  local tabHeader =
    "tabheader[0,0;"..TAB_BTN..";"..S(" Main ")..","..S("Mass Storage")..";"..tab..";false;true]"

  local topContent
  if tab == 2 then
    topContent = get_storage_tab_content(pos, playerName)
  else
    local filterHighImg = logistica.access_point_get_filter_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
    local sortHighImg = logistica.access_point_get_sort_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
    local pageInfo = logistica.access_point_get_current_page_info(pos, playerName, FAKE_INV_SIZE, meta)
    local usesMetadata = logistica.access_point_is_set_to_use_metadata(pos)
    local searchTerm = minetest.formspec_escape(logistica.access_point_get_current_search_term(meta))
    local usesMetaStr = usesMetadata and S("Metadata: ON") or S("Metadata: OFF")
    topContent =
      "list[detached:"..invName..";"..INV_FAKE..";0.2,"..(0.2+TAB_Y)..";"..FAKE_INV_W..","..FAKE_INV_H..";0]"..
      "image[3.2,"..(6.5+TAB_Y)..";0.8,0.8;logistica_icon_input.png]"..
      "list[detached:"..invName..";"..INV_INSERT..";4.0,"..(6.4+TAB_Y)..";1,1;0]"..
      get_error_display(5.2, 7.6+TAB_Y, optError)..
      get_liquid_section(invName, meta, playerName, TAB_Y)..
      get_listrings(invName)..
      get_filter_section(usesMetaStr, filterHighImg, TAB_Y)..
      get_tooltips()..
      get_sort_section(sortHighImg, TAB_Y)..
      "label[5.3,"..(6.3+TAB_Y)..";"..S("Network: ")..currentNetwork.."]"..
      get_search_and_page_section(searchTerm, pageInfo, TAB_Y)
  end

  return "formspec_version[4]"..
    "size["..logistica.inv_size(15.2, AP_FORM_H).."]"..
    logistica.ui.background..
    tabHeader..
    topContent..
    logistica.player_inv_formspec(AP_PLAYER_INV_X, AP_PLAYER_INV_Y)..
    "label[1.4,"..(12.7+TAB_Y)..";"..S("Crafting").."]"..
    "list[current_player;craft;0.2,"..(9.0+TAB_Y)..";3,3;]"..
    "list[current_player;craftpreview;3.9,"..(9.0+TAB_Y)..";1,1;]"
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

  -- preserve tab and storage page across re-shows
  local prev = accessPointForms[playerName] or {}
  accessPointForms[playerName] = {
    position       = pos,
    invName        = invName,
    storFilterInvName = get_or_create_storage_filter_inv(playerName),
    tab            = prev.tab or 1,
    storPage       = prev.storPage or 1,
    storMapping    = prev.storMapping or {},
  }

  logistica.access_point_refresh_fake_inv(pos, invName, INV_FAKE, FAKE_INV_SIZE, playerName)
  logistica.access_point_refresh_liquids(pos, playerName)
  minetest.show_formspec(
    playerName,
    FORMSPEC_NAME,
    get_access_point_formspec(
      pos, invName, meta, playerName,
      optError and S("Error: ")..optError or "",
      accessPointForms[playerName].tab
    )
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

local function get_total_storage_pages(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return 1 end
  local count = 0
  for _ in pairs(network.mass_storage) do count = count + 1 end
  return math.max(1, math.ceil(count / STOR_PER_PAGE))
end

function logistica.on_receive_access_point_formspec(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  if not accessPointForms[playerName] then return true end
  local pos = accessPointForms[playerName].position
  if not pos or minetest.is_protected(pos, playerName) then return true end

  if fields.quit and not fields.key_enter_field then
    return true
  elseif fields[TAB_BTN] then
    local newTab = tonumber(fields[TAB_BTN])
    if newTab then accessPointForms[playerName].tab = newTab end
  elseif fields[STOR_PREV_BTN] then
    local data = accessPointForms[playerName]
    local total = get_total_storage_pages(pos)
    data.storPage = (((data.storPage or 1) - 2) % total) + 1
  elseif fields[STOR_NEXT_BTN] then
    local data = accessPointForms[playerName]
    local total = get_total_storage_pages(pos)
    data.storPage = ((data.storPage or 1) % total) + 1
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
    local leftover = logistica.insert_item_in_network(stackToAdd, networkId, false, false, false, false, true, false)
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
  if storFilterInventories[playerName] then
    minetest.remove_detached_inventory(storFilterInventories[playerName])
    storFilterInventories[playerName] = nil
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

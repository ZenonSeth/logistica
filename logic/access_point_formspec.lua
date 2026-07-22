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
local DEPOSIT_ALL_BTN = "dep_all"
local DEPOSIT_MASS_BTN = "dep_mass"
local DEPOSIT_SUPPLY_BTN = "dep_supply"
local DEPOSIT_TOOL_BTN = "dep_tool"

local SUPPLY_PREV_BTN = "sup_prev"
local SUPPLY_NEXT_BTN = "sup_next"
local SUPPLY_SORT_NAME_BTN = "sup_sort_name"
local SUPPLY_SORT_MOD_BTN = "sup_sort_mod"
local SUPPLY_CHEST_PAGE_BTN = "sup_chest_page"
local SUPPLY_CHEST_PAGE_SIZE = 32 -- 8x4 slots shown at a time, same as the supplier chest's own formspec

local INV_FAKE = "fake"
local INV_INSERT = "isert"
local INV_LIQUID = "liqd"
local INV_STOR_FILTER = "stor_filter"
local INV_SUPPLY_MAIN = "sup_main"
local INV_SUPPLY_FILTER = "sup_filter"
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
local AP_PLAYER_INV_X = 5.2
local AP_PLAYER_INV_Y = 8.8  -- 8.0 + TAB_Y

local STOR_PER_PAGE = 2
local STOR_BLOCK_H  = 3.0   -- vertical space per mass-storage block
local STOR_START_Y  = 1.75  -- y where first block begins

local AC_SEARCH_FIELD  = "ac_srch"
local AC_SEARCH_BTN    = "ac_srch_go"
local AC_PREV_RES_BTN  = "ac_res_p"
local AC_NEXT_RES_BTN  = "ac_res_n"
local AC_RESULT_BTN    = "ac_res_"
local AC_PREV_RCP_BTN  = "ac_rcp_p"
local AC_NEXT_RCP_BTN  = "ac_rcp_n"
local AC_RECIPE_BTN    = "ac_rcp_"
local AC_CRAFT_BTN     = "ac_craft1"
local AC_CRAFT10_BTN   = "ac_craft10"
local AC_BACK_BTN      = "ac_bk"
local AC_FWD_BTN       = "ac_fw"
local AC_USE_PLR_INV   = "ac_plrinv"

local AC_RESULTS_PER_PAGE = 5
local AC_SLOT_SIZE    = 1.0
local AC_SLOT_STEP    = 1.1
local AC_GRID_X       = 6.6
local AC_GRID_Y       = 1.5
local AC_COLOR_HAVE   = "#2255EE88"
local AC_COLOR_MISS   = "#EE333388"

local AC_REC_CHECK_BTN   = "ac_rec_chk"
local AC_REC_CRAFT_BTN   = "ac_rec_cft"
local AC_REC_TEXTLIST    = "ac_rec_tl"
local AC_REC_X           = 10.1
local AC_OUTPUT_LIST     = "ac_output"
local AC_QUEUE_W         = 4
local AC_FORM_H_AC       = 16.05
local AC_PLAYER_INV_Y_AC = 10.8
local AC_QUEUE_INTERVAL  = 0.2

local detachedInventories = {}
local accessPointForms = {}
-- per-player detached inventories mirroring the visible mass-storage filter slots
local storFilterInventories = {}  -- [playerName] = invName
-- per-player no-interact queue display inventories for recursive crafting
local queueInventories = {}  -- [playerName] = invName
-- per-player detached inventory mirroring the currently-viewed supply chest's real inventory
local supplyInventories = {}  -- [playerName] = invName
-- per-position detached output inventories for autocrafting
local outputInventories = {}  -- [posHash] = invName
-- per-position detached trash inventories (trash slot + last deleted item slot)
local trashInventories = {}  -- [posHash] = invName

local function get_or_create_queue_inv(playerName)
  if queueInventories[playerName] then return queueInventories[playerName] end
  local invName = "Logistica_AP_Q_"..playerName
  local inv = minetest.create_detached_inventory(invName, {
    allow_move = function() return 0 end,
    allow_put  = function() return 0 end,
    allow_take = function() return 0 end,
    on_move = function() end,
    on_put  = function() end,
    on_take = function() end,
  }, playerName)
  inv:set_size("queue", AC_QUEUE_W)
  queueInventories[playerName] = invName
  return invName
end

local AC_OUTPUT_META_KEY = "ac_output_backup"
local AC_OUTPUT_SLOTS = 12

local function sync_output_to_meta(pos)
  logistica.load_position(pos)
  local invName = outputInventories[minetest.hash_node_position(pos)]
  if not invName then return end
  local inv = minetest.get_inventory({type = "detached", name = invName})
  if not inv then return end
  local stacks = {}
  for i = 1, AC_OUTPUT_SLOTS do
    local st = inv:get_stack(AC_OUTPUT_LIST, i)
    stacks[i] = st:to_string()
  end
  minetest.get_meta(pos):set_string(AC_OUTPUT_META_KEY, minetest.serialize(stacks))
end

local function get_or_create_output_inv(pos)
  local posHash = minetest.hash_node_position(pos)
  if outputInventories[posHash] then return outputInventories[posHash] end
  local invName = "Logistica_AP_Out_"..posHash
  local inv = minetest.create_detached_inventory(invName, {
    allow_move = function() return 0 end,
    allow_put  = function() return 0 end,
    allow_take = function(_, _, _, stack, player)
      local pName = player:get_player_name()
      if not logistica.player_has_network_access(pos, pName) then return 0 end
      return stack:get_count()
    end,
    on_move = function() end,
    on_put  = function() end,
    on_take = function() sync_output_to_meta(pos) end,
  })
  inv:set_size(AC_OUTPUT_LIST, AC_OUTPUT_SLOTS)
  logistica.load_position(pos)
  local saved = minetest.get_meta(pos):get_string(AC_OUTPUT_META_KEY)
  if saved ~= "" then
    local stacks = minetest.deserialize(saved)
    if stacks then
      for i = 1, AC_OUTPUT_SLOTS do
        if stacks[i] then inv:set_stack(AC_OUTPUT_LIST, i, ItemStack(stacks[i])) end
      end
    end
  end
  outputInventories[posHash] = invName
  return invName
end

local AP_TRASH_LIST     = "ap_trash"
local AP_TRASH_DST_LIST = "ap_trash_dst"
local AP_TRASH_DST_META_KEY = "ap_trash_dst_backup"

local function sync_trash_dst_to_meta(pos)
  logistica.load_position(pos)
  local invName = trashInventories[minetest.hash_node_position(pos)]
  if not invName then return end
  local inv = minetest.get_inventory({type = "detached", name = invName})
  if not inv then return end
  local stack = inv:get_stack(AP_TRASH_DST_LIST, 1)
  minetest.get_meta(pos):set_string(AP_TRASH_DST_META_KEY, stack:to_string())
end

local function get_or_create_trash_inv(pos)
  local posHash = minetest.hash_node_position(pos)
  if trashInventories[posHash] then return trashInventories[posHash] end
  local invName = "Logistica_AP_Trash_"..posHash
  local inv = minetest.create_detached_inventory(invName, {
    allow_move = function() return 0 end,
    allow_put  = function(_, listname, _, stack, player)
      if listname ~= AP_TRASH_LIST then return 0 end
      local pName = player:get_player_name()
      if not logistica.player_has_network_access(pos, pName) then return 0 end
      return stack:get_count()
    end,
    allow_take = function(_, listname, _, stack, player)
      if listname ~= AP_TRASH_DST_LIST then return 0 end
      local pName = player:get_player_name()
      if not logistica.player_has_network_access(pos, pName) then return 0 end
      return stack:get_count()
    end,
    on_move = function() end,
    on_put  = function(sinv, listname, index)
      if listname ~= AP_TRASH_LIST then return end
      local stack = sinv:get_stack(listname, index)
      sinv:set_stack(listname, index, ItemStack(""))
      sinv:set_stack(AP_TRASH_DST_LIST, 1, stack)
      sync_trash_dst_to_meta(pos)
    end,
    on_take = function() sync_trash_dst_to_meta(pos) end,
  })
  inv:set_size(AP_TRASH_LIST, 1)
  inv:set_size(AP_TRASH_DST_LIST, 1)
  logistica.load_position(pos)
  local saved = minetest.get_meta(pos):get_string(AP_TRASH_DST_META_KEY)
  if saved ~= "" then
    inv:set_stack(AP_TRASH_DST_LIST, 1, ItemStack(saved))
  end
  trashInventories[posHash] = invName
  return invName
end

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
      if not logistica.player_has_network_access(msPos, pName) then return 0 end
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
      if not logistica.player_has_network_access(msPos, pName) then return 0 end
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

-- writes the player's supply-tab `main` mirror list back onto the real chest's meta
-- inventory (loading the position first, since the chest may be unloaded), and triggers
-- the same cache update a direct player interaction with the chest would
local function sync_supply_main_to_real(playerName)
  local data = accessPointForms[playerName]
  local chestPos = data and data.supplyChestPos
  if not chestPos then return end
  local sInv = minetest.get_inventory({type = "detached", name = data.supplyInvName})
  if not sInv then return end
  logistica.load_position(chestPos)
  local realInv = minetest.get_meta(chestPos):get_inventory()
  realInv:set_list("main", sInv:get_list(INV_SUPPLY_MAIN))
  logistica.update_cache_at_pos(chestPos, LOG_CACHE_SUPPLIER)
end

-- only the `main` list supports free drag/move; the `filter` list is handled entirely in
-- allow_put/allow_take below, same as the real chest's own formspec and the Mass Storage
-- tab's filter mirror: it holds name-only markers, never real items, so moves are disallowed
local function supply_inv_allow_move(sinv, from_list, from_index, to_list, to_index, count, player)
  if from_list ~= INV_SUPPLY_MAIN or to_list ~= INV_SUPPLY_MAIN then return 0 end
  local pName = player:get_player_name()
  local data = accessPointForms[pName]
  if not data or not data.supplyChestPos then return 0 end
  if not logistica.player_has_network_access(data.supplyChestPos, pName) then return 0 end
  return count
end

-- `filter` markers never actually change hands: like the real chest's own formspec, putting
-- an item onto a filter slot only records its name (count 1) without consuming the source
-- stack, and taking one back off only clears the marker without handing over a real item.
-- Returning 0 here means the engine performs no transfer at all; we mutate both the real
-- chest and the mirror slot ourselves.
local function supply_inv_allow_put(sinv, listname, index, stack, player)
  local pName = player:get_player_name()
  local data = accessPointForms[pName]
  if not data or not data.supplyChestPos then return 0 end
  local chestPos = data.supplyChestPos
  if not logistica.player_has_network_access(chestPos, pName) then return 0 end

  if listname == INV_SUPPLY_FILTER then
    logistica.load_position(chestPos)
    local realInv = minetest.get_meta(chestPos):get_inventory()
    local copy = ItemStack(stack:get_name())
    copy:set_count(1)
    realInv:set_stack("filter", index, copy)
    sinv:set_stack(listname, index, copy)
    logistica.update_cache_at_pos(chestPos, LOG_CACHE_SUPPLIER)
    return 0
  end

  return stack:get_count()
end

local function supply_inv_allow_take(sinv, listname, index, stack, player)
  local pName = player:get_player_name()
  local data = accessPointForms[pName]
  if not data or not data.supplyChestPos then return 0 end
  local chestPos = data.supplyChestPos
  if not logistica.player_has_network_access(chestPos, pName) then return 0 end

  if listname == INV_SUPPLY_FILTER then
    logistica.load_position(chestPos)
    local realInv = minetest.get_meta(chestPos):get_inventory()
    realInv:set_stack("filter", index, ItemStack(""))
    sinv:set_stack(listname, index, ItemStack(""))
    logistica.update_cache_at_pos(chestPos, LOG_CACHE_SUPPLIER)
    return 0
  end

  return stack:get_count()
end

-- creates (or returns the existing) per-player detached inventory used to mirror the currently
-- displayed supply chest's `main` and `filter` lists on the AP's Supply Chests tab
local function get_or_create_supply_inv(playerName)
  if supplyInventories[playerName] then return supplyInventories[playerName] end
  local invName = "Logistica_AP_Sup_"..playerName
  minetest.create_detached_inventory(invName, {
    allow_move = supply_inv_allow_move,
    allow_put  = supply_inv_allow_put,
    allow_take = supply_inv_allow_take,
    on_move    = function(sinv, from_list, from_index, to_list, to_index, count, player)
      sync_supply_main_to_real(player:get_player_name())
    end,
    on_put     = function(sinv, listname, index, stack, player)
      if listname == INV_SUPPLY_MAIN then sync_supply_main_to_real(player:get_player_name()) end
    end,
    on_take    = function(sinv, listname, index, stack, player)
      if listname == INV_SUPPLY_MAIN then sync_supply_main_to_real(player:get_player_name()) end
    end,
  }, playerName)
  supplyInventories[playerName] = invName
  return invName
end

-- refreshes the player's supply-tab mirror inventory from the given chest's real meta
-- inventory; must be called before rendering the tab and whenever the shown chest changes
local function refresh_supply_inv(invName, chestPos)
  logistica.load_position(chestPos)
  local realInv = minetest.get_meta(chestPos):get_inventory()
  local sInv = minetest.get_inventory({type = "detached", name = invName})
  if not sInv then return end
  local size = logistica.get_supplier_inv_size(chestPos)
  sInv:set_size(INV_SUPPLY_MAIN, size)
  sInv:set_list(INV_SUPPLY_MAIN, realInv:get_list("main"))
  sInv:set_size(INV_SUPPLY_FILTER, logistica.SUPPLIER_FILTER_SLOTS)
  sInv:set_list(INV_SUPPLY_FILTER, realInv:get_list("filter"))
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

local function get_deposit_section(y) return
  "label[5.2,"..(y + 0.3)..";"..S("Deposit:").."]"..
  "button[6.4,"..y..";1.0,0.6;"..DEPOSIT_ALL_BTN..";"..S("All").."]"..
  "button[7.5,"..y..";2.5,0.6;"..DEPOSIT_MASS_BTN..";"..S("In Mass Storage").."]"..
  "button[10.1,"..y..";2.5,0.6;"..DEPOSIT_SUPPLY_BTN..";"..S("In Supply Chests").."]"..
  "button[12.7,"..y..";2.2,0.6;"..DEPOSIT_TOOL_BTN..";"..S("In Tool Chests").."]"
end

local function get_liquid_section(invName, meta, playerName, yOff)
  local currInfo = logistica.access_point_get_current_liquid_display_info(meta, playerName)
  return
    "list[detached:"..invName..";"..INV_LIQUID..";0.95,"..(7.1+yOff)..";1,1;0]"..
    "image[1.05,"..(5.8+yOff)..";0.8,0.8;"..currInfo.texture.."]"..
    "label[0.75,"..(6.9+yOff)..";"..currInfo.description.." "..currInfo.capacity.."]"..
    "image_button[0.45,"..(5.8+yOff)..";0.6,0.8;logistica_icon_prev.png;"..LIQUID_PREV_BTN..";;false;false]"..
    "image_button[1.85,"..(5.8+yOff)..";0.6,0.8;logistica_icon_next.png;"..LIQUID_NEXT_BTN..";;false;false]"..
    "label[0.6,"..(8.3+yOff)..";"..S("Place bucket here").."]"
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

local function sort_positions(list)
  table.sort(list, function(a, b)
    if a.x ~= b.x then return a.x < b.x end
    if a.y ~= b.y then return a.y < b.y end
    return a.z < b.z
  end)
  return list
end

local function get_sorted_mass_storage_list(network)
  local list = {}
  for hash, _ in pairs(network.mass_storage) do
    table.insert(list, minetest.get_position_from_hash(hash))
  end
  return sort_positions(list)
end

-- passive supplier chests only (nodes players can deposit into directly), not
-- generator/crafting/cooking/farming suppliers which fill themselves
local function get_sorted_supplier_list(network)
  local list = {}
  for hash, _ in pairs(network.suppliers) do
    local pos = minetest.get_position_from_hash(hash)
    logistica.load_position(pos)
    if logistica.is_passive_supplier_node(minetest.get_node(pos).name) then
      table.insert(list, pos)
    end
  end
  return sort_positions(list)
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
-- supply chests tab
----------------------------------------------------------------

local function get_total_supplier_pages(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return 1 end
  return math.max(1, #get_sorted_supplier_list(network))
end

-- advances the currently-viewed chest's own page (its slot window), not which chest is shown
local function advance_supply_chest_page(playerName)
  local data = accessPointForms[playerName]
  if not data or not data.supplyChestPos then return end
  local size = logistica.get_supplier_inv_size(data.supplyChestPos)
  local total = math.max(1, math.ceil(size / SUPPLY_CHEST_PAGE_SIZE))
  data.supplyChestPage = ((data.supplyChestPage or 1) % total) + 1
end

local function get_supply_tab_content(pos, playerName)
  local data = accessPointForms[playerName]

  local result =
    "label[0.2,0.5;"..S("Supply Chests").."]"..
    "label[0.2,0.85;"..S("Drag items to rearrange the chest's slots, or use Sort to compact and alphabetize them").."]"..
    "image_button[9.8,0.3;0.8,0.8;logistica_icon_prev.png;"..SUPPLY_PREV_BTN..";;false;false;]"..
    "image_button[13.4,0.3;0.8,0.8;logistica_icon_next.png;"..SUPPLY_NEXT_BTN..";;false;false;]"

  local network = logistica.get_network_or_nil(pos)
  if not network then
    return result.."label[0.2,2.0;"..S("No network connected.").."]"
  end

  local chests = get_sorted_supplier_list(network)
  if #chests == 0 then
    return result.."label[0.2,2.0;"..S("No Supply Chests on this network.").."]"
  end

  local page = logistica.clamp(data.supplyPage or 1, 1, #chests)
  data.supplyPage = page
  local chestPos = chests[page]
  data.supplyChestPos = chestPos

  refresh_supply_inv(data.supplyInvName, chestPos)

  logistica.load_position(chestPos)
  local node = minetest.get_node(chestPos)
  local def = minetest.registered_nodes[node.name]
  local desc = (def and def.description or node.name):match("^([^\n]+)") or node.name
  local size = logistica.get_supplier_inv_size(chestPos)

  local totalChestPages = math.max(1, math.ceil(size / SUPPLY_CHEST_PAGE_SIZE))
  local chestPage = logistica.clamp(data.supplyChestPage or 1, 1, totalChestPages)
  data.supplyChestPage = chestPage
  local startIndex = (chestPage - 1) * SUPPLY_CHEST_PAGE_SIZE
  local rows = math.max(1, math.min(4, math.ceil((size - startIndex) / 8)))

  local mainListY = 1.9
  local filterLabelY = mainListY + rows * 1.25 + 0.3
  local filterListY  = filterLabelY + 0.4

  local chestPageBtn = ""
  if totalChestPages > 1 then
    chestPageBtn = "button[10.6,1.85;3.4,0.6;"..SUPPLY_CHEST_PAGE_BTN..";"..
      S("Page").." "..chestPage.." / "..totalChestPages.."]"..
      "tooltip["..SUPPLY_CHEST_PAGE_BTN..";"..S("Click to view the next page of this chest's inventory").."]"
  end

  result = result..
    "label[11.25,0.75;"..S("Chest").." "..page.." / "..#chests.."]"..
    "label[0.2,1.3;"..minetest.formspec_escape(desc).."  @ "..chestPos.x..", "..chestPos.y..", "..chestPos.z.."]"..
    chestPageBtn..
    "label[10.6,2.85;"..S("Sort by:").."]"..
    "button[10.6,3.05;3.4,0.6;"..SUPPLY_SORT_NAME_BTN..";"..S("Alphabetical").."]"..
    "button[10.6,3.75;3.4,0.6;"..SUPPLY_SORT_MOD_BTN..";"..S("Mod").."]"..
    "list[detached:"..data.supplyInvName..";"..INV_SUPPLY_MAIN..";0.2,"..mainListY..";8,"..rows..";"..startIndex.."]"..
    "listring[detached:"..data.supplyInvName..";"..INV_SUPPLY_MAIN.."]"..
    "listring[current_player;main]"..
    "label[0.2,"..filterLabelY..";"..S("Items allowed to be stored (if empty, then all accepted):").."]"..
    "list[detached:"..data.supplyInvName..";"..INV_SUPPLY_FILTER..";0.2,"..filterListY..";8,1;0]"

  return result
end

----------------------------------------------------------------
-- autocrafting tab
----------------------------------------------------------------

local function ac_get_current_recipe(data)
  local hist_pos = data.ac_hist_pos or 0
  local current = hist_pos > 0 and data.ac_history[hist_pos] or nil
  if not current then return nil end
  local entry = logistica.ac_get_entry(current.name)
  if not entry or #entry.recipes == 0 then return nil end
  return entry.recipes[logistica.clamp(current.recipe_idx or 1, 1, #entry.recipes)]
end

-- display_items: list of {name, count} up to AC_QUEUE_W entries, or nil to clear
local function ac_populate_queue_display(data, display_items)
  local q_inv = minetest.get_inventory({type = "detached", name = data.ac_queue_inv_name})
  if not q_inv then return end
  for i = 1, AC_QUEUE_W do
    local item = display_items and display_items[i]
    if item then
      local st = ItemStack(item.name)
      st:set_count(item.count)
      q_inv:set_stack("queue", i, st)
    else
      q_inv:set_stack("queue", i, ItemStack(""))
    end
  end
end

local function compact_queue(raw_queue)
  local out = {}
  for _, name in ipairs(raw_queue) do
    if #out > 0 and out[#out].name == name then
      out[#out].count = out[#out].count + 1
    else
      out[#out + 1] = {name = name, count = 1}
    end
  end
  return out
end

-- builds the display_items list from a compacted queue, given current front position and
-- remaining count for the front entry
local function ac_queue_display_items(queue, pos_idx, cur_count)
  local items = {}
  for i = 1, AC_QUEUE_W do
    local entry = queue[pos_idx + i - 1]
    if not entry then break end
    items[i] = {name = entry.name, count = (i == 1) and cur_count or entry.count}
  end
  return items
end

local function ac_item_desc(item_name)
  local def = minetest.registered_items[item_name]
  if not def or not def.description then return item_name end
  return (def.description:match("^([^\n]+)") or def.description):gsub(",", ";")
end

local function ac_handle_recursive_check(pos, data)
  local recipe = ac_get_current_recipe(data)
  if not recipe then
    data.ac_rec_lines = {"No item selected or no craftable recipe"}
    data.ac_rec_plan  = nil
    return
  end
  local network = logistica.get_network_or_nil(pos)
  if not network then
    data.ac_rec_lines = {"No network connected"}
    data.ac_rec_plan  = nil
    return
  end

  local plan, err = logistica.ac_plan_recursive(recipe.output_name, 1, network)
  data.ac_rec_plan = plan

  if not plan then
    data.ac_rec_lines = {err or "Cannot craft"}
    return
  end

  local lines = {"Will craft: "..ac_item_desc(plan.output:get_name()).." x"..plan.output:get_count()}
  for item_name, count in pairs(plan.to_take) do
    lines[#lines + 1] = count.."x "..ac_item_desc(item_name)
  end
  table.sort(lines, function(a, b) return a < b end)
  -- move the "Will craft" summary back to position 1 after sort
  for i, l in ipairs(lines) do
    if l:sub(1, 10) == "Will craft" then
      table.remove(lines, i)
      table.insert(lines, 1, l)
      break
    end
  end
  data.ac_rec_lines = lines
end

local function ac_handle_recursive_craft(pos, data)
  local recipe = ac_get_current_recipe(data)
  if not recipe then
    data.ac_rec_lines = {"No item selected or no craftable recipe"}
    return
  end
  local network = logistica.get_network_or_nil(pos)
  if not network then
    data.ac_rec_lines = {"No network connected"}
    return
  end

  local plan, err = logistica.ac_plan_recursive(recipe.output_name, 1, network)
  data.ac_rec_plan = plan

  if not plan then
    data.ac_rec_lines = {err or "Cannot craft"}
    return
  end

  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    data.ac_rec_lines = {"No network"}
    return
  end

  local meta = minetest.get_meta(pos)
  local cq = compact_queue(plan.queue)
  local first_count = #cq > 0 and cq[1].count or 0
  meta:set_string("ac_queue", minetest.serialize(cq))
  meta:set_string("ac_pending_to_take", minetest.serialize(plan.to_take))
  meta:set_string("ac_pending_to_give", minetest.serialize(plan.to_give or {}))
  meta:set_string("ac_pending_output", plan.output:to_string())
  meta:set_int("ac_queue_pos", 1)
  meta:set_int("ac_queue_cur_count", first_count)
  ac_populate_queue_display(data, ac_queue_display_items(cq, 1, first_count))
  logistica.start_ac_queue_timer(pos)
  data.ac_rec_lines = {"Crafting: "..ac_item_desc(plan.output:get_name()).." x"..plan.output:get_count()}
end

local activeAcQueues = {}

local function ac_queue_tick(posHash)
  local pos = minetest.get_position_from_hash(posHash)
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  local queue_str = meta:get_string("ac_queue")
  if queue_str == "" then activeAcQueues[posHash] = nil; return end
  local queue = minetest.deserialize(queue_str)
  if not queue then meta:set_string("ac_queue", ""); activeAcQueues[posHash] = nil; return end

  local pos_idx   = meta:get_int("ac_queue_pos")
  local cur_count = meta:get_int("ac_queue_cur_count") - 1

  if cur_count <= 0 then
    pos_idx = pos_idx + 1
    if pos_idx > #queue then
      meta:set_string("ac_queue", "")
      local pending_output = meta:get_string("ac_pending_output")
      local pending_to_take = meta:get_string("ac_pending_to_take")
      local pending_to_give = meta:get_string("ac_pending_to_give")
      meta:set_string("ac_pending_output", "")
      meta:set_string("ac_pending_to_take", "")
      meta:set_string("ac_pending_to_give", "")
      if pending_output ~= "" and pending_to_take ~= "" then
        local to_take = minetest.deserialize(pending_to_take)
        local to_give = pending_to_give ~= "" and minetest.deserialize(pending_to_give) or {}
        local networkId = logistica.get_network_id_or_nil(pos)
        if to_take and networkId then
          local plan = { to_take = to_take, to_give = to_give, output = ItemStack(pending_output) }
          local output, execErr = logistica.ac_execute_plan(plan, networkId, pos)
          if output then
            local outInv = logistica.get_ac_output_inv(pos)
            local leftover = outInv:add_item(AC_OUTPUT_LIST, output)
            if not leftover:is_empty() then
              minetest.item_drop(leftover, nil, pos)
            end
            sync_output_to_meta(pos)
          end
          for _, pData in pairs(accessPointForms) do
            if vector.equals(pData.position, pos) then
              if output then
                pData.ac_rec_lines = {"Crafted: "..ac_item_desc(output:get_name()).." x"..output:get_count()}
              else
                pData.ac_rec_lines = {"Failed: "..(execErr or "Not enough materials")}
              end
            end
          end
        end
      end
      for _, pData in pairs(accessPointForms) do
        if vector.equals(pData.position, pos) then
          ac_populate_queue_display(pData, nil)
        end
      end
      activeAcQueues[posHash] = nil
      return
    end
    meta:set_int("ac_queue_pos", pos_idx)
    cur_count = queue[pos_idx].count
  end

  meta:set_int("ac_queue_cur_count", cur_count)
  local display = ac_queue_display_items(queue, pos_idx, cur_count)
  for _, pData in pairs(accessPointForms) do
    if vector.equals(pData.position, pos) then
      ac_populate_queue_display(pData, display)
    end
  end
  minetest.after(AC_QUEUE_INTERVAL, ac_queue_tick, posHash)
end

function logistica.start_ac_queue_timer(pos)
  local posHash = minetest.hash_node_position(pos)
  if activeAcQueues[posHash] then return end
  activeAcQueues[posHash] = true
  minetest.after(AC_QUEUE_INTERVAL, ac_queue_tick, posHash)
end

local function ac_navigate_to(data, name, recipe_idx)
  local hist = data.ac_history
  while #hist > data.ac_hist_pos do hist[#hist] = nil end
  hist[#hist + 1] = { name = name, recipe_idx = recipe_idx or 1 }
  data.ac_hist_pos = #hist
  data.ac_error = nil
end

local function ac_handle_craft(pos, data, player, count)
  local hist_pos = data.ac_hist_pos or 0
  local current  = hist_pos > 0 and data.ac_history[hist_pos] or nil
  if not current then data.ac_error = S("No item selected"); return end
  local entry = logistica.ac_get_entry(current.name)
  if not entry or #entry.recipes == 0 then data.ac_error = S("No craftable recipe"); return end
  local recipe_idx = logistica.clamp(current.recipe_idx or 1, 1, #entry.recipes)
  local recipe = entry.recipes[recipe_idx]
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then data.ac_error = S("No network connected"); return end
  local crafted, err = logistica.ac_craft(recipe, networkId, player, count, data.ac_use_player_inv, pos)
  if err then
    data.ac_error = err
  elseif crafted == 0 then
    data.ac_error = S("Not enough materials")
  else
    data.ac_error = S("Crafted: ")..crafted
  end
end

local function get_autocrafting_tab_content(pos, playerName)
  local data     = accessPointForms[playerName]

  if data.from_wap and not logistica.ac_has_synced_recursive_upgrade(pos) then
    return "label[4.5,4.0;"..S("Easy Crafting via\nWireless Access Pad\nonly available with\na ")..minetest.colorize("#44FF44", S("Synchronized"))..S(" Recursive Upgrade\nvia the Wireless Upgrader").."]"
  end

  local posStr   = pos.x..","..pos.y..","..pos.z
  local history  = data.ac_history  or {}
  local hist_pos = data.ac_hist_pos or 0
  local current  = hist_pos > 0 and history[hist_pos] or nil

  local out = {}
  local function add(s) out[#out + 1] = s end

  if not data.from_wap then
    add("label[12.8,0.72;"..S("Upgrade:").." ]")
    add("list[nodemeta:"..posStr..";"..logistica.AP_UPGRADE_LIST..";13.5,0.9;1,1;0]")
    add("listring[nodemeta:"..posStr..";"..logistica.AP_UPGRADE_LIST.."]")
    add("listring[current_player;main]")
  end

  -- vertical separator between result list and recipe panel
  add("box[5.85,0.8;0.05,7.5;#FFFFFF25]")

  -- left panel: search results
  local search_term = data.ac_search  or ""
  local results     = data.ac_results or {}
  local res_page    = data.ac_res_page or 1
  local total_pages = math.max(1, math.ceil(#results / AC_RESULTS_PER_PAGE))
  res_page = logistica.clamp(res_page, 1, total_pages)
  data.ac_res_page = res_page

  for i = 1, AC_RESULTS_PER_PAGE do
    local idx   = (res_page - 1) * AC_RESULTS_PER_PAGE + i
    local entry = results[idx]
    local y     = 1.0 + (i - 1) * 1.1
    if entry then
      add("item_image[0.2,"..y..";0.9,0.9;"..entry.name.."]")
      add("tooltip[0.2,"..y..";0.9,0.9;"..
        minetest.formspec_escape(ItemStack(entry.name):get_description()).."]")
      add("button[1.2,"..y..";4.3,0.9;"..AC_RESULT_BTN..i..";"..
        minetest.formspec_escape(entry.desc).."]")
    end
  end

  if #results == 0 and #search_term < 2 then
    add("label[0.2,6.6;"..S("Enter 2+ characters to search").."]")
  elseif #results == 0 then
    add("label[0.2,6.6;"..S("No results found").."]")
  else
    add("image_button[0.2,6.5;0.65,0.65;logistica_icon_prev.png;"..
      AC_PREV_RES_BTN..";;false;false;]")
    add("label[1.2,6.90;"..S("Page").." "..res_page.." / "..total_pages.."]")
    add("image_button[3.0,6.5;0.65,0.65;logistica_icon_next.png;"..
      AC_NEXT_RES_BTN..";;false;false;]")
  end

  add("field[0.2,7.45;4.3,0.65;"..AC_SEARCH_FIELD..";;"..(minetest.formspec_escape(search_term)).."]")
  add("field_close_on_enter["..AC_SEARCH_FIELD..";false]")
  add("image_button[4.6,7.45;0.65,0.65;logistica_icon_search.png;"..
    AC_SEARCH_BTN..";;false;false;]")
  add("tooltip["..AC_SEARCH_BTN..";"..S("Search (min. 2 characters)").."]")

  -- right panel: gated behind upgrade
  if not logistica.ac_has_upgrade(pos) then
    add("label[7.3,4.0;"..S("Insert Autocrafting Upgrade to enable").."]")
    return table.concat(out)
  end

  if not current then
    add("label[6.2,4.0;"..S("Click an item to view its recipe").."]")
  else
    local entry = logistica.ac_get_entry(current.name)
    if not entry or #entry.recipes == 0 then
      add("label[6.6,0.95;"..minetest.formspec_escape(current.name).."]")
      add("label[7.0,3.5;"..S("No craftable recipe found").."]")
    else
      local recipe_idx = logistica.clamp(current.recipe_idx or 1, 1, #entry.recipes)
      current.recipe_idx = recipe_idx
      local recipe     = entry.recipes[recipe_idx]
      local network    = logistica.get_network_or_nil(pos)
      local use_pi     = data.ac_use_player_inv
      local cur_player = use_pi and minetest.get_player_by_name(playerName) or nil

      add("label[6.6,0.95;"..minetest.formspec_escape(entry.desc).."]")

      -- 3x3 recipe grid: colored box behind each occupied slot
      local slot_display = network and logistica.ac_get_recipe_slot_display(recipe, network, cur_player) or {}
      for i = 1, 9 do
        local col  = (i - 1) % 3
        local row  = math.floor((i - 1) / 3)
        local x    = AC_GRID_X + col * AC_SLOT_STEP
        local y    = AC_GRID_Y + row * AC_SLOT_STEP
        local info = slot_display[i]
        if info then
          local color = (info.have >= info.need) and AC_COLOR_HAVE or AC_COLOR_MISS
          add(string.format("box[%.2f,%.2f;%.2f,%.2f;%s]",
            x - 0.06, y - 0.06, AC_SLOT_SIZE + 0.12, AC_SLOT_SIZE + 0.12, color))
          if info.is_group then
            add(string.format("item_image[%.2f,%.2f;%.2f,%.2f;%s]",
              x, y, AC_SLOT_SIZE, AC_SLOT_SIZE, info.display_item))
            add(string.format("label[%.2f,%.2f;G]", x + 0.38, y + 0.58))
            add(string.format("tooltip[%.2f,%.2f;%.2f,%.2f;%s]",
              x, y, AC_SLOT_SIZE, AC_SLOT_SIZE,
              minetest.formspec_escape("group:" .. info.group_name)))
          else
            add(string.format("item_image_button[%.2f,%.2f;%.2f,%.2f;%s;%s%d;]",
              x, y, AC_SLOT_SIZE, AC_SLOT_SIZE, info.display_item, AC_RECIPE_BTN, i))
          end
        end
      end

      -- recipe pagination
      add("image_button[6.6,5.05;0.65,0.65;logistica_icon_prev.png;"..
        AC_PREV_RCP_BTN..";;false;false;]")
      add("label[7.45,5.43;"..S("Recipe").." "..recipe_idx.." / "..(#entry.recipes).."]")
      add("image_button[9.15,5.05;0.65,0.65;logistica_icon_next.png;"..
        AC_NEXT_RCP_BTN..";;false;false;]")

      if network then
        local max_n = logistica.ac_get_max_craftable(recipe, network, cur_player, use_pi)
        add("label[6.8,6.6;"..S("Can craft: ")..max_n.."]")
      end
    end
  end

  -- error / status line (shown below recipe area)
  local err = data.ac_error or ""
  if err ~= "" then
    add("label[6.6,5.9;"..minetest.formspec_escape(err).."]")
  end

  -- player inventory checkbox + craft + history navigation buttons
  local use_pi_str = data.ac_use_player_inv and "true" or "false"
  add("checkbox[6.6,6.85;"..AC_USE_PLR_INV..";"..
    S("Also use player inventory")..";"..use_pi_str.."]")
  add("button[6.6,7.45;1.8,0.65;"..AC_CRAFT_BTN..";"..S("Craft").."]")
  add("button[8.5,7.45;1.0,0.65;"..AC_CRAFT10_BTN..";"..S("x10").."]")

  if hist_pos > 1 then
    add("image_button[7.0,8.45;0.65,0.65;logistica_icon_prev.png;"..
      AC_BACK_BTN..";;false;false;]")
    add("tooltip["..AC_BACK_BTN..";"..S("Back").."]")
  end
  if hist_pos < #history then
    add("image_button[7.75,8.45;0.65,0.65;logistica_icon_next.png;"..
      AC_FWD_BTN..";;false;false;]")
    add("tooltip["..AC_FWD_BTN..";"..S("Forward").."]")
  end

  -- recursive crafting section (right of recipe grid, below upgrade slot)
  add("label["..AC_REC_X..",2.2;"..S("Recursive Crafting").."]")

  if not logistica.ac_has_recursive_upgrade(pos) then
    add("label["..AC_REC_X..",3.0;"..S("Insert Recursive Crafting Upgrade to enable").."]")
  else
    add("button["..AC_REC_X..",2.7;2.3,0.65;"..AC_REC_CHECK_BTN..";"..S("Check").."]")
    add("button[12.5,2.7;2.3,0.65;"..AC_REC_CRAFT_BTN..";"..S("Craft").."]")

    local rec_lines = data.ac_rec_lines or {}
    local lines_strs = {}
    for _, l in ipairs(rec_lines) do lines_strs[#lines_strs + 1] = l end
    add("textlist["..AC_REC_X..",3.45;4.9,1.3;"..AC_REC_TEXTLIST..";"..
      table.concat(lines_strs, ",")..";0;false]")

    -- queue display: green highlight behind first slot
    add("box["..(AC_REC_X - 0.125)..",4.725;1.25,1.25;#00AA0066]")
    local q_inv_name = data.ac_queue_inv_name or ""
    add("list[detached:"..q_inv_name..";queue;"..AC_REC_X..",4.85;4,1;0]")
  end

  -- output inventory (normal slots, always visible when any upgrade is installed)
  local outInvName = get_or_create_output_inv(pos)
  add("label["..AC_REC_X..",6.3;"..S("Output:").."]")
  add("list[detached:"..outInvName..";"..AC_OUTPUT_LIST..";"..AC_REC_X..",6.5;4,3;0]")
  add("listring[detached:"..outInvName..";"..AC_OUTPUT_LIST.."]")
  add("listring[current_player;main]")

  return table.concat(out)
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
    "tabheader[0,0;"..TAB_BTN..";"..S(" Main ")..","..S("Mass Storage")..","..S("Supply Chests")..","..S("Easy Crafting")..";"..tab..";false;true]"

  local topContent
  if tab == 2 then
    topContent = get_storage_tab_content(pos, playerName)
  elseif tab == 3 then
    topContent = get_supply_tab_content(pos, playerName)
  elseif tab == 4 then
    topContent = get_autocrafting_tab_content(pos, playerName)
  else
    local filterHighImg = logistica.access_point_get_filter_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
    local sortHighImg = logistica.access_point_get_sort_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
    local pageInfo = logistica.access_point_get_current_page_info(pos, playerName, FAKE_INV_SIZE, meta)
    local usesMetadata = logistica.access_point_is_set_to_use_metadata(pos)
    local searchTerm = minetest.formspec_escape(logistica.access_point_get_current_search_term(meta))
    local usesMetaStr = usesMetadata and S("Metadata: ON") or S("Metadata: OFF")
    local filterSortYOff = TAB_Y + 0.5
    local liquidInsertYOff = TAB_Y + 1.0
    local networkSearchYOff = TAB_Y + 1.0
    topContent =
      "list[detached:"..invName..";"..INV_FAKE..";0.2,"..(0.2+TAB_Y)..";"..FAKE_INV_W..","..FAKE_INV_H..";0]"..
      "image[3.2,"..(6.5+liquidInsertYOff)..";0.8,0.8;logistica_icon_input.png]"..
      "list[detached:"..invName..";"..INV_INSERT..";4.0,"..(6.4+liquidInsertYOff)..";1,1;0]"..
      get_error_display(5.2, 7.6+liquidInsertYOff, optError)..
      get_liquid_section(invName, meta, playerName, liquidInsertYOff + 0.6)..
      get_listrings(invName)..
      get_filter_section(usesMetaStr, filterHighImg, filterSortYOff)..
      get_tooltips()..
      get_sort_section(sortHighImg, filterSortYOff)..
      "label[5.3,"..(6.3+networkSearchYOff)..";"..S("Network: ")..currentNetwork.."]"..
      get_search_and_page_section(searchTerm, pageInfo, networkSearchYOff)..
      get_deposit_section(9.9)
  end

  local formH   = AC_FORM_H_AC
  local plrInvY = AC_PLAYER_INV_Y_AC
  local craftYOff = AC_PLAYER_INV_Y_AC - AP_PLAYER_INV_Y
  local trashInvName = get_or_create_trash_inv(pos)

  return "formspec_version[4]"..
    "size["..logistica.inv_size(15.2, formH).."]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    tabHeader..
    topContent..
    logistica.player_inv_formspec(AP_PLAYER_INV_X, plrInvY)..
    "label[1.7,"..(9.1+TAB_Y+craftYOff)..";"..S("Trash slot").."]"..
    "list[detached:"..trashInvName..";"..AP_TRASH_LIST..";1.7,"..(9.4+TAB_Y+craftYOff)..";1,1;]"..
    "label[1.7,"..(11.1+TAB_Y+craftYOff)..";"..S("Last deleted item").."]"..
    "list[detached:"..trashInvName..";"..AP_TRASH_DST_LIST..";1.7,"..(11.4+TAB_Y+craftYOff)..";1,1;]"..
    "listring[detached:"..trashInvName..";"..AP_TRASH_DST_LIST.."]"..
    "listring[current_player;main]"
end

local function clear_stale_ac_queue(pos)
  local posHash = minetest.hash_node_position(pos)
  if activeAcQueues[posHash] then return end
  local meta = minetest.get_meta(pos)
  if meta:get_string("ac_queue") == "" and meta:get_string("ac_pending_to_take") == "" then return end
  meta:set_string("ac_queue", "")
  meta:set_string("ac_pending_to_take", "")
  meta:set_string("ac_pending_to_give", "")
  meta:set_string("ac_pending_output", "")
  meta:set_int("ac_queue_pos", 0)
  meta:set_int("ac_queue_cur_count", 0)
end

local function ensure_ap_inventories(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:get_size(logistica.AP_UPGRADE_LIST) < 1 then inv:set_size(logistica.AP_UPGRADE_LIST, 1) end
  get_or_create_output_inv(pos)
  get_or_create_trash_inv(pos)
  clear_stale_ac_queue(pos)
end

local function show_access_point_formspec(pos, playerName, optError)
  ensure_ap_inventories(pos)
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
    position          = pos,
    invName           = invName,
    storFilterInvName = get_or_create_storage_filter_inv(playerName),
    ac_queue_inv_name = get_or_create_queue_inv(playerName),
    supplyInvName     = get_or_create_supply_inv(playerName),
    tab               = prev.tab or 1,
    storPage          = prev.storPage or 1,
    storMapping       = prev.storMapping or {},
    supplyPage        = prev.supplyPage or 1,
    supplyChestPos    = prev.supplyChestPos,
    supplyChestPage   = prev.supplyChestPage or 1,
    ac_search         = prev.ac_search  or "",
    ac_results        = prev.ac_results or {},
    ac_res_page       = prev.ac_res_page or 1,
    ac_history        = prev.ac_history or {},
    ac_hist_pos       = prev.ac_hist_pos or 0,
    ac_error          = prev.ac_error,
    ac_use_player_inv = prev.ac_use_player_inv or false,
    from_wap          = prev.from_wap or false,
    ac_rec_lines      = prev.ac_rec_lines or {},
    ac_rec_plan       = prev.ac_rec_plan,
  }

  local ac_meta = minetest.get_meta(pos)
  local queue_str = ac_meta:get_string("ac_queue")
  if queue_str ~= "" then
    local queue = minetest.deserialize(queue_str)
    if queue then
      local q_pos   = ac_meta:get_int("ac_queue_pos")
      local q_count = ac_meta:get_int("ac_queue_cur_count")
      ac_populate_queue_display(accessPointForms[playerName], ac_queue_display_items(queue, q_pos, q_count))
    end
  end

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

-- tries to deposit every stack in the player's main inventory into the network, per the given
-- restrictions; returns an error string if nothing at all could be deposited, else nil
local function deposit_player_inventory(pos, player, ignoreRequesters, ignoreStorages, ignoreSuppliers, storageKind)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return S("Access Point not connected to any network") end

  local inv = player:get_inventory()
  local size = inv:get_size("main")
  local depositedAny = false
  for i = 1, size do
    local stack = inv:get_stack("main", i)
    if not stack:is_empty() then
      local origCount = stack:get_count()
      local leftover = logistica.insert_item_in_network(
        stack, networkId, false, ignoreRequesters, ignoreStorages, ignoreSuppliers, true, false, storageKind)
      if leftover < origCount then depositedAny = true end
      if leftover <= 0 then
        inv:set_stack("main", i, ItemStack(""))
      else
        stack:set_count(leftover)
        inv:set_stack("main", i, stack)
      end
    end
  end

  if not depositedAny then return S("Nothing to deposit") end
  return nil
end

function logistica.on_receive_access_point_formspec(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  if not accessPointForms[playerName] then return true end
  local pos = accessPointForms[playerName].position
  if not pos or not logistica.player_has_network_access(pos, playerName) then return true end

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
  elseif fields[SUPPLY_PREV_BTN] then
    local data = accessPointForms[playerName]
    local total = get_total_supplier_pages(pos)
    data.supplyPage = (((data.supplyPage or 1) - 2) % total) + 1
    data.supplyChestPage = 1
  elseif fields[SUPPLY_NEXT_BTN] then
    local data = accessPointForms[playerName]
    local total = get_total_supplier_pages(pos)
    data.supplyPage = ((data.supplyPage or 1) % total) + 1
    data.supplyChestPage = 1
  elseif fields["sup_chest_page"] then -- SUPPLY_CHEST_PAGE_BTN, hardcoded here to avoid adding another
    advance_supply_chest_page(playerName)                                 -- upvalue to this already near-the-limit function
  elseif fields[SUPPLY_SORT_NAME_BTN] then
    local data = accessPointForms[playerName]
    if data.supplyChestPos and logistica.player_has_network_access(data.supplyChestPos, playerName) then
      logistica.sort_supplier_inventory(data.supplyChestPos, LOG_SORT_NAME_AZ)
    end
  elseif fields[SUPPLY_SORT_MOD_BTN] then
    local data = accessPointForms[playerName]
    if data.supplyChestPos and logistica.player_has_network_access(data.supplyChestPos, playerName) then
      logistica.sort_supplier_inventory(data.supplyChestPos, LOG_SORT_MOD_AZ)
    end
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
  elseif fields[SEARCH_BTN] or fields.key_enter_field == SEARCH_FIELD then
    logistica.access_point_on_search_change(pos, fields[SEARCH_FIELD])
  elseif fields[LIQUID_PREV_BTN] then
    if not logistica.access_point_change_liquid(minetest.get_meta(pos),-1, playerName) then return true end
  elseif fields[LIQUID_NEXT_BTN] then
    if not logistica.access_point_change_liquid(minetest.get_meta(pos), 1, playerName) then return true end
  elseif fields[DEPOSIT_ALL_BTN] then
    local err = deposit_player_inventory(pos, player, false, false, false, nil)
    show_access_point_formspec(pos, playerName, err)
    return true
  elseif fields[DEPOSIT_MASS_BTN] then
    local err = deposit_player_inventory(pos, player, true, false, true, "mass")
    show_access_point_formspec(pos, playerName, err)
    return true
  elseif fields[DEPOSIT_SUPPLY_BTN] then
    local err = deposit_player_inventory(pos, player, true, true, false, nil)
    show_access_point_formspec(pos, playerName, err)
    return true
  elseif fields[DEPOSIT_TOOL_BTN] then
    local err = deposit_player_inventory(pos, player, true, false, true, "item")
    show_access_point_formspec(pos, playerName, err)
    return true
  else
    -- autocrafting tab handlers
    local data = accessPointForms[playerName]

    local res_clicked = nil
    for i = 1, AC_RESULTS_PER_PAGE do
      if fields[AC_RESULT_BTN..i] then res_clicked = i; break end
    end

    local rcp_clicked = nil
    for i = 1, 9 do
      if fields[AC_RECIPE_BTN..i] then rcp_clicked = i; break end
    end

    if fields[AC_SEARCH_BTN] or fields.key_enter_field == AC_SEARCH_FIELD then
      local term = fields[AC_SEARCH_FIELD] or ""
      data.ac_search  = term
      data.ac_results = #term >= 2 and logistica.ac_search(term) or {}
      data.ac_res_page = 1
      data.ac_error    = nil

    elseif fields[AC_PREV_RES_BTN] then
      local total = math.max(1, math.ceil(#(data.ac_results) / AC_RESULTS_PER_PAGE))
      data.ac_res_page = (((data.ac_res_page or 1) - 2) % total) + 1
      data.ac_error = nil

    elseif fields[AC_NEXT_RES_BTN] then
      local total = math.max(1, math.ceil(#(data.ac_results) / AC_RESULTS_PER_PAGE))
      data.ac_res_page = ((data.ac_res_page or 1) % total) + 1
      data.ac_error = nil

    elseif res_clicked then
      local idx   = ((data.ac_res_page or 1) - 1) * AC_RESULTS_PER_PAGE + res_clicked
      local entry = (data.ac_results or {})[idx]
      if entry then ac_navigate_to(data, entry.name, 1) end

    elseif fields[AC_PREV_RCP_BTN] then
      local cur = data.ac_history[data.ac_hist_pos]
      if cur then
        local e = logistica.ac_get_entry(cur.name)
        if e and #e.recipes > 0 then
          cur.recipe_idx = ((cur.recipe_idx - 2) % #e.recipes) + 1
        end
      end
      data.ac_error = nil

    elseif fields[AC_NEXT_RCP_BTN] then
      local cur = data.ac_history[data.ac_hist_pos]
      if cur then
        local e = logistica.ac_get_entry(cur.name)
        if e and #e.recipes > 0 then
          cur.recipe_idx = (cur.recipe_idx % #e.recipes) + 1
        end
      end
      data.ac_error = nil

    elseif rcp_clicked then
      local cur = data.ac_history[data.ac_hist_pos]
      if cur then
        local e = logistica.ac_get_entry(cur.name)
        if e then
          local recipe = e.recipes[cur.recipe_idx]
          if recipe then
            local item_str = recipe.raw_items[rcp_clicked]
            if item_str and item_str ~= "" then
              local item_name = ItemStack(item_str):get_name()
              if logistica.ac_get_entry(item_name) then
                ac_navigate_to(data, item_name, 1)
              end
            end
          end
        end
      end

    elseif fields[AC_BACK_BTN] then
      if (data.ac_hist_pos or 0) > 1 then
        data.ac_hist_pos = data.ac_hist_pos - 1
        data.ac_error = nil
      end

    elseif fields[AC_FWD_BTN] then
      if (data.ac_hist_pos or 0) < #(data.ac_history or {}) then
        data.ac_hist_pos = data.ac_hist_pos + 1
        data.ac_error = nil
      end

    elseif fields[AC_USE_PLR_INV] then
      data.ac_use_player_inv = fields[AC_USE_PLR_INV] == "true"
      data.ac_error = nil

    elseif fields[AC_CRAFT_BTN] then
      if activeAcQueues[minetest.hash_node_position(pos)] then
        data.ac_error = S("Crafting in progress")
      else
        ac_handle_craft(pos, data, player, 1)
      end

    elseif fields[AC_CRAFT10_BTN] then
      if activeAcQueues[minetest.hash_node_position(pos)] then
        data.ac_error = S("Crafting in progress")
      else
        ac_handle_craft(pos, data, player, 10)
      end

    elseif fields[AC_REC_CHECK_BTN] then
      if activeAcQueues[minetest.hash_node_position(pos)] then
        data.ac_rec_lines = {"Crafting in progress"}
      else
        ac_handle_recursive_check(pos, data)
      end

    elseif fields[AC_REC_CRAFT_BTN] then
      if activeAcQueues[minetest.hash_node_position(pos)] then
        data.ac_rec_lines = {"Crafting in progress"}
      else
        ac_handle_recursive_craft(pos, data)
      end
    end
  end
  show_access_point_formspec(pos, playerName)
  return true
end

function logistica.get_ac_output_inv(pos)
  local invName = get_or_create_output_inv(pos)
  return minetest.get_inventory({type = "detached", name = invName})
end

function logistica.sync_ac_output_to_meta(pos)
  sync_output_to_meta(pos)
end

function logistica.access_point_after_place(pos, meta)
  meta:set_string("infotext", S("Access Point"))
end

function logistica.access_point_allow_put(inv, listname, index, stack, player)
  if listname == INV_FAKE then return 0 end

  local pos = get_curr_pos(player)
  if not pos then return 0 end
  if not logistica.get_network_or_nil(pos) then return 0 end
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end

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
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end

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
      taken:get_meta():set_string("count_meta", "")
      inv:set_stack(listname, index, taken)
      return math.min(taken:get_count(), stackMax)
    else -- individual items are trickier
      -- we want to take the actual item, so place it in the slot before its taken
      local useMetadata = logistica.access_point_is_set_to_use_metadata(pos)
      local taken = nil
      local acceptTaken = function(st) taken = st; return 0 end

      -- count_meta is only for display in the fake inventory - strip it so metadata comparisons
      -- against the actual stored stack (which never has count_meta) succeed
      stack:get_meta():set_string("count_meta", "")

      -- for the rare case where two items got stacked despite using metadata
      local takeResult = logistica.take_stack_from_network(stack, network, acceptTaken, false, useMetadata, true)
      local error = nil ; if not takeResult.success then error = takeResult.error end

      if not taken or taken:is_empty() then
        show_access_point_formspec(pos, player:get_player_name(), error)
        return 0
      end
      -- remove the sometimes manually added count display - and set the stack in the inventory slot
      taken:get_meta():set_string("count_meta", "")
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
  local pname = clicker:get_player_name()
  if accessPointForms[pname] then accessPointForms[pname].from_wap = false end
  show_access_point_formspec(pos, pname)
end

function logistica.access_point_open_from_wap(pos, playerName)
  logistica.try_to_wake_up_network(pos)
  if not accessPointForms[playerName] then accessPointForms[playerName] = {} end
  accessPointForms[playerName].from_wap = true
  show_access_point_formspec(pos, playerName)
end

function logistica.access_point_on_player_leave(playerName)
  local info = accessPointForms[playerName]
  if info and info.invName then
    local onlyRef = true
    for pName, otherInfo in pairs(accessPointForms) do
      if pName ~= playerName and otherInfo.invName == info.invName then onlyRef = false end
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
  if queueInventories[playerName] then
    minetest.remove_detached_inventory(queueInventories[playerName])
    queueInventories[playerName] = nil
  end
  if supplyInventories[playerName] then
    minetest.remove_detached_inventory(supplyInventories[playerName])
    supplyInventories[playerName] = nil
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
  local posHash = minetest.hash_node_position(pos)
  local trashInvName = trashInventories[posHash]
  if trashInvName then
    minetest.remove_detached_inventory(trashInvName)
    trashInventories[posHash] = nil
  end
  local invName = outputInventories[posHash]
  if invName then
    minetest.remove_detached_inventory(invName)
    outputInventories[posHash] = nil
  end
end

function logistica.access_point_is_player_using_ap(playerName)
  return accessPointForms[playerName] ~= nil
end

function logistica.access_point_show_for_player(pos, playerName)
  show_access_point_formspec(pos, playerName)
end

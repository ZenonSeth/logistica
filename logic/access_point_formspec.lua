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

local INV_FAKE = "fake"
local INV_CRAFT = "craft"
local INV_CRAFT_OUTPUT = "output"
local INV_INSERT = "isert"
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

local ACCESS_POINT_TIMER = 1

local accessPointForms = {}



----------------------------------------------------------------
-- formspec
----------------------------------------------------------------

local function get_access_point_formspec(pos, optMeta, playerName)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local meta = optMeta or minetest.get_meta(pos)
  local currentNetwork = logistica.get_network_name_or_nil(pos) or S("<NONE>")
  local filterHighImg = logistica.access_point_get_filter_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
  local sortHighImg = logistica.access_point_get_sort_highlight_images(meta, IMG_HIGHLGIHT, IMG_BLANK)
  local pageInfo = logistica.access_point_get_current_page_info(pos, playerName, FAKE_INV_SIZE, meta)
  local usesMetadata = logistica.access_point_is_set_to_use_metadata(pos)
  local searchTerm = minetest.formspec_escape(logistica.access_point_get_current_search_term(meta))
  local usesMetaStr = usesMetadata and S("Metadata: ON") or S("Metadata: OFF")
  return "formspec_version[4]"..
    "size[15.2,12.5]"..
    logistica.ui.background..
    "list["..posForm..";"..INV_FAKE..";0.2,0.2;"..FAKE_INV_W..","..FAKE_INV_H..";0]"..
    "image[2.8,6.4;1,1;logistica_icon_input.png]"..
    "list["..posForm..";"..INV_INSERT..";3.8,6.4;1,1;0]"..
    "list[current_player;main;5.2,7.5;8.0,4.0;0]"..
    "listring[]"..
    -- "label[1.4,12.2;"..S("Crafting").."]"..
    -- "list["..posForm..";"..INV_CRAFT..";0.2,8.4;3,3;0]"..
    -- "list["..posForm..";"..INV_CRAFT_OUTPUT..";3.9,8.4;1,1;0]"..
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
    "image_button[8.8,5.1;0.8,0.8;"..IMG_FILT_LIGHT..";"..FILTER_LIGHTS_BTN..";;false;false;]"..
    "label[10.5,5.5;"..S("Sort").."]"..
    "image[11.0,5;1,1;"..sortHighImg.name.."]"..
    "image[11.9,5;1,1;"..sortHighImg.mod.."]"..
    "image[12.8,5;1,1;"..sortHighImg.count.."]"..
    "image[13.7,5;1,1;"..sortHighImg.wear.."]"..
    "image_button[11.1,5.1;0.8,0.8;"..IMG_SORT_NAME..";"..SORT_NAME_BTN..";;false;false;]"..
    "image_button[12.0,5.1;0.8,0.8;"..IMG_SORT_MOD..";"..SORT_MOD_BTN..";;false;false;]"..
    "image_button[12.9,5.1;0.8,0.8;"..IMG_SORT_COUNT..";"..SORT_COUNT_BTN..";;false;false;]"..
    "image_button[13.8,5.1;0.8,0.8;"..IMG_SORT_WEAR..";"..SORT_WEAR_BTN..";;false;false;]"..
    "label[5.3,6.3;"..S("Network: ")..currentNetwork.."]"..
    "field[5.2,6.5;2.8,0.8;"..SEARCH_FIELD..";;"..searchTerm.."]"..
    "field_close_on_enter["..SEARCH_FIELD..";false]"..
    "image_button[8.1,6.5;0.8,0.8;logistica_icon_search.png;"..SEARCH_BTN..";;false;false;]"..
    "image_button[9.2,6.5;0.8,0.8;logistica_icon_cancel.png;"..CLEAR_BTN..";;false;false;]"..
    "label[12.0,6.3;"..S("Page")..": "..pageInfo.curr.." / "..pageInfo.max.."]"..
    "image_button[10.6,6.5;0.8,0.8;logistica_icon_first.png;"..FRST_BTN..";;false;false;]"..
    "image_button[11.7,6.5;0.8,0.8;logistica_icon_prev.png;"..PREV_BTN..";;false;false;]"..
    "image_button[12.8,6.5;0.8,0.8;logistica_icon_next.png;"..NEXT_BTN..";;false;false;]"..
    "image_button[13.9,6.5;0.8,0.8;logistica_icon_last.png;"..LAST_BTN..";;false;false;]"
    -- TODO tooltips
end

local function show_access_point_formspec(pos, playerName, optMeta)
  local meta = optMeta or minetest.get_meta(pos)
  accessPointForms[playerName] = { position = pos }
  logistica.access_point_refresh_fake_inv(pos, INV_FAKE, FAKE_INV_SIZE, playerName)
  minetest.show_formspec(
    playerName,
    FORMSPEC_NAME,
    get_access_point_formspec(pos, meta, playerName)
  )
end

----------------------------------------------------------------
-- callbacks
----------------------------------------------------------------

function logistica.on_receive_access_point_formspec(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  if not accessPointForms[playerName] then return true end
  local pos = accessPointForms[playerName].position
  if minetest.is_protected(pos, playerName) or not pos then return true end

  if fields.quit and not fields.key_enter_field then
    accessPointForms[playerName] = nil
    logistica.access_point_on_player_close(playerName)
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
  end
  show_access_point_formspec(pos, playerName)
  return true
end

function logistica.access_point_after_place(pos, meta)
  local inv  = meta:get_inventory()
  inv:set_size(INV_FAKE, FAKE_INV_SIZE)
  inv:set_size(INV_CRAFT, 9)
  inv:set_width(INV_CRAFT, 3)
  inv:set_size(INV_CRAFT_OUTPUT, 1)
  inv:set_size(INV_INSERT, 1)
end

function logistica.access_point_allow_put(pos, listname, index, stack, player)
  if listname == INV_FAKE or listname == INV_CRAFT_OUTPUT then return 0 end
  return stack:get_count()
end

function logistica.access_point_allow_take(pos, listname, index, _stack, player)
  local stack = ItemStack(_stack)
  if listname == INV_FAKE then
    local network = logistica.get_network_or_nil(pos)
    if not network then
      show_access_point_formspec(pos, player:get_player_name())
      return 0
    end
    -- either way, only allow taking up to stack max
    stack:set_count(math.min(stack:get_count(), stack:get_stack_max()))
    if stack:get_stack_max() > 1 then
      local taken = nil
      local acceptTaken = function(st) taken = st; return 0 end
      logistica.take_stack_from_network(stack, network, acceptTaken)
      if not taken or taken:is_empty() then return 0 end
      return math.min(taken:get_count(), stack:get_stack_max())
    else -- individual items are trickier 
      -- we want to take the actual item, so place it in the slot before its taken
      local useMetadata = logistica.access_point_is_set_to_use_metadata(pos)
      local taken = nil
      local acceptTaken = function(st) taken = st; return 0 end
      logistica.take_stack_from_network(stack, network, acceptTaken, false, useMetadata)
      if not taken or taken:is_empty() then return 0 end
      local inv = minetest.get_meta(pos):get_inventory()
      inv:set_stack(listname, index, taken)
      return taken:get_count()
    end
  end
  return stack:get_count()
end

function logistica.access_point_allow_move(pos, from_list, from_index, to_list, to_index, count, player)
  if from_list == INV_FAKE or to_list == INV_FAKE or to_list == INV_CRAFT_OUTPUT then return 0 end
  return count
end

function logistica.access_point_on_inv_move(pos, from_list, from_index, to_list, to_index, count, player)

end

function logistica.access_point_on_put(pos, listname, index, stack, player)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then show_access_point_formspec(pos, player:get_player_name()) ; return end
  if listname == INV_INSERT then
    local leftover = logistica.insert_item_in_network(stack, networkId)
    stack:set_count(leftover)
    minetest.get_meta(pos):get_inventory():set_stack(listname, index, stack)
    show_access_point_formspec(pos, player:get_player_name())
  end
end

function logistica.access_point_on_take(pos, listname, index, stack, player)
  if listname == INV_FAKE then
    -- refresh the page in case we had to swap out a fake item or a stack is gone
    logistica.access_point_refresh_fake_inv(pos, listname, FAKE_INV_SIZE, player:get_player_name())
  end
end

function logistica.access_point_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
  show_access_point_formspec(pos, clicker:get_player_name())
end
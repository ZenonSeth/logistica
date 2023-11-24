local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "logistica_sync"

-- local META_LAVA = "loglav"
local META_F1 = "crf1"
local META_S1 = "crs1"
local META_F2 = "crf2"
local META_S2 = "crs2"
local META_TF1 = "tarf1"
local META_TS1 = "tars1"
local META_TF2 = "tarf2"
local META_TS2 = "tars2"

-- local MAX_LAVA_AMOUNT = 2000 -- in millibuckets

local FUP1_BTN = "FUP1"
local FDN1_BTN = "FDN1"
local SR1_BTN = "SR1"
local SL1_BTN = "SL1"
local FUP2_BTN = "FUP2"
local FDN2_BTN = "FDN2"
local SR2_BTN = "SR2"
local SL2_BTN = "SL2"
local APPLY_BUTTON = "APPLY"

local INV_C1 = "invc1"
local INV_C2 = "invc2"
local INV_UPGRADE = "upgr"

local THIRD_PI = 3.1415926 / 3
local FREQ_MIN = 200
local FREQ_MAX = 2000
local FREQ_STEP = 50
local SHIFT_MAX = 3000
local SHIFT_MIN = -3000
local SHIFT_STEP = 500
local DISPLAY_FACTOR = 1000.0
local GRAPH_XMIN = -35.0
local GRAPH_XSIZE = 70.0
local GRAPH_YMIN = -2.2
local GRAPH_YSIZE = 4.4
local GRAPH_STEP = 0.1
-- derived
local SHIFT_NUM_STEPS = (SHIFT_MAX - SHIFT_MIN) / SHIFT_STEP
local FREQ_NUM_STEPS = (FREQ_MAX - FREQ_MIN) / FREQ_STEP
local BOX_SIZE = math.min(GRAPH_STEP / 2, 0.02)
local BOX_W = BOX_SIZE * 2

local ITEM_WIRELESS_CRYSTAL = "logistica:wireless_crystal"
local ITEM_WAP = "logistica:wireless_access_pad"

local COLOR_TARGET = "#6BA1FFFF"
local COLOR_PTS_NO_MATCH = "#FFB300FF"
local COLOR_PTS_MATCH = "#CCFF00FF"

local forms = {}
local get_meta = minetest.get_meta

local HARD_MODE = logistica.settings.wifi_upgrader_hard_mode
local WAP_RANGE_UPGRADE = logistica.settings.wap_upgrade_step
local WAP_MAX_RANGE = logistica.settings.wap_max_range

----------------------------------------------------------------
-- local funcs
----------------------------------------------------------------

-- returns true if there was enough lava (and was used), false if not
-- local function use_lava(meta, amount)
--   local currLevel = meta:get_int(META_LAVA)
--   if currLevel - amount >= 0 then
--     meta:set_int(META_LAVA, currLevel - amount)
--     return true
--   else
--     return false
--   end
-- end

-- local function get_lava_level(meta)
--   return meta:get_int(META_LAVA)
-- end

-- -- returns y value for f(x) with given params
local function f(x, freq, shift)
  return math.sin( freq * x + shift * THIRD_PI )
end

local function both_crystals_present(inv)
  return (not inv:is_empty(INV_C1)) and (not inv:is_empty(INV_C2))
end

local function change_freq(meta, crysNum, change)
  local META_F = META_F1 ; if crysNum ~= 1 then META_F = META_F2 end
  local curF = meta:get_int(META_F)
  local newF = logistica.clamp(curF + change * FREQ_STEP, FREQ_MIN, FREQ_MAX)
  meta:set_int(META_F, newF)
end

local function change_shift(meta, crysNum, change)
  local META_S = META_S1 ; if crysNum ~= 1 then META_S = META_S2 end
  local curS = meta:get_int(META_S)
  local newS = curS + change * SHIFT_STEP
  if newS >= SHIFT_MAX then
    meta:set_int(META_S, SHIFT_MIN)
  elseif newS <= SHIFT_MIN then
    meta:set_int(META_S, SHIFT_MAX)
  else
    meta:set_int(META_S, newS)
  end
end

local function waves_match(meta)
  local freq1 = meta:get_int(META_F1)
  local freq2 = meta:get_int(META_F2)
  local shft1 = (HARD_MODE and meta:get_int(META_S1)) or 0
  local shft2 = (HARD_MODE and meta:get_int(META_S2)) or 0
  local freqT1 = meta:get_int(META_TF1)
  local shftT1 = (HARD_MODE and meta:get_int(META_TS1)) or 0
  local freqT2 = meta:get_int(META_TF2)
  local shftT2 = (HARD_MODE and meta:get_int(META_TS2)) or 0
  return (freq1 == freqT1 and shft1 == shftT1 and freq2 == freqT2 and shft2 == shftT2) or
         (freq2 == freqT1 and shft2 == shftT1 and freq1 == freqT2 and shft1 == shftT2)
end

local function apply_to_wap(pos, playerName)
  local meta = get_meta(pos)
  local inv = meta:get_inventory()
  if inv:is_empty(INV_UPGRADE) then return end
  if not both_crystals_present(inv) then return end
  if not waves_match(meta) then return end

  local item = inv:get_stack(INV_UPGRADE, 1)
  local itemMeta = item:get_meta()
  if item:get_name() == ITEM_WAP then
    local currRange = itemMeta:get_int(logistica.tools.wap.meta_range_key)
    if currRange >= WAP_MAX_RANGE then
      minetest.chat_send_player(
        playerName, S("Max range of @1 reached, cannot upgrade WAP further", WAP_MAX_RANGE))
      return
    end
    local newRange = currRange + WAP_RANGE_UPGRADE
    if newRange > WAP_MAX_RANGE then newRange = WAP_MAX_RANGE end
    itemMeta:set_int(logistica.tools.wap.meta_range_key, newRange)
    itemMeta:set_string("description", logistica.tools.wap.get_description_with_range(newRange))
    inv:set_stack(INV_UPGRADE, 1, item)
    inv:set_stack(INV_C1, 1, ItemStack(""))
    inv:set_stack(INV_C2, 1, ItemStack(""))
  end

end

local function set_new_targets(meta, valid)
  local targetF1 = (valid and FREQ_MIN + math.random(0, FREQ_NUM_STEPS) * FREQ_STEP) or 0
  local targetF2 = (valid and FREQ_MIN + math.random(0, FREQ_NUM_STEPS) * FREQ_STEP) or 0
  local targetS1 = (valid and SHIFT_MIN + math.random(0, SHIFT_NUM_STEPS) * SHIFT_STEP) or (SHIFT_MIN - 1)
  local targetS2 = (valid and SHIFT_MIN + math.random(0, SHIFT_NUM_STEPS) * SHIFT_STEP) or (SHIFT_MIN - 1)
  meta:set_int(META_TF1, targetF1)
  meta:set_int(META_TF2, targetF2)
  meta:set_int(META_TS1, targetS1)
  meta:set_int(META_TS2, targetS2)
end

local function randomize_curr_values(meta, valid)
  if not valid then return 0 end
  local cF1 = FREQ_MIN + math.random(0, FREQ_NUM_STEPS) * FREQ_STEP
  local cF2 = FREQ_MIN + math.random(0, FREQ_NUM_STEPS) * FREQ_STEP
  local cS1 = SHIFT_MIN + math.random(0, SHIFT_NUM_STEPS) * SHIFT_STEP
  local cS2 = SHIFT_MIN + math.random(0, SHIFT_NUM_STEPS) * SHIFT_STEP
  meta:set_int(META_F1, cF1)
  meta:set_int(META_F2, cF2)
  meta:set_int(META_S1, cS1)
  meta:set_int(META_S2, cS2)
end

----------------------------------------------------------------
-- formspec
----------------------------------------------------------------

local function box(xy, color)
  return string.format(
    "box[%s,%s;%s,%s;%s]",
    tostring(xy.x - BOX_SIZE), tostring(xy.y - BOX_SIZE), tostring(BOX_W), tostring(BOX_W), color
  )
end

-- returns {x=x, y=y}
local function map(x, y, rx, ry, rw, rh)
  return {
    x = rx + ((x - GRAPH_XMIN) / GRAPH_XSIZE) * rw,
    y = ry + ((y - GRAPH_YMIN) / GRAPH_YSIZE) * rh,
  }
end

local function get_point_boxes(x, y, w, h, f1, s1, f2, s2, color)
  if not color then return "" end
  local pts = {}
  for ptX = GRAPH_XMIN, GRAPH_XMIN + GRAPH_XSIZE, GRAPH_STEP do
    pts[ptX] = f(ptX, f1, s1) + f(ptX, f2, s2)
  end
  return table.concat(
    logistica.table_to_list_indexed(
      pts,
      function(ptX, ptY)
        return box(map(ptX, ptY, x, y, w, h), color)
      end
    )
  )
end

local function get_adjust_buttons()
  local btns = ""
  if HARD_MODE then btns =
    "image_button[2.1,0.8;0.8,0.8;logistica_icon_fup.png;"..FUP1_BTN..";]"..
    "image_button[2.1,1.6;0.8,0.8;logistica_icon_fdn.png;"..FDN1_BTN..";]"..
    "image_button[3.9,0.8;0.8,0.8;logistica_icon_sr.png;"..SR1_BTN..";]"..
    "image_button[3.9,1.6;0.8,0.8;logistica_icon_sl.png;"..SL1_BTN..";]"..
    "image_button[5.8,0.8;0.8,0.8;logistica_icon_fup.png;"..FUP2_BTN..";]"..
    "image_button[5.8,1.6;0.8,0.8;logistica_icon_fdn.png;"..FDN2_BTN..";]"..
    "image_button[7.6,0.8;0.8,0.8;logistica_icon_sr.png;"..SR2_BTN..";]"..
    "image_button[7.6,1.6;0.8,0.8;logistica_icon_sl.png;"..SL2_BTN..";]"
  else btns =
    "image_button[2.1,1.2;0.8,0.8;logistica_icon_fup.png;"..FUP1_BTN..";]"..
    "image_button[3.9,1.2;0.8,0.8;logistica_icon_fdn.png;"..FDN1_BTN..";]"..
    "image_button[5.8,1.2;0.8,0.8;logistica_icon_fup.png;"..FUP2_BTN..";]"..
    "image_button[7.6,1.2;0.8,0.8;logistica_icon_fdn.png;"..FDN2_BTN..";]"
  end
  local tips =
    "tooltip["..FUP1_BTN..";"..S("Increase Frequency").."]"..
    "tooltip["..FDN1_BTN..";"..S("Decrease Frequency").."]"..
    "tooltip["..FUP2_BTN..";"..S("Increase Frequency").."]"..
    "tooltip["..FDN2_BTN..";"..S("Decrease Frequency").."]"
  if HARD_MODE then
    tips = tips..
    "tooltip["..SR1_BTN..";"..S("Shift Right").."]"..
    "tooltip["..SL1_BTN..";"..S("Shift Left").."]"..
    "tooltip["..SR2_BTN..";"..S("Shift Right").."]"..
    "tooltip["..SL2_BTN..";"..S("Shift Left").."]"
  end
  return btns..tips
end

local function get_guide_labels() return
  "label[0.8,6.9;"..S("Target Wave").."]" ..
  "label[0.8,7.4;"..S("Crsyals' Wave").."]" ..
  "box[0.4,6.8;0.3,0.2;"..COLOR_TARGET.."]" ..
  "box[0.4,7.3;0.3,0.2;"..COLOR_PTS_NO_MATCH.."]"
end

local function get_formspec_sync(pos, playerName, optMeta)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local meta = optMeta or get_meta(pos)
  local tf1 = meta:get_int(META_TF1) / DISPLAY_FACTOR
  local ts1 = (HARD_MODE and meta:get_int(META_TS1) / DISPLAY_FACTOR) or 0
  local tf2 = meta:get_int(META_TF2) / DISPLAY_FACTOR
  local ts2 = (HARD_MODE and meta:get_int(META_TS2) / DISPLAY_FACTOR) or 0
  local f1 = meta:get_int(META_F1) / DISPLAY_FACTOR
  local f2 = meta:get_int(META_F2) / DISPLAY_FACTOR
  local s1 = (HARD_MODE and meta:get_int(META_S1) / DISPLAY_FACTOR) or 0
  local s2 = (HARD_MODE and meta:get_int(META_S2) / DISPLAY_FACTOR) or 0
  local valid = both_crystals_present(meta:get_inventory())
  local matching = waves_match(meta)
  local ptsColor = nil
  local tarColor = nil
  local applyBtn = ""
  if valid then
    if matching then
      ptsColor = COLOR_PTS_MATCH
      applyBtn = "button[3.2,6.8;2,0.8;"..APPLY_BUTTON..";"..S("Upgrade").."]"
    else
      tarColor = COLOR_TARGET
      ptsColor = COLOR_PTS_NO_MATCH
    end
  end

  local targBoxes = get_point_boxes(0.3,2.6,10,4, tf1, ts1, tf2, ts2, tarColor)
  local currBoxes = get_point_boxes(0.3,2.6,10,4, f1, s1, f2, s2, ptsColor)

  return "formspec_version[4]"..
    "size[10.5,13]"..
    logistica.ui.background..
    "list[current_player;main;0.4,8;8,4;0]"..
    "list["..posForm..";"..INV_C1..";2.9,1.1;1,1;0]"..
    "list["..posForm..";"..INV_C2..";6.6,1.1;1,1;0]"..
    get_adjust_buttons()..
    "image[4.75,0.6;1,2;logistica_icon_combine.png]"..
    "image[0.3,2.6;10,4;logistica_icon_graph_back.png]"..
    targBoxes..
    currBoxes..
    applyBtn..
    get_guide_labels()..
    "list["..posForm..";"..INV_UPGRADE..";5.3,6.7;1,1;0]"..
    "label[3.0,0.5;Crystal 1]"..
    "label[6.6,0.5;Crystal 2]"..
    "label[6.4,7.2;"..S("Wireless Access Pad").."]"
end

local function show_formspec_sync(playerName, pos, optMeta)
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec_sync(pos, optMeta))
end

----------------------------------------------------------------
-- callbacks
----------------------------------------------------------------

function logistica.sync_on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local info = forms[playerName]
  local pos = info.position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end
  local meta = get_meta(pos)

  if fields.quit then forms[playerName] = nil; return true
  elseif fields[FUP1_BTN] then change_freq(meta, 1,  1)
  elseif fields[FDN1_BTN] then change_freq(meta, 1, -1)
  elseif fields[SR1_BTN] then change_shift(meta, 1, -1)
  elseif fields[SL1_BTN] then change_shift(meta, 1,  1)
  elseif fields[FUP2_BTN] then change_freq(meta, 2,  1)
  elseif fields[FDN2_BTN] then change_freq(meta, 2, -1)
  elseif fields[SR2_BTN] then change_shift(meta, 2, -1)
  elseif fields[SL2_BTN] then change_shift(meta, 2,  1)
  elseif fields[APPLY_BUTTON] then apply_to_wap(pos, playerName)
  end
  show_formspec_sync(playerName, pos, meta)
  return true
end

function logistica.sync_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
  for k, _ in pairs(forms) do
    logistica.show_popup(clicker:get_player_name(), S("Someone is currently using this Upgrader!"))
    return
  end
  forms[clicker:get_player_name()] = {
    position = pos
  }
  show_formspec_sync(clicker:get_player_name(), pos)
end

function logistica.sync_after_place(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  logistica.set_infotext(pos, S("Wireless Upgrader"))
  local inv = meta:get_inventory()
  inv:set_size(INV_C1, 1)
  inv:set_size(INV_C2, 1)
  inv:set_size(INV_UPGRADE, 1)
  set_new_targets(meta, false)
end

function logistica.sync_allow_storage_inv_put(pos, listname, index, stack, player)
  local inv = minetest.get_meta(pos):get_inventory()
  if listname == INV_C1 or listname == INV_C2 then
    if not inv:get_stack(listname, index):is_empty() then return 0 end
    if stack:get_name() ~= ITEM_WIRELESS_CRYSTAL then return 0
    else return 1 end
  elseif listname == INV_UPGRADE then
    if stack:get_name() ~= ITEM_WAP then return 0
    else return 1 end
  end
  return 0
end

function logistica.sync_allow_inv_take(pos, listname, index, stack, player)
  return 1
end

function logistica.sync_on_inv_put(pos, listname, index, stack, player)
  if not player then return end
  if listname == INV_C1 or listname == INV_C2 then
    if not forms[player:get_player_name()] then return end
    local meta = get_meta(pos)
    if both_crystals_present(meta:get_inventory()) then
      set_new_targets(meta, true)
      randomize_curr_values(meta, true)
    end
    show_formspec_sync(player:get_player_name(), pos)
  end
end

function logistica.sync_on_inv_take(pos, listname, index, stack, player)
  if not player then return end
  if listname == INV_C1 or listname == INV_C2 then
    if not forms[player:get_player_name()] then return end
    set_new_targets(get_meta(pos), false)
    show_formspec_sync(player:get_player_name(), pos)
  end
end

function logistica.sync_can_dig(pos)
  local inv = get_meta(pos):get_inventory()
  return inv:is_empty(INV_C1) and inv:is_empty(INV_C2) and inv:is_empty(INV_UPGRADE)
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(logistica.sync_on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, _)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

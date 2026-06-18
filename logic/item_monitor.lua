local S  = logistica.TRANSLATOR
local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logistica:item_monitor"
local NUM_SLOTS     = 8
local MAX_SAMPLES   = 60
local INTERVALS     = {5, 60, 600, 3600}
local INTERVAL_LABELS = {"5 sec", "1 min", "10 min", "1 hr"}
local DEFAULT_IDX   = 2
local ON_OFF_BTN = "onffbtn"

local ITEM_COLORS = {
  "#FF5533FF",
  "#33FF77FF",
  "#4488FFFF",
  "#FFEE33FF",
  "#FF44EEFF",
  "#33EEFFFF",
  "#FF9933FF",
  "#BB55FFFF",
}

local GRAPH_X  = 0.3
local GRAPH_Y  = 0.3
local GRAPH_W  = 10.0
local GRAPH_H  = 4.0
local DOT_SIZE = 0.065

local SLOT_START_X = 0.50
local SLOT_Y       = 4.85
local COLOR_DOT_Y  = 5.85
local COUNT_LBL_Y  = 6.20

local META_IDX = "interval_idx"

local forms = {}

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------

local function get_interval_idx(meta)
  local idx = meta:get_int(META_IDX)
  if idx < 1 or idx > #INTERVALS then return DEFAULT_IDX end
  return idx
end

local function get_interval(meta)
  return INTERVALS[get_interval_idx(meta)]
end

local function save_history(meta, slot, history)
  meta:set_string("hist_" .. slot, table.concat(history, ","))
end

local function load_history(meta, slot)
  local s = meta:get_string("hist_" .. slot)
  if not s or s == "" then return {} end
  local hist = {}
  for v in s:gmatch("[^,]+") do
    hist[#hist + 1] = tonumber(v) or 0
  end
  return hist
end

local function clear_all_history(meta)
  for i = 1, NUM_SLOTS do
    meta:set_string("hist_" .. i, "")
  end
end

local function format_count(n)
  if n >= 1000000 then
    return string.format("%.1fM", n / 1000000)
  elseif n >= 10000 then
    return string.format("%.0fk", n / 1000)
  elseif n >= 1000 then
    return string.format("%.1fk", n / 1000)
  else
    return tostring(n)
  end
end

----------------------------------------------------------------
-- graph rendering
----------------------------------------------------------------

local function map_gx(sample_idx)
  if MAX_SAMPLES <= 1 then return GRAPH_X + GRAPH_W * 0.5 end
  return GRAPH_X + (sample_idx / (MAX_SAMPLES - 1)) * GRAPH_W
end

local function map_gy(count, min_count, max_count)
  local range = max_count - min_count
  local ratio = (range > 0) and ((count - min_count) / range) or 0.5
  -- ratio=0 -> near bottom, ratio=1 -> near top (y increases downward)
  return GRAPH_Y + GRAPH_H * 0.96 - ratio * GRAPH_H * 0.90
end

local function build_graph(pos)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()

  local max_count = nil
  local min_count = nil
  local histories = {}
  local item_names = {}
  for i = 1, NUM_SLOTS do
    local stack = inv:get_stack("filter", i)
    if not stack:is_empty() then
      local hist = load_history(meta, i)
      histories[i] = hist
      item_names[i] = stack:get_short_description()
      for _, v in ipairs(hist) do
        if not max_count or v > max_count then max_count = v end
        if not min_count or v < min_count then min_count = v end
      end
    end
  end

  -- no data yet
  if not max_count then max_count = 1 ; min_count = 0 end
  -- if all values are equal, expand the range by 1 so the line sits in the middle
  if min_count == max_count then
    min_count = min_count - 1
    max_count = max_count + 1
  end

  local parts = {}
  -- Y-axis labels: max at top-left, min at bottom-left
  parts[#parts + 1] = string.format("label[%.2f,%.2f;%s]",
    GRAPH_X + 0.08, GRAPH_Y + 0.18, format_count(max_count))
  parts[#parts + 1] = string.format("label[%.2f,%.2f;%s]",
    GRAPH_X + 0.08, GRAPH_Y + GRAPH_H - 0.35, format_count(min_count))

  for i = 1, NUM_SLOTS do
    local hist = histories[i]
    if hist and #hist > 0 then
      local color  = ITEM_COLORS[i]
      local offset = MAX_SAMPLES - #hist
      local name   = item_names[i] or ""
      for j, count in ipairs(hist) do
        local sx = map_gx(offset + j - 1)
        local sy = map_gy(count, min_count, max_count)
        parts[#parts + 1] = string.format(
          "box[%.3f,%.3f;%.3f,%.3f;%s]",
          sx - DOT_SIZE, sy - DOT_SIZE, DOT_SIZE * 2, DOT_SIZE * 2, color
        )
        parts[#parts + 1] = string.format(
          "tooltip[%.3f,%.3f;%.3f,%.3f;%s]",
          sx - DOT_SIZE, sy - DOT_SIZE, DOT_SIZE * 2, DOT_SIZE * 2,
          minetest.formspec_escape(name .. "\n" .. format_count(count))
        )
      end
    end
  end

  return table.concat(parts)
end

local function build_slot_indicators(pos)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  local parts = {}

  for i = 1, NUM_SLOTS do
    local stack = inv:get_stack("filter", i)
    if not stack:is_empty() then
      local hist  = load_history(meta, i)
      local count = (#hist > 0) and hist[#hist] or 0
      local sx    = SLOT_START_X + (i - 1) * 1.25
      parts[#parts + 1] = string.format("box[%.3f,%.3f;0.18,0.18;%s]",
        sx + 0.40, COLOR_DOT_Y, ITEM_COLORS[i])
      parts[#parts + 1] = string.format("label[%.3f,%.2f;%s]",
        sx + 0.30, COUNT_LBL_Y, format_count(count))
    end
  end

  return table.concat(parts)
end

----------------------------------------------------------------
-- formspec
----------------------------------------------------------------

local function get_formspec(pos)
  local meta     = minetest.get_meta(pos)
  local posForm  = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
  local idx      = get_interval_idx(meta)
  local lbl      = INTERVAL_LABELS[idx]

  return "formspec_version[4]" ..
    "size[" .. logistica.inv_size(10.5, 13.25) .. "]" ..
    logistica.ui.background ..
    logistica.ui.button_only_style ..
    logistica.player_inv_formspec(0.4, 8.0) ..
    "image[" .. GRAPH_X .. "," .. GRAPH_Y .. ";" ..
      GRAPH_W .. "," .. GRAPH_H .. ";logistica_icon_graph_back.png]" ..
    build_graph(pos) ..
    "label[0.30,4.50;" .. FS("Track items:") .. "]" ..
    "label[5.50,4.50;" .. FS("Record every:") .. "]" ..
    "button[7.90,4.32;2.30,0.50;interval_btn;" ..
      minetest.formspec_escape(lbl) .. "]" ..
    "list[" .. posForm .. ";filter;" ..
      SLOT_START_X .. "," .. SLOT_Y .. ";8,1;0]" ..
    build_slot_indicators(pos) ..
    -- "button[1.00,6.65;3.50,0.65;refresh_btn;" .. FS("Refresh") .. "]" ..
    "button[5.00,6.65;3.50,0.65;clear_btn;" .. FS("Clear History") .. "]" ..
    logistica.ui.on_off_btn(logistica.is_machine_on(pos), 9, 6.4, ON_OFF_BTN, FS("Enable")) ..
    "listring[" .. posForm .. ";filter]" ..
    "listring[current_player;main]"
end

local function show_formspec(playerName, pos)
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

----------------------------------------------------------------
-- callbacks (public)
----------------------------------------------------------------

function logistica.item_monitor_on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
    return true
  end

  local meta = minetest.get_meta(pos)

  if fields[ON_OFF_BTN] then
    logistica.toggle_machine_on_off(pos)
  elseif fields.interval_btn then
    local new_idx = (get_interval_idx(meta) % #INTERVALS) + 1
    meta:set_int(META_IDX, new_idx)
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId and logistica.is_machine_on(pos) then
      minetest.get_node_timer(pos):start(get_interval(meta))
    end
    logistica.item_monitor_update_infotext(pos)
  elseif fields.clear_btn then
    clear_all_history(meta)
  end
  -- refresh_btn just falls through to show_formspec

  show_formspec(playerName, pos)
  return true
end

function logistica.item_monitor_on_rightclick(pos, _, player, _, _)
  if not player or not player:is_player() then return end
  local playerName = player:get_player_name()
  if logistica.should_hide_from_player(pos, playerName) then return end
  forms[playerName] = { position = pos }
  show_formspec(playerName, pos)
end

function logistica.item_monitor_update_infotext(pos)
  local meta = minetest.get_meta(pos)
  local idx  = get_interval_idx(meta)
  local run  = logistica.is_machine_on(pos)
    and ("Recording every " .. INTERVAL_LABELS[idx])
    or "Paused"
  meta:set_string("infotext", "Item Monitor\n" .. run)
end

function logistica.item_monitor_after_place(pos, placer)
  local meta = minetest.get_meta(pos)
  meta:get_inventory():set_size("filter", NUM_SLOTS)
  meta:set_int(META_IDX, DEFAULT_IDX)
  logistica.item_monitor_update_infotext(pos)
  logistica.on_item_monitor_change(pos)
  if placer and placer:is_player() then
    logistica.item_monitor_on_rightclick(pos, nil, placer, nil, nil)
  end
end

function logistica.item_monitor_allow_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  if stack:get_stack_max() == 1 then return 0 end
  local meta = minetest.get_meta(pos)
  local copy = ItemStack(stack:get_name())
  copy:set_count(1)
  meta:get_inventory():set_stack(listname, index, copy)
  local seed_hist = {}
  local networkId = logistica.get_network_id_or_nil(pos)
  local network = networkId and logistica.get_network_by_id_or_nil(networkId)
  if network then
    seed_hist = { logistica.count_items_in_network(stack:get_name(), network, false) }
  end
  save_history(meta, index, seed_hist)
  show_formspec(player:get_player_name(), pos)
  return 0
end

function logistica.item_monitor_allow_inv_take(pos, listname, index, _, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  local meta = minetest.get_meta(pos)
  meta:get_inventory():set_stack(listname, index, ItemStack(""))
  save_history(meta, index, {})
  show_formspec(player:get_player_name(), pos)
  return 0
end

function logistica.item_monitor_allow_inv_move(_, _, _, _, _, _, _)
  return 0
end

----------------------------------------------------------------
-- timer / network
----------------------------------------------------------------

local function do_sample(pos, networkId)
  local network = logistica.get_network_by_id_or_nil(networkId)
  if not network then return end
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()

  for i = 1, NUM_SLOTS do
    local stack = inv:get_stack("filter", i)
    if not stack:is_empty() then
      local count = logistica.count_items_in_network(stack:get_name(), network, false)
      local hist  = load_history(meta, i)
      hist[#hist + 1] = count
      while #hist > MAX_SAMPLES do table.remove(hist, 1) end
      save_history(meta, i, hist)
    end
  end
end

local function refresh_open_formspecs(pos)
  local hash = minetest.hash_node_position(pos)
  for playerName, pform in pairs(forms) do
    if pform.position and minetest.hash_node_position(pform.position) == hash then
      minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
    end
  end
end

function logistica.item_monitor_timer(pos)
  if not logistica.is_machine_on(pos) then return false end
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  do_sample(pos, networkId)
  refresh_open_formspecs(pos)
  minetest.get_node_timer(pos):start(get_interval(minetest.get_meta(pos)))
  return false
end

function logistica.item_monitor_on_connect(pos, _)
  if logistica.is_machine_on(pos) then
    local jitter = math.random(0, 10) * 0.1
    minetest.get_node_timer(pos):start(get_interval(minetest.get_meta(pos)) + jitter)
  end
  logistica.item_monitor_update_infotext(pos)
end

function logistica.item_monitor_on_disconnect(pos, _)
  minetest.get_node_timer(pos):stop()
  logistica.item_monitor_update_infotext(pos)
end

function logistica.item_monitor_on_power(pos, isOn)
  if isOn then
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then
      minetest.get_node_timer(pos):start(get_interval(minetest.get_meta(pos)))
    end
  else
    minetest.get_node_timer(pos):stop()
  end
  logistica.item_monitor_update_infotext(pos)
end

----------------------------------------------------------------
-- engine hooks
----------------------------------------------------------------

minetest.register_on_player_receive_fields(logistica.item_monitor_on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, _)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

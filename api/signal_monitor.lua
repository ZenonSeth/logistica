
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_monitor"
local TAB_FIELD = "tabs"
local W, H = 12.5, 8.5
local LIST_X1, LIST_X2 = 0.3, 6.5
local LIST_Y, LIST_H = 2.05, 6.2
local LIST_W = 5.8

-- per-player form state
local forms = {}
local get_formspec  -- forward declaration; defined below

local function pos_to_str(p)
  return "(" .. p.x .. ", " .. p.y .. ", " .. p.z .. ")"
end

local function build_signal_list_items(signals)
  local items = {}
  for _, entry in ipairs(signals) do
    local color  = entry.isOn and "#CCFF00" or "#CCCCCC"
    local marker = entry.isOn and "(O) " or "(  ) "
    items[#items + 1] = color .. marker .. minetest.formspec_escape(entry.name)
  end
  return table.concat(items, ",")
end

local function build_detail_items(senders)
  local rows = {}
  local row_map = {}  -- [idx] = {desc, pos} or nil for header
  rows[#rows + 1] = "#FFFFFF" .. FS("Active senders: ") .. #senders
  row_map[1] = nil
  for _, s in ipairs(senders) do
    local nameIdx = #rows + 1
    rows[nameIdx] = "#AAAAFF  " .. minetest.formspec_escape(s.desc)
    row_map[nameIdx] = s
    local coordIdx = #rows + 1
    rows[coordIdx] = "#8888CC  : " .. minetest.formspec_escape(pos_to_str(s.pos))
    row_map[coordIdx] = s
  end
  return table.concat(rows, ","), row_map
end

local function get_sel_idx(list, selName)
  if not selName then return 0 end
  for i, entry in ipairs(list) do
    if entry.name == selName then return i end
  end
  return 0
end

get_formspec = function(pos, playerName)
  local pform = forms[playerName]
  if not pform then return "" end
  local tab    = pform.tab or 1
  local search = pform.search or ""

  local live_list = logistica.signal_monitor_get_live_signals(pos, search)
  local live_sel  = get_sel_idx(live_list, pform.live_sel)
  local live_items = build_signal_list_items(live_list)
  pform.live_list = live_list

  local snap_list = logistica.signal_monitor_get_snapshot_changed(pos, search)
  local snap_sel  = get_sel_idx(snap_list, pform.snap_sel)
  local snap_items = build_signal_list_items(snap_list)
  pform.snap_list = snap_list

  local sel_name = (tab == 1) and pform.live_sel or pform.snap_sel
  local senders   = sel_name and logistica.signal_monitor_get_senders(pos, sel_name) or {}
  local detail_str, detail_map = build_detail_items(senders)
  pform.detail_map = detail_map

  local has_snap = logistica.signal_monitor_has_snapshot(pos)
  local snap_btn_label = has_snap and FS("Reset snapshot") or FS("Take base snapshot")

  local fs = "formspec_version[4]"
    .. "size[" .. W .. "," .. H .. "]"
    .. logistica.ui.background
    .. logistica.ui.button_only_style
    .. "field_close_on_enter[search;false]"
    -- .. "tabheader[0,0;" .. TAB_FIELD .. ";" .. FS("Live Monitoring") .. "," .. FS("Snapshot") .. ";" .. tab .. ";false;true]"

  local reset_tooltip = minetest.formspec_escape(
    "Resets list of signals seen by this network.\nUse when you've removed signals entirely.")
  local live_update_on = logistica.signal_monitor_get_live_update(pos)
  if tab == 1 then
    fs = fs
      .. "label[0.3,0.85;" .. FS("Search:") .. "]"
      .. "field[1.5,0.6;4.0,0.7;search;;" .. minetest.formspec_escape(search) .. "]"
      .. "button[5.6,0.6;1.5,0.7;search_btn;" .. FS("Search") .. "]"
      .. "button[7.2,0.6;2.3,0.7;refresh;" .. FS("Refresh") .. "]"
      .. "button[9.7,0.6;2.5,0.7;live_reset;" .. FS("Reset") .. "]"
      .. "tooltip[live_reset;" .. reset_tooltip .. "]"
      .. "checkbox[7.2,1.55;live_update;" .. FS("Live Update") .. ";" .. (live_update_on and "true" or "false") .. "]"
      .. "textlist[" .. LIST_X1 .. "," .. LIST_Y .. ";" .. LIST_W .. "," .. LIST_H .. ";live_signals;" .. live_items .. ";" .. live_sel .. ";false]"
      .. "textlist[" .. LIST_X2 .. "," .. LIST_Y .. ";" .. LIST_W .. "," .. LIST_H .. ";sender_detail;" .. detail_str .. ";0;false]"
  else
    fs = fs
      .. "button[0.3,0.6;4.5,0.7;snap_action;" .. minetest.formspec_escape(snap_btn_label) .. "]"
      .. "field[5.2,0.6;4.0,0.7;search;;" .. minetest.formspec_escape(search) .. "]"
      .. "button[9.3,0.6;1.5,0.7;search_btn;" .. FS("Search") .. "]"
      .. "textlist[" .. LIST_X1 .. "," .. LIST_Y .. ";" .. LIST_W .. "," .. LIST_H .. ";snap_signals;" .. snap_items .. ";" .. snap_sel .. ";false]"
      .. "textlist[" .. LIST_X2 .. "," .. LIST_Y .. ";" .. LIST_W .. "," .. LIST_H .. ";sender_detail;" .. detail_str .. ";0;false]"
  end

  return fs
end

function logistica.signal_monitor_live_refresh(pos)
  local hash = minetest.hash_node_position(pos)
  for playerName, pform in pairs(forms) do
    if pform.position and minetest.hash_node_position(pform.position) == hash then
      minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    end
  end
end

local function show_formspec(pos, playerName)
  if not forms[playerName] then
    forms[playerName] = { position = pos, tab = 1, search = "", live_sel = nil, snap_sel = nil }
  else
    forms[playerName].position = pos
  end
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pform = forms[playerName]
  if not pform then return false end
  local pos = pform.position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
    return true
  end

  if fields[TAB_FIELD] then
    local t = tonumber(fields[TAB_FIELD])
    if t == 1 or t == 2 then pform.tab = t end
  end

  if fields.search ~= nil then
    pform.search = fields.search
  end

  if fields.live_update ~= nil then
    logistica.signal_monitor_set_live_update(pos, fields.live_update == "true")
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  if fields.refresh or fields.search_btn or fields.key_enter_field == "search" then
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  if fields.live_reset then
    logistica.signal_monitor_reset_live(pos)
    pform.live_sel = nil
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  if fields.snap_action then
    if logistica.signal_monitor_has_snapshot(pos) then
      logistica.signal_monitor_reset_snapshot(pos)
      pform.snap_sel = nil
    else
      logistica.signal_monitor_take_snapshot(pos)
    end
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  -- signal list selection
  if fields.live_signals then
    local evt = minetest.explode_textlist_event(fields.live_signals)
    if evt.type == "CHG" or evt.type == "DCL" then
      local entry = pform.live_list and pform.live_list[evt.index]
      pform.live_sel = entry and entry.name or nil
    end
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  if fields.snap_signals then
    local evt = minetest.explode_textlist_event(fields.snap_signals)
    if evt.type == "CHG" or evt.type == "DCL" then
      local entry = pform.snap_list and pform.snap_list[evt.index]
      pform.snap_sel = entry and entry.name or nil
    end
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  -- sender detail: clicking name or coord row sends chat
  if fields.sender_detail then
    local evt = minetest.explode_textlist_event(fields.sender_detail)
    if (evt.type == "CHG" or evt.type == "DCL") and pform.detail_map then
      local entry = pform.detail_map[evt.index]
      if entry then
        minetest.chat_send_player(playerName,
          "[Logistica] " .. entry.desc .. " at " .. minetest.pos_to_string(entry.pos))
      end
    end
    return true
  end

  if fields[TAB_FIELD] then
    minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
    return true
  end

  return true
end

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_signal_monitor(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_monitor_on_connect,
    on_disconnect_from_network = logistica.signal_monitor_on_disconnect,
    on_signal_received         = logistica.signal_monitor_on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_receiver_change(pos, nil, nil)
    minetest.get_meta(pos):set_string("infotext", "Signal Monitor")
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
    logistica.signal_monitor_cleanup(pos)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  logistica.GROUPS.signal_receivers.register(lname)

  minetest.register_node(lname, def)
end

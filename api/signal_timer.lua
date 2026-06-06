
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_timer"
local ON_OFF_BUTTON = "on_off_btn"

local forms = {}

local function fmt_sec(v)
  return string.format("%.1f", v) .. "s"
end

local function get_formspec(pos)
  local sigName = logistica.signal_timer_get_signal_name(pos)
  local onSec   = logistica.signal_timer_get_on_seconds(pos)
  local offSec  = logistica.signal_timer_get_off_seconds(pos)
  local isOn    = logistica.is_machine_on(pos)
  return "formspec_version[4]"..
    "size[6.5,5.2]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("Signal Timer Sender").."]"..
    "label[0.5,1.15;"..FS("Signal Name:").."]"..
    "field[2.5,0.9;3.5,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[0.5,1.85;"..FS("a-z 0-9 _ only").."]"..
    "label[0.5,2.65;"..FS("ON duration:").."]"..
    "button[3.0,2.4;0.65,0.65;on_minus;-]"..
    "label[3.85,2.82;"..fmt_sec(onSec).."]"..
    "button[5.0,2.4;0.65,0.65;on_plus;+]"..
    "label[0.5,3.45;"..FS("OFF duration:").."]"..
    "button[3.0,3.2;0.65,0.65;off_minus;-]"..
    "label[3.85,3.62;"..fmt_sec(offSec).."]"..
    "button[5.0,3.2;0.65,0.65;off_plus;+]"..
    logistica.ui.on_off_btn(isOn, 0.5, 4.1, ON_OFF_BUTTON, FS("Enable"))..
    "button_exit[3.8,4.25;2.2,0.75;save;"..FS("Save").."]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function adjust_duration(pos, metaKey, getter, delta)
  local cur = getter(pos)
  local new = math.max(0.5, math.floor((cur + delta) * 2 + 0.5) / 2)
  minetest.get_meta(pos):set_float(metaKey, new)
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  if fields.on_minus then
    adjust_duration(pos, "on_seconds", logistica.signal_timer_get_on_seconds, -0.5)
    show_formspec(pos, playerName)
  elseif fields.on_plus then
    adjust_duration(pos, "on_seconds", logistica.signal_timer_get_on_seconds, 0.5)
    show_formspec(pos, playerName)
  elseif fields.off_minus then
    adjust_duration(pos, "off_seconds", logistica.signal_timer_get_off_seconds, -0.5)
    show_formspec(pos, playerName)
  elseif fields.off_plus then
    adjust_duration(pos, "off_seconds", logistica.signal_timer_get_off_seconds, 0.5)
    show_formspec(pos, playerName)
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_formspec(pos, playerName)
  elseif fields.save or fields.key_enter_field == "signal_name" then
    if fields.signal_name then
      minetest.get_meta(pos):set_string("signal_name",
        logistica.sanitize_signal_name(fields.signal_name))
    end
    logistica.signal_timer_reconfigure(pos)
    forms[playerName] = nil
  elseif fields.quit then
    forms[playerName] = nil
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

function logistica.register_signal_timer(desc, name, tiles_off, tiles_on)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function after_place(pos, placer, _, _)
    logistica.on_signal_sender_change(pos, nil, nil)
    logistica.signal_timer_update_infotext(pos)
    if placer and placer:is_player() then
      show_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if minetest.is_protected(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_timer_on_connect,
    on_disconnect_from_network = logistica.signal_timer_on_disconnect,
    on_power                   = logistica.signal_timer_on_power,
  }

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles_off,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_timer         = logistica.signal_timer_on_timer,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def)
  def_on.tiles = tiles_on
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname,    def)
  minetest.register_node(lname_on, def_on)
end

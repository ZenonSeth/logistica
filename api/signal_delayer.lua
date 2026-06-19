
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_delayer"

local forms = {}

local DELAY_STEP = 0.5
local DELAY_MAX  = 600.0

local function fmt_delay(v)
  return string.format("%.1f", v) .. "s"
end

local function get_formspec(pos)
  local inputName  = logistica.signal_delayer_get_input(pos)
  local outputName = logistica.signal_delayer_get_output(pos)
  local onDly      = logistica.signal_delayer_get_on_delay(pos)
  local offDly     = logistica.signal_delayer_get_off_delay(pos)

  return "formspec_version[4]"..
    "size[7,6.5]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("Signal Delayer").."]"..
    "label[0.5,1.25;"..FS("Input Signal:").."]"..
    "field[2.5,0.9;4.0,0.75;input_signal;;"..minetest.formspec_escape(inputName).."]"..
    "label[2.5,1.85;"..FS("a-z 0-9 _ only").."]"..
    "label[0.5,2.75;"..FS("Output Signal:").."]"..
    "field[2.5,2.4;4.0,0.75;output_signal;;"..minetest.formspec_escape(outputName).."]"..
    "label[2.5,3.35;"..FS("a-z 0-9 _ only").."]"..
    "label[0.5,4.2;"..FS("ON delay:").."]"..
    "button[2.5,3.85;0.65,0.65;on_minus;-]"..
    "label[3.35,4.27;"..fmt_delay(onDly).."]"..
    "button[4.5,3.85;0.65,0.65;on_plus;+]"..
    "label[0.5,5.0;"..FS("OFF delay:").."]"..
    "button[2.5,4.65;0.65,0.65;off_minus;-]"..
    "label[3.35,5.07;"..fmt_delay(offDly).."]"..
    "button[4.5,4.65;0.65,0.65;off_plus;+]"..
    "button_exit[4.3,5.5;2.2,0.75;save;"..FS("Save").."]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function clamp_step(v)
  -- Round to nearest 0.5, clamp to [0, DELAY_MAX]
  return math.max(0, math.min(DELAY_MAX, math.floor(v * 2 + 0.5) / 2))
end

local function adjust_on_delay(pos, delta)
  local cur = logistica.signal_delayer_get_on_delay(pos)
  minetest.get_meta(pos):set_float("delayer_on_delay", clamp_step(cur + delta))
end

local function adjust_off_delay(pos, delta)
  local cur = logistica.signal_delayer_get_off_delay(pos)
  minetest.get_meta(pos):set_float("delayer_off_delay", clamp_step(cur + delta))
end

local function save_signal_names(pos, fields)
  local meta = minetest.get_meta(pos)
  if fields.input_signal ~= nil then
    meta:set_string("delayer_input", logistica.sanitize_signal_name(fields.input_signal))
  end
  if fields.output_signal and fields.output_signal ~= "" then
    meta:set_string("delayer_output", logistica.sanitize_signal_name(fields.output_signal))
  end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.on_minus then
    save_signal_names(pos, fields)
    adjust_on_delay(pos, -DELAY_STEP)
    show_formspec(pos, playerName)
  elseif fields.on_plus then
    save_signal_names(pos, fields)
    adjust_on_delay(pos, DELAY_STEP)
    show_formspec(pos, playerName)
  elseif fields.off_minus then
    save_signal_names(pos, fields)
    adjust_off_delay(pos, -DELAY_STEP)
    show_formspec(pos, playerName)
  elseif fields.off_plus then
    save_signal_names(pos, fields)
    adjust_off_delay(pos, DELAY_STEP)
    show_formspec(pos, playerName)
  elseif fields.save or fields.key_enter_field == "input_signal"
      or fields.key_enter_field == "output_signal" then
    save_signal_names(pos, fields)
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

-- tiles_off, tiles_on: 6-element tile tables
function logistica.register_signal_delayer(desc, name, tiles_off, tiles_on)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_delayer_on_connect,
    on_disconnect_from_network = logistica.signal_delayer_on_disconnect,
    on_signal_received         = logistica.signal_delayer_on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_receiver_change(pos, nil, nil)
    local meta = minetest.get_meta(pos)
    meta:set_string("infotext", "Signal Delayer")
    meta:set_float("delayer_on_delay", 1.0)
    meta:set_float("delayer_off_delay", 1.0)
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.signal_delayer_cleanup(pos)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "none",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles_off,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_timer         = logistica.signal_delayer_on_timer,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def)
  def_on.tiles = tiles_on
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  local def_disabled = table.copy(def)
  def_disabled.tiles = {}
  for i, t in ipairs(tiles_off) do def_disabled.tiles[i] = t .. "^logistica_disabled.png" end
  def_disabled.groups = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1,
    not_in_creative_inventory = 1 }
  def_disabled.after_place_node = nil
  def_disabled.after_dig_node   = nil
  def_disabled.on_rightclick    = nil
  def_disabled.on_timer         = nil
  def_disabled.logistica        = nil

  logistica.GROUPS.signal_gates.register(lname)
  logistica.GROUPS.signal_gates.register(lname_on)

  minetest.register_node(lname,            def)
  minetest.register_node(lname_on,         def_on)
  minetest.register_node(lname .. "_disabled", def_disabled)
end

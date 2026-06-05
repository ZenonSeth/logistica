
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_logic_gate"

local forms = {}

local MODE_NAMES = { and_ = "AND", or_ = "OR", adder = "ADDER" }

local function mode_display(mode)
  if mode == "and" then return "AND"
  elseif mode == "or" then return "OR"
  else return "ADDER" end
end

local function mode_desc(mode, threshold)
  if mode == "and" then
    return FS("All input signals must be On for the output signal to be On.")
  elseif mode == "or" then
    return FS("Any input signal being On sets the output signal to On.")
  else
    return FS("Output is On when ") .. threshold .. FS(" or more input signals are On.")
  end
end

local function get_formspec(pos)
  local mode      = logistica.signal_logic_gate_get_mode(pos)
  local threshold = logistica.signal_logic_gate_get_threshold(pos)
  local inputs    = logistica.signal_logic_gate_get_inputs(pos)
  local output    = logistica.signal_logic_gate_get_output(pos)
  local is_adder  = mode == "adder"

  local input_y  = is_adder and 3.3 or 2.7
  local hint_y   = input_y + 1.0
  local out_y    = hint_y + 0.45
  local field_y  = out_y + 0.2
  local save_y   = field_y + 0.9

  local fs = "formspec_version[4]"..
    "size[7,6.8]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.3;"..FS("Signal Logic Gate").."]"..
    "label[0.5,0.8;"..FS("Current Mode: ")..mode_display(mode).."]"..
    "label[0.5,1.2;"..mode_desc(mode, threshold).."]"..
    "label[0.5,1.7;"..FS("Select Mode:").."]"..
    "button[2.25,1.5;1.2,0.65;mode_and;AND]"..
    "button[3.5,1.5;1.2,0.65;mode_or;OR]"..
    "button[4.75,1.5;1.75,0.65;mode_adder;ADDER]"

  if is_adder then
    fs = fs..
      "label[0.5,2.6;"..FS("Threshold:").."]"..
      "button[2.25,2.4;0.65,0.65;thresh_dec;-]"..
      "label[3.05,2.8;"..threshold.."]"..
      "button[3.75,2.4;0.65,0.65;thresh_inc;+]"
  end

  fs = fs..
    "label[0.5,"..input_y..";"..FS("Input Signals:").."]"..
    "field[0.5,"..(input_y + 0.2)..";6.0,0.65;input_signals;;"..minetest.formspec_escape(inputs).."]"..
    "label[0.5,"..hint_y..";"..FS("a-z 0-9 _ only, space or comma separated").."]"..
    "label[0.5,"..out_y..";"..FS("Output Signal:").."]"..
    "field[0.5,"..(out_y + 0.2)..";6.0,0.65;output_signal;;"..minetest.formspec_escape(output).."]"..
    "button_exit[2.0,"..save_y..";3.0,0.65;save;"..FS("Save").."]"

  return fs
end

local function show_gate_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function save_signal_fields(pos, fields)
  local meta = minetest.get_meta(pos)
  if fields.input_signals and fields.input_signals ~= "" then
    local parts = {}
    for token in fields.input_signals:gmatch("[^%s,]+") do
      local s = logistica.sanitize_signal_name(token)
      if s ~= "" then parts[#parts + 1] = s end
    end
    if #parts > 0 then
      meta:set_string("gate_inputs", table.concat(parts, " "))
    end
  end
  if fields.output_signal and fields.output_signal ~= "" then
    meta:set_string("gate_output", logistica.sanitize_signal_name(fields.output_signal))
  end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  local meta = minetest.get_meta(pos)

  if fields.mode_and then
    save_signal_fields(pos, fields)
    meta:set_string("gate_mode", "and")
    show_gate_formspec(pos, playerName)
  elseif fields.mode_or then
    save_signal_fields(pos, fields)
    meta:set_string("gate_mode", "or")
    show_gate_formspec(pos, playerName)
  elseif fields.mode_adder then
    save_signal_fields(pos, fields)
    meta:set_string("gate_mode", "adder")
    show_gate_formspec(pos, playerName)
  elseif fields.thresh_dec then
    save_signal_fields(pos, fields)
    meta:set_int("gate_threshold", math.max(1, logistica.signal_logic_gate_get_threshold(pos) - 1))
    show_gate_formspec(pos, playerName)
  elseif fields.thresh_inc then
    save_signal_fields(pos, fields)
    meta:set_int("gate_threshold", math.min(100000, logistica.signal_logic_gate_get_threshold(pos) + 1))
    show_gate_formspec(pos, playerName)
  elseif fields.save or fields.key_enter_field == "input_signals"
      or fields.key_enter_field == "output_signal" then
    save_signal_fields(pos, fields)
    local network = logistica.get_network_or_nil(pos)
    if network then logistica.signal_logic_gate_on_connect(pos, network.controller) end
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

-- tiles: 6-element tile table
function logistica.register_signal_logic_gate(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_logic_gate_on_connect,
    on_disconnect_from_network = logistica.signal_logic_gate_on_disconnect,
    on_signal_received         = logistica.signal_logic_gate_on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_receiver_change(pos, nil, nil)
    minetest.get_meta(pos):set_string("infotext", "Off")
    minetest.get_node_timer(pos):start(0.1)
    if placer and placer:is_player() then
      show_gate_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if minetest.is_protected(pos, player:get_player_name()) then return end
    show_gate_formspec(pos, player:get_player_name())
  end

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "none",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node = after_dig,
    on_rightclick = on_rightclick,
    on_timer = logistica.signal_logic_gate_timer,
    logistica = logistica_callbacks,
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_disabled = table.copy(def)
  def_disabled.tiles = {}
  for i, t in ipairs(tiles) do def_disabled.tiles[i] = t .. "^logistica_disabled.png" end
  def_disabled.groups = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1,
    not_in_creative_inventory = 1 }
  def_disabled.after_place_node = nil
  def_disabled.after_dig_node   = nil
  def_disabled.on_rightclick    = nil
  def_disabled.on_timer         = nil
  def_disabled.logistica        = nil

  logistica.GROUPS.signal_gates.register(lname)

  minetest.register_node(lname, def)
  minetest.register_node(lname .. "_disabled", def_disabled)
end


local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_not_gate"

local forms = {}

local function get_formspec(pos)
  local inputName  = logistica.signal_not_gate_get_input(pos)
  local outputName = logistica.signal_not_gate_get_output(pos)
  return "formspec_version[4]"..
    "size[7,4.25]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("NOT Gate").."]"..
    "label[0.5,0.9;"..FS("Input Signal:").."]"..
    "field[2.75,0.7;3.75,0.75;input_signal;;"..minetest.formspec_escape(inputName).."]"..
    "label[2.75,1.6;"..FS("a-z 0-9 _ only").."]"..
    "label[0.5,2.0;"..FS("Output Signal:").."]"..
    "field[2.75,1.8;3.75,0.75;output_signal;;"..minetest.formspec_escape(outputName).."]"..
    "label[2.75,2.7;"..FS("a-z 0-9 _ only").."]"..
    "button_exit[2.0,3.25;3,0.75;save;"..FS("Save").."]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.save or fields.key_enter_field == "input_signal"
      or fields.key_enter_field == "output_signal" then
    local meta = minetest.get_meta(pos)
    if fields.input_signal and fields.input_signal ~= "" then
      meta:set_string("signal_input", logistica.sanitize_signal_name(fields.input_signal))
    end
    if fields.output_signal and fields.output_signal ~= "" then
      meta:set_string("signal_output", logistica.sanitize_signal_name(fields.output_signal))
    end
    -- re-evaluate with new config
    local network = logistica.get_network_or_nil(pos)
    if network then logistica.signal_not_gate_on_connect(pos, network.controller) end
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

-- tiles: 6-element tile table (top, top, side, side, back, front)
function logistica.register_signal_not_gate(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_not_gate_on_connect,
    on_disconnect_from_network = logistica.signal_not_gate_on_disconnect,
    on_signal_received         = logistica.signal_not_gate_on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_receiver_change(pos, nil, nil)
    minetest.get_meta(pos):set_string("infotext", "Off")
    minetest.get_node_timer(pos):start(0.1)
  end

  local function after_dig(pos, oldNode, oldMeta, _)
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
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node = after_dig,
    on_rightclick = on_rightclick,
    on_timer = logistica.signal_not_gate_timer,
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
  def_disabled.after_dig_node = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  logistica.GROUPS.signal_gates.register(lname)

  minetest.register_node(lname, def)
  minetest.register_node(lname .. "_disabled", def_disabled)
end

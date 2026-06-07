
if not minetest.get_modpath("mesecons") then return end

local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:mesecon_sender"
local SIZE = logistica.settings.cable_size
local RULES    = mesecon.rules.default
local COOLDOWN = 0.4  -- seconds between mesecon API calls; slows oscillation loops

local forms = {}

local function get_formspec(pos)
  local sigName = logistica.mesecon_sender_get_name(pos)
  local notFlag = logistica.mesecon_sender_get_not(pos)
  return "formspec_version[4]"..
    "size[7,3.5]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("Mesecon Signal Sender").."]"..
    "label[0.5,0.9;"..FS("Sends a Mesecons signal when it receives a Logistica signal").."]"..
    "checkbox[0.5,1.6;signal_not;"..FS("NOT")..";".. (notFlag and "true" or "false") .."]"..
    "label[1.75,1.55;"..FS("Signal Name:").."]"..
    "field[3.25,1.2;3.25,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[3.25,2.1;"..FS("a-z 0-9 _ only").."]"..
    "button_exit[2.0,2.6;3,0.75;save;"..FS("Save").."]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function fire_mesecon(pos, isOn)
  logistica.mesecon_sender_set_visual(pos, isOn)
  if isOn then mesecon.receptor_on(pos, RULES) else mesecon.receptor_off(pos, RULES) end
end

-- Throttled apply: fires immediately if outside cooldown, otherwise defers via node timer.
-- The node timer always reads the latest pending_state, so rapid flips collapse into one call.
local function apply_state(pos, isOn)
  local meta = minetest.get_meta(pos)
  meta:set_string("pending_state", isOn and "1" or "0")
  local now = minetest.get_gametime()
  if now - meta:get_float("last_send_time") >= COOLDOWN then
    meta:set_float("last_send_time", now)
    fire_mesecon(pos, isOn)
  else
    minetest.get_node_timer(pos):start(COOLDOWN)
  end
end

local function on_timer(pos)
  local meta = minetest.get_meta(pos)
  meta:set_float("last_send_time", minetest.get_gametime())
  fire_mesecon(pos, meta:get_string("pending_state") == "1")
  return false
end

local function effective_state(pos, sigIsOn)
  return logistica.mesecon_sender_get_not(pos) ~= sigIsOn
end

-- Logistica callbacks --

local function on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.mesecon_sender_get_name(pos) then return end
  apply_state(pos, effective_state(pos, sigIsOn))
end

local function on_connect(pos, networkId)
  local id = networkId or logistica.get_network_id_or_nil(pos)
  local sigName = logistica.mesecon_sender_get_name(pos)
  if not id or not sigName or sigName == "" then
    apply_state(pos, false)
    return
  end
  apply_state(pos, effective_state(pos, logistica.signal_get_state(id, sigName)))
end

local function on_disconnect(pos, _networkId)
  apply_state(pos, false)
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.signal_not ~= nil then
    minetest.get_meta(pos):set_string("signal_not", fields.signal_not == "true" and "1" or "0")
    on_connect(pos, nil)
  end
  if fields.save or fields.key_enter_field == "signal_name" then
    apply_state(pos, false)  -- clear mesecon output before renaming
    if fields.signal_name ~= nil then
      local n = fields.signal_name
      minetest.get_meta(pos):set_string("signal_name",
        (n == "") and "" or logistica.sanitize_signal_name(n))
    end
    on_connect(pos, nil)
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

local NODEBOX = {
  type = "connected",
  fixed = {
    {-0.5, -0.5, -0.5,  0.5, -6/16, 0.5},
    {-SIZE, -6/16, -SIZE, SIZE, SIZE, SIZE},
  },
  connect_top   = {-SIZE, -SIZE, -SIZE, SIZE, 0.5,  SIZE},
  connect_front = {-SIZE, -SIZE, -0.5,  SIZE, SIZE, SIZE},
  connect_back  = {-SIZE, -SIZE,  SIZE, SIZE, SIZE, 0.5 },
  connect_left  = {-0.5,  -SIZE, -SIZE, SIZE, SIZE, SIZE},
  connect_right = {-SIZE, -SIZE, -SIZE, 0.5,  SIZE, SIZE},
}

local SEL_BOX = {
  type = "fixed",
  fixed = { {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5} }
}

local function make_tiles(top, side, bottom)
  return { top, bottom, side, side, side, side }
end

function logistica.register_mesecon_sender(desc, name, tile_top_off, tile_top_on, tile_side, tile_bottom)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = on_connect,
    on_disconnect_from_network = on_disconnect,
    on_signal_received         = on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_receiver_change(pos, nil, nil)
    if placer and placer:is_player() then
      show_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    apply_state(pos, false)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local def_off = {
    description = desc,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "none",
    sunlight_propagates = true,
    is_ground_content = false,
    tiles = make_tiles(tile_top_off, tile_side, tile_bottom),
    node_box = NODEBOX,
    selection_box = SEL_BOX,
    connects_to = { logistica.GROUP_ALL, logistica.GROUP_CABLE_OFF },
    connect_sides = {"top", "left", "right", "back", "front"},
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node = after_dig,
    on_rightclick = on_rightclick,
    on_timer = on_timer,
    logistica = logistica_callbacks,
    mesecons = { receptor = { state = mesecon.state.off, rules = RULES } },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def_off)
  def_on.tiles = make_tiles(tile_top_on, tile_side, tile_bottom)
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1
  def_on.mesecons = { receptor = { state = mesecon.state.on, rules = RULES } }

  logistica.GROUPS.signal_receivers.register(lname)
  logistica.GROUPS.signal_receivers.register(lname_on)

  minetest.register_node(lname, def_off)
  minetest.register_node(lname_on, def_on)
end

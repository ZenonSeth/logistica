
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_lamp"

local forms = {}

local function get_formspec(pos)
  local signalName = logistica.signal_lamp_get_name(pos)
  local notFlag = logistica.signal_lamp_get_not(pos)
  return "formspec_version[4]"..
    "size[7.5,3.0]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("Signal Lamp").."]"..
    "checkbox[0.5,0.9;signal_not;"..FS("NOT")..";".. (notFlag and "true" or "false") .."]"..
    "label[1.75,0.95;"..FS("Signal Name:").."]"..
    "field[3.75,0.7;3.25,0.75;signal_name;;"..minetest.formspec_escape(signalName).."]"..
    "label[3.75,1.6;"..FS("a-z 0-9 _ only").."]"..
    "button_exit[2.0,2.1;3,0.75;save;"..FS("Save").."]"
end

local function show_lamp_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.signal_not ~= nil then
    -- checkboxes fire immediately on click and don't resend on button press,
    -- so save and re-evaluate right away
    minetest.get_meta(pos):set_string("signal_not", fields.signal_not == "true" and "1" or "0")
    local network = logistica.get_network_or_nil(pos)
    if network then
      logistica.signal_lamp_on_connect(pos, network.controller)
    end
  end
  if fields.save or fields.key_enter_field == "signal_name" then
    if fields.signal_name and fields.signal_name ~= "" then
      minetest.get_meta(pos):set_string("signal_name", logistica.sanitize_signal_name(fields.signal_name))
    end
    local network = logistica.get_network_or_nil(pos)
    if network then
      logistica.signal_lamp_on_connect(pos, network.controller)
    end
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

-- tile_off and tile_on are single texture name strings (applied to all 6 sides)
function logistica.register_signal_lamp(desc, name, tile_off, tile_on)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network    = logistica.signal_lamp_on_connect,
    on_disconnect_from_network = logistica.signal_lamp_on_disconnect,
    on_signal_received       = logistica.signal_lamp_on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_receiver_change(pos, nil, nil)
    minetest.get_meta(pos):set_string("infotext", "Off")
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_lamp_formspec(pos, player:get_player_name())
  end

  local def_off = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "colorfacedir",
    sunlight_propagates = false,
    is_ground_content = false,
    tiles = { tile_off },
    light_source = 0,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node = after_dig,
    on_rightclick = on_rightclick,
    logistica = logistica_callbacks,
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def_off)
  def_on.tiles = { tile_on }
  def_on.light_source = 14
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_receivers.register(lname)
  logistica.GROUPS.signal_receivers.register(lname_on)

  minetest.register_node(lname, def_off)
  minetest.register_node(lname_on, def_on)
end

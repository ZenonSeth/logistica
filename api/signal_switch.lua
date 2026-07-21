
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_switch"

local forms = {}

local function get_formspec(pos)
  local signalName = logistica.signal_switch_get_name(pos)
  local stateStr = logistica.signal_switch_is_on(pos) and FS("ON") or FS("OFF")
  local toggleLabel = logistica.signal_switch_is_on(pos) and FS("Turn Off") or FS("Turn On")
  return "formspec_version[4]"..
    "size[7.5,3.5]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("Signal Switch").."]"..
    "label[0.5,0.9;"..FS("Signal Name:").."]"..
    "field[2.5,0.7;4.5,0.75;signal_name;;"..minetest.formspec_escape(signalName).."]"..
    "label[2.5,1.6;"..FS("a-z 0-9 _ only").."]"..
    "label[0.5,1.9;"..FS("State: ")..stateStr.."]"..
    "button[0.5,2.5;3,0.75;toggle;"..toggleLabel.."]"..
    "button_exit[3.75,2.5;2.75,0.75;save;"..FS("Save Name").."]"
end

local function show_switch_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.save or fields.key_enter_field == "signal_name" then
    if fields.signal_name then
      logistica.signal_switch_set_name(pos, logistica.sanitize_signal_name(fields.signal_name))
    end
    forms[playerName] = nil
  elseif fields.toggle then
    logistica.signal_switch_toggle(pos)
    show_switch_formspec(pos, playerName)
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

-- tiles_off and tiles_on are each a tile table or single texture string
function logistica.register_signal_switch(desc, name, tiles_off, tiles_on)
  local lname = "logistica:" .. name
  local lname_on = lname .. "_on"

  local nodebox_off = {
    type = "fixed",
    fixed = {
      {-6/16, -5/16, 6/16,  6/16,  5/16, 8/16},  -- backplate
      {-1/16, -2/16, 5/16,  1/16,  0/16, 6/16},   -- lever (down = off)
    }
  }
  local nodebox_on = {
    type = "fixed",
    fixed = {
      {-6/16, -5/16, 6/16,  6/16,  5/16, 8/16},  -- backplate
      {-1/16,  0/16, 5/16,  1/16,  2/16, 6/16},   -- lever (up = on)
    }
  }
  local selection_box = {
    type = "fixed",
    fixed = { {-6/16, -5/16, 6/16, 6/16, 5/16, 8/16} }
  }

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function after_place(pos, placer, _, _)
    logistica.on_signal_sender_change(pos, nil, nil)
    logistica.signal_switch_update_infotext(pos)
    if placer and placer:is_player() then
      show_switch_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return end
    logistica.signal_switch_toggle(pos)
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_switch_on_connect,
    on_disconnect_from_network = logistica.signal_switch_on_disconnect,
    on_hyperspanner_use        = function(pos, player)
      show_switch_formspec(pos, player:get_player_name())
    end,
  }

  local def_off = {
    description = desc,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "colorfacedir",
    sunlight_propagates = true,
    is_ground_content = false,
    tiles = tiles_off,
    node_box = nodebox_off,
    selection_box = selection_box,
    collision_box = selection_box,
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
  def_on.tiles = tiles_on
  def_on.node_box = nodebox_on
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname, def_off)
  minetest.register_node(lname_on, def_on)
end

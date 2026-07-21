
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_button"

local forms = {}

local function get_formspec(pos)
  local sigName = logistica.signal_button_get_name(pos)
  return "formspec_version[4]"..
    "size[8.3,3.1]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("Signal Button").."]"..
    "label[0.5,1.25;"..FS("Signal Name:").."]"..
    "field[3.1,0.9;4.5,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[3.1,1.85;"..FS("a-z 0-9 _ only").."]"..
    "button_exit[3.75,2.1;2.75,0.75;save;"..FS("Save").."]"
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

  if fields.save or fields.key_enter_field == "signal_name" then
    if fields.signal_name then
      logistica.signal_button_set_name(pos, fields.signal_name)
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

function logistica.register_signal_button(desc, name, tiles_off, tiles_on)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  -- Frame: 4 parts surrounding the button hole, front face flush at z=6/16, back at z=8/16.
  -- Button hole is a 4x4 square in the center (-2/16 to 2/16 on both x and y).
  local frame_top    = {-6/16,  2/16, 6/16,  6/16,  5/16, 8/16}
  local frame_bottom = {-6/16, -5/16, 6/16,  6/16, -2/16, 8/16}
  local frame_left   = {-6/16, -2/16, 6/16, -2/16,  2/16, 8/16}
  local frame_right  = { 2/16, -2/16, 6/16,  6/16,  2/16, 8/16}
  -- Button: fills the hole, flat back at z=8/16.
  -- Unpressed: front at z=5/16 (1/16 proud of frame face).
  -- Pressed:   front at z=7/16 (1/16 recessed behind frame face).
  local button_out = {-2/16, -2/16, 5/16, 2/16, 2/16, 8/16}
  local button_in  = {-2/16, -2/16, 7/16, 2/16, 2/16, 8/16}

  local nodebox_off = { type = "fixed", fixed = { frame_top, frame_bottom, frame_left, frame_right, button_out } }
  local nodebox_on  = { type = "fixed", fixed = { frame_top, frame_bottom, frame_left, frame_right, button_in  } }
  local selection_box = {
    type = "fixed",
    fixed = { {-6/16, -5/16, 6/16, 6/16, 5/16, 8/16} }
  }

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function after_place(pos, placer, _, _)
    logistica.on_signal_sender_change(pos, nil, nil)
    logistica.signal_button_update_infotext(pos)
    if placer and placer:is_player() then
      show_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return end
    logistica.signal_button_press(pos)
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_button_on_connect,
    on_disconnect_from_network = logistica.signal_button_on_disconnect,
    on_hyperspanner_use        = function(pos, player)
      show_formspec(pos, player:get_player_name())
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
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_timer         = logistica.signal_button_timer,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def_off)
  def_on.tiles    = tiles_on
  def_on.node_box = nodebox_on
  def_on.groups   = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname,    def_off)
  minetest.register_node(lname_on, def_on)
end

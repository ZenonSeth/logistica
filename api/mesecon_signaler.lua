
if not minetest.get_modpath("mesecons") then return end

local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:mesecon_signaler"
local SIZE = logistica.settings.cable_size

local forms = {}

local function get_formspec(pos)
  local sigName = logistica.mesecon_signaler_get_name(pos)
  local notFlag = logistica.mesecon_signaler_get_not(pos)
  return "formspec_version[4]"..
    "size[7,3.5]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("Mesecon Signaler").."]"..
    "label[0.5,0.9;"..FS("Sends a Logistica Signal when it receives a Mesecons signal").."]"..
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

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.signal_not ~= nil then
    minetest.get_meta(pos):set_string("signal_not", fields.signal_not == "true" and "1" or "0")
    logistica.mesecon_signaler_on_connect(pos, nil)
  end
  if fields.save or fields.key_enter_field == "signal_name" then
    -- remove old signal contribution before renaming
    local network = logistica.get_network_or_nil(pos)
    if network then logistica.signal_remove_sender(pos, network.controller) end
    if fields.signal_name ~= nil then
      local n = fields.signal_name
      minetest.get_meta(pos):set_string("signal_name",
        (n == "") and "" or logistica.sanitize_signal_name(n))
    end
    logistica.mesecon_signaler_on_connect(pos, nil)
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
    {-0.5, -0.5, -0.5,  0.5, -6/16, 0.5},   -- wide base plate
    {-SIZE, -6/16, -SIZE, SIZE, SIZE, SIZE},  -- cable-width center column
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

-- tile_top_off, tile_top_on: top face texture for each mesecon state.
-- tile_side: texture for all 4 side faces (and the connection pieces).
-- tile_bottom: texture for the bottom face.
-- Tile order: top, bottom, right, left, back, front.
function logistica.register_mesecon_signaler(desc, name, tile_top_off, tile_top_on, tile_side, tile_bottom)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.mesecon_signaler_on_connect,
    on_disconnect_from_network = logistica.mesecon_signaler_on_disconnect,
  }

  local function after_place(pos, placer, _, _)
    logistica.on_signal_sender_change(pos, nil, nil)
    if placer and placer:is_player() then
      show_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
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
    tiles = { tile_top_off, tile_bottom, tile_side, tile_side, tile_side, tile_side },
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
    logistica = logistica_callbacks,
    mesecons = {
      effector = {
        action_on  = function(pos, _node) logistica.mesecon_signaler_action_on(pos)  end,
        action_off = function(pos, _node) logistica.mesecon_signaler_action_off(pos) end,
      }
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def_off)
  def_on.tiles = { tile_top_on, tile_bottom, tile_side, tile_side, tile_side, tile_side }
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname, def_off)
  minetest.register_node(lname_on, def_on)
end

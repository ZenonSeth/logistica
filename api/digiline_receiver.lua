
if not minetest.get_modpath("digilines") then return end

local FS   = logistica.FTRANSLATOR
local SIZE = logistica.settings.cable_size
local FORMSPEC_NAME = "logistica:digiline_receiver"

local forms = {}

local function get_formspec(pos)
  local meta    = minetest.get_meta(pos)
  local channel = meta:get_string("channel")
  local sigName = meta:get_string("signal_name")
  return
    "formspec_version[4]" ..
    "size[" .. logistica.inv_size(8.5, 5.0) .. "]" ..
    logistica.ui.background ..
    logistica.ui.button_only_style ..
    "label[0.5,0.4;"  .. FS("Digiline to Signal Converter") .. "]" ..
    "label[0.5,1.15;" .. FS("Digiline channel:") .. "]" ..
    "field[3.2,0.85;4.5,0.75;channel;;"     .. minetest.formspec_escape(channel) .. "]" ..
    "label[0.5,2.0;"  .. FS("Signal:") .. "]" ..
    "field[3.2,1.7;4.5,0.75;signal_name;;" .. minetest.formspec_escape(sigName) .. "]" ..
    "button_exit[2.75,2.65;3.0,0.75;save;" .. FS("Save") .. "]" ..
    "label[0.5,3.7;"  .. FS("Sends Logsitica signal with the given 'Signal' name, of: ") .. "]" ..
    "label[0.5,4.1;"  .. FS("ON when digiline message is: true, \"true\", \"on\", or integer > 0") .. "]" ..
    "label[0.5,4.5;"  .. FS("OFF when digiline message is any other value") .. "]"
end

function logistica.digiline_receiver_show_formspec(playerName, pos)
  if not forms[playerName] then forms[playerName] = {} end
  forms[playerName].position = pos
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  if not player or not player:is_player() then return false end
  local playerName = player:get_player_name()
  local data = forms[playerName]
  if not data then return false end
  local pos = data.position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
    return true
  end

  if fields.save
    or fields.key_enter_field == "channel"
    or fields.key_enter_field == "signal_name"
  then
    logistica.digiline_receiver_save(
      pos,
      fields.channel     or "",
      fields.signal_name or ""
    )
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

function logistica.register_digiline_receiver(desc, name, tile_side, tile_top, tile_bottom)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.digiline_receiver_on_connect,
    on_disconnect_from_network = logistica.digiline_receiver_on_disconnect,
  }

  local nodebox = {
    type = "connected",
    fixed = {
      {-0.5, -0.5, -0.5,  0.5, -6/16, 0.5},
      {-SIZE, -6/16, -SIZE, SIZE, 0.5, SIZE},
    },
    connect_top   = {-SIZE, -SIZE, -SIZE, SIZE, 0.5,  SIZE},
    connect_front = {-SIZE, -SIZE, -0.5,  SIZE, SIZE, SIZE},
    connect_back  = {-SIZE, -SIZE,  SIZE, SIZE, SIZE, 0.5 },
    connect_left  = {-0.5,  -SIZE, -SIZE, SIZE, SIZE, SIZE},
    connect_right = {-SIZE, -SIZE, -SIZE, 0.5,  SIZE, SIZE},
  }

  local sel_box = {
    type  = "fixed",
    fixed = { {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5} },
  }

  local def_off = {
    description = desc,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "none",
    sunlight_propagates = true,
    is_ground_content = false,
    tiles = { tile_top, tile_bottom, tile_side, tile_side, tile_side, tile_side },
    node_box = nodebox,
    selection_box = sel_box,
    connects_to = { logistica.GROUP_ALL, logistica.GROUP_CABLE_OFF },
    connect_sides = {"top", "left", "right", "back", "front"},
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = logistica.digiline_receiver_after_place,
    after_dig_node   = logistica.digiline_receiver_after_dig,
    on_rightclick    = logistica.digiline_receiver_on_rightclick,
    logistica = logistica_callbacks,
    digiline = {
      effector = {
        action = function(pos, node, channel, msg)
          logistica.digiline_receiver_effector(pos, node, channel, msg)
        end,
      },
    },
    _mcl_hardness         = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on      = table.copy(def_off)
  def_on.tiles      = { tile_top, tile_bottom, tile_side, tile_side, tile_side, tile_side }
  def_on.groups     = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname,    def_off)
  minetest.register_node(lname_on, def_on)
end

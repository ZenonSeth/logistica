
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_lamp_2c"

local forms = {}
-- registry[node_name] = { color_a = "blue", color_b = "red", base = "logistica:name" }
-- All three variants (base, _a, _b) map to the same entry.
local registry = {}

local function get_entry(pos)
  return registry[minetest.get_node(pos).name]
end

local function get_formspec(pos)
  local entry = get_entry(pos)
  if not entry then return "" end
  local sigName    = logistica.signal_lamp_2c_get_name(pos)
  local active     = logistica.signal_lamp_2c_get_active_color(pos)
  local ca, cb     = entry.color_a, entry.color_b
  local elseLabel  = (active == "a") and cb or ca
  local selIdx     = (active == "a") and "1" or "2"
  local colorList  = minetest.formspec_escape(ca) .. "," .. minetest.formspec_escape(cb)
  return "formspec_version[4]"..
    "size[7,3.8]"..
    logistica.ui.background..
    logistica.ui.button_style..
    "label[0.5,0.4;"..FS("Signal Lamp (2-Color)").."]"..
    "label[0.5,1.1;"..FS("Shows:").."]"..
    "dropdown[1.75,0.8;2.0,0.65;active_color;"..colorList..";"..selIdx.."]"..
    "label[3.85,1.1;"..FS("if:").."]"..
    "field[4.25,0.8;2.25,0.65;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[1.75,1.6;"..FS("a-z 0-9 _ only").."]"..
    "label[0.5,2.2;"..FS("else: ")..minetest.formspec_escape(elseLabel).."]"..
    "button_exit[2.0,2.75;3.0,0.75;save;"..FS("Save").."]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function save_fields(pos, fields)
  local entry = get_entry(pos)
  if not entry then return end
  if fields.active_color ~= nil then
    local newColor = (fields.active_color == entry.color_a) and "a" or "b"
    minetest.get_meta(pos):set_string("active_color", newColor)
  end
  if fields.signal_name ~= nil then
    local n = fields.signal_name
    minetest.get_meta(pos):set_string("signal_name",
      (n == "") and "" or logistica.sanitize_signal_name(n))
  end
end

local function reapply(pos)
  local network = logistica.get_network_or_nil(pos)
  if network then logistica.signal_lamp_2c_on_connect(pos, network.controller) end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  local dropdownChanged = fields.active_color ~= nil

  if fields.save or fields.key_enter_field == "signal_name" then
    save_fields(pos, fields)
    reapply(pos)
    forms[playerName] = nil
  elseif fields.quit then
    forms[playerName] = nil
  elseif dropdownChanged then
    -- dropdown fires immediately; reshow so "else:" label updates
    save_fields(pos, fields)
    reapply(pos)
    show_formspec(pos, playerName)
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
  type = "fixed",
  fixed = {
    {-4/16,  1/16, -4/16,  4/16,  8/16,  4/16},  -- top light
    {-3/16, -3/16, -3/16,  3/16,  3/16,  3/16},  -- neck
    {-4/16, -8/16, -4/16,  4/16, -1/16,  4/16},  -- bottom light
  }
}

local SEL_BOX = {
  type = "fixed",
  fixed = { {-4/16, -8/16, -4/16, 4/16, 8/16, 4/16} }
}

local function make_tiles(top, side)
  return { top, top, side, side, side, side }
end

-- color_a_name / color_b_name: strings shown in the formspec dropdown.
-- tile_X_top, tile_X_side: 2 textures per state (top+bottom face, 4 side faces).
function logistica.register_signal_lamp_2c(desc, name,
    color_a_name, tile_a_top, tile_a_side,
    color_b_name, tile_b_top, tile_b_side,
    tile_off_top, tile_off_side)

  local lname   = "logistica:" .. name
  local lname_a = lname .. "_a"
  local lname_b = lname .. "_b"

  local entry = { color_a = color_a_name, color_b = color_b_name, base = lname }
  registry[lname]   = entry
  registry[lname_a] = entry
  registry[lname_b] = entry

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_lamp_2c_on_connect,
    on_disconnect_from_network = logistica.signal_lamp_2c_on_disconnect,
    on_signal_received         = logistica.signal_lamp_2c_on_signal_received,
  }

  local function after_place(pos, placer, _, _)
    local meta = minetest.get_meta(pos)
    meta:set_string("color_a_name", color_a_name)
    meta:set_string("color_b_name", color_b_name)
    logistica.on_signal_receiver_change(pos, nil, nil)
    if placer and placer:is_player() then
      show_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local def_base = {
    description = desc,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = false,
    is_ground_content = false,
    tiles = make_tiles(tile_off_top, tile_off_side),
    node_box = NODEBOX,
    selection_box = SEL_BOX,
    collision_box = SEL_BOX,
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

  local def_a = table.copy(def_base)
  def_a.tiles = make_tiles(tile_a_top, tile_a_side)
  def_a.light_source = 12
  def_a.groups = table.copy(grps)
  def_a.groups.not_in_creative_inventory = 1

  local def_b = table.copy(def_base)
  def_b.tiles = make_tiles(tile_b_top, tile_b_side)
  def_b.light_source = 12
  def_b.groups = table.copy(grps)
  def_b.groups.not_in_creative_inventory = 1

  logistica.GROUPS.signal_receivers.register(lname)
  logistica.GROUPS.signal_receivers.register(lname_a)
  logistica.GROUPS.signal_receivers.register(lname_b)

  minetest.register_node(lname, def_base)
  minetest.register_node(lname_a, def_a)
  minetest.register_node(lname_b, def_b)
end

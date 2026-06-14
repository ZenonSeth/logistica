
local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME  = "logistica_woodcutter"
local ON_OFF_BUTTON  = "on_off_btn"
local INV_UPGRADE    = "upgrade"
local LEAVES_UPGRADE = "logistica:leaves_upgrade"

local RESULT_MSGS = {
  [1] = FS("No tree found at facing position (sneak+punch to see)."),
  [2] = FS("Tree too tall (max 30 nodes)."),
  [3] = FS("Too many nodes (max 500 total)."),
  [4] = FS("Inventory full."),
}

local LAVA_MAX = 1000

local function get_lava_indicator(pos, x, y, h)
  local lava = logistica.woodcutter_get_lava(pos)
  local pct = logistica.round(lava / LAVA_MAX * 100)
  local img
  if pct > 0 then
    img = "image["..x..","..y..";0.8,"..h..
      ";logistica_lava_furnace_tank_bg.png^[lowpart:"..pct..":logistica_lava_furnace_tank.png]"
  else
    img = "image["..x..","..y..";0.8,"..h..";logistica_lava_furnace_tank_bg.png]"
  end
  return "label["..x..","..(y - 0.35)..";"..FS("Lava").."]"..
    img..
    "tooltip["..x..","..y..";0.8,"..h..";"..FS("Lava reserve: ")..(lava).."/"..LAVA_MAX.."\nTaken From Network\nUses 1/1000th per harvest]"
end

local forms = {}

local function get_woodcutter_formspec(pos)
  local posForm = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
  local isOn    = logistica.is_machine_on(pos)
  local result  = logistica.woodcutter_get_harvest_result(pos)
  local cutting = logistica.woodcutter_is_cutting(pos)

  local status = ""
  if cutting then
    status = FS("Cutting...")
  elseif result > 0 then
    status = RESULT_MSGS[result] or ""
  end

  return "formspec_version[4]" ..
    "size[" .. logistica.inv_size(10.5, 10.5) .. "]" ..
    logistica.ui.background ..
    logistica.ui.button_only_style ..
    "label[0.5,0.6;" .. FS("Harvests the tree it faces, and supplies wood to the network.") .. "]" ..
    "list[" .. posForm .. ";main;0.4,1.2;7,2;0]" ..
    (status ~= "" and ("label[0.4,3.7;" .. minetest.formspec_escape(status) .. "]") or "") ..
    logistica.ui.on_off_btn(isOn, 4.0, 4.0, ON_OFF_BUTTON, FS("Enable")) ..
    "label[6.1,4.0;" .. FS("Leafcutter Upgrade") .. "]" ..
    "list[" .. posForm .. ";" .. INV_UPGRADE .. ";6.65,4.3;1,1;0]" ..
    get_lava_indicator(pos, 9.3, 1.0, 4.2) ..
    "label[0.5,5.1;" .. FS("Requires Lava in the Network to function") .. "]" ..
    logistica.player_inv_formspec(0.4, 5.6) ..
    "listring[current_player;main]" ..
    "listring[" .. posForm .. ";main]"
end

local function show_woodcutter_formspec(player_name, pos)
  forms[player_name] = { position = pos }
  minetest.show_formspec(player_name, FORMSPEC_NAME, get_woodcutter_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local player_name = player:get_player_name()
  if not forms[player_name] then return false end
  local pos = forms[player_name].position
  if not logistica.player_has_network_access(pos, player_name) then return true end

  if fields.quit then
    forms[player_name] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_woodcutter_formspec(player_name, pos)
  end
  return true
end

local function on_woodcutter_rightclick(pos, _node, clicker, _itemstack, _pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  show_woodcutter_formspec(clicker:get_player_name(), pos)
end

local function get_target_pos(pos)
  local node = minetest.get_node(pos)
  local dirs = logistica.get_rot_directions(node.param2)
  if not dirs then return nil end
  return vector.add(pos, dirs.backward)
end

local function on_woodcutter_punch(pos, _node, puncher, _pointed_thing)
  if not puncher or not puncher:is_player() then return end
  if puncher:get_player_control().sneak then
    local target = get_target_pos(pos)
    if target then logistica.show_input_at(target, tostring(minetest.hash_node_position(pos))) end
  end
end

local function on_woodcutter_rotate(pos, node, player, mode, newParam2)
  local dirs = logistica.get_rot_directions(newParam2)
  if not dirs then return end
  logistica.show_input_at(vector.add(pos, dirs.backward), tostring(minetest.hash_node_position(pos)))
end

local function after_place_woodcutter(pos, _placer, _itemstack)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  inv:set_size("main", logistica.get_supplier_inv_size(pos))
  inv:set_size(INV_UPGRADE, 1)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
  local target = get_target_pos(pos)
  if target then logistica.show_input_at(target, tostring(minetest.hash_node_position(pos))) end
end

local function allow_woodcutter_inv_put(pos, listname, _, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == INV_UPGRADE then
    if stack:get_name() ~= LEAVES_UPGRADE then return 0 end
    return 1
  end
  return 0 -- main list is output-only
end

local function allow_woodcutter_inv_take(pos, _, _, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_woodcutter_inv_move(pos, _, _, _, _, count, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  return count
end

local function on_woodcutter_inv_change(pos, _, _, _, _)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function can_dig_woodcutter(pos, _)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty("main") and inv:is_empty(INV_UPGRADE)
end

local function on_woodcutter_power(pos, power)
  logistica.woodcutter_on_power(pos, power)
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, _timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_woodcutter(desc, name, inventorySize, tiles)
  local lname     = string.lower(name:gsub(" ", "_"))
  local node_name = "logistica:" .. lname
  logistica.GROUPS.wood_suppliers.register(node_name)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1}
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype  = "nodebox",
    node_box  = {
      type  = "fixed",
      fixed = {
        -- body bottom (rotated: original bottom box)
        {-7/16, -8/16, -8/16,  7/16,  0/16,  8/16},
        -- body top/front (rotated: original top box, sits on front/player-facing side)
        {-7/16,  0/16, -8/16,  7/16,  8/16,  0/16},
        -- saw blade toward tree (+Z = backward), quarter-circle approximation:
        {-1/64,  5/16,  0/16,  1/64,  6/16,  3/16},  -- top segment
        {-1/64,  4/16,  0/16,  1/64,  5/16,  5/16},  -- lower top
        {-1/64,  3/16,  0/16,  1/64,  4/16,  6/16},  -- upper-middle segment
        {-1/64,  2/16,  0/16,  1/64,  3/16,  6/16},  -- lower-middle segment
        {-1/64,  0/16,  0/16,  1/64,  2/16,  7/16},  -- bottom segment
      }
    },
    selection_box = {
      type = "fixed",
      fixed = {
        {-7/16, -8/16, -8/16,  7/16,  0/16,  8/16},
        {-7/16,  0/16, -8/16,  7/16,  8/16,  0/16},
      }
    },
    collision_box = {
      type = "fixed",
      fixed = {
        {-7/16, -8/16, -8/16,  7/16,  0/16,  8/16},
        {-7/16,  0/16, -8/16,  7/16,  8/16,  0/16},
      }
    },
    tiles     = tiles,
    paramtype  = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups    = grps,
    drop      = node_name,
    sounds    = logistica.node_sound_metallic(),
    after_place_node = after_place_woodcutter,
    after_dig_node   = logistica.on_supplier_change,
    on_punch         = on_woodcutter_punch,
    on_rotate        = on_woodcutter_rotate,
    on_rightclick    = on_woodcutter_rightclick,
    allow_metadata_inventory_put  = allow_woodcutter_inv_put,
    allow_metadata_inventory_take = allow_woodcutter_inv_take,
    allow_metadata_inventory_move = allow_woodcutter_inv_move,
    on_metadata_inventory_put  = on_woodcutter_inv_change,
    on_metadata_inventory_take = on_woodcutter_inv_change,
    on_timer  = logistica.woodcutter_on_timer,
    can_dig   = can_dig_woodcutter,
    logistica = {
      inventory_size = inventorySize,
      on_power       = on_woodcutter_power,
      automatable    = true,
    },
    _mcl_hardness        = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(node_name, def)
  logistica.register_non_pushable(node_name)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v .. "^logistica_disabled.png" end
  def_disabled.tiles  = tiles_disabled
  def_disabled.groups = {oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, handy = 1, pickaxey = 1, axey = 1, not_in_creative_inventory = 1}
  def_disabled.on_construct  = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch      = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer      = nil
  def_disabled.logistica     = nil

  minetest.register_node(node_name .. "_disabled", def_disabled)
end

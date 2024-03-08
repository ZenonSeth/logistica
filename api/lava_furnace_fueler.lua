
local S = logistica.TRANSLATOR

local ON_OFF_BUTTON = "on_off_btn"
local FORMSPEC_NAME = "logistica_lvfurnfueler"
local BTN_INC = "btninc"
local BTN_DEC = "btndec"
local META_TARGET_LAVA = "tarlava"
local MAX_LAVA = 4000 -- not really related to lava furnace, but this is a refueler, so it should be fine

local forms = {}

local function get_lava_img(currLava, lavaPercent)
  local img = ""
  if lavaPercent > 0 then
    img = "image[4.1,1.6;1,3;logistica_lava_furnace_tank_bg.png^[lowpart:"..
      lavaPercent..":logistica_lava_furnace_tank.png]"
  else
    img = "image[4.1,1.6;1,3;logistica_lava_furnace_tank_bg.png]"
  end
  return img.."tooltip[4.1,1.6;1,3;"..S("Refuel if level below: ")..(currLava/1000)..S(" Buckets").."]"
end

local function get_fueler_formspec(pos)
  local isOn = logistica.is_machine_on(pos)
  local meta = minetest.get_meta(pos)
  local currLava = meta:get_int(META_TARGET_LAVA)
  local lavaPercent = logistica.round(currLava / MAX_LAVA * 100)
  return "formspec_version[4]"..
      "size[8.0,5.5]"..
      logistica.ui.background_lava_furnace..
      "label[0.2,0.2;"..S("Lava Furnace Fueler: Refuels Lava Furnace").."]"..
      "label[0.2,0.6;"..S("from Reservoirs connected to Network").."]"..
      "label[2.0,1.3;"..S("Refuel when lava drops below:").."]"..
      "button[2.9,1.6;1,1;"..BTN_INC..";+]"..
      "button[2.9,3.6;1,1;"..BTN_DEC..";-]"..
      "label[3.7,4.9;"..(currLava/1000)..S(" Buckets").."]"..
      get_lava_img(currLava, lavaPercent)..
      logistica.ui.on_off_btn(isOn, 0.5, 1.3, ON_OFF_BUTTON, S("Enable"))
end

local function change_target_lava(pos, change)
  local meta = minetest.get_meta(pos)
  local currLevel = meta:get_int(META_TARGET_LAVA)
  local newLevel = logistica.clamp(currLevel + change * 200, 0, MAX_LAVA)
  meta:set_int(META_TARGET_LAVA, newLevel)
end

local function show_fueler_formspec(playerName, pos)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_fueler_formspec(pos))
end

-- callbacks

local function on_fueler_recieve_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_fueler_formspec(player:get_player_name(), pos)
  elseif fields[BTN_INC] then
    change_target_lava(pos, 1)
    show_fueler_formspec(player:get_player_name(), pos)
  elseif fields[BTN_DEC] then
    change_target_lava(pos, -1)
    show_fueler_formspec(player:get_player_name(), pos)
  end
  return true
end

local function on_fueler_punch(pos, node, puncher, pointed_thing)
  local targetPos = logistica.lava_furnace_fueler_target_pos(pos)
  if targetPos and puncher:is_player() and puncher:get_player_control().sneak then
    logistica.show_output_at(targetPos)
  end
end

local function on_fueler_right_click(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_fueler_formspec(clicker:get_player_name(), pos)
end

local function after_place_fueler(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  logistica.show_output_at(logistica.lava_furnace_fueler_target_pos(pos))
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_lava_furnace_fueler_change(pos)
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_fueler_recieve_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_lava_furnace_fueler(description, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local fuelerName = "logistica:"..lname
  logistica.misc_machines[fuelerName] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1, }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = description,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = fuelerName,
    sounds = logistica.node_sound_metallic(),
    on_timer = logistica.on_timer_powered(logistica.lava_furnace_fueler_on_timer),
    after_place_node = function (pos, placer, itemstack)
      after_place_fueler(pos, placer, itemstack)
    end,
    after_dig_node = logistica.on_lava_furnace_fueler_change,
    on_punch = on_fueler_punch,
    on_rightclick = on_fueler_right_click,
    logistica = {
      on_connect_to_network = function(pos, networkId)
        logistica.lava_furnace_fueler_start_timer(pos)
      end,
      on_power = function(pos, isPoweredOn)
        if isPoweredOn then
          logistica.lava_furnace_fueler_start_timer(pos)
        end
        logistica.set_node_tooltip_from_state(pos, nil, isPoweredOn)
      end,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(fuelerName, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, handy = 1, pickaxey = 1, axey = 1, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(fuelerName.."_disabled", def_disabled)

end

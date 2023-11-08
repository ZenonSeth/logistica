
local NUM_DEMAND_SLOTS = 4 -- maybe at some point make this a param, but why?
local PUSH_LIST_PICKER = "push_pick"
local ON_OFF_BUTTON = "on_off_btn"
local FORMSPEC_NAME = "logistica_demander"

local demanderForms = {}

local function get_demander_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local pushPos = logistica.get_demander_target(pos)
  local selectedList = logistica.get_demander_target_list(pos)
  local isOn = logistica.is_machine_on(pos)
  return "formspec_version[4]" ..
    "size[10.6,7]" ..
    logistica.ui.background..
    logistica.ui.push_list_picker(PUSH_LIST_PICKER, 6.7, 0.7, pushPos, selectedList, "Put items in:")..
    logistica.ui.on_off_btn(isOn, 9.3, 0.5, ON_OFF_BUTTON, "Enable")..
    "list["..posForm..";filter;0.5,0.5;"..NUM_DEMAND_SLOTS..",1;0]"..
    "list[current_player;main;0.5,2;8,4;0]"
end

local function show_demander_formspec(playerName, pos)
  local pInfo = {}
  pInfo.position = pos
  demanderForms[playerName] = pInfo
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_demander_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not demanderForms[playerName] then return false end
  if fields.quit then
    demanderForms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    local pos = demanderForms[playerName].position
    if not pos then return false end
    logistica.toggle_machine_on_off(pos)
    show_demander_formspec(player:get_player_name(), pos)
  elseif fields[PUSH_LIST_PICKER] then
    local selected = fields[PUSH_LIST_PICKER]
    if logistica.is_allowed_push_list(selected) then
      local pos = demanderForms[playerName].position
      if not pos then return false end
      logistica.set_demander_target_list(pos, selected)
    end
  end
  return true
end

local function on_demander_punch(pos, node, puncher, pointed_thing)
  local targetPos = logistica.get_demander_target(pos)
  if targetPos and puncher:is_player() and puncher:get_player_control().sneak then
    minetest.add_entity(targetPos, "logistica:output_entity")
  end
end

local function on_demander_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  show_demander_formspec(clicker:get_player_name(), pos)
end

local function after_place_demander(pos, placer, itemstack, numDemandSlots)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
	  meta:set_string("owner", placer:get_player_name())
  end
  logistica.set_demander_target_list(pos, "main")
	local inv = meta:get_inventory()
	inv:set_size("filter", numDemandSlots)
  logistica.on_demander_change(pos)
  logistica.start_demander_timer(pos)
end

local function allow_demander_storage_inv_put(pos, listname, index, stack, player)
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local slotStack = inv:get_stack(listname, index)
  slotStack:add_item(stack)
  inv:set_stack(listname, index, slotStack)
  logistica.start_demander_timer(pos, 1)
  return 0
end

local function allow_demander_inv_take(pos, listname, index, stack, player)
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local slotStack = inv:get_stack(listname, index)
  slotStack:take_item(stack:get_count())
  inv:set_stack(listname, index, slotStack)
  return 0
end

local function allow_demander_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if from_list ~= "filter" and to_list ~= "filter" then return 0 end
  return count
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
-- transferRate is how many items per tick this demander can transfer, -1 for unlimited
function logistica.register_demander(simpleName, transferRate)
  local lname = string.lower(simpleName:gsub(" ", "_"))
  local demander_name = "logistica:demander_"..lname
  logistica.demanders[demander_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = simpleName.." Demander",
    drawtype = "normal",
    tiles = {
      "logistica_"..lname.."_demander_side.png^[transformR270",
      "logistica_"..lname.."_demander_side.png^[transformR90",
      "logistica_"..lname.."_demander_side.png^[transformR180",
      "logistica_"..lname.."_demander_side.png",
      "logistica_"..lname.."_demander_back.png",
      "logistica_"..lname.."_demander_front.png",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = demander_name,
    sounds = logistica.node_sound_metallic(),
    on_timer = logistica.on_demander_timer,
    after_place_node = function (pos, placer, itemstack)
      after_place_demander(pos, placer, itemstack, NUM_DEMAND_SLOTS)
    end,
    on_punch = on_demander_punch,
    on_rightclick = on_demander_rightclick,
    allow_metadata_inventory_put = allow_demander_storage_inv_put,
    allow_metadata_inventory_take = allow_demander_inv_take,
    allow_metadata_inventory_move = allow_demander_inv_move,
    logistica = {
      demander_transfer_rate = transferRate,
      on_connect_to_network = function(pos, networkId)
        logistica.start_demander_timer(pos)
      end,
      on_power = function(pos, isPoweredOn)
        if isPoweredOn then
          logistica.start_demander_timer(pos)
        end
      end,
    }
  }

  minetest.register_node(demander_name, def)

	local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_desctruct = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

	minetest.register_node(demander_name.."_disabled", def_disabled)

end

logistica.register_demander("Item", 1)
logistica.register_demander("Stack", 99)

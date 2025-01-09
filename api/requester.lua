local FS = logistica.FTRANSLATOR

local NUM_REQUEST_SLOTS = 4 -- maybe at some point make this a param, but why?
local PUSH_LIST_PICKER = "push_pick"
local ON_OFF_BUTTON = "on_off_btn"
local INF_CHECKBOX_PREFIX = "infchk"
local FORMSPEC_NAME = "logistica_requester"

local requesterForms = {}

local function get_checkbox_name_from_index(index)
  return INF_CHECKBOX_PREFIX..tostring(index)
end

local function get_filter_list_inf_checkboxes(checkboxStates, x, y)
  local checkboxes = {}
  for i = 1, NUM_REQUEST_SLOTS do
    local checkboxName = get_checkbox_name_from_index(i)
    local ticked = "false" ; if checkboxStates[i] then ticked = "true" end
    checkboxes[i] =
      "checkbox["..(x + 0.1 + (i - 1) * 1.25)..","..y..";"..checkboxName..";Inf;"..ticked.."]"..
      "tooltip["..checkboxName..";"..FS("Tick this to always try to insert the item above into the target inventory,\nregardless of how many of that item the target inventory contains.\nThe number of items put above is then requested every second.").."]"
  end
  return table.concat(checkboxes)
end

local function get_requester_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local pushPos = logistica.get_requester_target(pos)
  local selectedList = logistica.get_requester_target_list(pos)
  local isOn = logistica.is_machine_on(pos)
  local checkboxStates = logistica.get_requester_inf_state(pos)
  return "formspec_version[4]" ..
    "size["..logistica.inv_size(10.6, 8.45).."]" ..
    logistica.ui.background..
    logistica.ui.push_list_picker(PUSH_LIST_PICKER, 6.7, 1.5, pushPos, selectedList, FS("Put items in:"))..
    logistica.ui.on_off_btn(isOn, 9.3, 1.3, ON_OFF_BUTTON, FS("Enable"))..
    "label[0.5,0.4;"..FS("Configure items and count to put, and keep a minimium of, in target's inventory").."]"..
    "label[0.5,0.7;"..FS("Or tick the \"Inf\" (infinite) checkbox below a slot to always keep inserting the item.").."]"..
    "list["..posForm..";filter;0.5,1.2;"..NUM_REQUEST_SLOTS..",1;0]"..
    get_filter_list_inf_checkboxes(checkboxStates, 0.5, 2.5)..
    logistica.player_inv_formspec(0.5, 3.0)..
    "listring[current_player;main]"..
    "listring["..posForm..";filter]"
end

local function show_requester_formspec(playerName, pos)
  requesterForms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_requester_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not requesterForms[playerName] then return false end
  local pos = requesterForms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end

  local reshow = false
  -- infinite checkboxes check
  for i = 1, NUM_REQUEST_SLOTS do
    local checkboxName = get_checkbox_name_from_index(i)
    if fields[checkboxName] ~= nil then
      logistica.requester_on_infinite_request_toggle(pos, i, fields[checkboxName] == "true")
      reshow = true
    end
  end

  if fields.quit then
    requesterForms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    if not pos then return false end
    logistica.toggle_machine_on_off(pos)
    show_requester_formspec(player:get_player_name(), pos)
  elseif fields[PUSH_LIST_PICKER] then
    local selected = fields[PUSH_LIST_PICKER]
    if logistica.is_allowed_push_list(selected) then
      local pos = requesterForms[playerName].position
      if not pos then return false end
      logistica.set_requester_target_list(pos, selected)
    end
  end
  if reshow then show_requester_formspec(player:get_player_name(), pos) end
  return true
end

local function on_requester_punch(pos, node, puncher, pointed_thing)
  local targetPos = logistica.get_requester_target(pos)
  if targetPos and puncher:is_player() and puncher:get_player_control().sneak then
    logistica.show_output_at(targetPos)
  end
end

local function on_requester_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_requester_formspec(clicker:get_player_name(), pos)
end

local function after_place_requester(pos, placer, itemstack, numRequestSlots)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  logistica.set_requester_target_list(pos, "main")
  local inv = meta:get_inventory()
  inv:set_size("filter", numRequestSlots)
  inv:set_size("actual", numRequestSlots)
  logistica.on_requester_change(pos)
  logistica.show_output_at(logistica.get_requester_target(pos))
  logistica.set_node_tooltip_from_state(pos, nil, false)
end

local function allow_requester_storage_inv_put(pos, listname, index, stack, player)
  if listname ~= "filter" then return 0 end
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local slotStack = inv:get_stack(listname, index)
  slotStack:add_item(stack)
  inv:set_stack(listname, index, slotStack)
  logistica.update_cache_at_pos(pos, LOG_CACHE_REQUESTER)
  logistica.start_requester_timer(pos, 1)
  return 0
end

local function allow_requester_inv_take(pos, listname, index, stack, player)
  if listname ~= "filter" then return 0 end
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local slotStack = inv:get_stack(listname, index)
  slotStack:take_item(stack:get_count())
  inv:set_stack(listname, index, slotStack)
  logistica.update_cache_at_pos(pos, LOG_CACHE_REQUESTER)
  return 0
end

local function allow_requester_inv_move(_, _, _, _, _, _, _)
  return 0
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    requesterForms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
-- transferRate is how many items per tick this requester can transfer, -1 for unlimited
function logistica.register_requester(description, name, transferRate, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local requester_name = "logistica:"..lname
  logistica.GROUPS.requesters.register(requester_name)
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
    drop = requester_name,
    sounds = logistica.node_sound_metallic(),
    on_timer = logistica.on_timer_powered(logistica.on_requester_timer),
    after_place_node = function (pos, placer, itemstack)
      after_place_requester(pos, placer, itemstack, NUM_REQUEST_SLOTS)
    end,
    after_dig_node = logistica.on_requester_change,
    on_punch = on_requester_punch,
    on_rightclick = on_requester_rightclick,
    allow_metadata_inventory_put = allow_requester_storage_inv_put,
    allow_metadata_inventory_take = allow_requester_inv_take,
    allow_metadata_inventory_move = allow_requester_inv_move,
    logistica = {
      requester_transfer_rate = transferRate,
      on_connect_to_network = function(pos, networkId)
        logistica.start_requester_timer(pos)
      end,
      on_power = function(pos, isPoweredOn)
        logistica.set_node_tooltip_from_state(pos, nil, isPoweredOn)
        if isPoweredOn then
          logistica.start_requester_timer(pos)
        end
      end,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(requester_name, def)
  logistica.register_non_pushable(requester_name)

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

  minetest.register_node(requester_name.."_disabled", def_disabled)

end

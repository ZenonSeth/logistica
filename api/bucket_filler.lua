local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "logistica_bktfil"
local INV_MAIN = "main"
local INV_INPUT = "input"

local BTN_NEXT_LIQUID = "btn_next"
local BTN_PREV_LIQUID = "btn_prev"

local TOOLTIP_BUCKET_INPUT = S("If no Empty Buckets are added here,\nthen they will be taken from the network.")

local forms = {}

local function get_filler_formspec(pos, errorMsg)
  if not errorMsg then errorMsg = "" else errorMsg = S("Error: ")..errorMsg end
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local currLiquid = logistica.filler_get_current_selected_bucket(pos)
  local liquidInfo = logistica.get_liquid_info_in_network(pos, currLiquid.liquidName)
  local liquidText = ItemStack(currLiquid.bucketName):get_short_description()
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.5, 9).."]"..
    logistica.ui.background..
    "list["..posForm..";"..INV_MAIN..";6.7,1.2;1,1;0]"..
    "list["..posForm..";"..INV_INPUT..";0.4,1.2;4,1;0]"..
    "label[0.4,0.4;"..S("Supplies the selected filled buckets on-demand, if empty buckets are available").."]"..
    "label[0.4,1.0;"..S("Optional Empty Buckets").." \\[?\\]]"..
    "button[5.8,1.3;0.8,0.8;"..BTN_PREV_LIQUID..";<]"..
    "button[7.8,1.3;0.8,0.8;"..BTN_NEXT_LIQUID..";>]"..
    "label[0.4,3.0;"..errorMsg.."]"..
    "label[5.7,1.0;"..S("Supply")..": "..liquidText.."]"..
    "label[5.7,2.5;"..S("Amount Available")..": "..liquidInfo.curr.." ]"..
    "tooltip[0.2,0.4;3.5,1.0;"..TOOLTIP_BUCKET_INPUT.."]"..
    "listring[current_player;main]"..
    "listring["..posForm..";"..INV_INPUT.."]"..
    "listring[current_player;main]"..
    logistica.player_inv_formspec(0.4,4)
end

local function show_filler_formspec(playerName, pos)
  if not forms[playerName] then forms[playerName] = {position = pos} end
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_filler_formspec(pos, forms[playerName].errorMsg))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[BTN_PREV_LIQUID] then
    logistica.filler_change_selected_bucket(pos, -1)
    show_filler_formspec(playerName, pos)
  elseif fields[BTN_NEXT_LIQUID] then
    logistica.filler_change_selected_bucket(pos, 1)
    show_filler_formspec(playerName, pos)
  end
  return true
end

local function on_filler_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_filler_formspec(clicker:get_player_name(), pos)
end

local function after_place_filler(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_MAIN, 1)
  inv:set_size(INV_INPUT, 4)
  logistica.set_node_tooltip_from_state(pos)
  logistica.filler_change_selected_bucket(pos, 1000000) -- makes sure the 1st liquid is selected
  logistica.on_supplier_change(pos)
end

local function allow_filler_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_MAIN then return 0 end
  if listname == INV_INPUT then
    if logistica.reservoir_is_empty_bucket(stack:get_name()) then return stack:get_count()
    else return 0 end
  end
end

local function allow_filler_inv_take(pos, listname, index, stack, player)
  local playerName = player:get_player_name()
  if minetest.is_protected(pos, playerName) then return 0 end
  if listname == INV_MAIN then
    local numTaken = 0
    local takeFunc = function(takenStack) numTaken = takenStack:get_count() ; return 0 end
    local result = logistica.take_item_from_bucket_filler(pos, stack, logistica.get_network_or_nil(pos), takeFunc, false, false)
    if forms[playerName] then
      forms[playerName].errorMsg = result.error
    end
    if numTaken == 0 then show_filler_formspec(player:get_player_name(), pos) end
    return numTaken
  end
  return stack:get_count()
end

local function allow_filler_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

local function on_filler_inv_take(pos, listname, index, stack, player)
  if not player:is_player() then return end
  if listname == INV_MAIN then
    local inv = minetest.get_meta(pos):get_inventory()
    inv:add_item(listname, stack) -- the bucket is an indicator, it needs to remain there
    show_filler_formspec(player:get_player_name(), pos)
  end
end

local function can_dig_filler(pos, player)
  return minetest.get_meta(pos):get_inventory():is_empty(INV_INPUT)
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
function logistica.register_bucket_filler(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local filler_name = "logistica:"..lname
  logistica.GROUPS.bucket_fillers.register(filler_name)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1, }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = filler_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_filler,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_filler_rightclick,
    allow_metadata_inventory_put = allow_filler_inv_put,
    allow_metadata_inventory_take = allow_filler_inv_take,
    allow_metadata_inventory_move = allow_filler_inv_move,
    on_metadata_inventory_take = on_filler_inv_take,
    can_dig = can_dig_filler,
    logistica = {},
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(filler_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, axey = 1, handy = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(filler_name.."_disabled", def_disabled)

end

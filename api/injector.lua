local FS = logistica.FTRANSLATOR

local PULL_LIST_PICKER = "pull_pick"
local ON_OFF_BUTTON = "on_off_btn"
local CBX_REQ = "cbxreq"
local CBX_MAS = "cbxmas"
local CBX_SUP = "cbxsup"
local CBX_TRA = "cbxtra"

local FORMSPEC_NAME = "logistica_storinject"
local NUM_FILTER_SLOTS = 8

local PUT_INTO_TOOLTIP = FS("Select what types of machines this Importer will put items into.\nMachine priority is from top to bottom, e.g. Trashcans, if enabled,\nare always the last machine type that items are put into.")

local injectorForms = {}

local function get_add_into_section(pos, x, y)
  local chst = function(idx) if logistica.injector_get_put_into_state(pos, idx) == true then return "true" else return "false" end end
  return
    "label["..(x)..","..(y + 0.5)..";"..FS("Put in (?):").."]"..
    "checkbox["..(x + 1.3)..","..(y + 0.0)..";"..CBX_REQ..";"..FS("Requesters")..";"..chst(1).."]"..
    "checkbox["..(x + 1.3)..","..(y + 0.4)..";"..CBX_MAS..";"..FS("Mass/Item Storage")..";"..chst(2).."]"..
    "checkbox["..(x + 1.3)..","..(y + 0.8)..";"..CBX_SUP..";"..FS("Supply Chests")..";"..chst(3).."]"..
    "checkbox["..(x + 1.3)..","..(y + 1.2)..";"..CBX_TRA..";"..FS("Trashcans")..";"..chst(4).."]"..
    "tooltip["..(x)..","..(y + 0.2)..";1,0.6;"..PUT_INTO_TOOLTIP.."]"
end

local function get_injector_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local pullPos = logistica.get_injector_target(pos)
  local selectedList = logistica.get_injector_target_list(pos)
  local isOn = logistica.is_machine_on(pos)
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.7, 9.45).."]"..
    logistica.ui.background..
    "label[0.5,0.3;"..FS("Network Importer take items from target and add them to the network").."]"..
    "label[0.5,0.8;"..FS("Filter: Import only filtered. If empty, imports all items.").."]"..
    "list["..posForm..";filter;0.5,1.0;"..NUM_FILTER_SLOTS..",1;0]"..
    logistica.player_inv_formspec(0.5,4.0)..
    "listring[current_player;main]"..
    "listring["..posForm..";filter]"..
    logistica.ui.pull_list_picker(PULL_LIST_PICKER, 0.5, 2.8, pullPos, selectedList, FS("Take items from:"))..
    logistica.ui.on_off_btn(isOn, 4.0, 2.6, ON_OFF_BUTTON, FS("Enable"))..
    get_add_into_section(pos, 6.5, 2.3)
end

local function show_injector_formspec(playerName, pos)
  injectorForms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_injector_formspec(pos))
end

-- callbacks

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not injectorForms[playerName] then return false end
  local pos = injectorForms[playerName].position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    injectorForms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_injector_formspec(player:get_player_name(), pos)
  elseif fields[CBX_REQ] ~= nil then
    logistica.injector_set_put_into_state(pos, 1, fields[CBX_REQ])
  elseif fields[CBX_MAS] ~= nil then
    logistica.injector_set_put_into_state(pos, 2, fields[CBX_MAS])
  elseif fields[CBX_SUP] ~= nil then
    logistica.injector_set_put_into_state(pos, 3, fields[CBX_SUP])
  elseif fields[CBX_TRA] ~= nil then
    logistica.injector_set_put_into_state(pos, 4, fields[CBX_TRA])
  elseif fields[PULL_LIST_PICKER] then -- this has to be last, because its always sent
    local selected = fields[PULL_LIST_PICKER]
    logistica.set_injector_target_list(pos, selected)
  end
  return true
end

local function on_injector_punch(pos, node, puncher, pointed_thing)
  local targetPos = logistica.get_injector_target(pos)
  if targetPos and puncher:is_player() and puncher:get_player_control().sneak then
    logistica.show_input_at(targetPos)
  end
end

local function on_injector_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_injector_formspec(clicker:get_player_name(), pos)
end

local function after_place_injector(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  local inv = meta:get_inventory()
  inv:set_size("filter", NUM_FILTER_SLOTS)
  logistica.set_injector_target_list(pos, "main")
  logistica.on_injector_change(pos)
  logistica.start_injector_timer(pos)
  logistica.show_input_at(logistica.get_injector_target(pos))
end

local function allow_injector_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local copyStack = ItemStack(stack:get_name())
  copyStack:set_count(1)
  inv:set_stack("filter", index, copyStack)
  return 0
end

local function allow_injector_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  local inv = minetest.get_meta(pos):get_inventory()
  local storageStack = inv:get_stack("filter", index)
  storageStack:clear()
  inv:set_stack("filter", index, storageStack)
  return 0
end

local function allow_injector_inv_move(_, _, _, _, _, _, _)
  return 0
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    injectorForms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

-- `simpleName` is used for the description and for the name (can contain spaces)
-- transferRate is how many items per tick this injector can transfer, -1 for unlimited
function logistica.register_injector(description, name, transferRate, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local injectorName = "logistica:"..lname
  logistica.GROUPS.injectors.register(injectorName)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = description,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = injectorName,
    sounds = logistica.node_sound_metallic(),
    on_timer = logistica.on_timer_powered(logistica.on_injector_timer),
    after_place_node = function (pos, placer, itemstack)
      after_place_injector(pos, placer, itemstack)
    end,
    after_dig_node = logistica.on_injector_change,
    on_punch = on_injector_punch,
    on_rightclick = on_injector_rightclick,
    allow_metadata_inventory_put = allow_injector_storage_inv_put,
    allow_metadata_inventory_take = allow_injector_inv_take,
    allow_metadata_inventory_move = allow_injector_inv_move,
    logistica = {
      injector_transfer_rate = transferRate,
      on_connect_to_network = function(pos, networkId)
        logistica.start_injector_timer(pos)
      end,
      on_power = function(pos, isPoweredOn)
        if isPoweredOn then
          logistica.start_injector_timer(pos)
        end
        logistica.set_node_tooltip_from_state(pos, nil, isPoweredOn)
      end,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(injectorName, def)
  logistica.register_non_pushable(injectorName)

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

  minetest.register_node(injectorName.."_disabled", def_disabled)

end

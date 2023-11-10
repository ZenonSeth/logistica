
local PULL_LIST_PICKER = "pull_pick"
local ON_OFF_BUTTON = "on_off_btn"
local FORMSPEC_NAME = "logistica_storinject"

local injectorForms = {}

local function get_injector_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local pushPos = logistica.get_injector_target(pos)
  local selectedList = logistica.get_injector_target_list(pos)
  local isOn = logistica.is_machine_on(pos)
  return "formspec_version[4]" ..
    "size[7,2.0]" ..
    logistica.ui.background..
    "label[0.5,0.3;Active Suppliers try to insert items in the network one at a time]"..
    logistica.ui.pull_list_picker(PULL_LIST_PICKER, 0.5, 1.0, pushPos, selectedList, "Take items from:")..
    logistica.ui.on_off_btn(isOn, 4.5, 0.8, ON_OFF_BUTTON, "Enable")
end

local function show_injector_formspec(playerName, pos)
  local pInfo = {}
  pInfo.position = pos
  injectorForms[playerName] = pInfo
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
  elseif fields[PULL_LIST_PICKER] then
    local selected = fields[PULL_LIST_PICKER]
    if logistica.is_allowed_pull_list(selected) then
      logistica.set_injector_target_list(pos, selected)
    end
  end
  return true
end

local function on_injector_punch(pos, node, puncher, pointed_thing)
  local targetPos = logistica.get_injector_target(pos)
  if targetPos and puncher:is_player() and puncher:get_player_control().sneak then
    minetest.add_entity(targetPos, "logistica:input_entity")
  end
end

local function on_injector_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  show_injector_formspec(clicker:get_player_name(), pos)
end

local function after_place_injector(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  logistica.set_injector_target_list(pos, "main")
  logistica.on_injector_change(pos)
  logistica.start_injector_timer(pos)
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

-- `simpleName` is used for the description and for the name (can contain spaces)
-- transferRate is how many items per tick this injector can transfer, -1 for unlimited
function logistica.register_injector(description, name, transferRate, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local injectorName = "logistica:injector_"..lname
  logistica.injectors[injectorName] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3 }
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
    after_destruct = logistica.on_injector_change,
    on_punch = on_injector_punch,
    on_rightclick = on_injector_rightclick,
    logistica = {
      injector_transfer_rate = transferRate,
      on_connect_to_network = function(pos, networkId)
        logistica.start_injector_timer(pos)
      end,
      on_power = function(pos, isPoweredOn)
        if isPoweredOn then
          logistica.start_injector_timer(pos)
        end
      end,
    }
  }

  minetest.register_node(injectorName, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_destruct = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(injectorName.."_disabled", def_disabled)

end

local function get_tiles(name) return {
  "logistica_"..name.."_injector_side.png^[transformR270",
  "logistica_"..name.."_injector_side.png^[transformR90",
  "logistica_"..name.."_injector_side.png^[transformR180",
  "logistica_"..name.."_injector_side.png",
  "logistica_"..name.."_injector_back.png",
  "logistica_"..name.."_injector_front.png",
} end

logistica.register_injector("Item Network Inserter\nInserts 1 item per cycle", "item", 1, get_tiles("item"))
logistica.register_injector("Stack Network Inserter\nInserts 1 stack per cycle", "stack", 99, get_tiles("stack"))

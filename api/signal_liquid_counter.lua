
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_liquid_counter"
local ON_OFF_BUTTON = "on_off_btn"
local LIQUID_PREV_BTN = "liquid_prev"
local LIQUID_NEXT_BTN = "liquid_next"

local STR_NO_LIQUID_SELECTED = FS("(no liquid selected)")
local STR_NO_LIQUID = FS("(no liquids on network)")

-- per-player cache of available liquids: list of {name, curr, max}
local liquidsMap = {}

local function refresh_liquids(pos, playerName)
  liquidsMap[playerName] = logistica.get_available_liquids_in_network(pos)
end

-- Find the index of savedName in list, or nil if absent.
local function find_liquid_idx(list, savedName)
  for i, entry in ipairs(list) do
    if entry.name == savedName then return i end
  end
  return nil
end

local function change_liquid(pos, playerName, dir)
  local list = liquidsMap[playerName]
  if not list or #list == 0 then return end
  local saved = minetest.get_meta(pos):get_string("liquid_name")
  local idx = find_liquid_idx(list, saved)
  -- if current selection is absent from the live list, treat position as 0 so
  -- next (+1) lands on 1 and prev (-1) lands on #list
  if not idx then
    idx = (dir > 0) and 0 or (#list + 1)
  end
  idx = idx + dir
  if idx > #list then idx = 1 end
  if idx < 1 then idx = #list end
  minetest.get_meta(pos):set_string("liquid_name", list[idx].name)
  logistica.signal_liquid_counter_reconfigure(pos)
end

local function get_liquid_display(pos, playerName)
  local savedName = minetest.get_meta(pos):get_string("liquid_name")
  if not savedName or savedName == "" then
    return { description = STR_NO_LIQUID_SELECTED, capacity = "", texture = "" }
  end
  -- texture and description come from the global liquid registry, not network state
  local desc = logistica.reservoir_get_description_of_liquid(savedName)
  local tex  = logistica.reservoir_get_texture_of_liquid(savedName)
  if not desc or desc == "" then desc = savedName end
  if not tex  or tex  == "" then tex  = "blank.png" end
  -- capacity only available if the liquid is currently on the network
  local cap = ""
  local list = liquidsMap[playerName]
  if list then
    local idx = find_liquid_idx(list, savedName)
    if idx then
      local e = list[idx]
      cap = tostring(e.curr) .. " / " .. tostring(e.max)
    end
  end
  return { description = desc, capacity = cap, texture = tex }
end

local function get_formspec(pos, playerName)
  local sigName    = logistica.signal_liquid_counter_get_signal_name(pos)
  local threshold  = logistica.signal_liquid_counter_get_threshold(pos)
  local comparison = logistica.signal_liquid_counter_get_comparison(pos)
  local isOn       = logistica.is_machine_on(pos)
  local cmpIdx     = comparison == ">=" and 1 or 2
  local liq        = get_liquid_display(pos, playerName)

  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.6, 6.2).."]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("Liquid Count Sender").."]"..
    -- liquid selector row
    "label[0.5,1.15;"..FS("Liquid:").."]"..
    "image_button[2.0,0.75;0.6,0.8;logistica_icon_prev.png;"..LIQUID_PREV_BTN..";;false;false]"..
    "image[2.7,0.75;0.8,0.8;"..liq.texture.."]"..
    "image_button[3.55,0.75;0.6,0.8;logistica_icon_next.png;"..LIQUID_NEXT_BTN..";;false;false]"..
    "label[4.3,1.05;"..minetest.formspec_escape(liq.description).." "..minetest.formspec_escape(liq.capacity).."]"..
    -- condition row
    "label[0.5,2.15;"..FS("Condition:").."]"..
    "dropdown[2.0,1.8;1.5,0.75;comparison;>=,<=;"..cmpIdx.."]"..
    "label[3.65,2.15;"..FS("buckets:").."]"..
    "field[5.2,1.8;2.1,0.75;threshold;;"..threshold.."]"..
    -- signal name
    "label[0.5,3.05;"..FS("Signal:").."]"..
    "field[2.0,2.7;8.1,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[2.0,3.60;"..FS("Sends signal ON when the liquid condition is met").."]"..
    -- enable + save
    logistica.ui.on_off_btn(isOn, 4.1, 4.5, ON_OFF_BUTTON, FS("Enable"))..
    "button_exit[7.6,4.65;2.5,0.75;save;"..FS("Save").."]"
end

local forms = {}

local function show_formspec(pos, playerName)
  refresh_liquids(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields[LIQUID_PREV_BTN] then
    change_liquid(pos, playerName, -1)
    show_formspec(pos, playerName)
    return true
  elseif fields[LIQUID_NEXT_BTN] then
    change_liquid(pos, playerName, 1)
    show_formspec(pos, playerName)
    return true
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_formspec(pos, playerName)
    return true
  elseif fields.save
      or fields.key_enter_field == "signal_name"
      or fields.key_enter_field == "threshold" then
    local meta = minetest.get_meta(pos)
    if fields.signal_name then
      meta:set_string("signal_name", logistica.sanitize_signal_name(fields.signal_name))
    end
    if fields.threshold then
      local t = math.floor(tonumber(fields.threshold) or 1)
      meta:set_int("threshold", math.max(1, t))
    end
    if fields.comparison == ">=" or fields.comparison == "<=" then
      meta:set_string("comparison", fields.comparison)
    end
    logistica.signal_liquid_counter_reconfigure(pos)
    forms[playerName] = nil
    return true
  elseif fields.quit then
    forms[playerName] = nil
    liquidsMap[playerName] = nil
  end
  return true
end

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then
    local name = objRef:get_player_name()
    forms[name] = nil
    liquidsMap[name] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_signal_liquid_counter(desc, name, tiles_off, tiles_on)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function after_place(pos, placer, _, _)
    logistica.on_signal_sender_change(pos, nil, nil)
    logistica.signal_liquid_counter_update_infotext(pos)
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_liquid_counter_on_connect,
    on_disconnect_from_network = logistica.signal_liquid_counter_on_disconnect,
    on_power                   = logistica.signal_liquid_counter_on_power,
  }

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles_off,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_timer         = logistica.signal_liquid_counter_timer,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def)
  def_on.tiles = tiles_on
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  local def_disabled = table.copy(def)
  local tiles_disabled = logistica.table_map(def.tiles, function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles        = tiles_disabled
  def_disabled.groups       = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.on_construct  = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_timer      = nil
  def_disabled.on_rightclick  = nil

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname,              def)
  minetest.register_node(lname_on,           def_on)
  minetest.register_node(lname.."_disabled", def_disabled)
end

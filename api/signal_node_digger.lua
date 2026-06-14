
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_node_digger"
local FILTER_SIZE   = 8
local MAIN_SIZE     = 16

local forms = {}

local function get_formspec(pos, playerName)
  local posForm   = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local sigName   = logistica.node_digger_get_signal_name(pos)
  local dist      = logistica.node_digger_get_distance(pos)
  local ownerName = logistica.node_digger_get_owner(pos)
  local isOwner   = (playerName == ownerName)
  local invert    = logistica.node_digger_get_invert(pos)
  local lastError = minetest.get_meta(pos):get_string("last_error")
  local statusText
  if lastError == "nothing_to_dig" then
    statusText = minetest.colorize("#FFCC00", FS("Nothing to dig at target position"))
  elseif lastError == "no_match" then
    statusText = minetest.colorize("#FFCC00", FS("Target node does not match filter"))
  elseif lastError == "wrong_tool" then
    statusText = minetest.colorize("#FF8844", FS("Tool cannot dig that node type"))
  elseif lastError ~= "" then
    statusText = minetest.colorize("#FF4444", minetest.formspec_escape(lastError))
  else
    statusText = FS("Dug items stored here; network can take from here")
  end

  local ownerLabel = FS("Owner:") .. " " .. (ownerName ~= "" and ownerName or FS("(none)"))
  local ownerRow = "label[0.5,0.8;" .. ownerLabel .. "]"
  if not isOwner then
    ownerRow = ownerRow ..
      "button[6.5,3.9;2.5,0.55;take_ownership;" .. FS("Take Ownership") .. "]"
  end

  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.6, 16.0).."]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("Node Digger").."]"..
    "label[5.5,0.4;"..FS("Sneak-punch to see target").."]"..
    "label[5.5,0.8;"..FS("Digs node on signal ON (rising edge)").."]"..
    ownerRow..
    "label[0.5,1.3;"..FS("Filter: (dig only these node types, or all if empty)").."]"..
    "list["..posForm..";filter;0.5,1.55;8,1;0]"..
    "label[0.5,2.75;"..FS("Tool:").."]"..
    "list["..posForm..";tool;0.5,3.0;1,1;0]"..
    "label[0.5,4.25;"..FS("Dig distance:").."]"..
    "button[3.0,3.9;0.65,0.65;dist_dec;-]"..
    "label[3.85,4.15;"..tostring(dist).."]"..
    "button[4.2,3.9;0.65,0.65;dist_inc;+]"..
    "label[0.5,5.1;"..FS("Signal Name:").."]"..
    "field[2.8,4.85;7.3,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[2.8,5.7;"..FS("a-z 0-9 _ only").."]"..
    "checkbox[0.5,6.2;invert_signal;"..FS("Not (act on signal OFF instead of ON)")..";"
      ..(invert and "true" or "false").."]"..
    "label[0.5,6.8;"..statusText.."]"..
    "button_exit[7.6,6.95;2.5,0.75;save;"..FS("Save").."]"..
    "label[0.5,7.8;"..FS("Stored items (network can take from here):").."]"..
    "list["..posForm..";main;0.5,8.05;8,2;0]"..
    logistica.player_inv_formspec(0.5, 10.8)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
end

local function reshow_for_pos(pos)
  for playerName, data in pairs(forms) do
    if data.position and vector.equals(data.position, pos) then
      show_formspec(pos, playerName)
    end
  end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.invert_signal ~= nil then
    logistica.node_digger_set_invert(pos, fields.invert_signal == "true")
    return true
  elseif fields.take_ownership then
    logistica.node_digger_set_owner(pos, playerName)
    minetest.get_meta(pos):set_string("last_error", "")
    logistica.node_digger_update_infotext(pos)
    reshow_for_pos(pos)
  elseif fields.save or fields.key_enter_field == "signal_name" then
    if fields.signal_name then
      minetest.get_meta(pos):set_string("signal_name",
        logistica.sanitize_signal_name(fields.signal_name))
    end
    logistica.node_digger_reconfigure(pos)
    forms[playerName] = nil
  elseif fields.dist_inc or fields.dist_dec then
    local delta = fields.dist_inc and 1 or -1
    logistica.node_digger_set_distance(pos, logistica.node_digger_get_distance(pos) + delta)
    logistica.node_digger_reconfigure(pos)
    logistica.node_digger_show_target(pos)
    show_formspec(pos, playerName)
  elseif fields.quit then
    forms[playerName] = nil
  end
  return true
end

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then forms[objRef:get_player_name()] = nil end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_signal_node_digger(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function allow_inv_put(pos, listname, index, stack, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname == "filter" then
      if not minetest.registered_nodes[stack:get_name()] then return 0 end
      local copy = ItemStack(stack:get_name())
      copy:set_count(1)
      minetest.get_meta(pos):get_inventory():set_stack("filter", index, copy)
      minetest.get_meta(pos):set_string("last_error", "")
      logistica.node_digger_reconfigure(pos)
      reshow_for_pos(pos)
      return 0
    elseif listname == "tool" then
      return stack:get_count()
    elseif listname == "main" then
      return stack:get_count()
    end
    return 0
  end

  local function allow_inv_take(pos, listname, index, stack, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname == "filter" then
      minetest.get_meta(pos):get_inventory():set_stack("filter", index, ItemStack(""))
      minetest.get_meta(pos):set_string("last_error", "")
      logistica.node_digger_reconfigure(pos)
      reshow_for_pos(pos)
      return 0
    elseif listname == "tool" then
      return stack:get_count()
    elseif listname == "main" then
      return stack:get_count()
    end
    return 0
  end

  local function on_inv_put(pos, listname, _, _, _)
    if listname == "main" then
      logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
    elseif listname == "tool" then
      minetest.get_meta(pos):set_string("last_error", "")
      logistica.node_digger_reconfigure(pos)
      reshow_for_pos(pos)
    end
  end

  local function on_inv_take(pos, listname, _, _, _)
    if listname == "main" then
      logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
    elseif listname == "tool" then
      minetest.get_meta(pos):set_string("last_error", "")
      logistica.node_digger_reconfigure(pos)
      reshow_for_pos(pos)
    end
  end

  local function allow_inv_move(_, _, _, _, _, _, _) return 0 end

  local function after_place(pos, placer, _, _)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("filter", FILTER_SIZE)
    inv:set_size("tool", 1)
    inv:set_size("main", MAIN_SIZE)
    logistica.node_digger_set_distance(pos, 1)
    if placer and placer:is_player() then
      logistica.node_digger_set_owner(pos, placer:get_player_name())
    end
    logistica.on_signal_receiver_change(pos, nil, nil)
    logistica.on_supplier_change(pos, nil, nil)
    logistica.node_digger_update_infotext(pos)
    logistica.node_digger_show_target(pos)
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
    logistica.on_supplier_change(pos, oldNode, oldMeta)
  end

  local function can_dig(pos, _)
    local inv = minetest.get_meta(pos):get_inventory()
    return inv:is_empty("main") and inv:is_empty("tool")
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local function on_punch(pos, _, player, _)
    if not player or not player:is_player() then return end
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    if player:get_player_control().sneak then
      logistica.node_digger_show_target(pos)
    end
  end

  local function on_rotate(pos, node, player, mode, newParam2)
    logistica.node_digger_show_target(pos, newParam2)
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.node_digger_on_connect,
    on_disconnect_from_network = logistica.node_digger_on_disconnect,
    on_signal_received         = logistica.node_digger_on_signal_received,
    inventory_size             = MAIN_SIZE,
    supplierMayAccept          = false,
  }

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_punch         = on_punch,
    on_rotate        = on_rotate,
    can_dig          = can_dig,
    allow_metadata_inventory_put  = allow_inv_put,
    allow_metadata_inventory_take = allow_inv_take,
    allow_metadata_inventory_move = allow_inv_move,
    on_metadata_inventory_put  = on_inv_put,
    on_metadata_inventory_take = on_inv_take,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_disabled = table.copy(def)
  local tiles_disabled = logistica.table_map(def.tiles,
    function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles         = tiles_disabled
  def_disabled.groups        = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3,
                                  not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.after_dig_node = nil
  def_disabled.on_rightclick  = nil

  logistica.GROUPS.signal_receivers.register(lname)
  logistica.GROUPS.suppliers.register(lname)

  minetest.register_node(lname,              def)
  minetest.register_node(lname.."_disabled", def_disabled)
end

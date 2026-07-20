
local S = logistica.TRANSLATOR

local clipboard = {}

local SKIP_FIELDS = { infotext = true, owner = true, last_error = true, prev_signal_state = true, toggle_state = true, logonoff = true }
local ALLOW_GROUPS = {
  "signal_senders",
  "signal_receivers",
  "signal_gates",
  "signal_togglers",
  "injectors",
  "requesters",
  "crafting_suppliers",
}

-- autocrafters don't join logistica.GROUPS (they don't connect to networks), so they're
-- tagged with this plain minetest group instead, just so this tool can recognize them
local AUTOCRAFTER_GROUP = "logistica_autocrafter"

local function is_autocrafter(nodeName)
  return minetest.get_item_group(nodeName, AUTOCRAFTER_GROUP) == 1
end

local function is_recognized_node(nodeName)
  return logistica.is_machine(nodeName) or is_autocrafter(nodeName)
end

local function is_allowed(nodeName)
  if is_autocrafter(nodeName) then return true end
  for _, g in ipairs(ALLOW_GROUPS) do
    if logistica.GROUPS[g] and logistica.GROUPS[g].is(nodeName) then return true end
  end
  return false
end
local COPY_INV_LISTS = { filter = true, tool = true, crf = true }

local function base_name(nodeName)
  if nodeName:sub(-3) == "_on" then
    return nodeName:sub(1, -4)
  end
  return nodeName
end

local function get_node_desc(nodeName)
  return ItemStack(nodeName):get_short_description() or nodeName
end

local function copy_state(pos, player)
  local playerName = player:get_player_name()
  local node = minetest.get_node_or_nil(pos)
  if not node then return end
  if not is_recognized_node(node.name) then return end
  if not is_allowed(node.name) then
    logistica.show_popup(playerName, S("Cannot copy this node type!"))
    return
  end
  local raw = minetest.get_meta(pos):to_table()
  local fields = {}
  for k, v in pairs(raw.fields) do
    if not SKIP_FIELDS[k] then fields[k] = v end
  end
  local invs = {}
  for listName, items in pairs(raw.inventory or {}) do
    if COPY_INV_LISTS[listName] then invs[listName] = items end
  end
  clipboard[playerName] = {
    node_base = base_name(node.name),
    fields = fields,
    invs = invs,
  }
  minetest.sound_play("on", { to_player = playerName, gain = 0.5, pitch = 0.7 })
  logistica.show_popup(playerName, S("Copied: ")..get_node_desc(node.name))
end

local function paste_state(pos, player)
  local playerName = player:get_player_name()
  if not clipboard[playerName] then
    logistica.show_popup(playerName, S("Nothing copied yet!"))
    return
  end
  local node = minetest.get_node_or_nil(pos)
  if not node then return end
  if not is_recognized_node(node.name) then return end
  if not is_allowed(node.name) then
    logistica.show_popup(playerName, S("Cannot paste to this node type!"))
    return
  end
  if base_name(node.name) ~= clipboard[playerName].node_base then
    logistica.show_popup(playerName, S("Wrong node type - cannot paste"))
    return
  end
  if minetest.is_protected(pos, playerName) then
    logistica.show_popup(playerName, S("Cannot paste: area is protected"))
    return
  end
  local entry = clipboard[playerName]
  local meta = minetest.get_meta(pos)
  for k, v in pairs(entry.fields) do
    meta:set_string(k, v)
  end
  local inv = meta:get_inventory()
  for listName, items in pairs(entry.invs) do
    if inv:get_size(listName) > 0 then
      for i, item in ipairs(items) do
        inv:set_stack(listName, i, ItemStack(item))
      end
    end
  end
  local nodeDef = minetest.registered_nodes[node.name]
  local networkId = logistica.get_network_id_or_nil(pos)
  if nodeDef and nodeDef.logistica and nodeDef.logistica.on_connect_to_network and networkId then
    nodeDef.logistica.on_connect_to_network(pos, networkId)
  end
  if nodeDef and nodeDef.logistica and nodeDef.logistica.on_paste_state then
    nodeDef.logistica.on_paste_state(pos)
  end
  minetest.sound_play("off", { to_player = playerName, gain = 0.5, pitch = 0.7 })
  logistica.show_popup(playerName, S("Pasted to ")..get_node_desc(node.name))
end

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then
    clipboard[objRef:get_player_name()] = nil
  end
end)

minetest.register_tool("logistica:state_copier", {
  description = S("State Copy Tool\nRight-click to copy node state\nPunch to paste"),
  short_description = S("State Copy Tool"),
  inventory_image = "logistica_state_copier.png",
  wield_image = "logistica_state_copier.png",
  stack_max = 1,
  on_secondary_use = function(itemstack, user, _)
    if not user or not user:is_player() then return end
    local playerName = user:get_player_name()
    local entry = clipboard[playerName]
    if entry then
      logistica.show_popup(playerName, S("Clipboard: ")..get_node_desc(entry.node_base))
    else
      logistica.show_popup(playerName, S("Clipboard is empty"))
    end
  end,
  on_place = function(itemstack, placer, pointed_thing)
    if not placer or not placer:is_player() then return end
    if pointed_thing.type ~= "node" then return end
    copy_state(pointed_thing.under, placer)
  end,
  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
    if pointed_thing.type ~= "node" then return end
    paste_state(pointed_thing.under, user)
  end,
})

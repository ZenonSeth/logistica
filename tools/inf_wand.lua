local S = logistica.TRANSLATOR

local function refresh_infotext(nodeName, pos, isInfinite)
  if logistica.GROUPS.mass_storage.is(nodeName) then
    logistica.update_mass_storage_infotext(pos)
  elseif logistica.GROUPS.suppliers.is(nodeName) then
    logistica.set_node_tooltip_from_state(pos, isInfinite and S("INFINITE") or nil)
  elseif logistica.GROUPS.reservoirs.is(nodeName) then
    local meta = minetest.get_meta(pos)
    local nodeDef = minetest.registered_nodes[nodeName]
    local liquidLevel = meta:get_int("liquidLevel")
    local liquidDesc = logistica.reservoir_get_description_of_liquid(nodeDef.logistica.liquidName)
    meta:set_string("infotext", logistica.reservoir_get_description(liquidLevel, nodeDef.logistica.maxBuckets, liquidDesc, isInfinite))
  end
end

local function is_eligible(nodeName)
  if logistica.GROUPS.mass_storage.is(nodeName) then return true end
  if logistica.GROUPS.suppliers.is(nodeName) then return logistica.is_passive_supplier_node(nodeName) end
  if logistica.GROUPS.reservoirs.is(nodeName) then return true end
  return false
end

local function toggle_infinite(pos, player)
  local playerName = player:get_player_name()
  local node = minetest.get_node_or_nil(pos)
  if not node then return end
  if not is_eligible(node.name) then
    logistica.show_popup(playerName, S("Cannot toggle infinite on this node type!"))
    return
  end
  if minetest.is_protected(pos, playerName) then
    logistica.show_popup(playerName, S("Cannot toggle infinite: area is protected"))
    return
  end
  local isInfinite = logistica.toggle_pos_infinite(pos)
  refresh_infotext(node.name, pos, isInfinite)
  minetest.sound_play(isInfinite and "on" or "off", { to_player = playerName, gain = 0.5, pitch = 0.7 })
  logistica.show_popup(playerName, isInfinite and S("Infinite: ON") or S("Infinite: OFF"))
end

minetest.register_tool("logistica:inf_wand", {
  description = S("Infinite Wand\nRight-click a mass storage, passive supplier,\nor reservoir to toggle infinite supply"),
  short_description = S("Infinite Wand"),
  inventory_image = "logistica_inf_wand.png",
  wield_image = "logistica_inf_wand.png",
  stack_max = 1,
  groups = { not_in_creative_inventory = 1 },
  on_place = function(itemstack, placer, pointed_thing)
    if not placer or not placer:is_player() then return end
    if pointed_thing.type ~= "node" then return end
    toggle_infinite(pointed_thing.under, placer)
  end,
})

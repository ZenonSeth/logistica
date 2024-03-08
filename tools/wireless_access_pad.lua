local S = logistica.TRANSLATOR

local META_ACCESS_POINT_POSITION = "logacptps"
local META_RANGE = "log_range"

local STR_INIT_TIP = S("Use in a Wireless Upgrader to initialize")

logistica.tools.wap = {
  meta_range_key = META_RANGE,
  description_default = S("Wireless Access Pad").."\n"..STR_INIT_TIP,
  get_description_with_range = function (range, isMax)
    return S("Wireless Access Pad\nSneak+Punch an Access Point to Sync\nRange: @1", range)
  end
}

-- we need this because default tostring(number) function returns scientific representation which loses accuracy
local str = function(anInt) return string.format("%.0f", anInt) end

local function on_wireless_pad_primary(itemstack, user, pointed_thing)
  local pos = pointed_thing.under
  if not pos or not user or not user:is_player() or not user:get_player_control().sneak then return end

  local node = minetest.get_node(pos)
  if minetest.get_item_group(node.name, logistica.TIER_ACCESS_POINT) <= 0 then return end

  local playerName = user:get_player_name()
  local itemMeta = itemstack:get_meta()
  local range = itemMeta:get_int(META_RANGE)

  if range <= 0 then
    logistica.show_popup(
      playerName,
      S("This Wireless Access Pad is not initialized").."\n"..STR_INIT_TIP
    )
    return
  end

  if minetest.is_protected(pos, playerName) then
    logistica.show_popup(playerName, S("This Access Point is in a protected area!"))
    return
  end

  local posHashStr = str(minetest.hash_node_position(pos))
  itemMeta:set_string(META_ACCESS_POINT_POSITION, posHashStr)

  logistica.show_popup(playerName, S("Synced to Access Point at").." ("..pos.x..","..pos.y..","..pos.z..")")

  return itemstack
end

local function on_wireless_pad_secondary(itemstack, placer, pointed_thing)
  if not placer or not placer:is_player() then return end

  local playerName = placer:get_player_name()
  local itemMeta = itemstack:get_meta()
  local posHashStr = itemMeta:get_string(META_ACCESS_POINT_POSITION)

  local range = itemMeta:get_int(META_RANGE)
  if range <= 0 then
    logistica.show_popup(
      playerName,
      S("This Wireless Access Pad is not initialized").."\n"..STR_INIT_TIP
    )
    return
  end

  if posHashStr == "" then
    logistica.show_popup(playerName, S("This WAP is not synced to any Access Point."))
    return
  end

  local targetPos = minetest.get_position_from_hash(tonumber(posHashStr))

  local dist = vector.length(vector.subtract(placer:get_pos(), targetPos))
  if not dist or dist > range then
    logistica.show_popup(playerName, S("The synced Access Point is too far away!"))
    return
  end

  logistica.load_position(targetPos)
  logistica.try_to_wake_up_network(targetPos)

  local node = minetest.get_node(targetPos)

  if minetest.get_item_group(node.name, logistica.TIER_ACCESS_POINT) <= 0 then
    logistica.show_popup(playerName, S("The synced Access Point no longer exists!"))
    return
  end

  if minetest.is_protected(targetPos, playerName) then
    logistica.show_popup(playerName, S("The synced Access Point is in a protected area! How did you manage that?"))
    return
  end

  local nodeDef = minetest.registered_nodes[node.name]
  nodeDef.on_rightclick(targetPos, node, placer, itemstack, pointed_thing)

  -- logistica.access_point_on_rightclick(targetPos, node, placer, itemstack, pointed_thing)
end

-- registration

-- minetest.register_on_leaveplayer(function(objRef, timed_out)
--   if objRef:is_player() then
--     forms[objRef:get_player_name()] = nil
--   end
-- end)

minetest.register_tool("logistica:wireless_access_pad",{
  description = logistica.tools.wap.description_default,
  inventory_image = "logistica_wap.png",
  wield_image = "logistica_wap.png",
  stack_max = 1,
  on_use = on_wireless_pad_primary,
  on_secondary_use = on_wireless_pad_secondary,
  on_place = on_wireless_pad_secondary,
})

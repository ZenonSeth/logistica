local S = logistica.TRANSLATOR

local META_ACCESS_POINT_POSITION = "logacptps"
local WAP_MAX_DIST_DEF = 200 -- in nodes

-- we need this because default tostring(number) function returns scientific representation which loses accuracy
local str = function(anInt) return string.format("%.0f", anInt) end

-- local forms = {}

local function on_wireless_pad_primary(itemstack, user, pointed_thing)
  local pos = pointed_thing.under
  if not pos or not user or not user:is_player() or not user:get_player_control().sneak then return end

  local node = minetest.get_node(pos)
  if minetest.get_item_group(node.name, logistica.TIER_ACCESS_POINT) <= 0 then return end

  local playerName = user:get_player_name()
  if minetest.is_protected(pos, playerName) then
    logistica.show_popup(playerName, S("This Access Point is in a protected area!"))
    return
  end

  local itemMeta = itemstack:get_meta()
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

  if posHashStr == "" then
    logistica.show_popup(playerName, S("This WAP is not synced to any Access Point."))
    return
  end

  local targetPos = minetest.get_position_from_hash(tonumber(posHashStr))
  logistica.load_position(targetPos)
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

minetest.register_craftitem("logistica:wireless_access_pad",{
  description = S("Wireless Access Pad\nSneak+Punch an Access Point to Sync"),
  inventory_image = "logistica_wap.png",
  wield_image = "logistica_wap.png",
  stack_max = 1,
  on_use = on_wireless_pad_primary,
  on_secondary_use = on_wireless_pad_secondary,
})

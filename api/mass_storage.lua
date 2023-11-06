
local META_SERIALIZED_INV = "logistica:ser_inv"
local META_ITEM_NAME = "logistica:item_name"

local function get_mass_storage_upgrade_inv(posForm, numUpgradeSlots)
  if numUpgradeSlots <= 0 then return "" end
  local upIconX = 1.5 + 1.25 * (7 - numUpgradeSlots) -- sort of hardcoded
  local upInvX = upIconX + 1.25
  local y = 3.5
  return "image["..upIconX..","..y..";1,1;logistica_icon_upgrade.png]" ..
         "list["..posForm..";upgrade;"..upInvX..","..y..";"..numUpgradeSlots..",1;0]"
end

-- formspec

local function get_mass_storage_formspec(pos, numUpgradeSlots)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local upgradeInvString = get_mass_storage_upgrade_inv(posForm, numUpgradeSlots)
  return "formspec_version[4]"..
    "size[12,10.5]" ..
    logistica.ui.background..
    "list[current_player;main;1.5,5;8,4;0]" ..
    "list["..posForm..";storage;1.5,2.1;8,1;0]" ..
    "list["..posForm..";filter;1.5,1;8,1;0]" ..
    "image[0.25,1;1,1;logistica_icon_filter.png]" ..
    "list["..posForm..";main;1.5,3.5;1,1;0]" ..
    "image[0.25,2.1;1,1;logistica_icon_mass_storage.png]" ..
    "image[0.25,3.5;1,1;logistica_icon_input.png]"..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"..
    "listring["..posForm..";storage]"..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"..
    "listring[current_player;main]"..
    upgradeInvString
end

-- callbacks

local function after_place_mass_storage(pos, placer, itemstack, numSlots, numUpgradeSlots)
	local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
	  meta:set_string("owner", placer:get_player_name())
  end
	local inv = meta:get_inventory()
	inv:set_size("main", 1)
	inv:set_size("filter", numSlots)
	inv:set_size("storage", numSlots)
	inv:set_size("upgrade", numUpgradeSlots)
  -- and connect to network
  logistica.on_storage_change(pos)
  -- restore inventory, if any
  local itemstackMetaInv = itemstack:get_meta():get_string(META_SERIALIZED_INV)
  if itemstackMetaInv then
    local listsTable = logistica.deserialize_inv(itemstackMetaInv)
    for name, listTable in pairs(listsTable) do
      inv:set_list(name, listTable)
    end
  end
end

local function on_mass_storage_preserve_metadata(pos, oldnode, oldmeta, drops)
  local drop = drops[1]
  local meta = minetest.get_meta(pos)
  if not drop or not meta then return end
  local inv = meta:get_inventory()
  local serialized = logistica.serialize_inv(inv)
  drop:get_meta():set_string(META_SERIALIZED_INV, serialized)
  -- update description
  local name = minetest.registered_nodes[oldnode.name].logistica.baseName
  if inv:is_empty("storage") then
    name = name.."\n(Empty)"
  else
    name = name.."\n(Contains items)" -- TODO set a node name or use a stackname
  end
  drop:get_meta():set_string("description", name)
end

local function allow_mass_storage_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player) then return 0 end
  if listname == "storage" then
    return logistica.clamp(stack:get_count(), 0, stack:get_stack_max())
  end
  if listname == "main" then return stack:get_count() end
  if listname == "filter" then
			local inv = minetest.get_meta(pos):get_inventory()
      if not inv:get_stack("storage", index):is_empty() then return 0 end
			local storageStack = inv:get_stack("filter", index)
			storageStack:clear()
			inv:set_stack("filter", index, storageStack)
      logistica.updateStorageCacheFromPosition(pos)
      return 0
  end
  return stack:get_count()
end

local function allow_mass_storage_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player) then return 0 end
  if from_list == "main" and to_list == "main" then return count end
  if from_list == "upgrade" and to_list == "upgrade" then return count end
  return 0
end

local function allow_mass_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player) then return 0 end
  if listname == "storage" then return 0 end
  if listname == "main" then
    return logistica.try_to_add_item_to_storage(pos, stack, true)
  end
  if listname == "filter" then
    if stack:get_stack_max() == 1 then return 0 end
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    local inv = minetest.get_meta(pos):get_inventory()
    inv:set_stack("filter", index, copyStack)
    logistica.updateStorageCacheFromPosition(pos)
    return 0
  end
  return stack:get_count()
end


local function on_mass_storage_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player) then return 0 end

end

local function on_mass_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player) then return 0 end
  if listname == "main" then
    local taken = logistica.try_to_add_item_to_storage(pos, stack)
    if taken > 0 then
      local inv = minetest.get_meta(pos):get_inventory()
      local fullstack = inv:get_stack(listname, index)
      if taken == fullstack:get_count() then
        fullstack:clear()
      else
        fullstack:set_count(fullstack:get_count() - taken)
      end
      inv:set_stack(listname, index, fullstack)
    end
  end
end

local function on_mass_storage_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player) then return 0 end

end

local function on_mass_storage_right_click(pos, node, clicker, itemstack, pointed_thing)
  local numUpgradeSlots = minetest.registered_nodes[node.name].logistica.numUpgradeSlots
  minetest.show_formspec(
    clicker:get_player_name(),
    "mass_storage_formspec",
    get_mass_storage_formspec(pos, numUpgradeSlots)
  )
end

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_mass_storage(simpleName, numSlots, numItemsPerSlot, numUpgradeSlots)
  local lname = string.lower(string.gsub(simpleName, " ", "_"))
  local storageName = "logistica:mass_storage_"..lname
  local grps = {cracky = 1, choppy = 1, oddly_breakable_by_hand = 1}
  numUpgradeSlots = logistica.clamp(numUpgradeSlots, 0, 4)
  grps[logistica.TIER_ALL] = 1
  logistica.mass_storage[storageName] = true

  local def = {
    description = simpleName.." Mass Storage\n(Empty)",
    tiles = { "logistica_"..lname.."_mass_storage.png" },
    groups = grps,
    sounds = logistica.node_sound_metallic(),
    after_place_node = function(pos, placer, itemstack)
      after_place_mass_storage(pos, placer, itemstack, numSlots, numUpgradeSlots)
    end,
    after_destruct = logistica.on_storage_change,
    drop = storageName,
    logistica = {
      baseName = simpleName.." Mass Storage",
      maxItems = numItemsPerSlot,
      numSlots = numSlots,
      numUpgradeSlots = numUpgradeSlots,
    },
    allow_metadata_inventory_put = allow_mass_storage_inv_put,
    allow_metadata_inventory_take = allow_mass_storage_inv_take,
    allow_metadata_inventory_move = allow_mass_storage_inv_move,
    on_metadata_inventory_put = on_mass_storage_inv_put,
    on_metadata_inventory_take = on_mass_storage_inv_take,
    on_metadata_inventory_move = on_mass_storage_inv_move,
    on_rightclick = on_mass_storage_right_click,
    preserve_metadata = on_mass_storage_preserve_metadata,
    stack_max = 1,
  }

  minetest.register_node(storageName, def)

  local def_disabled = {}
	for k, v in pairs(def) do def_disabled[k] = v end
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1 }

	minetest.register_node(storageName.."_disabled", def_disabled)

end

logistica.register_mass_storage("Basic", 8, 512, 4)

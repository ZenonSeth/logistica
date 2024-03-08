
local S = logistica.TRANSLATOR

local META_SERIALIZED_INV = "logserlist"
local META_IMG_INDEX = "logimginxd"
local META_SELECTED_RES = "logselres"

local FORMSPEC_NAME = "mass_storage_formspec"
local ON_OFF_BTN = "on_off_btn"

local MASS_STORAGE_TIMER = 1

local storageForms = {}

local RESERVE_TOOLTIP = S("How many items to reserve.\nReserved items won't be taken by other network machines")
local IMAGE_TOOLTIP = S("Pick which slot to use as front image.\nClick the selected slot again to disable the front image.")
local FILTER_TOOLTIP = S("Place item to select what kind of item to store in each slot.")
local UPGRADE_TOOLTIP = S("Upgrade slots: The 4 slots to the right are for placing mass storage upgrades.")
local STORAGE_TOOLTIP = S("Storage slots: items can be taken from them. To add items, put them in the input slot below.")
local INPUT_TOOLTIP = S("Input slot: Place items here (or shift+click items to send them here) to put them in storage")
local PULL_TOOLTIP = S("If ON, this mass storage will try to take items from connected suppliers, if it can store them.")

local function get_sel_index(vals, selectedValue)
  for i, v in ipairs(vals) do if v == selectedValue then return i end end
  return 0
end

local function upgrade_inv(posForm, numUpgradeSlots, y)
  if numUpgradeSlots <= 0 then return "" end
  local upIconX = 1.5 + 1.25 * (7 - numUpgradeSlots) -- sort of hardcoded
  local upInvX = upIconX + 1.25
  return "image["..upIconX..","..y..";1,1;logistica_icon_upgrade.png]" ..
         "list["..posForm..";upgrade;"..upInvX..","..y..";"..numUpgradeSlots..",1;0]"
end

local function image_picker(initialX, y, index, selectedImgIndex, meta)
  local x = initialX + (index - 1)*1.25
  local itemName = ""
  if selectedImgIndex == index then
    itemName = meta:get_inventory():get_stack("filter", index):get_name()
  end
  return "item_image_button["..x..","..y..";0.7,0.7;"..itemName..";ico"..index..";]"
end

local function reserve_dropdown(x, y, index, vals, valsAsStr, selectedValue)
  local selectedIndex = get_sel_index(vals, selectedValue)
  return "dropdown["..x..","..y..";1.2,0.6;res"..index..";"..valsAsStr..";"..selectedIndex..";false]"
end

local get_sr = logistica.get_mass_storage_reserve

local function get_reserve_as_string(name, meta)
  local numSlots = minetest.registered_nodes[name].logistica.numSlots
  local ret = ""
  for i = 1, numSlots do
    if i == 1 then ret = logistica.get_mass_storage_reserve(meta, i)
    else ret = ret..","..logistica.get_mass_storage_reserve(meta, i) end
  end
  return ret
end

local function get_reserve_from_string(name, str)
  local vals = string.split(str, ",", false)
  local numSlots = minetest.registered_nodes[name].logistica.numSlots
  local ret = {}
  for i = 1, numSlots do
    ret[i] = vals[i] ~= nil and tonumber(vals[i]) or 0
  end
  return ret
end

----------------------------------------------------------------
-- formspec
----------------------------------------------------------------

local function formspec_get_image_pickers(imgPickX, imgPickY, selectedImgIndex, meta)
  return
    image_picker(imgPickX, imgPickY, 1, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 2, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 3, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 4, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 5, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 6, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 7, selectedImgIndex, meta)..
    image_picker(imgPickX, imgPickY, 8, selectedImgIndex, meta)..
    "label[0.2,0.4;Front Img]"
end

local function formspec_get_reserve_dropdowns(vals, valsAsStr, meta)
  return
    reserve_dropdown( 1.40, 3, 1, vals, valsAsStr, get_sr(meta, 1))..
    reserve_dropdown( 2.65, 3, 2, vals, valsAsStr, get_sr(meta, 2))..
    reserve_dropdown( 3.90, 3, 3, vals, valsAsStr, get_sr(meta, 3))..
    reserve_dropdown( 5.15, 3, 4, vals, valsAsStr, get_sr(meta, 4))..
    reserve_dropdown( 6.40, 3, 5, vals, valsAsStr, get_sr(meta, 5))..
    reserve_dropdown( 7.65, 3, 6, vals, valsAsStr, get_sr(meta, 6))..
    reserve_dropdown( 8.90, 3, 7, vals, valsAsStr, get_sr(meta, 7))..
    reserve_dropdown(10.15, 3, 8, vals, valsAsStr, get_sr(meta, 8))..
    "label[0.2,3.3;Res (?)]"
end

-- `meta` is optional
local function get_mass_storage_formspec(pos, numUpgradeSlots, optionalMeta)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local upgradeInvString = upgrade_inv(posForm, numUpgradeSlots, 3.8)
  local isOn = logistica.is_machine_on(pos)
  local meta = optionalMeta or minetest.get_meta(pos)
  local selectedImgIndex = logistica.get_mass_storage_image_slot(meta)
  local vals = logistica.get_mass_storage_valid_reserve_list(pos)
  local valsAsStr = table.concat(vals, ",")
  local imgPickX = 1.65
  local imgPickY = 0.1
  return "formspec_version[4]"..
    "size["..logistica.inv_size(12, 10.75).."]" ..
    logistica.ui.background..
    logistica.inventory_formspec(1.5,5)..
    "list["..posForm..";storage;1.5,1.9;8,1;0]" ..
    "list["..posForm..";filter;1.5,0.8;8,1;0]" ..
    "image[0.25,0.8;1,1;logistica_icon_filter.png]" ..
    "list["..posForm..";main;1.5,3.8;1,1;0]" ..
    "image[0.25,1.9;1,1;logistica_icon_mass_storage.png]" ..
    "image[0.2,3.8;1,1;logistica_icon_input.png]" ..
    formspec_get_image_pickers(imgPickX, imgPickY, selectedImgIndex, meta)..
    formspec_get_reserve_dropdowns(vals, valsAsStr, meta)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"..
    "listring["..posForm..";storage]"..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"..
    "listring[current_player;main]"..
    logistica.ui.on_off_btn(isOn, 3.4, 4.0, ON_OFF_BTN, S("Pull Items"))..
    upgradeInvString..
    "tooltip[3.4,4.0;1,1;"..PULL_TOOLTIP.."]"..
    "tooltip[0.25,1.9;1,1;"..STORAGE_TOOLTIP.."]"..
    "tooltip[0.2,3.8;1,1;"..INPUT_TOOLTIP.."]"..
    "tooltip[0.25,0.8;1,1;"..FILTER_TOOLTIP.."]"..
    "tooltip["..tostring(1.5 + 1.25 * (7 - numUpgradeSlots))..",3.8;1,1;"..UPGRADE_TOOLTIP.."]"..
    "tooltip[0.2,3.0;1,0.5;"..RESERVE_TOOLTIP.."]"..
    "tooltip[0.2,0.1;1,0.5;"..IMAGE_TOOLTIP.."]"
end

local function show_mass_storage_formspec(pos, name, meta)
  local node = minetest.get_node(pos)
  local numUpgradeSlots = minetest.registered_nodes[node.name].logistica.numUpgradeSlots
  storageForms[name] = { position = pos }
  minetest.show_formspec(
    name,
    FORMSPEC_NAME,
    get_mass_storage_formspec(pos, numUpgradeSlots, meta)
  )
end

----------------------------------------------------------------
-- callbacks
----------------------------------------------------------------

local function on_receive_storage_formspec(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  local pos = storageForms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit and not fields.key_enter_field then
    logistica.update_mass_storage_front_image(pos)
    storageForms[playerName] = nil
  elseif fields[ON_OFF_BTN] then
    if logistica.toggle_machine_on_off(pos) then
      logistica.start_node_timer(pos, MASS_STORAGE_TIMER)
    end
    show_mass_storage_formspec(pos, playerName)
  else
    for i = 1, 8 do
      if fields["ico"..i] then
        logistica.on_mass_storage_image_select_change(pos, i)
        show_mass_storage_formspec(pos, playerName)
        return
      end
    end
    for i = 1, 8 do
      if fields["res"..i] then
        logistica.on_mass_storage_reserve_changed(pos, i, fields["res"..i])
        show_mass_storage_formspec(pos, playerName)
        return
      end
    end
    return true
  end
  return true
end

local function after_place_mass_storage(pos, placer, itemstack, numSlots, numUpgradeSlots)
  local meta = minetest.get_meta(pos)
  if placer and placer:is_player() then
    meta:set_string("owner", placer:get_player_name())
  end
  meta:set_string("infotext", S("Mass Storage"))
  local nodeName = minetest.get_node(pos).name
  local inv = meta:get_inventory()
  inv:set_size("main", 1)
  inv:set_size("filter", numSlots)
  inv:set_size("storage", numSlots)
  inv:set_size("upgrade", numUpgradeSlots)
  -- restore inventory, if any
  local itemMeta = itemstack:get_meta()
  local itemstackMetaInv = itemMeta:get_string(META_SERIALIZED_INV)
  if itemstackMetaInv then
    local listsTable = logistica.deserialize_inv(itemstackMetaInv)
    for name, listTable in pairs(listsTable) do
      inv:set_list(name, listTable)
    end
  end
  local selImgIndex = itemMeta:get_int(META_IMG_INDEX)
  local reserves = get_reserve_from_string(nodeName, itemMeta:get_string(META_SELECTED_RES))

  logistica.set_mass_storage_image_slot(meta, selImgIndex)
  for i, v in ipairs(reserves) do logistica.set_mass_storage_reserve(meta, i, v) end
  logistica.update_mass_storage_front_image(pos)
  logistica.update_mass_storage_cap(pos, meta)
  logistica.on_mass_storage_change(pos)
end

local function after_mass_storage_destruct(pos, oldNode, oldmeta)
  logistica.remove_item_on_block_front(pos)
  logistica.on_mass_storage_change(pos, oldNode, oldmeta)
end

local function on_mass_storage_preserve_metadata(pos, oldnode, oldmeta, drops)
  local drop = drops[1]
  local meta = minetest.get_meta(pos)
  if not drop or not meta then return end
  local inv = meta:get_inventory()
  local serialized = logistica.serialize_inv(inv)
  local dropMeta = drop:get_meta()
  dropMeta:set_string(META_SERIALIZED_INV, serialized)
  dropMeta:set_int(META_IMG_INDEX, logistica.get_mass_storage_image_slot(meta))
  dropMeta:set_string(META_SELECTED_RES, get_reserve_as_string(oldnode.name, meta))
  -- update description
  local name = minetest.registered_nodes[oldnode.name].logistica.baseName
  name = name..logistica.get_mass_storage_imgname_or_first_item(meta)
 -- TODO set a node name or use a stackname
  drop:get_meta():set_string("description", name)
end

local function allow_mass_storage_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
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
      logistica.update_cache_at_pos(pos, LOG_CACHE_MASS_STORAGE)
      return 0
  end
  if listname == "upgrade" then
    if logistica.can_remove_mass_storage_upgrade(pos, stack:get_name()) then
      return 1
    else
      return 0
    end
  end
  return stack:get_count()
end

local function allow_mass_storage_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

local function allow_mass_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == "storage" then return 0 end
  if listname == "main" then
    local inv = minetest.get_meta(pos):get_inventory()
    local remain = logistica.insert_item_into_mass_storage(pos, inv, stack, true)
    return stack:get_count() - remain:get_count()
  end
  if listname == "filter" then
    if stack:get_stack_max() == 1 then return 0 end
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    local inv = minetest.get_meta(pos):get_inventory()
    inv:set_stack("filter", index, copyStack)
    logistica.update_cache_at_pos(pos, LOG_CACHE_MASS_STORAGE)
    return 0
  end
  if listname == "upgrade" then
    local inv = minetest.get_meta(pos):get_inventory()
    if not logistica.is_valid_storage_upgrade(stack:get_name()) then return 0 end
    if inv:get_stack(listname, index):is_empty() then return 1 end
    return 0
  end
  return stack:get_count()
end


local function on_mass_storage_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return 0
end

local function on_mass_storage_inv_put(pos, listname, index, stack, player)
  if listname == "main" then
    local inv = minetest.get_meta(pos):get_inventory()
    local remainingStack = logistica.insert_item_into_mass_storage(pos, inv, stack)
    local taken = stack:get_count() - remainingStack:get_count()
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
  elseif listname == "upgrade" then
    local inv = minetest.get_meta(pos):get_inventory()
    logistica.on_mass_storage_upgrade_change(pos, inv:get_stack(listname, index):get_name(), true)
  end
end

local function on_mass_storage_inv_take(pos, listname, index, stack, player)
  if listname == "upgrade" then
    logistica.on_mass_storage_upgrade_change(pos, stack:get_name(), false)
  end
end

local function on_mass_storage_punch(pos, node, puncher, pointed_thing)
  if not puncher and not puncher:is_player() then return end
  if minetest.is_protected(pos, puncher:get_player_name()) then return end
  logistica.try_to_add_player_wield_item_to_mass_storage(pos, puncher)
end

local function on_mass_storage_right_click(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_mass_storage_formspec(pos, clicker:get_player_name())
end

local function on_mass_storage_rotate(pos, node, player, mode, newParam2)
  logistica.update_mass_storage_front_image(pos, newParam2)
end

----------------------------------------------------------------
-- register
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_receive_storage_formspec)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    storageForms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_mass_storage(simpleName, description, numSlots, numItemsPerSlot, numUpgradeSlots, tiles)
  local lname = string.lower(string.gsub(simpleName, " ", "_"))
  local storageName = "logistica:"..lname
  local grps = {cracky = 1, choppy = 1, oddly_breakable_by_hand = 1, pickaxey = 3, axey = 3, handy = 1}
  numUpgradeSlots = logistica.clamp(numUpgradeSlots, 0, 4)
  grps[logistica.TIER_ALL] = 1
  logistica.mass_storage[storageName] = true

  local def = {
    description = description.."\n(Empty)",
    tiles = tiles,
    groups = grps,
    sounds = logistica.node_sound_metallic(),
    after_place_node = function(pos, placer, itemstack)
      after_place_mass_storage(pos, placer, itemstack, numSlots, numUpgradeSlots)
    end,
    after_dig_node = after_mass_storage_destruct,
    drop = storageName,
    on_timer = logistica.on_timer_powered(logistica.on_mass_storage_timer),
    paramtype2 = "facedir",
    logistica = {
      baseName = description,
      maxItems = numItemsPerSlot,
      numSlots = numSlots,
      numUpgradeSlots = numUpgradeSlots,
      on_power = function(pos, isPoweredOn)
        if isPoweredOn then logistica.start_mass_storage_timer(pos) end
      end,
      on_connect_to_network = function(pos, networkId)
        logistica.start_mass_storage_timer(pos)
      end
    },
    connect_sides = {"top", "bottom", "left", "back", "right" },
    allow_metadata_inventory_put = allow_mass_storage_inv_put,
    allow_metadata_inventory_take = allow_mass_storage_inv_take,
    allow_metadata_inventory_move = allow_mass_storage_inv_move,
    on_metadata_inventory_put = on_mass_storage_inv_put,
    on_metadata_inventory_take = on_mass_storage_inv_take,
    on_metadata_inventory_move = on_mass_storage_inv_move,
    on_punch = on_mass_storage_punch,
    on_rightclick = on_mass_storage_right_click,
    on_rotate = on_mass_storage_rotate,
    preserve_metadata = on_mass_storage_preserve_metadata,
    stack_max = 1,
    _mcl_hardness = 10,
    _mcl_blast_resistance = 100
  }

  minetest.register_node(storageName, def)

  local def_disabled = {}
  for k, v in pairs(def) do def_disabled[k] = v end
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1, pickaxey = 1, axey = 1, handy = 1 }
  def_disabled.after_dig_node = function(pos, _) logistica.remove_item_on_block_front(pos) end

  minetest.register_node(storageName.."_disabled", def_disabled)

end

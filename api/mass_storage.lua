local S = logistica.TRANSLATOR
local FS = logistica.FTRANSLATOR

local META_SERIALIZED_INV = "logserlist"
local META_IMG_INDEX = "logimginxd"
local META_SELECTED_RES = "logselres"
local META_SERIALIZED_DEMAND = "logdemandser"

local FORMSPEC_NAME = "mass_storage_formspec"
local SWAP_FORMSPEC_NAME = "mass_storage_swap_formspec"
local SLOT_CONFIG_FORMSPEC_NAME = "mass_storage_slot_config"
local CLOSE_SWAP_BTN = "close_swap_btn"

local MASS_STORAGE_TIMER = 1

local storageForms = {}
local swapForms = {}
local slotConfigForms = {}

local IMAGE_TOOLTIP = FS("Pick which slot to use as front image.\nClick the selected slot again to disable the front image.")
local FILTER_TOOLTIP = FS("Place item to select what kind of item to store in each slot.")
local UPGRADE_TOOLTIP = FS("Upgrade slots: The 4 slots to the right are for placing mass storage upgrades.")
local STORAGE_TOOLTIP = FS("Storage slots: items can be taken from them. To add items, put them in the input slot below.")
local INPUT_TOOLTIP = FS("Input slot: Place items here (or shift+click items to send them here) to put them in storage")
local CFG_TOOLTIP = FS("Configure reserve and demand for this slot")

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

local SWAP_BTN_TOOLTIP = FS("Swap")

local function upgrade_swap_buttons(pos, numUpgradeSlots, upgradeY)
  if numUpgradeSlots <= 0 then return "" end
  local upIconX = 1.5 + 1.25 * (7 - numUpgradeSlots)
  local upInvX = upIconX + 1.25
  local buttonY = upgradeY + 1.1
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:get_size("upgrade") == 0 then return "" end
  local result = ""
  for i = 1, numUpgradeSlots do
    if not inv:get_stack("upgrade", i):is_empty() then
      local bx = upInvX + (i - 1) * 1.25 + 0.25
      local btnName = "swap_upg_"..i
      result = result..
        "image_button["..bx..","..buttonY..";0.5,0.5;logistica_icon_swap.png;"..btnName..";]"..
        "tooltip["..btnName..";"..SWAP_BTN_TOOLTIP.."]"
    end
  end
  return result
end

local function image_picker(initialX, y, index, selectedImgIndex, meta)
  local x = initialX + (index - 1)*1.25
  local itemName = ""
  if selectedImgIndex == index then
    itemName = meta:get_inventory():get_stack("filter", index):get_name()
  end
  return "item_image_button["..x..","..y..";0.7,0.7;"..itemName..";ico"..index..";]"
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
-- swap helpers
----------------------------------------------------------------

local function ensure_upgrade_swap_slot(inv)
  if inv:get_size("upgrade_swap") == 0 then
    inv:set_size("upgrade_swap", 1)
  end
end

local function clear_upgrade_swap_slot_and_return(pos, player)
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:get_size("upgrade_swap") == 0 then return end
  local swapStack = inv:get_stack("upgrade_swap", 1)
  if swapStack:is_empty() then return end
  local leftover = player:get_inventory():add_item("main", swapStack)
  if not leftover:is_empty() then minetest.add_item(player:get_pos(), leftover) end
  inv:set_stack("upgrade_swap", 1, ItemStack(""))
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
    "label[0.2,0.4;"..FS("Front Img").."]"
end

local CFG_BTN_Y   = 3.0
local CFG_BTN_W   = 0.6
local CFG_BTN_H   = 0.6
local CFG_BTN_OFF = (1.25 - CFG_BTN_W) / 2  -- center in slot width

local function formspec_get_cfg_buttons()
  local result = ""
  for i = 1, 8 do
    local bx = 1.4 + (i - 1) * 1.25 + CFG_BTN_OFF
    local btnName = "cfg_slot_"..i
    result = result..
      "image_button["..bx..","..CFG_BTN_Y..";"..CFG_BTN_W..","..CFG_BTN_H..
      ";logistica_icon_swap.png^[transformR90;"..btnName..";]"..
      "tooltip["..btnName..";"..CFG_TOOLTIP.."]"
  end
  return result
end

local SLOT_X      = 1.36
local SLOT_W      = 1.25
local SLOT_Y      = 1.9
local SLOT_H      = 1.0
local BAR_W       = 0.1
local BAR_COLOR   = "#229922"
local BAR_BG      = "#000000"

local function formspec_get_fill_bars(pos, meta)
  local maxSize = logistica.get_mass_storage_max_size(pos)
  if not maxSize or maxSize <= 0 then return "" end
  local inv = meta:get_inventory()
  local result = ""
  for i = 1, 8 do
    local bx   = SLOT_X + (i - 1) * SLOT_W + SLOT_W - BAR_W - 0.01
    local count = inv:get_stack("storage", i):get_count()
    local fill  = math.min(count / maxSize, 1.0)
    local fillH = fill * SLOT_H
    result = result .. "box[" .. bx .. "," .. SLOT_Y .. ";" .. BAR_W .. "," .. SLOT_H .. ";" .. BAR_BG .. "]"
    if fillH > 0 then
      local fy = SLOT_Y + SLOT_H - fillH
      result = result .. "box[" .. bx .. "," .. fy .. ";" .. BAR_W .. "," .. fillH .. ";" .. BAR_COLOR .. "]"
    end
  end
  return result
end

-- `meta` is optional
local function mass_storage_has_filter(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  local filterList = inv:get_list("filter")
  if not filterList then return false end
  for _, stack in ipairs(filterList) do
    if not stack:is_empty() then return true end
  end
  return false
end

local function get_mass_storage_formspec(pos, numUpgradeSlots, optionalMeta)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local upgradeInvString = upgrade_inv(posForm, numUpgradeSlots, 3.8)
  local meta = optionalMeta or minetest.get_meta(pos)
  local selectedImgIndex = logistica.get_mass_storage_image_slot(meta)
  local imgPickX = 1.65
  local imgPickY = 0.1
  local swapButtonsString = upgrade_swap_buttons(pos, numUpgradeSlots, 3.8)
  local hasFilter = mass_storage_has_filter(pos)
  local depositBtn = ""
  if hasFilter then
    depositBtn = "button[3.0,3.9;2.0,0.75;deposit;"..FS("Deposit").."]"..
      "tooltip[deposit;"..FS("Deposit all filtered items from inventory into storage").."]"
  end
  return "formspec_version[4]"..
    "size["..logistica.inv_size(12, 11.5).."]" ..
    logistica.ui.background..
    logistica.player_inv_formspec(1.5,5.75)..
    logistica.ui.button_style..
    "list["..posForm..";storage;1.5,1.9;8,1;0]" ..
    "list["..posForm..";filter;1.5,0.8;8,1;0]" ..
    "image[0.25,0.8;1,1;logistica_icon_filter.png]" ..
    "list["..posForm..";main;1.5,3.8;1,1;0]" ..
    "image[0.25,1.9;1,1;logistica_icon_mass_storage.png]" ..
    "image[0.2,3.8;1,1;logistica_icon_input.png]" ..
    formspec_get_image_pickers(imgPickX, imgPickY, selectedImgIndex, meta)..
    formspec_get_cfg_buttons()..
    formspec_get_fill_bars(pos, meta)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"..
    "listring["..posForm..";storage]"..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"..
    "listring[current_player;main]"..
    upgradeInvString..
    swapButtonsString..
    depositBtn..
    "label[1.55,5.15;"..FS("Slot Storage Capacity: ")..logistica.get_mass_storage_max_size(pos).."]"..
    "tooltip[0.25,1.9;1,1;"..STORAGE_TOOLTIP.."]"..
    "tooltip[0.2,3.8;1,1;"..INPUT_TOOLTIP.."]"..
    "tooltip[0.25,0.8;1,1;"..FILTER_TOOLTIP.."]"..
    "tooltip["..tostring(1.5 + 1.25 * (7 - numUpgradeSlots))..",3.8;1,1;"..UPGRADE_TOOLTIP.."]"..
    "tooltip[0.2,0.1;1,0.5;"..IMAGE_TOOLTIP.."]"
end

local show_mass_storage_formspec

local function refresh_mass_storage_forms(pos)
  for playerName, data in pairs(storageForms) do
    if data and vector.equals(data.position, pos) then
      show_mass_storage_formspec(pos, playerName)
    end
  end
end

show_mass_storage_formspec = function(pos, name, meta)
  local node = minetest.get_node(pos)
  local numUpgradeSlots = minetest.registered_nodes[node.name].logistica.numUpgradeSlots
  storageForms[name] = { position = pos }
  minetest.show_formspec(
    name,
    FORMSPEC_NAME,
    get_mass_storage_formspec(pos, numUpgradeSlots, meta)
  )
end

local function get_slot_config_formspec(pos, slotIndex)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local maxSize = logistica.get_mass_storage_max_size(pos)
  local filterStack = inv:get_stack("filter", slotIndex)
  local itemDesc = filterStack:is_empty() and FS("(empty)") or filterStack:get_short_description()
  local currentCount = inv:get_stack("storage", slotIndex):get_count()
  local reserve = logistica.clamp(get_sr(meta, slotIndex), 0, maxSize)
  local demand  = logistica.clamp(logistica.get_mass_storage_demand(meta, slotIndex), 0, maxSize)
  local crafting = logistica.get_mass_storage_demand_crafting(meta, slotIndex)
  return "formspec_version[4]"..
    "size["..logistica.inv_size(6.5, 6.5).."]"..
    logistica.ui.background..
    "label[0.4,0.4;"..FS("Slot ")..slotIndex.."]"..
    "label[0.4,0.9;"..FS("Item: ")..minetest.formspec_escape(itemDesc).."]"..
    "label[0.4,1.4;"..FS("Stored: ")..currentCount.." / "..maxSize.."]"..
    "label[0.4,2.2;"..FS("Reserve").."]"..
    "field[2.5,1.95;3.6,0.75;reserve;;"..reserve.."]"..
    "label[0.4,2.95;"..FS("Items the network will not take from this slot.").."]"..
    "label[0.4,3.75;"..FS("Demand up to").."]"..
    "field[2.5,3.5;3.6,0.75;demand;;"..demand.."]"..
    "label[0.4,4.5;"..FS("Pull from suppliers until this count is reached.").."]"..
    "checkbox[0.4,4.9;demand_crafting;"..FS("Include Crafting Suppliers")..";"..tostring(crafting).."]"..
    "button_exit[2.0,5.4;2.5,0.75;save;"..FS("Save").."]"
end

local function show_slot_config_formspec(pos, playerName, slotIndex)
  storageForms[playerName] = nil
  slotConfigForms[playerName] = { position = pos, slotIndex = slotIndex }
  minetest.show_formspec(playerName, SLOT_CONFIG_FORMSPEC_NAME, get_slot_config_formspec(pos, slotIndex))
end

local function get_swap_formspec(pos, slotIndex)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local inv = minetest.get_meta(pos):get_inventory()
  ensure_upgrade_swap_slot(inv)
  local currentName = inv:get_stack("upgrade", slotIndex):get_name()
  return "formspec_version[4]"..
    "size["..logistica.inv_size(12, 9.0).."]"..
    logistica.ui.background..
    logistica.player_inv_formspec(1.5, 3.5)..
    "button[11.5,0.15;0.65,0.65;"..CLOSE_SWAP_BTN..";X]"..
    "label[0.25,0.55;"..FS("Swap Upgrade - Slot ")..tostring(slotIndex).."]"..
    "label[0.25,1.35;"..FS("Current:").."]\n"..
    "item_image[1.5,1.0;1.25,1.25;"..currentName.."]"..
    "label[3.75,1.35;"..FS("New:").."]\n"..
    "list["..posForm..";upgrade_swap;4.75,1.0;1,1;0]"..
    "label[0.25,2.6;"..FS("Place a valid upgrade to swap.").."]\n"..
    "listring[current_player;main]"..
    "listring["..posForm..";upgrade_swap]"..
    "listring[current_player;main]"
end

local function show_swap_formspec(pos, playerName, slotIndex)
  storageForms[playerName] = nil
  swapForms[playerName] = { position = pos, slotIndex = slotIndex }
  local inv = minetest.get_meta(pos):get_inventory()
  ensure_upgrade_swap_slot(inv)
  minetest.show_formspec(playerName, SWAP_FORMSPEC_NAME, get_swap_formspec(pos, slotIndex))
end

----------------------------------------------------------------
-- callbacks
----------------------------------------------------------------

local function on_receive_swap_formspec(player, formname, fields)
  if formname ~= SWAP_FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  local swapData = swapForms[playerName]
  if not swapData then return true end
  local pos = swapData.position
  if not logistica.player_has_network_access(pos, playerName) then return true end
  if fields[CLOSE_SWAP_BTN] or (fields.quit and not fields.key_enter_field) then
    clear_upgrade_swap_slot_and_return(pos, player)
    swapForms[playerName] = nil
    if fields[CLOSE_SWAP_BTN] then
      show_mass_storage_formspec(pos, playerName)
    end
  end
  return true
end

local function on_receive_slot_config_formspec(player, formname, fields)
  if formname ~= SLOT_CONFIG_FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local data = slotConfigForms[playerName]
  if not data then return false end
  local pos = data.position
  local slotIndex = data.slotIndex
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.demand_crafting ~= nil then
    -- checkboxes fire immediately on click and don't resend on button press
    logistica.set_mass_storage_demand_crafting(minetest.get_meta(pos), slotIndex, fields.demand_crafting == "true")
  end
  if fields.save or fields.key_enter_field then
    local maxSize = logistica.get_mass_storage_max_size(pos)
    local meta = minetest.get_meta(pos)
    local reserve = logistica.clamp(math.floor(tonumber(fields.reserve) or 0), 0, maxSize)
    local demand  = logistica.clamp(math.floor(tonumber(fields.demand)  or 0), 0, maxSize)
    logistica.set_mass_storage_reserve(meta, slotIndex, reserve)
    logistica.set_mass_storage_demand(meta, slotIndex, demand)
    slotConfigForms[playerName] = nil
    show_mass_storage_formspec(pos, playerName)
  elseif fields.quit then
    slotConfigForms[playerName] = nil
    show_mass_storage_formspec(pos, playerName)
  end
  return true
end

local function on_receive_storage_formspec(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not storageForms[playerName] then return false end
  local pos = storageForms[playerName].position
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit and not fields.key_enter_field then
    logistica.update_mass_storage_front_image(pos)
    storageForms[playerName] = nil
  elseif fields.deposit then
    logistica.mass_storage_deposit_from_player(pos, playerName)
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
      if fields["cfg_slot_"..i] then
        show_slot_config_formspec(pos, playerName, i)
        return true
      end
    end
    local node = minetest.get_node(pos)
    local numUpgradeSlots = minetest.registered_nodes[node.name].logistica.numUpgradeSlots
    for i = 1, numUpgradeSlots do
      if fields["swap_upg_"..i] then
        show_swap_formspec(pos, playerName, i)
        return true
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
  logistica.set_mass_storage_demand_from_string(nodeName, itemMeta:get_string(META_SERIALIZED_DEMAND), meta)
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
  dropMeta:set_string(META_SERIALIZED_DEMAND, logistica.get_mass_storage_demand_as_string(oldnode.name, meta))
  -- update description
  local name = minetest.registered_nodes[oldnode.name].logistica.baseName
  name = name..logistica.get_mass_storage_imgname_or_first_item(meta)
 -- TODO set a node name or use a stackname
  drop:get_meta():set_string("description", name)
end

local function allow_mass_storage_inv_take(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
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
  if listname == "upgrade_swap" then return stack:get_count() end
  return stack:get_count()
end

local function allow_mass_storage_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

local function allow_mass_storage_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == "storage" then return 0 end
  if listname == "main" then
    local inv = minetest.get_meta(pos):get_inventory()
    local remain = logistica.insert_item_into_mass_storage(pos, inv, stack, true)
    return stack:get_count() - remain:get_count()
  end
  if listname == "filter" then
    if stack:get_stack_max() == 1 then return 0 end
    local inv = minetest.get_meta(pos):get_inventory()
    if not inv:get_stack("storage", index):is_empty() then return 0 end
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    inv:set_stack("filter", index, copyStack)
    logistica.update_cache_at_pos(pos, LOG_CACHE_MASS_STORAGE)
    return 0
  end
  if listname == "upgrade" then
    local inv = minetest.get_meta(pos):get_inventory()
    if not logistica.is_valid_storage_upgrade(stack:get_name()) then return 0 end
    if not inv:get_stack(listname, index):is_empty() then return 0 end
    if logistica.is_multiplier_storage_upgrade(stack:get_name()) and logistica.has_multiplier_upgrade_in_inv(inv) then
      return 0
    end
    return 1
  end
  if listname == "upgrade_swap" then
    local swapData = swapForms[player:get_player_name()]
    if not swapData then return 0 end
    local slotIndex = swapData.slotIndex
    if not logistica.is_valid_storage_upgrade(stack:get_name()) then return 0 end
    local inv = minetest.get_meta(pos):get_inventory()
    if logistica.is_multiplier_storage_upgrade(stack:get_name()) then
      for i, st in ipairs(logistica.get_list(inv, "upgrade")) do
        if i ~= slotIndex and logistica.is_multiplier_storage_upgrade(st:get_name()) then return 0 end
      end
    end
    local maxStored = 0
    for _, st in ipairs(logistica.get_list(inv, "storage")) do
      if st:get_count() > maxStored then maxStored = st:get_count() end
    end
    if logistica.get_mass_storage_max_after_swap(pos, slotIndex, stack:get_name()) < maxStored then return 0 end
    return 1
  end
  return stack:get_count()
end


local function on_mass_storage_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
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
      refresh_mass_storage_forms(pos)
    end
  elseif listname == "upgrade" then
    local inv = minetest.get_meta(pos):get_inventory()
    logistica.on_mass_storage_upgrade_change(pos, inv:get_stack(listname, index):get_name(), true)
    refresh_mass_storage_forms(pos)
  elseif listname == "upgrade_swap" then
    local playerName = player:get_player_name()
    local swapData = swapForms[playerName]
    if not swapData then return end
    local slotIndex = swapData.slotIndex
    local inv = minetest.get_meta(pos):get_inventory()
    local newUpgrade = inv:get_stack("upgrade_swap", 1)
    local oldUpgrade = inv:get_stack("upgrade", slotIndex)
    inv:set_stack("upgrade", slotIndex, newUpgrade)
    inv:set_stack("upgrade_swap", 1, ItemStack(""))
    if not oldUpgrade:is_empty() then
      local leftover = player:get_inventory():add_item("main", oldUpgrade)
      if not leftover:is_empty() then minetest.add_item(player:get_pos(), leftover) end
    end
    logistica.update_mass_storage_cap(pos)
    swapForms[playerName] = nil
    show_mass_storage_formspec(pos, playerName)
    refresh_mass_storage_forms(pos)
  end
end

local function on_mass_storage_inv_take(pos, listname, index, stack, player)
  if listname == "upgrade" then
    logistica.on_mass_storage_upgrade_change(pos, stack:get_name(), false)
    refresh_mass_storage_forms(pos)
  elseif listname == "storage" then
    refresh_mass_storage_forms(pos)
  end
end

local function on_mass_storage_punch(pos, node, puncher, pointed_thing)
  if not puncher or not puncher:is_player() then return end
  if not logistica.player_has_network_access(pos, puncher:get_player_name()) then return end
  logistica.try_to_add_player_wield_item_to_mass_storage(pos, puncher)
end

local function on_mass_storage_right_click(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  show_mass_storage_formspec(pos, clicker:get_player_name())
end

local function on_mass_storage_rotate(pos, node, player, mode, newParam2)
  logistica.update_mass_storage_front_image(pos, newParam2)
end

----------------------------------------------------------------
-- register
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_receive_swap_formspec)
minetest.register_on_player_receive_fields(on_receive_slot_config_formspec)
minetest.register_on_player_receive_fields(on_receive_storage_formspec)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    local playerName = objRef:get_player_name()
    storageForms[playerName] = nil
    swapForms[playerName] = nil
    slotConfigForms[playerName] = nil
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
  logistica.GROUPS.mass_storage.register(storageName)

  local def = {
    description = description..S("\n(Empty)"),
    tiles = tiles,
    groups = grps,
    sounds = logistica.node_sound_metallic(),
    after_place_node = function(pos, placer, itemstack)
      after_place_mass_storage(pos, placer, itemstack, numSlots, numUpgradeSlots)
    end,
    after_dig_node = after_mass_storage_destruct,
    drop = storageName,
    on_timer = logistica.on_mass_storage_timer,
    paramtype2 = "facedir",
    logistica = {
      baseName = description,
      maxItems = numItemsPerSlot,
      numSlots = numSlots,
      numUpgradeSlots = numUpgradeSlots,
      on_connect_to_network = function(pos, networkId)
        logistica.start_mass_storage_timer(pos, true)
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
  logistica.register_non_pushable(storageName)

  local def_disabled = {}
  for k, v in pairs(def) do def_disabled[k] = v end
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1, pickaxey = 1, axey = 1, handy = 1 }
  def_disabled.after_dig_node = function(pos, _) logistica.remove_item_on_block_front(pos) end
  def_disabled.on_timer = nil

  minetest.register_node(storageName.."_disabled", def_disabled)

end

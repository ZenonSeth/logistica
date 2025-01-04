local S = logistica.TRANSLATOR

local ITEM_STORAGE_LIST = "main"
local META_STORED_ORDER = "logitemsort"

local sortFunctions = {
  [1] = function(list) return logistica.sort_list_by(list, LOG_SORT_NAME_AZ) end,
  [2] = function(list) return logistica.sort_list_by(list, LOG_SORT_MOD_AZ) end,
  [3] = function(list) return logistica.sort_list_by(list, LOG_SORT_DURABILITY_FWD) end,
}

-- the order should match above lookup
local sortListOrder = {S("Name"), S("Mod"), S("Durability")}
local sortListStr = table.concat(sortListOrder, ",")

--------------------------------
-- public functions
--------------------------------

function logistica.get_item_storage_sort_list_str()
  return sortListStr
end

function logistica.get_item_storage_selected_sort_index(meta)
  local index = meta:get_int(META_STORED_ORDER)
  if index <= 0 then return 1 else return index end
end

function logistica.set_item_storage_selected_sort_value(meta, value)
  meta:set_int(META_STORED_ORDER, table.indexof(sortListOrder, value))
end

function logistica.sort_item_storage_list(meta)
  local sortFunc = sortFunctions[logistica.get_item_storage_selected_sort_index(meta)]
  if not sortFunc then return end
  local inv = meta:get_inventory()
  local list = logistica.get_list(inv, ITEM_STORAGE_LIST)
  local sortedList = sortFunc(list)
  if not sortedList then return end
  inv:set_list(ITEM_STORAGE_LIST, sortedList)
end

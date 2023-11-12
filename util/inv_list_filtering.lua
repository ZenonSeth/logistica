
local lights_map = {}

-- all these get initialized after loadtime

LOG_FILTER_NODE = function(_) return true end
LOG_FILTER_CRAFTITEM = function(_) return true end
LOG_FILTER_TOOL = function(_) return true end
LOG_FILTER_LIGHT = function(_) return true end

local function load_lights()
  for name, def in pairs(minetest.registered_items) do
    if def.light_source and def.light_source > 0 then
      lights_map[name] = true
    end
  end
end

local function create_filter(lookupTable)
  return function(name)
    return lookupTable[name] ~= nil
  end
end

local function load_filters()
  LOG_FILTER_NODE = create_filter(minetest.registered_nodes)
  LOG_FILTER_CRAFTITEM = create_filter(minetest.registered_craftitems)
  LOG_FILTER_TOOL = create_filter(minetest.registered_tools)
  LOG_FILTER_LIGHT = create_filter(lights_map)
end

local function do_filter(stackList, filterMethod)
  local res = {}
  local idx = 0
  for _, stack in ipairs(stackList) do
    if filterMethod(stack:get_name()) then
      idx = idx + 1
      res[idx] = stack
    end
  end
  return res, idx
end

--------------------------------
-- public funcs
--------------------------------

-- 1st return: a new list that cotains only matching items; 2nd return: filtered list size
-- or return just the same list immediately for convenience if `filterMethod` is nil
-- filterMethod should be one of LOG_FILTER_NODE, LOG_FILTER_CRAFTITEM, LOG_FILTER_TOOL, LOG_FILTER_LIGHT
function logistica.filter_list_by(stackList, filterMethod)
  return do_filter(stackList, filterMethod)
end

--------------------------------
-- registration
--------------------------------

minetest.register_on_mods_loaded(function()
  load_lights()
  load_filters()
end)

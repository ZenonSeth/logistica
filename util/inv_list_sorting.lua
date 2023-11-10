local S = logistica.TRANSLATOR
local LANG_EN = "en"

--------------------------------
-- private funcs
--------------------------------

local function get_description(st) return minetest.get_translated_string(LANG_EN, st:get_short_description()) end
local function get_name(st) d.log(st:get_name()) ; return st:get_name() end
local function get_stack_size(st) return st:get_count() end
local function get_wear(st) return st:get_wear() end

local compareSmallestFirst = function(s1,s2) return s1 < s2 end
local compareLargestFirst = function(s1,s2) return s1 > s2 end

local function create_sorter(valOf, compare) return {
  areEq = function(stack1, stack2) return valOf(stack1) == valOf(stack2) end,
  compare = function (stack1, stack2) return compare(valOf(stack1), valOf(stack2)) end
} end

local function do_sort(list, crit1, crit2)
  if crit2 then
    table.sort(list, function(s1, s2)
      if crit1.areEq(s1, s2) then return crit2.compare(s1, s2) end
      return crit1.compare(s1, s2)
    end)
  else
    table.sort(list, crit1.compare)
  end
end

--------------------------------
-- sorting criteria
--------------------------------

LOG_SORT_NAME_AZ = create_sorter(get_description, compareSmallestFirst)
LOG_SORT_NAME_ZA = create_sorter(get_description, compareLargestFirst)
LOG_SORT_MOD_AZ = create_sorter(get_name, compareSmallestFirst)
LOG_SORT_MOD_ZA = create_sorter(get_name, compareLargestFirst)
LOG_SORT_DURABILITY_FWD = create_sorter(get_wear, compareSmallestFirst)
LOG_SORT_DURABILITY_REV = create_sorter(get_wear, compareLargestFirst)
LOG_SORT_STACK_SIZE_FWD = create_sorter(get_stack_size, compareSmallestFirst)
LOG_SORT_STACK_SIZE_REV = create_sorter(get_stack_size, compareLargestFirst)

--------------------------------
-- public functions
--------------------------------

-- sorts the given list, returning a new, sorted copy
-- `criteria` must be one of:<br>
-- `LOG_SORT_NAME_AZ`, `LOG_SORT_MOD_AZ`, `LOG_SORT_DURABILITY`, `LOG_SORT_STACK_SIZE`<br>
-- `secondaryCriteria` is optional; takes a function just like `criteria` and will be used
-- if two items are equal by the primary `criteria`.<br>
-- `emptyFirst` is optional, default `nil`; `true` = put all empty slots at top; `false`/`nil` = put all empty slots at bottom
function logistica.sort_list_by(list, criteria, secondaryCriteria, emptyFirst)
  if not list then return end
  local filledList = {}
  local emptyList = {}
  for _, v in ipairs(list) do
    if v:is_empty() then table.insert(emptyList, v)
    else table.insert(filledList, v) end
  end
  do_sort(filledList, criteria, secondaryCriteria)
  local first = filledList; local second = emptyList
  if emptyFirst then first = emptyList ; second = filledList end
  return table.insert_all(first, second)
end

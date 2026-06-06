-- Reverse-recipe registry for the Logistica Machine Disassembler.
-- Use logistica.register_craft(def) instead of minetest.register_craft for any
-- machine recipe that should be disassemblable. Component item recipes (item_recipes.lua)
-- continue to use minetest.register_craft directly and are not tracked here.

logistica._disassemble_recipes = {}

local function parse_output(output_str)
  local name, count = output_str:match("^(%S+)%s+(%d+)$")
  if name then return name, tonumber(count) end
  return output_str, 1
end

local function build_ingredients(def)
  local replaced = {}
  if def.replacements then
    for _, r in ipairs(def.replacements) do
      -- r[1] is the ingredient consumed; it gets replaced, so treat as not consumed
      local name = r[1]:match("^(%S+)")
      if name then replaced[name] = true end
    end
  end

  local flat = {}
  local items = def.recipe
  if type(items[1]) == "table" then
    for _, row in ipairs(items) do
      for _, item in ipairs(row) do
        if item and item ~= "" then flat[#flat + 1] = item end
      end
    end
  else
    for _, item in ipairs(items) do
      if item and item ~= "" then flat[#flat + 1] = item end
    end
  end

  local ingredients = {}
  for _, item in ipairs(flat) do
    local name = item:match("^(%S+)")
    if name and name ~= "" and not replaced[name] then
      ingredients[name] = (ingredients[name] or 0) + 1
    end
  end
  return ingredients
end

function logistica.register_craft(def)
  minetest.register_craft(def)
  if def.no_recycle then return end

  local output_name, output_count = parse_output(def.output)
  if not output_name or output_name == "" then return end

  local entry = {
    ingredients = build_ingredients(def),
    output_count = output_count,
  }

  if not logistica._disassemble_recipes[output_name] then
    logistica._disassemble_recipes[output_name] = {}
  end
  table.insert(logistica._disassemble_recipes[output_name], entry)
end

-- Returns list of recipe entries for item_name, each:
--   { ingredients = {[item_name] = count, ...}, output_count = N }
-- Returns empty table if item has no registered disassemble recipe.
function logistica.get_disassemble_recipes(item_name)
  return logistica._disassemble_recipes[item_name] or {}
end

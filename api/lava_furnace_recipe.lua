
local lava_furance_recipes = {}
local NORMAL_COOK_LAVA_USAGE_PER_SEC = 2 -- in millibuckets
local NORMAL_COOK_REDUCTION_FACTOR = 2
local MIN_TIME = 0.5

--[[
The Lava Furnace recipes format is indexed for item stack.<br>
`def`: A table in the following format:
{
  input = "input_name", -- required, a string of the input stack needed in the input slot
  input_count = N, -- optional; how many of the input items are needed
  output = "item_name N", -- required, the result of the crystalization
  lava = 1000, -- required, how much lava is consumed. 1000 units = 1 bucket
  additive = "item_name N", -- optional; the additive that is required to be present for this recipe
  additive_use_chance = 100, -- optional; the chance that the additive will be consumed (0 = never, 100 = always)
  time = 10, -- required, approximate time, in seconds, this recipe takes to complete, min is defined by MIN_TIME (or 1sec in practice)
}
]]
function logistica.register_lava_furnace_recipe(def)
  if not def or not def.input or not def.output or not def.lava or not def.time then
    return
  end

  local useChance = (def.additive_use_chance ~= nil and logistica.clamp(def.additive_use_chance, 0, 100)) or 100
  lava_furance_recipes[def.input] = lava_furance_recipes[def.input] or {}
  table.insert(lava_furance_recipes[def.input], {
    input = def.input,
    input_count = def.input_count or 1,
    output = def.output,
    lava = math.max(1, def.lava),
    additive = def.additive,
    additive_use_chance = useChance,
    time = math.max(MIN_TIME, def.time or 1),
  })
end

function logistica.get_lava_furnace_recipes_for(itemName)
  local presets = lava_furance_recipes[itemName]
  if presets then return presets end

  -- else, try to adopt the real one
  local output, decrOut = minetest.get_craft_result({
    method = "cooking", width = 1, items = { ItemStack(itemName) }
  })

  if output.time > 0 and decrOut.items[1]:is_empty() then
    local lavaTime = math.max(MIN_TIME, output.time / NORMAL_COOK_REDUCTION_FACTOR)
    return {{
      input_count = 1,
      output = output.item:to_string(),
      lava = lavaTime * NORMAL_COOK_LAVA_USAGE_PER_SEC,
      time = lavaTime
    }}
  end

  -- nothing found
  return nil
end

-- returns a copy_pointed_thing of internal the internal recipes - for reference
function logistica.get_lava_furnace_internal_recipes()
  return table.copy(lava_furance_recipes)
end
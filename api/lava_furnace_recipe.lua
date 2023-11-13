
local lava_furance_recipes = {}
local NORMAL_COOK_LAVA_USAGE_PER_SEC = 5 -- in millibuckets
local NORMAL_COOK_REDUCTION_FACTOR = 2
local MIN_TIME = 0.5

--[[
The Lava Furnace recipes format is indexed for item stack.<br>
`name`: The input item
`def`: A table in the following format:
{
  input_count = N, -- optional; how many of the input items are needed
  output = "item_name N", -- the result of the crystalization
  lava = 1000, -- how much lava is consumed. 1000 units = 1 bucket
  additive = "item_name N", -- optional; the additive that is required to be present for this recipe
  additive_use_chance = 100, -- optional; the chance that the additive will be consumed (0 = never, 100 = always)
  time = 10, -- approximate time, in seconds, this recipe takes to complete, min is defined by MIN_TIME (or 1sec in practice)
}
]]
function logistica.register_lava_furnace_recipe(name, def)
  if not name or not def or not def.output or not def.lava or not def.time then
    return
  end

  local useChance = (def.additive_use_chance ~= nil and logistica.clamp(def.additive_use_chance, 0, 100)) or 100
  lava_furance_recipes[name] = {
    input_count = def.input_count or 1,
    output = def.output,
    lava = math.max(1, def.lava),
    additive = def.additive,
    additive_use_chance = useChance,
    time = math.max(MIN_TIME, def.time or 1),
  }
end

function logistica.get_lava_furnace_recipe_for(itemName)
  local preset = lava_furance_recipes[itemName]
  if preset then return preset end

  -- else, try to adopt the real one
  local output, decrOut = minetest.get_craft_result({
    method = "cooking", width = 1, items = { ItemStack(itemName) }
  })

  if output.time > 0 and decrOut.items[1]:is_empty() then
    local lavaTime = math.max(MIN_TIME, output.time / NORMAL_COOK_REDUCTION_FACTOR)
    return {
      input_count = 1,
      output = output.item:to_string(),
      lava = lavaTime * NORMAL_COOK_LAVA_USAGE_PER_SEC,
      time = lavaTime
    }
  end

  -- nothing found
  return nil
end

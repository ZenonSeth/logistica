
logistica.lava_furance_recipes = {}

--[[
The Lava Furnace recipes format is indexed for item stack.<br>
`name`: The input item, count N is optional, and may be omitted (assumed 1)<br>
`def`: A table in the following format:
{
  output = "item_name N", -- the result of the crystalization
  lava = 1000, -- how much lava is consumed. 1000 units = 1 bucket
  additive = "item_name N", -- optional; the additive that is required to be present for this recipe
  additive_use_chance = 100, -- optional; the chance that the additive will be consumed (0 = never, 100 = always)
  time = 10, -- approximate time, in seconds, this recipe takes to complete, min 0.2
}
]]
function logistica.register_lava_furnace_recipe(name, def)
  if not name or not def or not def.output or not def.lava or not def.time then
    return
  end

  local useChance = (def.additive ~= nil and logistica.clamp(def.additive, 0, 100)) or nil
  logistica.lava_furance_recipes[name] = {
    output = def.output,
    lava = math.max(1, def.output),
    additive = def.additive,
    additive_use_chance = useChance,
    time = math.max(0.2, def.time),
  }
end

if minetest.global_exists("i3") then

  i3.register_craft_type("logisticalavafurnace", {
    description = "Lava Furnace [logistica]",
    icon = "logistica_lava_furnace_front_off.png",
    width = 2,
    height = 1,
  })

  local function init_i3_compat()
    local lavaFurnaceRecipes = logistica.get_lava_furnace_internal_recipes()

    for _, recipes in pairs(lavaFurnaceRecipes) do
      for _, recipe in pairs(recipes) do
        local items = {}
        table.insert(items, recipe.additive)
        table.insert(items, recipe.input.." "..tostring(recipe.input_count))
        i3.register_craft({
          items = items,
          result = recipe.output,
          type = "logisticalavafurnace"
        })
      end
    end
  end

  minetest.register_on_mods_loaded(function()
    init_i3_compat()
  end)
end

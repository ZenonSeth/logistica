local S = logistica.TRANSLATOR

if minetest.global_exists("unified_inventory") then
  unified_inventory.register_craft_type("logisticalavafurnace", {
    description = S("Lava Furnace [logistica]"),
    icon = "logistica_lava_furnace_front_off.png",
    width = 2,
    height = 1,
  })


  local function init_unified_inv_compat()
    local lavaFurnaceRecipes = logistica.get_lava_furnace_internal_recipes()

    for _, recipes in pairs(lavaFurnaceRecipes) do
      for _, recipe in pairs(recipes) do
        local items = {}
        table.insert(items, recipe.input.." "..tostring(recipe.input_count))
        table.insert(items, recipe.additive)
        unified_inventory.register_craft({
          items = items,
          output = recipe.output,
          type = "logisticalavafurnace"
        })
      end
    end
  end

  minetest.register_on_mods_loaded(function()
    init_unified_inv_compat()
  end)

end

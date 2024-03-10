if minetest.global_exists("i3") then

  local L  = function(str) return "logistica:"..str end

  i3.register_craft_type("logisticalavafurnace", {
    description = "Lava Furnace [logistica]",
    icon = "logistica_lava_furnace_front_off.png",
  })

  i3.register_craft({
		items = {"default:silver_sand", "default:ice"},
		result = L("silverin"),
		type = "logisticalavafurnace"
	})

	i3.register_craft({
		items = {L("silverin"), "default:steel_ingot"},
		result = L("silverin_plate 4"),
		type = "logisticalavafurnace"
	})

	i3.register_craft({
		items = {L("silverin_slice"), "default:mese_crystal_fragment"},
		result = L("silverin_circuit"),
		type = "logisticalavafurnace"
	})

  i3.register_craft({
		items = {"default:glass", L("silverin_slice 6")},
		result = L("silverin_mirror_box"),
		type = "logisticalavafurnace"
	})

	i3.register_craft({
		items = {L("silverin"), "default:mese_crystal"},
		result = L("wireless_crystal"),
		type = "logisticalavafurnace"
	})

end

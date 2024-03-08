if minetest.global_exists("unified_inventory") then

  local L  = function(str) return "logistica:"..str end

	unified_inventory.register_craft_type("logisticalavafurnace", {
		description = "Lava Furnace [logistica]",
		icon = "logistica_lava_furnace_front_off.png",
		width = 2,
		height = 1,
	})

  unified_inventory.register_craft({
		items = {"default:silver_sand", "default:ice"},
		output = L("silverin"),
		type = "logisticalavafurnace"
	})

	unified_inventory.register_craft({
		items = {L("silverin"), "default:steel_ingot"},
		output = L("silverin_plate 4"),
		type = "logisticalavafurnace"
	})

	unified_inventory.register_craft({
		items = {L("silverin_slice"), "default:mese_crystal_fragment"},
		output = L("silverin_circuit"),
		type = "logisticalavafurnace"
	})

  unified_inventory.register_craft({
		items = {"default:glass", L("silverin_slice 6")},
		output = L("silverin_mirror_box"),
		type = "logisticalavafurnace"
	})

	unified_inventory.register_craft({
		items = {L("silverin"), "default:mese_crystal"},
		output = L("wireless_crystal"),
		type = "logisticalavafurnace"
	})

end



-- todo: rework this to make tiers not tied to cable name and to be optional

-- Main function to register a new cable of certain tier
function logistica.register_cable(tier, size)
	local ltier = string.lower(tier)
	local cable_name = "logistica:" .. ltier .. "_cable"
	local cable_group = logistica.get_cable_group(ltier)
	logistica.cables[cable_name] = tier
	logistica.tiers[ltier] = true

	local node_box = {
		type           = "connected",
		fixed          = { -size, -size, -size, size, size, size },
		connect_top    = { -size, -size, -size, size, 0.5, size }, -- y+
		connect_bottom = { -size, -0.5, -size, size, size, size }, -- y-
		connect_front  = { -size, -size, -0.5, size, size, size }, -- z-
		connect_back   = { -size, -size, size, size, size, 0.5 }, -- z+
		connect_left   = { -0.5, -size, -size, size, size, size }, -- x-
		connect_right  = { -size, -size, -size, 0.5, size, size }, -- x+
	}

	local def = {
		description = tier .. " Cable",
		tiles = { "logistica_" .. ltier .. "_cable.png" },
		inventory_image = "logistica_" .. ltier .. "_cable_inv.png",
		wield_image = "logistica_" .. ltier .. "_cable_inv.png",
		groups = {
			cracky = 3,
			choppy = 3,
			oddly_breakable_by_hand = 2,
			[cable_group] = 1,
		},
		sounds = logistica.node_sound_metallic(),
		drop = cable_name,
		paramtype = "light",
		sunlight_propagates = true,
		drawtype = "nodebox",
		node_box = node_box,
		connects_to = { "group:" .. cable_group, "group:"..logistica.get_machine_group(ltier), logistica.GROUP_ALL },
		on_construct = function(pos) logistica.on_cable_change(pos, nil) end,
		after_destruct = function(pos, oldnode) logistica.on_cable_change(pos, oldnode) end,
	}

	minetest.register_node(cable_name, def)

	local def_broken = {}
	for k, v in pairs(def) do def_broken[k] = v end
	def_broken.tiles = { "logistica_" .. ltier .. "_cable.png^logistica_broken.png" }
	def_broken.inventory_image = "logistica_" .. ltier .. "_cable_inv.png^logistica_broken.png"
	def_broken.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 }
	def_broken.description = "Broken " .. tier .. " Cable"
	def_broken.node_box = { type = "fixed", fixed = { -0.5, -size, -size, 0.5, size, size } }
	def_broken.selection_box = def_broken.node_box
	def_broken.connects_to = nil
	def_broken.on_construct = nil
	def_broken.after_destruct = nil

	minetest.register_node(cable_name .. "_disabled", def_broken)
end

logistica.register_cable("Copper", 1 / 8)
logistica.register_cable("Silver", 1 / 8)
logistica.register_cable("Gold", 1 / 8)

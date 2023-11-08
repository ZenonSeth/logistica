local IO_ENTITY_LIFETIME = 3
local entityTable = {}

function logistica.add_entity(key, entity)
	logistica.remove_entity(key)
	entityTable[key] = entity
end

function logistica.remove_entity(key)
	if entityTable[key] then
		entityTable[key].object:remove()
	end
end

local ioCommonDef = {
	physical = false,
	collide_with_objects = false,
	visual = "cube",
	collisionbox = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0},
	backface_culling = false,
	visual_size = {x=1.1, y=1.1},
	static_save = false,
	groups = {"immortal"},
	on_punch = function (self, puncher, time_from_last_punch, tool_capabilities, dir)
		self.object:remove()
	end,
	on_activate = function(self, staticdata, dtime_s)
		self.data = staticdata
	end,
	on_step = function (self, dtime)
		self.lifeTime = self.lifeTime + dtime
		if self.lifeTime > IO_ENTITY_LIFETIME then
			self.object:remove()
		end
	end,
	lifeTime = 0,
	data = ""
}

local inputDef = table.copy(ioCommonDef)
inputDef.textures =
	{"logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png"}
minetest.register_entity("logistica:input_entity", inputDef)

local outputDef = table.copy(ioCommonDef)
outputDef.textures =
	{"logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png"}
minetest.register_entity("logistica:output_entity", outputDef)

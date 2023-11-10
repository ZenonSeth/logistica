local INPUT_ENAME = "logistica:input_entity"
local OUTPUT_ENAME = "logistica:output_entity"
local IO_ENTITY_LIFETIME = 3
local entityTable = {}

local ioCommonDef = {
  physical = false,
  collide_with_objects = false,
  visual = "cube",
  collisionbox = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0},
  selectionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
  backface_culling = false,
  glow = 5,
  visual_size = {x=1.1, y=1.1},
  static_save = false,
  groups = {"immortal"},
  on_punch = function (self, puncher, time_from_last_punch, tool_capabilities, dir)
    self.object:remove()
  end,
  on_activate = function(self, staticdata, dtime_s)
    self.key = staticdata
  end,
  on_step = function (self, dtime)
    self.lifeTime = self.lifeTime + dtime
    if self.lifeTime > IO_ENTITY_LIFETIME then
      self.object:remove()
      entityTable[self.key] = nil
    end
  end,
  lifeTime = 0,
  key = ""
}

-- register entity

local inputDef = table.copy(ioCommonDef)
inputDef.textures =
  {"logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png", "logistica_entity_input.png"}
minetest.register_entity(INPUT_ENAME, inputDef)

local outputDef = table.copy(ioCommonDef)
outputDef.textures =
  {"logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png", "logistica_entity_output.png"}
minetest.register_entity(OUTPUT_ENAME, outputDef)

local function show_entity(pos, optionalKey, name)
  local key = optionalKey or logistica.get_rand_string_for(pos)
  local entity = entityTable[key]
  if entity ~= nil then
    entity:remove()
    entityTable[key] = nil
  end
  entity = minetest.add_entity(pos, name, key)
  entityTable[key] = entity
end

-- public functions

-- key is an optional string, if not passed, the position's hash is used
function logistica.show_input_at(pos, optionalKey)
  show_entity(pos, optionalKey, INPUT_ENAME)
end

-- key is an optional string, if not passed, the position's hash is used
function logistica.show_output_at(pos, optionalKey)
  show_entity(pos, optionalKey, OUTPUT_ENAME)
end

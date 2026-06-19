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
    entityTable[self.key] = nil
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

local function show_entity(pos, optionalKey, name, optVisualSize)
  if not pos then return end
  local key = optionalKey or logistica.get_rand_string_for(pos)
  local entity = entityTable[key]
  if entity ~= nil then
    entity:remove()
    entityTable[key] = nil
  end
  entity = minetest.add_entity(pos, name, key)
  if entity and optVisualSize then
    entity:set_properties({visual_size = optVisualSize})
  end
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

-- Shows a single scaled IN entity covering the box from pos1 to pos2.
-- For cube visuals, x and z scale together, so the larger of the two spans is used.
-- key is an optional string for deduplication; if not passed, derived from pos1.
function logistica.show_input_area(pos1, pos2, optionalKey)
  local center = vector.new(
    (pos1.x + pos2.x) / 2,
    (pos1.y + pos2.y) / 2,
    (pos1.z + pos2.z) / 2
  )
  local sx = pos2.x - pos1.x + 1.1
  local sz = pos2.z - pos1.z + 1.1
  local sy = pos2.y - pos1.y + 1.1
  show_entity(center, optionalKey, INPUT_ENAME, {x = math.max(sx, sz), y = sy})
end

local ENTITY_NAME = "logistica:display_item"
local ENTITY_DIST_ADJ = 17 / 32
-- must be created with staticdata="id;texture"
minetest.register_entity(ENTITY_NAME, {
  initial_properties = {
    hp_max = 1,
    visual = "wielditem",
    visual_size = {x = 0.3, y = 0.3},
    collisionbox = {0, 0, 0, 0, 0, 0},
    physical = false,
    textures = {"air"},
    static_save = true
  },

  on_activate = function(self, staticdata)
    if staticdata and staticdata ~= "" then
      local data = staticdata:split(";")
      if data and data[1] and data[2] then
        self.id = data[1]
        self.texture = data[2]
      else
        self.object:remove()
      end
    end

    if self.texture then
      self.object:set_properties({textures = {self.texture}})
    end
  end,

  get_staticdata = function(self)
    if self.id and self.texture then return
      self.id..";"..self.texture
    else
      return ""
    end
  end
})

-- public functions 

-- `optionalId` is optional
function logistica.remove_item_on_block_front(pos, optionalId)
  local id = optionalId or logistica.get_rand_string_for(pos)
  local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1)
  if objs then
    for _, obj in pairs(objs) do
      if obj and obj:get_luaentity()
        and obj:get_luaentity().name == ENTITY_NAME
        and obj:get_luaentity().id == id then
        obj:remove()
      end
    end
  end
end

-- `newParam2` is optional, will override the lookup of node.param2 for rotation
function logistica.display_item_on_block_front(pos, item, newParam2)
  if item == nil or item == "" then return logistica.remove_item_on_block_front(pos) end
  local node = minetest.get_node(pos)
  if not node then return end
  local id = logistica.get_rand_string_for(pos)

  logistica.remove_item_on_block_front(pos, id)

  local adjust = logistica.get_front_face_object_info(newParam2 or node.param2)
  if not adjust then return end

  pos.x = pos.x + adjust.x * ENTITY_DIST_ADJ
  pos.y = pos.y + adjust.y * ENTITY_DIST_ADJ
  pos.z = pos.z + adjust.z * ENTITY_DIST_ADJ
  local  pitch = adjust.pitch
  --local yaw = math.pi * 2 - adjust.yaw * math.pi / 2
  local yaw = 6.28 - adjust.yaw * 1.57
  --local roll = math.pi * 2 - adjust.roll * math.pi / 2
  local roll = 6.28 - adjust.roll * 1.57

  local texture = ItemStack(item):get_name()

  local entity = minetest.add_entity(pos, ENTITY_NAME, id..";"..texture)

  entity:set_rotation({x = pitch, y = yaw, z = roll})
end

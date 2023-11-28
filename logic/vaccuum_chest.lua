
local TIMER_INTERVAL = 0.8
local TIMER_INTERVAL_LONG = 2.0
local DEF_RADIUS = 3
local INV_MAIN = "main"
local ITEM_TAKE_PER_CYCLE_LIMIT = 10
local NUM_PARTICLES_PER_COLLECT = 3

local function random_offset()
  return vector.new((math.random() - 0.5)/4, (math.random()  - 0.5)/4, (math.random()  - 0.5)/4)
end

local function add_particle_effect_for_item_taken(itemPos, vaccuumPos)
  for _ = 1, NUM_PARTICLES_PER_COLLECT do
    local startPos = vector.add(itemPos, random_offset())
    local endPos = vector.add(vaccuumPos, vector.new(0, -0.45, 0))
    local vel = vector.multiply(vector.normalize(vector.subtract(endPos, startPos)), 2)
    minetest.add_particle({
      pos = startPos,
      velocity = vel,
      expirationtime = 2,
      size = 1,
      collisiondetection = true,
      collision_removal = true,
      object_collision = false,
      texture = "logistica_vaccuum_particle.png",
    })
  end
end

-- returns how many were inserted
local function collect_items_into(pos, distance)
  local inserted = 0

  local nodeName = minetest.get_node(pos).name
  if not logistica.is_vaccuum_supplier(nodeName) then return inserted end
  local nodeDef = minetest.registered_nodes[nodeName]
  if not nodeDef or not nodeDef.logistica or not nodeDef.on_metadata_inventory_put then
    return inserted
  end

  distance = distance + 0.5
	local minPos = vector.subtract(pos, distance)
	local maxPos = vector.add(pos, distance)
  local inv = minetest.get_meta(pos):get_inventory()
	for _, obj in pairs(minetest.get_objects_in_area(minPos, maxPos)) do
		local entity = obj:get_luaentity()
		if entity
      and entity.name == "__builtin:item"
      and entity.itemstring ~= "" then
      local itemStack = ItemStack(entity.itemstring)
      if inv:room_for_item(INV_MAIN, itemStack) then
        add_particle_effect_for_item_taken(obj:get_pos(), pos)
        inv:add_item(INV_MAIN, itemStack)
        -- this look unsafe, but we only target our supplier nodes
        entity.itemstring = ""
        inserted = inserted + 1
        obj:remove()
        if ITEM_TAKE_PER_CYCLE_LIMIT > 0
          and inserted >= ITEM_TAKE_PER_CYCLE_LIMIT then
            nodeDef.on_metadata_inventory_put(pos, nil, nil, nil, nil)
            return inserted
        end
      end
		end
	end
  if inserted > 0 then
    nodeDef.on_metadata_inventory_put(pos, nil, nil, nil, nil)
  end
  return inserted
end

-- global functions

function logistica.vaccuum_chest_on_timer(pos, elapsed)
  if not logistica.is_machine_on(pos) then return false end
  local inserted = collect_items_into(pos, DEF_RADIUS)
  if inserted then
    logistica.start_node_timer(pos, TIMER_INTERVAL)
  else
    logistica.start_node_timer(pos, TIMER_INTERVAL_LONG)
  end
  return false
end

function logistica.vaccuum_chest_on_power(pos, power)
  logistica.set_node_tooltip_from_state(pos, nil, power)
  logistica.start_node_timer(pos, TIMER_INTERVAL)
end

local INV_MAIN = "main"
local INV_UPGRADE = "upgrade"
local SPRINKLER_UPGRADE = "logistica:sprinkler_upgrade"
local SPRINKLER_GROW_CHANCE = 0.15
local MAX_HARVESTS_PER_CYCLE = 4
local META_RADIUS = "farm_radius"
local META_HEIGHT_MODE = "farm_height_mode"
local META_TIMER_INTERVAL = "farm_timer_interval"

local MIN_RADIUS = 1
local MAX_RADIUS = 3
local DEF_RADIUS = 3

-- height mode constants
local MODE_ABOVE = 1
local MODE_LEVEL = 2
local MODE_BELOW = 3
local DEF_HEIGHT_MODE = MODE_ABOVE

local TIMER_CHOICES = {3.0, 3.2, 3.4, 3.6}

local function get_radius(pos)
  local r = minetest.get_meta(pos):get_int(META_RADIUS)
  if r < MIN_RADIUS then return DEF_RADIUS end
  return r
end

local function get_height_mode(pos)
  local m = minetest.get_meta(pos):get_int(META_HEIGHT_MODE)
  if m < MODE_ABOVE or m > MODE_BELOW then return DEF_HEIGHT_MODE end
  return m
end

local function pick_timer_interval()
  return TIMER_CHOICES[math.random(#TIMER_CHOICES)]
end

local function get_timer_interval(pos)
  local meta = minetest.get_meta(pos)
  local t = meta:get_float(META_TIMER_INTERVAL)
  if t <= 0 then
    t = pick_timer_interval()
    meta:set_float(META_TIMER_INTERVAL, t)
  end
  return t
end

local function get_base_and_stage(nodename)
  local base, num = nodename:match("^(.+_)(%d+)$")
  if not base then return nil, nil end
  return base, tonumber(num)
end

local function is_fully_grown(nodename)
  local base, stage = get_base_and_stage(nodename)
  if not base then return true end -- single-stage plant
  return minetest.registered_nodes[base .. (stage + 1)] == nil
end

local function get_scan_bounds(pos, radius, height_mode)
  local y_min, y_max
  if height_mode == MODE_ABOVE then
    y_min, y_max = pos.y + 1, pos.y + 2
  elseif height_mode == MODE_BELOW then
    y_min, y_max = pos.y - 2, pos.y - 1
  else -- MODE_LEVEL
    y_min, y_max = pos.y, pos.y
  end
  return
    vector.new(pos.x - radius, y_min, pos.z - radius),
    vector.new(pos.x + radius, y_max, pos.z + radius)
end

local function has_sprinkler_upgrade(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:get_size(INV_UPGRADE) == 0 then return false end
  return inv:get_stack(INV_UPGRADE, 1):get_name() == SPRINKLER_UPGRADE
end

local function spawn_water_particles(pos, height_mode)
  local spawn_y, vy_base
  if height_mode == MODE_BELOW then
    spawn_y = pos.y - 0.55
    vy_base = 0.2
  else -- MODE_LEVEL
    spawn_y = pos.y + 0.6
    vy_base = -0.5
  end
  local count = math.random(10, 12)
  for _ = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = 1.0 + math.random() * 1.5
    minetest.add_particle({
      pos = vector.new(
        pos.x + (math.random() - 0.5) * 0.3,
        spawn_y,
        pos.z + (math.random() - 0.5) * 0.3),
      velocity = vector.new(
        math.cos(angle) * speed,
        vy_base + (math.random() - 0.5) * 0.3,
        math.sin(angle) * speed),
      acceleration = vector.new(0, -3, 0),
      expirationtime = 1.0,
      size = 1.5,
      collisiondetection = true,
      -- collision_removal = true,
      object_collision = false,
      texture = "logistica_water_particle.png",
    })
  end
end

local function try_advance_growth(crop_pos)
  local node = minetest.get_node(crop_pos)
  local below = minetest.get_node(vector.new(crop_pos.x, crop_pos.y - 1, crop_pos.z))
  if minetest.get_item_group(below.name, "soil") == 0 then return false end
  local base, stage = get_base_and_stage(node.name)
  if not base then return false end
  local next_name = base .. (stage + 1)
  if not minetest.registered_nodes[next_name] then return false end
  minetest.set_node(crop_pos, {name = next_name, param2 = node.param2})
  return true
end

local function try_harvest(crop_pos, inv)
  local node = minetest.get_node(crop_pos)
  local def = minetest.registered_nodes[node.name]
  if not def or not def.groups or not def.groups.plant then return false end
  local below = minetest.get_node(vector.new(crop_pos.x, crop_pos.y - 1, crop_pos.z))
  if minetest.get_item_group(below.name, "soil") == 0 then return false end
  if not is_fully_grown(node.name) then return false end

  local drops = minetest.get_node_drops(node.name, "")
  if not drops or #drops == 0 then return false end

  -- check room for all drops before committing
  for _, drop in ipairs(drops) do
    if drop and drop ~= "" then
      if not inv:room_for_item(INV_MAIN, ItemStack(drop)) then return false end
    end
  end

  -- add all drops
  for _, drop in ipairs(drops) do
    if drop and drop ~= "" then
      inv:add_item(INV_MAIN, ItemStack(drop))
    end
  end

  -- replant at stage 1 or set air
  local base = get_base_and_stage(node.name)
  local replant = base and (base .. "1") or nil
  if replant and minetest.registered_nodes[replant] then
    local p2 = minetest.registered_nodes[replant].place_param2 or 1
    minetest.set_node(crop_pos, {name = replant, param2 = p2})
  else
    minetest.set_node(crop_pos, {name = "air"})
  end

  return true
end

local function do_farming(pos)
  if not logistica.get_network_or_nil(pos) then return false end
  local inv = minetest.get_meta(pos):get_inventory()

  local radius = get_radius(pos)
  local height_mode = get_height_mode(pos)
  local min_pos, max_pos = get_scan_bounds(pos, radius, height_mode)

  local plant_positions = minetest.find_nodes_in_area(min_pos, max_pos, "group:plant")
  if not plant_positions or #plant_positions == 0 then return false end

  local harvested = 0
  for _, crop_pos in ipairs(plant_positions) do
    if harvested >= MAX_HARVESTS_PER_CYCLE then break end
    if try_harvest(crop_pos, inv) then
      harvested = harvested + 1
    end
  end

  -- sprinkler pass: disabled in Farm Above mode, runs after harvest
  if has_sprinkler_upgrade(pos) and height_mode ~= MODE_ABOVE then
    local empty = ItemStack(logistica.itemstrings.empty_bucket)
    local result = logistica.use_bucket_for_liquid_in_network(pos, empty, logistica.liquids.water, false)
    if result ~= nil then
      spawn_water_particles(pos, height_mode)
      -- local grown = 0
      for _, crop_pos in ipairs(plant_positions) do
        -- if grown >= MAX_HARVESTS_PER_CYCLE then break end
        if math.random() < SPRINKLER_GROW_CHANCE then
          if try_advance_growth(crop_pos) then
            -- grown = grown + 1
          end
        end
      end
    end
  end

  if harvested > 0 then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
    return true
  end
  return false
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function logistica.farming_supplier_on_timer(pos, _elapsed)
  if not logistica.is_machine_on(pos) then return false end
  do_farming(pos)
  logistica.start_node_timer(pos, get_timer_interval(pos))
  return false
end

function logistica.farming_supplier_on_power(pos, _power)
  local meta = minetest.get_meta(pos)
  -- pick interval once on power-up
  local t = pick_timer_interval()
  meta:set_float(META_TIMER_INTERVAL, t)
  logistica.set_node_tooltip_from_state(pos)
  logistica.start_node_timer(pos, t)
end

function logistica.farming_supplier_get_radius(pos)
  return get_radius(pos)
end

function logistica.farming_supplier_get_height_mode(pos)
  return get_height_mode(pos)
end

function logistica.farming_supplier_set_radius(pos, r)
  minetest.get_meta(pos):set_int(META_RADIUS, logistica.clamp(r, MIN_RADIUS, MAX_RADIUS))
end

function logistica.farming_supplier_set_height_mode(pos, m)
  local clamped = logistica.clamp(m, MODE_ABOVE, MODE_BELOW)
  minetest.get_meta(pos):set_int(META_HEIGHT_MODE, clamped)
end

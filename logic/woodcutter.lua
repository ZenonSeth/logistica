
local INV_MAIN = "main"
local INV_UPGRADE = "upgrade"
local LEAVES_UPGRADE = "logistica:leaves_upgrade"
local META_HARVEST_RESULT = "lastHarvestSuccess"
local META_CUT_GEN = "cut_gen"
local META_IS_CUTTING = "is_cutting"

local EMPTY_BUCKET = logistica.itemstrings.empty_bucket
local LAVA_LIQUID_NAME = logistica.liquids.lava
local META_LAVA = "lava_reserve"
local LAVA_MAX = 1000

local MAX_TRUNK_HEIGHT = logistica.settings.woodcutter_max_trunk_height
local MAX_TOTAL_NODES = logistica.settings.woodcutter_max_nodes
local CUT_DELAY = 0.6
local CYCLE_TIME = 8.0

local RESULT_NO_TREE   = 1
local RESULT_TOO_TALL  = 2
local RESULT_TOO_MANY  = 3
local RESULT_INV_FULL  = 4

local META_SAVED_SAPLING = "saved_sapling"
local META_CUT_INTERRUPTED = "cut_interrupted"

local TRUNK_DIRS = {
  vector.new( 1, 0, 0),
  vector.new(-1, 0, 0),
  vector.new( 0, 0, 1),
  vector.new( 0, 0,-1),
  vector.new( 0, 1, 0),
}

local LEAF_DIRS = {
  vector.new( 1, 0, 0),
  vector.new(-1, 0, 0),
  vector.new( 0, 0, 1),
  vector.new( 0, 0,-1),
  vector.new( 0, 1, 0),
  vector.new( 0,-1, 0),
}

local function get_lava(meta) return meta:get_int(META_LAVA) end

local function has_lava(pos, meta, amount)
  if get_lava(meta) >= amount then return true end
  local result = logistica.use_bucket_for_liquid_in_network(pos, ItemStack(EMPTY_BUCKET), LAVA_LIQUID_NAME)
  if not result then return false end
  meta:set_int(META_LAVA, math.min(LAVA_MAX, get_lava(meta) + 1000))
  return get_lava(meta) >= amount
end

local function consume_lava(meta, amount)
  meta:set_int(META_LAVA, math.max(0, get_lava(meta) - amount))
end

local function pkey(p)
  return p.x .. "," .. p.y .. "," .. p.z
end

local function inv_has_any_room(inv)
  for _, stack in ipairs(inv:get_list(INV_MAIN)) do
    if stack:is_empty() then return true end
  end
  return false
end

local function has_leaves_upgrade(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:get_size(INV_UPGRADE) == 0 then return false end
  return inv:get_stack(INV_UPGRADE, 1):get_name() == LEAVES_UPGRADE
end

-- returns trunk_list, endpoints on success; nil, error_code on failure
local function scan_trunk(start_pos, tree_node_name)
  local visited = { [pkey(start_pos)] = true }
  local queue   = { start_pos }
  local trunk_list = {}
  local endpoints  = {}
  local base_y = start_pos.y

  while #queue > 0 do
    local cur = table.remove(queue, 1)
    table.insert(trunk_list, cur)

    if cur.y - base_y >= MAX_TRUNK_HEIGHT then return nil, RESULT_TOO_TALL end
    if #trunk_list > MAX_TOTAL_NODES       then return nil, RESULT_TOO_MANY end

    local added_any = false
    for _, d in ipairs(TRUNK_DIRS) do
      local npos = vector.add(cur, d)
      local key  = pkey(npos)
      if not visited[key] and minetest.get_node(npos).name == tree_node_name then
        visited[key] = true
        table.insert(queue, npos)
        added_any = true
      end
    end

    if not added_any then
      table.insert(endpoints, cur)
    end
  end

  return trunk_list, endpoints
end

local function find_most_common_leaf(endpoints)
  local counts = {}
  for _, ep in ipairs(endpoints) do
    local name = minetest.get_node(vector.new(ep.x, ep.y + 1, ep.z)).name
    if minetest.get_item_group(name, "leaves") > 0 then
      counts[name] = (counts[name] or 0) + 1
    end
  end

  local best_name, best_count = nil, 0
  for name, count in pairs(counts) do
    if count > best_count or (count == best_count and math.random(2) == 1) then
      best_name  = name
      best_count = count
    end
  end
  return best_name
end

-- returns leaf_list on success; nil, error_code on failure
local function scan_leaves(endpoints, leaf_node_name, trunk_count)
  local visited = {}
  local queue   = {}
  local leaf_list = {}

  for _, ep in ipairs(endpoints) do
    local above = vector.new(ep.x, ep.y + 1, ep.z)
    local key   = pkey(above)
    if not visited[key] and minetest.get_node(above).name == leaf_node_name then
      visited[key] = true
      table.insert(queue, above)
    end
  end

  while #queue > 0 do
    local cur = table.remove(queue, 1)
    table.insert(leaf_list, cur)

    if trunk_count + #leaf_list > MAX_TOTAL_NODES then break end

    for _, d in ipairs(LEAF_DIRS) do
      local npos = vector.add(cur, d)
      local key  = pkey(npos)
      if not visited[key] and minetest.get_node(npos).name == leaf_node_name then
        visited[key] = true
        table.insert(queue, npos)
      end
    end
  end

  return leaf_list
end

local function try_replant_sapling(sapling_name, tree_pos)
  logistica.load_position(tree_pos)
  if minetest.get_node(tree_pos).name ~= "air" then return end
  local below_pos = vector.new(tree_pos.x, tree_pos.y - 1, tree_pos.z)
  logistica.load_position(below_pos)
  local below_name = minetest.get_node(below_pos).name
  if below_name == "air" or below_name == "ignore" then return end
  local below_def = minetest.registered_nodes[below_name]
  if not below_def then return end
  local dt = below_def.drawtype
  if dt ~= nil and dt ~= "normal" then return end
  if minetest.get_item_group(below_name, "tree") > 0 then return end
  if minetest.get_item_group(below_name, "wood") > 0 then return end
  minetest.set_node(tree_pos, {name = sapling_name})
end

local schedule_next_cut
schedule_next_cut = function(machine_pos, enabled_name, gen, nodes, idx, trunk_name, leaf_name, leaves_cut, tree_pos, cut_base)
  leaves_cut = leaves_cut or 0
  cut_base   = cut_base or false
  if idx > #nodes then
    local meta = minetest.get_meta(machine_pos)
    if cut_base and tree_pos then
      local sapling = meta:get_string(META_SAVED_SAPLING)
      if sapling ~= "" then try_replant_sapling(sapling, tree_pos) end
    end
    meta:set_string(META_SAVED_SAPLING, "")
    meta:set_int(META_HARVEST_RESULT, 0)
    meta:set_int(META_IS_CUTTING, 0)
    logistica.update_cache_at_pos(machine_pos, LOG_CACHE_SUPPLIER)
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end

  minetest.after(CUT_DELAY, function()
    if minetest.get_node(machine_pos).name ~= enabled_name then return end
    local meta = minetest.get_meta(machine_pos)
    if meta:get_int(META_CUT_GEN) ~= gen then return end
    if not logistica.get_network_or_nil(machine_pos) then
      meta:set_int(META_IS_CUTTING, 0)
      meta:set_int(META_CUT_INTERRUPTED, 1)
      meta:set_int(META_CUT_GEN, meta:get_int(META_CUT_GEN) + 1)
      logistica.start_node_timer(machine_pos, CYCLE_TIME)
      return
    end

    local cut_pos  = nodes[idx]
    local cut_name = minetest.get_node(cut_pos).name

    if cut_name == "air" or cut_name == "ignore" then
      schedule_next_cut(machine_pos, enabled_name, gen, nodes, idx + 1, trunk_name, leaf_name, leaves_cut, tree_pos, cut_base)
      return
    end

    -- node changed to something unexpected; abort and let timer restart
    if cut_name ~= trunk_name and cut_name ~= leaf_name then
      meta:set_int(META_IS_CUTTING, 0)
      logistica.start_node_timer(machine_pos, CYCLE_TIME)
      return
    end

    -- determine lava cost: 1 per trunk, 1 per 10 leaves
    local is_leaf = leaf_name ~= nil and cut_name == leaf_name
    local new_leaves_cut = leaves_cut + (is_leaf and 1 or 0)
    local lava_cost = 0
    if is_leaf then
      if new_leaves_cut % 10 == 0 then lava_cost = 1 end
    else
      lava_cost = 1
    end

    if lava_cost > 0 and not has_lava(machine_pos, meta, lava_cost) then
      meta:set_int(META_IS_CUTTING, 0)
      logistica.start_node_timer(machine_pos, CYCLE_TIME)
      return
    end

    local inv   = meta:get_inventory()
    local drops = minetest.get_node_drops(cut_name, "")

    local skip_sapling = nil
    if tree_pos and meta:get_string(META_SAVED_SAPLING) == "" then
      for _, drop in ipairs(drops) do
        if drop and drop ~= "" and minetest.get_item_group(drop, "sapling") > 0 then
          skip_sapling = drop
          meta:set_string(META_SAVED_SAPLING, drop)
          break
        end
      end
    end

    local skip_used = false
    for _, drop in ipairs(drops) do
      if drop and drop ~= "" then
        if skip_sapling and not skip_used and drop == skip_sapling then
          skip_used = true
        elseif not inv:room_for_item(INV_MAIN, ItemStack(drop)) then
          meta:set_int(META_HARVEST_RESULT, RESULT_INV_FULL)
          meta:set_int(META_IS_CUTTING, 0)
          return
        end
      end
    end

    if lava_cost > 0 then consume_lava(meta, lava_cost) end
    skip_used = false
    for _, drop in ipairs(drops) do
      if drop and drop ~= "" then
        if skip_sapling and not skip_used and drop == skip_sapling then
          skip_used = true
        else
          inv:add_item(INV_MAIN, ItemStack(drop))
        end
      end
    end
    minetest.set_node(cut_pos, {name = "air"})

    local is_base = tree_pos ~= nil and
      cut_pos.x == tree_pos.x and cut_pos.y == tree_pos.y and cut_pos.z == tree_pos.z
    schedule_next_cut(machine_pos, enabled_name, gen, nodes, idx + 1, trunk_name, leaf_name, new_leaves_cut, tree_pos, cut_base or is_base)
  end)
end

local function start_harvest(machine_pos, enabled_name)
  if not logistica.get_network_or_nil(machine_pos) then
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end

  local meta = minetest.get_meta(machine_pos)
  local inv  = meta:get_inventory()

  if not inv_has_any_room(inv) then
    meta:set_int(META_HARVEST_RESULT, RESULT_INV_FULL)
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end

  local node = minetest.get_node(machine_pos)
  local dirs = logistica.get_rot_directions(node.param2)
  if not dirs then
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end

  local tree_pos  = vector.add(machine_pos, dirs.backward)
  local tree_name = minetest.get_node(tree_pos).name

  if minetest.get_item_group(tree_name, "tree") == 0 then
    meta:set_int(META_HARVEST_RESULT, RESULT_NO_TREE)
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end

  local trunk_list, result = scan_trunk(tree_pos, tree_name)
  if not trunk_list then
    meta:set_int(META_HARVEST_RESULT, result)
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end
  local endpoints = result

  local leaf_list = {}
  local expected_leaf_name = nil
  if has_leaves_upgrade(machine_pos) then
    expected_leaf_name = find_most_common_leaf(endpoints)
    if expected_leaf_name then
      leaf_list = scan_leaves(endpoints, expected_leaf_name, #trunk_list)
    end
  end

  table.sort(leaf_list,  function(a, b) return a.y > b.y end)
  table.sort(trunk_list, function(a, b) return a.y > b.y end)

  local all_nodes = {}
  for _, p in ipairs(leaf_list)  do table.insert(all_nodes, p) end
  for _, p in ipairs(trunk_list) do table.insert(all_nodes, p) end

  if #all_nodes == 0 then
    logistica.start_node_timer(machine_pos, CYCLE_TIME)
    return
  end

  local gen = meta:get_int(META_CUT_GEN) + 1
  local was_interrupted = meta:get_int(META_CUT_INTERRUPTED) == 1
  meta:set_int(META_CUT_GEN, gen)
  meta:set_int(META_IS_CUTTING, 1)
  meta:set_int(META_HARVEST_RESULT, 0)
  meta:set_int(META_CUT_INTERRUPTED, 0)
  if not was_interrupted then
    meta:set_string(META_SAVED_SAPLING, "")
  end

  local sapling_tree_pos = has_leaves_upgrade(machine_pos) and tree_pos or nil
  schedule_next_cut(machine_pos, enabled_name, gen, all_nodes, 1, tree_name, expected_leaf_name, 0, sapling_tree_pos, false)
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function logistica.woodcutter_on_timer(pos, _elapsed)
  if not logistica.is_machine_on(pos) then return false end
  start_harvest(pos, minetest.get_node(pos).name)
  return false
end

function logistica.woodcutter_on_power(pos, _power)
  local meta = minetest.get_meta(pos)
  if meta:get_int(META_IS_CUTTING) == 1 then
    meta:set_int(META_CUT_INTERRUPTED, 1)
  end
  meta:set_int(META_IS_CUTTING, 0)
  meta:set_int(META_CUT_GEN, meta:get_int(META_CUT_GEN) + 1)
  logistica.set_node_tooltip_from_state(pos)
  logistica.start_node_timer(pos, CYCLE_TIME)
end

function logistica.woodcutter_get_harvest_result(pos)
  return minetest.get_meta(pos):get_int(META_HARVEST_RESULT)
end

function logistica.woodcutter_is_cutting(pos)
  return minetest.get_meta(pos):get_int(META_IS_CUTTING) == 1
end

function logistica.woodcutter_get_lava(pos)
  return minetest.get_meta(pos):get_int(META_LAVA)
end

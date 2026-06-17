
logistica.AP_UPGRADE_LIST            = "ac_upg"
logistica.AP_UPGRADE_ITEM            = "logistica:autocrafting_upgrade"
logistica.AP_RECURSIVE_UPGRADE_ITEM  = "logistica:autocrafting_recursive_upgrade"

local AP_UPGRADE_LIST           = logistica.AP_UPGRADE_LIST
local AP_UPGRADE_ITEM           = logistica.AP_UPGRADE_ITEM
local AP_RECURSIVE_UPGRADE_ITEM = logistica.AP_RECURSIVE_UPGRADE_ITEM

local ac_index = nil
local group_to_items = {}

local function build_group_lookup()
  group_to_items = {}
  for iname, def in pairs(minetest.registered_items) do
    if def.groups then
      for g in pairs(def.groups) do
        if not group_to_items[g] then group_to_items[g] = {} end
        group_to_items[g][#group_to_items[g] + 1] = iname
      end
    end
  end
  for _, list in pairs(group_to_items) do table.sort(list) end
end

local function get_number_of_items_in_group(gname)
  local members = group_to_items[gname]
  return members and #members or 0
end

local function process_item_recipes(name, def)
  local all_recipes = minetest.get_all_craft_recipes(name)
  if not all_recipes then return end
  local valid = {}
  for _, recipe in ipairs(all_recipes) do
    if recipe.method == "normal" then
      local out = ItemStack(recipe.output)
      local out_name  = out:get_name()
      local out_count = math.max(1, out:get_count())
      local skip = false
      local seen_groups = {}
      local unique_group_count = 0
      local resolved_items = {}
      for i = 1, 9 do
        local s = recipe.items[i]
        resolved_items[i] = s
        if s and s ~= "" and s:sub(1, 6) == "group:" then
          local gname, rest = s:match("^group:(%S+)(.*)")
          local n = gname and get_number_of_items_in_group(gname) or 0
          if n == 0 then
            skip = true; break
          elseif n == 1 then
            resolved_items[i] = group_to_items[gname][1] .. rest
          elseif not seen_groups[gname] then
            seen_groups[gname] = true
            unique_group_count = unique_group_count + 1
            if unique_group_count > 1 then skip = true; break end
          end
        end
      end
      if not skip then
        valid[#valid + 1] = {
          raw_items    = resolved_items,
          width        = recipe.width,
          output_name  = out_name,
          output_count = out_count,
        }
      end
    end
  end
  if #valid == 0 then return end
  local desc = def.description or name
  desc = desc:match("^([^\n]+)") or desc
  ac_index[name] = { desc = desc, recipes = valid }
end

local function build_index()
  ac_index = {}
  build_group_lookup()
  for name, def in pairs(minetest.registered_items) do
    if not (def.groups and tonumber(def.groups.not_in_creative_inventory or 0) > 0) then
      process_item_recipes(name, def)
    end
  end
end

minetest.register_on_mods_loaded(build_index)

-- Resolves group slots in recipe.raw_items to concrete items greedily,
-- picking the group member with the most available stock.
-- virtual: optional lazy-cache map (item_name -> count), used read-only for scoring.
-- player: optional; player inventory is also checked when scoring group members.
-- Returns counts (item_name -> total needed), resolved_raw (9-slot concrete list),
-- or nil if any required group has no members.
local function get_recipe_counts(recipe, virtual, network, player)
  local group_choice = {}
  local counts = {}
  local resolved_raw = {}

  for i = 1, 9 do
    local s = recipe.raw_items[i]
    if s and s ~= "" then
      if s:sub(1, 6) == "group:" then
        local gname, rest = s:match("^group:(%S+)(.*)")
        if not group_choice[gname] then
          local members = group_to_items[gname]
          if not members or #members == 0 then return nil end
          local best_item, best_count = nil, -1
          for _, member in ipairs(members) do
            local have = virtual and virtual[member]
            if have == nil then
              have = logistica.count_items_in_network(member, network, true)
            end
            if player then have = have + logistica.ac_count_in_player_inv(player, member) end
            if have > best_count then best_count = have; best_item = member end
          end
          if not best_item then return nil end
          group_choice[gname] = best_item
        end
        local resolved = group_choice[gname] .. rest
        resolved_raw[i] = resolved
        local st = ItemStack(resolved)
        local n = st:get_name()
        if n ~= "" then counts[n] = (counts[n] or 0) + st:get_count() end
      else
        resolved_raw[i] = s
        local st = ItemStack(s)
        local n = st:get_name()
        if n ~= "" then counts[n] = (counts[n] or 0) + st:get_count() end
      end
    end
  end

  return counts, resolved_raw
end

-- Word-prefix search: each space-separated token must be a prefix of some word
-- in the description. E.g. "no br" matches "Node Breaker".
-- Returns a list of {name, desc, recipes} sorted alphabetically by desc.
function logistica.ac_search(query)
  if not ac_index then return {} end
  local results = {}
  if not query or query:gsub("%s+", "") == "" then
    for name, entry in pairs(ac_index) do
      results[#results + 1] = { name = name, desc = entry.desc, recipes = entry.recipes }
    end
  else
    local tokens = {}
    for t in query:lower():gmatch("%S+") do tokens[#tokens + 1] = t end
    for name, entry in pairs(ac_index) do
      local words = {}
      for w in entry.desc:lower():gmatch("%S+") do words[#words + 1] = w end
      for part in name:lower():gmatch("[^:_]+") do words[#words + 1] = part end
      local match = true
      for _, tok in ipairs(tokens) do
        local found = false
        for _, word in ipairs(words) do
          if word:sub(1, #tok) == tok then found = true; break end
        end
        if not found then match = false; break end
      end
      if match then
        results[#results + 1] = { name = name, desc = entry.desc, recipes = entry.recipes }
      end
    end
  end
  table.sort(results, function(a, b) return a.desc < b.desc end)
  return results
end

local function count_in_player_inv(player, item_name)
  local count = 0
  for _, stack in ipairs(player:get_inventory():get_list("main") or {}) do
    if stack:get_name() == item_name then count = count + stack:get_count() end
  end
  return count
end

logistica.ac_count_in_player_inv = count_in_player_inv

-- Returns the max number of times recipe can be crafted.
-- Pass player + use_player_inv=true to include the player's inventory in the count.
function logistica.ac_get_max_craftable(recipe, network, player, use_player_inv)
  local counts = get_recipe_counts(recipe, nil, network, use_player_inv and player or nil)
  if not counts then return 0 end
  local min_times = math.huge
  for item_name, needed in pairs(counts) do
    local have = logistica.count_items_in_network(item_name, network, true)
    if use_player_inv and player then
      have = have + count_in_player_inv(player, item_name)
    end
    local times = math.floor(have / needed)
    if times < min_times then min_times = times end
  end
  return min_times == math.huge and 0 or min_times
end

-- Craft recipe up to `count` times, placing output in the detached ac_output inventory.
-- With use_player_inv=true, takes from network first then player inventory for remainder.
-- Returns crafted_count, error_msg.
function logistica.ac_craft(recipe, networkId, player, count, use_player_inv, pos)
  local network = logistica.get_network_by_id_or_nil(networkId)
  if not network then return 0, "No network" end
  local player_inv = player:get_inventory()
  local out_inv = logistica.get_ac_output_inv(pos)
  local crafted = 0

  local function refund(taken)
    for _, st in ipairs(taken) do
      local remaining = logistica.insert_item_in_network(st, networkId, false, true, false, false, false, true)
      if remaining > 0 then
        st:set_count(remaining)
        minetest.item_drop(st, player, player:get_pos())
      end
    end
  end

  local function give_or_drop(st)
    if st:is_empty() then return end
    local remaining = logistica.insert_item_in_network(st, networkId, false, true, false, false, false, true)
    if remaining > 0 then
      st:set_count(remaining)
      local leftover = out_inv:add_item("ac_output", st)
      if not leftover:is_empty() then minetest.item_drop(leftover, player, player:get_pos()) end
    end
  end

  for _ = 1, count do
    local out_st = ItemStack(recipe.output_name)
    out_st:set_count(recipe.output_count)
    if not out_inv:room_for_item("ac_output", out_st) then
      return crafted, "Output full"
    end

    local counts, resolved_raw = get_recipe_counts(recipe, nil, network, use_player_inv and player or nil)
    if not counts then break end

    -- plan how much to take from network vs player for each ingredient
    local plan = {}
    local can_craft = true
    for item_name, needed in pairs(counts) do
      local net_have = logistica.count_items_in_network(item_name, network, true)
      local from_net = math.min(needed, net_have)
      local from_plr = needed - from_net
      if from_plr > 0 then
        if not use_player_inv or count_in_player_inv(player, item_name) < from_plr then
          can_craft = false; break
        end
      end
      plan[item_name] = { net = from_net, plr = from_plr }
    end
    if not can_craft then break end

    -- take per plan: network first, then player inventory; refund on failure
    local taken = {}
    local take_ok = true
    for item_name, amounts in pairs(plan) do
      if amounts.net > 0 then
        local take_st = ItemStack(item_name)
        take_st:set_count(amounts.net)
        local ok = logistica.take_stack_from_network(
          take_st, network,
          function(st) taken[#taken + 1] = st; return 0 end,
          false, false, false)
        if not ok.success then
          refund(taken); take_ok = false; break
        end
      end
      if amounts.plr > 0 then
        local rem_st = ItemStack(item_name)
        rem_st:set_count(amounts.plr)
        local removed = player_inv:remove_item("main", rem_st)
        if removed:get_count() < amounts.plr then
          player_inv:add_item("main", removed)  -- put partial back
          refund(taken); take_ok = false; break
        end
      end
    end
    if not take_ok then break end

    -- build craft grid and execute
    local craft_items = {}
    for i = 1, 9 do
      local s = resolved_raw[i]
      craft_items[i] = (s and s ~= "") and ItemStack(s) or ItemStack("")
    end
    local output, decremented = minetest.get_craft_result({
      method = "normal", width = recipe.width, items = craft_items,
    })

    if not output or output.item:is_empty() then
      refund(taken); break
    end

    local leftover = out_inv:add_item("ac_output", output.item)
    if not leftover:is_empty() then
      refund(taken)
      return crafted, "Output full"
    end

    for _, repl in ipairs(output.replacements or {}) do give_or_drop(repl) end
    for _, st   in ipairs(decremented.items   or {}) do give_or_drop(st) end

    crafted = crafted + 1
  end

  logistica.sync_ac_output_to_meta(pos)
  return crafted, nil
end

-- Returns the index entry for item_name, or nil if not craftable.
function logistica.ac_get_entry(name)
  return ac_index and ac_index[name]
end

-- Returns display info for all 9 recipe slots for the crafting grid UI.
-- Resolves groups greedily (same logic as crafting) to pick a representative item.
-- Each non-empty slot returns: {display_item, have, need, is_group, group_name}.
--   display_item: concrete item name to show (representative member for group slots).
--   have:         total available in network (+player if provided).
--   need:         total of that resolved item needed across all slots in the recipe.
--   is_group:     true if the slot was a group: entry.
--   group_name:   group name string (only set when is_group is true).
function logistica.ac_get_recipe_slot_display(recipe, network, player)
  local counts, resolved_raw = get_recipe_counts(recipe, nil, network, player)
  local slots = {}
  if not counts then return slots end
  for i = 1, 9 do
    local s = recipe.raw_items[i]
    if s and s ~= "" then
      local is_group = s:sub(1, 6) == "group:"
      local gname = is_group and s:match("^group:(%S+)") or nil
      local resolved = resolved_raw[i]
      local rname = resolved and ItemStack(resolved):get_name() or ""
      if rname ~= "" then
        local need = counts[rname] or 1
        local have = logistica.count_items_in_network(rname, network, true)
        if player then have = have + logistica.ac_count_in_player_inv(player, rname) end
        slots[i] = { display_item = rname, have = have, need = need,
                     is_group = is_group, group_name = gname }
      end
    end
  end
  return slots
end

-- Returns true if any crafting upgrade (basic or recursive) is installed in the AP at pos.
function logistica.ac_has_upgrade(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:contains_item(AP_UPGRADE_LIST, ItemStack(AP_UPGRADE_ITEM))
    or inv:contains_item(AP_UPGRADE_LIST, ItemStack(AP_RECURSIVE_UPGRADE_ITEM))
end

-- Returns true if the recursive crafting upgrade is installed in the AP at pos.
function logistica.ac_has_recursive_upgrade(pos)
  return minetest.get_meta(pos):get_inventory():contains_item(
    AP_UPGRADE_LIST, ItemStack(AP_RECURSIVE_UPGRADE_ITEM))
end

local AP_SYNC_KEY_1 = "synced1"
local AP_SYNC_KEY_2 = "synced2"
local AP_SYNC_VAL_1 = 10
local AP_SYNC_VAL_2 = 20

function logistica.ac_has_synced_recursive_upgrade(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  local stack = inv:get_stack(AP_UPGRADE_LIST, 1)
  return logistica.ac_is_upgrade_synced(stack)
end

function logistica.ac_is_upgrade_synced(stack)
  if stack:get_name() ~= AP_RECURSIVE_UPGRADE_ITEM then return false end
  local meta = stack:get_meta()
  return meta:get_int(AP_SYNC_KEY_1) == AP_SYNC_VAL_1
    and meta:get_int(AP_SYNC_KEY_2) == AP_SYNC_VAL_2
end

function logistica.ac_sync_upgrade(stack)
  local meta = stack:get_meta()
  local baseDesc = minetest.registered_items[AP_RECURSIVE_UPGRADE_ITEM].description
  if meta:get_int(AP_SYNC_KEY_1) ~= AP_SYNC_VAL_1 then
    meta:set_int(AP_SYNC_KEY_1, AP_SYNC_VAL_1)
    meta:set_string("description",
      baseDesc .. "\n" .. minetest.colorize("#FFFF00", "Partially Synchronized"))
  else
    meta:set_int(AP_SYNC_KEY_2, AP_SYNC_VAL_2)
    meta:set_string("description",
      baseDesc .. "\n" .. minetest.colorize("#44FF44", "Synchronized"))
  end
end

-- Recursive autocrafting planner -----------------------------------------------

local function shallow_copy(t)
  local c = {}
  for k, v in pairs(t) do c[k] = v end
  return c
end

-- Recursively plans to satisfy `count` of `item_name` from virtual storage.
-- `virtual`: lazily-populated map of item_name -> remaining available count;
--   mutated in place on success, restored on failure.
-- `expanding`: set of item names currently in the call stack (cycle detection).
-- Returns queue, nil on success; nil, missing_item_name on failure.
local function plan_item(item_name, count, virtual, expanding, network)
  if virtual[item_name] == nil then
    virtual[item_name] = logistica.count_items_in_network(item_name, network, true)
  end
  local have = virtual[item_name]

  if have >= count then
    virtual[item_name] = have - count
    return {}
  end

  if expanding[item_name] then return nil, item_name end
  local entry = ac_index[item_name]
  if not entry then return nil, item_name end

  local still_need = count - have
  virtual[item_name] = 0
  expanding[item_name] = true

  local recipes_to_try = entry.recipes
  if #entry.recipes > 1 then
    local scored = {}
    for _, recipe in ipairs(entry.recipes) do
      local crafts = math.ceil(still_need / recipe.output_count)
      local score = 0
      local rcounts = get_recipe_counts(recipe, virtual, network)
      if rcounts then
        for ingr_name, ingr_count in pairs(rcounts) do
          local ingr_have = virtual[ingr_name]
          if ingr_have == nil then
            ingr_have = logistica.count_items_in_network(ingr_name, network, true)
          end
          if ingr_have >= ingr_count * crafts then score = score + 1 end
        end
      end
      scored[#scored + 1] = { recipe = recipe, score = score }
    end
    table.sort(scored, function(a, b) return a.score > b.score end)
    recipes_to_try = {}
    for _, s in ipairs(scored) do recipes_to_try[#recipes_to_try + 1] = s.recipe end
  end

  local last_missing = item_name
  for _, recipe in ipairs(recipes_to_try) do
    local crafts = math.ceil(still_need / recipe.output_count)
    local rcounts = get_recipe_counts(recipe, virtual, network)
    if rcounts then
      local v_snap = shallow_copy(virtual)
      local queue = {}
      local ok = true
      for ingr_name, ingr_count in pairs(rcounts) do
        local sub_q, missing = plan_item(ingr_name, ingr_count * crafts, virtual, expanding, network)
        if not sub_q then ok = false; last_missing = missing or ingr_name; break end
        for _, q_item in ipairs(sub_q) do queue[#queue + 1] = q_item end
      end
      if ok then
        local surplus = (crafts * recipe.output_count) - still_need
        virtual[item_name] = surplus
        for _ = 1, crafts do queue[#queue + 1] = item_name end
        expanding[item_name] = nil
        return queue
      end
      for k in pairs(virtual) do virtual[k] = nil end
      for k, v in pairs(v_snap) do virtual[k] = v end
    end
  end

  expanding[item_name] = nil
  virtual[item_name] = have
  return nil, last_missing
end

-- Takes `count` of `item_name` from mass storage and normal suppliers only
-- (matching what count_items_in_network counts). Appends taken stacks to `taken`.
-- Returns true if the full count was collected.
local function take_from_storage_only(item_name, count, network, taken)
  local collected = 0
  local collector = function(st)
    taken[#taken + 1] = st
    collected = collected + st:get_count()
    return 0
  end

  local mass_stack = ItemStack(item_name)
  mass_stack:set_count(count)
  logistica.take_stack_from_mass_storage(mass_stack, network, collector, false, false)

  local still_need = count - collected
  if still_need <= 0 then return true end

  local supp_stack = ItemStack(item_name)
  supp_stack:set_count(still_need)
  logistica.take_stack_from_suppliers(supp_stack, network, collector, false, false, false, 0, "normal")

  return (count - collected) <= 0
end

-- Executes a plan returned by ac_plan_recursive: takes items from storage (no
-- crafting suppliers). On success returns plan.output (the ItemStack to deliver);
-- on failure refunds all taken items and returns nil + error string.
-- nodePos is used as the drop position if refunded items cannot fit back in the network.
function logistica.ac_execute_plan(plan, networkId, nodePos)
  local network = logistica.get_network_by_id_or_nil(networkId)
  if not network then return nil, "No network" end

  local taken = {}

  local function refund()
    for _, st in ipairs(taken) do
      local remaining = logistica.insert_item_in_network(st, networkId, false, true, false, false, false, true)
      if remaining > 0 then
        st:set_count(remaining)
        minetest.item_drop(st, nil, nodePos)
      end
    end
  end

  for item_name, count in pairs(plan.to_take) do
    if not take_from_storage_only(item_name, count, network, taken) then
      refund()
      return nil, "Not enough materials"
    end
  end

  return plan.output, nil
end

local function item_short_desc(name)
  local def = minetest.registered_items[name]
  if not def or not def.description then return name end
  return (def.description:match("^([^\n]+)") or def.description)
end

-- Plans a recursive craft of `item_name` repeated `count` times against `network`.
-- Tries all recipes for item_name at the top level and returns the plan with the
-- shortest craft queue. Sub-item recipes prefer the recipe with most ingredients
-- available in storage. Returns a plan table on success, or nil + error string on
-- failure.
--   plan.to_take: {item_name -> count} to remove from network storage upfront.
--   plan.queue:   ordered list of item names to craft, bottom-to-top,
--                 including `count` entries of the top item at the end.
--   plan.output:  ItemStack of the final output (what ac_execute_plan returns on success).
function logistica.ac_plan_recursive(item_name, count, network)
  local entry = ac_index[item_name]
  if not entry or #entry.recipes == 0 then return nil, "Not enough materials" end

  local best_plan = nil
  local last_missing_name = nil
  local last_missing_count = nil

  for _, recipe in ipairs(entry.recipes) do
    local virtual = {}
    local rcounts = get_recipe_counts(recipe, virtual, network)
    if rcounts then
      local queue = {}
      local ok = true

      for ingr_name, ingr_count in pairs(rcounts) do
        local needed = ingr_count * count
        local sub_q, missing = plan_item(ingr_name, needed, virtual, {}, network)
        if not sub_q then
          ok = false; last_missing_name = ingr_name; last_missing_count = needed; break
        end
        for _, q_item in ipairs(sub_q) do queue[#queue + 1] = q_item end
      end

      if ok then
        local to_take = {}
        for iname, remaining in pairs(virtual) do
          local original = logistica.count_items_in_network(iname, network, true)
          if original > remaining then
            to_take[iname] = original - remaining
          end
        end
        for _ = 1, count do queue[#queue + 1] = item_name end
        local output = ItemStack(item_name)
        output:set_count(recipe.output_count * count)
        local plan = { to_take = to_take, queue = queue, output = output }
        if best_plan == nil or #queue < #best_plan.queue then
          best_plan = plan
        end
      end
    end
  end

  if best_plan then return best_plan, nil end
  if last_missing_name then
    return nil, "NOT ENOUGH FOR: " .. last_missing_count .. "x " .. item_short_desc(last_missing_name)
  end
  return nil, "Not enough materials"
end

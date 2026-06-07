
logistica.AP_UPGRADE_LIST = "ac_upg"
logistica.AP_UPGRADE_ITEM = "logistica:autocrafting_upgrade"

local AP_UPGRADE_LIST = logistica.AP_UPGRADE_LIST
local AP_UPGRADE_ITEM = logistica.AP_UPGRADE_ITEM

local ac_index = nil

local function has_group_ingredient(items)
  for i = 1, 9 do
    local s = items[i]
    if s and s ~= "" and s:sub(1, 6) == "group:" then return true end
  end
  return false
end

local function aggregate_ingredients(items)
  local counts = {}
  for i = 1, 9 do
    local s = items[i]
    if s and s ~= "" then
      local st = ItemStack(s)
      local n = st:get_name()
      if n ~= "" then counts[n] = (counts[n] or 0) + st:get_count() end
    end
  end
  return counts
end

local function process_item_recipes(name, def)
  local all_recipes = minetest.get_all_craft_recipes(name)
  if not all_recipes then return end
  local valid = {}
  for _, recipe in ipairs(all_recipes) do
    if recipe.method == "normal" and not has_group_ingredient(recipe.items) then
      local out = ItemStack(recipe.output)
      valid[#valid + 1] = {
        items        = aggregate_ingredients(recipe.items),
        raw_items    = recipe.items,
        width        = recipe.width,
        output_name  = out:get_name(),
        output_count = math.max(1, out:get_count()),
      }
    end
  end
  if #valid == 0 then return end
  local desc = def.description or name
  desc = desc:match("^([^\n]+)") or desc
  ac_index[name] = { desc = desc, recipes = valid }
end

local function build_index()
  ac_index = {}
  local all = {}
  for n, d in pairs(minetest.registered_nodes)      do all[n] = d end
  for n, d in pairs(minetest.registered_craftitems) do all[n] = d end
  for n, d in pairs(minetest.registered_tools)      do all[n] = d end
  for name, def in pairs(all) do process_item_recipes(name, def) end
end

minetest.register_on_mods_loaded(build_index)

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
  local min_times = math.huge
  for item_name, needed in pairs(recipe.items) do
    local have = logistica.count_items_in_network(item_name, network, true)
    if use_player_inv and player then
      have = have + count_in_player_inv(player, item_name)
    end
    local times = math.floor(have / needed)
    if times < min_times then min_times = times end
  end
  return min_times == math.huge and 0 or min_times
end

-- Craft recipe up to `count` times, placing output directly in player inventory.
-- With use_player_inv=true, takes from network first then player inventory for remainder.
-- Returns crafted_count, error_msg.
function logistica.ac_craft(recipe, networkId, player, count, use_player_inv)
  local network = logistica.get_network_by_id_or_nil(networkId)
  if not network then return 0, "No network" end
  local player_inv = player:get_inventory()
  local crafted = 0

  local function refund(taken)
    for _, st in ipairs(taken) do
      local leftover = logistica.insert_item_in_network(st, networkId, false, true, false, false, false, true)
      if leftover and not leftover:is_empty() then
        minetest.item_drop(leftover, player, player:get_pos())
      end
    end
  end

  local function give_or_drop(st)
    if st:is_empty() then return end
    local leftover = logistica.insert_item_in_network(st, networkId, false, true, false, false, false, true)
    if leftover and not leftover:is_empty() then
      leftover = player_inv:add_item("main", leftover)
      if not leftover:is_empty() then minetest.item_drop(leftover, player, player:get_pos()) end
    end
  end

  for _ = 1, count do
    local out_st = ItemStack(recipe.output_name)
    out_st:set_count(recipe.output_count)
    if not player_inv:room_for_item("main", out_st) then
      return crafted, "Inventory full"
    end

    -- plan how much to take from network vs player for each ingredient
    local plan = {}
    local can_craft = true
    for item_name, needed in pairs(recipe.items) do
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
      local s = recipe.raw_items[i]
      craft_items[i] = (s and s ~= "") and ItemStack(s) or ItemStack("")
    end
    local output, decremented = minetest.get_craft_result({
      method = "normal", width = recipe.width, items = craft_items,
    })

    if not output or output.item:is_empty() then
      refund(taken); break
    end

    local leftover = player_inv:add_item("main", output.item)
    if not leftover:is_empty() then
      refund(taken)
      return crafted, "Inventory full"
    end

    for _, repl in ipairs(output.replacements or {}) do give_or_drop(repl) end
    for _, st   in ipairs(decremented.items   or {}) do give_or_drop(st) end

    crafted = crafted + 1
  end

  return crafted, nil
end

-- Returns the index entry for item_name, or nil if not craftable.
function logistica.ac_get_entry(name)
  return ac_index and ac_index[name]
end

-- Returns true if the autocrafting upgrade is installed in the AP at pos.
function logistica.ac_has_upgrade(pos)
  return minetest.get_meta(pos):get_inventory():contains_item(
    AP_UPGRADE_LIST, ItemStack(AP_UPGRADE_ITEM))
end

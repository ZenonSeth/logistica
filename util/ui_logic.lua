local disallowedPull = {}

local allowedPull = {
    ["main"] = true,
    --["src"] = true,
    ["dst"] = true,
    ["output"] = true
    --["fuel"] = true,
}

local allowedPush = {
    ["main"] = true,
    ["src"] = true,
    ["fuel"] = true,
    ["input"] = true,
    ["shift"] = true
}

local disallowedPush = {
    ["techage:ta4_recipeblock"] = {["input"] = true},
    ["techage:ta4_pusher_pas"] = {["main"] = true},
    ["techage:ta4_pusher_act"] = {["main"] = true},
    ["techage:ta5_hl_chest"] = {["main"] = true},
    ["techage:ta3_doorcontroller2"] = {["main"] = true},
    ["techage:ta4_movecontroller2"] = {["main"] = true}
}

local disallowedPull = {
    ["techage:ta2_autocrafter_pas"] = {["output"] = true},
    ["techage:ta2_autocrafter_act"] = {["output"] = true},
    ["techage:ta3_autocrafter_pas"] = {["output"] = true},
    ["techage:ta3_autocrafter_act"] = {["output"] = true},
    ["techage:ta4_autocrafter_pas"] = {["output"] = true},
    ["techage:ta4_autocrafter_act"] = {["output"] = true},
    ["techage:ta4_recipeblock"] = {["output"] = true},
    ["techage:ta4_pusher_pas"] = {["main"] = true},
    ["techage:ta4_pusher_act"] = {["main"] = true},
    ["techage:ta5_hl_chest"] = {["main"] = true},
    ["techage:ta3_doorcontroller2"] = {["main"] = true},
    ["techage:ta4_movecontroller2"] = {["main"] = true}
}

-- this MUST be a subset of the allowed push list above
local logisticaBucketEmptierAllowedPush = {
    ["input"] = true
}

local function get_lists(targetPosition, usePushLists)
    logistica.load_position(targetPosition)
    local node = minetest.get_node(targetPosition)

    local allowedLists = {}
    local disallowedList
    if logistica.GROUPS.bucket_emptiers.is(node.name) then
        if usePushLists then
            allowedLists = logisticaBucketEmptierAllowedPush
        else
            return {}
        end -- can only push to bucket emptier, it acts as a supplier so no need to pull
    elseif logistica.is_machine(node.name) then
        return {}
    elseif usePushLists then
        disallowedList = disallowedPush[node.name] or {}
        allowedLists = allowedPush
    else
        disallowedList = disallowedPull[node.name] or {}
        allowedLists = allowedPull
    end

    local availableLists = minetest.get_meta(targetPosition):get_inventory():get_lists()
    local lists = {}
    for name, _ in pairs(availableLists) do
        if allowedLists[name] and not disallowedList[name] then
            table.insert(lists, name)
        end
    end
    return lists
end

----------------------------------------------------------------
-- API
----------------------------------------------------------------

-- returns a string of comma separated lists allowed to push to at the given position
function logistica.get_push_lists(targetPosition)
    return get_lists(targetPosition, true)
end

-- returns a string of comma separated lists allowed to pull to at the given position
function logistica.get_pull_lists(targetPosition)
    return get_lists(targetPosition, false)
end

function logistica.is_allowed_pull_list(pos, listName)
    local targetNode = minetest.get_node(logistica.get_injector_target(pos))
    local disallowedList = disallowedPull[targetNode.name]
    return (allowedPull[listName] == true) and
            not (disallowedList and disallowedList[listName] == true)
end

function logistica.is_allowed_push_list(pos, listName)
    local targetNode = minetest.get_node(logistica.get_requester_target(pos))
    local disallowedList = disallowedPush[targetNode.name]
    return (allowedPush[listName] == true) and
            not (disallowedList and disallowedList[listName] == true)
end

function logistica.add_allowed_push_list(listName)
    if not listName then
        return
    end
    allowedPush[listName] = true
end

function logistica.add_allowed_pull_list(listName)
    if not listName then
        return
    end
    allowedPull[listName] = true
end

-- a safer way to get inv list, returns an empty table if something goes wrong
function logistica.get_list(inventory, listName)
    if not inventory or not listName or type(listName) ~= "string" then
        return {}
    end
    return inventory:get_list(listName) or {}
end

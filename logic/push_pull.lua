local M_SCAN_POS = "logistica_scanpos"

-- attempts to take 1 item from the targetMeta, rotating over all slots
function logistica.get_item(pullerMeta, targetMeta, listname)
	if targetMeta == nil or targetMeta.get_inventory == nil then return nil end
	local inv = targetMeta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	local startpos = pullerMeta:get_int(M_SCAN_POS) or 0
	for i = startpos, startpos + size do
		i = (i % size) + 1
		local items = inv:get_stack(listname, inv)
		if items:get_count() > 0 then
			local taken = items:take_item(1)
			inv:set_stack(listname, i, items)
			pullerMeta:set_int(M_SCAN_POS, i)
			return taken
		end
	end
	pullerMeta:set_int("tubelib_startpos", 0)
	return nil
end

function logistica.get_specific_item(meta, listname, slotNumber, numItems)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end

	if numItems == nil then numItems = 1 end
	local items = inv:get_stack(listname, slotNumber)
	if items:get_count() > 0 then
		local taken = items:take_item(numItems)
		inv:set_stack(listname, slotNumber, items)
		return taken
	end
	return nil
end


-- Try to put item in list, returns false if failed, true otherwise
function logistica.put_item(meta, listname, item)
	if meta == nil or meta.get_inventory == nil then return false end
	local inv = meta:get_inventory()
	if inv:room_for_item(listname, item) then
		inv:add_item(listname, item)
		return true
	end
	return false
end

-- Take the number of items from the given ItemList.
-- Returns nil if the requested number is not available.
function logistica.get_num_items(meta, listname, num)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	for idx = 1, size do
		local items = inv:get_stack(listname, idx)
		if items:get_count() >= num then
			local taken = items:take_item(num)
			inv:set_stack(listname, idx, items)
			return taken
		end
	end
	return nil
end

function logistica.get_stack(pullerMeta, targetMeta, listname)
	local inv = targetMeta:get_inventory()
	local item = logistica.get_item(pullerMeta, targetMeta, listname)
	if item and item:get_stack_max() > 1 and inv:contains_item(listname, item) then
		-- try to remove a complete stack
		item:set_count(math.min(98, item:get_stack_max() - 1))
		local taken = inv:remove_item(listname, item)
		-- add the already removed
		taken:set_count(taken:get_count() + 1)
		return taken
	end
	return item
end

-- Return "full", "loaded", or "empty" depending
-- on the number of fuel stack items.
-- Function only works on fuel inventories with one stacks/99 items
function logistica.fuelstate(meta, listname, item)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return "empty"
	end
	local list = inv:get_list(listname)
	if #list == 1 and list[1]:get_count() == 99 then
		return "full"
	else
		return "loaded"
	end
end

-- Return "full", "loaded", or "empty" depending
-- on the inventory load.
-- Full is returned, when no empty stack is available.
function logistica.get_inv_state(meta, listname)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	local state
    if inv:is_empty(listname) then
        state = "empty"
    else
        local list = inv:get_list(listname)
        state = "full"
        local num = 0
        for i, item in ipairs(list) do
            if item:is_empty() then
                return "loaded"
            end
        end
    end
    return state
end

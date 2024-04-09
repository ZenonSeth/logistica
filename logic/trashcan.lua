
local INV_FILT = "filt"

-- Tries to trash the given itemstack for Trashcan at the given position
-- Returns either an empty ItemStack if successful, or the same itemStack if not
function logistica.trashcan_trash_item(pos, inputStack)
  local itemStackName = inputStack:get_name()
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:is_empty(INV_FILT) then return ItemStack("") end
  for _, filterStack in ipairs(logistica.get_list(inv, INV_FILT)) do
    if filterStack:get_name() == itemStackName then
      return ItemStack("")
    end
  end
  return inputStack
end

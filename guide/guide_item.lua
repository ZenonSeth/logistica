local S = logistica.TRANSLATOR
local GUIDE_NAME = "logistica_guide"

local function convert_to_open(itemstack, user, _)
  if not user or not user:is_player() then return itemstack end
  logistica.GuideApi.show_guide(user:get_player_name(), GUIDE_NAME)
  return ItemStack("logistica:guide_open")
end

local function place_or_show(itemstack, placer, pointed_thing)
  if not placer or not placer:is_player() then return itemstack end
  if placer:get_player_control().sneak then
    local open_stack = ItemStack("logistica:guide_open")
    local _, placed = minetest.item_place_node(open_stack, placer, pointed_thing)
    if placed then itemstack:take_item() end
    return itemstack
  end
  return convert_to_open(itemstack, placer, nil)
end

minetest.register_tool("logistica:guide", {
  description = S("Guide Book to Logistica machines and concepts") .. "\n" .. S("Sneak+rightclick to place on ground"),
  inventory_image = "logistica_guide_book_item.png",
  stack_max = 1,
  groups = { not_in_creative_inventory = 1 },
  on_secondary_use = convert_to_open,
  on_place = place_or_show,
  node_placement_prediction = "",
})

minetest.register_craft({
  output = "logistica:guide_open",
  recipe = {
    {logistica.itemstrings.sand},
    {logistica.itemstrings.paper},
    {logistica.itemstrings.sand},
  }
})

local S = logistica.TRANSLATOR
local GUIDE_NAME = "logistica_guide"

local function show_guide(_, user, _)
  if user:is_player() then
    logistica.GuideApi.show_guide(user:get_player_name(), GUIDE_NAME)
  end
end

minetest.register_craftitem("logistica:guide", {
  description = S("Guide Book to Logistica machines and concepts"),
  inventory_image = "logistica_guide_book_item.png",
  stack_max = 1,
  on_secondary_use = show_guide,
  on_place = show_guide,
})

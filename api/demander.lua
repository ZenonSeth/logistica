--[[
  Demander nodes should provide a table called `logistica_demander` in their definition
  This table should define::
  {
    get_demanded = function(pos)
      -- required
      -- pos: The position of this demander node
      -- This will be called to check what item demands are required. 
      -- The function must return a table of `itemstack` definitions that are needed, e.g.:
      -- {"default:cobble 3", "default:stick 2"}
      -- if the function returns an empty table or nil, no items will be supplied

    receive_items = function(pos, itemstack)
      -- required
      -- pos: The position of this demanded node
      -- itemstack: an ItemStack object instance
      -- called to provide items, as requested by get_demand
      -- multiple itemstack requests will result in multiple calls to this function
      -- each call providing one itemstack (which may contain multiple items in the stack)
  }

  Currently demanders will connect to all network tiers - network tiers only differ
]]

function logistica.register_demander(simpleName, definition)
  local demander_name = "logistica:demander_"..simpleName
  
end

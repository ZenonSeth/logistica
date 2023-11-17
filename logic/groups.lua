logistica.cables = {}
logistica.controllers = {}
logistica.injectors = {}
logistica.requesters = {}
logistica.suppliers = {}
logistica.mass_storage = {}
logistica.item_storage = {}
logistica.misc_machines = {}
logistica.trashcans = {}
logistica.vaccuum_suppliers = {}
logistica.tiers = {}
logistica.TIER_ALL = "logistica_all_tiers"
logistica.GROUP_ALL = "group:" .. logistica.TIER_ALL
logistica.TIER_CONTROLLER = "controller"

function logistica.get_cable_group(tier)
  return "logistica_" .. tier .. "_cable"
end

function logistica.get_machine_group(tier)
  return "logistica_" .. tier .. "_machine"
end

function logistica.is_machine(name)
  return logistica.is_requester(name) or logistica.is_supplier(name) or logistica.is_mass_storage(name)
          or logistica.is_item_storage(name) or logistica.is_controller(name) or logistica.is_injector(name)
          or logistica.is_misc(name)
end

function logistica.is_cable(name)
  return logistica.cables[name] ~= nil
end

function logistica.is_requester(name)
  return logistica.requesters[name] ~= nil
end

function logistica.is_supplier(name)
  return logistica.suppliers[name] ~= nil
end

function logistica.is_mass_storage(name)
  return logistica.mass_storage[name] ~= nil
end

function logistica.is_item_storage(name)
  return logistica.item_storage[name] ~= nil
end

function logistica.is_controller(name)
  return logistica.controllers[name] ~= nil
end

function logistica.is_injector(name)
  return logistica.injectors[name] ~= nil
end

function logistica.is_misc(name)
  return logistica.misc_machines[name] ~= nil
end

function logistica.is_trashcan(name)
  return logistica.trashcans[name] ~= nil
end

function logistica.is_vaccuum_supplier(name)
  return logistica.vaccuum_suppliers[name] ~= nil
end

function logistica.get_item_tiers(name)
  local tiers = {}
  for tier,_  in pairs(logistica.tiers) do
    local cable_group = logistica.get_cable_group(tier)
    local machine_group = logistica.get_machine_group(tier)
    if minetest.get_item_group(name, cable_group) > 0 then
      tiers[tier] = true
    end
    if minetest.get_item_group(name, machine_group) > 0 then
      tiers[tier] = true
    end
    if minetest.get_item_group(name, logistica.TIER_ALL) > 0 then
      tiers[logistica.TIER_ALL] = true
    end
  end
  return tiers
end

function logistica.do_tiers_match(tiers1, tiers2)
  for t1, _ in pairs(tiers1) do
    for t2, _ in pairs(tiers2) do
      if t1 == logistica.TIER_ALL or t2 == logistica.TIER_ALL or t1 == t2 then
        return true
      end
    end
  end
  return false
end

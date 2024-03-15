logistica.cables = {}
logistica.controllers = {}
logistica.injectors = {}
logistica.requesters = {}
logistica.suppliers = {}
logistica.craftsups = {}
logistica.bucket_emptiers = {}
logistica.bucket_fillers = {}
logistica.pumps = {}
logistica.mass_storage = {}
logistica.item_storage = {}
logistica.misc_machines = {}
logistica.trashcans = {}
logistica.vaccuum_suppliers = {}
logistica.reservoirs = {}
logistica.TIER_ALL = "logistica_all_tiers"
logistica.GROUP_ALL = "group:" .. logistica.TIER_ALL
logistica.TIER_CONTROLLER = "logistica_controller"
logistica.TIER_CABLE_OFF = "logistica_cable_off"
logistica.GROUP_CABLE_OFF = "group:" .. logistica.TIER_CABLE_OFF
logistica.TIER_ACCESS_POINT = "logistica_acspt"

function logistica.is_machine(name)
  return logistica.is_requester(name) or logistica.is_supplier(name) or logistica.is_mass_storage(name)
          or logistica.is_item_storage(name) or logistica.is_controller(name) or logistica.is_injector(name)
          or logistica.is_crafting_supplier(name) or logistica.is_trashcan(name) or logistica.is_vaccuum_supplier(name)
          or logistica.is_misc(name) or logistica.is_reservoir(name) or logistica.is_bucket_filler(name)
          or logistica.is_bucket_emptier(name) or logistica.is_pump(name)
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

function logistica.is_crafting_supplier(name)
  return logistica.craftsups[name] ~= nil
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

function logistica.is_reservoir(name)
  return logistica.reservoirs[name] ~= nil
end

function logistica.is_bucket_filler(name)
  return logistica.bucket_fillers[name] ~= nil
end

function logistica.is_bucket_emptier(name)
  return logistica.bucket_emptiers[name] ~= nil
end

function logistica.is_pump(name)
  return logistica.pumps[name] ~= nil
end

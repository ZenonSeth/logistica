## Logistica 2.0 Wishlist
### Definitely
- Mass Storage
  - Make Reserve an input field -- DONE (per-slot config sub-formspec)
  - Add new Demand field instead of Pull switch -- DONE (per-slot demand target)
  - Add Demand from Crafting Suppliers -- DONE (per-slot "Include Crafting Suppliers" checkbox)
  - Add Multiplexer Upgrade (one per machine, x16 storage cap) -- DONE
  - Max Storage readout -- DONE
  - Filled up indicators -- (Maybe not)
- Passive Supply Chest
  - Increase size of inventory
  - Split: Allow Storing From Machines and Allow Storing From Access Point
  - (Maybe) Allow storing rules (e.g. what items to be allowed to be stored in it)
- Change injectors to use numbers and not items, allowing larger supply requests
- Vacuum Chest
  - Fix name
  - Add pushing option
- Toggle machines -- DONE
  - Signals sender/receivers -- DONE
  - Senders:
    - Timer (time on, time off) -- DONE (signal_timer)
    - Network content (#items) -- DONE (signal_item_counter)
    - Network content (#liquid) -- not built (Maybe)
    - External Content Reader (#items in another node) -- DONE (signal_ext_reader)
    - User Switch and User Button -- DONE (signal_switch, signal_button)
    - Mesecon receiver - sends signal if mesecon on/off -- DONE (mesecon_signaler)
  - Signal Logic Gate -- DONE (signal_logic_gate + signal_not_gate)
  - Receivers:
    - Toggler: Can toggle other select machines on/off -- DONE (signal_toggler)
    - Status Light: Turns on/off based on signal -- DONE (signal_lamp_white, signal_lamp_2c_br)
    - External Mesecon sender - sends a mesecon on -- DONE (mesecon_sender)
    - Digiline output -- not built (Maybe)
    - (Maybe) Display Unit -- not built
- Recycler machine (un-crafts logistica machines)
- Lava Furnace
  - Fix shift+click on slots
- Difficult to make Cooking Crafting Supplier
- Farming node -- deferred (similar to vacuum chest, but for plants)
- Tree cutting node -- deferred
- Allow configuration of distance of pickup for vacuum chest
- Upgrade recipes for Importer and Requester
- Filters on Vacuum chest

### Maybe
- Lava generator - but slow
- Access Point
  - Add tabs to access point
  - Add advanced autocrafting
  - Make allocating mass storage slots possible from access point
- Item monitoring station
- Digilines compat
- On-demand node-breaker
- On-demand node cracker
- Node placer
- Named interactors?
  - Allow you to remotely place and get things from other blocks, e.g. furnaces

## Low priority
- Add compatibility with on_move_node - used by mods that teleport nodes
- Demander modes: AND/OR 
  - Mode AND: supply target with "item 1 AND item 2..."
  - Mode OR: supply target with "item 1" OR (if not available) "item 2"
- Add tabs to Access Point GUI, split and extend funcionality

## Other changes to consider
- Mesecons compat
- Direct pipeworks compatibility
- Direct tubelib compatibility
- API improvements
- Rework old UI icons to be.. 48x48? 64x64? something else?

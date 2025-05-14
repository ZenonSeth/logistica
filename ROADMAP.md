## Logistica 2.0 Wishlist
### Definitely
- Lava generator - but slow
- Mass Storage
  - Make Reserve an input field
  - Add new Demand field instead of Pull switch
  - Add Demand from Crafting Suppliers
  - Add Multiplexer Upgrade (one per machine, x8 storage cap)
  - Max Storage readout
  - Filled up indicators
- Passive Supply Chest
  - Increase size of inventory
  - Split: Allow Storing From Machines and Allow Storing From Access Point
  - (Maybe) Allow storing rules (e.g. what items to be allowed to be stored in it)
- Change injectors to use numbers and not items, allowing larger supply requests
- Vacuum Chest
  - Fix name
  - Add pushing option
- Toggle machines
  - Signals sender/receivers
  - Senders:
    - Network content (#items, #liquid)
    - External Content Reader (#items in another node)
    - External Mesecon connection
    - User Switch and User Button
  - Receivers:
    - Toggler: Can toggle other select machines on/off
    - Status Light: Turns on/off based on signal
    - Mesecon receiver
- Recycler machine (un-crafts logistica machines)
- Lava Furnace
  - Fix shift+click on slots
- Difficult to make Cooking Crafting Supplier
- Farming node (similar to vacuum chest, but for plants)
- Tree cutting node
- Allow configuration of distance of pickup for vacuum chest
- Upgrade recipes for Importer and Requester
- Filters on Vacuum chest

### Maybe
- Use respec for layout changes
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

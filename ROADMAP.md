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
  - Increase size of inventory -- DONE (16 -> 32 slots, 4x8; existing chests resize on open)
  - Split: Allow Storing From Machines and Allow Storing From Access Point -- DONE (two separate toggles, isAutomated flag through insert_item_in_network)
  - (Maybe) Allow storing rules (e.g. what items to be allowed to be stored in it)
- Change Request Inserter filter slots to use numbers instead of item stacks -- DONE (per-slot "Request up to" amount fields, max 9999; inf checkbox removed; migration on open and on timer)
- Vacuum Chest
  - Fix name -- DONE (display name only)
  - Add pushing option -- skipped
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
- Recycler machine (un-crafts logistica machines) -- DONE (Logistica Machine Disassembler: logistica:disassembler, api/disassembler.lua + api/disassembler_machine.lua)
- Lava Furnace
  - Fix shift+click on slots -- DONE
- Difficult to make Cooking Crafting Supplier -- (Maybe)
- Farming node -- DONE (logistica:farming_supplier; api/farming_supplier.lua + logic/farming_supplier.lua; Sprinkler Upgrade item)
- Tree cutting node -- DONE (logistica:woodcutter; api/woodcutter.lua + logic/woodcutter.lua; Leafcutter Upgrade item)
- Allow configuration of distance of pickup for vacuum chest -- DONE (+/- in formspec, range 1-3)
- Upgrade recipes for Importer and Requester -- DONE
- Filters on Vacuum chest -- (Maybe not)
- (Maybe) - Automatic Packer + Unpacker - detect crafting loops (e.g. 9 ingots = 1 block = 9 ingots) at load time, make a machine that enables that conversion by default on a network.

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

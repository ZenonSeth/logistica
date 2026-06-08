## Logistica 2.0 Wishlist

## TODO - fixes + improvements on new features
- Make sure Harvester doesn't allow storing from network - it's a take-only inventory, filled only by its machine harvesting plants/seeds. -- DONE
- Add new decorative/for-crafting node: Hardened Silverin Block (Silvering Block + Obsidian additive in the Lava Furnace)
- Use new Hardned Silverin Block in construction of a Rock Melter node (was mentioned below too) - a furnace that burns regular items and makes lava. TODO: Check how much burn time a lava bucket provides. That's exactly how much time making a single lava node should take. The Rock Melter takes Cobblestone or Stone (todo: make itemstrings for those if not present). This should have an output tank of say 16 buckets of lava, which it can provide to the network, the same way Reservoirs provide lava to network. It should also have a slot to fill (but not empty) a bucket with Lava from the tank.
- Access Point Migration - ensure upgrade inv (and any others we may add due to recursive crafting) exist when formspec is opened -- DONE

- New idea: Two machines - network bridgers - a Network Bridge Provider and a Network Bridge Recevier. Provider has either push mode or passive supply mode. Recevier simply connects to the bridger and either tries to fulfil requests when they come or accepts things being pushed by the receiver. They are part of different networks but they have to face each other (well their backsides have to face each other)


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
- Farming node -- DONE (logistica:farming_supplier; api/farming_supplier.lua + logic/farming_supplier.lua; Sprinkler Upgrade item)
- Tree cutting node -- DONE (logistica:woodcutter; api/woodcutter.lua + logic/woodcutter.lua; Leafcutter Upgrade item)
- Allow configuration of distance of pickup for vacuum chest -- DONE (+/- in formspec, range 1-3)
- Upgrade recipes for Importer and Requester -- DONE
- Filters on Vacuum chest -- (Maybe not)
- (Maybe) - Automatic Packer + Unpacker - detect crafting loops (e.g. 9 ingots = 1 block = 9 ingots) at load time, make a machine that enables that conversion by default on a network.

### Maybe
- Lava generator - but slow
- Access Point
  - Add tabs to access point -- DONE (Items tab + Storage Management tab)
  - Add advanced autocrafting -- DONE (Easy Crafting tab: search, recipe view, basic craft to ac_output, recursive craft with queue display; two upgrade tiers: autocrafting_upgrade / autocrafting_recursive_upgrade)
  - Make allocating mass storage slots possible from access point -- DONE (Storage Management tab)
- Item monitoring station -- DONE (logistica:item_monitor; logic/item_monitor.lua + api/item_monitor.lua; tracks up to 8 items, configurable interval, rolling graph with per-point tooltips, monitor-stand nodebox, custom textures)
- Digilines compat
- On-demand node-breaker
- On-demand node cracker
- Node placer
- Named interactors?
  - Allow you to remotely place and get things from other blocks, e.g. furnaces

- Network Access Control -- DONE
  - Network Controller stores owner (set on place; migrates from wireless transmitter on first scan for existing networks)
  - Controller formspec: "Give Access To" field (comma-separated players), "Hide network content based on area protection" checkbox (off by default)
  - Owner always has full access regardless of area protection
  - All machines: formspec visible to all by default; take/move/put blocked for players without owner status, area access, or access list entry
  - Non-network machines (Disassembler, Autocrafter) fall back to area-protection-only

## Low priority
- Add compatibility with on_move_node - used by mods that teleport nodes

## Other changes to consider
- Direct pipeworks compatibility
- Direct tubelib compatibility
- API improvements
- Rework old UI icons to be.. 48x48? 64x64? something else?

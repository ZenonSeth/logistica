## Logistica 2.0 Wishlist

## TODO - fixes + improvements on new features
- RECURSIVE CRAFTING RECIPE SELECTION IMPROVEMENT: Prefer using recipes that have the most # of their ingredients available directly in storage. E.g. if an item has 3 recipes, let's say 1 stone + 1 woodA, then woodB then woodC - and we have woodC in storage, but not woodA or woodB - then prefer the recipe with woodC. Basically count how many items from the recipe are available to fulfil this craft and then use the recipe that has the most number -- DONE
- Make sure Harvester doesn't allow storing from network - it's a take-only inventory, filled only by its machine harvesting plants/seeds. -- DONE
- Add new decorative/for-crafting node: Hardened Silverin Block (Silvering Block + Obsidian additive in the Lava Furnace) -- DONE
- Use new Hardened Silverin Block in construction of a Rock Melter node -- DONE (read-only lava reservoir on the network; fuel/src/dst slots automatable; nodebox visuals; guide entry)
- Access Point Migration - ensure upgrade inv (and any others we may add due to recursive crafting) exist when formspec is opened -- DONE

- New idea: Two machines - network bridgers - a Network Bridge Provider and a Network Bridge Recevier. Provider has either push mode or passive supply mode. Recevier simply connects to the bridger and either tries to fulfil requests when they come or accepts things being pushed by the receiver. They are part of different networks but they have to face each other (well their backsides have to face each other)


### Definitely
- Mass Storage
  - Make Reserve an input field -- DONE (per-slot config sub-formspec)
  - Add new Demand field instead of Pull switch -- DONE (per-slot demand target)
  - Add Demand from Crafting Suppliers -- DONE (per-slot "Include Crafting Suppliers" checkbox)
  - Add Multiplexer Upgrade (one per machine, x16 storage cap) -- DONE
  - Max Storage readout -- DONE
- Passive Supply Chest
  - Increase size of inventory -- DONE (16 -> 32 slots, 4x8; existing chests resize on open)
  - Split: Allow Storing From Machines and Allow Storing From Access Point -- DONE (two separate toggles, isAutomated flag through insert_item_in_network)
- Change Request Inserter filter slots to use numbers instead of item stacks -- DONE (per-slot "Request up to" amount fields, max 9999; inf checkbox removed; migration on open and on timer)
- Vacuum Chest
  - Fix name -- DONE (display name only)
- Toggle machines -- DONE
  - Signals sender/receivers -- DONE
  - Senders:
    - Timer (time on, time off) -- DONE (signal_timer)
    - Network content (#items) -- DONE (signal_item_counter)
    - External Content Reader (#items in another node) -- DONE (signal_ext_reader)
    - User Switch and User Button -- DONE (signal_switch, signal_button)
    - Mesecon receiver - sends signal if mesecon on/off -- DONE (mesecon_signaler)
  - Signal Logic Gate -- DONE (signal_logic_gate + signal_not_gate)
  - Receivers:
    - Toggler: Can toggle other select machines on/off -- DONE (signal_toggler)
    - Status Light: Turns on/off based on signal -- DONE (signal_lamp_white, signal_lamp_2c_br)
    - External Mesecon sender - sends a mesecon on -- DONE (mesecon_sender)
- Recycler machine (un-crafts logistica machines) -- DONE (Logistica Machine Disassembler: logistica:disassembler, api/disassembler.lua + api/disassembler_machine.lua)
- Lava Furnace
  - Fix shift+click on slots -- DONE
- Farming node -- DONE (logistica:farming_supplier; api/farming_supplier.lua + logic/farming_supplier.lua; Sprinkler Upgrade item)
- Tree cutting node -- DONE (logistica:woodcutter; api/woodcutter.lua + logic/woodcutter.lua; Leafcutter Upgrade item)
- Allow configuration of distance of pickup for vacuum chest -- DONE (+/- in formspec, range 1-3)
- Upgrade recipes for Importer and Requester -- DONE
### Maybe
- Lava generator - but slow -- DONE (Rock Melter: logistica:rock_melter; read-only lava reservoir on the network)
- Mass Storage - filled up indicators -- DONE
- Passive Supply Chest - allow storing rules (e.g. whitelist items allowed to be stored in it) -- DONE
- Vacuum Chest - add pushing option -- not going to implement
- Signal sender: Network content (#liquid) -- DONE (signal_liquid_counter: prev/next liquid selector with texture + curr/max display, >=/<= condition, bucket threshold, named signal; empty signal name = no send)
- Signal sender: Digiline output -- EXPERIMENTAL (digiline_sender: polls network every 1s, 8 item filter slots, signal monitoring, freeform message template with %sN/%iM placeholders, optional parse-as-table, Help tab with examples; requires digilines mod)
- Signal receiver: Digiline input -- DONE (digiline_receiver: translate incoming digiline message on a channel to a logistica on/off signal; simpler than sender)
- Signal receiver: Display Unit -- DONE
- Signal Monitor -- DONE (logistica:signal_monitor; logic/signal_monitor.lua + api/signal_monitor.lua; live signal list with ON/OFF state, per-signal sender detail panel with chat-send on click, search filter, live update mode, per-network state persistence in memory)
- Automatic Packer + Unpacker - detect crafting loops (e.g. 9 ingots = 1 block = 9 ingots) at load time, make a machine that enables that conversion by default on a network
- Filters on Vacuum chest -- DONE
- Access Point
  - Add tabs to access point -- DONE (Items tab + Storage Management tab)
  - Add advanced autocrafting -- DONE (Easy Crafting tab: search, recipe view, basic craft to ac_output, recursive craft with queue display; two upgrade tiers: autocrafting_upgrade / autocrafting_recursive_upgrade)
  - Make allocating mass storage slots possible from access point -- DONE (Storage Management tab)
- Item monitoring station -- DONE (logistica:item_monitor; logic/item_monitor.lua + api/item_monitor.lua; tracks up to 8 items, configurable interval, rolling graph with per-point tooltips, monitor-stand nodebox, custom textures)
- Digilines compat -- DONE
- On-demand node-breaker -- DONE
- On-demand node cracker -- out of scope
- Node placer -- DONE
- Network Bridge Provider + Network Bridge Receiver
  - Provider has push mode or passive supply mode; faces the Receiver (backsides touching)
  - Receiver connects to the Provider and either fulfils requests or accepts pushed items
  - The two nodes are on different networks

- Network Access Control -- DONE
  - Network Controller stores owner (set on place; migrates from wireless transmitter on first scan for existing networks)
  - Controller formspec: "Give Access To" field (comma-separated players), "Hide network content based on area protection" checkbox (off by default)
  - Owner always has full access regardless of area protection
  - All machines: formspec visible to all by default; take/move/put blocked for players without owner status, area access, or access list entry
  - Non-network machines (Disassembler, Autocrafter) fall back to area-protection-only

## Low priority
- Named interactors - allow you to remotely place and get things from other blocks, e.g. furnaces
- Add compatibility with on_move_node - used by mods that teleport nodes

## Other changes to consider
- Direct pipeworks compatibility
- Direct tubelib compatibility
- API improvements
- Rework old UI icons to be.. 48x48? 64x64? something else? -- DONE

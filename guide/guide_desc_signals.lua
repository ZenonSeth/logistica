local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

g.signal_relay = S([[
The Signal Relay is a crafting component used in all signal machine recipes.

It is made from two Silverin Slices sandwiching a Mese Crystal Fragment, and yields 4 relays per craft.
]])

g.signals_overview = S([[
Signals are a named on/off messaging system that works within a single Logistica network.

How signals work
------------------------------
A signal has a name (e.g. "power", "door_open") and a state: ON or OFF.
Signal names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Machines that send signals are called senders. Machines that react to signals are called receivers.

Multiple senders can broadcast the same signal name. The signal is considered ON as long as at least one sender is broadcasting it as ON. This is called OR logic: if any sender is on, the signal is on.

When a sender is removed from the network (disconnected or dug up), its contribution is automatically removed. If no other sender is keeping the signal ON, the signal turns OFF and all receivers are notified.

Senders and Receivers
------------------------------
Senders start a signal. The Signal Switch is the simplest sender: a manual on/off switch. More advanced senders like the Signal Item Count Sender and the External Content Reader monitor conditions and send signals automatically.

Receivers listen for a signal by name and do something when it changes state. The Signal Lamp and Signal Network Switch are both receivers.

Some receivers support a NOT mode: when NOT is checked, the receiver activates when the signal is ABSENT instead of when it is present. Not all receivers have this option. For those that do not, you can use the Signal NOT Gate to broadcast an inverted signal network-wide and have receivers listen to that instead.

Logic Gates
------------------------------
Logic gates are machines that act as both receivers and senders. They read one or more input signals, apply a logic rule, and broadcast a single output signal. Use them to combine or transform signals before they reach other receivers.

Signal names and scope
------------------------------
Signal names are scoped to the network. Two machines on different networks cannot affect each other through signals even if they share the same signal name.

All machines on the same network that share a signal name will communicate with each other.
]])

g.signal_button = S([[
The Signal Button is a momentary signal sender. When pressed it sends a named signal ON, stays pushed for 1 second, then turns the signal OFF again.

Right-click (or use) to press the button. Use the Hyperspanner on it to open the configuration and set the signal name.

Configuration
------------------------------
Signal Name: the name of the signal this button broadcasts when pressed. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Behavior
------------------------------
Pressing the button while it is already pushed has no effect - it must finish its 1-second push before it can be pressed again.

If the button is mid-press when it connects to a network, it re-sends the ON signal to that network. When disconnected, its signal contribution is automatically removed.

The infotext shows the signal name, current state (Ready or Pressed), and a reminder to use the Hyperspanner for configuration.

Example uses
------------------------------
- Trigger a one-shot action in a Logic Gate.
- Manually fire a timed pulse without needing a timer sender.
]])

g.signal_switch = S([[
The Signal Switch is a manual signal sender. It broadcasts a named ON or OFF signal to all receivers on the same network.

Right-click to toggle the switch ON or OFF. Use the Hyperspanner on it to open the configuration and set the signal name.

Configuration
------------------------------
Signal Name: the name of the signal this switch broadcasts. All receivers watching the same name on the same network will react.

Signal names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Notes
------------------------------
The infotext shows the signal name, current state, and a reminder to use the Hyperspanner for configuration.

If the switch is ON when it is disconnected from the network (dug up or isolated by a Toggleable Cable), it will automatically remove its signal contribution from the network. If no other sender is keeping that signal ON, the signal turns OFF.
]])

g.signal_lamp = S([[
The Signal Lamp is a signal receiver that lights up when a named signal is active on the network.

When ON, the lamp emits light. When OFF, it is dark.

Usage
------------------------------
Right-click to open the settings and configure the signal name and NOT mode.

The infotext above the node shows the current state: On or Off.

Configuration
------------------------------
NOT checkbox: when checked, the lamp logic is inverted. The lamp turns ON when the named signal is ABSENT, and turns OFF when the signal is present. This is useful for "warning" setups where you want a light on when something is NOT running.

Signal Name: the name of the signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Colors
------------------------------
Signal Lamps come in 7 colors: White, Red, Yellow, Green, Cyan, Blue, and Purple. All colors behave identically, they are purely cosmetic.

The White lamp has a standard craft recipe. All colors can also be cycled into the next color in the chain (White -> Red -> Yellow -> Green -> Cyan -> Blue -> Purple -> White) by placing any lamp alone in the crafting grid.
]])

g.signal_lamp_2c = S([[
The 2-Color Signal Lamp is a signal receiver that shows one of two colors depending on whether a named signal is active on the network. When no signal name is set, or when the node is not connected to a network, both lights are dark.

Usage
------------------------------
Right-click to open the settings and configure which color is shown when the signal is ON.

Configuration
------------------------------
Color dropdown: choose which color lights up when the signal is ON. The other color is shown automatically when the signal is OFF.

Signal Name: the name of the signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _). Leave empty to keep both lights dark.

Notes
------------------------------
The 2-Color Signal Lamp can be crafted in different color pairs. All color pairs behave identically and are purely cosmetic.
]])

g.mesecon_signal_receiver = S([[
Only available if the Mesecons mod is present.

The Mesecon Signal Receiver bridges Mesecons wiring into the Logistica signal system. When it receives power from a Mesecon wire, it broadcasts a named Logistica signal as ON. When Mesecon power is removed, the signal is broadcast as OFF.

This allows Mesecon machines, buttons, pressure plates, and other Mesecon devices to trigger Logistica automation.

Usage
------------------------------
Right-click to configure the signal name and optional NOT mode.

Configuration
------------------------------
NOT checkbox: when checked, the logic is inverted. The Logistica signal is sent as ON when Mesecon power is ABSENT, and OFF when power is present.

Signal Name: the name of the Logistica signal to broadcast. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Notes
------------------------------
The receiver connects to Logistica cables from any face. Mesecon wires can connect from any face independently.

When disconnected from a Logistica network, the node stops broadcasting but still reacts to Mesecon power visually.
]])

g.mesecon_signal_sender = S([[
Only available if the Mesecons mod is present.

The Mesecon Signal Sender bridges the Logistica signal system into Mesecons wiring. When a named Logistica signal is ON, the node emits Mesecon power. When the signal is OFF, Mesecon power stops.

This allows Logistica signals to control Mesecon machines, doors, lights, and other Mesecon devices.

Usage
------------------------------
Right-click to configure the signal name and optional NOT mode.

Configuration
------------------------------
NOT checkbox: when checked, the logic is inverted. Mesecon power is emitted when the Logistica signal is ABSENT, and stopped when the signal is ON.

Signal Name: the name of the Logistica signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Loop protection
------------------------------
If a Mesecon Signal Receiver and a Mesecon Signal Sender are wired together in a loop (e.g. through a NOT configuration), the sender has a built-in cooldown that limits how fast it can change its Mesecon output. This prevents the loop from overloading the server, though the correct fix is to redesign the circuit.

Notes
------------------------------
The sender connects to Logistica cables from any face. Mesecon wires connect from any face independently.

When disconnected from a Logistica network, the sender turns its Mesecon output off.
]])

g.digiline_sender = S([[
Only available if the Digilines mod is present.

The Digiline Signal Sender monitors your Logistica network every second and sends a message on a configurable Digilines channel whenever the message content changes.

It supports up to 8 item filter slots for item count queries and a list of Logistica signal names to monitor. Values are inserted into a freeform message template using placeholders. Optionally the message can be parsed and sent as a Lua table.

For full details on placeholders, table mode, and examples, open the node and check the Help tab inside its interface.
]])

g.digiline_receiver = S([[
Only available if the Digilines mod is present.

The Digiline to Signal Converter listens on a configurable Digilines channel and broadcasts a named Logistica signal based on the received message.

Usage
------------------------------
Right-click to open the settings. Configure a Digiline channel to listen on and a Logistica signal name to broadcast.

The node turns ON when the current signal state is ON, and returns to its default appearance when OFF.

The infotext above the node shows the configured channel, signal name, and current state.

Configuration
------------------------------
Digiline channel: the Digilines channel this node listens on. Only messages arriving on exactly this channel are processed.

Signal: the name of the Logistica signal to broadcast. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Message interpretation
------------------------------
ON: true, "true", "on", or integer > 0
OFF: any other value

Behavior
------------------------------
When a message arrives on the configured channel, the node evaluates it and sends the resulting ON or OFF state as a Logistica signal. If the state is unchanged from the last received message, the signal is not resent.

When the node connects to a Logistica network, it immediately rebroadcasts its current state so downstream receivers are in sync.

When disconnected or dug up, its signal contribution is automatically removed from the network.
]])

g.signal_not_gate = S([[
The Signal NOT Gate is both a signal receiver and a signal sender. It reads one input signal and broadcasts the opposite state on a separate output signal.

If the input signal is ON, the output signal is OFF. If the input signal is OFF (or absent), the output signal is ON.

Usage
------------------------------
Right-click to open the settings and configure the input and output signal names.

The infotext above the node shows the current output state: On or Off.

Configuration
------------------------------
Input Signal: the name of the signal this gate listens for. When this signal changes, the gate immediately recalculates and sends the inverted result.

Output Signal: the name of the signal this gate broadcasts. Other receivers can listen to this name to react to the inverted state.

Both names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Notes
------------------------------
The NOT gate will immediately send OFF on its output signal when connected to a network, then update when the input signal arrives.

If no other sender is keeping the output signal ON and the gate is disconnected or dug up, its output contribution is automatically removed.
]])

g.signal_logic_gate = S([[
The Signal Logic Gate is both a signal receiver and a signal sender. It combines multiple input signals using a configurable logic rule and broadcasts the result on an output signal.

Four modes are available: AND, OR, XOR, and ADDER.

Usage
------------------------------
Right-click to open the settings and configure the mode, input signals, and output signal.

The infotext above the node shows the current output state: On or Off.

Modes
------------------------------
AND: the output is ON only if ALL listed input signals are currently ON. If any input is OFF or absent, the output is OFF.

OR: the output is ON if ANY of the listed input signals is currently ON. The output is only OFF when all inputs are absent or OFF.

XOR: the output is ON if exactly 1 of the listed input signals is currently ON. If zero or more than one input is ON, the output is OFF.

ADDER: the output is ON if the number of input signals that are currently ON is greater than or equal to the configured threshold. Use this to require a minimum count of active signals.

Configuration
------------------------------
Input Signals: a list of signal names separated by spaces or commas. The gate listens to all of them. Duplicates are ignored.

Output Signal: the name of the signal this gate broadcasts.

Threshold (ADDER mode only): the minimum number of inputs that must be ON for the output to turn ON. Can be set from 1 to 100000 using the [-] and [+] buttons.

All signal names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Notes
------------------------------
The gate re-reads all input states fresh each time any one of its inputs changes, so the output always reflects the true combined state.

If the gate is disconnected or dug up, its output contribution is automatically removed from the network.
]])

g.signal_ext_reader = S([[
The External Content Reader is a signal sender that monitors the inventory of a non-Logistica node placed directly behind it and broadcasts up to 4 named signals based on item count conditions.

Place the reader facing a chest, furnace, or any other node with an inventory. The node behind its back face is its target.

Usage
------------------------------
Right-click to open the settings. Use the Enable button to start or stop monitoring.

Sneak+punch the reader to highlight its target node.

The infotext shows the target node name and whether the reader is Running or Paused.

Configuration
------------------------------
Each of the 4 rows works independently:

Item slot: place an item to identify what to count. The slot is a filter only - the item is not consumed.

Condition: choose >= or <= to compare the count against the threshold.

Amount: the threshold number to compare the count against.

Signal Name: the name of the signal this row broadcasts when its condition is met. Leave blank to disable that row.

Behavior
------------------------------
When enabled, the reader scans the target's inventory every second. It combines all inventory lists that Logistica is allowed to push to or pull from on that node.

Logistica machine nodes cannot be used as targets (with the exception of Bucket Emptiers).

If the target slot has no item set, or the signal name is blank, that row sends no signal. If the item is removed from the slot while the machine is running, that row's signal is sent as OFF.

When disconnected or dug up, all signal contributions are automatically removed.

Example uses
------------------------------
- Send a signal when a furnace output reaches a certain count.
- Monitor a chest shared with another mod and gate a machine when it fills up.
- Watch 4 different items in the same chest with independent thresholds.
]])

g.signal_timer = S([[
The Signal Timer Sender is a signal sender that automatically cycles a named signal ON and OFF on a repeating timer. Configure the ON duration and OFF duration independently, each as a multiple of 0.5 seconds.

Usage
------------------------------
Right-click to open the settings.
Use the Enable button to start or stop the timer.

The infotext above the node shows the signal name, the configured durations, and whether the node is Running or Paused, along with the current phase (ON or OFF).

Configuration
------------------------------
Signal Name: the name of the signal this node broadcasts. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

ON duration: how long the signal stays ON each cycle, in seconds. Must be a multiple of 0.5 (minimum 0.5).

OFF duration: how long the signal stays OFF each cycle, in seconds. Must be a multiple of 0.5 (minimum 0.5).

Enable button: toggles the node between Running and Paused. When Paused, the signal is immediately sent as OFF and the timer stops.

Behavior
------------------------------
When enabled, the timer starts immediately in the ON phase. After the ON duration elapses, it switches to OFF, then back to ON, and so on indefinitely.

If the node is not connected to a network, the timer continues ticking internally. The signal is sent as soon as the node joins a network.

When the node is disconnected (dug up or isolated), its signal contribution is automatically removed.

Example uses
------------------------------
- Flash a lamp at a regular interval.
- Create a pulsed signal to periodically trigger another sender via a Logic Gate.
- Run a machine for a set time then pause it, repeatedly.
]])

g.signal_item_counter = S([[
The Signal Item Count Sender is a signal sender that monitors how many of a specific item are present across the network and broadcasts a named signal based on whether that count meets a configured condition.

Only items physically stored in Mass Storage nodes and Passive Supply Chests (including Vacuum Suppliers) are counted. Crafting Suppliers are excluded.

Usage
------------------------------
Right-click to open the settings.
Use the Enable button to start or pause monitoring.

The infotext above the node shows the item being monitored, the condition, the signal name, and whether the node is Running or Paused.

Configuration
------------------------------
Item to Monitor: place any item into the slot to select what to count. The slot is a filter only - the item is not consumed. Remove the item to stop monitoring.

Condition: choose >= (greater than or equal) or <= (less than or equal) from the dropdown.

Amount: the threshold number to compare the count against.

Signal Name: the name of the signal this node broadcasts when the condition is met. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Respect Mass Storage Reserve: when checked, items that are reserved in Mass Storage slots are subtracted from the count before comparing. When unchecked, all stored items including reserved amounts are counted.

Enable button: toggles the node between Running and Paused. When Paused, the signal is immediately sent as OFF regardless of the current item count.

Behavior
------------------------------
The node checks the item count once per second. When the condition is met, the signal is sent as ON. When the condition is not met, the signal is sent as OFF.

If no item is set in the filter slot, the signal is always OFF.

When the node is disconnected from the network (dug up or isolated), its signal contribution is automatically removed.

Example uses
------------------------------
- Send a signal when iron ingot stock drops below 500 (condition: <= 499).
- Trigger an alarm when a material exceeds a cap (condition: >= 1000).
- Gate a machine with a Signal Toggler so it only runs while supplies are available.
]])

g.signal_liquid_counter = S([[
The Signal Liquid Count Sender is a signal sender that monitors how many buckets of a specific liquid are stored across all reservoirs on the network and broadcasts a named signal based on whether that amount meets a configured condition.

Usage
------------------------------
Right-click to open the settings.
Use the Enable button to start or pause monitoring.

The infotext above the node shows the liquid being monitored, the condition, the signal name, and whether the node is Running or Paused.

Configuration
------------------------------
Liquid: use the arrow buttons to cycle through liquids currently present on the network. The display shows the liquid name and its current total (in buckets) out of total reservoir capacity. If no reservoirs are on the network the signal is always OFF.

Condition: choose >= (greater than or equal) or <= (less than or equal) from the dropdown.

Buckets: the threshold number of buckets to compare the stored amount against.

Signal: the name of the signal this node broadcasts when the condition is met. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Enable button: toggles the node between Running and Paused. When Paused, the signal is immediately sent as OFF regardless of the current liquid level.

Behavior
------------------------------
The node checks the liquid level once per second. When the condition is met, the signal is sent as ON. When the condition is not met, the signal is sent as OFF.

If no liquid is selected or no reservoirs with the selected liquid are on the network, the signal is always OFF.

When the node is disconnected from the network, its signal contribution is automatically removed.

Example uses
------------------------------
- Send a signal when lava drops below 10 buckets (condition: <= 9).
- Trigger a pump when water reserves fall below half capacity (condition: <= 16).
- Gate a Lava Furnace fueler with a Signal Toggler so it only runs while lava is available.
]])

g.signal_node_detector = S([[
The Signal Node Detector is a signal sender that checks whether a specific node (or any non-air node) is present at a configured distance directly behind it, and broadcasts a named signal accordingly.

Usage
------------------------------
Right-click to open the settings.
Use the Enable button to start or pause detection.

The infotext above the node shows the configured filter, distance, signal name, and current state.

Configuration
------------------------------
Node to detect: place any node item into the filter slot to restrict detection to that specific node type. Leave the slot empty to detect ANY non-air node regardless of type.

Detect distance: the number of blocks behind the detector to check. Distance 1 means the node directly behind it; distance 2 means one block further back, and so on. Use the - and + buttons to adjust.

Signal Name: the name of the signal this node broadcasts when the target node is detected. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Enable button: toggles the node between Running and Paused. When Paused, the signal is immediately sent as OFF.

Behavior
------------------------------
The detector checks once per second. The signal is ON when the node at the target position matches the filter (or is any non-air node if the filter is empty). The signal is OFF when the target position is air, unloaded, or does not match the filter.

When the node is disconnected from the network (dug up or isolated), its signal contribution is automatically removed.
]])

g.signal_node_digger = S([[
The Signal Node Digger is a signal receiver that digs a node at a set distance directly behind it when it receives a rising signal edge (OFF to ON). Dug items are stored inside the digger and made available to the network as a passive supplier (take-only). The network cannot push items into a digger.

Usage
------------------------------
Right-click to open the settings.
Sneak+punch to highlight the target position.

The infotext shows the current filter state, distance, signal name, and status.

Configuration
------------------------------
Filter slots: place up to 8 node items to restrict digging to only those node types. Leave all slots empty to dig any node at the target position regardless of type.

Tool slot: place a tool to dig with. The tool stays in this slot and is not consumed - its dig capabilities determine which nodes can be dug (matching the same rules as digging by hand or with a wielded tool). Leave empty to dig with bare hands. Items that only "use" on a node rather than dig it (e.g. a hoe, bonemeal) do not belong here - see the Signal Node Placer for that.

Dig distance: the number of blocks behind the digger to target. Use the - and + buttons to adjust.

Signal Name: the name of the signal this node listens for. The digger fires once each time this signal transitions from OFF to ON (rising edge). Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Not: when this checkbox is checked, the digger fires on the falling edge instead (ON to OFF).

Behavior
------------------------------
The digger stores an owner used for protection checks. Digging works whether or not the owner is online. However, some node types may require a player to be present for their dig logic to work correctly - in most cases this is not an issue. If a different player opens the formspec, they can press Take Ownership to become the new owner.

Dug items fill the digger's internal buffer (16 slots). If the buffer is full, excess drops fall at the target position. The network can pull from the buffer at any time. The digger cannot be picked up while its buffer contains items.

When disconnected from the network (dug up or isolated), the digger stops reacting to signals.
]])

g.signal_node_placer = S([[
The Signal Node Placer is a signal receiver that places or uses a configured item at a set distance directly behind it when it receives a rising signal edge (OFF to ON). Items are drawn from network storage automatically.

Usage
------------------------------
Right-click to open the settings.
Sneak+punch to highlight the target position.

The infotext shows the configured item, distance, signal name, and current state.

Configuration
------------------------------
Item to place/use: put a node item into the filter slot to have the placer place it, or an item that has its own "use" action (e.g. a hoe, bonemeal) to have the placer use it on the target position instead. Only registered items are accepted. Leave the slot empty and the placer will do nothing when triggered.

Place distance: the number of blocks behind the placer to target. Distance 1 means the node directly behind it; distance 2 means one block further back, and so on. Use the - and + buttons to adjust.

Signal Name: the name of the signal this node listens for. The placer fires once each time this signal transitions from OFF to ON (rising edge). Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Not: when this checkbox is checked, the placer fires on the falling edge instead (ON to OFF).

Behavior
------------------------------
When the filter item is a node, triggering checks the target position first. If it is occupied (not air or otherwise not buildable), the trigger is silently ignored and no item is consumed. If the position is free, the placer takes one of the configured node from the network and places it at the target.

When the filter item instead has its own "use" action, the occupied check is skipped - the placer takes one from the network and uses it directly on the target position, just as a player would by pointing at that position and using the item. Whether the item is consumed depends on that item's own behavior (e.g. bonemeal is used up, most tools are not).

The status line in the formspec turns red if the last attempt failed because the item was not available in the network. The status clears when the action succeeds or when the filter slot is changed.

The placer stores an owner used for protection checks. Placement works whether or not the owner is online. However, some node types may require a player to be present for their placement logic to work correctly - in most cases this is not an issue. If a different player opens the formspec, they can press Take Ownership to become the new owner.

When disconnected from the network (dug up or isolated), the placer stops reacting to signals.
]])

g.signal_monitor = S([[
The Signal Monitor is a signal receiver that passively records every signal it sees on the network and lets you inspect them at a glance.

Right-click to open the interface.

Interface
------------------------------
The signal list on the left shows every signal name the monitor has observed since it was last reset, one entry per signal. Each entry shows its current state:

(O) signal_name - the signal is currently ON (shown in green)
( ) signal_name - the signal is currently OFF (shown in grey)

Signals are kept in the list even after they go OFF, so you can see what has been active at any point since the last reset.

Clicking a signal name in the left list opens the sender panel on the right, which shows how many senders are currently broadcasting that signal as ON, with the node name and position of each one. Clicking a node name or position sends a chat message to you with the exact location.

Controls
------------------------------
Search: filters the signal list to names containing the typed text. Press Enter or Refresh to apply.

Refresh: redraws the display with the latest recorded state. No data is lost when refreshing.

Reset: clears the entire signal list and starts fresh from the current network state. Use this after removing signal senders to clean up stale entries.

Live Update: when checked, the display automatically updates whenever any signal on the network changes. When unchecked, use Refresh to update manually.

Behavior
------------------------------
The monitor records signals from the moment it connects to a network. If it is moved to a different network, the recorded list is automatically cleared and restarted for the new network.

The recorded list is stored in memory only and is not saved to disk. It will be cleared on server restart.
]])

g.signal_delayer = S([[
The Signal Delayer is both a signal receiver and a signal sender. It forwards a named input signal to a named output signal, but delays the ON transition and the OFF transition independently.

Usage
------------------------------
Right-click to open the settings and configure the input signal name, output signal name, ON delay, and OFF delay.

The infotext above the node shows the current configuration, the current output state, and any pending transitions.

Configuration
------------------------------
Input Signal: the name of the signal this node listens for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Output Signal: the name of the signal this node broadcasts. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

ON delay: how long to wait after the input goes ON before the output follows. Set with +/- buttons in 0.5s steps, from 0 to 600s.

OFF delay: how long to wait before the output follows the OFF transition. Set with +/- buttons in 0.5s steps, from 0 to 600s.

Behavior
------------------------------
Each transition of the input signal (ON or OFF) is queued. At most two pending transitions are held at once: the one being timed (head) and the next one (tail). If the same transition type arrives again while it is queued as the head, the head timer restarts. If the same transition type arrives while it is queued as the tail, it is a no-op. If the opposite type arrives while two are queued, the tail is discarded and the head timer restarts with the new value.

A delay of 0 means the output follows immediately (within one server step).

On connecting to a network, the node broadcasts its current output state immediately.

When the node is dug or disconnected, all pending transitions are cancelled.

Example uses
------------------------------
- Debounce a noisy input: set a short ON delay so brief flickers do not propagate.
- Create a delayed shutdown: set a long OFF delay so a machine keeps running for a while after the input drops.
- Sequence two machines: set different delays on two delayers fed by the same signal so one starts before the other.
]])

g.signal_toggle = S([[
The Signal Toggle is both a signal receiver and a signal sender. It toggles its output signal ON or OFF each time its input signal turns ON.

Each rising edge (OFF to ON transition) of the input flips the output to the opposite state. The falling edge (ON to OFF) of the input is ignored. The output state is stored persistently and survives network reconnections.

Usage
------------------------------
Right-click to open the settings and configure the input and output signal names.

The Toggle Output button in the formspec manually flips the output state immediately, regardless of the input signal. This is useful for forcing a known state on placement or for manual overrides.

The infotext above the node shows the current input and output signal names and the current output state.

Configuration
------------------------------
Input Signal: the name of the signal this toggle listens for. Each time this signal goes ON, the output flips.

Output Signal: the name of the signal this toggle broadcasts. Other receivers can listen to this name to react to the toggled state.

Both names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Notes
------------------------------
On connecting to a network, the toggle immediately re-broadcasts its stored output state, so downstream receivers are always in sync.

If no other sender is keeping the output signal ON and the toggle is disconnected or dug up, its output contribution is automatically removed.
]])

g.signal_toggler = S([[
The Signal Network Switch is a signal receiver that controls network connectivity. It conditionally connects the machines behind its back face to the rest of the network, depending on whether a named signal is ON or OFF.

Usage
------------------------------
Right-click to configure the signal name and NOT mode.
Sneak + punch to show which node the switch is currently targeting (the back face direction).

The infotext above the node shows the current state: On or Off.

When the switch is ON, machines and cables connected through its back face become part of the network. When OFF, they are disconnected.

Placement
------------------------------
The switch is directional. Place it so its back face points toward the machines you want to gate. The entity indicator (shown on placement and on sneak+punch) marks the node the back face is targeting.

The main network connects to the switch from any face except the back face.

Configuration
------------------------------
NOT checkbox: when checked, the logic is inverted. The switch will open the connection when the signal is absent, and close it when the signal is present.

Signal Name: the name of the signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Notes
------------------------------
When the switch turns ON, the network automatically rescans to discover any machines connected through the back face. When it turns OFF, those machines are disconnected from the network.
]])

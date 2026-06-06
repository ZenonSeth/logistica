local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

g.signal_relay = S([[
The Signal Relay is a crafting component used in all signal machine recipes.

It is made from two Silverin Slices sandwiching a Mese Crystal Fragment, and yields 4 relays per craft.
]])

g.signals_overview = S([[
Signals are a named on/off messaging system that works within a single Logistica network.

# How signals work

A signal has a name (e.g. "power", "door_open") and a state: ON or OFF.
Signal names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Machines that send signals are called senders. Machines that react to signals are called receivers.

Multiple senders can broadcast the same signal name. The signal is considered ON as long as at least one sender is broadcasting it as ON. This is called OR logic: if any sender is on, the signal is on.

When a sender is removed from the network (disconnected or dug up), its contribution is automatically removed. If no other sender is keeping the signal ON, the signal turns OFF and all receivers are notified.

# Senders and Receivers

Senders start a signal. The Signal Switch is the simplest sender: a manual on/off switch.

Receivers listen for a signal by name and do something when it changes state. The Signal Lamp and Signal Toggler are both receivers.

Receivers also support a NOT mode: when NOT is checked, the receiver activates when the signal is ABSENT instead of when it is present.

# Signal names and scope

Signal names are scoped to the network. Two machines on different networks cannot affect each other through signals even if they share the same signal name.

All machines on the same network that share a signal name will communicate with each other.
]])

g.signal_button = S([[
The Signal Button is a momentary signal sender. When pressed it sends a named signal ON for one second, then automatically releases and sends it OFF again.

# Usage

Punch the button to press it. Right-click to open the settings and configure the signal name.

The infotext shows Ready (punch to press) or Pressed while the button is active.

# Configuration

Signal Name: the name of the signal this button broadcasts when pressed. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Behavior

Pressing the button while it is already pressed has no effect - it must complete its 1-second release before it can be pressed again.

If the button is mid-press when it connects to a network, it re-sends the ON signal to that network. When disconnected, its signal contribution is automatically removed.

# Example uses

- Trigger a one-shot action in a Logic Gate.
- Manually fire a timed pulse without needing a timer sender.
]])

g.signal_switch = S([[
The Signal Switch is a manual signal sender. It broadcasts a named ON or OFF signal to all receivers on the same network.

# Usage

- Punch (left-click) to toggle the switch ON or OFF.
- Right-click to open the settings and configure the signal name.

The infotext above the node shows the current state: On or Off.

# Configuration

Signal Name: the name of the signal this switch broadcasts. All receivers watching the same name on the same network will react.

Signal names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Notes

If the switch is ON when it is disconnected from the network (dug up or isolated by a Toggleable Cable), it will automatically remove its signal contribution from the network. If no other sender is keeping that signal ON, the signal turns OFF.
]])

g.signal_lamp = S([[
The Signal Lamp is a signal receiver that lights up when a named signal is active on the network.

When ON, the lamp emits light. When OFF, it is dark.

# Usage

Right-click to open the settings and configure the signal name and NOT mode.

The infotext above the node shows the current state: On or Off.

# Configuration

NOT checkbox: when checked, the lamp logic is inverted. The lamp turns ON when the named signal is ABSENT, and turns OFF when the signal is present. This is useful for "warning" setups where you want a light on when something is NOT running.

Signal Name: the name of the signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Colors

Signal Lamps can be crafted in different colors. All colors behave identically, they are purely cosmetic.
]])

g.signal_lamp_2c = S([[
The 2-Color Signal Lamp is a signal receiver that shows one of two colors depending on whether a named signal is active on the network. When no signal name is set, or when the node is not connected to a network, both lights are dark.

# Usage

Right-click to open the settings and configure which color is shown when the signal is ON.

# Configuration

Color dropdown: choose which color lights up when the signal is ON. The other color is shown automatically when the signal is OFF.

Signal Name: the name of the signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _). Leave empty to keep both lights dark.

# Notes

The 2-Color Signal Lamp can be crafted in different color pairs. All color pairs behave identically and are purely cosmetic.
]])

g.mesecon_signal_receiver = S([[
Only available if the Mesecons mod is present.

The Mesecon Signal Receiver bridges Mesecons wiring into the Logistica signal system. When it receives power from a Mesecon wire, it broadcasts a named Logistica signal as ON. When Mesecon power is removed, the signal is broadcast as OFF.

This allows Mesecon machines, buttons, pressure plates, and other Mesecon devices to trigger Logistica automation.

# Usage

Right-click to configure the signal name and optional NOT mode.

# Configuration

NOT checkbox: when checked, the logic is inverted. The Logistica signal is sent as ON when Mesecon power is ABSENT, and OFF when power is present.

Signal Name: the name of the Logistica signal to broadcast. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Notes

The receiver connects to Logistica cables from any face. Mesecon wires can connect from any face independently.

When disconnected from a Logistica network, the node stops broadcasting but still reacts to Mesecon power visually.
]])

g.mesecon_signal_sender = S([[
Only available if the Mesecons mod is present.

The Mesecon Signal Sender bridges the Logistica signal system into Mesecons wiring. When a named Logistica signal is ON, the node emits Mesecon power. When the signal is OFF, Mesecon power stops.

This allows Logistica signals to control Mesecon machines, doors, lights, and other Mesecon devices.

# Usage

Right-click to configure the signal name and optional NOT mode.

# Configuration

NOT checkbox: when checked, the logic is inverted. Mesecon power is emitted when the Logistica signal is ABSENT, and stopped when the signal is ON.

Signal Name: the name of the Logistica signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Loop protection

If a Mesecon Signal Receiver and a Mesecon Signal Sender are wired together in a loop (e.g. through a NOT configuration), the sender has a built-in cooldown that limits how fast it can change its Mesecon output. This prevents the loop from overloading the server, though the correct fix is to redesign the circuit.

# Notes

The sender connects to Logistica cables from any face. Mesecon wires connect from any face independently.

When disconnected from a Logistica network, the sender turns its Mesecon output off.
]])

g.signal_not_gate = S([[
The Signal NOT Gate is both a signal receiver and a signal sender. It reads one input signal and broadcasts the opposite state on a separate output signal.

If the input signal is ON, the output signal is OFF. If the input signal is OFF (or absent), the output signal is ON.

# Usage

Right-click to open the settings and configure the input and output signal names.

The infotext above the node shows the current output state: On or Off.

# Configuration

Input Signal: the name of the signal this gate listens for. When this signal changes, the gate immediately recalculates and sends the inverted result.

Output Signal: the name of the signal this gate broadcasts. Other receivers can listen to this name to react to the inverted state.

Both names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Notes

The NOT gate will immediately send OFF on its output signal when connected to a network, then update when the input signal arrives.

If no other sender is keeping the output signal ON and the gate is disconnected or dug up, its output contribution is automatically removed.
]])

g.signal_logic_gate = S([[
The Signal Logic Gate is both a signal receiver and a signal sender. It combines multiple input signals using a configurable logic rule and broadcasts the result on an output signal.

Three modes are available: AND, OR, and ADDER.

# Usage

Right-click to open the settings and configure the mode, input signals, and output signal.

The infotext above the node shows the current output state: On or Off.

# Modes

AND: the output is ON only if ALL listed input signals are currently ON. If any input is OFF or absent, the output is OFF.

OR: the output is ON if ANY of the listed input signals is currently ON. The output is only OFF when all inputs are absent or OFF.

ADDER: the output is ON if the number of input signals that are currently ON is greater than or equal to the configured threshold. Use this to require a minimum count of active signals.

# Configuration

Input Signals: a list of signal names separated by spaces or commas. The gate listens to all of them. Duplicates are ignored.

Output Signal: the name of the signal this gate broadcasts.

Threshold (ADDER mode only): the minimum number of inputs that must be ON for the output to turn ON. Can be set from 1 to 100000 using the [-] and [+] buttons.

All signal names must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Notes

The gate re-reads all input states fresh each time any one of its inputs changes, so the output always reflects the true combined state.

If the gate is disconnected or dug up, its output contribution is automatically removed from the network.
]])

g.signal_timer = S([[
The Signal Timer Sender is a signal sender that automatically cycles a named signal ON and OFF on a repeating timer. Configure the ON duration and OFF duration independently, each as a multiple of 0.5 seconds.

# Usage

Right-click to open the settings.
Use the Enable button to start or stop the timer.

The infotext above the node shows the signal name, the configured durations, and whether the node is Running or Paused, along with the current phase (ON or OFF).

# Configuration

Signal Name: the name of the signal this node broadcasts. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

ON duration: how long the signal stays ON each cycle, in seconds. Must be a multiple of 0.5 (minimum 0.5).

OFF duration: how long the signal stays OFF each cycle, in seconds. Must be a multiple of 0.5 (minimum 0.5).

Enable button: toggles the node between Running and Paused. When Paused, the signal is immediately sent as OFF and the timer stops.

# Behavior

When enabled, the timer starts immediately in the ON phase. After the ON duration elapses, it switches to OFF, then back to ON, and so on indefinitely.

If the node is not connected to a network, the timer continues ticking internally. The signal is sent as soon as the node joins a network.

When the node is disconnected (dug up or isolated), its signal contribution is automatically removed.

# Example uses

- Flash a lamp at a regular interval.
- Create a pulsed signal to periodically trigger another sender via a Logic Gate.
- Run a machine for a set time then pause it, repeatedly.
]])

g.signal_item_counter = S([[
The Signal Item Count Sender is a signal sender that monitors how many of a specific item are present across the network and broadcasts a named signal based on whether that count meets a configured condition.

Only items physically stored in Mass Storage nodes and Passive Supply Chests (including Vacuum Suppliers) are counted. Crafting Suppliers are excluded.

# Usage

Right-click to open the settings.
Use the Enable button to start or pause monitoring.

The infotext above the node shows the item being monitored, the condition, the signal name, and whether the node is Running or Paused.

# Configuration

Item to Monitor: place any item into the slot to select what to count. The slot is a filter only - the item is not consumed. Remove the item to stop monitoring.

Condition: choose >= (greater than or equal) or <= (less than or equal) from the dropdown.

Amount: the threshold number to compare the count against.

Signal Name: the name of the signal this node broadcasts when the condition is met. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

Respect Mass Storage Reserve: when checked, items that are reserved in Mass Storage slots are subtracted from the count before comparing. When unchecked, all stored items including reserved amounts are counted.

Enable button: toggles the node between Running and Paused. When Paused, the signal is immediately sent as OFF regardless of the current item count.

# Behavior

The node checks the item count once per second. When the condition is met, the signal is sent as ON. When the condition is not met, the signal is sent as OFF.

If no item is set in the filter slot, the signal is always OFF.

When the node is disconnected from the network (dug up or isolated), its signal contribution is automatically removed.

# Example uses

- Send a signal when iron ingot stock drops below 500 (condition: <= 499).
- Trigger an alarm when a material exceeds a cap (condition: >= 1000).
- Gate a machine with a Signal Toggler so it only runs while supplies are available.
]])

g.signal_toggler = S([[
The Signal Toggler is a signal receiver that controls network connectivity. It conditionally connects the machines behind its back face to the rest of the network, depending on whether a named signal is ON or OFF.

# Usage

Right-click to configure the signal name and NOT mode.
Sneak + punch to show which node the toggler is currently targeting (the back face direction).

The infotext above the node shows the current state: On or Off.

When the toggler is ON, machines and cables connected through its back face become part of the network. When OFF, they are disconnected.

# Placement

The toggler is directional. Place it so its back face points toward the machines you want to gate. The entity indicator (shown on placement and on sneak+punch) marks the node the back face is targeting.

The main network connects to the toggler from any face except the back face.

# Configuration

NOT checkbox: when checked, the logic is inverted. The toggler will open the connection when the signal is absent, and close it when the signal is present.

Signal Name: the name of the signal to listen for. Must use only lowercase letters, digits, and underscores (a-z 0-9 _).

# Notes

When the toggler turns ON, the network automatically rescans to discover any machines connected through the back face. When it turns OFF, those machines are disconnected from the network.
]])

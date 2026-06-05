local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

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

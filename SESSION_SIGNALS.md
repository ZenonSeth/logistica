# Session Summary: Signals System

Branch: logistica-2.0

---

## What was built

A complete signaling system for Logistica. Signals are named ON/OFF values scoped to a network. OR semantics: a signal is ON if any sender has it ON. Signal names must be lowercase a-z, 0-9, _ only (uppercase is auto-lowercased by `logistica.sanitize_signal_name` in `util/common.lua`).

---

## New files

### logic/signal_switch.lua
Logic for the signal switch (sender). Key functions:
- `signal_switch_get_name(pos)`, `signal_switch_is_on(pos)`
- `signal_switch_toggle(pos)` -- swaps node variant, calls signal_send, updates infotext
- `signal_switch_set_name(pos, newName)` -- sends OFF on old name, updates meta, re-sends if on
- `signal_switch_on_connect(pos, networkId)` -- re-sends current state
- `signal_switch_on_disconnect(pos, networkId)` -- calls signal_remove_sender
- `signal_switch_update_infotext(pos)` -- sets "On"/"Off"

### api/signal_switch.lua
Registers `logistica:signal_switch` and `logistica:signal_switch_on`.
- paramtype2 = "colorfacedir", nodebox with backplate + lever
- on_punch toggles, on_rightclick opens formspec
- Formspec: signal name field + toggle button + button_exit Save
- CRITICAL: fields.save checked BEFORE fields.quit (button_exit sends both simultaneously)

### logic/signal_lamp.lua
Logic for the signal lamp (receiver/display). Key functions:
- `signal_lamp_get_name(pos)`, `signal_lamp_get_not(pos)`
- `signal_lamp_set_state(pos, shouldBeOn)` -- swaps node variant, updates infotext
- `signal_lamp_on_signal_received(pos, sigName, sigIsOn)` -- XOR with NOT flag
- `signal_lamp_on_connect(pos, networkId)` -- reads signal_get_state, applies
- `signal_lamp_on_disconnect(pos, networkId)` -- applies with sigIsOn=false

### api/signal_lamp.lua
Registers `logistica:signal_lamp_white` and `logistica:signal_lamp_white_on`.
- light_source 0 (off) / 14 (on)
- Formspec: NOT checkbox + signal name + button_exit Save
- NOT checkbox uses standalone `if` not `elseif` so it fires even alongside fields.save

### logic/signal_lamp_2c.lua
Logic for the 2-color signal lamp. Key functions:
- `signal_lamp_2c_get_name(pos)`, `signal_lamp_2c_get_active_color(pos)` -- returns "a" or "b"
- `apply_state(pos, sigIsOn)` -- swaps to _a or _b variant based on active_color + sigIsOn; shows infotext with color name from meta; shows dark (base) variant if signal_name is empty
- `signal_lamp_2c_on_signal_received`, `signal_lamp_2c_on_connect`, `signal_lamp_2c_on_disconnect`
- Color names are stored in meta at placement ("color_a_name", "color_b_name") so logic can read them for infotext without knowing the registry

### api/signal_lamp_2c.lua
Registers 3-variant lamps (base=dark, _a, _b). Key design:
- `registry[node_name] = {color_a, color_b, base}` -- all 3 variants map to same entry
- Formspec: dropdown (color A or B) + "if: [signal_name]" + "else: [other color]" label
- Dropdown fires immediately and reshows formspec to update "else:" label
- Empty signal_name is allowed (saves "" -- node stays dark)
- 2 textures per variant: top/bottom + 4 sides → tiles = {tb, tb, side, side, side, side}
- Nodebox: top light (y 2/16→8/16) + neck (y -2/16→2/16, narrower) + bottom light (y -8/16→-2/16)
- paramtype2 = "facedir", light_source 12 when lit
- Registration API: `register_signal_lamp_2c(desc, name, color_a_name, tile_a_top, tile_a_side, color_b_name, tile_b_top, tile_b_side, tile_off_top, tile_off_side)`

### logic/signal_toggler.lua
Logic for the signal toggler (receiver that gates network connectivity).
- `get_signal_toggler_target(pos)` -- returns pos + dirs.backward
- `signal_toggler_is_on(pos)`
- `set_toggler_state(pos, shouldBeOn)` -- returns true if changed, updates infotext
- `signal_toggler_on_signal_received`, `signal_toggler_on_connect`, `signal_toggler_timer`, `signal_toggler_on_disconnect`

### api/signal_toggler.lua
Registers `logistica:signal_toggler` and `logistica:signal_toggler_on`.
- Formspec: NOT checkbox + signal name + button_exit Save

### logic/signal_not_gate.lua
Logic for the NOT gate (signal_gates group, both receiver and sender). Key functions:
- `signal_not_gate_get_input(pos)`, `signal_not_gate_get_output(pos)`
- `signal_not_gate_on_signal_received(pos, sigName, sigIsOn)` -- returns true/false (BFS contract)
- `signal_not_gate_on_connect(pos, networkId)` -- starts 0.1s deferred timer
- `signal_not_gate_timer(pos)` -- reads input signal, sends inverted output
- `signal_not_gate_on_disconnect(pos, networkId)` -- calls signal_remove_sender
- Infotext: "NOT: <input>\nOutput: On/Off"

### api/signal_not_gate.lua
Registers `logistica:signal_not_gate` and `logistica:signal_not_gate_disabled`.
- Formspec: input signal field + output signal field + hint labels + button_exit Save

### logic/signal_logic_gate.lua
Logic for AND/OR/ADDER logic gate (signal_gates group). Key functions:
- `signal_logic_gate_get_mode(pos)` -- returns "and"/"or"/"adder"
- `signal_logic_gate_get_threshold(pos)` -- integer, min 1 max 100000
- `signal_logic_gate_get_inputs(pos)` -- space-separated sanitized signal list
- `signal_logic_gate_get_output(pos)`
- `signal_logic_gate_on_signal_received(pos, sigName, sigIsOn)` -- re-reads ALL input states at evaluation time
- Infotext: "AND/OR/ADD N: sig1, sig2\nOutput: On/Off"

### api/signal_logic_gate.lua
Registers `logistica:signal_logic_gate` and `logistica:signal_logic_gate_disabled`.
- Formspec: mode label + mode description + [AND][OR][ADDER] buttons + threshold row (ADDER only) + input signals field + output signal field + button_exit Save

### logic/mesecon_signaler.lua
Logic for the Mesecon Signal Receiver (mesecon effector → logistica signal sender). Key functions:
- `mesecon_signaler_get_name(pos)`, `mesecon_signaler_get_not(pos)`
- `mesecon_signaler_action_on(pos)` -- saves "mesecon_on"="1", swaps to _on variant, calls apply_signal
- `mesecon_signaler_action_off(pos)` -- saves "mesecon_on"="0", swaps to base variant, calls apply_signal
- `mesecon_signaler_on_connect(pos, networkId)` -- re-applies current mesecon state to logistica
- `mesecon_signaler_on_disconnect(pos, networkId)` -- calls signal_remove_sender
- apply_signal: reads mesecon_on + NOT flag, XORs, calls logistica.signal_send

### api/mesecon_signaler.lua
Registers `logistica:mesecon_signaler` and `logistica:mesecon_signaler_on`.
- Guard: `if not minetest.get_modpath("mesecons") then return end`
- Logistica group: signal_senders
- Nodebox: connected type, wide base plate (y -8/16 → -6/16) + cable-width center column, connects top + 4 sides, no connect_bottom
- Mesecon: effector with action_on/action_off
- Formspec: description label + NOT checkbox + signal name + Save

### logic/mesecon_sender.lua
Logic for the Mesecon Signal Sender (logistica signal receiver → mesecon receptor). Key functions:
- `mesecon_sender_get_name(pos)`, `mesecon_sender_get_not(pos)`
- `mesecon_sender_set_visual(pos, isOn)` -- swaps node variant only, no mesecon calls

### api/mesecon_sender.lua
Registers `logistica:mesecon_sender` and `logistica:mesecon_sender_on`.
- Guard: `if not minetest.get_modpath("mesecons") then return end`
- Logistica group: signal_receivers
- Nodebox: identical to mesecon_signaler
- Mesecon: receptor with state=on/off on respective variants, rules=mesecon.rules.default
- `apply_state(pos, isOn)`: THROTTLED -- writes pending_state to meta, fires immediately if >= COOLDOWN (0.3s) since last fire, otherwise starts node timer
- `on_timer(pos)`: reads pending_state from meta, fires mesecon receptor, resets last_send_time
- Loop protection: rapid oscillation (e.g. receiver + sender with NOT via same wire) collapses to one mesecon call per 0.3s
- Formspec: same layout as mesecon_signaler with reversed description

---

## Modified files

### logic/groups.lua
Added to GROUPS:
- `signal_senders` -> NETWORK_GROUPS.signal_senders
- `signal_receivers` -> NETWORK_GROUPS.signal_receivers
- `signal_togglers` -> NETWORK_GROUPS.signal_receivers (NOT its own network group)
- `signal_gates` -> NETWORK_GROUPS.signal_receivers (gates are receivers that also send)

Added to NETWORK_GROUPS and NETWORK_GROUP_NAMES:
- `signal_senders`, `signal_receivers`

### logic/network_logic.lua
Major additions -- see original session notes for full detail. Key points:
- `network.signals = {}` on create_network
- `signal_send(pos, name, isOn)` -- adds/removes sender, notifies receivers, BFS for gates
- `signal_remove_sender(pos, networkId)` -- removes all of this node's signal contributions
- `signal_get_state(networkId, name)` -- returns bool
- `notify_signal_receivers` -- gates go into BFS queue, non-gates called immediately
- BFS cycle detection: {hash -> {signal_name -> true}}, only marks visited when on_signal_received returns true
- Signal toggler scan: ON toggler adds itself to connections (relay); blockedToggler check prevents joining from backward (output) side -- checks `offset == d.forward` where offset is direction from scanner to toggler
- Public API: `on_signal_sender_change`, `on_signal_receiver_change`, `on_signal_toggler_change`, `rescan_network_at_pos`

### registration/machines_api_reg.lua
Registered all signal nodes including:
- Signal Lamp White (single color)
- Signal Lamp 2-Color blue/red (signal_lamp_2c_br)
- Signal NOT Gate, Signal Logic Gate
- Signal Switch, Signal Toggler
- Mesecon Signal Receiver (mesecon_signaler) -- mesecons guarded
- Mesecon Signal Sender (mesecon_sender) -- mesecons guarded

### guide/guide_desc_signals.lua + guide/guide_content.lua
Guide pages written for all signal nodes:
- Signals Overview
- Signal Switch, Signal Lamp, Signal Lamp (2-Color), Signal Toggler
- Signal NOT Gate, Signal Logic Gate
- Mesecon Signal Receiver, Mesecon Signal Sender (both note "only available if Mesecons mod is present")

---

## Key design decisions / gotchas

1. **signal_togglers node group maps to signal_receivers network group** (not its own).
2. **signal_gates node group maps to signal_receivers network group**. Gates are both receivers and senders. Identified by GROUPS.signal_gates.is() in notify_signal_receivers for BFS routing.
3. **BFS cycle detection uses {hash -> {signal_name -> true}}** not just hash. Prevents false positives when a gate ignores a signal (returns false) and later receives its real input in same wave.
4. **on_signal_received return value contract for gates**: return true if signal matched and processed, false/nil if ignored. BFS only marks visited on true.
5. **Post-dig network lookup**: get_network_or_nil fails for dug nodes. Use get_unchecked_cached_network_id(oldMeta).
6. **try_to_add_to_network does NOT call notify_connected**. For nodes that need to initialize state from existing signals on placement, explicitly call notify_connected after (done for toggler) or use deferred timer (gates, lamp).
7. **button_exit sends both fields.save and fields.quit**. Always check fields.save BEFORE fields.quit.
8. **Luanti checkboxes fire immediately on click**. Use standalone `if` (not `elseif`) for checkbox handlers so they run alongside fields.save.
9. **Signal toggler scan**: ON toggler adds itself to connections[] so scan propagates through it. blockedToggler check (offset == d.forward of the toggler) prevents gated-side cables from adding the toggler from the wrong direction. This check IS implemented and working.
10. **Signal name sanitization**: lowercase only (a-z 0-9 _). Uppercase auto-lowercased. Empty string allowed for 2c lamp and mesecon sender (means "inactive").
11. **2c lamp registry**: all 3 variants (base, _a, _b) map to same registry entry so get_entry(pos) works from any variant.
12. **Mesecon sender throttle**: COOLDOWN = 0.3s. Uses node timer for deferred firing -- calling timer:start() again resets it naturally. pending_state in meta always holds latest desired state. on_timer reads it and fires once.
13. **Mesecon sender after_dig**: explicitly calls apply_state(pos, false) BEFORE on_signal_receiver_change so mesecon is notified the receptor went dark before the node disappears.

---

## Textures (all created by user)
All signal node textures exist. See textures/ folder.

---

## TODO / next steps

### Crafting recipes
All signal nodes need crafting recipes. Nodes without recipes:
- signal_switch, signal_lamp_white, signal_lamp_2c_br
- signal_toggler, signal_not_gate, signal_logic_gate
- mesecon_signaler, mesecon_sender (guard with mesecons check)

### New signal machines to build

**Item Count Reader** (most important next):
- Reads the total count of a specific item across the entire Logistica network
- Sends a Logistica signal ON when count >= configured threshold
- Configuration: item name (or item picker), threshold number, signal name to send, optional NOT
- Group: signal_senders (it actively sends a signal)
- Needs: periodic polling (node timer every N seconds) to recheck count
- Could also react to network inventory change events if those exist

**Other possible future signalers:**
- Machine state reader (is machine X active/idle?)
- Network full/empty detector (is any storage full?)
- Player proximity detector (mesecons has this but a logistica-native one could be useful)
- Timer/clock signal (sends ON/OFF on a configurable interval, pure sender)

### Testing
- NOT gate and Logic Gate need in-game testing (placed but not verified end-to-end)
- Mesecon receiver/sender need in-game testing with actual Mesecons wiring
- 2c lamp needs in-game testing of dropdown + else label update

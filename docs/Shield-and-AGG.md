# Shield and AGG

## Shield Features

The HUD displays shield status including current resistances, shield strength, and on/off state.

### Auto Shield Toggle

Set `AutoShieldToggle = true` to automatically manage shield state based on PvP zone status:

- In safe (PvE) zones: shield is automatically disabled to remove the visual graphic
- In PvP zones: shield is automatically enabled

### Shield Controls

| Keybind / Command | Action |
|-------------------|--------|
| ALT-SHIFT-6 | Vent shield (only if not at max HP and not on cooldown) |
| ALT-SHIFT-7 | Manual shield toggle (overridden by AutoShieldToggle if enabled) |
| `/resist 0.15, 0.15, 0.15, 0.15` | Set shield resistances (values must total 0.60). Can only be applied once per minute. |

### Auto Resist

Set `AutoShieldPercent` to a value greater than 0 to enable automatic resistance adjustment. When the shield drops below this percentage, the system analyzes recent incoming damage types and redistributes resistances accordingly.

---

## AGG Features

Requires an antigravity generator connected to the control unit. If you are using an external AGG controller, set `ExternalAGG = true`.

### General Behavior

- **AGG on, not moving:** The AGG base altitude is treated as ground level for brake landing calculations.
- **Alt-4 to waypoint with saved AGG altitude:** Turns on AGG, sets the target height, and uses that height for flight.
- **AGG on during altitude hold:** The hold altitude is set to the current AGG altitude and changes if the AGG altitude is adjusted.
- **Alt-6 from ground with AGG on:** Takes off to the AGG height.
- **Alt-6-6:** Behaves the same as Alt-6 with AGG on.

### AGG Commands

| Command / Action | Description |
|------------------|-------------|
| `/agg <targetheight>` | Manually set AGG target height |
| Save AGG Alt button | Save current AGG height at the current IPH waypoint |
| Clear AGG Alt button | Clear saved AGG height from the waypoint |

### AGG Scenarios

The following scenarios describe how autopilot interacts with the AGG in different situations:

#### Scenario 1: Ground, AGG off, Alt-4 same planet

Normal takeoff procedure. If you turn on AGG before arrival:

- **Above AGG height:** Brake landing descends to AGG height and holds.
- **Below AGG height:** Normal brake landing to the surface.
- **AGG turned on during takeoff:** Changes the takeoff target height to the AGG height.

#### Scenario 2: Ground, AGG on, Alt-4 same planet

Behaves the same as turning on AGG during takeoff in Scenario 1.

#### Scenario 3: In air at AGG height, AGG on, Alt-4 same planet

Releases brakes, levels and aligns toward the waypoint, then waits for throttle input. Proceeds to waypoint at the current AGG height.

#### Scenario 4: In air at AGG height, AGG on, Alt-4-4 same planet

Performs an orbital hop. Returns at 11% atmosphere depth, then performs an AGG brake landing to the AGG altitude.

#### Scenario 5: Ground, AGG on, Alt-4 other planet

Normal takeoff and interplanetary travel. Arrival behavior follows Scenario 4.

#### Scenario 6: Ground, AGG on, Alt-4-4

Takes off to low orbit height. Arrival behavior follows Scenario 4.

#### Scenario 7: In air at AGG height, Alt-4 other planet

Standard interplanetary autopilot procedure with no special AGG handling.

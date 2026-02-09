# Settings

Complete reference for all ArchHUD user variables. For HUD element descriptions, see [HUD Display](HUD-Display.md). For keybind configuration, see [Keybinds](Keybinds.md).

---

## How to Change Settings

There are four ways to modify ArchHUD settings:

| Method | When to Use |
|--------|-------------|
| **Edit Lua Parameters** | Right-click seat > Advanced > Edit Lua Parameters. Available in the modular version only. Changes are written to the `.conf` file. |
| **Lua Chat command** | While seated, type `/G VariableName newValue` in Lua Chat to change a value immediately. |
| **userglobals.lua** | Edit the file at `autoconf/custom/archhud/custom/userglobals.lua` for persistent overrides that survive databank resets. |
| **Settings button** | Click the Settings button in the HUD (button control mode) to visually toggle true/false variables. |

Use `/G dump` in Lua Chat to print all current variable names and their values.

---

## Setting Load Order

Settings are loaded in a specific order, with each step overriding the previous:

| Priority | Source | Notes |
|----------|--------|-------|
| 1 (lowest) | `.conf` file defaults | Set via Edit Lua Parameters |
| 2 | `userglobals.lua` | Loaded if the file exists |
| 3 (highest) | Databank saved values | Applied unless `useTheseSettings` is true |

On exit, all current values are saved to the databank.

---

## Special Settings

### useTheseSettings

| | |
|---|---|
| **Default** | `false` |
| **Purpose** | When set to `true`, forces the `.conf` and `userglobals.lua` values to take priority over databank-saved values. |

**Usage:** Set `useTheseSettings = true` when you want to reset variables to their `.conf` / `userglobals.lua` values. After standing up from the seat (which saves the new values to the databank), set it back to `false` so future sessions resume from the databank as normal.

### userControlScheme

| | |
|---|---|
| **Default** | `"keyboard"` |
| **Options** | `"keyboard"`, `"virtual joystick"`, `"mouse"` |

Change the control scheme with **Shift + button click** on the control scheme button in the HUD, or set it directly via `/G userControlScheme "virtual joystick"`.

---

## String Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `userControlScheme` | `"keyboard"` | Active control scheme: `"keyboard"`, `"virtual joystick"`, or `"mouse"` |
| `soundFolder` | `"archHUD"` | Name of the sound pack folder to use for audio alerts |
| `privateFile` | `"name"` | Filename for private/custom location waypoints |

---

## True/False Variables

### General

| Variable | Default | Description |
|----------|---------|-------------|
| `showHud` | `true` | Show the ArchHUD overlay |
| `hideHudOnToggleWidgets` | `true` | Hide the ArchHUD overlay when vanilla widgets are toggled on |
| `brightHud` | `false` | Prevent the HUD from dimming in freelook mode |
| `DisplayOdometer` | `true` | Show the odometer indicator bar (heading info remains visible when hidden) |
| `AlwaysVSpd` | `false` | Keep the vertical speed meter visible even when ALT-3 hides other elements |
| `BarFuelDisplay` | `true` | Use bar-style fuel display (`false` for traditional numeric readout) |
| `DisplayDeadZone` | `true` | Show the deadzone circle when using virtual joystick mode |

### Input and Control

| Variable | Default | Description |
|----------|---------|-------------|
| `freeLookToggle` | `true` | Freelook is toggle-based (`false` for vanilla hold-to-look) |
| `BrakeToggleDefault` | `true` | Brake key toggles on/off (`false` for vanilla hold-to-brake) |
| `InvertMouse` | `false` | Invert the mouse Y axis |
| `ShiftShowsRemoteButtons` | `true` | Holding Shift reveals button overlay on remote control |

### Flight Behavior

| Variable | Default | Description |
|----------|---------|-------------|
| `autoRollPreference` | `false` | Automatically roll to level in atmosphere |
| `VanillaRockets` | `false` | Use vanilla rocket engine behavior |
| `AtmoSpeedAssist` | `true` | Enable atmospheric speed limiting system |
| `ForceAlignment` | `false` | Force velocity vector alignment while in altitude hold |
| `CollisionSystem` | `true` | Enable graduated collision detection and avoidance |
| `MaintainOrbit` | `true` | Prevent orbit from decaying (station-keeping) |
| `PreventPvP` | `true` | Automatically stop the ship before crossing a PvP boundary |

### Remote and ECU

| Variable | Default | Description |
|----------|---------|-------------|
| `RemoteFreeze` | `false` | Freeze character in place when using remote control |
| `RemoteHud` | `false` | Show the full HUD overlay on remote control |
| `ECUHud` | `false` | Show the full HUD overlay on Emergency Control Unit |

### External Systems

| Variable | Default | Description |
|----------|---------|-------------|
| `ExternalAGG` | `false` | Disable ArchHUD AGG control (for ships using an external AGG system) |
| `UseSatNav` | `false` | Enable Trog SatNav integration |

### Monitoring and Safety

| Variable | Default | Description |
|----------|---------|-------------|
| `ShouldCheckDamage` | `true` | Enable damage monitoring and repair arrows |
| `AbandonedRadar` | `false` | Check radar contacts for abandoned status |
| `AutoShieldToggle` | `true` | Automatically toggle shields on/off when crossing PvE/PvP boundaries |

### Sound

| Variable | Default | Description |
|----------|---------|-------------|
| `voices` | `true` | Enable voice audio alerts |
| `alerts` | `true` | Enable sound effect alerts |

### Miscellaneous

| Variable | Default | Description |
|----------|---------|-------------|
| `SetWaypointOnExit` | `true` | Automatically set a waypoint at the ship's location when exiting the seat |

---

## Ship Handling Variables

### Speed and Throttle

| Variable | Default | Description |
|----------|---------|-------------|
| `AtmoSpeedLimit` | `1175` | Maximum atmospheric speed in km/h |
| `SpaceSpeedLimit` | `66000` | Maximum space speed in km/h (`66000` effectively disables the limit) |
| `MaxGameVelocity` | `-1.0` | Maximum autopilot speed in m/s (`-1` = auto-detect from game settings) |
| `AutopilotInterplanetaryThrottle` | `1.0` | Throttle fraction for interplanetary autopilot (0.0 -- 1.0) |

### Takeoff and Landing

| Variable | Default | Description |
|----------|---------|-------------|
| `brakeLandingRate` | `30` | Maximum descent speed in m/s during brake landing |
| `AutoTakeoffAltitude` | `1000` | Target height above ground for auto takeoff |
| `TargetHoverHeight` | `50` | Hover height in meters for G-key takeoff |
| `LandingGearGroundHeight` | `0` | AGL reading when the ship is resting on the ground |
| `allowedHorizontalDrift` | `0.01` | Maximum horizontal drift in m/s permitted during brake landing |

### Pitch and Orientation

| Variable | Default | Description |
|----------|---------|-------------|
| `MaxPitch` | `30` | Maximum pitch angle in degrees during takeoff and altitude changes |
| `ReEntryPitch` | `-30` | Maximum downward pitch angle in degrees during re-entry freefall |
| `YawStallAngle` | `35` | Yaw stall angle in degrees |
| `PitchStallAngle` | `35` | Pitch stall angle in degrees |

### Autopilot

| Variable | Default | Description |
|----------|---------|-------------|
| `AutopilotSpaceDistance` | `5000` | Distance in meters at which the autopilot stops from a space waypoint |
| `TargetOrbitRadius` | `1.2` | Orbit tightness as a multiple of atmosphere height |
| `LowOrbitHeight` | `2000` | Height above the atmosphere boundary for orbital hops |
| `ReEntryHeight` | `100000` | Re-entry height above the surface (100000 = approximately 11% of atmosphere) |

### Engine and Fuel

| Variable | Default | Description |
|----------|---------|-------------|
| `warmup` | `32` | Space engine warmup time in seconds |
| `fuelTankHandlingAtmo` | `0` | Atmospheric fuel tank handling skill level (0--5) |
| `fuelTankHandlingSpace` | `0` | Space fuel tank handling skill level (0--5) |
| `fuelTankHandlingRocket` | `0` | Rocket fuel tank handling skill level (0--5) |
| `ContainerOptimization` | `0` | Container optimization skill level (0--5) |
| `FuelTankOptimization` | `0` | Fuel tank optimization skill level (0--5) |
| `ExtraEscapeThrust` | `1.0` | Multiplier for thrust when escaping atmosphere |
| `ExtraLongitudeTags` | `"none"` | Additional engine tags for longitudinal thrust |
| `ExtraLateralTags` | `"none"` | Additional engine tags for lateral thrust |
| `ExtraVerticalTags` | `"none"` | Additional engine tags for vertical thrust |

### Shield and Combat

| Variable | Default | Description |
|----------|---------|-------------|
| `AutoShieldPercent` | `0` | Automatically adjust shield resistances when shield drops below this percentage (0 = disabled) |
| `EmergencyWarp` | `0` | Distance threshold in meters for emergency warp activation (0 = disabled) |
| `DockingMode` | `1` | Docking behavior: `1` = Manual, `2` = Automatic, `3` = Semi-automatic |

---

## HUD Positioning Variables

### Resolution

| Variable | Default | Description |
|----------|---------|-------------|
| `ResolutionX` | `1920` | HUD resolution width in pixels |
| `ResolutionY` | `1080` | HUD resolution height in pixels |

These values do not need to match the actual game resolution. Setting them smaller makes HUD elements appear larger; setting them larger makes elements appear smaller.

### Element Positions

All position variables use pixel coordinates within the HUD resolution space. Setting both X and Y of any element to `0` hides that element.

| Element | X Variable | Y Variable | Default X | Default Y |
|---------|-----------|-----------|-----------|-----------|
| Nav Ball | `centerX` | `centerY` | 960 | 540 |
| Throttle Meter | `throtPosX` | `throtPosY` | 1300 | 540 |
| Vertical Speed Meter | `vSpdMeterX` | `vSpdMeterY` | 1525 | 325 |
| Altimeter | `altMeterX` | `altMeterY` | 550 | 540 |
| Fuel Display | `fuelX` | `fuelY` | 30 | 700 |
| Shield Info | `shieldX` | `shieldY` | 1750 | 250 |
| Radar Info | `radarX` | `radarY` | 1750 | 350 |
| Friendly Contacts | `friendlyX` | `friendlyY` | -- | -- |
| Orbit Map | `OrbitMapX` | `OrbitMapY` | 0 | 30 |

### Nav Ball and Orbit Map Sizing

| Variable | Default | Description |
|----------|---------|-------------|
| `circleRad` | `400` | Nav ball radius in pixels (`0` = hidden, `< 200` = small style, `>= 200` = F16 style) |
| `OrbitMapSize` | `250` | Orbit map diameter in pixels (should be divisible by 4) |

### HUD Colors

| Variable | Default | Description |
|----------|---------|-------------|
| `SafeR` | `130` | PvE HUD color -- red component (0--255) |
| `SafeG` | `224` | PvE HUD color -- green component (0--255) |
| `SafeB` | `255` | PvE HUD color -- blue component (0--255) |
| `PvPR` | `255` | PvP HUD color -- red component (0--255) |
| `PvPG` | `0` | PvP HUD color -- green component (0--255) |
| `PvPB` | `0` | PvP HUD color -- blue component (0--255) |

### Deadzone

| Variable | Default | Description |
|----------|---------|-------------|
| `DeadZone` | `50` | Deadzone radius in pixels for virtual joystick mode |

---

## Flight Physics Variables

### Speed Change

| Variable | Default | Description |
|----------|---------|-------------|
| `speedChangeLarge` | `5` | Speed change per tap as a percentage |
| `speedChangeSmall` | `1` | Speed change per hold as a percentage |

### Mouse Sensitivity

| Variable | Default | Description |
|----------|---------|-------------|
| `MouseXSensitivity` | `0.003` | Virtual joystick X-axis sensitivity |
| `MouseYSensitivity` | `0.003` | Virtual joystick Y-axis sensitivity |

### Rotation and Roll

| Variable | Default | Description |
|----------|---------|-------------|
| `autoRollFactor` | `2` | Auto-roll correction strength |
| `rollSpeedFactor` | `1.5` | Roll input multiplier |
| `autoRollRollThreshold` | `180` | Maximum roll angle in degrees for auto-roll to engage |
| `minRollVelocity` | `150` | Minimum velocity in m/s for auto-roll to engage |
| `pitchSpeedFactor` | `0.8` | Keyboard pitch rate multiplier |
| `yawSpeedFactor` | `1` | Keyboard yaw rate multiplier |
| `torqueFactor` | `2` | Rotation force multiplier |

### Autopilot Tuning

| Variable | Default | Description |
|----------|---------|-------------|
| `TrajectoryAlignmentStrength` | `0.002` | Autopilot velocity alignment strength |
| `DampingMultiplier` | `40` | Autopilot orientation dampening factor |
| `FastOrbit` | `0.0` | Orbit speed multiplier (0.0 = normal speed) |

### Braking

| Variable | Default | Description |
|----------|---------|-------------|
| `brakeSpeedFactor` | `3` | Brake force multiplier based on velocity |
| `brakeFlatFactor` | `1` | Brake force flat multiplier |

### Tick Rate

| Variable | Default | Description |
|----------|---------|-------------|
| `hudTickRate` | `0.0666667` | HUD refresh interval in seconds (approximately 15 Hz) |

---

## Using userglobals.lua

The `userglobals.lua` file allows you to set persistent variable overrides that survive databank resets.

**File location:**

```
autoconf/custom/archhud/custom/userglobals.lua
```

**Setup:**

1. Navigate to `autoconf/custom/archhud/custom/`.
2. Rename `userglobals.example` to `userglobals.lua`.
3. Edit the file to set your preferred values.

**Load behavior:**

- Variables in `userglobals.lua` are loaded after `.conf` defaults but before databank values.
- Under normal operation (`useTheseSettings = false`), databank values still override `userglobals.lua`.
- To force `userglobals.lua` values to take effect, set `useTheseSettings = true`, sit down, then set it back to `false`.

---

## Copying Databank

Use the `/copydatabank` chat command to copy all settings from your active `dbHud` databank to a blank databank.

**Steps:**

1. Link a blank databank to the seat.
2. Run the autoconf to register the new databank.
3. While seated, type `/copydatabank` in Lua Chat.
4. Check the slot names -- you may need to swap `dbHud_1` and `dbHud_2` if they were assigned in the wrong order.

---

## Sample Resolution Settings

### 3440 x 1440 (Ultrawide)

| Variable | Value |
|----------|-------|
| `ResolutionX` | `3440` |
| `ResolutionY` | `1440` |
| `circleRad` | `400` |
| `centerX` | `1720` |
| `centerY` | `720` |
| `throtPosX` | `2050` |
| `throtPosY` | `720` |
| `vSpdMeterX` | `2900` |
| `vSpdMeterY` | `400` |
| `altMeterX` | `1330` |
| `altMeterY` | `710` |
| `fuelX` | `5` |
| `fuelY` | `600` |
| `shieldX` | `3132` |
| `shieldY` | `300` |
| `radarX` | `3170` |
| `radarY` | `475` |

# HUD Display

This page covers all visual elements of the ArchHUD overlay, including panels, meters, indicators, and their configuration options. For keybinds that control these elements, see [Keybinds](Keybinds.md). For a complete variable reference, see [Settings](Settings.md).

---

## Button Control

Tap **LMB** (left mouse button) to reveal the HUD button overlay. Move your pointer over an item and click to activate it. The overlay displays mode toggles, autopilot actions, and system controls. Clicking away or tapping LMB again dismisses the overlay.

- **Shift + button click** cycles through control schemes (`keyboard`, `virtual joystick`, `mouse`).
- The Settings button opens a visual panel for toggling true/false variables without using chat commands.

---

## System Panels

Five buttons appear in the upper-left corner of the HUD. These are clickable when button control mode is active:

| Button | Description |
|--------|-------------|
| Info   | Opens the Info Panel with live ship statistics |
| Orbit  | Opens the Orbit Panel with orbital mechanics display |
| Scope  | Opens the Scope Panel with planetary heading view |
| Hide   | Hides the system panel buttons |

A fifth button provides additional context-dependent functionality. All five buttons are only interactive while button control mode is active.

---

## Info Panel

The Info Panel displays live ship telemetry and computed statistics. All values update in real time.

| Field | Description |
|-------|-------------|
| BrkTime | Time required to brake from current speed to a full stop |
| BrkDist | Distance required to brake from current speed to a full stop |
| Trip | Distance traveled since sitting down |
| Lifetime | Total distance traveled across all sessions |
| Trip Time | Elapsed time since sitting down |
| Total Time | Cumulative flight time across all sessions |
| Mass | Current ship mass including cargo and fuel |
| Max Brake | Maximum braking force available |
| Max Thrust | Maximum thrust available |
| Safe Atmo Mass | 50% of the mass that atmospheric engines can barely move |
| Safe Space Mass | 50% of the mass that space engines can barely move |
| Safe Hover Mass | 50% of the mass that hover engines can barely support |
| Safe Brake Mass | 50% of the mass that brakes can barely stop |
| Space Fuel Used | Space fuel consumed this session (printed to Lua chat on exit) |
| Set Max Speed | Current configured speed limit |
| Actual Max Speed | Computed maximum speed based on thrust and drag |
| Friction Burn Speed | Speed at which atmospheric friction causes hull damage (minimum 1200 km/hr) |

---

## Orbit Panel

Displays a graphical orbit map with orbital statistics for the current trajectory.

- **Degraded orbit** -- When periapsis dips into the atmosphere or terrain, the periapsis value is hidden and orbit lines render in red.
- **Escape velocity** -- When on an escape trajectory, the panel switches to a system-level map showing your position relative to other bodies.
- **Atmosphere visibility** -- The orbit panel is hidden while in atmosphere until the ship reaches minimum space engine activation height.

**Configuration:**

| Variable | Default | Description |
|----------|---------|-------------|
| `OrbitMapSize` | 250 | Orbit map diameter in pixels (should be divisible by 4) |
| `OrbitMapX` | 0 | Orbit map horizontal position |
| `OrbitMapY` | 30 | Orbit map vertical position |

---

## Scope Panel

Shows planets and moons that lie along your current heading direction. Useful for visual orientation during interplanetary travel.

- Hovering over a planet displays the distance to it.
- In mouse mode, use **+** and **-** to zoom the scope view in and out.

---

## Odometer

A horizontal indicator bar that lights up individual segments for each active flight feature:

- Alt Hold
- Autopilot
- Orbit
- Brake Landing
- Vertical Takeoff
- And other active modes

The odometer can be hidden by setting `DisplayOdometer = false`. When hidden, the heading readout remains visible.

---

## Vertical Speed Meter

Displays the ship's vertical velocity on a **logarithmic scale**, allowing it to represent both small hover adjustments and high-speed orbital maneuvers on the same gauge.

| Variable | Default | Description |
|----------|---------|-------------|
| `vSpdMeterX` | 1525 | Horizontal position |
| `vSpdMeterY` | 325 | Vertical position |

---

## Throttle Info Meter

Shows the current throttle percentage and speed limit information. When `AtmoSpeedAssist` is active, the display reads:

```
Throttle: X% | Cruise: Y kph
```

The label `(limited)` is appended when the speed assist system is actively restricting throttle output below the pilot's requested level.

| Variable | Default | Description |
|----------|---------|-------------|
| `throtPosX` | 1300 | Horizontal position |
| `throtPosY` | 540 | Vertical position |

---

## Altimeter

Displays height above the nearest planet's surface, computed from the planet atlas data (not radar).

- Turns off automatically above 200,000m altitude.
- **AGL (Above Ground Level)** -- When hover engines, vertical boosters, or a telemeter detect the ground surface, the altimeter switches to AGL mode showing true distance to ground rather than atlas-computed altitude.

| Variable | Default | Description |
|----------|---------|-------------|
| `altMeterX` | 550 | Horizontal position |
| `altMeterY` | 540 | Vertical position |

---

## Nav Ball

A 3D orientation indicator showing pitch, roll, and yaw relative to the horizon and velocity vector.

Two rendering styles are available, controlled by `circleRad`:

| circleRad Value | Style |
|-----------------|-------|
| 0 | Hidden (nav ball disabled) |
| 1 -- 199 | Small circular indicator |
| 200+ | F16 / traditional flight-style HUD |

| Variable | Default | Description |
|----------|---------|-------------|
| `circleRad` | 400 | Nav ball size in pixels |
| `centerX` | 960 | Horizontal position |
| `centerY` | 540 | Vertical position |

---

## Fuel Tank Display

Displays fuel levels for all installed fuel tanks. Two visual styles are available:

| Style | Setting | Description |
|-------|---------|-------------|
| Bar | `BarFuelDisplay = true` | Horizontal bar graph per tank |
| Traditional | `BarFuelDisplay = false` | Numeric readout per tank |

**Slotted vs. unslotted tanks:**

- Tanks that are linked to the seat's slots display exact fuel values read from the element API.
- Unslotted tanks use a calculated estimate based on mass. The accuracy of this estimate depends on the fuel handling skill variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `fuelTankHandlingAtmo` | 0 | Atmospheric fuel tank handling skill level |
| `fuelTankHandlingSpace` | 0 | Space fuel tank handling skill level |
| `fuelTankHandlingRocket` | 0 | Rocket fuel tank handling skill level |
| `ContainerOptimization` | 0 | Container optimization skill level |
| `FuelTankOptimization` | 0 | Fuel tank optimization skill level |

**Position:**

| Variable | Default | Description |
|----------|---------|-------------|
| `fuelX` | 30 | Horizontal position |
| `fuelY` | 700 | Vertical position |

Setting both `fuelX` and `fuelY` to 0 hides the fuel display entirely.

---

## IPH Widget (Interplanetary Helper)

Shows all waypoints -- both default planetary waypoints and user-created custom waypoints. Information displayed changes based on whether the ship is in atmosphere or space.

**Controls:**

| Action | Key |
|--------|-----|
| Cycle forward | ALT-1 |
| Cycle backward | ALT-2 |

**Filter modes** (cycled through with ALT-1 / ALT-2):

| Mode | Description |
|------|-------------|
| All | All default and custom waypoints |
| Custom Only | Only user-created waypoints |
| All without Moons/Asteroids | Default planets and custom waypoints, excluding moons and asteroids |

---

## Radar Info

Displays a traditional radar widget alongside a summary info line.

- When contacts are detected, the info line reads: `Plotted X/Y, Ignored Z` -- where X is the number of tracked/plotted contacts, Y is the total contacts, and Z is the number of ignored contacts.
- The radar info is automatically hidden when no contacts are detected.

| Variable | Default | Description |
|----------|---------|-------------|
| `radarX` | 1750 | Radar info horizontal position |
| `radarY` | 350 | Radar info vertical position |
| `friendlyX` | -- | Friendly contact list horizontal position |
| `friendlyY` | -- | Friendly contact list vertical position |

---

## PvP and Pipe Info

Two proximity indicators related to PvP zones:

**PvP Boundary Distance** -- Shows the distance to the nearest PvP zone boundary. The HUD color automatically changes from PvE colors to PvP colors when crossing the boundary (see HUD Color section below).

**Pipe Distance** -- Shows the distance to the nearest "pipe" (the direct-line tunnel between two planets). When the ship is within 500,000m of a pipe, the distance text renders in red as a warning.

- The `/pipecenter` command creates navigation waypoints along the nearest pipe for guided avoidance.

---

## Shield Info

Displays shield status when a shield generator is linked:

- Current shield strength (percentage and absolute)
- Resistance values per damage type
- On/off status indicator

| Variable | Default | Description |
|----------|---------|-------------|
| `shieldX` | 1750 | Horizontal position |
| `shieldY` | 250 | Vertical position |

---

## AGG Info

When an Anti-Gravity Generator is linked and active, the standard AGG widget is displayed with altitude and target information.

- Setting `ExternalAGG = true` disables ArchHUD's AGG control logic, for ships that use a separate AGG management system.

---

## Human-Readable Status Codes

All brake and autopilot status indicators display human-readable labels instead of internal code abbreviations. The full mapping includes over 30 status codes:

**Landing statuses:**

| Internal Code | Display Label |
|---------------|---------------|
| BL Stop Dist | Landing: Descent Controlled |
| BL Align Hzn | Landing: Reducing Speed |
| BL hSpd | Landing: Reducing Horizontal Speed |
| BL Complete | Landing Complete |

**Takeoff statuses:**

| Internal Code | Display Label |
|---------------|---------------|
| VTO Limit | VTO: Limiting Ascent |
| ATO Space | Takeoff: Exiting Atmosphere |

**Braking statuses:**

| Internal Code | Display Label |
|---------------|---------------|
| SpdLmt | Speed Limit Braking |
| Collision | COLLISION AVOIDANCE |
| AP Brk | Autopilot: Braking |
| ECU Braking | ECU: Emergency Braking |
| Manual | Manual Brake |

And many more. The status text appears in the odometer bar and flight mode summary panel.

---

## Landing Feedback

During a brake landing, an overlay displays real-time approach telemetry:

```
Stop: 450m | Ground: 380m | Safe
```

| Field | Description |
|-------|-------------|
| Stop | Computed distance required to decelerate to 0 at current descent rate |
| Ground | Current distance to the ground surface |
| Safety | `Safe` when stop distance < ground distance; warns otherwise |

This overlay is only visible while a brake landing is in progress.

---

## Flight Mode Summary

A compact status bar showing all currently active flight modes as short labels. Each label lights up when its corresponding mode is engaged:

| Label | Mode |
|-------|------|
| AP | Autopilot |
| ALT | Altitude Hold |
| VEC | Vector Lock |
| ORB | Orbital |
| LAND | Brake Landing |
| VTO | Vertical Takeoff |
| ATO | Auto Takeoff |
| RE | Re-entry |
| PRO | Prograde |
| RET | Retrograde |
| AROL | Auto-Roll Override |
| COL | Collision Avoidance |
| SPD | Speed Assist |

The bar provides at-a-glance awareness of which flight systems are currently active.

---

## Graduated Collision Display

Collision avoidance uses a 3-tier graduated system instead of a binary on/off approach. Each tier escalates both the visual warning and the system response:

| Tier | Time to Impact | Label | Behavior |
|------|---------------|-------|----------|
| 1 | > 10 seconds | CAUTION | Advisory warning displayed on HUD |
| 2 | 3 -- 10 seconds | WARNING | Audible alarm sounds |
| 3 | < 3 seconds | EMERGENCY | Automatic emergency braking engaged |

The collision display is controlled by the `CollisionSystem` variable (default `true`).

---

## HUD Color

The HUD automatically changes its color scheme when crossing PvP zone boundaries.

| Variable | Default | Usage |
|----------|---------|-------|
| `SafeR` | 130 | PvE red component |
| `SafeG` | 224 | PvE green component |
| `SafeB` | 255 | PvE blue component |
| `PvPR` | 255 | PvP red component |
| `PvPG` | 0 | PvP green component |
| `PvPB` | 0 | PvP blue component |

**Default colors:** PvE space renders in light blue (130/224/255), PvP space renders in red (255/0/0).

**Resolution scaling:**

| Variable | Default | Description |
|----------|---------|-------------|
| `ResolutionX` | 1920 | HUD resolution width |
| `ResolutionY` | 1080 | HUD resolution height |

These values can differ from the actual game resolution to achieve UI scaling. Setting them smaller than the game resolution makes HUD elements appear larger; setting them larger makes elements appear smaller.

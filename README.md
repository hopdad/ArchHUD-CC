# ArchHUD

A feature-rich flight HUD for Dual Universe with full autopilot, orbital mechanics, and ship management.

For help: [OSIN Discord](https://discord.gg/9RD3xQfYXG) | [Archaegeo Discord](https://discord.gg/CNRE45xRu7)

## Features

- **Full Autopilot** -- Planet-to-planet, surface-to-surface, orbital hops, multipoint routes
- **Brake Landing** -- Automated safe descent with landing feedback
- **Altitude Hold / Orbit** -- Atmospheric altitude hold, orbital establishment and maintenance
- **Glide and Parachute Re-Entry** -- Two re-entry modes with pilot-selectable preference
- **Collision Avoidance** -- Graduated 3-tier system (caution / warning / emergency)
- **Speed Management** -- Atmospheric speed limiter with throttle assist
- **HUD Display** -- NavBall, altimeter, fuel gauges, radar, shield, orbit map, damage monitoring
- **AGG Support** -- Full anti-gravity generator integration with saved waypoint heights
- **ECU Support** -- Full HUD on Emergency Control Unit with safety braking
- **Customizable** -- 80+ user variables for colors, positions, flight physics, and behavior

See the [full documentation](docs/Home.md) for details on every feature.

## Installation

1. Download `ArchHUD.zip` from the [Releases](https://github.com/hopdad/ArchHUD-CC/releases) page
2. Extract into your DU `autoconf/custom` folder, keeping subfolders:
   - Default: `C:\ProgramData\Dual Universe\Game\data\lua\autoconf\custom`
   - Steam: `C:\Program Files (x86)\Steam\steamapps\common\Dual Universe\data\lua\autoconf\custom`
3. In-game: right-click your seat/remote/ECU:
   - **Advanced > Update custom autoconflist**
   - **Advanced > Run custom autoconfigure > ArchHud**
4. Link a **databank** to the control unit for settings persistence

The zip contains `ArchHUD.conf`, `Arch-ECU.conf`, and the `archhud/` require folder.

## Board Add-ons

Optional programming board scripts that display telemetry from your ArchHUD databank on screens.

| Board | Description |
|-------|-------------|
| [Telemetry Dashboard](board/TelemetryBoard.lua) | Flight data, autopilot status, fuel levels |
| [Radar Display](board/RadarDisplay.lua) | Contact table with threat assessment |
| [Damage Report](board/DamageDisplay.lua) | Ship integrity and element-by-element breakdown |
| [Flight Recorder](board/FlightRecorder.lua) | 30-minute black box with scrolling charts |
| [Route Planner](board/RoutePlanner.lua) | Route visualization with ETAs and progress |

Setup: Link a programming board to your ArchHUD databank (`db` slot) and a screen (`screen` slot), paste the Lua, and activate.

## Quick Reference

| Key | Action |
|-----|--------|
| G | Brake land / takeoff |
| Alt-4 | Autopilot to selected waypoint |
| Alt-6 | Altitude hold (atmo) / orbit (space) |
| Alt-1/2 | Cycle waypoints |
| CTRL | Toggle brakes |
| Alt-3 | Toggle HUD display |

See [Keybinds](docs/Keybinds.md) for the full reference.

## Documentation

Full documentation is in the [docs/](docs/Home.md) folder:

- [Installation](docs/Installation.md) -- Setup and configuration
- [Flight Controls](docs/Flight-Controls.md) -- All flight features
- [Autopilot](docs/Autopilot.md) -- Waypoints, routes, scenarios
- [HUD Display](docs/HUD-Display.md) -- UI elements and status codes
- [Settings](docs/Settings.md) -- All 80+ user variables
- [Chat Commands](docs/Chat-Commands.md) -- Lua chat command reference
- [Keybinds](docs/Keybinds.md) -- Complete keybind table

## Credits

- Rezoix -- [DU-hud](https://github.com/Rezoix/DU-hud)
- JayleBreak -- [Orbital math and atlas](https://gitlab.com/JayleBreak/dualuniverse/-/tree/master/DUflightfiles/autoconf/custom)
- Dimencia -- Autopilot math and core features

# Board Add-ons

Programming board add-on scripts that display data from the ArchHUD telemetry system. These are standalone Lua files located in the `board/` folder of the repository.

## Requirements

- A programming board
- The same databank linked to your ArchHUD seat (the `dbHud` slot)
- A screen (ScreenUnit)
- Link both the databank and screen to the programming board

## Installation

1. Download the desired `.lua` file from the `board/` folder in the repository.
2. In-game: right-click the programming board, then select Advanced > Edit Lua.
3. Paste the script contents into the `onStart` handler of the unit.
4. Activate the programming board.

---

## Available Add-ons

### Telemetry Dashboard (`TelemetryBoard.lua`)

Comprehensive flight data display showing:

- **Speed** -- ground speed, vertical speed, orbital velocity
- **Position** -- altitude, AGL, planet/body
- **Navigation** -- heading, pitch, roll, autopilot status
- **Fuel levels** -- atmo, space, rocket percentages
- **Ship status** -- mass, brake info, engine status

Refreshes every 2 seconds from telemetry databank keys (prefixed with `T_`).

### Radar Tactical Display (`RadarDisplay.lua`)

Real-time radar contact visualization:

- Color-coded contacts by type (hostile = red, friendly = green, abandoned = yellow, unknown = neutral)
- Contact details: name, distance, speed, size category
- Sorted by distance
- Shows total contact counts by category

### Damage Display (`DamageDisplay.lua`)

Ship health monitoring:

- Per-element health status with percentage bars
- Damaged elements highlighted in red/yellow
- Total ship integrity percentage
- Element counts by category (engines, wings, etc.)

### Flight Recorder (`FlightRecorder.lua`)

Flight data logging:

- Records position, speed, altitude, heading at regular intervals
- Trip statistics (distance, time, avg speed, max speed)
- Fuel consumption tracking
- Visual flight log display

### Route Planner (`RoutePlanner.lua`)

Route visualization and management:

- Displays all waypoints in the current route
- Shows leg distances and estimated travel times
- Total route distance and time
- Visual waypoint list with current leg highlighted

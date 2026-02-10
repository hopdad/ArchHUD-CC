# Board Add-ons

Programming board add-on scripts that display data from the ArchHUD telemetry system on physical screens. Each add-on has a `.json` file (paste-ready for DU) and a `.lua` source file, both located in the `board/` folder.

Each add-on runs on its own programming board and screen, reading telemetry data from the same databank used by your ArchHUD seat.

---

## Requirements

- A **programming board** (one per add-on)
- The **same databank** linked to your ArchHUD seat (the `dbHud` slot)
- A **screen** (ScreenUnit) -- any size works; larger screens show more detail
- Link **both** the databank and screen to the programming board

> **Note:** You can run multiple add-ons simultaneously on separate programming boards, all sharing the same databank. The pilot must be seated for telemetry data to be published.

---

## Installation

Each add-on has a `.json` file in the `board/` folder that auto-configures all slots, event handlers, and code in one paste.

### Quick Install (Recommended)

1. Place a **programming board** on your construct.
2. Place a **screen** (ScreenUnit) near the programming board.
3. Use the link tool to link the **databank** (the same one your ArchHUD seat uses) to the programming board.
4. Use the link tool to link the **screen** to the programming board.
5. Open the `.json` file for the add-on you want (e.g., `TelemetryBoard.json`).
6. **Copy the entire contents** of the JSON file to your clipboard.
7. In-game, right-click the programming board and select **Paste Lua configuration from clipboard**.
8. Right-click the programming board and select **Activate** (or use a switch).

That's it. The JSON paste auto-configures slot names, event handlers, and all code. The screen should display the add-on interface. If you see "AWAITING DATA", make sure a pilot is seated in the ArchHUD seat so telemetry is being published.

| Add-on | JSON File |
|--------|-----------|
| Telemetry Dashboard | `TelemetryBoard.json` |
| Radar Tactical Display | `RadarDisplay.json` |
| Damage Display | `DamageDisplay.json` |
| Flight Recorder | `FlightRecorder.json` |
| Route Planner | `RoutePlanner.json` |
| Combined Display | `CombinedDisplay.json` |

> **Combined Display note:** The Combined Display JSON includes a `screen2` slot. If you only use one screen, just leave the second slot unlinked -- it will be ignored. If you want two screens, link a second screen before pasting.

### Manual Install (Alternative)

If you prefer to set up the board manually instead of using the JSON paste:

1. Place and link elements as above (databank + screen to the programming board).
2. Right-click the programming board, select **Advanced > Edit Lua**.
3. **Rename slots** in the left panel: rename the databank slot to **`db`** and the screen slot to **`screen`**.
4. Select **unit > onStart** and paste the entire contents of the `.lua` file.
5. Add a new filter: **unit > onTimer(timerId)** and paste: `onBoardTick(timerId)`
6. Add a new filter: **unit > onStop** and paste: `if screen then screen.setHTML("") end`
7. Click **Apply**, close the editor, and activate the board.

For the Combined Display, the stop handler is `onBoardStop()` and you also need two screen handlers -- see its section below for details.

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Screen stays blank | Missing onTimer handler | Add `onBoardTick(timerId)` to unit > onTimer |
| Screen stays blank | Slot names wrong | Rename slots to exactly `db` and `screen` |
| "No databank linked" in chat | Databank not linked or slot not renamed | Re-link databank and rename slot to `db` |
| "No screen linked" in chat | Screen not linked or slot not renamed | Re-link screen and rename slot to `screen` |
| "AWAITING DATA" on screen | No pilot seated / telemetry not publishing | Sit in the ArchHUD seat to start telemetry |
| Data shows "Xs AGO" | Pilot stood up | Data goes stale when no one is seated |

---

## Available Add-ons

### Telemetry Dashboard (`TelemetryBoard.lua`)

Comprehensive flight data display. Refreshes every 1 second.

**Panels:**

- **Flight Data** -- ground speed (km/h and m/s), altitude, vertical speed, atmosphere density, throttle percentage, and status indicators (in-atmo, gear, brake, near-planet).
- **Autopilot** -- engagement status, current phase, target name, distance to target, brake distance, and mode indicators (altitude hold, turn & burn, orbit, reentry).
- **Fuel** -- atmo, space, and rocket fuel levels with color-coded percentage bars. Turns orange below 25% and red below 10%.
- **Ship Status** -- shield percentage, total mass, odometer (total distance traveled), and flight time.

**Databank keys read:** `T_flight`, `T_ap`, `T_ship`, `T_fuel`

### Radar Tactical Display (`RadarDisplay.lua`)

Real-time radar contact visualization. Refreshes every 2 seconds.

**Features:**

- Color-coded contacts: hostile/unknown in PVP = red/amber, friendly = green, static = gray
- Contact table with name, distance, size category (XS/S/M/L), type (Dynamic/Static), and friendly status
- Distance color-coding in PVP zones: red within 2 km, orange within 10 km
- Radar status indicator (Operational, Broken, Jammed, Obstructed, No Radar)
- Total contact count and PVP threat count
- Sorted by distance (closest first), max 22 contacts displayed
- **Alerts:** Writes threat warnings to the HUD via the alert channel (see below)

**Databank keys read:** `T_radar`, `T_flight`, `T_ship`

### Damage Display (`DamageDisplay.lua`)

Ship health monitoring. Refreshes every 5 seconds with auto-paginating element list.

**Features:**

- Large ship integrity percentage with color gradient (green > yellow > red)
- Full-width integrity bar
- Summary: damaged count, disabled count, total element count
- Per-element detail table: name, type, HP bar, and HP values
- Destroyed elements highlighted in red with "DESTROYED" label
- Auto-paginates through damaged elements every 5 seconds
- **Alerts:** Writes hull integrity warnings to the HUD via the alert channel (see below)

**Databank keys read:** `T_damage`, `T_flight`

### Flight Recorder (`FlightRecorder.lua`)

Flight data logging with scrolling line charts. Records every 10 seconds, keeps 30 minutes of history.

**Features:**

- Three stacked line charts: Speed (km/h), Altitude, and Vertical Speed
- Auto-scaling Y-axis with grid lines and min/max readouts
- Shared X-axis with time labels (now, 30s, 1m, 5m, etc.)
- Recording status indicator (REC dot when actively recording)
- Data persistence: history is saved to the databank and survives board restarts
- Recording duration display
- **Alerts:** Writes anomaly warnings (rapid altitude loss, sudden deceleration) to the HUD

**Databank keys read:** `T_flight`
**Databank keys written:** `T_history` (flight recording buffer)

### Route Planner (`RoutePlanner.lua`)

Route visualization and management. Refreshes every 3 seconds.

**Features:**

- Route progress bar with waypoint markers and completion percentage
- Summary stats: total distance, remaining distance, ETA, current speed, waypoint count
- Waypoint list with visual connector lines between legs
- Current target highlighted with double-ring indicator
- Per-waypoint data: name, planet, leg distance, distance from ship, ETA
- Saved route display when no active route is loaded
- Autopilot status indicator

**Databank keys read:** `T_route`, `T_ap`, `T_flight`

### Combined Display (`CombinedDisplay.lua`)

All five displays in a single script. Click the screen to navigate between pages. Supports 1 or 2 screens, each independently navigable.

**Pages:**

1. **Telemetry** -- flight data, autopilot, fuel, ship status (same as TelemetryBoard)
2. **Radar** -- contact list with threat indicators (same as RadarDisplay)
3. **Damage** -- hull integrity and element health (same as DamageDisplay)
4. **Flight Recorder** -- speed/altitude/vspeed charts with history (same as FlightRecorder)
5. **Route Planner** -- route progress and waypoint list (same as RoutePlanner)

**Navigation:**

- Click the **right half** of the screen to go to the next page
- Click the **left half** to go to the previous page
- Each screen shows page indicator dots and arrows at the bottom
- With 2 screens, each screen navigates independently

**Installation:** Use `CombinedDisplay.json` with the Quick Install method above. If using two screens, link both screens to the programming board before pasting.

**Manual setup** (if not using JSON paste) requires extra event handlers for screen click navigation:

| Event | Code |
|-------|------|
| unit > onStart | *paste entire CombinedDisplay.lua* |
| unit > onTimer(timerId) | `onBoardTick(timerId)` |
| unit > onStop | `onBoardStop()` |
| screen > onMouseDown(x,y) | `onScreenNav(1,x)` |
| screen2 > onMouseDown(x,y) | `onScreenNav(2,x)` *(only if using 2 screens)* |

Rename slots to `db`, `screen`, and optionally `screen2`.

**Databank keys read:** `T_flight`, `T_ap`, `T_ship`, `T_fuel`, `T_radar`, `T_damage`, `T_route`
**Databank keys written:** `T_history` (flight recording buffer), `A_damage`, `A_radar`, `A_recorder` (alert channels)

> **Tip:** The Combined Display replaces all five standalone boards with a single programming board. You only need one board and one or two screens instead of five boards and five screens.

---

## Alert Channel

Board add-ons can send alerts back to the HUD. When a board detects an important condition, it writes an alert to the shared databank. The HUD reads these alerts every second and displays them as warning messages on the pilot's screen.

### How It Works

1. Each board writes to its own alert key (`A_damage`, `A_radar`, `A_recorder`) on the shared databank.
2. Each alert includes a message and timestamp.
3. The HUD checks for new alerts every second. If the timestamp is newer than the last seen, the message is displayed.

### Alert Triggers

| Board | Condition | Message |
|-------|-----------|---------|
| **Damage** | Integrity drops below 75% | "Hull integrity X% - taking damage" |
| **Damage** | Integrity drops below 50% | "WARNING: Hull integrity X%" |
| **Damage** | Integrity drops below 25% | "CRITICAL: Hull integrity X%" |
| **Damage** | Element destroyed | "ALERT: N element(s) destroyed!" |
| **Radar** | Hostile within 2 km (PVP) | "THREAT: N hostile(s) within 2 km!" |
| **Radar** | New dynamic contact | "Radar: New contact 'Name' at distance" |
| **Recorder** | Altitude loss >1000m in 30s | "ALERT: Rapid altitude loss!" |
| **Recorder** | Speed loss >50% in 30s | "ALERT: Sudden deceleration!" |

### Requirements

Alerts require the board to be running (programming board activated) and linked to the same databank as the HUD seat. The HUD will display alerts regardless of which boards are active -- boards that are not running simply won't write alerts.

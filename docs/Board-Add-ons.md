# Board Add-ons

The **Combined Display** is the recommended board add-on for ArchHUD. It runs all five display pages (Telemetry, Radar, Damage, Flight Recorder, Route Planner) on a single programming board using DU's native `setRenderScript` API. Click the screen to navigate between pages.

The `board/` folder also contains standalone single-page scripts (`TelemetryBoard.lua`, `RadarDisplay.lua`, etc.) which use the older `setHTML` API. These are **deprecated** and may be removed in a future release. Use the Combined Display instead.

---

## Requirements

- A **programming board**
- The **same databank** linked to your ArchHUD seat (the `dbHud` slot)
- A **screen** (ScreenUnit) -- any size works; larger screens show more detail
- Optionally a **second screen** for dual-screen mode
- Link the **databank** and **screen(s)** to the programming board

> **Note:** The pilot must be seated for telemetry data to be published.

---

## Installation

### Quick Install (Recommended)

1. Place a **programming board** on your construct.
2. Place a **screen** (ScreenUnit) near the programming board.
3. Use the link tool to link the **databank** (the same one your ArchHUD seat uses) to the programming board.
4. Use the link tool to link the **screen** to the programming board.
5. Open `board/CombinedDisplay.json`.
6. **Copy the entire contents** of the JSON file to your clipboard.
7. In-game, right-click the programming board and select **Paste Lua configuration from clipboard**.
8. Right-click the programming board and select **Activate** (or use a switch).

That's it. The JSON paste auto-configures slot names, event handlers, and all code. The screen should display the Telemetry page. If you see "AWAITING DATA", make sure a pilot is seated in the ArchHUD seat so telemetry is being published.

> **Dual screen:** The JSON includes a `screen2` slot. If you only use one screen, leave the second slot unlinked -- it will be ignored. If you want two screens, link a second screen before pasting. Each screen navigates independently.

### Manual Install (Alternative)

If you prefer to set up the board manually instead of using the JSON paste:

1. Place and link elements as above (databank + screen to the programming board).
2. Right-click the programming board, select **Advanced > Edit Lua**.
3. **Rename slots** in the left panel: rename the databank slot to **`db`** and the screen slot to **`screen`** (and optionally a second screen to **`screen2`**).
4. Select **unit > onStart** and paste the entire contents of `CombinedDisplay.lua`.
5. Add a new filter: **unit > onTimer(timerId)** with value `refresh` and paste: `onBoardTick(timerId)`
6. Add a new filter: **unit > onStop** and paste: `onBoardStop()`
7. Click **Apply**, close the editor, and activate the board.

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

## Combined Display (`CombinedDisplay.lua`)

All five display pages in a single script using DU's native `setRenderScript` API. Click the screen to navigate between pages. Supports 1 or 2 screens, each independently navigable.

**Pages:**

1. **Telemetry** -- ground speed, altitude, vertical speed, atmosphere, throttle, status indicators, autopilot status/phase/target, fuel levels, shield, mass, odometer
2. **Radar** -- radar status, contact count, threat count, color-coded contact table sorted by distance with size/type/friendly status
3. **Damage** -- ship integrity percentage with color gradient bar, damaged/disabled/total counts, per-element HP table with auto-pagination
4. **Flight Recorder** -- three stacked line charts (speed, altitude, vertical speed) with auto-scaling Y-axis, recording indicator, 30-minute history saved to databank
5. **Route Planner** -- route progress bar, total/remaining distance, ETA, waypoint list with leg distances and per-waypoint ETA

**Navigation:**

- Click the **right half** of the screen to go to the next page
- Click the **left half** to go to the previous page
- Each screen shows page indicator dots and arrows at the bottom
- With 2 screens, each screen navigates independently

**Alerts:** The display monitors for dangerous conditions and writes alerts to the shared databank for the HUD to display (see Alert Channel section below).

**Databank keys read:** `T_flight`, `T_ap`, `T_ship`, `T_fuel`, `T_radar`, `T_damage`, `T_route`
**Databank keys written:** `T_history` (flight recording buffer), `A_damage`, `A_radar`, `A_recorder` (alert channels)

---

## Deprecated Standalone Boards

The following standalone scripts are **deprecated** and use the older `setHTML` API which produces console warnings in current DU. They remain in the `board/` folder for reference but are no longer recommended. Use the Combined Display instead.

| Script | JSON | Description |
|--------|------|-------------|
| `TelemetryBoard.lua` | `TelemetryBoard.json` | Flight data, autopilot, fuel, ship status |
| `RadarDisplay.lua` | `RadarDisplay.json` | Radar contact table with threat indicators |
| `DamageDisplay.lua` | `DamageDisplay.json` | Hull integrity and element health |
| `FlightRecorder.lua` | `FlightRecorder.json` | Speed/altitude/vspeed charts with history |
| `RoutePlanner.lua` | `RoutePlanner.json` | Route progress and waypoint list |

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

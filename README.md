
<!--Intro information-->
# Arch-Orbital-HUD
## A general purpose HUD for Dual Universe, based on DU Orbital Hud 5.450 and earlier

### NOTE: Version 1.7XX+ is a modular version that uses require files and will not work on GeForce Now. Use version ArchHUDGFN.conf for GEForce Now.

###### For assistance, see the OSIN discord channel [Discord](https://discord.gg/9RD3xQfYXG) or my personal [Discord](https://discord.gg/CNRE45xRu7)
###### Donations are accepted but not expected. You may donate to Archaegeo in game via Wallet or to https://paypal.me/archaegeo for Paypal.

Please see the [User manual](https://docs.google.com/document/d/13-Kz1pqbbIHq8HTFLVG1r58D9zxsJe8_eTXezuryfPg/edit?usp=sharing) for installation and details on use

---

## Programming Board Add-ons

ArchHUD can publish telemetry data to your databank, which standalone programming boards read and display on screens. These are optional — install any or all of them.

### Requirements

- Your existing ArchHUD seat/ECU with a linked databank (`dbHud`)
- One **Programming Board** per add-on
- One **Screen** (M or L recommended) per add-on

### Available Boards

| Board | File | Description |
|-------|------|-------------|
| **Radar Tactical Display** | `ArchHUD-Radar.conf` | Contact table sorted by distance, PVP/safe zone indicator, threat count, friendly/unknown status, color-coded proximity warnings |
| **Damage Report** | `ArchHUD-Damage.conf` | Ship integrity percentage with color gradient bar, paginated element-by-element breakdown with HP bars, auto-cycling pages |
| **Telemetry Dashboard** | `ArchHUD-Telemetry.conf` | Flight data (speed, altitude, throttle), autopilot status, fuel levels with bars, ship info and odometer |
| **Flight Recorder** | `ArchHUD-Recorder.conf` | Black box that records 30 minutes of speed, altitude, and vertical speed as scrolling line charts. Persists across restarts |
| **Route Planner** | `ArchHUD-Route.conf` | Displays active autopilot route with waypoint list, leg distances, ETAs, progress bar, and saved route preview |

### Installation (per board)

1. Place a **Programming Board** and a **Screen** on your construct
2. Link the programming board to your **existing ArchHUD databank** (the same one your seat uses) as the `db` slot
3. Link the programming board to the **screen** as the `screen` slot
4. Right-click the programming board > **Advanced** > **Paste Lua configuration from clipboard**
5. Paste the contents of the `.conf` file for the board you want
6. Activate the programming board (right-click > Activate, or wire to a switch/button)

The boards will display "AWAITING DATA" until you sit in your ArchHUD seat, which starts publishing telemetry to the databank.

### How It Works

The telemetry system uses a publish/subscribe pattern through the shared databank:

- **ArchHUD seat** writes flight, autopilot, fuel, ship, radar, damage, and route data to `T_` prefixed keys in the databank at different intervals (1s / 2s / 3s / 10s)
- **Each programming board** reads those keys on its own timer, decodes the JSON, and renders an SVG dashboard to its linked screen
- Boards are fully independent — add or remove any combination without affecting ArchHUD or each other

---

### Credits

Rezoix and his HUD - https://github.com/Rezoix/DU-hud

JayleBreak and his orbital maths/atlas - https://gitlab.com/JayleBreak/dualuniverse/-/tree/master/DUflightfiles/autoconf/custom

Dimencia and all of his hard math work on the autopilot and other features.



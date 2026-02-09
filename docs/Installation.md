# Installation

## Initial Installation

1. Download `ArchHUD.zip` from the [GitHub Releases](../../releases) page.
2. Place the zip file in your `autoconf/custom` folder.
3. Extract it **keeping the subfolder structure intact**.

### Default install path

```
C:\ProgramData\Dual Universe\Game\data\lua\autoconf\custom
```

### Steam install path

```
C:\Program Files (x86)\Steam\steamapps\common\Dual Universe\data\lua\autoconf\custom
```

### Expected result after extraction

```
autoconf/custom/
  ArchHUD.conf          -- Main modular HUD (pilot seat / remote controller)
  Arch-ECU.conf         -- Emergency Control Unit variant
  archhud/              -- Subfolder containing all require files
    apclass.lua         -- Autopilot logic (60 Hz)
    atlasclass.lua      -- Planet atlas, orbital math, Kepler/Kinematic
    baseclass.lua       -- Startup, base calculations, variable loading
    controlclass.lua    -- User input and keybinds
    hudclass.lua        -- HUD rendering and SVG generation
    globals.lua         -- Global variable definitions
    radarclass.lua      -- Radar processing
    shieldclass.lua     -- Shield management
    telemetryclass.lua  -- Telemetry publish/subscribe
    ...                 -- Additional support files
```

| File | Purpose |
|------|---------|
| `ArchHUD.conf` | Main HUD configuration. Install this on pilot seats and remote controllers. |
| `Arch-ECU.conf` | Emergency Control Unit configuration. Install on an ECU for automated emergency flight when the pilot leaves the seat. |
| `archhud/` | Required Lua modules loaded at runtime. Must remain as a subfolder of `autoconf/custom`. |

---

## In-Game Setup

1. **Set control scheme** -- Right-click the control unit (seat or remote) > **Advanced** > **Change Control Scheme** > **Keyboard**.
2. **Update autoconf list** -- Right-click > **Advanced** > **Update custom autoconflist**.
3. **Link a databank** (recommended) -- Link a databank element to the control unit. This is needed for saving and loading user settings, telemetry publishing, and persistent flight data. The slot name is `dbHud`.
4. **Link other elements** -- Link any other elements you want the HUD to use (see the slot list below). Slots marked *auto* will be linked automatically by autoconfigure if present. Slots marked *manual* must be linked by hand.
5. **Run autoconfigure** -- Right-click > **Advanced** > **Run custom autoconfigure** > select **ArchHud**.

---

## Slot List

The following table lists every slot the HUD recognizes. **Auto** slots are linked automatically during autoconfigure if a matching element is found on the construct. **Manual** slots must be linked by hand before or after running autoconfigure.

| Slot Name | Element Class | Link Mode |
|-----------|--------------|-----------|
| `core` | CoreUnit | auto |
| `radar` | RadarPVPUnit | manual |
| `antigrav` | AntiGravityGeneratorUnit | auto |
| `warpdrive` | WarpDriveUnit | auto |
| `gyro` | GyroUnit | auto |
| `weapon` | WeaponUnit | manual |
| `dbHud` | databank | manual |
| `telemeter` | TelemeterUnit | manual |
| `vBooster` | VerticalBooster | auto |
| `hover` | Hovercraft | auto |
| `door` | DoorUnit | manual |
| `switch` | ManualSwitchUnit | manual |
| `forcefield` | ForceFieldUnit | manual |
| `atmofueltank` | AtmoFuelContainer | manual |
| `spacefueltank` | SpaceFuelContainer | manual |
| `rocketfueltank` | RocketFuelContainer | manual |
| `shield` | ShieldGeneratorUnit | auto |
| `screenHud` | ScreenUnit | manual |
| `transponder` | TransponderUnit | manual |

> **Tip:** You do not need every slot filled. Link only the elements your construct has. The HUD will adapt to whatever is available.

---

## Post Installation -- User Setting Load Order

ArchHUD loads user settings in three stages. Each stage can override the previous one:

1. **`.conf` defaults** -- The values defined in `ArchHUD.conf` under "Edit Lua Parameters" (right-click seat > **Advanced** > **Edit Lua Parameters**). These are the factory defaults.
2. **`userglobals.lua`** -- If the file `autoconf/custom/archhud/custom/userglobals.lua` exists, any variables set in it override the `.conf` defaults. A template is provided as `userglobals.example` in that folder. Rename it to `userglobals.lua` and edit as needed.
3. **Databank saved values** -- When you stand up from the seat, your current settings are saved to the linked databank. On the next session, those saved values override both the `.conf` defaults and `userglobals.lua`.

### `useTheseSettings`

The `useTheseSettings` variable (in Edit Lua Parameters) controls whether the databank is allowed to override your `.conf` and `userglobals.lua` values:

- `false` (default) -- Normal behavior. Databank saved values take priority.
- `true` -- Forces the HUD to use the values from `.conf` and `userglobals.lua`, ignoring any databank saved values. The new values are then saved to the databank when you stand up. Use this when you want to push a settings change and have it stick.

### `userControlScheme`

Controls how the ship responds to pilot input. Set via Edit Lua Parameters or by holding **Shift** and clicking the control scheme button in the lower-left of the HUD button panel.

| Value | Description |
|-------|-------------|
| `"keyboard"` | Standard keyboard flight (default) |
| `"mouse"` | Mouse direct -- mouse movement controls pitch and yaw |
| `"virtual joystick"` | Virtual joystick -- on-screen joystick with deadzone |

---

## Board Add-ons

ArchHUD includes optional programming board scripts that display telemetry data on physical screens. These are standalone Lua files located in the `board/` folder of the repository.

| Board | File | Description |
|-------|------|-------------|
| Telemetry Dashboard | `TelemetryBoard.lua` | Flight data, autopilot status, fuel levels, ship info |
| Radar Display | `RadarDisplay.lua` | Contact table, PVP zone indicator, threat and friendly status |
| Damage Display | `DamageDisplay.lua` | Ship integrity bar, paginated element breakdown with HP bars |
| Flight Recorder | `FlightRecorder.lua` | 30-minute black box with speed, altitude, and vertical speed charts |
| Route Planner | `RoutePlanner.lua` | Active route waypoints, leg distances, ETAs, and progress bar |

### Board installation

1. Place a **Programming Board** and a **Screen** (M or L recommended) on your construct.
2. Link the programming board to your **existing ArchHUD databank** (the same `dbHud` your seat uses).
3. Link the programming board to the **screen**.
4. Paste the board Lua file contents into the programming board (right-click > **Advanced** > **Paste Lua configuration from clipboard**).
5. Activate the programming board.

Boards display "AWAITING DATA" until you sit in your ArchHUD seat, which starts publishing telemetry to the shared databank.

Download board scripts individually as needed -- you do not need to install all of them.

---

## Sound Pack (Optional)

ArchHUD supports an optional sound pack for audio feedback during flight events.

### Sound pack installation

1. Download the sound pack zip file.
2. Extract it to your Dual Universe audio folder:
   ```
   Documents\NQ\DualUniverse\audio
   ```
3. **Rename the subfolder** to something unique (for security -- this prevents other scripts from triggering sounds on your client).
4. Set the `soundFolder` user variable (in Edit Lua Parameters) to the name of your renamed subfolder.
5. Use **Alt-7** in-game to toggle sounds on and off.

> **Security note:** Renaming the sound folder from the default is important. Any Lua script that knows the folder name can play sounds on your client. Use a name only you know.

# Chat Commands

Full reference for Lua Chat channel commands. Open Lua Chat in-game to use these.

---

## Navigation Commands

| Command | Description |
|---------|-------------|
| `/addlocation Name ::pos{...}` | Add a saved waypoint at the given position |
| `::pos{...}` | Add a temporary waypoint (named "0-Temp", not saved) |
| `/setname <newname>` | Rename current selected IPH waypoint |
| `/deletewp` | Delete current selected custom waypoint |
| `/iphWP` | Display current IPH target's `::pos` coordinates |

## Route Commands

| Command | Description |
|---------|-------------|
| `/resumeroute` | Restore route saved by collision avoidance |

## Settings Commands

| Command | Description |
|---------|-------------|
| `/G VariableName newValue` | Change a user variable |
| `/G dump` | Show all variables changeable with `/G` |

## Ship Commands

| Command | Description |
|---------|-------------|
| `/agg <targetheight>` | Manually set AGG target height |
| `/resist 0.15, 0.15, 0.15, 0.15` | Set shield resistances (must total 0.60) |
| `/trans` | Show current transponder tag |
| `/trans <idcode>` | Change transponder tag |
| `/reentry` | Toggle reentry mode between Glide and Parachute |

## Data Commands

| Command | Description |
|---------|-------------|
| `/copydatabank` | Copy dbHud databank to a blank databank |
| `/createPrivate` | Dump private locations to screen |
| `/createPrivate all` | Dump all locations (including databank) to screen as private |

---

## Pipe Navigation

### `/pipecenter`

Sets pipe navigation waypoints. Creates the following entries:

1. **1-ClosestPipeCenter** -- center of the closest pipe
2. **2-NamePipeCenter** -- center of the target planet pipe
3. **3-NamePipeParallel** -- destination parallel to the pipe at your current distance

### Pipe Navigation Guide

1. Fly into space with the target planet selected in IPH.
2. Type `/pipecenter`, then select **2-NamePipeCenter** in IPH.
3. Press `ALT-5-5` to lock 180 degrees from pipe center, then fly to the desired distance (8+ SU recommended).
4. Stop, type `/pipecenter` again, and select **3-NamePipeParallel**.
5. Press `ALT-4` to fly parallel to the pipe the entire way.
6. Optionally: paste a dropoff location first, then use `ALT-SHIFT-8` to build a route through the parallel point to the destination.

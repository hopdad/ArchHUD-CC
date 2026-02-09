# Autopilot

This page covers the interplanetary autopilot system, custom waypoints, route planning, and all autopilot flight scenarios. For altitude hold and orbital mechanics, see [Altitude and Orbit](Altitude-and-Orbit). For general flight controls, see [Flight Controls](Flight-Controls).

---

## Interplanetary Helper (IPH)

The Interplanetary Helper is the waypoint selector used by the autopilot. It maintains a list of all known destinations and provides distance, direction, and travel information for each one.

### Waypoint List

The IPH includes two categories of waypoints:

- **Default waypoints** -- All planets and moons in the Dual Universe solar system.
- **Custom waypoints** -- User-saved locations such as bases, market stations, or points of interest.

### Cycling Waypoints

- **ALT-1** cycles forward through the waypoint list.
- **ALT-2** cycles backward through the waypoint list.

### Filtering Waypoints

The IPH filter button cycles through three filter modes:

1. **All** -- Shows every waypoint (planets, moons, asteroids, and custom locations).
2. **Custom Only** -- Shows only user-saved custom waypoints.
3. **All without Moons/Asteroids** -- Shows planets and custom waypoints, hiding moons and asteroids.

### Information Display

The information shown for the selected waypoint changes based on your current environment:

- **In atmosphere** -- Displays distance, direction arrow, and basic travel estimates.
- **In space** -- Displays distance, direction, orbital parameters, fuel estimates, and alignment angle.

---

## Adding Custom Waypoints

There are three ways to add a custom waypoint:

### Save Current Position

With a non-custom IPH entry selected, click the **Save Position** button to save your current location as a custom waypoint associated with that planet or moon.

### Add via Chat Command

Use the `/addlocation` chat command with a name and position string:

```
/addlocation My Base ::pos{0,2,12.3456,45.6789,150.0000}
```

### Paste a Position String

Paste a `::pos{...}` string directly into Lua chat. This adds the location as **0-Temp**, a temporary waypoint that is not saved to the databank. This is useful for one-time trips such as flying to DSAT asteroid locations.

---

## Updating Waypoints

The following actions are available for the currently selected custom waypoint:

| Action | Effect |
|--------|--------|
| `/setname Name` | Rename the current waypoint |
| **Update Position** button | Update the waypoint to your current location |
| **Save AGG Alt** button | Save the current AGG altitude as the arrival height for this waypoint |
| **Save Heading** button | Save your current heading as the landing alignment for this waypoint |
| **Clear** button | Clear the waypoint position |
| **Clear Heading** button | Clear the saved heading |
| **Clear AGG Alt** button | Clear the saved AGG altitude |
| `/deletewp` | Delete the current custom waypoint entirely |
| `/iphWP` | Display the world coordinates of the current waypoint |

---

## Private Locations

Waypoints whose names begin with `*` are treated as private locations. Private locations are **not** saved to the databank when you stand up from the seat, keeping them hidden from other pilots who use the same construct.

### Setup

1. In your `custom` autoconf folder, rename the sample private locations file to `privatelocations.lua`.
2. Set the `privateFile` user variable to the filename (e.g., `privatelocations`).
3. Private locations defined in this file are loaded when you sit down.

### Generating the File

Use the `/createPrivate` chat command to generate private location data:

- `/createPrivate` -- Dumps only waypoints starting with `*`.
- `/createPrivate all` -- Dumps all custom waypoints.

The output is sent to a linked screen for copy-paste into your `privatelocations.lua` file.

---

## Quick Navigation

### `/nearest` -- Find Closest Waypoint

Type `/nearest` in Lua chat to automatically select the closest saved waypoint in the IPH and show its distance. Then press **ALT-4** to fly there.

### `/return` -- Return to Takeoff Position

Type `/return` to set the autopilot destination back to where you last took off from. Your takeoff position is saved automatically each time you retract landing gear.

### Paste-to-Fly

Paste a `::pos{...}` string into Lua chat. The HUD will show the destination name and distance, then prompt you to press **ALT-4** to engage autopilot.

---

## Autopilot Usage

> **WARNING:** Do NOT use autopilot to fly to a moon surface. The autopilot will place you in orbit around moons rather than landing on them.

Press **ALT-4** to engage autopilot to the currently selected IPH location. The autopilot behavior depends on where you are and where you are going.

---

## Autopilot Scenarios

### 1. Ground to Same-Planet Endpoint

- **ALT-4:** Takes off, prompts for throttle up and brake release, then flies at starting altitude plus `AutoTakeoffAltitude`.
- **ALT-4-4** (double-tap): Same as above but performs a low orbit hop to the destination.

### 2. In Atmosphere to Same-Planet Endpoint

- **ALT-4:** Engages altitude hold at current altitude and proceeds horizontally to the endpoint.
- **ALT-4-4** (double-tap): Performs a low orbit hop instead of atmospheric flight.

### 3. Space to Same-Planet Endpoint

- **ALT-4:** Proceeds to the endpoint with a safe re-entry sequence.

### 4. Space to Space Waypoint

- **ALT-4:** Flies to the waypoint and stops at `AutopilotSpaceDistance` from it (default 5000m).

### 5. Ground to Another Planet Endpoint

- **ALT-4:** Performs a full interplanetary sequence:
  1. Takes off into space.
  2. Clears line of sight from the departure planet.
  3. Aligns to the destination and accelerates.
  4. Decelerates on approach.
  5. Re-entry and brake landing at the destination.

### 6. Space to Another Planet Endpoint

- **ALT-4:** Starts only if line of sight to the destination is clear. Performs normal interplanetary autopilot with landing at arrival.

---

## Landing Behavior

When the autopilot reaches its destination, it performs a brake landing at the endpoint:

- If a **saved heading** exists for the waypoint, the ship aligns to that heading during descent.
- If the **AGG is active** and a saved AGG height exists, the ship stops at the saved AGG altitude instead of landing.
- **Override alignment:** Tap **A** or **D** during landing to cancel heading alignment.
- **Override drift prevention:** Tap **G** during landing to cancel horizontal drift correction.

### Speed Adjustment

During autopilot in space, use **ALT-Mousewheel** to adjust the travel speed up or down, capped at the maximum speed your ship can achieve.

---

## Autopilot Transparency

The autopilot displays warning messages before major phase transitions so the pilot knows what is happening:

- **"VTO complete -- transitioning to orbital insertion"** -- Vertical takeoff phase has ended; the ship is entering orbit.
- **"Atmosphere cleared -- engaging interplanetary autopilot"** -- The ship has exited atmosphere and is beginning interplanetary travel.
- **"Above atmosphere -- transitioning to orbital insertion"** -- Already in space; entering the orbital insertion phase.

---

## Alignment Progress

During alignment phases (when the ship is rotating to face a target direction), the HUD displays a real-time percentage indicator:

```
Aligning: 87%
```

This shows how close the ship is to completing its alignment before the next autopilot phase begins.

---

## ETA Display

While autopilot is active and the ship is moving, the HUD shows an estimated time of arrival and remaining distance below the autopilot status:

```
ETA: 5m 30s | 1.23 su
```

This updates in real time as your speed and distance change.

---

## Pre-Flight Warnings

When engaging autopilot, the system performs automatic checks and warns you about potential issues:

- **Overweight for atmo engines** -- Ship mass exceeds what atmosphere engines can safely lift.
- **Overweight for space engines** -- Ship mass exceeds what space engines can handle (interplanetary trips).
- **No space engines** -- Interplanetary trip selected but no space engines detected.
- **Low thrust-to-weight ratio** -- General warning when thrust margin is thin.
- **Collision system without radar** -- Collision avoidance is enabled but no radar is linked.
- **No space fuel tanks** -- Interplanetary trip detected but no space fuel tanks found on the construct.

## Weight Warnings

The HUD monitors ship mass against engine capacity in real time. As cargo is loaded or unloaded, the warnings update automatically.

### Persistent HUD Warning

When the ship is flying and mass exceeds safe limits for the current environment, the HUD displays a blinking warning:

- **In atmosphere**: `** OVERWEIGHT **` -- atmo engines cannot safely support the ship.
- **In space**: `** OVERWEIGHT FOR SPACE **` -- space engines cannot safely support the ship at current gravity.

### Takeoff Warning

When you retract landing gear (takeoff), the system checks if the ship is too heavy:

- **Too heavy for atmo engines** -- warns before takeoff so you can reduce cargo.
- **Exceeds safe hover mass** -- hovers may struggle to maintain altitude.

---

## Multipoint Route Support

The autopilot supports multi-leg routes through a series of IPH waypoints.

### Creating a Route

1. Select a waypoint in the IPH.
2. Press **ALT-SHIFT-8** to add it to the route.
3. Repeat for each waypoint in the desired order.

### Flying a Route

- Start with **ALT-4** (or any other autopilot engagement method).
- The autopilot flies each leg in sequence, automatically proceeding to the next waypoint after completing each one.
- Stopping mid-route and pressing **ALT-4** again continues the remaining legs.

### Route Management

- **Save Route** button -- Saves the current route to the databank for later use.
- **Load Route** button -- Loads a previously saved route from the databank.
- **Clear Route** button -- Clears the current route.

### Route Recovery

If collision avoidance interrupts an active route, use the `/resumeroute` chat command to restore the route and continue from where it was interrupted.

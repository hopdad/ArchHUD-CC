# Altitude and Orbit

This page covers altitude hold, enhanced hover mode, orbital establishment, and fast orbit. For autopilot-specific behavior, see [Autopilot](Autopilot). For general flight controls, see [Flight Controls](Flight-Controls).

---

## Altitude Hold

**ALT-6** in atmosphere engages altitude hold at your current height. The ship maintains the target altitude automatically while you control heading and speed.

### Disengaging Altitude Hold

Altitude hold can be turned off by any of the following:

- Press **ALT-6** again.
- Double-tap brakes (**CTRL** twice).
- Double-tap middle mouse button (**MMB** twice).

### Adjusting Target Altitude

While altitude hold is active:

- **ALT-Space** raises the target altitude.
- **ALT-C** lowers the target altitude.

### Step Altitude Changes

**ALT-SHIFT-Space** and **ALT-SHIFT-C** jump the target altitude to predefined levels:

1. **100m above surface** -- Low hover height.
2. **11% atmosphere** -- Mid-atmosphere cruising altitude.
3. **Low orbit** -- Just above the atmosphere edge.
4. **High orbit** -- Well above the atmosphere.

Each press of the step key advances to the next level in the sequence.

### Starting from Ground

When **ALT-6** is pressed while on the ground:

- If the **AGG is active**, the target altitude is set to the AGG height.
- Otherwise, the target altitude is set to ground level plus `AutoTakeoffAltitude` (default 1000m).

### Quick Mid-Atmosphere Hold

**ALT-6-6** (double-tap) sets the target altitude directly to 11% of the planet's atmosphere height, a common cruising altitude.

---

## Enhanced Hover Mode

If **ALT-6** is pressed when AGL (above ground level) is showing -- meaning ground is detected beneath the ship -- the system enters enhanced hover mode. In this mode, the ship maintains a constant height above the terrain rather than a fixed sea-level altitude, following the contour of the ground as it moves.

### Disengaging Hover Mode

Hover mode can be cancelled by:

- Pressing **ALT-6** again.
- Braking.
- Using a step altitude change (**ALT-SHIFT-Space** / **ALT-SHIFT-C**), which switches to standard altitude hold.

> **WARNING:** Enhanced hover mode is only recommended at slow speeds. Using low-altitude hover hold above 300 km/h will support the scrap industry.

---

## Establish Orbit

**ALT-6** in space near a planet establishes a circular orbit at your current distance from the planet center.

### Adjusting Orbital Height

Before the orbit is fully established, you can adjust the target orbital altitude:

- **ALT-Space** raises the target orbit.
- **ALT-C** lowers the target orbit.

Once the orbit is established and stable, these controls are no longer available.

### Quick Low Orbit

**ALT-6-6** (double-tap) in space establishes an orbit at `LowOrbitHeight` above the atmosphere edge, which is typically the lowest safe orbit altitude.

---

## Fast Orbit

> **USE AT OWN RISK** -- Fast orbit will probably destroy your ship if your adjustors cannot handle the increased velocity.

Fast orbit increases your orbital speed beyond the natural circular orbit velocity, resulting in a tighter, faster orbit.

### Requirements

- `MaintainOrbit` must be set to `true`.
- `FastOrbit` must be set to a value greater than `0.0`.

### How It Works

The actual orbit speed is calculated as:

```
Actual Speed = OrbitSpeed + (FastOrbit * OrbitSpeed)
```

For example, a `FastOrbit` value of `0.5` results in 1.5x the normal orbital speed.

### Safety

Slowly raise the `FastOrbit` value based on your ship's adjustor capability. Ships with insufficient lateral thrust will be unable to maintain the turn radius and will break apart or spiral out of orbit.

---

## Key Variables

The following user variables control altitude and orbital behavior. These can be set through the seat's **Edit Lua Parameters** menu or through `userglobals.lua`.

| Variable | Default | Description |
|----------|---------|-------------|
| `AutoTakeoffAltitude` | 1000 | Height in meters above ground for automatic takeoff when starting from the surface. |
| `TargetHoverHeight` | 50 | Height in meters above ground when using **G** to lift off from a landed state. |
| `LowOrbitHeight` | 2000 | Height in meters above the atmosphere edge used for orbital hops and orbit establishment. |
| `TargetOrbitRadius` | 1.2 | Multiplier applied to the atmospheric height to determine orbit tightness. Higher values produce wider orbits. |
| `MaintainOrbit` | true | When enabled, the ship uses small amounts of fuel to prevent orbit decay. Keeps the orbit stable indefinitely. |
| `FastOrbit` | 0.0 | Orbit speed multiplier for fast orbit mode. A value of 0.0 disables fast orbit. Use with extreme caution. |

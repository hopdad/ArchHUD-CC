# Re-Entry Modes

ArchHUD offers two re-entry modes for returning to a planet's surface from space. Both can be triggered from buttons in the HUD when your ship is in space over a planet.

---

## Glide Re-Entry

Activate by clicking LMB on the **Glide Re-Entry** button in the HUD.

- Slowly and safely descends into the atmosphere
- Leaves the ship in altitude hold at 11% atmosphere depth
- Provides the pilot with full control for the final descent

**Recommended engagement speed:** Less than 5,000 km/hr.

---

## Parachute Re-Entry

Activate by clicking LMB on the **Parachute Re-Entry** button in the HUD.

- Noses the ship downward and dives toward the planet
- Automatically slows to avoid friction burn damage
- Engages brakes at 25% atmosphere depth
- Recommended only for ships with excellent braking capability

**Recommended engagement speed:** Less than 5,000 km/hr.

---

## Pilot-Selectable Reentry Mode

Use the `/reentry` chat command to toggle between Glide and Parachute modes. This preference is remembered and applied to all automatic re-entries, including those triggered by autopilot and orbit arrival.

**Default mode:** Parachute.

The toggle confirmation message indicates the current selection:

- `Reentry mode: Glide (controlled descent)`
- `Reentry mode: Parachute (ballistic descent)`

During re-entry, the HUD displays the active mode:

- `Re-entry in Progress (Glide)`
- `Re-entry in Progress (Parachute)`

---

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ReEntryPitch | -30 | Maximum downward pitch angle (degrees) during the freefall portion of re-entry |
| ReEntryHeight | 100000 | Height above surface (meters) at which re-entry begins. A value of 100000 uses 11% atmosphere as the start point. |

# Flight Controls

This page covers all normal (non-autopilot) flight features in ArchHUD. For autopilot-specific behavior, see the Autopilot documentation. For a full keybind reference, see [Keybinds](Keybinds.md).

---

## Brake Landing

Press **G** to initiate a brake landing at your current location.

- Throttle is cut to 0% and the ship levels roll and pitch to 0.
- The ship drops at a safe rate, feathering brakes to control descent speed.
- Once at the maximum surface height threshold, the descent rate slows until the ground is detected by hover engines, vertical boosters, or a telemeter.
- Landing gear auto-deploys when ground is detected.
- The ship lowers to the known landing height, then hover power cuts off.

**Configuration:**

- `LandingGearGroundHeight` -- Set this to the AGL (above ground level) value when your ship is resting on the ground. This tells the system how tall your landing gear is.
- `allowedHorizontalDrift` -- Controls how much horizontal drift is permitted during autopilot brake landings. Default is 0.05 m/s.

**Abort:** Tap **CTRL** to toggle brakes off and cancel the brake landing.

**Takeoff from ground:** Press **G** while on the ground to take off to `TargetHoverHeight`.

**Landing Feedback HUD:** During brake landing, a feedback overlay displays stop distance, ground distance, and safety status so you can monitor the approach in real time.

---

## Speed Limits

### Atmosphere Speed Assist

`AtmoSpeedAssist` is a built-in cruise replacement when flying in throttle mode. It enforces speed limits automatically without requiring the pilot to manage throttle manually.

- `AtmoSpeedLimit` sets the maximum allowed speed in atmosphere.
- The throttle UI shows the current speed limit, throttle percentage, and current engine output percentage.
- **ALT-Mousewheel** adjusts the current speed limit up or down (capped at `AtmoSpeedLimit`).
- **ALT-MMB** toggles the limit between 0 and `AtmoSpeedLimit`.
- `ExtraEscapeThrust` allows exceeding the speed limit when escaping the atmosphere.

The speed assist visibility line on the HUD reads `Throttle: X% | Cruise: Y kph` and appends a `(limited)` indicator when the throttle is being actively restricted by the speed limiter.

### Space Speed Limit

`SpaceSpeedLimit` stops engines in space when you are not in autopilot, preventing uncontrolled acceleration.

---

## Brake Toggle Mode

Brake toggle is **on by default** (controlled by `BrakeToggleDefault`).

- When enabled, tap **CTRL** once to engage brakes and tap again to release.
- When disabled, vanilla brake behavior applies: hold **CTRL** to brake, release to stop braking.
- **ALT-CTRL** engages the handbrake, which locks brakes on even in vanilla (non-toggle) mode.

---

## Bank Turn

**ALT-Q** and **ALT-E** perform bank turns in atmosphere (left and right respectively).

- Altitude Hold auto-engages during the bank turn to maintain altitude.
- If Altitude Hold was not already active before the bank, it disengages automatically once the bank completes.

---

## 180 Degree Reversal

**ALT-S** in atmosphere initiates a 180-degree bank turn reversal.

- Altitude Hold engages at the start and remains on after the reversal completes.
- Press **ALT-S** again during the maneuver to stop the reversal early.

---

## Prograde Toggle

**ALT-W** in space (when not in autopilot) toggles prograde alignment. The ship will orient to face along its velocity vector.

---

## Retrograde / Turn and Burn

**ALT-S** in space (when not in autopilot) toggles retrograde alignment. The ship orients to face opposite its velocity vector for deceleration burns.

**ALT-S** during autopilot toggles turn-and-burn braking, where the ship flips retrograde and fires engines to decelerate.

---

## Lock Alignment

**ALT-5** locks alignment to the current IPH (interplanetary helper) target while not in autopilot. The ship holds its heading toward the selected destination.

**ALT-5-5** (double-tap) locks retrograde (180-degree) alignment instead.

Cancel locked alignment with any of:
- Activating any autopilot mode
- Tapping brake
- Pressing **ALT-5** again

---

## Lock Pitch

**ALT-SHIFT-5** locks the current pitch angle. The ship will hold its nose at the current elevation regardless of other inputs.

---

## AutoRoll

When `autoRollPreference` is enabled, the ship automatically rolls to level in atmosphere, keeping wings parallel to the ground.

**AutoRoll Override:** Manual roll input (**A** / **D**) pauses autoRoll for 3 seconds, allowing temporary manual roll control. After the pause, autoRoll resumes automatically.

AutoRoll is **not overridable** during BrakeLanding or Reentry for safety reasons.

---

## Decoupled Flight

**ALT-8** toggles decoupled mode, primarily useful for underwater flying.

In decoupled mode, the ship maintains its current altitude without the hover system pulling it to sea level. This allows stable underwater navigation.

---

## Gyroscope Toggle

**ALT-9** toggles the gyroscope on or off, affecting rotational stabilization.

---

## Extra Engine Tags

User variables `ExtraLongitudeTags`, `ExtraLateralTags`, and `ExtraVerticalTags` let you tag specific engines for selective activation.

**ALT-SHIFT-9** cycles through engine tag modes:

1. **Off** -- No extra engine tags active
2. **All** -- All tagged engines fire
3. **Longitude** -- Only longitudinally tagged engines fire
4. **Lateral** -- Only laterally tagged engines fire
5. **Vertical** -- Only vertically tagged engines fire

Only engines with the specified tags will activate in each mode.

---

## Vertical Takeoff

Available only if your ship has vertical engines.

- A UI button allows switching between Horizontal and Vertical takeoff mode.
- **ALT-6** performs a vertical takeoff to the normal target height, then transitions to horizontal flight.
- With AGG (antigravity generator) active: the ship stops at the VTO height and brakes instead of transitioning.

---

## Pre-Flight Validation

When engaging autopilot, the system performs automatic pre-flight checks:

- **Thrust-to-weight ratio** -- Warns if the ratio is too low for the planned maneuver.
- **Radar presence** -- Warns if the collision avoidance system is enabled but no radar is linked to the construct.

These checks help prevent engaging autopilot in unsafe configurations.

---

## Flight Mode Panel

A compact status bar is displayed on the HUD showing all currently active flight modes at a glance. The following mode indicators may appear:

| Code | Mode |
|------|------|
| AP | Autopilot |
| ALT | Altitude Hold |
| VEC | Vector Lock |
| ORB | Orbital |
| LAND | Brake Landing |
| VTO | Vertical Takeoff |
| ATO | Auto Takeoff |
| RE | Reentry |
| PRO | Prograde |
| RET | Retrograde |
| AROL | AutoRoll |
| COL | Collision Avoidance |
| SPD | Speed Assist |

Only active modes are shown, providing a quick overview of which systems are currently engaged.

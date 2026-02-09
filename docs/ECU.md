# Emergency Control Unit

The ECU activates when the pilot disconnects or exits the main control unit while the ECU is armed. There are three ways to use the ECU with ArchHUD.

---

## Arch-ECU.conf (Standalone)

The standalone ECU configuration (`Arch-ECU.conf`) provides a simple, reliable emergency controller.

### Behavior

- Stabilizes roll and pitch using PID controllers
- Deploys landing gear when ground is detected
- Activates antigravity generator if one is connected
- In deep space: cancels rotation and applies brakes to bring the ship to a full stop
- Automatically exits control when the ship has stopped and is on the ground

### BrakeLand Export

The `BrakeLand` export variable controls the landing behavior:

| Value | Behavior |
|-------|----------|
| true | Brake-land on activation (descend and stop) |
| false | Level flight with braking (maintain altitude while decelerating) |

---

## Full HUD on ECU

If the full `ArchHUD.conf` (not `Arch-ECU.conf`) is installed on an ECU, it provides the complete HUD display on the ECU seat.

Standard ECU actions still apply:

- AGG activation
- Brake landing in atmosphere
- Full stop in space

---

## ECUHud Mode

Set `ECUHud = true` to enable continuous flight when the ECU activates. Instead of performing emergency actions, the ship continues flying as if the pilot were still in the control unit.

### Controls in ECUHud Mode

Pitch, roll, and yaw controls are available. Use **ALT-SHIFT-L** to freeze or unfreeze the player character, which is required to use these controls from the ECU seat.

---

## Limitations

Some controls do not function on an ECU:

- Pitch, yaw, and roll controls require the player freeze (ALT-SHIFT-L) to work
- Cruise control switching is not available

The following features work normally on an ECU:

- Autopilot in atmosphere
- Altitude hold
- Brake landing
- Swapping from a seat to remote control preserves the current autopilot state

---

## ECU Slot Connections

The following slots must be connected on the ECU for full functionality:

| Slot Name | Element Type |
|-----------|-------------|
| core | CoreUnit |
| antigrav | AntiGravityGeneratorUnit |
| container | FuelContainer (connect all fuel containers) |
| gyro | GyroUnit |
| vBooster | VerticalBooster |
| hover | Hovercraft |

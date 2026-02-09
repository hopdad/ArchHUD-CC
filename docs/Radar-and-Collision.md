# Radar and Collision

## Dual Radar Support

ArchHUD supports connecting both an Atmospheric radar and a Space radar simultaneously. The HUD automatically swaps between them based on which radar is currently active for the environment you are in.

**Important:** The radar used for Dual Universe's Identify function must be connected to the radar-specific slot on the control unit, not a generic slot.

## Collision Warning

Collision warning requires `CollisionSystem = true` in your configuration.

When enabled, the system warns you when your ship is on a collision path with other constructs. Only the following core types are tracked:

- Static cores (any size)
- Space cores (any size)
- Dynamic cores size S and above (these can hover with AGG)

### Graduated 3-Tier Warning System

The collision warning uses a graduated three-tier system rather than a simple binary on/off detection:

| Tier | Label | Time to Impact | Behavior |
|------|-------|----------------|----------|
| 1 | **CAUTION** | More than 10 seconds | Advisory warning displayed on HUD. No automatic action taken. |
| 2 | **WARNING** | 3 to 10 seconds | Alarm sounds. Warning is prominently displayed on HUD. |
| 3 | **EMERGENCY** | Less than 3 seconds | Automatic emergency brake is engaged immediately. |

Each tier is color-coded on the HUD for quick visual identification.

## Collision Avoidance

Collision avoidance is active during any autopilot mode, including altitude hold and waypoint navigation.

When the emergency tier triggers automatic braking, the system saves your current route before engaging the brake. After the collision avoidance maneuver completes, you can restore the saved route using the `/resumeroute` chat command.

The current collision tier is displayed on the HUD with color-coded labels throughout the encounter.

## Abandoned Contacts

Abandoned contact reporting requires both `CollisionSystem = true` and `AbandonedRadar = true`.

When enabled, the system reports abandoned radar contacts with their approximate position in the Lua chat channel. Note that position accuracy for abandoned contacts is lower than the accuracy used for collision detection.

## Friendly Contacts

Ships that share your transponder code appear in a dedicated friendlies list on the HUD. You can manage your transponder code using the `/trans` chat command.

## Radar Widget

**Note:** The radar widget causes significant lag on any HUD when the widget panel is open. Close it when not actively needed.

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| CollisionSystem | true | Enable collision detection and avoidance |
| AbandonedRadar | false | Check for and report abandoned contacts |

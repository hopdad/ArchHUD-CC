# Changelog

## Version History

### Version 2.105 -- MyDU Update and Bug Fixes

- Implement calculations for the anti-gravity fuel tank
- Resolve issues with Lua property saving and duplication

### Version 2.104 -- MyDU Enhancement Update

- Improve fuel tank detection, allowing creation of new fuel tank
- Change default user control scheme to "keyboard"
- Add the possibility to load a custom atlas

### Version 2.103 -- Minor Bug Fixes

- Fixed 100k/hr up speed limit in atmo, now limited to adjusted atmo speed limit

### Version 2.102 -- Six Axis Joystick Support

- Added analog stick support for Strafe (Left/Right) and Up/Down
  - Lua Axis 4: Strafe Left/Right
  - Lua Axis 5: Vertical Up/Down

### Version 2.101 -- Analog HOTAS/Single Stick Support

- Added joystick support for pitch, roll, yaw, and throttle
- Fixed IPH index reset on exit
- Fixed ship moving in freelook

### Version 2.1 -- Dual Universe 1.4 Update

- Updated for DU 1.4 (thanks to NQ-Ligo)
- Added support for Sicari and Sinnen

### Version 2.027

- Fixed LOS blockage re-check after clearing
- Fixed align-to-target (ALT-5) for space locations

### Version 2.026 -- AP Throttle Control

- Refactored throttle/cruise speed control
- Fixed intermittent negative cruise speed on re-entry
- Fixed AP not fully resetting after warp

### Version 2.025

- AP Route re-align at 2000 km/hr (was 5000)
- Fixed LOS false conflicts
- Fixed AGG altitude adjustment above 200k in space
- Fixed AP not clearing completely on cancel
- Fixed Aegis closest planet detection

### Version 2.024

- Fixed closest pipe and `/pipecenter`
- IPH swaps to position 1 on temp location paste
- Prevent waypoint paste during autopilot
- Fixed cruise mode AP start (250000% throttle error)

### Version 2.023

- Fixed yo-yo yawing on AP planet arrival
- Fixed IntoOrbit dive recovery reliability
- Reverted ReEntryPitch default to -30

### Version 2.022 -- AP Enhancements

- HUD proactively clears LOS blockage by adjusting arrival waypoint
- MaxGameVelocity -1 = auto-detect max speed
- Double MMB clears more features
- After planet arrival, uses low orbit to reach ground target faster
- Required Thrust re-added to INFO panel
- Safe mass numbers update continuously based on gravity
- Default ReEntryPitch changed to -60
- Fixed re-entry vector timing

---

For the complete changelog of older versions, see the `ChangeLog.md` file in the repository.

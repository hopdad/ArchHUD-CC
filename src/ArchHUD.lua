require 'src.slots'

Nav = Navigator.new(system, core, unit)

-- Accessor factory for databank save/load system
local function _A(n)return{set=function(i)_G[n]=i end,get=function()return _G[n]end}end

-- User variables. Must be global to work with databank system
    useTheseSettings = false --export:  Change this to true to override databank saved settings
    userControlScheme = "keyboard" --export: (Default: "keyboard") Set to "virtual joystick", "mouse", or "keyboard". This can be set by holding SHIFT and clicking the button in lower left of main Control buttons view.
    soundFolder = "archHUD" --export: (Default: "archHUD") Set to the name of the folder with sound files in it. Must be changed from archHUD to prevent other scripts making your PC play sounds.
    privateFile = "name" --export: (Default "name") Set to the name of the file for private locations to prevent others from getting your private locations. Filename should end in .lua
    customAtlas = "atlas" --export: (Default "atlas") Custom atlas file to override NQ atlas (file need to be located in autoconf/custom/)
    -- True/False variables
    -- NOTE: saveableVariablesBoolean below must contain any True/False variables that needs to be saved/loaded from databank.
        freeLookToggle = true --export: (Default: true) Set to false for vanilla DU free look behavior.
        BrakeToggleDefault = true --export: (Default: true) Whether your brake toggle is on/off by default. Can be adjusted in the button menu. False is vanilla DU brakes.
        RemoteFreeze = false --export: (Default: false) Whether or not to freeze your character in place when using a remote controller.
        RemoteHud = false --  (Default: false) Whether you want to see the full normal HUD while in remote mode.
        brightHud = false --export: (Default: false) Enable to prevent hud hiding when in freelook.
        VanillaRockets = false --export: (Default: false) If on, rockets behave like vanilla
        InvertMouse = false --export: (Default: false) If true, then when controlling flight mouse Y axis is inverted (pushing up noses plane down) Does not affect selecting buttons or camera.
        autoRollPreference = false --export: (Default: false) [Only in atmosphere] - When the pilot stops rolling, flight model will try to get back to horizontal (no roll)
        ExternalAGG = false --export: (Default: false) Toggle On if using an external AGG system. If on will prevent this HUD from doing anything with AGG.
        ShouldCheckDamage = false --export: (Default: true) Whether or not damage checks are performed. Disable for performance improvement on very large ships or if using external Damage Report and you do not want the built in info.
        AtmoSpeedAssist = true --export: (Default: true) Whether or not atmospheric speeds should be limited to a maximum of AtmoSpeedLimit (Hud built in speed limiter)
        ForceAlignment = false --export: (Default: false) Whether velocity vector alignment should be forced when in Altitude Hold (needed for ships that drift alignment in altitude hold mode due to poor inertial matrix)
        DisplayDeadZone = true --export: (Default: true) Virtual Joystick Mode: Set this to false to not display deadzone circle while in virtual joystick mode.
        showHud = true --export: (Default: true) False to hide the HUD screen and only use HUD Autopilot features (AP via ALT+# keys)
        hideHudOnToggleWidgets = true --export: (Default: true) Uncheck to keep showing HUD when you toggle on the vanilla widgets via ALT+3. Note, hiding the HUD with Alt+3 gives a lot of FPS back in laggy areas, so leave true normally.
        ShiftShowsRemoteButtons = true --export: (Default: true) Whether or not pressing Shift in remote controller mode shows you the buttons (otherwise no access to them)
        SetWaypointOnExit = false --export: (Default: true) Set to false to not set a waypoint when you exit hud. True helps find your ship in crowded locations when you get out of seat.
        AlwaysVSpd = false --export: (Default: false) Set to true to make vertical speed meter stay on screen when you alt-3 widget mode.
        BarFuelDisplay = true --export: (Default: true) Set to false to use old non-bar fuel display
        voices = true --export: (Default: true) Set to false to disable voice sounds when using sound pack
        alerts = true --export: (Default: true) Set to false to disable alert sounds when using sound pack
        CollisionSystem = true --export: (Default: true) If True, system will provide collision alerts and abort vector to target if conditions met.
        AbandonedRadar = false --export: (Default: false) If true, and CollisionSystem is true, all radar contacts will be checked for abandoned status.
        AutoShieldToggle = true --export: (Default: true) If true, system will toggle Shield off in safe space and on in PvP space automagically.
        PreventPvP = true --export: (Default: true) If true, system will stop you before crossing from safe to pvp space while in autopilot.
        DisplayOdometer = true --export: (Default: true) If false the top odometer bar of information will be hidden.
        ECUHud = false --export: (Default: false) If set to true and HUD is installed on an Emergency Control Unit, when ECU activates due to leaving control unit, it will continue normal hud flight.
        MaintainOrbit = true --export: (Default: true) If true, ship will attempt to maintain orbit if it decays (when not autopiloting to a landing point) till fuel runs out.
        saveableVariablesBoolean = {userControlScheme=_A("userControlScheme"), soundFolder=_A("soundFolder"), privateFile=_A("privateFile"),
        freeLookToggle=_A("freeLookToggle"), BrakeToggleDefault=_A("BrakeToggleDefault"), RemoteFreeze=_A("RemoteFreeze"),
        brightHud=_A("brightHud"), RemoteHud=_A("RemoteHud"), VanillaRockets=_A("VanillaRockets"),
        InvertMouse=_A("InvertMouse"), autoRollPreference=_A("autoRollPreference"), ExternalAGG=_A("ExternalAGG"),
        ShouldCheckDamage=_A("ShouldCheckDamage"), AtmoSpeedAssist=_A("AtmoSpeedAssist"), ForceAlignment=_A("ForceAlignment"),
        DisplayDeadZone=_A("DisplayDeadZone"), showHud=_A("showHud"), hideHudOnToggleWidgets=_A("hideHudOnToggleWidgets"),
        ShiftShowsRemoteButtons=_A("ShiftShowsRemoteButtons"), SetWaypointOnExit=_A("SetWaypointOnExit"),
        AlwaysVSpd=_A("AlwaysVSpd"), BarFuelDisplay=_A("BarFuelDisplay"),
        voices=_A("voices"), alerts=_A("alerts"), CollisionSystem=_A("CollisionSystem"),
        AbandonedRadar=_A("AbandonedRadar"), AutoShieldToggle=_A("AutoShieldToggle"), PreventPvP=_A("PreventPvP"),
        DisplayOdometer=_A("DisplayOdometer"), ECUHud=_A("ECUHud"), MaintainOrbit=_A("MaintainOrbit")}

    -- Ship Handling variables
    -- NOTE: saveableVariablesHandling below must contain any Ship Handling variables that needs to be saved/loaded from databank system
        YawStallAngle = 35 --export: (Default: 35) Angle at which the ship stalls when yawing, determine by experimentation. Higher allows faster AP Bank turns.
        PitchStallAngle = 35 --export: (Default: 35) Angle at which the ship stalls when pitching, determine by experimentation.
        brakeLandingRate = 30 --export: (Default: 30) Max loss of altitude speed in m/s when doing a brake landing. 30 is safe for almost all ships.
        MaxPitch = 30 --export: (Default: 30) Maximum allowed pitch during takeoff and altitude changes while in altitude hold. You can set higher or lower depending on your ships capabilities.
        ReEntryPitch = -30 --export: (Default: -30) Maximum downward pitch allowed during freefall portion of re-entry.
        AutopilotSpaceDistance = 5000 --export: (Default: 5000) Target distance AP will try to stop from a custom waypoint in space.  Good ships can lower this value a lot.
        TargetOrbitRadius = 1.3 --export: (Default: 1.3) How tight you want to orbit the planet at end of autopilot.  The smaller the value the tighter the orbit.  Value is multiple of Atmospheric Height
        LowOrbitHeight = 2000 --export: (Default: 2000) Height of Orbit above top of atmosphere when using Alt-4-4 same planet autopilot or alt-6-6 in space.
        AtmoSpeedLimit = 1175 --export: (Default: 1175) Speed limit in Atmosphere in km/h. AtmoSpeedAssist will cause ship to throttle back when this speed is reached.
        SpaceSpeedLimit = 66000 --export: (Default: 66000) Space speed limit in KM/H. If you hit this speed and are NOT in active autopilot, engines will turn off to prevent using all fuel (66000 means they wont turn off)
        AutoTakeoffAltitude = 1000 --export: (Default: 1000) How high above your ground height AutoTakeoff tries to put you
        TargetHoverHeight = 50 --export: (Default: 50) Hover height above ground when G used to lift off, 50 is above all max hover heights.
        LandingGearGroundHeight = 0 --export: (Default: 0) Set to AGL when on ground. Will help prevent ship landing on ground then bouncing back up to landing gear height.
        ReEntryHeight = 100000 --export: (Default: 100000) Height above a planets maximum surface altitude used for re-entry, if height exceeds min space engine height, then 11% atmo is used instead. (100000 means 11% is used)
        MaxGameVelocity = -1.00 --export: (Default: -1.00) Max speed for your autopilot in m/s.  If -1 then when you sit down it will set to actualy max speed.
        AutopilotInterplanetaryThrottle = 1 --export: (Default: 1) How much throttle, 0.0 to 1, you want it to use when in autopilot to another planet while reaching MaxGameVelocity
        warmup = 32 --export: (Default: 32) How long it takes your space engines to warmup. Basic Space Engines, from XS to XL: 0.25,1,4,16,32. Only affects turn and burn brake calculations.
        fuelTankHandlingAtmo = 0 --export: (Default: 0) For accurate estimates on unslotted tanks, set this to the fuel tank handling level of the person who placed the tank. Ignored for slotted tanks.
        fuelTankHandlingSpace = 0 --export: (Default: 0) For accurate estimates on unslotted tanks, set this to the fuel tank handling level of the person who placed the tank. Ignored for slotted tanks.
        fuelTankHandlingRocket = 0 --export: (Default: 0) For accurate estimates on unslotted tanks, set this to the fuel tank handling level of the person who placed the tank. Ignored for slotted tanks.
        ContainerOptimization = 0 --export: (Default: 0) For accurate estimates on unslotted tanks, set this to the Container Optimization level of the person who placed the tanks. Ignored for slotted tanks.
        FuelTankOptimization = 0 --export: (Default: 0) For accurate estimates on unslotted tanks, set this to the fuel tank optimization skill level of the person who placed the tank. Ignored for slotted tanks.
        AutoShieldPercent = 0 --export: (Default: 0) Automatically adjusts shield resists once per minute if shield percent is less than this value.
        EmergencyWarp = 0 --export: (Default: 0) If > 0 and a radar contact is detected in pvp space and the contact is closer than EmergencyWarp value, and all other warp conditions met, will initiate warp.
        DockingMode = 1 --export: (Default: 1) Docking mode of ship, default is 1 (Manual), options are Manual = 1, Automatic = 2, Semi-automatic = 3
        saveableVariablesHandling = {YawStallAngle=_A("YawStallAngle"), PitchStallAngle=_A("PitchStallAngle"),
        brakeLandingRate=_A("brakeLandingRate"), MaxPitch=_A("MaxPitch"), ReEntryPitch=_A("ReEntryPitch"),
        AutopilotSpaceDistance=_A("AutopilotSpaceDistance"), TargetOrbitRadius=_A("TargetOrbitRadius"),
        LowOrbitHeight=_A("LowOrbitHeight"), AtmoSpeedLimit=_A("AtmoSpeedLimit"), SpaceSpeedLimit=_A("SpaceSpeedLimit"),
        AutoTakeoffAltitude=_A("AutoTakeoffAltitude"), TargetHoverHeight=_A("TargetHoverHeight"),
        LandingGearGroundHeight=_A("LandingGearGroundHeight"), ReEntryHeight=_A("ReEntryHeight"),
        MaxGameVelocity=_A("MaxGameVelocity"), AutopilotInterplanetaryThrottle=_A("AutopilotInterplanetaryThrottle"),
        warmup=_A("warmup"), fuelTankHandlingAtmo=_A("fuelTankHandlingAtmo"),
        fuelTankHandlingSpace=_A("fuelTankHandlingSpace"), fuelTankHandlingRocket=_A("fuelTankHandlingRocket"),
        ContainerOptimization=_A("ContainerOptimization"), FuelTankOptimization=_A("FuelTankOptimization"),
        AutoShieldPercent=_A("AutoShieldPercent"), EmergencyWarp=_A("EmergencyWarp"), DockingMode=_A("DockingMode")}

    -- HUD Positioning variables
    -- NOTE: saveableVariablesHud below must contain any HUD Positioning variables that needs to be saved/loaded from databank system
        ResolutionX = 1920 --export: (Default: 1920) Does not need to be set to same as game resolution. You can set 1920 on a 2560 to get larger resolution
        ResolutionY = 1080 --export: (Default: 1080) Does not need to be set to same as game resolution. You can set 1080 on a 1440 to get larger resolution
        circleRad = 400 --export: (Default: 400) The size of the artifical horizon circle, recommended minimum 100, maximum 400. Looks different > 200. Set to 0 to remove.
        SafeR = 130 --export: (Default: 130) Primary HUD color
        SafeG = 224 --export: (Default: 224) Primary HUD color
        SafeB = 255 --export: (Default: 255) Primary HUD color
        PvPR = 255 --export: (Default: 255) PvP HUD color
        PvPG = 0 --export: (Default: 0) PvP HUD color
        PvPB = 0 --export: (Default: 0) PvP HUD color
        centerX = 960 --export: (Default: 960) X position of Artifical Horizon (KSP Navball), Default 960. Use centerX=700 and centerY=880 for lower left placement.
        centerY = 540 --export: (Default: 540) Y position of Artifical Horizon (KSP Navball), Default 540. Use centerX=700 and centerY=880 for lower left placement.
        throtPosX = 1300 --export: (Default: 1300) X position of Throttle Indicator, default 1300 to put it to right of default AH centerX parameter.
        throtPosY = 540 --export: (Default: 540) Y position of Throttle indicator, default is 540 to place it centered on default AH centerY parameter
        vSpdMeterX = 1525  --export: (Default: 1525) X position of Vertical Speed Meter. Default 1525
        vSpdMeterY = 325 --export: (Default: 325) Y position of Vertical Speed Meter. Default 325
        altMeterX = 550  --export: (Default: 550) X position of Altimeter. Default 550
        altMeterY = 540 --export: (Default: 540) Y position of Altimeter. Default 500
        fuelX = 30 --export: (Default: 30) X position of fuel tanks, set to 100 for non-bar style fuel display, set both fuelX and fuelY to 0 to hide fuel display
        fuelY = 700 --export: (Default: 700) Y position of fuel tanks, set to 300 for non-bar style fuel display, set both fuelX and fuelY to 0 to hide fuel display
        shieldX = 1750 --export: (Default: 1750) X position of shield indicator
        shieldY = 250 --export: (Default: 250) Y position of shield indicator
        radarX = 1750 --export: (Default 1750) X position of radar info
        radarY = 350 --export: (Default: 350) Y position of radar info
        DeadZone = 50 --export: (Default: 50) Number of pixels of deadzone at the center of the screen
        OrbitMapSize = 250 --export: (Default: 250) Size of the orbit map, make sure it is divisible by 4
        OrbitMapX = 0 --export: (Default: 0) X position of Orbit Display
        OrbitMapY = 30 --export: (Default: 30) Y position of Orbit Display

        saveableVariablesHud = {ResolutionX=_A("ResolutionX"), ResolutionY=_A("ResolutionY"),
        circleRad=_A("circleRad"), SafeR=_A("SafeR"), SafeG=_A("SafeG"), SafeB=_A("SafeB"),
        PvPR=_A("PvPR"), PvPG=_A("PvPG"), PvPB=_A("PvPB"),
        centerX=_A("centerX"), centerY=_A("centerY"), throtPosX=_A("throtPosX"), throtPosY=_A("throtPosY"),
        vSpdMeterX=_A("vSpdMeterX"), vSpdMeterY=_A("vSpdMeterY"),
        altMeterX=_A("altMeterX"), altMeterY=_A("altMeterY"),
        fuelX=_A("fuelX"), fuelY=_A("fuelY"), shieldX=_A("shieldX"), shieldY=_A("shieldY"),
        radarX=_A("radarX"), radarY=_A("radarY"), DeadZone=_A("DeadZone"),
        OrbitMapSize=_A("OrbitMapSize"), OrbitMapX=_A("OrbitMapX"), OrbitMapY=_A("OrbitMapY")}

    -- Ship flight physics variables - Change with care, can have large effects on ships performance.
        -- NOTE: saveableVariablesPhysics below must contain any Ship flight physics variables that needs to be saved/loaded from databank system
            speedChangeLarge = 5.0 --export: (Default: 5) The speed change that occurs when you tap speed up/down or mousewheel, default is 5%
            speedChangeSmall = 1.0 --export: (Default: 1) the speed change that occurs while you hold speed up/down, default is 1%
            MouseXSensitivity = 0.003 --export: (Default: 0.003) For virtual joystick only
            MouseYSensitivity = 0.003 --export: (Default: 0.003) For virtual joystick only
            autoRollFactor = 2 --export: (Default: 2) [Only in atmosphere] When autoRoll is engaged, this factor will increase to strength of the roll back to 0
            rollSpeedFactor = 1.5 --export: (Default: 1.5) This factor will increase/decrease the player input along the roll axis (higher value may be unstable)
            autoRollRollThreshold = 180 --export: (Default: 180) The amount of roll below which autoRoll to 0 will occur (if autoRollPreference is true)
            minRollVelocity = 150 --export: (Default: 150) Min velocity, in m/s, over which autorolling can occur
            TrajectoryAlignmentStrength = 0.002 --export: (Default: 0.002) How strongly AP tries to align your velocity vector to the target when not in orbit, recommend 0.002
            torqueFactor = 2 --export: (Default: 2) Force factor applied to reach rotationSpeed (higher value may be unstable)
            pitchSpeedFactor = 0.8 --export: (Default: 0.8) For keyboard control, affects rate of pitch change
            yawSpeedFactor = 1 --export: (Default: 1) For keyboard control, affects rate of yaw change
            brakeSpeedFactor = 3 --export: (Default: 3) When braking, this factor will increase the brake force by brakeSpeedFactor * velocity
            brakeFlatFactor = 1 --export: (Default: 1) When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction> (higher value may be unstable)
            DampingMultiplier = 40 --export: (Default: 40) How strongly autopilot dampens when nearing the correct orientation
            hudTickRate = 0.0666667 --export: (Default: 0.0666667) Set the tick rate for your HUD.
            ExtraEscapeThrust = 1.0 --export: (Default: 1.0) Set this to 1 to use friction burn speed as your max speed when escaping atmosphere. Setting other than 1 will be a the value multiplied by your friction burn speed.
            ExtraLongitudeTags = "none" --export: (Default: "none") Enter any extra longitudinal tags you use inside '' separated by space, i.e. "forward faster major" These will be added to the engines that are control by longitude.
            ExtraLateralTags = "none" --export: (Default: "none") Enter any extra lateral tags you use inside '' separated by space, i.e. "left right" These will be added to the engines that are control by lateral.
            ExtraVerticalTags = "none" --export: (Default: "none") Enter any extra longitudinal tags you use inside '' separated by space, i.e. "up down" These will be added to the engines that are control by vertical.
            allowedHorizontalDrift = 0.05 --export: (Default: 0.05) Allowed horizontal drift rate, in m/s, during brakelanding with Alignment or Drift prevention active.
            FastOrbit = 0.0 --export: (Default: 0.0) If > 0, and MaintainOrbit is true, ship will add OrbitVelocity * FastOrbit to OrbitVelocity and use engines to maintain. USE AT OWN RISK.
            saveableVariablesPhysics = {speedChangeLarge=_A("speedChangeLarge"), speedChangeSmall=_A("speedChangeSmall"),
            MouseXSensitivity=_A("MouseXSensitivity"), MouseYSensitivity=_A("MouseYSensitivity"),
            autoRollFactor=_A("autoRollFactor"), rollSpeedFactor=_A("rollSpeedFactor"),
            autoRollRollThreshold=_A("autoRollRollThreshold"), minRollVelocity=_A("minRollVelocity"),
            TrajectoryAlignmentStrength=_A("TrajectoryAlignmentStrength"), torqueFactor=_A("torqueFactor"),
            pitchSpeedFactor=_A("pitchSpeedFactor"), yawSpeedFactor=_A("yawSpeedFactor"),
            brakeSpeedFactor=_A("brakeSpeedFactor"), brakeFlatFactor=_A("brakeFlatFactor"),
            DampingMultiplier=_A("DampingMultiplier"), hudTickRate=_A("hudTickRate"),
            ExtraEscapeThrust=_A("ExtraEscapeThrust"), ExtraLongitudeTags=_A("ExtraLongitudeTags"),
            ExtraLateralTags=_A("ExtraLateralTags"), ExtraVerticalTags=_A("ExtraVerticalTags"),
            allowedHorizontalDrift=_A("allowedHorizontalDrift"), FastOrbit=_A("FastOrbit")}

local s, atlas = pcall(require, "autoconf/custom/" .. customAtlas)
if not s then
    atlas = require("atlas")
end

local requireTable = {"autoconf/custom/archhud/globals","autoconf/custom/archhud/hudclass", "autoconf/custom/archhud/apclass", "autoconf/custom/archhud/controlclass",
                      "autoconf/custom/archhud/atlasclass", "autoconf/custom/archhud/baseclass", "autoconf/custom/archhud/shieldclass",
                      "autoconf/custom/archhud/radarclass", "autoconf/custom/archhud/axiscommandoverride", "autoconf/custom/archhud/fueltankdefinitions",
                      "autoconf/custom/archhud/telemetryclass", "autoconf/custom/archhud/userclass"}

for k,v in ipairs(requireTable) do
    local ok, err = pcall(require, v)
    if not ok then system.print("Failed to load " .. v .. ": " .. tostring(err)) end
end

script = {}  -- wrappable container for all the code

VERSION_NUMBER = 2.200


-- DU Events written for wrap and minimization. Written by Dimencia and Archaegeo. Optimization and Automation of scripting by ChronosWS  Linked sources where appropriate, most have been modified.
    function script.onStart()
        PROGRAM.onStart()
    end

    function script.onOnStop()
        PROGRAM.onStop()
    end

    function script.onTick(timerId)
        PROGRAM.onTick(timerId)       -- Various tick timers
    end

    function script.onOnFlush()
        PROGRAM.onFlush()
    end

    function script.onOnUpdate()
        PROGRAM.onUpdate()
    end

    function script.onActionStart(action)
        PROGRAM.controlStart(action)
    end

    function script.onActionStop(action)
        PROGRAM.controlStop(action)
    end

    function script.onActionLoop(action)
        PROGRAM.controlLoop(action)
    end

    function script.onInputText(text)
        PROGRAM.controlInput(text)
    end

    function script.onEnter(id)
        PROGRAM.radarEnter(id)
    end

    function script.onLeave(id)
        PROGRAM.radarLeave(id)
    end

-- Execute Script
    globalDeclare(core, unit, system.getArkTime, math.floor, unit.getAtmosphereDensity) -- Variables that need to be Global, arent user defined, and are declared in globals.lua due to use across multiple modules where their values can change.
    PROGRAM = programClass(Nav, core, unit, atlas, vBooster, hover, telemeter_1, antigrav, dbHud_1, dbHud_2, radar_1, radar_2, shield, gyro, warpdrive, weapon, screenHud_1, transponder_1)

    script.onStart()

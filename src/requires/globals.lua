-- Auto Variable declarations that store status of ship on databank. Do not edit directly here unless you know what you are doing, these change as ship flies.
-- NOTE: autoVariables below must contain any variable that needs to be saved/loaded from databank system

-- Accessor factory for databank save/load system (also defined in ArchHUD.lua for user variables)
local function _A(n)return{set=function(i)_G[n]=i end,get=function()return _G[n]end}end

    BrakeToggleStatus = BrakeToggleDefault
    VertTakeOffEngine = false
    BrakeIsOn = false
    RetrogradeIsOn = false
    ProgradeIsOn = false
    Autopilot = false
    TurnBurn = false
    AltitudeHold = false
    BrakeLanding = false
    AutoTakeoff = false
    Reentry = false
    VertTakeOff = false
    HoldAltitude = 1000 -- In case something goes wrong, give this a decent start value
    AutopilotAccelerating = false
    AutopilotRealigned = false
    AutopilotBraking = false
    AutopilotCruising = false
    AutopilotEndSpeed = 0
    AutopilotStatus = "Aligning"
    PrevViewLock = true
    AutopilotTargetName = "None"
    AutopilotTargetCoords = nil
    AutopilotTargetIndex = 0
    GearExtended = nil
    TotalDistanceTravelled = 0.0
    TotalFlightTime = 0
    SavedLocations = {}
    VectorToTarget = false
    LocationIndex = 0
    LastMaxBrake = 0
    LockPitch = nil
    LastMaxBrakeInAtmo = 0
    AntigravTargetAltitude = 1000
    LastStartTime = 0
    SpaceTarget = false
    LeftAmount = 0
    IntoOrbit = false
    iphCondition = "All"
    stablized = true -- NOTE: intentional misspelling preserved for databank key compatibility
    UseExtra = "Off"
    LastVersionUpdate = 0.000
    saveRoute = {}
    apRoute = {}
    ecuThrottle = {}
    adjMaxGameVelocity = 9000
    SelectedTab = nil

    autoVariables = {VertTakeOff=_A("VertTakeOff"), VertTakeOffEngine=_A("VertTakeOffEngine"),
    SpaceTarget=_A("SpaceTarget"), BrakeToggleStatus=_A("BrakeToggleStatus"),
    BrakeIsOn=_A("BrakeIsOn"), RetrogradeIsOn=_A("RetrogradeIsOn"), ProgradeIsOn=_A("ProgradeIsOn"),
    Autopilot=_A("Autopilot"), TurnBurn=_A("TurnBurn"), AltitudeHold=_A("AltitudeHold"),
    BrakeLanding=_A("BrakeLanding"), Reentry=_A("Reentry"), AutoTakeoff=_A("AutoTakeoff"),
    HoldAltitude=_A("HoldAltitude"), AutopilotAccelerating=_A("AutopilotAccelerating"),
    AutopilotBraking=_A("AutopilotBraking"), AutopilotCruising=_A("AutopilotCruising"),
    AutopilotRealigned=_A("AutopilotRealigned"), AutopilotEndSpeed=_A("AutopilotEndSpeed"),
    AutopilotStatus=_A("AutopilotStatus"), PrevViewLock=_A("PrevViewLock"),
    AutopilotTargetName=_A("AutopilotTargetName"), AutopilotTargetCoords=_A("AutopilotTargetCoords"),
    AutopilotTargetIndex=_A("AutopilotTargetIndex"), TotalDistanceTravelled=_A("TotalDistanceTravelled"),
    TotalFlightTime=_A("TotalFlightTime"), SavedLocations=_A("SavedLocations"),
    VectorToTarget=_A("VectorToTarget"), LocationIndex=_A("LocationIndex"),
    LastMaxBrake=_A("LastMaxBrake"), LockPitch=_A("LockPitch"),
    LastMaxBrakeInAtmo=_A("LastMaxBrakeInAtmo"), AntigravTargetAltitude=_A("AntigravTargetAltitude"),
    LastStartTime=_A("LastStartTime"), iphCondition=_A("iphCondition"),
    stablized=_A("stablized"), UseExtra=_A("UseExtra"), SelectedTab=_A("SelectedTab"),
    saveRoute=_A("saveRoute"), apRoute=_A("apRoute"), ecuThrottle=_A("ecuThrottle"),
    adjMaxGameVelocity=_A("adjMaxGameVelocity")}

-- Shared constants used across multiple modules
    minAutopilotSpeed = 55 -- Minimum speed for autopilot to maneuver in m/s. Keep above 25m/s to prevent nosedives when boosters kick in.

-- Unsaved Globals - Do not edit unless you know what you are doing
    function globalDeclare(c, u, systime, mfloor, atmosphere) -- # is how many classes variable is in
        local s = DUSystem
        local C = DUConstruct
        time = systime() -- 6
        PlayerThrottle = 0 -- 4
        brakeInput2 = 0 -- 2
        ThrottleLimited = false -- 2
        calculatedThrottle = 0 -- 2
        WasInCruise = false -- 3
        hasGear = false -- 4
        pitchInput = 0 -- 2
        rollInput = 0 -- 2
        yawInput = 0 -- 2
        upAmount = 0 -- 2
        followMode = false -- 2
        holdingShift = false -- 3
        leftmouseclick = false
        msgText = "empty" -- 6
        msgTimer = 3 -- 4
        isBoosting = false -- 3 Dodgin's Don't Die Rocket Governor
        brakeDistance = 0 -- 2
        brakeTime = 0 -- 2
        autopilotTargetPlanet = nil -- 4
        simulatedX = 0 -- 3
        simulatedY = 0 -- 3
        distance = 0 -- 4 but needs investigation
        spaceLand = false -- 2
        spaceLaunch = false -- 3
        finalLand = false -- 3
        abvGndDet = -1 -- 4
        inAtmo = (atmosphere() > 0) -- 5
        atmosDensity = atmosphere() -- 4
        coreAltitude = c.getAltitude() -- 3
        coreMass = DUConstruct.getMass() -- 2
        gyroIsOn = nil -- 4
        atmoTanks = {} -- 2
        spaceTanks = {} -- 2
        rocketTanks = {} -- 2
        galaxyReference = nil -- 4
        Kinematic = nil -- 4
        Kep = nil -- 3
        HUD = nil -- 5
        ATLAS = nil -- 4
        AP = nil -- 5
        RADAR = nil -- 3
        CONTROL = nil -- 2
        SHIELD = nil -- 2
        TELEMETRY = nil -- 1
        Animating = false -- 4
        Animated = false -- 2
        autoRoll = autoRollPreference -- 4
        stalling = false -- 2
        adjustedAtmoSpeedLimit = AtmoSpeedLimit -- 4
        orbitMsg = nil -- 2
        OrbitTargetOrbit = 0 -- 2
        OrbitAchieved = false -- 2
        SpaceEngineVertDn = false -- 2
        SpaceEngines = false -- 2
        constructForward = vec3(C.getWorldOrientationForward()) -- 2
        constructRight = vec3(C.getWorldOrientationRight()) -- 3
        coreVelocity = vec3(C.getVelocity()) -- 3
        constructVelocity = vec3(C.getWorldVelocity()) -- 4
        velMag = constructVelocity:len() -- 3
        worldVertical = vec3(c.getWorldVertical()) -- 3
        vSpd = -worldVertical:dot(constructVelocity) -- 2
        worldPos = vec3(C.getWorldPosition()) -- 5
        UpVertAtmoEngine = false -- 3
        antigravOn = false -- 4
        throttleMode = true -- 3
        adjustedPitch = 0 -- 2
        adjustedRoll = 0 -- 2
        AtlasOrdered = {} -- 3
        notPvPZone = false -- 3
        pvpDist = 50000 -- 2
        ReversalIsOn = nil -- 3
        nearPlanet = u.getClosestPlanetInfluence() > 0 or (coreAltitude > 0 and coreAltitude < 200000) -- 3
        collisionAlertStatus = false -- 2
        collisionTarget = nil -- 2
        apButtonsHovered = false -- 2
        apScrollIndex = 0 -- 2
        passengers = {} -- 2
        ships = {} -- 2
        planetAtlas = {} -- 3
        scopeFOV = 90 -- 2
        oldShowHud = showHud -- 2
        ThrottleValue = nil -- 2
        radarPanelID = nil -- 2
        privatelocations = {} -- 3
        customlocations = {} -- 2
        apBrk = false -- 2
        alignHeading = nil -- 2
        mouseDistance = 0 -- 2
        sEFC = false -- 2
        MaxSpeed = C.getMaxSpeed() -- 2
        pipePosC = nil -- 2
        pipeDestC = nil -- 2
        pipeDistC = nil -- 2
        pipePosT = nil -- 2
        pipeDestT = nil -- 2
        pipeDistT = nil -- 2
        alignTarget = false -- 2
        if shield then shieldPercent = mfloor(0.5 + shield.getShieldHitpoints() * 100 / shield.getMaxShieldHitpoints()) end
    end

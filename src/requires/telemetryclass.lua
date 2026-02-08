function TelemetryClass(db, jencode, systime, mfloor, c)
    local Telemetry = {}
    if not db then return nil end

    local lastPublish = 0
    local publishInterval = 1 -- seconds between telemetry writes
    local eleMass = c.getElementMassById

    -- Compute aggregate fuel percentage for a tank array
    -- Tank structure: {id, name, maxVolume, massEmpty, curMass, curTime, slottedIndex}
    local function getFuelSummary(tankTable)
        if not tankTable or #tankTable == 0 then return nil end
        local totalFuel = 0
        local totalCapacity = 0
        local count = #tankTable
        for i = 1, count do
            local tank = tankTable[i]
            local maxVol = tank[3]
            local massEmpty = tank[4]
            local curMass = eleMass(tank[1])
            local fuelMass = curMass - massEmpty
            if fuelMass < 0 then fuelMass = 0 end
            totalFuel = totalFuel + fuelMass
            totalCapacity = totalCapacity + maxVol
        end
        local pct = 0
        if totalCapacity > 0 then
            pct = mfloor(totalFuel / totalCapacity * 100 + 0.5)
        end
        return { pct = pct, count = count }
    end

    function Telemetry.publish()
        local now = systime()
        if now - lastPublish < publishInterval then return end
        lastPublish = now

        -- Flight data
        db.setStringValue("T_flight", jencode({
            spd = mfloor((velMag or 0) * 100) / 100,
            vspd = mfloor((vSpd or 0) * 100) / 100,
            alt = mfloor(coreAltitude or 0),
            atmo = mfloor((atmosDensity or 0) * 10000) / 100,
            mass = mfloor(coreMass or 0),
            thr = mfloor((PlayerThrottle or 0) * 100),
            inA = inAtmo or false,
            near = nearPlanet or false,
            gear = GearExtended or false,
            brk = BrakeIsOn or false,
            time = now
        }))

        -- Autopilot data
        db.setStringValue("T_ap", jencode({
            on = Autopilot or false,
            stat = AutopilotStatus or "Off",
            tgt = AutopilotTargetName or "None",
            brk = AutopilotBraking or false,
            crs = AutopilotCruising or false,
            acc = AutopilotAccelerating or false,
            tb = TurnBurn or false,
            ah = AltitudeHold or false,
            hAlt = HoldAltitude or 0,
            re = Reentry or false,
            bl = BrakeLanding or false,
            orb = IntoOrbit or false,
            vtt = VectorToTarget or false,
            dist = mfloor(distance or 0),
            bDist = mfloor(brakeDistance or 0),
            bTime = mfloor(brakeTime or 0)
        }))

        -- Ship status
        db.setStringValue("T_ship", jencode({
            shld = shieldPercent or -1,
            pvp = not (notPvPZone or false),
            odo = mfloor((TotalDistanceTravelled or 0) * 10) / 10,
            ft = mfloor(TotalFlightTime or 0),
            ver = VERSION_NUMBER or 0
        }))

        -- Fuel summary
        db.setStringValue("T_fuel", jencode({
            atmo = getFuelSummary(atmoTanks),
            space = getFuelSummary(spaceTanks),
            rocket = getFuelSummary(rocketTanks)
        }))
    end

    return Telemetry
end

function TelemetryClass(db, jencode, systime, mfloor, c)
    local Telemetry = {}
    if not db then return nil end

    local lastPublish = 0
    local lastRadar = 0
    local lastDamage = 0
    local publishInterval = 1 -- seconds between flight/ap telemetry writes
    local radarInterval = 2   -- seconds between radar data writes
    local damageInterval = 10 -- seconds between damage scans (expensive)
    local eleMass = c.getElementMassById
    local eleHp = c.getElementHitPointsById
    local eleMaxHp = c.getElementMaxHitPointsById
    local eleIdList = c.getElementIdList()
    local eleName = c.getElementNameById
    local eleDisplayName = c.getElementDisplayNameById

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

    -- Publish radar contact data
    local function publishRadar()
        local radar = radar_1 or radar_2
        if not radar then
            db.setStringValue("T_radar", jencode({count = 0, state = -4}))
            return
        end

        local state = radar.getOperationalState()
        local ids = radar.getConstructIds()
        local count = #ids
        local contacts = {}
        local kindNames = {"Universe","Planet","Asteroid","Static","Dynamic","Space","Alien"}

        -- Limit to 20 contacts for databank size
        local limit = count > 20 and 20 or count
        for i = 1, limit do
            local id = ids[i]
            local dist = mfloor(radar.getConstructDistance(id))
            local kind = radar.getConstructKind(id)
            local friendly = radar.hasMatchingTransponder(id)
            local size = radar.getConstructCoreSize(id)
            local name = radar.getConstructName(id)
            if name == "" then name = "Unknown" end
            contacts[i] = {
                n = name,
                d = dist,
                s = size,
                k = kindNames[kind] or "Unknown",
                f = friendly
            }
        end

        db.setStringValue("T_radar", jencode({
            count = count,
            state = state,
            pvp = not (notPvPZone or false),
            list = contacts
        }))
    end

    -- Publish damage report data
    local function publishDamage()
        local totalMax = 0
        local totalCur = 0
        local damaged = {}
        local damagedCount = 0
        local disabledCount = 0
        local totalElements = #eleIdList

        for k in pairs(eleIdList) do
            local id = eleIdList[k]
            local hp = eleHp(id)
            local mhp = eleMaxHp(id)
            totalMax = totalMax + mhp
            totalCur = totalCur + hp
            if hp + 1 < mhp then
                local entry = {
                    n = eleName(id),
                    t = eleDisplayName(id),
                    hp = mfloor(hp),
                    mhp = mfloor(mhp)
                }
                if hp == 0 then
                    disabledCount = disabledCount + 1
                    entry.off = true
                else
                    damagedCount = damagedCount + 1
                end
                -- Limit to 30 damaged elements for databank size
                if #damaged < 30 then
                    damaged[#damaged + 1] = entry
                end
            end
        end

        local pct = 100
        if totalMax > 0 then
            pct = mfloor(totalCur / totalMax * 10000 + 0.5) / 100
        end

        db.setStringValue("T_damage", jencode({
            pct = pct,
            dmg = damagedCount,
            off = disabledCount,
            tot = totalElements,
            list = damaged
        }))
    end

    function Telemetry.publish()
        local now = systime()

        -- Flight, AP, ship, fuel data (every 1 second)
        if now - lastPublish >= publishInterval then
            lastPublish = now

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

            db.setStringValue("T_ship", jencode({
                shld = shieldPercent or -1,
                pvp = not (notPvPZone or false),
                odo = mfloor((TotalDistanceTravelled or 0) * 10) / 10,
                ft = mfloor(TotalFlightTime or 0),
                ver = VERSION_NUMBER or 0
            }))

            db.setStringValue("T_fuel", jencode({
                atmo = getFuelSummary(atmoTanks),
                space = getFuelSummary(spaceTanks),
                rocket = getFuelSummary(rocketTanks)
            }))
        end

        -- Radar data (every 2 seconds)
        if now - lastRadar >= radarInterval then
            lastRadar = now
            publishRadar()
        end

        -- Damage data (every 10 seconds)
        if now - lastDamage >= damageInterval then
            lastDamage = now
            publishDamage()
        end
    end

    return Telemetry
end

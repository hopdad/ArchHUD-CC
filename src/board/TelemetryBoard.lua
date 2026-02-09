-- ArchHUD Telemetry Dashboard - Programming Board Script
-- Reads telemetry data from a shared databank and renders a dashboard on a linked screen.
-- Link this programming board to the SAME databank used by ArchHUD (dbHud slot) and a screen.
--
-- Slots:
--   db    = databank (same one linked to your seat/ECU as dbHud)
--   screen = ScreenUnit

local db = db ---@type databank
local screen = screen ---@type ScreenUnit
local unit = unit ---@type ProgrammingBoard
local system = system

local jdecode = json.decode
local mfloor = math.floor
local stringf = string.format

-- State
local lastUpdate = 0

-- Safe JSON decode with fallback
local function safeDecode(key)
    if not db.hasKey(key) then return nil end
    local ok, result = pcall(jdecode, db.getStringValue(key))
    if ok then return result end
    return nil
end

-- Format speed for display
local function fmtSpeed(mps)
    if mps > 1000 then
        return stringf("%.1f km/s", mps / 1000)
    else
        return stringf("%.0f m/s", mps)
    end
end

local function fmtSpeedKmh(mps)
    return stringf("%.0f km/h", mps * 3.6)
end

-- Format altitude
local function fmtAlt(meters)
    if meters > 100000 then
        return stringf("%.2f su", meters / 200000)
    elseif meters > 1000 then
        return stringf("%.1f km", meters / 1000)
    else
        return stringf("%.0f m", meters)
    end
end

-- Format distance
local function fmtDist(meters)
    if meters > 200000 then
        return stringf("%.2f su", meters / 200000)
    elseif meters > 1000 then
        return stringf("%.1f km", meters / 1000)
    else
        return stringf("%.0f m", meters)
    end
end

-- Format time from seconds
local function fmtTime(seconds)
    if seconds <= 0 then return "0s" end
    local d = mfloor(seconds / 86400)
    local h = mfloor((seconds % 86400) / 3600)
    local m = mfloor((seconds % 3600) / 60)
    local s = mfloor(seconds % 60)
    if d > 365 then return ">1y"
    elseif d > 0 then return stringf("%dd %dh", d, h)
    elseif h > 0 then return stringf("%dh %dm", h, m)
    elseif m > 0 then return stringf("%dm %ds", m, s)
    else return stringf("%ds", s)
    end
end

-- Color helpers
local function rgb(r, g, b) return stringf("rgb(%d,%d,%d)", r, g, b) end
local function rgba(r, g, b, a) return stringf("rgba(%d,%d,%d,%.2f)", r, g, b, a) end

-- Theme colors
local accentColor = rgb(130, 224, 255)
local dimColor = rgb(90, 155, 180)
local warnColor = rgb(255, 165, 0)
local dangerColor = rgb(255, 60, 60)
local safeColor = rgb(60, 255, 120)
local pvpColor = rgb(255, 60, 60)
local bgColor = rgb(12, 16, 22)
local panelColor = rgba(20, 30, 40, 0.85)
local borderColor = rgba(130, 224, 255, 0.3)

-- Build a fuel bar SVG
local function fuelBar(x, y, w, h, pct, label, color)
    if not pct then return "" end
    local fill = mfloor(w * pct / 100)
    local barColor = color or accentColor
    if pct < 10 then barColor = dangerColor
    elseif pct < 25 then barColor = warnColor end
    return stringf([[
        <text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">%s</text>
        <rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="3"/>
        <rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="3"/>
        <text x="%d" y="%d" fill="white" font-size="12" font-family="monospace" text-anchor="end">%d%%</text>
    ]], x, y - 4, dimColor, label,
       x, y, w, h, rgba(40, 50, 60, 0.8),
       x, y, fill, h, barColor,
       x + w + 40, y + h - 3, pct)
end

-- Build status indicator
local function statusDot(x, y, active, label)
    local color = active and safeColor or rgba(60, 70, 80, 0.8)
    return stringf([[
        <circle cx="%d" cy="%d" r="5" fill="%s"/>
        <text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">%s</text>
    ]], x, y, color, x + 12, y + 4, active and accentColor or dimColor, label)
end

-- Main render function
local function renderDashboard()
    local flight = safeDecode("T_flight")
    local ap = safeDecode("T_ap")
    local ship = safeDecode("T_ship")
    local fuel = safeDecode("T_fuel")

    -- Screen dimensions (DU screen HTML mode)
    local sw, sh = 1920, 1080

    local svg = {}
    svg[#svg+1] = stringf([[<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">]], sw, sh)

    -- Background
    svg[#svg+1] = stringf([[<rect width="%d" height="%d" fill="%s"/>]], sw, sh, bgColor)

    -- Title bar
    local titleColor = accentColor
    local zoneLabel = "SAFE ZONE"
    if ship and ship.pvp then
        titleColor = pvpColor
        zoneLabel = "PVP ZONE"
    end
    svg[#svg+1] = stringf([[
        <rect x="0" y="0" width="%d" height="50" fill="%s"/>
        <text x="20" y="34" fill="%s" font-size="22" font-family="monospace" font-weight="bold">ARCHHUD TELEMETRY</text>
        <text x="%d" y="34" fill="%s" font-size="18" font-family="monospace" text-anchor="end">%s</text>
    ]], sw, rgba(20, 30, 40, 0.95), titleColor, sw - 20, ship and ship.pvp and pvpColor or safeColor, zoneLabel)

    if ship and ship.ver then
        svg[#svg+1] = stringf([[<text x="380" y="34" fill="%s" font-size="14" font-family="monospace">v%s</text>]], dimColor, ship.ver)
    end

    -- No data fallback
    if not flight then
        svg[#svg+1] = stringf([[
            <text x="%d" y="%d" fill="%s" font-size="24" font-family="monospace" text-anchor="middle">AWAITING TELEMETRY DATA</text>
            <text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Link this board's databank to the same databank as your ArchHUD seat</text>
        ]], sw/2, sh/2 - 20, warnColor, sw/2, sh/2 + 20, dimColor)
        svg[#svg+1] = "</svg>"
        return table.concat(svg)
    end

    -- ═══════════════════════════════════════
    -- LEFT COLUMN: Flight Data
    -- ═══════════════════════════════════════
    local lx, ly = 30, 70

    -- Flight Panel
    svg[#svg+1] = stringf([[<rect x="%d" y="%d" width="580" height="320" fill="%s" stroke="%s" rx="6"/>]], lx - 10, ly, panelColor, borderColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">FLIGHT DATA</text>]], lx + 10, ly + 28, accentColor)

    local fy = ly + 55
    local lineH = 38

    -- Speed
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">SPEED</text>]], lx + 10, fy, dimColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="28" font-family="monospace">%s</text>]], lx + 120, fy + 2, fmtSpeedKmh(flight.spd))
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">(%s)</text>]], lx + 380, fy, dimColor, fmtSpeed(flight.spd))
    fy = fy + lineH + 6

    -- Altitude
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">ALTITUDE</text>]], lx + 10, fy, dimColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="28" font-family="monospace">%s</text>]], lx + 120, fy + 2, fmtAlt(flight.alt))
    fy = fy + lineH + 6

    -- Vertical Speed
    local vColor = "white"
    if flight.vspd > 10 then vColor = safeColor
    elseif flight.vspd < -10 then vColor = warnColor end
    local vSign = flight.vspd >= 0 and "+" or ""
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">V-SPEED</text>]], lx + 10, fy, dimColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="28" font-family="monospace">%s%.1f m/s</text>]], lx + 120, fy + 2, vColor, vSign, flight.vspd)
    fy = fy + lineH + 6

    -- Atmosphere / Throttle row
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">ATMO</text>]], lx + 10, fy, dimColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="22" font-family="monospace">%.1f%%</text>]], lx + 120, fy + 2, flight.atmo)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">THROTTLE</text>]], lx + 280, fy, dimColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="22" font-family="monospace">%d%%</text>]], lx + 400, fy + 2, flight.thr)
    fy = fy + lineH

    -- Status indicators row
    svg[#svg+1] = statusDot(lx + 10, fy + 8, flight.inA, "IN ATMO")
    svg[#svg+1] = statusDot(lx + 140, fy + 8, flight.gear, "GEAR")
    svg[#svg+1] = statusDot(lx + 240, fy + 8, flight.brk, "BRAKE")
    svg[#svg+1] = statusDot(lx + 350, fy + 8, flight.near, "NEAR PLANET")

    -- ═══════════════════════════════════════
    -- RIGHT COLUMN: Autopilot
    -- ═══════════════════════════════════════
    local rx = 640

    svg[#svg+1] = stringf([[<rect x="%d" y="%d" width="580" height="320" fill="%s" stroke="%s" rx="6"/>]], rx - 10, ly, panelColor, borderColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">AUTOPILOT</text>]], rx + 10, ly + 28, accentColor)

    if ap then
        local ay = ly + 60

        -- AP Status
        local apStatusColor = ap.on and safeColor or dimColor
        local apStatusText = ap.on and "ENGAGED" or "OFF"
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">STATUS</text>]], rx + 10, ay, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="24" font-family="monospace" font-weight="bold">%s</text>]], rx + 120, ay + 2, apStatusColor, apStatusText)
        ay = ay + lineH

        -- AP Phase
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">PHASE</text>]], rx + 10, ay, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>]], rx + 120, ay + 2, ap.stat or "---")
        ay = ay + lineH

        -- Target
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">TARGET</text>]], rx + 10, ay, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>]], rx + 120, ay + 2, ap.tgt or "None")
        ay = ay + lineH

        -- Distance / Brake Distance
        if ap.dist and ap.dist > 0 then
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">DISTANCE</text>]], rx + 10, ay, dimColor)
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>]], rx + 120, ay + 2, fmtDist(ap.dist))
        end
        ay = ay + lineH

        if ap.bDist and ap.bDist > 0 then
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">BRAKE DIST</text>]], rx + 10, ay, dimColor)
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="20" font-family="monospace">%s</text>]], rx + 120, ay + 2, warnColor, fmtDist(ap.bDist))
        end
        ay = ay + lineH + 10

        -- AP Mode indicators
        svg[#svg+1] = statusDot(rx + 10, ay, ap.ah, "ALT HOLD")
        svg[#svg+1] = statusDot(rx + 150, ay, ap.tb, "TURN+BURN")
        svg[#svg+1] = statusDot(rx + 300, ay, ap.orb, "ORBIT")
        svg[#svg+1] = statusDot(rx + 420, ay, ap.re, "REENTRY")
    end

    -- ═══════════════════════════════════════
    -- BOTTOM LEFT: Fuel
    -- ═══════════════════════════════════════
    local by = 420

    svg[#svg+1] = stringf([[<rect x="%d" y="%d" width="580" height="220" fill="%s" stroke="%s" rx="6"/>]], lx - 10, by, panelColor, borderColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">FUEL</text>]], lx + 10, by + 28, accentColor)

    if fuel then
        local barY = by + 50
        local barW = 420
        local barH = 18
        local barSpacing = 55

        if fuel.atmo then
            svg[#svg+1] = fuelBar(lx + 10, barY, barW, barH, fuel.atmo.pct, stringf("ATMO  [%d]", fuel.atmo.count))
            barY = barY + barSpacing
        end
        if fuel.space then
            svg[#svg+1] = fuelBar(lx + 10, barY, barW, barH, fuel.space.pct, stringf("SPACE [%d]", fuel.space.count))
            barY = barY + barSpacing
        end
        if fuel.rocket then
            svg[#svg+1] = fuelBar(lx + 10, barY, barW, barH, fuel.rocket.pct, stringf("RCKT  [%d]", fuel.rocket.count))
        end
    else
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">No fuel data available</text>]], lx + 10, by + 60, dimColor)
    end

    -- ═══════════════════════════════════════
    -- BOTTOM RIGHT: Ship Status & Odometer
    -- ═══════════════════════════════════════
    svg[#svg+1] = stringf([[<rect x="%d" y="%d" width="580" height="220" fill="%s" stroke="%s" rx="6"/>]], rx - 10, by, panelColor, borderColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">SHIP STATUS</text>]], rx + 10, by + 28, accentColor)

    local sy = by + 60

    -- Shield
    if ship and ship.shld >= 0 then
        local shieldColor = accentColor
        if ship.shld < 25 then shieldColor = dangerColor
        elseif ship.shld < 50 then shieldColor = warnColor end
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">SHIELD</text>]], rx + 10, sy, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="24" font-family="monospace">%d%%</text>]], rx + 120, sy + 2, shieldColor, ship.shld)
    else
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">SHIELD</text>]], rx + 10, sy, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="20" font-family="monospace">N/A</text>]], rx + 120, sy + 2, dimColor)
    end

    -- Mass
    if flight then
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">MASS</text>]], rx + 280, sy, dimColor)
        local massStr = flight.mass > 1000 and stringf("%.1f t", flight.mass / 1000) or stringf("%d kg", flight.mass)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>]], rx + 380, sy + 2, massStr)
    end
    sy = sy + 50

    -- Odometer
    svg[#svg+1] = stringf([[<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]], rx, sy - 15, rx + 560, sy - 15, borderColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace" font-weight="bold">ODOMETER</text>]], rx + 10, sy, accentColor)
    sy = sy + 32

    if ship then
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">TOTAL DIST</text>]], rx + 10, sy, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>]], rx + 160, sy + 2, fmtDist(ship.odo))

        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">FLIGHT TIME</text>]], rx + 300, sy, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>]], rx + 450, sy + 2, fmtTime(ship.ft))
    end

    -- ═══════════════════════════════════════
    -- BOTTOM BAR: Data freshness
    -- ═══════════════════════════════════════
    if flight and flight.time then
        local age = system.getArkTime() - flight.time
        local freshColor = age < 3 and safeColor or (age < 10 and warnColor or dangerColor)
        local freshText = age < 3 and "LIVE" or stringf("%.0fs AGO", age)
        svg[#svg+1] = stringf([[
            <circle cx="30" cy="%d" r="5" fill="%s"/>
            <text x="42" y="%d" fill="%s" font-size="13" font-family="monospace">DATA: %s</text>
        ]], sh - 20, freshColor, sh - 15, freshColor, freshText)
    end

    svg[#svg+1] = "</svg>"
    return table.concat(svg)
end

-- ════════════════════════════════════════════
-- Script entry points (called by conf handlers)
-- ════════════════════════════════════════════
script = {}

function script.onStart()
    if not db then
        system.print("ArchHUD Telemetry: No databank linked. Link a databank and restart.")
        return
    end
    if not screen then
        system.print("ArchHUD Telemetry: No screen linked. Link a screen and restart.")
        return
    end
    unit.setTimer("refresh", 1)
    system.print("ArchHUD Telemetry Dashboard started.")
    -- Render once immediately
    screen.setHTML(renderDashboard())
end

function script.onStop()
    if screen then
        screen.setHTML("")
    end
end

function script.onTick(timerId)
    if timerId == "refresh" then
        if screen and db then
            screen.setHTML(renderDashboard())
        end
    end
end

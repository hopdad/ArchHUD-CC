-- ArchHUD Route Planner Display - Programming Board Script
-- Reads route telemetry (T_route) and autopilot data (T_ap, T_flight) from a shared
-- databank and renders a route overview on a linked screen.
--
-- Shows: active route waypoints with leg distances, ship distance, ETAs,
-- overall progress bar, and saved route status.
--
-- Slots:
--   db     = databank (same one linked to your seat/ECU as dbHud)
--   screen = ScreenUnit
--
-- Databank keys used:
--   T_route  = {active, count, wps=[...], totalDist, remainDist, totalEta, remainEta, progress, tgt, spd}
--   T_ap     = {on, stat, tgt, dist, bDist, bTime, ...}
--   T_flight = {spd, alt, time, ...}

local db = db         ---@type databank
local screen = screen ---@type ScreenUnit
local unit = unit     ---@type ProgrammingBoard
local system = system

local jdecode = json.decode
local mfloor  = math.floor
local mmin    = math.min
local mmax    = math.max
local stringf = string.format

-- ═══════════════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════════════

local function safeDecode(key)
    if not db.hasKey(key) then return nil end
    local ok, result = pcall(jdecode, db.getStringValue(key))
    if ok then return result end
    return nil
end

local function esc(str)
    if not str then return "?" end
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

local function rgb(r, g, b)
    return stringf("rgb(%d,%d,%d)", r, g, b)
end

local function rgba(r, g, b, a)
    return stringf("rgba(%d,%d,%d,%.2f)", r, g, b, a)
end

-- ═══════════════════════════════════════════════
-- Theme Colors
-- ═══════════════════════════════════════════════

local accentColor = rgb(130, 224, 255)
local dimColor    = rgb(90, 155, 180)
local warnColor   = rgb(255, 165, 0)
local dangerColor = rgb(255, 60, 60)
local safeColor   = rgb(60, 255, 120)
local bgColor     = rgb(12, 16, 22)
local panelColor  = rgba(20, 30, 40, 0.85)
local borderColor = rgba(130, 224, 255, 0.3)
local routeColor  = rgb(100, 200, 255)       -- Route line/connector color
local completedColor = rgba(60, 255, 120, 0.6) -- Completed waypoint
local currentColor = rgb(255, 220, 50)         -- Current target highlight
local pendingColor = rgba(130, 224, 255, 0.5)  -- Future waypoints

-- ═══════════════════════════════════════════════
-- Formatting Helpers
-- ═══════════════════════════════════════════════

--- Format distance for display
local function fmtDist(meters)
    if not meters or meters == 0 then return "---" end
    if meters > 200000 then
        return stringf("%.2f su", meters / 200000)
    elseif meters > 10000 then
        return stringf("%.1f km", meters / 1000)
    elseif meters > 1000 then
        return stringf("%.2f km", meters / 1000)
    else
        return stringf("%.0f m", meters)
    end
end

--- Format time in seconds to readable string
local function fmtTime(seconds)
    if not seconds or seconds <= 0 then return "---" end
    if seconds > 86400 then
        local d = mfloor(seconds / 86400)
        local h = mfloor((seconds % 86400) / 3600)
        return stringf("%dd %dh", d, h)
    elseif seconds > 3600 then
        local h = mfloor(seconds / 3600)
        local m = mfloor((seconds % 3600) / 60)
        return stringf("%dh %dm", h, m)
    elseif seconds > 60 then
        local m = mfloor(seconds / 60)
        local s = mfloor(seconds % 60)
        return stringf("%dm %ds", m, s)
    else
        return stringf("%ds", mfloor(seconds))
    end
end

--- Format speed
local function fmtSpeed(mps)
    if not mps or mps == 0 then return "0 km/h" end
    return stringf("%.0f km/h", mps * 3.6)
end

-- ═══════════════════════════════════════════════
-- Main Render Function
-- ═══════════════════════════════════════════════

function renderDashboard()
    local route  = safeDecode("T_route")
    local ap     = safeDecode("T_ap")
    local flight = safeDecode("T_flight")

    local sw, sh = 1920, 1080
    local svg = {}

    svg[#svg+1] = stringf([[<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">]], sw, sh)

    -- Background
    svg[#svg+1] = stringf([[<rect width="%d" height="%d" fill="%s"/>]], sw, sh, bgColor)

    -- ── Title Bar ──────────────────────────────
    svg[#svg+1] = stringf(
        [[<rect x="0" y="0" width="%d" height="50" fill="%s"/>]] ..
        [[<text x="20" y="34" fill="%s" font-size="22" font-family="monospace" font-weight="bold">ARCHHUD ROUTE PLANNER</text>]],
        sw, rgba(20, 30, 40, 0.95), accentColor)

    -- Data freshness indicator (top right)
    if flight and flight.time then
        local age = system.getArkTime() - flight.time
        local freshColor = age < 5 and safeColor or (age < 15 and warnColor or dangerColor)
        local freshText = age < 5 and "LIVE" or stringf("%.0fs AGO", age)
        svg[#svg+1] = stringf(
            [[<circle cx="%d" cy="25" r="5" fill="%s"/>]] ..
            [[<text x="%d" y="30" fill="%s" font-size="14" font-family="monospace" text-anchor="end">DATA: %s</text>]],
            sw - 200, freshColor, sw - 20, freshColor, freshText)
    end

    -- ── No Data Fallback ─────────────────────────
    if not route then
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="28" font-family="monospace" text-anchor="middle" font-weight="bold">AWAITING DATA</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Link this board to the same databank as your ArchHUD seat</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" text-anchor="middle">Route telemetry is published every 3 seconds while seated</text>]],
            sw/2, sh/2 - 30, warnColor,
            sw/2, sh/2 + 10, dimColor,
            sw/2, sh/2 + 40, dimColor)
        svg[#svg+1] = "</svg>"
        return table.concat(svg)
    end

    -- ══════════════════════════════════════════════
    -- NO ACTIVE ROUTE
    -- ══════════════════════════════════════════════
    if not route.active then
        -- Show "no route" state with saved route info
        svg[#svg+1] = stringf(
            [[<rect x="40" y="80" width="%d" height="200" fill="%s" stroke="%s" rx="8"/>]],
            sw - 80, panelColor, borderColor)

        svg[#svg+1] = stringf(
            [[<text x="%d" y="170" fill="%s" font-size="32" font-family="monospace" text-anchor="middle" font-weight="bold">NO ACTIVE ROUTE</text>]],
            sw/2, dimColor)

        svg[#svg+1] = stringf(
            [[<text x="%d" y="210" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Select a target in ArchHUD and use ALT+9 to add waypoints to a route</text>]],
            sw/2, rgba(130, 224, 255, 0.5))

        -- Saved route status
        if route.saved and route.savedCount > 0 then
            svg[#svg+1] = stringf(
                [[<text x="%d" y="250" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Saved route available: %d waypoints (use ALT+9 menu to load)</text>]],
                sw/2, safeColor, route.savedCount)

            -- Show saved route waypoints if available
            if route.savedList then
                local listY = 320
                svg[#svg+1] = stringf(
                    [[<rect x="40" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="8"/>]],
                    listY - 10, sw - 80, mmin(#route.savedList * 40 + 60, sh - listY - 30), panelColor, borderColor)

                svg[#svg+1] = stringf(
                    [[<text x="70" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">SAVED ROUTE</text>]],
                    listY + 20, accentColor)

                -- Separator
                svg[#svg+1] = stringf(
                    [[<line x1="60" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
                    listY + 30, sw - 60, listY + 30, borderColor)

                local ey = listY + 55
                local maxShow = mfloor((sh - listY - 80) / 40)
                for i = 1, mmin(#route.savedList, maxShow) do
                    local name = esc(route.savedList[i])

                    -- Waypoint number circle
                    svg[#svg+1] = stringf(
                        [[<circle cx="85" cy="%d" r="12" fill="none" stroke="%s" stroke-width="1.5"/>]] ..
                        [[<text x="85" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="middle">%d</text>]],
                        ey - 5, pendingColor, ey - 1, pendingColor, i)

                    -- Connector line to next waypoint
                    if i < #route.savedList and i < maxShow then
                        svg[#svg+1] = stringf(
                            [[<line x1="85" y1="%d" x2="85" y2="%d" stroke="%s" stroke-width="1" stroke-dasharray="4,3"/>]],
                            ey + 7, ey + 28, rgba(130, 224, 255, 0.2))
                    end

                    -- Name
                    svg[#svg+1] = stringf(
                        [[<text x="115" y="%d" fill="%s" font-size="16" font-family="monospace">%s</text>]],
                        ey, pendingColor, name)

                    ey = ey + 40
                end

                if #route.savedList > maxShow then
                    svg[#svg+1] = stringf(
                        [[<text x="115" y="%d" fill="%s" font-size="13" font-family="monospace">... +%d more waypoints</text>]],
                        ey, dimColor, #route.savedList - maxShow)
                end
            end
        else
            svg[#svg+1] = stringf(
                [[<text x="%d" y="250" fill="%s" font-size="15" font-family="monospace" text-anchor="middle">No saved route on databank</text>]],
                sw/2, dimColor)
        end

        -- Autopilot status footer
        if ap then
            svg[#svg+1] = stringf(
                [[<text x="40" y="%d" fill="%s" font-size="14" font-family="monospace">AP TARGET: %s</text>]],
                sh - 20, ap.on and safeColor or dimColor, esc(ap.tgt or "None"))
            if ap.dist and ap.dist > 0 then
                svg[#svg+1] = stringf(
                    [[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" text-anchor="end">DISTANCE: %s</text>]],
                    sw - 40, sh - 20, dimColor, fmtDist(ap.dist))
            end
        end

        svg[#svg+1] = "</svg>"
        return table.concat(svg)
    end

    -- ══════════════════════════════════════════════
    -- ACTIVE ROUTE DISPLAY
    -- ══════════════════════════════════════════════

    local wps = route.wps or {}
    local wpCount = route.count or #wps
    local progress = route.progress or 0
    local spd = route.spd or 0

    -- ── Overview Panel ────────────────────────────
    local ovY = 60
    local ovH = 130
    svg[#svg+1] = stringf(
        [[<rect x="20" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>]],
        ovY, sw - 40, ovH, panelColor, borderColor)

    -- Route progress label
    svg[#svg+1] = stringf(
        [[<text x="50" y="%d" fill="%s" font-size="14" font-family="monospace">ROUTE PROGRESS</text>]],
        ovY + 28, dimColor)

    -- Progress percentage (large)
    svg[#svg+1] = stringf(
        [[<text x="260" y="%d" fill="%s" font-size="28" font-family="monospace" font-weight="bold">%.1f%%</text>]],
        ovY + 30, accentColor, progress)

    -- Progress bar
    local pBarX = 50
    local pBarY = ovY + 42
    local pBarW = sw - 100
    local pBarH = 20
    local pBarFill = mmax(0, mfloor(pBarW * progress / 100))

    -- Bar track
    svg[#svg+1] = stringf(
        [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>]],
        pBarX, pBarY, pBarW, pBarH, rgba(40, 50, 60, 0.8))

    -- Bar fill
    if pBarFill > 0 then
        svg[#svg+1] = stringf(
            [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>]],
            pBarX, pBarY, pBarFill, pBarH, accentColor)
    end

    -- Bar border
    svg[#svg+1] = stringf(
        [[<rect x="%d" y="%d" width="%d" height="%d" fill="none" stroke="%s" rx="4"/>]],
        pBarX, pBarY, pBarW, pBarH, borderColor)

    -- Waypoint markers on progress bar
    for i = 1, wpCount do
        local markerX = pBarX + mfloor(pBarW * (i / wpCount))
        local markerColor = wps[i] and wps[i].cur and currentColor or rgba(255, 255, 255, 0.4)
        svg[#svg+1] = stringf(
            [[<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
            markerX, pBarY, markerX, pBarY + pBarH, markerColor)
    end

    -- Stats row below progress bar
    local statsY = pBarY + pBarH + 22

    -- Total distance
    svg[#svg+1] = stringf(
        [[<text x="50" y="%d" fill="%s" font-size="12" font-family="monospace">TOTAL</text>]] ..
        [[<text x="50" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>]],
        statsY, dimColor, statsY + 18, accentColor, fmtDist(route.totalDist))

    -- Remaining distance
    svg[#svg+1] = stringf(
        [[<text x="350" y="%d" fill="%s" font-size="12" font-family="monospace">REMAINING</text>]] ..
        [[<text x="350" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>]],
        statsY, dimColor, statsY + 18, warnColor, fmtDist(route.remainDist))

    -- ETA to completion
    svg[#svg+1] = stringf(
        [[<text x="700" y="%d" fill="%s" font-size="12" font-family="monospace">ETA</text>]] ..
        [[<text x="700" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>]],
        statsY, dimColor, statsY + 18, safeColor, fmtTime(route.remainEta))

    -- Current speed
    svg[#svg+1] = stringf(
        [[<text x="1000" y="%d" fill="%s" font-size="12" font-family="monospace">SPEED</text>]] ..
        [[<text x="1000" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>]],
        statsY, dimColor, statsY + 18, accentColor, fmtSpeed(spd))

    -- Waypoints counter
    svg[#svg+1] = stringf(
        [[<text x="1350" y="%d" fill="%s" font-size="12" font-family="monospace">WAYPOINTS</text>]] ..
        [[<text x="1350" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%d</text>]],
        statsY, dimColor, statsY + 18, accentColor, wpCount)

    -- Autopilot status
    local apOn = ap and ap.on
    local apStatColor = apOn and safeColor or dimColor
    local apStatText = apOn and "ACTIVE" or "OFF"
    svg[#svg+1] = stringf(
        [[<text x="1600" y="%d" fill="%s" font-size="12" font-family="monospace">AUTOPILOT</text>]] ..
        [[<text x="1600" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>]],
        statsY, dimColor, statsY + 18, apStatColor, apStatText)

    -- ── Waypoint List Panel ──────────────────────
    local listTop = ovY + ovH + 15
    local listBot = sh - 50
    local listX = 20
    local listW = sw - 40

    svg[#svg+1] = stringf(
        [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>]],
        listX, listTop, listW, listBot - listTop, panelColor, borderColor)

    -- Column headers
    local hdrY = listTop + 25
    local colNum = 70
    local colName = 140
    local colPlanet = 850
    local colLeg = 1100
    local colDist = 1350
    local colEta = 1650

    svg[#svg+1] = stringf(
        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">#</text>]] ..
        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">WAYPOINT</text>]] ..
        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">PLANET</text>]] ..
        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">LEG DIST</text>]] ..
        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">FROM SHIP</text>]] ..
        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">ETA</text>]],
        colNum, hdrY, accentColor,
        colName, hdrY, accentColor,
        colPlanet, hdrY, accentColor,
        colLeg, hdrY, accentColor,
        colDist, hdrY, accentColor,
        colEta, hdrY, accentColor)

    -- Header separator
    svg[#svg+1] = stringf(
        [[<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
        listX + 15, hdrY + 10, listX + listW - 15, hdrY + 10, borderColor)

    -- ── Render Waypoint Rows ─────────────────────
    local rowH = 58
    local rowStartY = hdrY + 20
    local maxRows = mfloor((listBot - rowStartY - 10) / rowH)
    local connectorX = 55 -- X position for the vertical route line

    for i = 1, mmin(wpCount, maxRows) do
        local wp = wps[i]
        if not wp then break end

        local ry = rowStartY + ((i - 1) * rowH)
        local isCurrent = wp.cur
        local name = esc(wp.n or "Unknown")
        if #name > 42 then name = name:sub(1, 40) .. ".." end
        local planet = esc(wp.p or "")
        local legDist = fmtDist(wp.leg)
        local shipDist = fmtDist(wp.d)
        local eta = "---"
        if spd > 1 and wp.d and wp.d > 0 then
            eta = fmtTime(wp.d / spd)
        end

        -- Row styling
        local nodeColor, nameColor, textColor
        if isCurrent then
            nodeColor = currentColor
            nameColor = currentColor
            textColor = "white"
            -- Highlight current row background
            svg[#svg+1] = stringf(
                [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="3"/>]],
                listX + 5, ry - 8, listW - 10, rowH - 4, rgba(255, 220, 50, 0.08))
        else
            nodeColor = pendingColor
            nameColor = pendingColor
            textColor = dimColor
        end

        -- Vertical connector line (between waypoints)
        if i < wpCount and i < maxRows then
            svg[#svg+1] = stringf(
                [[<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2" stroke-dasharray="4,4"/>]],
                connectorX, ry + 14, connectorX, ry + rowH - 8, rgba(130, 224, 255, 0.2))
        end

        -- Waypoint node circle
        if isCurrent then
            -- Double ring for current target
            svg[#svg+1] = stringf(
                [[<circle cx="%d" cy="%d" r="14" fill="none" stroke="%s" stroke-width="2"/>]] ..
                [[<circle cx="%d" cy="%d" r="8" fill="%s"/>]],
                connectorX, ry + 2, currentColor,
                connectorX, ry + 2, currentColor)
        else
            svg[#svg+1] = stringf(
                [[<circle cx="%d" cy="%d" r="12" fill="none" stroke="%s" stroke-width="1.5"/>]] ..
                [[<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="middle">%d</text>]],
                connectorX, ry + 2, nodeColor,
                connectorX, ry + 6, nodeColor, i)
        end

        -- Waypoint number (for current, show as label instead)
        if isCurrent then
            svg[#svg+1] = stringf(
                [[<text x="%d" y="%d" fill="%s" font-size="11" font-family="monospace" text-anchor="middle">%d</text>]],
                connectorX, ry + 5, rgb(12, 16, 22), i)
        end

        -- Waypoint name
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="17" font-family="monospace"%s>%s</text>]],
            colName, ry + 6, nameColor, isCurrent and ' font-weight="bold"' or "", name)

        -- Current target indicator label
        if isCurrent then
            svg[#svg+1] = stringf(
                [[<text x="%d" y="%d" fill="%s" font-size="11" font-family="monospace">CURRENT TARGET</text>]],
                colName, ry + 22, currentColor)
        end

        -- Planet
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
            colPlanet, ry + 6, textColor, planet)

        -- Leg distance
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
            colLeg, ry + 6, textColor, legDist)

        -- Distance from ship
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace"%s>%s</text>]],
            colDist, ry + 6, isCurrent and currentColor or textColor,
            isCurrent and ' font-weight="bold"' or "", shipDist)

        -- ETA from ship
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
            colEta, ry + 6, isCurrent and safeColor or textColor, eta)
    end

    -- Overflow indicator
    if wpCount > maxRows then
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" text-anchor="middle">... +%d more waypoints</text>]],
            sw/2, listBot - 10, dimColor, wpCount - maxRows)
    end

    -- ── Footer Bar ───────────────────────────────
    local footY = sh - 35
    svg[#svg+1] = stringf(
        [[<line x1="20" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
        footY, sw - 20, footY, borderColor)

    -- Current AP target
    local tgtName = route.tgt or (ap and ap.tgt) or "None"
    svg[#svg+1] = stringf(
        [[<text x="40" y="%d" fill="%s" font-size="13" font-family="monospace">TARGET: %s</text>]],
        footY + 18, accentColor, esc(tgtName))

    -- Saved route indicator
    if route.saved then
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="end">SAVED ROUTE: %d WP</text>]],
            sw - 40, footY + 18, dimColor, route.savedCount or 0)
    end

    svg[#svg+1] = "</svg>"
    return table.concat(svg)
end

-- ═══════════════════════════════════════════════
-- Script Entry Points (called by conf handlers)
-- ═══════════════════════════════════════════════
script = {}

function script.onStart()
    if not db then
        system.print("ArchHUD Route: No databank linked.")
        return
    end
    if not screen then
        system.print("ArchHUD Route: No screen linked.")
        return
    end
    unit.setTimer("refresh", 3)
    system.print("ArchHUD Route Planner started.")
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

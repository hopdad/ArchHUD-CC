-- ArchHUD Radar Tactical Display - Programming Board Script
-- Reads radar telemetry data from a shared databank and renders a tactical contact display on a linked screen.
--
-- ═══════════════════════════════════════════════════════
-- SETUP INSTRUCTIONS
-- ═══════════════════════════════════════════════════════
-- 1. Place a programming board, a screen, and link BOTH to the same databank
--    used by your ArchHUD seat (the dbHud slot).
-- 2. Right-click the programming board > Advanced > Edit Lua.
-- 3. In the slot list (left side), rename the databank slot to "db"
--    and the screen slot to "screen".
-- 4. Select the filter: unit > onStart
--    Paste this ENTIRE script into the code editor.
-- 5. Add a NEW filter: unit > onTimer(timerId)
--    Paste this single line:     onBoardTick(timerId)
-- 6. Add a NEW filter: unit > onStop
--    Paste this single line:     if screen then screen.setHTML("") end
-- 7. Apply changes and activate the programming board.
-- ═══════════════════════════════════════════════════════
--
-- Databank keys read:
--   T_radar  = radar contact list and state (published by ArchHUD every 2s)
--   T_flight = flight telemetry (for timestamp/freshness check)
--   T_ship   = ship info (for PVP zone status)
--
-- T_radar structure:
--   { count=N, state=1, pvp=true/false, list={ {n="Name", d=meters, s="M", k="Dynamic", f=false}, ... } }
--
-- Radar state codes:
--   1=Operational, 0=Broken, -1=Jammed, -2=Obstructed, -3=In Use, -4=No Radar
--
-- Slots (rename in the Lua editor slot list):
--   db     = databank (same one linked to your seat/ECU as dbHud)
--   screen = ScreenUnit

local db = db       ---@type databank
local screen = screen ---@type ScreenUnit
local unit = unit   ---@type ProgrammingBoard
local system = system

local jdecode = json.decode
local jencode = json.encode
local mfloor = math.floor
local stringf = string.format
local tblSort = table.sort
local tblConcat = table.concat

-- Alert state: track previous contacts to detect new arrivals
local prevContactIds = {}   -- set of previously seen contact names+distance keys
local prevThreatClose = 0   -- count of hostiles within 2km last tick

-- ════════════════════════════════════════════
-- Helpers
-- ════════════════════════════════════════════

-- Safe JSON decode with fallback
local function safeDecode(key)
    if not db.hasKey(key) then return nil end
    local ok, result = pcall(jdecode, db.getStringValue(key))
    if ok then return result end
    return nil
end

-- Format distance for display
local function fmtDist(meters)
    if meters > 200000 then
        return stringf("%.2f su", meters / 200000)
    elseif meters > 1000 then
        return stringf("%.1f km", meters / 1000)
    else
        return stringf("%.0f m", meters)
    end
end

-- Color helpers
local function rgb(r, g, b) return stringf("rgb(%d,%d,%d)", r, g, b) end
local function rgba(r, g, b, a) return stringf("rgba(%d,%d,%d,%.2f)", r, g, b, a) end

-- Escape special XML characters in contact names
local function escXml(s)
    if not s then return "?" end
    return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

-- ════════════════════════════════════════════
-- Theme colors (matches Telemetry Dashboard)
-- ════════════════════════════════════════════
local accentColor  = rgb(130, 224, 255)
local dimColor     = rgb(90, 155, 180)
local warnColor    = rgb(255, 165, 0)
local dangerColor  = rgb(255, 60, 60)
local safeColor    = rgb(60, 255, 120)
local pvpColor     = rgb(255, 60, 60)
local bgColor      = rgb(12, 16, 22)
local panelColor   = rgba(20, 30, 40, 0.85)
local borderColor  = rgba(130, 224, 255, 0.3)
local staticColor  = rgb(100, 110, 125)
local amberColor   = rgb(255, 190, 50)

-- ════════════════════════════════════════════
-- Radar state labels
-- ════════════════════════════════════════════
local radarStateLabels = {
    [1]  = "OPERATIONAL",
    [0]  = "BROKEN",
    [-1] = "JAMMED",
    [-2] = "OBSTRUCTED",
    [-3] = "IN USE",
    [-4] = "NO RADAR",
}

local radarStateColors = {
    [1]  = safeColor,
    [0]  = dangerColor,
    [-1] = dangerColor,
    [-2] = warnColor,
    [-3] = warnColor,
    [-4] = dimColor,
}

-- ════════════════════════════════════════════
-- Contact color logic
-- ════════════════════════════════════════════
local function contactColor(contact, isPvp)
    -- Friendly contacts are always green
    if contact.f then
        return safeColor
    end
    -- Static constructs are dim
    if contact.k == "Static" then
        return staticColor
    end
    -- Dynamic constructs in PVP zone
    if isPvp then
        if contact.d < 2000 then
            return dangerColor   -- Close proximity = red alert
        else
            return amberColor    -- PVP zone dynamic = amber warning
        end
    end
    -- Dynamic constructs in safe zone
    return accentColor
end

-- ════════════════════════════════════════════
-- Friendly status label
-- ════════════════════════════════════════════
local function friendlyLabel(contact)
    if contact.f then return "FRIENDLY" end
    return "UNKNOWN"
end

local function friendlyColor(contact)
    if contact.f then return safeColor end
    return dimColor
end

-- ════════════════════════════════════════════
-- Main render function
-- ════════════════════════════════════════════
local function renderDashboard()
    local radar  = safeDecode("T_radar")
    local flight = safeDecode("T_flight")
    local ship   = safeDecode("T_ship")

    -- Screen dimensions
    local sw, sh = 1920, 1080
    local maxRows = 22  -- Max contact rows that fit on screen

    local svg = {}
    svg[#svg+1] = stringf([[<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">]], sw, sh)

    -- Background
    svg[#svg+1] = stringf([[<rect width="%d" height="%d" fill="%s"/>]], sw, sh, bgColor)

    -- ═══════════════════════════════════════
    -- TITLE BAR
    -- ═══════════════════════════════════════
    local isPvp = (ship and ship.pvp) or (radar and radar.pvp)
    local titleColor = isPvp and pvpColor or accentColor
    local zoneLabel = isPvp and "PVP ZONE" or "SAFE ZONE"
    local zoneColor = isPvp and pvpColor or safeColor

    svg[#svg+1] = stringf([[<rect x="0" y="0" width="%d" height="50" fill="%s"/>]], sw, rgba(20, 30, 40, 0.95))
    svg[#svg+1] = stringf([[<text x="20" y="34" fill="%s" font-size="22" font-family="monospace" font-weight="bold">ARCHHUD RADAR</text>]], titleColor)
    svg[#svg+1] = stringf([[<text x="%d" y="34" fill="%s" font-size="18" font-family="monospace" text-anchor="end">%s</text>]], sw - 20, zoneColor, zoneLabel)

    -- ═══════════════════════════════════════
    -- NO DATA FALLBACK
    -- ═══════════════════════════════════════
    if not radar then
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="28" font-family="monospace" text-anchor="middle">AWAITING DATA</text>]],
            sw/2, sh/2 - 30, warnColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">No radar telemetry received from databank</text>]],
            sw/2, sh/2 + 10, dimColor)
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" text-anchor="middle">Link this board to the same databank as your ArchHUD seat and ensure radar is equipped</text>]],
            sw/2, sh/2 + 40, dimColor)
        svg[#svg+1] = "</svg>"
        return tblConcat(svg)
    end

    -- ═══════════════════════════════════════
    -- STATUS BAR (below title)
    -- ═══════════════════════════════════════
    local statusY = 55
    svg[#svg+1] = stringf([[<rect x="0" y="%d" width="%d" height="55" fill="%s"/>]], statusY, sw, panelColor)

    -- Radar status
    local rState = radar.state or -4
    local stateLabel = radarStateLabels[rState] or "UNKNOWN"
    local stateColor = radarStateColors[rState] or dimColor

    svg[#svg+1] = stringf([[<text x="40" y="%d" fill="%s" font-size="14" font-family="monospace">RADAR STATUS</text>]], statusY + 24, dimColor)
    svg[#svg+1] = stringf([[<circle cx="200" cy="%d" r="6" fill="%s"/>]], statusY + 20, stateColor)
    svg[#svg+1] = stringf([[<text x="214" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>]], statusY + 25, stateColor, stateLabel)

    -- Contact count
    local contactCount = radar.count or 0
    local countColor = contactCount > 0 and accentColor or dimColor
    svg[#svg+1] = stringf([[<text x="500" y="%d" fill="%s" font-size="14" font-family="monospace">CONTACTS</text>]], statusY + 24, dimColor)
    svg[#svg+1] = stringf([[<text x="620" y="%d" fill="%s" font-size="22" font-family="monospace" font-weight="bold">%d</text>]], statusY + 26, countColor, contactCount)

    -- Threat summary (count of non-friendly dynamic contacts in PVP)
    if isPvp and radar.list then
        local threats = 0
        for _, c in ipairs(radar.list) do
            if not c.f and c.k == "Dynamic" then threats = threats + 1 end
        end
        if threats > 0 then
            svg[#svg+1] = stringf([[<text x="720" y="%d" fill="%s" font-size="14" font-family="monospace">THREATS</text>]], statusY + 24, dimColor)
            svg[#svg+1] = stringf([[<text x="830" y="%d" fill="%s" font-size="22" font-family="monospace" font-weight="bold">%d</text>]], statusY + 26, dangerColor, threats)
        end
    end

    -- ═══════════════════════════════════════
    -- CONTACT TABLE
    -- ═══════════════════════════════════════
    local tableY = 120
    local rowH = 36
    local headerY = tableY + 8

    -- Table panel background
    svg[#svg+1] = stringf([[<rect x="20" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>]],
        tableY, sw - 40, sh - tableY - 50, panelColor, borderColor)

    -- Column positions
    local colNum  = 50
    local colName = 110
    local colDist = 900
    local colSize = 1200
    local colType = 1350
    local colFriend = 1600

    -- Header row
    local hdrY = headerY + 22
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">#</text>]], colNum, hdrY, accentColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">NAME</text>]], colName, hdrY, accentColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">DISTANCE</text>]], colDist, hdrY, accentColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">SIZE</text>]], colSize, hdrY, accentColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">TYPE</text>]], colType, hdrY, accentColor)
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">STATUS</text>]], colFriend, hdrY, accentColor)

    -- Header separator line
    svg[#svg+1] = stringf([[<line x1="40" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
        hdrY + 8, sw - 40, hdrY + 8, borderColor)

    -- Sort contacts by distance (closest first)
    local contacts = radar.list or {}
    tblSort(contacts, function(a, b) return (a.d or 0) < (b.d or 0) end)

    -- Render contact rows
    local rowStartY = hdrY + 14
    local rendered = 0

    if #contacts == 0 and rState == 1 then
        -- Operational but no contacts
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="18" font-family="monospace" text-anchor="middle">NO CONTACTS DETECTED</text>]],
            sw/2, rowStartY + 60, dimColor)
    elseif rState ~= 1 then
        -- Radar not operational
        svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="18" font-family="monospace" text-anchor="middle">RADAR %s</text>]],
            sw/2, rowStartY + 60, stateColor, stateLabel)
    else
        for i, contact in ipairs(contacts) do
            if rendered >= maxRows then break end

            local ry = rowStartY + (rendered * rowH)
            local nameColor = contactColor(contact, isPvp)

            -- Alternating row background (subtle)
            if rendered % 2 == 0 then
                svg[#svg+1] = stringf([[<rect x="30" y="%d" width="%d" height="%d" fill="%s" rx="2"/>]],
                    ry - 2, sw - 60, rowH - 2, rgba(30, 40, 55, 0.4))
            end

            -- Row number
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">%d</text>]],
                colNum, ry + 20, dimColor, i)

            -- Contact name (truncate if too long)
            local name = escXml(contact.n or "Unknown")
            if #name > 50 then name = name:sub(1, 47) .. "..." end
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace">%s</text>]],
                colName, ry + 21, nameColor, name)

            -- Distance
            local distStr = fmtDist(contact.d or 0)
            local distColor = "white"
            if isPvp and not contact.f and contact.k == "Dynamic" then
                if contact.d < 2000 then distColor = dangerColor
                elseif contact.d < 10000 then distColor = warnColor end
            end
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace">%s</text>]],
                colDist, ry + 21, distColor, distStr)

            -- Size
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
                colSize, ry + 21, dimColor, contact.s or "?")

            -- Type (Dynamic/Static)
            local typeColor = contact.k == "Dynamic" and accentColor or staticColor
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
                colType, ry + 21, typeColor, contact.k or "?")

            -- Friendly status
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
                colFriend, ry + 21, friendlyColor(contact), friendlyLabel(contact))

            rendered = rendered + 1
        end

        -- Show overflow indicator
        if #contacts > maxRows then
            local overflowY = rowStartY + (maxRows * rowH) + 16
            svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" text-anchor="middle">... and %d more contact(s) beyond display limit</text>]],
                sw/2, overflowY, dimColor, #contacts - maxRows)
        end
    end

    -- ═══════════════════════════════════════
    -- BOTTOM BAR: Data freshness
    -- ═══════════════════════════════════════
    local bottomY = sh - 35
    svg[#svg+1] = stringf([[<line x1="20" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
        bottomY - 5, sw - 20, bottomY - 5, borderColor)

    if flight and flight.time then
        local age = system.getArkTime() - flight.time
        local freshColor = age < 4 and safeColor or (age < 10 and warnColor or dangerColor)
        local freshText = age < 4 and "LIVE" or stringf("%.0fs AGO", age)
        svg[#svg+1] = stringf([[<circle cx="40" cy="%d" r="5" fill="%s"/>]], bottomY + 8, freshColor)
        svg[#svg+1] = stringf([[<text x="52" y="%d" fill="%s" font-size="13" font-family="monospace">DATA: %s</text>]], bottomY + 12, freshColor, freshText)
    else
        svg[#svg+1] = stringf([[<circle cx="40" cy="%d" r="5" fill="%s"/>]], bottomY + 8, dimColor)
        svg[#svg+1] = stringf([[<text x="52" y="%d" fill="%s" font-size="13" font-family="monospace">DATA: NO TIMESTAMP</text>]], bottomY + 12, dimColor)
    end

    -- Version / label on bottom right
    svg[#svg+1] = stringf([[<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="end">ARCHHUD RADAR TACTICAL DISPLAY</text>]],
        sw - 30, bottomY + 12, rgba(130, 224, 255, 0.3))

    svg[#svg+1] = "</svg>"
    return tblConcat(svg)
end

--- Check radar data and write alert to databank if new threats detected
local function checkAlerts()
    local radar = safeDecode("T_radar")
    if not radar or not radar.list then return end

    local isPvp = radar.pvp
    local contacts = radar.list
    local alertMsg = nil
    local threatClose = 0

    -- Build current contact set and count close threats
    local currentIds = {}
    for _, c in ipairs(contacts) do
        local key = (c.n or "?") .. "_" .. (c.s or "?")
        currentIds[key] = true

        -- Count non-friendly dynamic contacts within 2km in PVP
        if isPvp and not c.f and c.k == "Dynamic" and c.d < 2000 then
            threatClose = threatClose + 1
        end
    end

    -- Alert: new hostile within 2km
    if threatClose > prevThreatClose and isPvp then
        local newThreats = threatClose - prevThreatClose
        alertMsg = stringf("THREAT: %d hostile(s) within 2 km!", newThreats)
    end

    -- Alert: new dynamic contact appeared (not seen last tick)
    if not alertMsg then
        for _, c in ipairs(contacts) do
            if c.k == "Dynamic" and not c.f then
                local key = (c.n or "?") .. "_" .. (c.s or "?")
                if not prevContactIds[key] then
                    local zoneTxt = isPvp and " in PVP zone" or ""
                    alertMsg = stringf("Radar: New contact '%s' at %s%s", c.n or "Unknown", fmtDist(c.d or 0), zoneTxt)
                    break
                end
            end
        end
    end

    prevContactIds = currentIds
    prevThreatClose = threatClose

    if alertMsg then
        db.setStringValue("A_radar", jencode({
            msg = alertMsg,
            t = system.getArkTime()
        }))
    end
end

-- ════════════════════════════════════════════
-- Timer callback (global so unit > onTimer can call it)
-- In unit > onTimer, paste:  onBoardTick(timerId)
-- ════════════════════════════════════════════
function onBoardTick(timerId)
    if timerId == "refresh" then
        if screen and db then
            checkAlerts()
            screen.setHTML(renderDashboard())
        end
    end
end

-- ════════════════════════════════════════════
-- Auto-initialization (runs on unit > onStart)
-- ════════════════════════════════════════════
if not db then
    system.print("ArchHUD Radar: No databank linked. Rename the databank slot to 'db' and restart.")
    return
end
if not screen then
    system.print("ArchHUD Radar: No screen linked. Rename the screen slot to 'screen' and restart.")
    return
end
unit.setTimer("refresh", 2)
system.print("ArchHUD Radar Tactical Display started.")
screen.setHTML(renderDashboard())

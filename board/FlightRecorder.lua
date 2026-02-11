-- ArchHUD Flight Recorder (Black Box) - Programming Board Script
-- Records flight telemetry snapshots from the shared databank and displays
-- historical data as scrolling line charts on a linked screen.
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
-- Slots (rename in the Lua editor slot list):
--   db     = databank (same one linked to your seat/ECU as dbHud)
--   screen = ScreenUnit
--
-- Databank keys:
--   T_flight   (read)  - Real-time telemetry published by ArchHUD
--   T_history  (write) - Rolling buffer of recorded snapshots

local db = db ---@type databank
local screen = screen ---@type ScreenUnit
local unit = unit ---@type ProgrammingBoard
local system = system

local jdecode = json.decode
local jencode = json.encode
local mfloor = math.floor
local stringf = string.format

-- ════════════════════════════════════════════
-- Constants
-- ════════════════════════════════════════════

local MAX_HISTORY = 180         -- Max snapshots (180 x 10s = 30 minutes)
local RECORD_INTERVAL = 10     -- Seconds between snapshots / timer ticks

-- Screen dimensions (DU HTML screen mode)
local SW, SH = 1920, 1080

-- ════════════════════════════════════════════
-- Theme Colors
-- ════════════════════════════════════════════

local function rgb(r, g, b) return stringf("rgb(%d,%d,%d)", r, g, b) end
local function rgba(r, g, b, a) return stringf("rgba(%d,%d,%d,%.2f)", r, g, b, a) end

local accentColor = rgb(130, 224, 255)    -- Accent / speed line
local dimColor    = rgb(90, 155, 180)     -- Dim labels
local greenColor  = rgb(60, 255, 120)     -- Altitude line / live indicator
local orangeColor = rgb(255, 165, 0)      -- V-speed line / stale warning
local dangerColor = rgb(255, 60, 60)      -- Recording dot / old data
local bgColor     = rgb(12, 16, 22)       -- Background
local panelColor  = rgba(20, 30, 40, 0.85)
local borderColor = rgba(130, 224, 255, 0.3)
local gridColor   = rgba(130, 224, 255, 0.12)

-- ════════════════════════════════════════════
-- State
-- ════════════════════════════════════════════

local history = {}   -- Rolling buffer: each entry is {t=time, s=speed_mps, a=alt_m, v=vspd_mps}

-- ════════════════════════════════════════════
-- Data Persistence
-- ════════════════════════════════════════════

--- Load existing history from the databank (persists across restarts)
local function loadHistory()
    if db.hasKey("T_history") then
        local ok, data = pcall(jdecode, db.getStringValue("T_history"))
        if ok and type(data) == "table" then
            history = data
            system.print(stringf("Flight Recorder: Loaded %d snapshots from databank.", #history))
        end
    end
end

--- Save the history buffer to the databank
local function saveHistory()
    db.setStringValue("T_history", jencode(history))
end

-- ════════════════════════════════════════════
-- Recording
-- ════════════════════════════════════════════

--- Read T_flight from the databank, append a snapshot if the data is new,
--- trim the buffer to MAX_HISTORY, and persist.
--- @return table|nil  The current flight data, or nil if unavailable
local function recordSnapshot()
    if not db.hasKey("T_flight") then return nil end

    local ok, flight = pcall(jdecode, db.getStringValue("T_flight"))
    if not ok or not flight or not flight.time then return nil end

    -- Only record if this is genuinely new data
    local n = #history
    if n > 0 and history[n].t >= flight.time then
        return flight   -- Same or older timestamp; skip recording
    end

    -- Append compact snapshot
    history[n + 1] = {
        t = flight.time,
        s = flight.spd,
        a = flight.alt,
        v = flight.vspd,
    }

    -- Trim oldest entries if over capacity
    while #history > MAX_HISTORY do
        table.remove(history, 1)
    end

    -- Persist to databank
    saveHistory()

    return flight
end

-- ════════════════════════════════════════════
-- Formatting Helpers
-- ════════════════════════════════════════════

--- Format speed value for Y-axis grid labels (km/h)
local function fmtSpeedLabel(kmh)
    if kmh > 10000 then
        return stringf("%.1fk", kmh / 1000)
    else
        return stringf("%.0f", kmh)
    end
end

--- Format speed for the current-value display
local function fmtSpeedCurrent(kmh)
    return stringf("%.0f km/h", kmh)
end

--- Format altitude for Y-axis grid labels
local function fmtAltLabel(meters)
    if meters > 100000 then
        return stringf("%.1f su", meters / 200000)
    elseif meters > 10000 then
        return stringf("%.1f km", meters / 1000)
    elseif meters > 1000 then
        return stringf("%.2f km", meters / 1000)
    else
        return stringf("%.0f m", meters)
    end
end

--- Format altitude for current-value display
local function fmtAltCurrent(meters)
    if meters > 100000 then
        return stringf("%.2f su", meters / 200000)
    elseif meters > 1000 then
        return stringf("%.1f km", meters / 1000)
    else
        return stringf("%.0f m", meters)
    end
end

--- Format vertical speed for Y-axis grid labels
local function fmtVspdLabel(mps)
    return stringf("%.1f", mps)
end

--- Format vertical speed for current-value display
local function fmtVspdCurrent(mps)
    local sign = mps >= 0 and "+" or ""
    return stringf("%s%.1f m/s", sign, mps)
end

-- ════════════════════════════════════════════
-- Chart Rendering
-- ════════════════════════════════════════════

--- Draw a single line chart within a panel region of the SVG.
---
--- @param svg       table    SVG string-builder table
--- @param panelY    number   Top Y coordinate of the chart panel
--- @param panelH    number   Height of the chart panel
--- @param times     table    Array of timestamp values (arkTime)
--- @param values    table    Array of data values for this metric
--- @param n         number   Number of data points
--- @param lineColor string   SVG color string for the data line
--- @param chartLabel string  Title text displayed in the panel header
--- @param fmtLabel  function Formatter for Y-axis grid labels
--- @param fmtCurrent function Formatter for the large current-value display
--- @param showZero  boolean  If true, ensure zero is in range and draw a dashed zero-line
local function drawChart(svg, panelY, panelH, times, values, n,
                         lineColor, chartLabel, fmtLabel, fmtCurrent, showZero)
    -- Panel geometry
    local panelX, panelW = 15, 1610
    local plotX   = 105             -- Left edge of plot area (room for Y-axis labels)
    local plotX2  = 1600            -- Right edge of plot area
    local plotW   = plotX2 - plotX  -- 1495
    local plotY   = panelY + 34    -- Top of plot area (below title)
    local plotH   = panelH - 44    -- Height of plot area
    local infoX   = 1660           -- X position for current-value readout

    -- Panel background
    svg[#svg+1] = stringf(
        '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>',
        panelX, panelY, panelW, panelH, panelColor, borderColor)

    -- Chart title
    svg[#svg+1] = stringf(
        '<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace" font-weight="bold">%s</text>',
        panelX + 15, panelY + 24, accentColor, chartLabel)

    -- Empty state
    if n == 0 then
        svg[#svg+1] = stringf(
            '<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">NO RECORDED DATA</text>',
            panelX + panelW / 2, panelY + panelH / 2, dimColor)
        return
    end

    -- ── Compute value range ──────────────────

    local vmin, vmax = values[1], values[1]
    for i = 2, n do
        if values[i] < vmin then vmin = values[i] end
        if values[i] > vmax then vmax = values[i] end
    end

    -- For charts with a zero-line, ensure zero is always visible
    if showZero then
        if vmin > 0 then vmin = 0 end
        if vmax < 0 then vmax = 0 end
    end

    -- Pad the range by 8% each side so lines don't sit on the edge
    local range = vmax - vmin
    if range < 0.1 then
        -- Flat data: expand symmetrically
        local center = (vmin + vmax) / 2
        vmin = center - 1
        vmax = center + 1
        range = 2
    else
        vmin = vmin - range * 0.08
        vmax = vmax + range * 0.08
        range = vmax - vmin
    end

    -- ── Horizontal grid lines (6 lines, 5 intervals) ──

    local numGrid = 5
    for i = 0, numGrid do
        local frac = i / numGrid
        local gy = plotY + plotH - frac * plotH
        local gv = vmin + frac * range

        -- Grid line
        svg[#svg+1] = stringf(
            '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="0.5"/>',
            plotX, gy, plotX2, gy, gridColor)

        -- Y-axis label
        svg[#svg+1] = stringf(
            '<text x="%d" y="%.1f" fill="%s" font-size="11" font-family="monospace" text-anchor="end">%s</text>',
            plotX - 8, gy + 4, dimColor, fmtLabel(gv))
    end

    -- ── Zero reference line (dashed) ──

    if showZero and vmin < 0 and vmax > 0 then
        local zeroY = plotY + plotH - ((0 - vmin) / range) * plotH
        svg[#svg+1] = stringf(
            '<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="1" stroke-dasharray="6,4"/>',
            plotX, zeroY, plotX2, zeroY, rgba(255, 255, 255, 0.3))
    end

    -- ── Data polyline ──

    local tStart = times[1]
    local tEnd   = times[n]
    local tRange = tEnd - tStart
    if tRange < 1 then tRange = 1 end

    local points = {}
    for i = 1, n do
        local xFrac = (times[i] - tStart) / tRange
        local yFrac = (values[i] - vmin) / range
        local px = plotX + xFrac * plotW
        local py = plotY + plotH - yFrac * plotH
        points[i] = stringf("%.1f,%.1f", px, py)
    end

    svg[#svg+1] = stringf(
        '<polyline points="%s" fill="none" stroke="%s" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
        table.concat(points, " "), lineColor)

    -- Endpoint dot at the most recent data point
    local endX = plotX + ((times[n] - tStart) / tRange) * plotW
    local endY = plotY + plotH - ((values[n] - vmin) / range) * plotH
    svg[#svg+1] = stringf(
        '<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>',
        endX, endY, lineColor)

    -- ── Current value readout (right side) ──

    svg[#svg+1] = stringf(
        '<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace">CURRENT</text>',
        infoX, panelY + 22, dimColor)
    svg[#svg+1] = stringf(
        '<text x="%d" y="%d" fill="%s" font-size="26" font-family="monospace" font-weight="bold">%s</text>',
        infoX, panelY + 52, lineColor, fmtCurrent(values[n]))

    -- Min / Max summary
    local actualMin, actualMax = values[1], values[1]
    for i = 2, n do
        if values[i] < actualMin then actualMin = values[i] end
        if values[i] > actualMax then actualMax = values[i] end
    end
    svg[#svg+1] = stringf(
        '<text x="%d" y="%d" fill="%s" font-size="11" font-family="monospace">MAX %s</text>',
        infoX, panelY + 74, dimColor, fmtLabel(actualMax))
    svg[#svg+1] = stringf(
        '<text x="%d" y="%d" fill="%s" font-size="11" font-family="monospace">MIN %s</text>',
        infoX, panelY + 90, dimColor, fmtLabel(actualMin))
end

-- ════════════════════════════════════════════
-- Main Render Function
-- ════════════════════════════════════════════

--- Build and return the full SVG string for the flight recorder display.
local function render()
    local n   = #history
    local now = system.getArkTime()

    local svg = {}
    svg[#svg+1] = stringf('<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">', SW, SH)

    -- Background
    svg[#svg+1] = stringf('<rect width="%d" height="%d" fill="%s"/>', SW, SH, bgColor)

    -- ── Title Bar ──

    svg[#svg+1] = stringf(
        '<rect x="0" y="0" width="%d" height="50" fill="%s"/>',
        SW, rgba(20, 30, 40, 0.95))
    svg[#svg+1] = stringf(
        '<text x="20" y="34" fill="%s" font-size="22" font-family="monospace" font-weight="bold">ARCHHUD FLIGHT RECORDER</text>',
        accentColor)

    -- ── Recording Status Indicator ──

    local hasData = n > 0
    local isRecording = hasData and (now - history[n].t) < 30

    if isRecording then
        svg[#svg+1] = stringf(
            '<circle cx="%d" cy="28" r="6" fill="%s"/>' ..
            '<text x="%d" y="34" fill="%s" font-size="16" font-family="monospace" font-weight="bold">REC</text>' ..
            '<text x="%d" y="34" fill="%s" font-size="14" font-family="monospace">%d samples</text>',
            SW - 260, dangerColor,
            SW - 248, dangerColor,
            SW - 200, dimColor, n)
    else
        svg[#svg+1] = stringf(
            '<circle cx="%d" cy="28" r="6" fill="%s"/>' ..
            '<text x="%d" y="34" fill="%s" font-size="16" font-family="monospace">NO DATA</text>',
            SW - 260, rgba(80, 80, 80, 0.8),
            SW - 248, dimColor)
    end

    -- ── Extract data arrays from history ──

    local times, speeds, alts, vspeeds = {}, {}, {}, {}
    for i = 1, n do
        local h = history[i]
        times[i]   = h.t
        speeds[i]  = h.s * 3.6     -- Convert m/s to km/h for display
        alts[i]    = h.a
        vspeeds[i] = h.v
    end

    -- ── Chart Layout ──
    -- Three stacked charts, each 290px tall, with the shared time axis below

    local chartH  = 290
    local chartY1 = 60    -- Speed chart (top)
    local chartY2 = 360   -- Altitude chart (middle)
    local chartY3 = 660   -- V-Speed chart (bottom)

    drawChart(svg, chartY1, chartH, times, speeds, n,
        accentColor, "SPEED (km/h)", fmtSpeedLabel, fmtSpeedCurrent, false)

    drawChart(svg, chartY2, chartH, times, alts, n,
        greenColor, "ALTITUDE", fmtAltLabel, fmtAltCurrent, false)

    drawChart(svg, chartY3, chartH, times, vspeeds, n,
        orangeColor, "VERTICAL SPEED (m/s)", fmtVspdLabel, fmtVspdCurrent, true)

    -- ── Shared X-Axis (Time) ──

    local axisY = 960
    local plotX, plotX2 = 105, 1600
    local plotW = plotX2 - plotX

    if n > 1 then
        local tStart = times[1]
        local tEnd   = times[n]
        local totalSec = tEnd - tStart

        -- Choose tick interval based on data span
        local tickInterval
        if totalSec > 1500 then     tickInterval = 300    -- 5-minute ticks
        elseif totalSec > 600 then  tickInterval = 120    -- 2-minute ticks
        elseif totalSec > 300 then  tickInterval = 60     -- 1-minute ticks
        else                        tickInterval = 30     -- 30-second ticks
        end

        -- Axis baseline
        svg[#svg+1] = stringf(
            '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',
            plotX, axisY, plotX2, axisY, borderColor)

        -- Tick marks and labels
        local maxTicks = mfloor(totalSec / tickInterval)
        for i = 0, maxTicks do
            local secAgo = i * tickInterval
            local t = tEnd - secAgo
            if t >= tStart then
                local x = plotX + ((t - tStart) / totalSec) * plotW

                -- Tick mark
                svg[#svg+1] = stringf(
                    '<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s" stroke-width="1"/>',
                    x, axisY, x, axisY + 8, dimColor)

                -- Time label
                local label
                if secAgo == 0 then
                    label = "now"
                elseif secAgo < 60 then
                    label = stringf("%ds", secAgo)
                else
                    label = stringf("%dm", mfloor(secAgo / 60))
                end
                svg[#svg+1] = stringf(
                    '<text x="%.1f" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="middle">%s</text>',
                    x, axisY + 22, dimColor, label)
            end
        end
    end

    -- ── Data Freshness Indicator (bottom-left) ──

    if n > 0 then
        local age = now - history[n].t
        local freshColor, freshText
        if age < 15 then
            freshColor = greenColor
            freshText = "LIVE"
        elseif age < 30 then
            freshColor = orangeColor
            freshText = stringf("%.0fs AGO", age)
        else
            freshColor = dangerColor
            freshText = stringf("%.0fs AGO", age)
        end

        svg[#svg+1] = stringf(
            '<circle cx="30" cy="%d" r="5" fill="%s"/>' ..
            '<text x="42" y="%d" fill="%s" font-size="13" font-family="monospace">DATA: %s</text>',
            SH - 20, freshColor, SH - 15, freshColor, freshText)

        -- Recording duration (bottom-right)
        local duration = now - history[1].t
        local durText
        if duration > 3600 then
            durText = stringf("%.1fh recorded", duration / 3600)
        elseif duration > 60 then
            durText = stringf("%dm recorded", mfloor(duration / 60))
        else
            durText = stringf("%ds recorded", mfloor(duration))
        end
        svg[#svg+1] = stringf(
            '<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" text-anchor="end">%s</text>',
            SW - 20, SH - 15, dimColor, durText)
    end

    svg[#svg+1] = "</svg>"
    return table.concat(svg)
end

-- ════════════════════════════════════════════
-- Combined Record + Render
-- ════════════════════════════════════════════

--- Called every timer tick: records a snapshot then re-renders the display.
function recordAndRender()
    recordSnapshot()
    screen.setHTML(render())
end

--- Check recorded history for anomalies and write alert if detected
local function checkAlerts()
    local n = #history
    if n < 4 then return end -- Need at least 4 snapshots (40s of data)

    local cur = history[n]
    local prev = history[n - 3] -- 30 seconds ago
    local alertMsg = nil

    -- Alert: rapid altitude loss (>1000m in 30s while not near ground)
    if prev.a and cur.a and prev.a > 500 then
        local altDrop = prev.a - cur.a
        if altDrop > 1000 then
            alertMsg = stringf("ALERT: Rapid altitude loss! -%dm in 30s", mfloor(altDrop))
        end
    end

    -- Alert: sudden speed loss (>50% drop in 30s, from >100 m/s)
    if prev.s and cur.s and prev.s > 100 then
        local spdDrop = prev.s - cur.s
        if spdDrop > prev.s * 0.5 then
            alertMsg = stringf("ALERT: Sudden deceleration! %.0f -> %.0f m/s", prev.s, cur.s)
        end
    end

    if alertMsg then
        db.setStringValue("A_recorder", jencode({
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
            recordAndRender()
            checkAlerts()
        end
    end
end

-- ════════════════════════════════════════════
-- Auto-initialization (runs on unit > onStart)
-- ════════════════════════════════════════════
if not db then
    system.print("ArchHUD Recorder: No databank linked. Rename the databank slot to 'db' and restart.")
    return
end
if not screen then
    system.print("ArchHUD Recorder: No screen linked. Rename the screen slot to 'screen' and restart.")
    return
end
loadHistory()
unit.setTimer("refresh", RECORD_INTERVAL)
system.print("ArchHUD Flight Recorder started.")
recordAndRender()

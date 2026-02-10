-- ArchHUD Damage Report Display - Programming Board Script
-- Reads damage telemetry (T_damage) from a shared databank and renders a full-screen
-- damage report on a linked screen using setHTML() with SVG.
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
-- The main ArchHUD publishes T_damage every 10 seconds while the pilot is seated.
-- This board refreshes every 5 seconds.
--
-- Slots (rename in the Lua editor slot list):
--   db     = databank (same one linked to your seat/ECU as dbHud)
--   screen = ScreenUnit
--
-- Databank keys used:
--   T_damage = {pct, dmg, off, tot, list=[{n, t, hp, mhp, off?}...]}
--   T_flight = {time, ...}  (used for data freshness indicator)

local db = db         ---@type databank
local screen = screen ---@type ScreenUnit
local unit = unit     ---@type ProgrammingBoard
local system = system

-- Cached standard library references
-- json fallback for emulators (du-lua.dev) where the library slot
-- doesn't inject the json global automatically.
if not json then
    json = {}
    -- Minimal JSON decoder
    function json.decode(s)
        if not s or s == "" then return nil end
        local i = 1
        local V
        local function w() while i <= #s and s:byte(i) <= 32 do i = i + 1 end end
        local function S()
            i = i + 1; local b = {}
            while true do
                local c = s:sub(i,i)
                if c == '"' then break
                elseif c == '\\' then i=i+1; c=s:sub(i,i); if c=='n' then b[#b+1]='\n' elseif c=='t' then b[#b+1]='\t' else b[#b+1]=c end
                else b[#b+1] = c end
                i = i + 1
            end
            i = i + 1; return table.concat(b)
        end
        V = function()
            w(); local c = s:sub(i,i)
            if c == '"' then return S()
            elseif c == '{' then
                i=i+1; w(); local t = {}
                if s:sub(i,i) ~= '}' then
                    local k = S(); w(); i=i+1; t[k] = V()
                    while true do w(); if s:sub(i,i) ~= ',' then break end; i=i+1; k=S(); w(); i=i+1; t[k]=V() end
                end; w(); i=i+1; return t
            elseif c == '[' then
                i=i+1; w(); local t = {}
                if s:sub(i,i) ~= ']' then
                    t[1]=V(); local n=1
                    while true do w(); if s:sub(i,i) ~= ',' then break end; i=i+1; n=n+1; t[n]=V() end
                end; w(); i=i+1; return t
            elseif c == 't' then i=i+4; return true
            elseif c == 'f' then i=i+5; return false
            elseif c == 'n' then i=i+4; return nil
            else local j2=i; if c=='-' then i=i+1 end; while i<=#s and s:sub(i,i):match('[%deE%.%+%-]') do i=i+1 end; return tonumber(s:sub(j2,i-1))
            end
        end
        local ok, r = pcall(V); return ok and r or nil
    end
    -- Minimal JSON encoder
    function json.encode(val)
        local buf = {}
        local function enc(v)
            local tp = type(v)
            if v == nil then buf[#buf+1] = "null"
            elseif tp == "boolean" then buf[#buf+1] = v and "true" or "false"
            elseif tp == "number" then
                if v ~= v then buf[#buf+1] = "null"
                elseif v == 1/0 then buf[#buf+1] = "1e999"
                elseif v == -1/0 then buf[#buf+1] = "-1e999"
                else buf[#buf+1] = string.format("%.14g", v) end
            elseif tp == "string" then
                buf[#buf+1] = '"'; buf[#buf+1] = v:gsub('[\\"\n\t\r]', {['\\']='\\\\',  ['"']='\\"', ['\n']='\\n', ['\t']='\\t', ['\r']='\\r'}); buf[#buf+1] = '"'
            elseif tp == "table" then
                -- Detect array vs object: sequential integer keys from 1..#v
                local n = #v
                local isArr = n > 0
                if isArr then for k in pairs(v) do if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then isArr = false; break end end end
                if isArr then
                    buf[#buf+1] = '['
                    for i = 1, n do if i > 1 then buf[#buf+1] = ',' end; enc(v[i]) end
                    buf[#buf+1] = ']'
                else
                    buf[#buf+1] = '{'
                    local first = true
                    for k2, v2 in pairs(v) do
                        if type(k2) == "string" then
                            if not first then buf[#buf+1] = ',' end; first = false
                            enc(k2); buf[#buf+1] = ':'; enc(v2)
                        end
                    end
                    buf[#buf+1] = '}'
                end
            end
        end
        enc(val)
        return table.concat(buf)
    end
end
local jdecode = json.decode
local jencode = json.encode
local mfloor  = math.floor
local mmin    = math.min
local mmax    = math.max
local mceil   = math.ceil
local stringf = string.format

-- Pagination state: auto-advances each render cycle
local currentPage = 0

-- Alert state: track previous integrity to detect drops
local prevIntegrity = 100
local prevDisabled = 0

-- ═══════════════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════════════

--- Safe JSON decode from a databank key. Returns decoded table or nil.
local function safeDecode(key)
    if not db.hasKey(key) then return nil end
    local ok, result = pcall(jdecode, db.getStringValue(key))
    if ok then return result end
    return nil
end

--- Escape special XML/SVG characters in a string
local function esc(str)
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

--- Color helper: build rgb() string
local function rgb(r, g, b)
    return stringf("rgb(%d,%d,%d)", r, g, b)
end

--- Color helper: build rgba() string
local function rgba(r, g, b, a)
    return stringf("rgba(%d,%d,%d,%.2f)", r, g, b, a)
end

-- ═══════════════════════════════════════════════
-- Theme Colors
-- ═══════════════════════════════════════════════

local accentColor = rgb(130, 224, 255)            -- Cyan accent
local dimColor    = rgb(90, 155, 180)             -- Muted label text
local warnColor   = rgb(255, 165, 0)              -- Orange warning
local dangerColor = rgb(255, 60, 60)              -- Red danger/destroyed
local safeColor   = rgb(60, 255, 120)             -- Green safe/operational
local bgColor     = rgb(12, 16, 22)               -- Dark background
local panelColor  = rgba(20, 30, 40, 0.85)        -- Panel fill
local borderColor = rgba(130, 224, 255, 0.3)      -- Panel border

-- ═══════════════════════════════════════════════
-- Color Computation
-- ═══════════════════════════════════════════════

--- Compute integrity percentage color with smooth gradient:
---   100% = green rgb(60, 255, 120)
---    50% = yellow rgb(255, 255, 0)
---     0% = red rgb(255, 60, 60)
local function integrityColor(pct)
    pct = mmax(0, mmin(100, pct))
    if pct >= 50 then
        -- Interpolate: yellow(50%) -> green(100%)
        local t = (pct - 50) / 50
        local r = mfloor(255 - 195 * t)    -- 255 -> 60
        local g = 255                       -- 255 -> 255
        local b = mfloor(120 * t)           -- 0   -> 120
        return rgb(r, g, b)
    else
        -- Interpolate: red(0%) -> yellow(50%)
        local t = pct / 50
        local r = 255                       -- 255 -> 255
        local g = mfloor(60 + 195 * t)     -- 60  -> 255
        local b = mfloor(60 - 60 * t)      -- 60  -> 0
        return rgb(r, g, b)
    end
end

--- Compute element row color based on HP percentage.
--- Damaged elements use yellow (high HP) to orange (low HP).
local function elementColor(pct)
    if pct >= 50 then
        return rgb(255, 200, 50)    -- Yellow for higher HP remaining
    else
        return rgb(255, 130, 30)    -- Orange for lower HP remaining
    end
end

-- ═══════════════════════════════════════════════
-- Main Render Function
-- ═══════════════════════════════════════════════

--- Build and return the complete SVG damage report as an HTML string.
function renderDashboard()
    local damage = safeDecode("T_damage")
    local flight = safeDecode("T_flight")

    -- Screen dimensions (DU screen HTML/SVG viewport)
    local sw, sh = 1920, 1080

    local svg = {}

    -- SVG root element
    svg[#svg+1] = stringf([[<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">]], sw, sh)

    -- Background
    svg[#svg+1] = stringf([[<rect width="%d" height="%d" fill="%s"/>]], sw, sh, bgColor)

    -- ── Title Bar ──────────────────────────────
    svg[#svg+1] = stringf(
        [[<rect x="0" y="0" width="%d" height="50" fill="%s"/>]] ..
        [[<text x="20" y="34" fill="%s" font-size="22" font-family="monospace" font-weight="bold">ARCHHUD DAMAGE REPORT</text>]],
        sw, rgba(20, 30, 40, 0.95), accentColor)

    -- ── Data Freshness Indicator (top right) ───
    if flight and flight.time then
        local age = system.getArkTime() - flight.time
        -- Damage updates every 10s, so 15s threshold for "live"
        local freshColor = age < 15 and safeColor or (age < 30 and warnColor or dangerColor)
        local freshText = age < 15 and "LIVE" or stringf("%.0fs AGO", age)
        svg[#svg+1] = stringf(
            [[<circle cx="%d" cy="25" r="5" fill="%s"/>]] ..
            [[<text x="%d" y="30" fill="%s" font-size="14" font-family="monospace" text-anchor="end">DATA: %s</text>]],
            sw - 200, freshColor, sw - 20, freshColor, freshText)
    end

    -- ── No Data Fallback ───────────────────────
    if not damage then
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="28" font-family="monospace" text-anchor="middle" font-weight="bold">AWAITING DATA</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Link this board databank to the same databank as your ArchHUD seat</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" text-anchor="middle">Damage telemetry is published every 10 seconds while seated</text>]],
            sw/2, sh/2 - 30, warnColor,
            sw/2, sh/2 + 10, dimColor,
            sw/2, sh/2 + 40, dimColor)
        svg[#svg+1] = "</svg>"
        return table.concat(svg)
    end

    -- ═══════════════════════════════════════
    -- Integrity Section
    -- ═══════════════════════════════════════

    local pct = damage.pct or 0
    local iColor = integrityColor(pct)

    -- Large percentage display (centered)
    svg[#svg+1] = stringf(
        [[<text x="%d" y="150" fill="%s" font-size="80" font-family="monospace" font-weight="bold" text-anchor="middle">%.1f%%</text>]] ..
        [[<text x="%d" y="178" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">SHIP INTEGRITY</text>]],
        sw/2, iColor, pct,
        sw/2, dimColor)

    -- Wide integrity bar (nearly full screen width)
    local barX = 40
    local barY = 198
    local barW = sw - 80
    local barH = 24
    local barFill = mmax(0, mfloor(barW * pct / 100))

    -- Bar background track
    svg[#svg+1] = stringf(
        [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>]],
        barX, barY, barW, barH, rgba(40, 50, 60, 0.8))

    -- Bar fill (colored by integrity)
    if barFill > 0 then
        svg[#svg+1] = stringf(
            [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>]],
            barX, barY, barFill, barH, iColor)
    end

    -- Bar border outline
    svg[#svg+1] = stringf(
        [[<rect x="%d" y="%d" width="%d" height="%d" fill="none" stroke="%s" stroke-width="1" rx="4"/>]],
        barX, barY, barW, barH, borderColor)

    -- Summary line: "X damaged | Y disabled | Z total elements"
    local dmgCount = damage.dmg or 0
    local offCount = damage.off or 0
    local totCount = damage.tot or 0
    svg[#svg+1] = stringf(
        [[<text x="%d" y="252" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">]] ..
        [[%d damaged  |  %d disabled  |  %d total elements</text>]],
        sw/2, dimColor, dmgCount, offCount, totCount)

    -- ═══════════════════════════════════════
    -- Element List Panel
    -- ═══════════════════════════════════════

    local listTop = 275
    local listBot = sh - 40
    local listX   = 40
    local listW   = sw - 80

    -- Panel background with border
    svg[#svg+1] = stringf(
        [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>]],
        listX - 10, listTop - 10, listW + 20, listBot - listTop + 20, panelColor, borderColor)

    local list = damage.list

    if not list or #list == 0 then
        -- ── All Systems Operational ────────────
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="30" font-family="monospace" text-anchor="middle" font-weight="bold">]] ..
            [[ALL SYSTEMS OPERATIONAL</text>]],
            sw/2, (listTop + listBot) / 2, safeColor)
    else
        -- ── Column Headers ─────────────────────
        local hdrY = listTop + 10
        svg[#svg+1] = stringf(
            [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">ELEMENT NAME</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">TYPE</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">HEALTH</text>]] ..
            [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">HP</text>]],
            listX, hdrY, dimColor,
            listX + 520, hdrY, dimColor,
            listX + 1050, hdrY, dimColor,
            listX + 1560, hdrY, dimColor)

        -- Header separator line
        svg[#svg+1] = stringf(
            [[<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>]],
            listX, hdrY + 10, listX + listW, hdrY + 10, borderColor)

        -- ── Pagination Calculation ─────────────
        local totalItems = #list
        local rowH = 50                              -- Height per element row
        local contentTop = hdrY + 20                 -- First row content area starts here
        local availH = listBot - contentTop - 10
        local itemsPerPage = mmax(1, mfloor(availH / rowH))  -- Approximately 14 items
        local totalPages = mmax(1, mceil(totalItems / itemsPerPage))
        local page = currentPage % totalPages
        local startIdx = page * itemsPerPage + 1
        local endIdx = mmin(startIdx + itemsPerPage - 1, totalItems)

        -- ── Render Element Rows ────────────────
        local ey = contentTop + 20
        for i = startIdx, endIdx do
            local elem = list[i]
            if elem then
                local eName  = elem.n or "Unknown"
                local eType  = elem.t or ""
                local eHP    = elem.hp or 0
                local eMaxHP = elem.mhp or 1
                local eOff   = elem.off
                local ePct   = eMaxHP > 0 and (eHP / eMaxHP * 100) or 0

                -- Truncate long names to fit columns
                if #eName > 34 then eName = eName:sub(1, 32) .. ".." end
                if #eType > 28 then eType = eType:sub(1, 26) .. ".." end

                -- Escape for SVG/XML safety
                eName = esc(eName)
                eType = esc(eType)

                -- Determine if element is destroyed/disabled
                local isDestroyed = eHP <= 0 or eOff
                local rowColor = isDestroyed and dangerColor or elementColor(ePct)

                -- Element name (colored by status)
                svg[#svg+1] = stringf(
                    [[<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>]],
                    listX, ey, rowColor, eName)

                -- Element type (dimmed)
                svg[#svg+1] = stringf(
                    [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">%s</text>]],
                    listX + 520, ey, dimColor, eType)

                -- HP bar background track
                local hpBarX = listX + 1050
                local hpBarW = 460
                local hpBarH = 14
                svg[#svg+1] = stringf(
                    [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="2"/>]],
                    hpBarX, ey - 11, hpBarW, hpBarH, rgba(40, 50, 60, 0.8))

                -- HP bar fill (colored by status)
                local hpFill = mmax(0, mfloor(hpBarW * ePct / 100))
                if hpFill > 0 then
                    svg[#svg+1] = stringf(
                        [[<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="2"/>]],
                        hpBarX, ey - 11, hpFill, hpBarH, rowColor)
                end

                -- HP text or DESTROYED label
                if isDestroyed then
                    svg[#svg+1] = stringf(
                        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">DESTROYED</text>]],
                        listX + 1560, ey, dangerColor)
                else
                    svg[#svg+1] = stringf(
                        [[<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">%d / %d</text>]],
                        listX + 1560, ey, dimColor, eHP, eMaxHP)
                end

                ey = ey + rowH
            end
        end

        -- Page indicator (shown only when there are multiple pages)
        if totalPages > 1 then
            svg[#svg+1] = stringf(
                [[<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" text-anchor="end">PAGE %d / %d</text>]],
                listX + listW, listBot + 5, dimColor, page + 1, totalPages)
        end

        -- Auto-advance page for next render cycle (cycles every 5 seconds)
        currentPage = currentPage + 1
    end

    -- ── Footer ─────────────────────────────────
    svg[#svg+1] = stringf(
        [[<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="end">Refreshes every 5s  |  Damage data updates every 10s</text>]],
        sw - 20, sh - 10, rgba(90, 155, 180, 0.5))

    svg[#svg+1] = "</svg>"
    return table.concat(svg)
end

--- Check damage data and write alert to databank if thresholds crossed
local function checkAlerts()
    local damage = safeDecode("T_damage")
    if not damage then return end

    local pct = damage.pct or 100
    local off = damage.off or 0
    local alertMsg = nil

    -- Alert on integrity threshold crossings (75%, 50%, 25%)
    if pct < 25 and prevIntegrity >= 25 then
        alertMsg = stringf("CRITICAL: Hull integrity %.0f%% - %d disabled", pct, off)
    elseif pct < 50 and prevIntegrity >= 50 then
        alertMsg = stringf("WARNING: Hull integrity %.0f%% - %d elements damaged", pct, damage.dmg or 0)
    elseif pct < 75 and prevIntegrity >= 75 then
        alertMsg = stringf("Hull integrity %.0f%% - taking damage", pct)
    end

    -- Alert on new element destruction
    if off > prevDisabled then
        local newOff = off - prevDisabled
        alertMsg = stringf("ALERT: %d element(s) destroyed! %d total disabled", newOff, off)
    end

    prevIntegrity = pct
    prevDisabled = off

    if alertMsg then
        db.setStringValue("A_damage", jencode({
            msg = alertMsg,
            t = system.getArkTime()
        }))
    end
end

-- ═══════════════════════════════════════════════
-- Timer callback (global so unit > onTimer can call it)
-- In unit > onTimer, paste:  onBoardTick(timerId)
-- ═══════════════════════════════════════════════
function onBoardTick(timerId)
    if timerId == "refresh" then
        if screen and db then
            checkAlerts()
            screen.setHTML(renderDashboard())
        end
    end
end

-- ═══════════════════════════════════════════════
-- Auto-initialization (runs on unit > onStart)
-- ═══════════════════════════════════════════════
if not db then
    system.print("ArchHUD Damage: No databank linked. Rename the databank slot to 'db' and restart.")
    return
end
if not screen then
    system.print("ArchHUD Damage: No screen linked. Rename the screen slot to 'screen' and restart.")
    return
end
unit.setTimer("refresh", 5)
system.print("ArchHUD Damage Report started.")
screen.setHTML(renderDashboard())

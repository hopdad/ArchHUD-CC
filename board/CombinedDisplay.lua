-- ArchHUD Combined Display - Programming Board Script
-- All-in-one display: Telemetry, Radar, Damage, Flight Recorder, Route Planner.
-- Click left/right side of screen to navigate between pages.
-- Supports 1 or 2 screens, each independently navigable.
--
-- ═══════════════════════════════════════════════════════
-- SETUP INSTRUCTIONS
-- ═══════════════════════════════════════════════════════
-- 1. Place a programming board, 1-2 screens, and link ALL to the same
--    databank used by your ArchHUD seat (the dbHud slot).
-- 2. Right-click the programming board > Advanced > Edit Lua.
-- 3. Rename slots: databank="db", first screen="screen", second screen="screen2"
-- 4. Filter: unit > onStart           → paste this ENTIRE script
-- 5. Filter: unit > onTimer(timerId)  → onBoardTick(timerId)
-- 6. Filter: unit > onStop            → onBoardStop()
-- 7. Filter: screen > onMouseDown(x,y) → onScreenNav(1,x)
-- 8. (If 2 screens) Filter: screen2 > onMouseDown(x,y) → onScreenNav(2,x)
-- 9. Apply and activate.
-- ═══════════════════════════════════════════════════════

local db = db           ---@type databank
local screen = screen   ---@type ScreenUnit
local screen2 = screen2 ---@type ScreenUnit
local unit = unit       ---@type ProgrammingBoard
local system = system

-- ═══════════════════════════════════════════
-- Configuration
-- ═══════════════════════════════════════════
local TICK_INTERVAL = 2
local RECORDER_TICKS = 5        -- Record snapshot every 5 ticks (10s)

-- ═══════════════════════════════════════════
-- Standard Library Cache
-- ═══════════════════════════════════════════
local jdecode = json.decode
local jencode = json.encode
local mfloor = math.floor
local mceil = math.ceil
local mmin = math.min
local mmax = math.max
local stringf = string.format
local tblSort = table.sort
local tblConcat = table.concat

-- ═══════════════════════════════════════════
-- State
-- ═══════════════════════════════════════════
local pageCount = 5
local screen1Page = 1
local screen2Page = 2
local recorderTicks = 0

-- ═══════════════════════════════════════════
-- Shared Utilities
-- ═══════════════════════════════════════════
local function safeDecode(key)
    if not db.hasKey(key) then return nil end
    local ok, r = pcall(jdecode, db.getStringValue(key))
    if ok then return r end
    return nil
end

local function esc(s)
    if not s then return "?" end
    return s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;")
end

local function rgb(r,g,b) return stringf("rgb(%d,%d,%d)",r,g,b) end
local function rgba(r,g,b,a) return stringf("rgba(%d,%d,%d,%.2f)",r,g,b,a) end

-- ═══════════════════════════════════════════
-- Theme
-- ═══════════════════════════════════════════
local accentColor = rgb(130,224,255)
local dimColor    = rgb(90,155,180)
local warnColor   = rgb(255,165,0)
local dangerColor = rgb(255,60,60)
local safeColor   = rgb(60,255,120)
local pvpColor    = rgb(255,60,60)
local bgColor     = rgb(12,16,22)
local panelColor  = rgba(20,30,40,0.85)
local borderColor = rgba(130,224,255,0.3)
local gridColor   = rgba(130,224,255,0.12)
local staticColor = rgb(100,110,125)
local amberColor  = rgb(255,190,50)

-- ═══════════════════════════════════════════
-- Shared Formatting
-- ═══════════════════════════════════════════
local function fmtDist(m)
    if not m or m == 0 then return "---" end
    if m > 200000 then return stringf("%.2f su",m/200000)
    elseif m > 10000 then return stringf("%.1f km",m/1000)
    elseif m > 1000 then return stringf("%.2f km",m/1000)
    else return stringf("%.0f m",m) end
end
local function fmtTime(s)
    if not s or s <= 0 then return "---" end
    local d=mfloor(s/86400) local h=mfloor((s%86400)/3600) local m=mfloor((s%3600)/60) local sec=mfloor(s%60)
    if d>365 then return ">1y" elseif d>0 then return stringf("%dd %dh",d,h)
    elseif h>0 then return stringf("%dh %dm",h,m) elseif m>0 then return stringf("%dm %ds",m,sec)
    else return stringf("%ds",sec) end
end
local function fmtSpeed(mps) return stringf("%.0f km/h",(mps or 0)*3.6) end
local function fmtSpeedKmh(mps) return stringf("%.0f km/h",(mps or 0)*3.6) end
local function fmtSpeedMs(mps)
    if (mps or 0)>1000 then return stringf("%.1f km/s",mps/1000) else return stringf("%.0f m/s",mps or 0) end
end
local function fmtAlt(m)
    if (m or 0)>100000 then return stringf("%.2f su",m/200000) elseif m>1000 then return stringf("%.1f km",m/1000)
    else return stringf("%.0f m",m or 0) end
end

-- ═══════════════════════════════════════════
-- Shared SVG Builders
-- ═══════════════════════════════════════════
local SW, SH = 1920, 1080
local pageNames = {"TELEMETRY","RADAR","DAMAGE","FLIGHT RECORDER","ROUTE PLANNER"}

local function svgOpen(svg)
    svg[#svg+1] = stringf('<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">',SW,SH)
    svg[#svg+1] = stringf('<rect width="%d" height="%d" fill="%s"/>',SW,SH,bgColor)
end

local function svgTitle(svg, title, rightText, rightClr)
    svg[#svg+1] = stringf('<rect x="0" y="0" width="%d" height="50" fill="%s"/>',SW,rgba(20,30,40,0.95))
    svg[#svg+1] = stringf('<text x="20" y="34" fill="%s" font-size="22" font-family="monospace" font-weight="bold">%s</text>',accentColor,title)
    if rightText then
        svg[#svg+1] = stringf('<text x="%d" y="34" fill="%s" font-size="18" font-family="monospace" text-anchor="end">%s</text>',SW-20,rightClr or dimColor,rightText)
    end
end

local function svgFresh(svg, flight, cx, cy)
    if flight and flight.time then
        local age = system.getArkTime() - flight.time
        local fc = age<5 and safeColor or (age<15 and warnColor or dangerColor)
        local ft = age<5 and "LIVE" or stringf("%.0fs AGO",age)
        svg[#svg+1] = stringf('<circle cx="%d" cy="%d" r="5" fill="%s"/>',cx,cy,fc)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">DATA: %s</text>',cx+12,cy+4,fc,ft)
    end
end

local function svgPageNav(svg, pageIdx)
    local ny = SH - 14
    -- Left arrow
    svg[#svg+1] = stringf('<text x="30" y="%d" fill="%s" font-size="18" font-family="monospace" opacity="0.4">◄</text>',ny,accentColor)
    -- Page name
    svg[#svg+1] = stringf('<text x="960" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="middle">%s  %d/%d</text>',ny,dimColor,pageNames[pageIdx] or "?",pageIdx,pageCount)
    -- Right arrow
    svg[#svg+1] = stringf('<text x="1890" y="%d" fill="%s" font-size="18" font-family="monospace" text-anchor="end" opacity="0.4">►</text>',ny,accentColor)
    -- Page dots
    local dotX = 960 - (pageCount*8)
    for i=1,pageCount do
        local dc = (i==pageIdx) and accentColor or rgba(60,70,80,0.6)
        svg[#svg+1] = stringf('<circle cx="%d" cy="%d" r="3" fill="%s"/>',dotX+i*16,ny+10,dc)
    end
end

local function svgClose(svg, pageIdx)
    svgPageNav(svg, pageIdx)
    svg[#svg+1] = '</svg>'
    return tblConcat(svg)
end

local function svgNoData(svg, msg, pageIdx)
    svg[#svg+1] = stringf('<text x="960" y="500" fill="%s" font-size="28" font-family="monospace" text-anchor="middle">AWAITING DATA</text>',warnColor)
    svg[#svg+1] = stringf('<text x="960" y="540" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">%s</text>',dimColor,msg)
    return svgClose(svg, pageIdx)
end

-- ═══════════════════════════════════════════
-- PAGE 1: TELEMETRY
-- ═══════════════════════════════════════════
local function fuelBar(x,y,w,h,pct,label)
    if not pct then return "" end
    local fill = mfloor(w*pct/100)
    local bc = accentColor
    if pct<10 then bc=dangerColor elseif pct<25 then bc=warnColor end
    return stringf(
        '<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">%s</text>'..
        '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="3"/>'..
        '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="3"/>'..
        '<text x="%d" y="%d" fill="white" font-size="12" font-family="monospace" text-anchor="end">%d%%</text>',
        x,y-4,dimColor,label, x,y,w,h,rgba(40,50,60,0.8), x,y,fill,h,bc, x+w+40,y+h-3,pct)
end

local function statusDot(x,y,active,label)
    local c = active and safeColor or rgba(60,70,80,0.8)
    return stringf('<circle cx="%d" cy="%d" r="5" fill="%s"/><text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">%s</text>',
        x,y,c, x+12,y+4, active and accentColor or dimColor, label)
end

local function renderTelemetry(pageIdx)
    local flight = safeDecode("T_flight")
    local ap = safeDecode("T_ap")
    local ship = safeDecode("T_ship")
    local fuel = safeDecode("T_fuel")
    local svg = {}
    svgOpen(svg)
    local isPvp = ship and ship.pvp
    local zl = isPvp and "PVP ZONE" or "SAFE ZONE"
    local zc = isPvp and pvpColor or safeColor
    svgTitle(svg,"ARCHHUD TELEMETRY",zl,zc)
    if ship and ship.ver then
        svg[#svg+1] = stringf('<text x="380" y="34" fill="%s" font-size="14" font-family="monospace">v%s</text>',dimColor,ship.ver)
    end
    if not flight then return svgNoData(svg,"Link databank to same databank as ArchHUD seat",pageIdx) end

    local lx,ly = 30,70
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="580" height="320" fill="%s" stroke="%s" rx="6"/>',lx-10,ly,panelColor,borderColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">FLIGHT DATA</text>',lx+10,ly+28,accentColor)
    local fy,lH = ly+55, 38
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">SPEED</text>',lx+10,fy,dimColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="28" font-family="monospace">%s</text>',lx+120,fy+2,fmtSpeedKmh(flight.spd))
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">(%s)</text>',lx+380,fy,dimColor,fmtSpeedMs(flight.spd))
    fy=fy+lH+6
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">ALTITUDE</text>',lx+10,fy,dimColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="28" font-family="monospace">%s</text>',lx+120,fy+2,fmtAlt(flight.alt))
    fy=fy+lH+6
    local vColor = "white"
    if flight.vspd>10 then vColor=safeColor elseif flight.vspd<-10 then vColor=warnColor end
    local vSign = flight.vspd>=0 and "+" or ""
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">V-SPEED</text>',lx+10,fy,dimColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="28" font-family="monospace">%s%.1f m/s</text>',lx+120,fy+2,vColor,vSign,flight.vspd)
    fy=fy+lH+6
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">ATMO</text>',lx+10,fy,dimColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="22" font-family="monospace">%.1f%%</text>',lx+120,fy+2,flight.atmo)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">THROTTLE</text>',lx+280,fy,dimColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="22" font-family="monospace">%d%%</text>',lx+400,fy+2,flight.thr)
    fy=fy+lH
    svg[#svg+1] = statusDot(lx+10,fy+8,flight.inA,"IN ATMO")
    svg[#svg+1] = statusDot(lx+140,fy+8,flight.gear,"GEAR")
    svg[#svg+1] = statusDot(lx+240,fy+8,flight.brk,"BRAKE")
    svg[#svg+1] = statusDot(lx+350,fy+8,flight.near,"NEAR PLANET")

    -- Autopilot panel
    local rx = 640
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="580" height="320" fill="%s" stroke="%s" rx="6"/>',rx-10,ly,panelColor,borderColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">AUTOPILOT</text>',rx+10,ly+28,accentColor)
    if ap then
        local ay = ly+60
        local asc = ap.on and safeColor or dimColor
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">STATUS</text>',rx+10,ay,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="24" font-family="monospace" font-weight="bold">%s</text>',rx+120,ay+2,asc,ap.on and "ENGAGED" or "OFF")
        ay=ay+lH
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">PHASE</text>',rx+10,ay,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>',rx+120,ay+2,ap.stat or "---")
        ay=ay+lH
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">TARGET</text>',rx+10,ay,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>',rx+120,ay+2,ap.tgt or "None")
        ay=ay+lH
        if ap.dist and ap.dist>0 then
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">DISTANCE</text>',rx+10,ay,dimColor)
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>',rx+120,ay+2,fmtDist(ap.dist))
        end
        ay=ay+lH
        if ap.bDist and ap.bDist>0 then
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">BRAKE DIST</text>',rx+10,ay,dimColor)
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="20" font-family="monospace">%s</text>',rx+120,ay+2,warnColor,fmtDist(ap.bDist))
        end
        ay=ay+lH+10
        svg[#svg+1] = statusDot(rx+10,ay,ap.ah,"ALT HOLD")
        svg[#svg+1] = statusDot(rx+150,ay,ap.tb,"TURN+BURN")
        svg[#svg+1] = statusDot(rx+300,ay,ap.orb,"ORBIT")
        svg[#svg+1] = statusDot(rx+420,ay,ap.re,"REENTRY")
    end

    -- Fuel panel
    local by = 420
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="580" height="220" fill="%s" stroke="%s" rx="6"/>',lx-10,by,panelColor,borderColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">FUEL</text>',lx+10,by+28,accentColor)
    if fuel then
        local barY,barW,barH,barS = by+50, 420, 18, 55
        if fuel.atmo then svg[#svg+1] = fuelBar(lx+10,barY,barW,barH,fuel.atmo.pct,stringf("ATMO  [%d]",fuel.atmo.count)); barY=barY+barS end
        if fuel.space then svg[#svg+1] = fuelBar(lx+10,barY,barW,barH,fuel.space.pct,stringf("SPACE [%d]",fuel.space.count)); barY=barY+barS end
        if fuel.rocket then svg[#svg+1] = fuelBar(lx+10,barY,barW,barH,fuel.rocket.pct,stringf("RCKT  [%d]",fuel.rocket.count)) end
    else
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">No fuel data</text>',lx+10,by+60,dimColor)
    end

    -- Ship status panel
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="580" height="220" fill="%s" stroke="%s" rx="6"/>',rx-10,by,panelColor,borderColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">SHIP STATUS</text>',rx+10,by+28,accentColor)
    local sy = by+60
    if ship and ship.shld >= 0 then
        local sc = accentColor
        if ship.shld<25 then sc=dangerColor elseif ship.shld<50 then sc=warnColor end
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">SHIELD</text>',rx+10,sy,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="24" font-family="monospace">%d%%</text>',rx+120,sy+2,sc,ship.shld)
    else
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">SHIELD</text><text x="%d" y="%d" fill="%s" font-size="20" font-family="monospace">N/A</text>',rx+10,sy,dimColor,rx+120,sy+2,dimColor)
    end
    if flight then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">MASS</text>',rx+280,sy,dimColor)
        local ms = flight.mass>1000 and stringf("%.1f t",flight.mass/1000) or stringf("%d kg",flight.mass)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>',rx+380,sy+2,ms)
    end
    sy=sy+50
    svg[#svg+1] = stringf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',rx,sy-15,rx+560,sy-15,borderColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace" font-weight="bold">ODOMETER</text>',rx+10,sy,accentColor)
    sy=sy+32
    if ship then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">TOTAL DIST</text>',rx+10,sy,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>',rx+160,sy+2,fmtDist(ship.odo))
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">FLIGHT TIME</text>',rx+300,sy,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="white" font-size="20" font-family="monospace">%s</text>',rx+450,sy+2,fmtTime(ship.ft))
    end

    svgFresh(svg,flight,30,SH-45)
    return svgClose(svg, pageIdx)
end

-- ═══════════════════════════════════════════
-- PAGE 2: RADAR
-- ═══════════════════════════════════════════
local radarStateLabels = {[1]="OPERATIONAL",[0]="BROKEN",[-1]="JAMMED",[-2]="OBSTRUCTED",[-3]="IN USE",[-4]="NO RADAR"}
local radarStateColors = {[1]=safeColor,[0]=dangerColor,[-1]=dangerColor,[-2]=warnColor,[-3]=warnColor,[-4]=dimColor}

local function contactColor(c,isPvp)
    if c.f then return safeColor end
    if c.k=="Static" then return staticColor end
    if isPvp then return c.d<2000 and dangerColor or amberColor end
    return accentColor
end

local function renderRadar(pageIdx)
    local radar = safeDecode("T_radar")
    local flight = safeDecode("T_flight")
    local ship = safeDecode("T_ship")
    local svg = {}
    svgOpen(svg)
    local isPvp = (ship and ship.pvp) or (radar and radar.pvp)
    local zl = isPvp and "PVP ZONE" or "SAFE ZONE"
    local zc = isPvp and pvpColor or safeColor
    svgTitle(svg,"ARCHHUD RADAR",zl,zc)
    if not radar then return svgNoData(svg,"No radar telemetry from databank",pageIdx) end

    -- Status bar
    local statusY = 55
    svg[#svg+1] = stringf('<rect x="0" y="%d" width="%d" height="55" fill="%s"/>',statusY,SW,panelColor)
    local rState = radar.state or -4
    local stLabel = radarStateLabels[rState] or "UNKNOWN"
    local stColor = radarStateColors[rState] or dimColor
    svg[#svg+1] = stringf('<text x="40" y="%d" fill="%s" font-size="14" font-family="monospace">RADAR STATUS</text>',statusY+24,dimColor)
    svg[#svg+1] = stringf('<circle cx="200" cy="%d" r="6" fill="%s"/>',statusY+20,stColor)
    svg[#svg+1] = stringf('<text x="214" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>',statusY+25,stColor,stLabel)
    local cc = radar.count or 0
    svg[#svg+1] = stringf('<text x="500" y="%d" fill="%s" font-size="14" font-family="monospace">CONTACTS</text>',statusY+24,dimColor)
    svg[#svg+1] = stringf('<text x="620" y="%d" fill="%s" font-size="22" font-family="monospace" font-weight="bold">%d</text>',statusY+26,cc>0 and accentColor or dimColor,cc)
    if isPvp and radar.list then
        local threats = 0
        for _,c in ipairs(radar.list) do if not c.f and c.k=="Dynamic" then threats=threats+1 end end
        if threats>0 then
            svg[#svg+1] = stringf('<text x="720" y="%d" fill="%s" font-size="14" font-family="monospace">THREATS</text>',statusY+24,dimColor)
            svg[#svg+1] = stringf('<text x="830" y="%d" fill="%s" font-size="22" font-family="monospace" font-weight="bold">%d</text>',statusY+26,dangerColor,threats)
        end
    end

    -- Contact table
    local tableY,rowH,maxRows = 120, 36, 22
    svg[#svg+1] = stringf('<rect x="20" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>',tableY,SW-40,SH-tableY-70,panelColor,borderColor)
    local cN,cNm,cD,cS,cT,cF = 50,110,900,1200,1350,1600
    local hY = tableY+30
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">#</text>',cN,hY,accentColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">NAME</text>',cNm,hY,accentColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">DISTANCE</text>',cD,hY,accentColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">SIZE</text>',cS,hY,accentColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">TYPE</text>',cT,hY,accentColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" font-weight="bold">STATUS</text>',cF,hY,accentColor)
    svg[#svg+1] = stringf('<line x1="40" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',hY+8,SW-40,hY+8,borderColor)

    local contacts = radar.list or {}
    tblSort(contacts, function(a,b) return (a.d or 0)<(b.d or 0) end)
    local rStartY = hY+14
    local rendered = 0
    if #contacts==0 and rState==1 then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="18" font-family="monospace" text-anchor="middle">NO CONTACTS DETECTED</text>',SW/2,rStartY+60,dimColor)
    elseif rState~=1 then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="18" font-family="monospace" text-anchor="middle">RADAR %s</text>',SW/2,rStartY+60,stColor,stLabel)
    else
        for i,ct in ipairs(contacts) do
            if rendered>=maxRows then break end
            local ry = rStartY+(rendered*rowH)
            local nc = contactColor(ct,isPvp)
            if rendered%2==0 then svg[#svg+1] = stringf('<rect x="30" y="%d" width="%d" height="%d" fill="%s" rx="2"/>',ry-2,SW-60,rowH-2,rgba(30,40,55,0.4)) end
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace">%d</text>',cN,ry+20,dimColor,i)
            local nm = esc(ct.n or "Unknown"); if #nm>50 then nm=nm:sub(1,47).."..." end
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace">%s</text>',cNm,ry+21,nc,nm)
            local dc = "white"
            if isPvp and not ct.f and ct.k=="Dynamic" then dc = ct.d<2000 and dangerColor or (ct.d<10000 and warnColor or dc) end
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="16" font-family="monospace">%s</text>',cD,ry+21,dc,fmtDist(ct.d or 0))
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',cS,ry+21,dimColor,ct.s or "?")
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',cT,ry+21,ct.k=="Dynamic" and accentColor or staticColor,ct.k or "?")
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',cF,ry+21,ct.f and safeColor or dimColor,ct.f and "FRIENDLY" or "UNKNOWN")
            rendered = rendered+1
        end
        if #contacts>maxRows then
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" text-anchor="middle">... +%d more</text>',SW/2,rStartY+(maxRows*rowH)+16,dimColor,#contacts-maxRows)
        end
    end

    svgFresh(svg,flight,40,SH-45)
    return svgClose(svg, pageIdx)
end

-- ═══════════════════════════════════════════
-- PAGE 3: DAMAGE
-- ═══════════════════════════════════════════
local damageListPage = 0

local function integrityColor(pct)
    pct = mmax(0,mmin(100,pct))
    if pct>=50 then
        local t=(pct-50)/50
        return rgb(mfloor(255-195*t),255,mfloor(120*t))
    else
        local t=pct/50
        return rgb(255,mfloor(60+195*t),mfloor(60-60*t))
    end
end

local function renderDamage(pageIdx)
    local damage = safeDecode("T_damage")
    local flight = safeDecode("T_flight")
    local svg = {}
    svgOpen(svg)
    svgTitle(svg,"ARCHHUD DAMAGE REPORT")
    if flight and flight.time then
        local age = system.getArkTime()-flight.time
        local fc = age<15 and safeColor or (age<30 and warnColor or dangerColor)
        local ft = age<15 and "LIVE" or stringf("%.0fs AGO",age)
        svg[#svg+1] = stringf('<circle cx="%d" cy="25" r="5" fill="%s"/><text x="%d" y="30" fill="%s" font-size="14" font-family="monospace" text-anchor="end">DATA: %s</text>',SW-200,fc,SW-20,fc,ft)
    end
    if not damage then return svgNoData(svg,"Damage telemetry published every 10s while seated",pageIdx) end

    local pct = damage.pct or 0
    local iColor = integrityColor(pct)
    svg[#svg+1] = stringf('<text x="%d" y="150" fill="%s" font-size="80" font-family="monospace" font-weight="bold" text-anchor="middle">%.1f%%</text>',SW/2,iColor,pct)
    svg[#svg+1] = stringf('<text x="%d" y="178" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">SHIP INTEGRITY</text>',SW/2,dimColor)
    -- Bar
    local bx,bY,bW,bH = 40,198,SW-80,24
    local bf = mmax(0,mfloor(bW*pct/100))
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>',bx,bY,bW,bH,rgba(40,50,60,0.8))
    if bf>0 then svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>',bx,bY,bf,bH,iColor) end
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="none" stroke="%s" stroke-width="1" rx="4"/>',bx,bY,bW,bH,borderColor)
    svg[#svg+1] = stringf('<text x="%d" y="252" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">%d damaged  |  %d disabled  |  %d total</text>',SW/2,dimColor,damage.dmg or 0,damage.off or 0,damage.tot or 0)

    -- Element list
    local listTop,listBot,listX,listW = 275,SH-60,40,SW-80
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>',listX-10,listTop-10,listW+20,listBot-listTop+20,panelColor,borderColor)
    local list = damage.list
    if not list or #list==0 then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="30" font-family="monospace" text-anchor="middle" font-weight="bold">ALL SYSTEMS OPERATIONAL</text>',SW/2,(listTop+listBot)/2,safeColor)
    else
        local hdY = listTop+10
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">ELEMENT</text><text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">TYPE</text><text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">HEALTH</text><text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">HP</text>',
            listX,hdY,dimColor, listX+520,hdY,dimColor, listX+1050,hdY,dimColor, listX+1560,hdY,dimColor)
        svg[#svg+1] = stringf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',listX,hdY+10,listX+listW,hdY+10,borderColor)
        local rowHt,contentTop = 50, hdY+20
        local availH = listBot-contentTop-10
        local perPage = mmax(1,mfloor(availH/rowHt))
        local totalPages = mmax(1,mceil(#list/perPage))
        local pg = damageListPage % totalPages
        local sIdx = pg*perPage+1
        local eIdx = mmin(sIdx+perPage-1,#list)
        local ey = contentTop+20
        for i=sIdx,eIdx do
            local el = list[i]
            if el then
                local en = esc((el.n or "Unknown"):sub(1,34))
                local et = esc((el.t or ""):sub(1,28))
                local ep = el.mhp>0 and (el.hp/el.mhp*100) or 0
                local dead = el.hp<=0 or el.off
                local rc = dead and dangerColor or (ep>=50 and rgb(255,200,50) or rgb(255,130,30))
                svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',listX,ey,rc,en)
                svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">%s</text>',listX+520,ey,dimColor,et)
                local hbx,hbw,hbh = listX+1050,460,14
                svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="2"/>',hbx,ey-11,hbw,hbh,rgba(40,50,60,0.8))
                local hf = mmax(0,mfloor(hbw*ep/100))
                if hf>0 then svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="2"/>',hbx,ey-11,hf,hbh,rc) end
                if dead then
                    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">DESTROYED</text>',listX+1560,ey,dangerColor)
                else
                    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace">%d / %d</text>',listX+1560,ey,dimColor,el.hp,el.mhp)
                end
                ey = ey+rowHt
            end
        end
        if totalPages>1 then
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="14" font-family="monospace" text-anchor="end">PAGE %d / %d</text>',listX+listW,listBot+5,dimColor,pg+1,totalPages)
        end
    end
    return svgClose(svg, pageIdx)
end

-- ═══════════════════════════════════════════
-- PAGE 4: FLIGHT RECORDER
-- ═══════════════════════════════════════════
local MAX_HISTORY = 180
local history = {}

local function loadHistory()
    if db.hasKey("T_history") then
        local ok,data = pcall(jdecode,db.getStringValue("T_history"))
        if ok and type(data)=="table" then history=data; system.print(stringf("Recorder: Loaded %d snapshots.",#history)) end
    end
end

local function recordSnapshot()
    if not db.hasKey("T_flight") then return end
    local ok,fl = pcall(jdecode,db.getStringValue("T_flight"))
    if not ok or not fl or not fl.time then return end
    local n = #history
    if n>0 and history[n].t>=fl.time then return end
    history[n+1] = {t=fl.time,s=fl.spd,a=fl.alt,v=fl.vspd}
    while #history>MAX_HISTORY do table.remove(history,1) end
    db.setStringValue("T_history",jencode(history))
end

local function drawChart(svg,panelY,panelH,times,values,n,lineColor,chartLabel,fmtLabel,fmtCurr,showZero)
    local pX,pW = 105,1495
    local pX2 = pX+pW
    local plotY,plotH = panelY+34, panelH-44
    local infoX = 1660
    svg[#svg+1] = stringf('<rect x="15" y="%d" width="1610" height="%d" fill="%s" stroke="%s" rx="6"/>',panelY,panelH,panelColor,borderColor)
    svg[#svg+1] = stringf('<text x="30" y="%d" fill="%s" font-size="15" font-family="monospace" font-weight="bold">%s</text>',panelY+24,accentColor,chartLabel)
    if n==0 then
        svg[#svg+1] = stringf('<text x="820" y="%d" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">NO DATA</text>',panelY+panelH/2,dimColor)
        return
    end
    local vmin,vmax = values[1],values[1]
    for i=2,n do if values[i]<vmin then vmin=values[i] end; if values[i]>vmax then vmax=values[i] end end
    if showZero then if vmin>0 then vmin=0 end; if vmax<0 then vmax=0 end end
    local rng = vmax-vmin
    if rng<0.1 then local ctr=(vmin+vmax)/2; vmin=ctr-1; vmax=ctr+1; rng=2 else vmin=vmin-rng*0.08; vmax=vmax+rng*0.08; rng=vmax-vmin end
    for i=0,5 do
        local fr=i/5; local gy=plotY+plotH-fr*plotH; local gv=vmin+fr*rng
        svg[#svg+1] = stringf('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="0.5"/>',pX,gy,pX2,gy,gridColor)
        svg[#svg+1] = stringf('<text x="%d" y="%.1f" fill="%s" font-size="11" font-family="monospace" text-anchor="end">%s</text>',pX-8,gy+4,dimColor,fmtLabel(gv))
    end
    if showZero and vmin<0 and vmax>0 then
        local zy=plotY+plotH-((0-vmin)/rng)*plotH
        svg[#svg+1] = stringf('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="1" stroke-dasharray="6,4"/>',pX,zy,pX2,zy,rgba(255,255,255,0.3))
    end
    local tS,tE = times[1],times[n]; local tR=tE-tS; if tR<1 then tR=1 end
    local pts = {}
    for i=1,n do
        local xf=(times[i]-tS)/tR; local yf=(values[i]-vmin)/rng
        pts[i] = stringf("%.1f,%.1f",pX+xf*pW,plotY+plotH-yf*plotH)
    end
    svg[#svg+1] = stringf('<polyline points="%s" fill="none" stroke="%s" stroke-width="2" stroke-linejoin="round"/>',tblConcat(pts," "),lineColor)
    local ex=pX+((times[n]-tS)/tR)*pW; local ey=plotY+plotH-((values[n]-vmin)/rng)*plotH
    svg[#svg+1] = stringf('<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>',ex,ey,lineColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace">CURRENT</text>',infoX,panelY+22,dimColor)
    svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="26" font-family="monospace" font-weight="bold">%s</text>',infoX,panelY+52,lineColor,fmtCurr(values[n]))
end

local function renderRecorder(pageIdx)
    local n = #history
    local now = system.getArkTime()
    local svg = {}
    svgOpen(svg)
    svgTitle(svg,"ARCHHUD FLIGHT RECORDER")
    local isRec = n>0 and (now-history[n].t)<30
    if isRec then
        svg[#svg+1] = stringf('<circle cx="%d" cy="28" r="6" fill="%s"/><text x="%d" y="34" fill="%s" font-size="16" font-family="monospace" font-weight="bold">REC</text><text x="%d" y="34" fill="%s" font-size="14" font-family="monospace">%d samples</text>',
            SW-260,dangerColor,SW-248,dangerColor,SW-200,dimColor,n)
    else
        svg[#svg+1] = stringf('<circle cx="%d" cy="28" r="6" fill="%s"/><text x="%d" y="34" fill="%s" font-size="16" font-family="monospace">NO DATA</text>',SW-260,rgba(80,80,80,0.8),SW-248,dimColor)
    end

    local times,speeds,alts,vspeeds = {},{},{},{}
    for i=1,n do local h=history[i]; times[i]=h.t; speeds[i]=h.s*3.6; alts[i]=h.a; vspeeds[i]=h.v end
    local cH = 290
    drawChart(svg,60,cH,times,speeds,n,accentColor,"SPEED (km/h)",
        function(v) return v>10000 and stringf("%.1fk",v/1000) or stringf("%.0f",v) end,
        function(v) return stringf("%.0f km/h",v) end, false)
    drawChart(svg,360,cH,times,alts,n,safeColor,"ALTITUDE",
        function(v) return fmtAlt(v) end, function(v) return fmtAlt(v) end, false)
    drawChart(svg,660,cH,times,vspeeds,n,warnColor,"VERTICAL SPEED (m/s)",
        function(v) return stringf("%.1f",v) end,
        function(v) return stringf("%s%.1f m/s",v>=0 and "+" or "",v) end, true)

    -- Time axis
    if n>1 then
        local axY,plotX,plotX2 = 960,105,1600
        local tS,tE = times[1],times[n]; local totalS=tE-tS
        local ti = totalS>1500 and 300 or (totalS>600 and 120 or (totalS>300 and 60 or 30))
        svg[#svg+1] = stringf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',plotX,axY,plotX2,axY,borderColor)
        for i=0,mfloor(totalS/ti) do
            local sa=i*ti; local t=tE-sa
            if t>=tS then
                local x=plotX+((t-tS)/totalS)*(plotX2-plotX)
                svg[#svg+1] = stringf('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s" stroke-width="1"/>',x,axY,x,axY+8,dimColor)
                local lb = sa==0 and "now" or (sa<60 and stringf("%ds",sa) or stringf("%dm",mfloor(sa/60)))
                svg[#svg+1] = stringf('<text x="%.1f" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="middle">%s</text>',x,axY+22,dimColor,lb)
            end
        end
    end

    if n>0 then
        local age=now-history[n].t
        local fc=age<15 and safeColor or (age<30 and warnColor or dangerColor)
        svg[#svg+1] = stringf('<circle cx="30" cy="%d" r="5" fill="%s"/><text x="42" y="%d" fill="%s" font-size="13" font-family="monospace">DATA: %s</text>',
            SH-40,fc,SH-35,fc,age<15 and "LIVE" or stringf("%.0fs AGO",age))
        local dur=now-history[1].t
        local dt = dur>3600 and stringf("%.1fh recorded",dur/3600) or (dur>60 and stringf("%dm recorded",mfloor(dur/60)) or stringf("%ds recorded",mfloor(dur)))
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" text-anchor="end">%s</text>',SW-20,SH-35,dimColor,dt)
    end
    return svgClose(svg, pageIdx)
end

-- ═══════════════════════════════════════════
-- PAGE 5: ROUTE PLANNER
-- ═══════════════════════════════════════════
local routeColor = rgb(100,200,255)
local currentColor = rgb(255,220,50)
local pendingColor = rgba(130,224,255,0.5)

local function renderRoute(pageIdx)
    local route = safeDecode("T_route")
    local ap = safeDecode("T_ap")
    local flight = safeDecode("T_flight")
    local svg = {}
    svgOpen(svg)
    svgTitle(svg,"ARCHHUD ROUTE PLANNER")
    if flight and flight.time then
        local age=system.getArkTime()-flight.time
        local fc=age<5 and safeColor or (age<15 and warnColor or dangerColor)
        svg[#svg+1] = stringf('<circle cx="%d" cy="25" r="5" fill="%s"/><text x="%d" y="30" fill="%s" font-size="14" font-family="monospace" text-anchor="end">DATA: %s</text>',
            SW-200,fc,SW-20,fc,age<5 and "LIVE" or stringf("%.0fs AGO",age))
    end
    if not route then return svgNoData(svg,"Route telemetry published every 3s while seated",pageIdx) end

    if not route.active then
        svg[#svg+1] = stringf('<rect x="40" y="80" width="%d" height="200" fill="%s" stroke="%s" rx="8"/>',SW-80,panelColor,borderColor)
        svg[#svg+1] = stringf('<text x="%d" y="170" fill="%s" font-size="32" font-family="monospace" text-anchor="middle" font-weight="bold">NO ACTIVE ROUTE</text>',SW/2,dimColor)
        svg[#svg+1] = stringf('<text x="%d" y="210" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Select a target and use ALT+SHIFT+8 to add waypoints</text>',SW/2,pendingColor)
        if route.saved and route.savedCount and route.savedCount>0 then
            svg[#svg+1] = stringf('<text x="%d" y="250" fill="%s" font-size="16" font-family="monospace" text-anchor="middle">Saved route: %d waypoints</text>',SW/2,safeColor,route.savedCount)
        end
        if ap then
            svg[#svg+1] = stringf('<text x="40" y="%d" fill="%s" font-size="14" font-family="monospace">AP TARGET: %s</text>',SH-40,ap.on and safeColor or dimColor,esc(ap.tgt or "None"))
        end
        return svgClose(svg, pageIdx)
    end

    local wps = route.wps or {}
    local wpCount = route.count or #wps
    local progress = route.progress or 0
    local spd = route.spd or 0

    -- Overview panel
    local ovY,ovH = 60,130
    svg[#svg+1] = stringf('<rect x="20" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>',ovY,SW-40,ovH,panelColor,borderColor)
    svg[#svg+1] = stringf('<text x="50" y="%d" fill="%s" font-size="14" font-family="monospace">ROUTE PROGRESS</text>',ovY+28,dimColor)
    svg[#svg+1] = stringf('<text x="260" y="%d" fill="%s" font-size="28" font-family="monospace" font-weight="bold">%.1f%%</text>',ovY+30,accentColor,progress)
    local pbX,pbY,pbW,pbH = 50,ovY+42,SW-100,20
    local pbF = mmax(0,mfloor(pbW*progress/100))
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>',pbX,pbY,pbW,pbH,rgba(40,50,60,0.8))
    if pbF>0 then svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="4"/>',pbX,pbY,pbF,pbH,accentColor) end
    svg[#svg+1] = stringf('<rect x="%d" y="%d" width="%d" height="%d" fill="none" stroke="%s" rx="4"/>',pbX,pbY,pbW,pbH,borderColor)
    for i=1,wpCount do
        local mx=pbX+mfloor(pbW*(i/wpCount))
        local mc = wps[i] and wps[i].cur and currentColor or rgba(255,255,255,0.4)
        svg[#svg+1] = stringf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',mx,pbY,mx,pbY+pbH,mc)
    end
    local sY = pbY+pbH+22
    svg[#svg+1] = stringf('<text x="50" y="%d" fill="%s" font-size="12" font-family="monospace">TOTAL</text><text x="50" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>',sY,dimColor,sY+18,accentColor,fmtDist(route.totalDist))
    svg[#svg+1] = stringf('<text x="350" y="%d" fill="%s" font-size="12" font-family="monospace">REMAINING</text><text x="350" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>',sY,dimColor,sY+18,warnColor,fmtDist(route.remainDist))
    svg[#svg+1] = stringf('<text x="700" y="%d" fill="%s" font-size="12" font-family="monospace">ETA</text><text x="700" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>',sY,dimColor,sY+18,safeColor,fmtTime(route.remainEta))
    svg[#svg+1] = stringf('<text x="1000" y="%d" fill="%s" font-size="12" font-family="monospace">SPEED</text><text x="1000" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>',sY,dimColor,sY+18,accentColor,fmtSpeed(spd))
    svg[#svg+1] = stringf('<text x="1350" y="%d" fill="%s" font-size="12" font-family="monospace">WAYPOINTS</text><text x="1350" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%d</text>',sY,dimColor,sY+18,accentColor,wpCount)
    local apOn = ap and ap.on
    svg[#svg+1] = stringf('<text x="1600" y="%d" fill="%s" font-size="12" font-family="monospace">AUTOPILOT</text><text x="1600" y="%d" fill="%s" font-size="16" font-family="monospace" font-weight="bold">%s</text>',sY,dimColor,sY+18,apOn and safeColor or dimColor,apOn and "ACTIVE" or "OFF")

    -- Waypoint list
    local ltop = ovY+ovH+15
    local lbot = SH-70
    svg[#svg+1] = stringf('<rect x="20" y="%d" width="%d" height="%d" fill="%s" stroke="%s" rx="6"/>',ltop,SW-40,lbot-ltop,panelColor,borderColor)
    local hdY = ltop+25
    svg[#svg+1] = stringf('<text x="70" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">#</text><text x="140" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">WAYPOINT</text><text x="850" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">PLANET</text><text x="1100" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">LEG DIST</text><text x="1350" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">FROM SHIP</text><text x="1650" y="%d" fill="%s" font-size="13" font-family="monospace" font-weight="bold">ETA</text>',
        hdY,accentColor,hdY,accentColor,hdY,accentColor,hdY,accentColor,hdY,accentColor,hdY,accentColor)
    svg[#svg+1] = stringf('<line x1="35" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>',hdY+10,SW-55,hdY+10,borderColor)

    local rowHt = 58
    local rowSY = hdY+20
    local maxR = mfloor((lbot-rowSY-10)/rowHt)
    local connX = 55
    for i=1,mmin(wpCount,maxR) do
        local wp = wps[i]; if not wp then break end
        local ry = rowSY+((i-1)*rowHt)
        local isCur = wp.cur
        local nm = esc(wp.n or "Unknown"); if #nm>42 then nm=nm:sub(1,40)..".." end
        local planet = esc(wp.p or "")
        local legD = fmtDist(wp.leg)
        local shipD = fmtDist(wp.d)
        local eta = "---"
        if spd>1 and wp.d and wp.d>0 then eta = fmtTime(wp.d/spd) end
        local nodeC,nameC,txtC
        if isCur then
            nodeC,nameC,txtC = currentColor,currentColor,"white"
            svg[#svg+1] = stringf('<rect x="25" y="%d" width="%d" height="%d" fill="%s" rx="3"/>',ry-8,SW-50,rowHt-4,rgba(255,220,50,0.08))
        else nodeC,nameC,txtC = pendingColor,pendingColor,dimColor end
        if i<wpCount and i<maxR then
            svg[#svg+1] = stringf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2" stroke-dasharray="4,4"/>',connX,ry+14,connX,ry+rowHt-8,rgba(130,224,255,0.2))
        end
        if isCur then
            svg[#svg+1] = stringf('<circle cx="%d" cy="%d" r="14" fill="none" stroke="%s" stroke-width="2"/><circle cx="%d" cy="%d" r="8" fill="%s"/>',connX,ry+2,currentColor,connX,ry+2,currentColor)
            svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="11" font-family="monospace" text-anchor="middle">%d</text>',connX,ry+5,rgb(12,16,22),i)
        else
            svg[#svg+1] = stringf('<circle cx="%d" cy="%d" r="12" fill="none" stroke="%s" stroke-width="1.5"/><text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="middle">%d</text>',connX,ry+2,nodeC,connX,ry+6,nodeC,i)
        end
        svg[#svg+1] = stringf('<text x="140" y="%d" fill="%s" font-size="17" font-family="monospace"%s>%s</text>',ry+6,nameC,isCur and ' font-weight="bold"' or "",nm)
        if isCur then svg[#svg+1] = stringf('<text x="140" y="%d" fill="%s" font-size="11" font-family="monospace">CURRENT TARGET</text>',ry+22,currentColor) end
        svg[#svg+1] = stringf('<text x="850" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',ry+6,txtC,planet)
        svg[#svg+1] = stringf('<text x="1100" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',ry+6,txtC,legD)
        svg[#svg+1] = stringf('<text x="1350" y="%d" fill="%s" font-size="15" font-family="monospace"%s>%s</text>',ry+6,isCur and currentColor or txtC,isCur and ' font-weight="bold"' or "",shipD)
        svg[#svg+1] = stringf('<text x="1650" y="%d" fill="%s" font-size="15" font-family="monospace">%s</text>',ry+6,isCur and safeColor or txtC,eta)
    end
    if wpCount>maxR then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="13" font-family="monospace" text-anchor="middle">... +%d more</text>',SW/2,lbot-10,dimColor,wpCount-maxR)
    end

    -- Footer
    local tgtN = route.tgt or (ap and ap.tgt) or "None"
    svg[#svg+1] = stringf('<text x="40" y="%d" fill="%s" font-size="13" font-family="monospace">TARGET: %s</text>',SH-40,accentColor,esc(tgtN))
    if route.saved then
        svg[#svg+1] = stringf('<text x="%d" y="%d" fill="%s" font-size="12" font-family="monospace" text-anchor="end">SAVED: %d WP</text>',SW-40,SH-40,dimColor,route.savedCount or 0)
    end
    return svgClose(svg, pageIdx)
end

-- ═══════════════════════════════════════════
-- ALERT CHECKS (run every tick)
-- ═══════════════════════════════════════════
local prevIntegrity = 100
local prevDisabled = 0
local prevContactIds = {}
local prevThreatClose = 0

local function checkDamageAlerts()
    local damage = safeDecode("T_damage")
    if not damage then return end
    local pct = damage.pct or 100
    local off = damage.off or 0
    local alertMsg = nil
    if pct<25 and prevIntegrity>=25 then alertMsg = stringf("CRITICAL: Hull integrity %.0f%% - %d disabled",pct,off)
    elseif pct<50 and prevIntegrity>=50 then alertMsg = stringf("WARNING: Hull integrity %.0f%% - %d damaged",pct,damage.dmg or 0)
    elseif pct<75 and prevIntegrity>=75 then alertMsg = stringf("Hull integrity %.0f%% - taking damage",pct) end
    if off>prevDisabled then alertMsg = stringf("ALERT: %d element(s) destroyed! %d total disabled",off-prevDisabled,off) end
    prevIntegrity = pct; prevDisabled = off
    if alertMsg then db.setStringValue("A_damage",jencode({msg=alertMsg,t=system.getArkTime()})) end
end

local function checkRadarAlerts()
    local radar = safeDecode("T_radar")
    if not radar or not radar.list then return end
    local isPvp,contacts = radar.pvp, radar.list
    local alertMsg,threatClose = nil, 0
    local currentIds = {}
    for _,c in ipairs(contacts) do
        local key=(c.n or "?").."_"..(c.s or "?"); currentIds[key]=true
        if isPvp and not c.f and c.k=="Dynamic" and c.d<2000 then threatClose=threatClose+1 end
    end
    if threatClose>prevThreatClose and isPvp then alertMsg=stringf("THREAT: %d hostile(s) within 2 km!",threatClose-prevThreatClose) end
    if not alertMsg then
        for _,c in ipairs(contacts) do
            if c.k=="Dynamic" and not c.f then
                local key=(c.n or "?").."_"..(c.s or "?")
                if not prevContactIds[key] then
                    alertMsg=stringf("Radar: New contact '%s' at %s%s",c.n or "Unknown",fmtDist(c.d or 0),isPvp and " in PVP zone" or ""); break
                end
            end
        end
    end
    prevContactIds=currentIds; prevThreatClose=threatClose
    if alertMsg then db.setStringValue("A_radar",jencode({msg=alertMsg,t=system.getArkTime()})) end
end

local function checkRecorderAlerts()
    local n = #history
    if n<4 then return end
    local cur,prev = history[n], history[n-3]
    local alertMsg = nil
    if prev.a and cur.a and prev.a>500 then
        local drop=prev.a-cur.a; if drop>1000 then alertMsg=stringf("ALERT: Rapid altitude loss! -%dm in 30s",mfloor(drop)) end
    end
    if prev.s and cur.s and prev.s>100 then
        if prev.s-cur.s > prev.s*0.5 then alertMsg=stringf("ALERT: Sudden deceleration! %.0f -> %.0f m/s",prev.s,cur.s) end
    end
    if alertMsg then db.setStringValue("A_recorder",jencode({msg=alertMsg,t=system.getArkTime()})) end
end

-- ═══════════════════════════════════════════
-- PAGE DISPATCHER
-- ═══════════════════════════════════════════
local renderers = {renderTelemetry, renderRadar, renderDamage, renderRecorder, renderRoute}

local function renderPage(pageIdx)
    local r = renderers[pageIdx]
    if r then return r(pageIdx) end
    return ""
end

-- ═══════════════════════════════════════════
-- SCREEN CLICK NAVIGATION
-- In screen > onMouseDown(x,y):  onScreenNav(1,x)
-- In screen2 > onMouseDown(x,y): onScreenNav(2,x)
-- ═══════════════════════════════════════════
function onScreenNav(screenNum, x)
    if screenNum == 1 then
        if x > 0.5 then screen1Page = (screen1Page % pageCount) + 1
        else screen1Page = ((screen1Page - 2) % pageCount) + 1 end
        if screen then screen.setHTML(renderPage(screen1Page)) end
    elseif screenNum == 2 and screen2 then
        if x > 0.5 then screen2Page = (screen2Page % pageCount) + 1
        else screen2Page = ((screen2Page - 2) % pageCount) + 1 end
        screen2.setHTML(renderPage(screen2Page))
    end
end

-- ═══════════════════════════════════════════
-- TIMER CALLBACK
-- In unit > onTimer(timerId):  onBoardTick(timerId)
-- ═══════════════════════════════════════════
function onBoardTick(timerId)
    if timerId == "refresh" then
        -- Flight recorder snapshots
        recorderTicks = recorderTicks + 1
        if recorderTicks >= RECORDER_TICKS then
            recordSnapshot()
            recorderTicks = 0
        end
        -- Damage page auto-advances element list
        damageListPage = damageListPage + 1
        -- Alert checks
        checkDamageAlerts()
        checkRadarAlerts()
        checkRecorderAlerts()
        -- Refresh current page on each screen
        if screen and db then screen.setHTML(renderPage(screen1Page)) end
        if screen2 and db then screen2.setHTML(renderPage(screen2Page)) end
    end
end

-- ═══════════════════════════════════════════
-- STOP HANDLER
-- In unit > onStop:  onBoardStop()
-- ═══════════════════════════════════════════
function onBoardStop()
    if screen then screen.setHTML("") end
    if screen2 then screen2.setHTML("") end
end

-- ═══════════════════════════════════════════
-- AUTO-INITIALIZATION
-- ═══════════════════════════════════════════
if not db then
    system.print("ArchHUD Display: No databank. Rename databank slot to 'db'.")
    return
end
if not screen then
    system.print("ArchHUD Display: No screen. Rename screen slot to 'screen'.")
    return
end
loadHistory()
unit.setTimer("refresh", TICK_INTERVAL)
local mode = screen2 and "2 screens" or "1 screen"
system.print(stringf("ArchHUD Combined Display started. %d pages, %s. Click screen to navigate.", pageCount, mode))
screen.setHTML(renderPage(screen1Page))
if screen2 then screen2.setHTML(renderPage(screen2Page)) end

#!/usr/bin/env lua5.3
--- Unit tests for ArchHUD pure helper functions.
---
--- These mirror the real implementations in src/requires/baseclass.lua. Those
--- helpers are file-local closures inside the BaseClass constructor and cannot
--- be require()'d directly, so (as with tests/test_math.lua) we test faithful
--- copies. KEEP THESE IN SYNC with the source. The tree-wide syntax check
--- (tests/test_syntax.lua) plus luacheck validate that the real source compiles.
---
--- Run from the repo root:  lua tests/test_util.lua

local passed, failed = 0, 0
local errors = {}

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        errors[#errors + 1] = string.format("  FAIL: %s\n    %s", name, tostring(err))
    end
end

local function eq(a, b, msg)
    if a ~= b then
        error(string.format("%s: expected %s, got %s", msg or "", tostring(b), tostring(a)))
    end
end

local mfloor = math.floor
local mabs = math.abs
local epsilon = 1e-09

-------------------------------------------------------------------------------
-- Mirrors of src/requires/baseclass.lua (keep in sync)
-------------------------------------------------------------------------------
local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return mfloor(num * mult + 0.5) / mult
end

local function float_eq(a, b)
    if a == 0 then
        return mabs(b) < 1e-09
    elseif b == 0 then
        return mabs(a) < 1e-09
    else
        return mabs(a - b) < math.max(mabs(a), mabs(b)) * epsilon
    end
end

local function getDistanceDisplayString(distance, places)
    places = places or 1
    local unit = "m"
    if distance > 100000 then
        distance = distance / 200000
        unit = "su"
    elseif distance > 1000 then
        distance = distance / 1000
        unit = "km"
    end
    return round(distance, places) .. unit
end

local function FormatTimeString(seconds)
    local minutes, hours, days = 0, 0, 0
    if seconds < 60 then
        seconds = mfloor(seconds)
    elseif seconds < 3600 then
        minutes = mfloor(seconds / 60)
        seconds = mfloor(seconds % 60)
    elseif seconds < 86400 then
        hours = mfloor(seconds / 3600)
        minutes = mfloor((seconds % 3600) / 60)
    else
        days = mfloor(seconds / 86400)
        hours = mfloor((seconds % 86400) / 3600)
    end
    if days > 365 then return ">1y"
    elseif days > 0 then return days .. "d " .. hours .. "h "
    elseif hours > 0 then return hours .. "h " .. minutes .. "m "
    elseif minutes > 0 then return minutes .. "m " .. seconds .. "s"
    elseif seconds > 0 then return seconds .. "s"
    else return "0s" end
end

local function uclamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-------------------------------------------------------------------------------
-- round
-------------------------------------------------------------------------------
test("round half-up", function()
    eq(round(2.4), 2.0, "2.4"); eq(round(2.5), 3.0, "2.5"); eq(round(2.6), 3.0, "2.6")
end)
test("round negative rounds toward +inf at .5", function()
    eq(round(-2.5), -2.0, "-2.5"); eq(round(-2.6), -3.0, "-2.6")
end)
test("round to decimal places", function()
    eq(round(3.14159, 2), 3.14, "2dp down"); eq(round(3.146, 2), 3.15, "2dp up")
end)

-------------------------------------------------------------------------------
-- getDistanceDisplayString
-------------------------------------------------------------------------------
test("distance meters", function() eq(getDistanceDisplayString(500), "500.0m", "m") end)
test("distance km", function() eq(getDistanceDisplayString(1500), "1.5km", "km") end)
test("distance su", function() eq(getDistanceDisplayString(2000000), "10.0su", "su") end)
test("distance 1000 boundary stays meters", function() eq(getDistanceDisplayString(1000), "1000.0m", "1000") end)
test("distance honors places arg", function() eq(getDistanceDisplayString(1234, 0), "1.0km", "0dp") end)

-------------------------------------------------------------------------------
-- FormatTimeString
-------------------------------------------------------------------------------
test("time zero", function() eq(FormatTimeString(0), "0s", "0") end)
test("time seconds", function() eq(FormatTimeString(45), "45s", "45") end)
test("time minutes", function() eq(FormatTimeString(125), "2m 5s", "125") end)
test("time hours", function() eq(FormatTimeString(3725), "1h 2m ", "3725") end)
test("time days", function() eq(FormatTimeString(90000), "1d 1h ", "90000") end)
test("time over a year", function() eq(FormatTimeString(366 * 86400 + 1), ">1y", ">1y") end)

-------------------------------------------------------------------------------
-- float_eq / uclamp
-------------------------------------------------------------------------------
test("float_eq zero branch", function()
    assert(float_eq(0, 0), "0,0"); assert(float_eq(0, 1e-10), "0,tiny"); assert(not float_eq(0, 1e-3), "0,big")
end)
test("float_eq general", function()
    assert(float_eq(100, 100), "equal"); assert(not float_eq(100, 101), "unequal")
end)
test("uclamp", function()
    eq(uclamp(5, 0, 10), 5, "mid"); eq(uclamp(-1, 0, 10), 0, "lo"); eq(uclamp(99, 0, 10), 10, "hi")
end)

print(string.format("=== test_util: %d passed, %d failed ===", passed, failed))
if failed > 0 then
    for _, e in ipairs(errors) do print(e) end
    os.exit(1)
end
print("All util tests passed!")

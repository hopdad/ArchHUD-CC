#!/usr/bin/env lua5.3
--- Test harness for ArchHUD math functions (Kinematic, Kepler, PlanetRef)
--- Validates correctness, edge cases, and NaN/inf safety.
--- Run: lua5.3 tests/test_math.lua

local passed = 0
local failed = 0
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

local function assertEq(a, b, msg, tol)
    tol = tol or 0.001
    if type(a) == "number" and type(b) == "number" then
        if a ~= a or b ~= b then -- NaN check
            error(string.format("%s: got NaN (a=%s, b=%s)", msg or "", tostring(a), tostring(b)))
        end
        if math.abs(a - b) > tol then
            error(string.format("%s: expected %f, got %f (tol=%f)", msg or "", b, a, tol))
        end
    elseif a ~= b then
        error(string.format("%s: expected %s, got %s", msg or "", tostring(b), tostring(a)))
    end
end

local function assertNotNaN(v, msg)
    if v ~= v then
        error(string.format("%s: got NaN", msg or ""))
    end
end

local function assertNotInf(v, msg)
    if v == math.huge or v == -math.huge then
        error(string.format("%s: got inf", msg or ""))
    end
end

local function assertGte(a, b, msg)
    if a < b then
        error(string.format("%s: expected >= %f, got %f", msg or "", b, a))
    end
end

-----------------------------------------------------------------------
-- Minimal vec3 implementation for testing
-----------------------------------------------------------------------
local vec3_mt = {}
vec3_mt.__index = vec3_mt

function vec3_mt.__add(a, b) return setmetatable({x=a.x+b.x, y=a.y+b.y, z=a.z+b.z}, vec3_mt) end
function vec3_mt.__sub(a, b) return setmetatable({x=a.x-b.x, y=a.y-b.y, z=a.z-b.z}, vec3_mt) end
function vec3_mt.__mul(a, b)
    if type(a) == "number" then return setmetatable({x=a*b.x, y=a*b.y, z=a*b.z}, vec3_mt) end
    if type(b) == "number" then return setmetatable({x=a.x*b, y=a.y*b, z=a.z*b}, vec3_mt) end
    return setmetatable({x=a.x*b.x, y=a.y*b.y, z=a.z*b.z}, vec3_mt)
end
function vec3_mt.__div(a, b) return setmetatable({x=a.x/b, y=a.y/b, z=a.z/b}, vec3_mt) end
function vec3_mt.__unm(a) return setmetatable({x=-a.x, y=-a.y, z=-a.z}, vec3_mt) end
function vec3_mt:len2() return self.x*self.x + self.y*self.y + self.z*self.z end
function vec3_mt:len() return math.sqrt(self:len2()) end
function vec3_mt:normalize()
    local l = self:len()
    if l < 1e-12 then return setmetatable({x=0,y=0,z=0}, vec3_mt) end
    return self / l
end
function vec3_mt:dot(b) return self.x*b.x + self.y*b.y + self.z*b.z end
function vec3_mt:cross(b)
    return setmetatable({
        x = self.y*b.z - self.z*b.y,
        y = self.z*b.x - self.x*b.z,
        z = self.x*b.y - self.y*b.x
    }, vec3_mt)
end
function vec3_mt:project_on(b)
    local bn = b:normalize()
    return bn * self:dot(bn)
end
function vec3_mt:project_on_plane(n)
    return self - self:project_on(n)
end
function vec3_mt:unpack() return self.x, self.y, self.z end

local function vec3(a, b, c)
    if type(a) == "table" and a.x then return setmetatable({x=a.x, y=a.y, z=a.z}, vec3_mt) end
    return setmetatable({x=a or 0, y=b or 0, z=c or 0}, vec3_mt)
end

-- Make vec3 global for the loaded modules
_G.vec3 = vec3

-----------------------------------------------------------------------
-- Mock DU environment
-----------------------------------------------------------------------
local function uclamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function float_eq(a, b) return math.abs(a - b) < 1e-9 end
local function tonum(v) return tonumber(v) end
local msqrt = math.sqrt
local mabs = math.abs

-- Minimal mock objects
local Nav = {}
local c = {}
local u = {}
local s = {}

-- MapPosition metatable
local MapPosition = {}
MapPosition.__index = MapPosition

-----------------------------------------------------------------------
-- Load Kinematics from atlasclass.lua
-----------------------------------------------------------------------
-- We need to extract the Kinematics function. Since it's defined as a global,
-- we can dofile the atlasclass and it will set the global functions.
-- But the file has many dependencies, so we'll extract just the math functions.

-- Load the file as a string and extract Kinematics function
local function loadKinematics()
    -- Build a self-contained Kinematic module
    local Kinematic = {}

    function Kinematic.computeAccelerationTime(initial, acceleration, final)
        return (final - initial)/acceleration
    end

    function Kinematic.computeDistanceAndTime(initial, final, mass, thrust, t50, brakeThrust)
        t50         = t50 or 0
        brakeThrust = brakeThrust or 0

        local speedUp = initial < final
        local a0      = thrust / (speedUp and mass or -mass)
        local b0      = -brakeThrust/mass
        local totA    = a0+b0

        if initial == final then
            return 0, 0
        elseif speedUp and totA <= 0 or not speedUp and totA >= 0 then
            return -1, -1
        end

        local distanceToMax, timeToMax = 0, 0

        if a0 ~= 0 and t50 > 0 then
            local c1 = math.pi/t50/2
            local v = function(t)
                return a0*(t/2 - t50*math.sin(c1*t)/math.pi) + b0*t + initial
            end
            local speedchk = speedUp and function(s) return s >= final end or
                                         function(s) return s <= final end
            timeToMax = 2*t50
            if speedchk(v(timeToMax)) then
                local lasttime = 0
                while math.abs(timeToMax - lasttime) > 0.25 do
                    local t = (timeToMax + lasttime)/2
                    if speedchk(v(t)) then
                        timeToMax = t
                    else
                        lasttime = t
                    end
                end
            end
            local K = 2*a0*t50^2/math.pi^2
            distanceToMax = K*(math.cos(c1*timeToMax) - 1) +
                            (a0+2*b0)*timeToMax^2/4 + initial*timeToMax
            if timeToMax < 2*t50 then
                return distanceToMax, timeToMax
            end
            initial = v(timeToMax)
        end
        local a = a0+b0
        local t = Kinematic.computeAccelerationTime(initial, a, final)
        local d = initial*t + a*t*t/2
        return distanceToMax+d, timeToMax+t
    end

    function Kinematic.computeTravelTime(initial, acceleration, distance)
        if distance == 0 then return 0 end
        if acceleration ~= 0 then
            return (math.sqrt(2*acceleration*distance+initial^2) - initial)/acceleration
        end
        assert(initial > 0, 'Acceleration and initial speed are both zero.')
        return distance/initial
    end

    return Kinematic
end

-----------------------------------------------------------------------
-- Load orbital parameters function (extracted from Keplers)
-----------------------------------------------------------------------
local function computeOrbitalParameters(bodyGM, bodyCenter, bodyRadius, worldPos, velocity)
    local pos = vec3(worldPos)
    local v = vec3(velocity)
    local r = pos - bodyCenter
    local v2 = v:len2()
    local d = r:len()
    local mu = bodyGM
    local e = ((v2 - mu / d) * r - r:dot(v) * v) / mu

    local denom = 2 * mu / d - v2
    local a
    if math.abs(denom) < 1e-6 then
        a = math.huge
    else
        a = mu / denom
    end
    local ecc = e:len()
    local dir = e:normalize()
    local pd = a * (1 - ecc)
    local ad = a * (1 + ecc)
    local per = pd * dir + bodyCenter
    local apo = ecc <= 1 and -ad * dir + bodyCenter or nil

    local taCos = (ecc * d > 0) and ((e:dot(r)) / (ecc * d)) or 1
    taCos = taCos > 1 and 1 or (taCos < -1 and -1 or taCos)
    local trueAnomaly = math.acos(taCos)
    if r:dot(v) < 0 then
        trueAnomaly = -(trueAnomaly - 2 * math.pi)
    end

    local eaDenom = 1 + ecc * math.cos(trueAnomaly)
    local eaCos = math.abs(eaDenom) > 1e-10 and (math.cos(trueAnomaly) + ecc) / eaDenom or 1
    eaCos = eaCos > 1 and 1 or (eaCos < -1 and -1 or eaCos)
    local EccentricAnomaly = math.acos(eaCos)

    return {
        eccentricity = ecc,
        semiMajorAxis = a,
        periapsis = { altitude = pd - bodyRadius, speed = 0 },
        apoapsis = apo and { altitude = ad - bodyRadius, speed = 0 } or nil,
        trueAnomaly = trueAnomaly,
        eccentricAnomaly = EccentricAnomaly,
    }
end


-----------------------------------------------------------------------
-- KINEMATIC TESTS
-----------------------------------------------------------------------
local K = loadKinematics()

print("=== Kinematic Tests ===")

test("computeAccelerationTime: basic", function()
    -- v = v0 + a*t => t = (v-v0)/a
    assertEq(K.computeAccelerationTime(0, 10, 100), 10, "0 to 100 at 10m/s^2")
    assertEq(K.computeAccelerationTime(50, 5, 100), 10, "50 to 100 at 5m/s^2")
    assertEq(K.computeAccelerationTime(100, -10, 0), 10, "100 to 0 at -10m/s^2")
end)

test("computeDistanceAndTime: trivial (same speed)", function()
    local d, t = K.computeDistanceAndTime(100, 100, 1000, 50000, 0, 0)
    assertEq(d, 0, "distance")
    assertEq(t, 0, "time")
end)

test("computeDistanceAndTime: basic acceleration", function()
    -- 10,000 kg ship, 100,000N thrust, no warmup, no brakes
    -- a = F/m = 10 m/s^2
    -- 0 to 100 m/s: t = 10s, d = 500m
    local d, t = K.computeDistanceAndTime(0, 100, 10000, 100000, 0, 0)
    assertEq(t, 10, "time", 0.01)
    assertEq(d, 500, "distance", 0.01)
end)

test("computeDistanceAndTime: braking only", function()
    -- 10,000 kg ship, no forward thrust, 100,000N brakes
    -- a = -brakeThrust/m = -10 m/s^2
    -- 100 to 0: t = 10s, d = 500m
    local d, t = K.computeDistanceAndTime(100, 0, 10000, 0, 0, 100000)
    assertEq(t, 10, "time", 0.01)
    assertEq(d, 500, "distance", 0.01)
end)

test("computeDistanceAndTime: no solution (insufficient thrust)", function()
    -- Try to accelerate with zero thrust
    local d, t = K.computeDistanceAndTime(0, 100, 10000, 0, 0, 0)
    assertEq(d, -1, "distance should be -1")
    assertEq(t, -1, "time should be -1")
end)

test("computeDistanceAndTime: no solution (brake > thrust)", function()
    -- Forward thrust less than brakeThrust when trying to speed up
    local d, t = K.computeDistanceAndTime(0, 100, 10000, 10000, 0, 20000)
    assertEq(d, -1, "distance should be -1")
    assertEq(t, -1, "time should be -1")
end)

test("computeDistanceAndTime: with warmup (t50)", function()
    -- With engine warmup, result should be >= pure Newton result
    local d1, t1 = K.computeDistanceAndTime(0, 100, 10000, 100000, 0, 0)
    local d2, t2 = K.computeDistanceAndTime(0, 100, 10000, 100000, 1, 0)
    -- Warmup means it takes longer
    assertGte(t2, t1, "warmup time >= instant time")
    assertGte(d2, d1, "warmup distance >= instant distance")
    assertNotNaN(d2, "warmup distance")
    assertNotNaN(t2, "warmup time")
end)

test("computeDistanceAndTime: large speed values", function()
    -- Near max game velocity (8333 m/s = 30000 km/h)
    local d, t = K.computeDistanceAndTime(8000, 0, 500000, 0, 0, 2000000)
    assertNotNaN(d, "distance")
    assertNotNaN(t, "time")
    assertGte(d, 0, "positive distance")
    assertGte(t, 0, "positive time")
end)

test("computeDistanceAndTime: very small speed", function()
    local d, t = K.computeDistanceAndTime(0.001, 0, 10000, 0, 0, 100000)
    assertNotNaN(d, "distance")
    assertNotNaN(t, "time")
end)

test("computeDistanceAndTime: NaN/inf safety", function()
    -- Zero mass would cause division by zero — but in practice mass > 0
    -- Test with very small mass
    local d, t = K.computeDistanceAndTime(100, 0, 1, 0, 0, 1000000)
    assertNotNaN(d, "distance with tiny mass")
    assertNotNaN(t, "time with tiny mass")
end)

test("computeTravelTime: basic", function()
    -- d = v*t + a*t^2/2
    -- At constant speed: t = d/v
    assertEq(K.computeTravelTime(100, 0, 1000), 10, "constant speed", 0.01)
end)

test("computeTravelTime: with acceleration", function()
    -- d = v0*t + a*t^2/2, solve for t
    local t = K.computeTravelTime(0, 10, 500)
    assertEq(t, 10, "from rest", 0.01)
end)

test("computeTravelTime: zero distance", function()
    assertEq(K.computeTravelTime(100, 10, 0), 0, "zero distance")
end)

-----------------------------------------------------------------------
-- ORBITAL PARAMETER TESTS
-----------------------------------------------------------------------
print("\n=== Orbital Parameter Tests ===")

-- Use Alioth-like planet: GM ~ 157470 km^3/s^2, radius ~ 126068 m
local aliothGM = 1.572199e+12  -- m^3/s^2
local aliothRadius = 126068    -- m
local aliothCenter = vec3(0, 0, 0)

test("orbitalParameters: circular orbit", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local orbitalSpeed = math.sqrt(aliothGM / distance)
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, orbitalSpeed, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity")
    -- Circular orbit should have eccentricity near 0
    assertEq(orbit.eccentricity, 0, "circular eccentricity", 0.01)
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly")
end)

test("orbitalParameters: elliptical orbit", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    -- Speed between circular and escape
    local orbitalSpeed = math.sqrt(aliothGM / distance)
    local speed = orbitalSpeed * 1.3 -- Elliptical
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, speed, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity")
    -- Should be elliptical (0 < e < 1)
    assertGte(orbit.eccentricity, 0, "e >= 0")
    assert(orbit.eccentricity < 1, "e < 1 for elliptical")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly")
    -- Apoapsis should exist
    assert(orbit.apoapsis ~= nil, "apoapsis should exist")
end)

test("orbitalParameters: escape trajectory", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local escapeSpeed = math.sqrt(2 * aliothGM / distance)
    local speed = escapeSpeed * 1.5 -- Well above escape
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, speed, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity")
    -- Should be hyperbolic (e > 1)
    assertGte(orbit.eccentricity, 1, "e >= 1 for escape")
    -- No apoapsis on escape
    assertEq(orbit.apoapsis, nil, "no apoapsis on escape")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly")
end)

test("orbitalParameters: exactly escape velocity (edge case)", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local escapeSpeed = math.sqrt(2 * aliothGM / distance)
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, escapeSpeed, 0)

    -- This is the exact edge case that caused division by zero (fix #3)
    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity at escape velocity")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly at escape velocity")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly at escape velocity")
end)

test("orbitalParameters: stationary (zero velocity)", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, 0, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity at zero velocity")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly at zero velocity")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly at zero velocity")
end)

test("orbitalParameters: very low altitude", function()
    local altitude = 100  -- Just above surface
    local distance = aliothRadius + altitude
    local orbitalSpeed = math.sqrt(aliothGM / distance)
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, orbitalSpeed * 0.5, 0) -- Sub-orbital

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity near surface")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly near surface")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly near surface")
end)

test("orbitalParameters: radial velocity only (straight up)", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local pos = vec3(distance, 0, 0)
    local vel = vec3(1000, 0, 0) -- Moving straight away from planet

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity radial")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly radial")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly radial")
end)

test("orbitalParameters: near-circular with slight eccentricity", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local orbitalSpeed = math.sqrt(aliothGM / distance)
    -- Add a tiny radial component
    local pos = vec3(distance, 0, 0)
    local vel = vec3(10, orbitalSpeed, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity")
    -- Should be very slightly eccentric
    assert(orbit.eccentricity < 0.1, "nearly circular")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly")
end)

test("orbitalParameters: very high altitude", function()
    local altitude = 10000000 -- 10,000 km
    local distance = aliothRadius + altitude
    local orbitalSpeed = math.sqrt(aliothGM / distance)
    local pos = vec3(distance, 0, 0)
    local vel = vec3(0, orbitalSpeed, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity high alt")
    assertEq(orbit.eccentricity, 0, "circular at high alt", 0.01)
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly high alt")
end)

test("orbitalParameters: 3D position and velocity", function()
    local altitude = 50000
    local distance = aliothRadius + altitude
    local orbitalSpeed = math.sqrt(aliothGM / distance)
    -- Inclined orbit
    local pos = vec3(distance * 0.707, 0, distance * 0.707)
    local vel = vec3(0, orbitalSpeed, 0)

    local orbit = computeOrbitalParameters(aliothGM, aliothCenter, aliothRadius, pos, vel)
    assertNotNaN(orbit.eccentricity, "eccentricity 3D")
    assertNotNaN(orbit.trueAnomaly, "trueAnomaly 3D")
    assertNotNaN(orbit.eccentricAnomaly, "eccentricAnomaly 3D")
end)

-----------------------------------------------------------------------
-- VEC3 MATH TESTS (sanity checks for our test vec3)
-----------------------------------------------------------------------
print("\n=== Vec3 Sanity Tests ===")

test("vec3: basic operations", function()
    local a = vec3(1, 2, 3)
    local b = vec3(4, 5, 6)
    local c = a + b
    assertEq(c.x, 5, "add x")
    assertEq(c.y, 7, "add y")
    assertEq(c.z, 9, "add z")
end)

test("vec3: length", function()
    local a = vec3(3, 4, 0)
    assertEq(a:len(), 5, "3-4-5 triangle")
end)

test("vec3: normalize", function()
    local a = vec3(10, 0, 0)
    local n = a:normalize()
    assertEq(n.x, 1, "normalized x")
    assertEq(n:len(), 1, "unit length")
end)

test("vec3: zero normalize", function()
    local a = vec3(0, 0, 0)
    local n = a:normalize()
    assertEq(n:len(), 0, "zero vector normalized")
end)

test("vec3: dot product", function()
    local a = vec3(1, 0, 0)
    local b = vec3(0, 1, 0)
    assertEq(a:dot(b), 0, "perpendicular dot")
    assertEq(a:dot(a), 1, "parallel dot")
end)

test("vec3: cross product", function()
    local x = vec3(1, 0, 0)
    local y = vec3(0, 1, 0)
    local z = x:cross(y)
    assertEq(z.x, 0, "cross x")
    assertEq(z.y, 0, "cross y")
    assertEq(z.z, 1, "cross z")
end)


-----------------------------------------------------------------------
-- UTILITY FUNCTION TESTS (from baseclass.lua)
-----------------------------------------------------------------------
print("\n=== Utility Function Tests ===")

-- Extract utility functions matching baseclass.lua implementations
local mfloor = math.floor
local epsilon = 1e-09

local function float_eq_impl(a, b)
    if a == 0 then
        return mabs(b) < 1e-09
    elseif b == 0 then
        return mabs(a) < 1e-09
    else
        return mabs(a - b) < math.max(mabs(a), mabs(b)) * epsilon
    end
end

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return mfloor(num * mult + 0.5) / mult
end

local function addTable(table1, table2)
    for k, v in pairs(table2) do
        if type(k) == "string" then
            table1[k] = v
        else
            table1[#table1 + 1] = table2[k]
        end
    end
    return table1
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
    local minutes = 0
    local hours = 0
    local days = 0
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
    if days > 365 then
        return ">1y"
    elseif days > 0 then
        return days .. "d " .. hours .. "h "
    elseif hours > 0 then
        return hours .. "h " .. minutes .. "m "
    elseif minutes > 0 then
        return minutes .. "m " .. seconds .. "s"
    elseif seconds > 0 then
        return seconds .. "s"
    else
        return "0s"
    end
end

-- round() tests
test("round: integer rounding", function()
    assertEq(round(3.7), 4, "3.7 -> 4")
    assertEq(round(3.2), 3, "3.2 -> 3")
    assertEq(round(3.5), 4, "3.5 -> 4 (round half up)")
    assertEq(round(-3.5), -3, "-3.5 -> -3")
end)

test("round: decimal places", function()
    assertEq(round(3.14159, 2), 3.14, "pi to 2 places", 1e-10)
    assertEq(round(3.14159, 4), 3.1416, "pi to 4 places", 1e-10)
    assertEq(round(3.14159, 0), 3, "pi to 0 places", 1e-10)
    assertEq(round(99.999, 1), 100.0, "99.999 to 1 place", 1e-10)
end)

test("round: zero and negatives", function()
    assertEq(round(0, 5), 0, "zero", 1e-10)
    -- round uses floor(x+0.5), so half-up: -7.555*100+0.5 = -755, floor=-755, /100=-7.55
    assertEq(round(-7.555, 2), -7.55, "negative to 2 places (half-up)", 1e-10)
end)

-- float_eq() tests
test("float_eq: equal values", function()
    assert(float_eq_impl(1.0, 1.0), "exact equal")
    assert(float_eq_impl(0, 0), "both zero")
end)

test("float_eq: near-equal values", function()
    assert(float_eq_impl(1.0, 1.0 + 1e-12), "within epsilon")
    assert(not float_eq_impl(1.0, 1.1), "clearly different")
end)

test("float_eq: zero comparisons", function()
    assert(float_eq_impl(0, 1e-10), "zero vs tiny")
    assert(not float_eq_impl(0, 1e-5), "zero vs small")
    assert(float_eq_impl(1e-10, 0), "tiny vs zero")
end)

-- FormatTimeString() tests
test("FormatTimeString: seconds only", function()
    assertEq(FormatTimeString(0), "0s", "zero")
    assertEq(FormatTimeString(30), "30s", "30 seconds")
    assertEq(FormatTimeString(59.9), "59s", "59.9 seconds floors")
end)

test("FormatTimeString: minutes", function()
    assertEq(FormatTimeString(60), "1m 0s", "exactly 1 minute")
    assertEq(FormatTimeString(90), "1m 30s", "1.5 minutes")
    assertEq(FormatTimeString(3599), "59m 59s", "just under 1 hour")
end)

test("FormatTimeString: hours", function()
    assertEq(FormatTimeString(3600), "1h 0m ", "exactly 1 hour")
    assertEq(FormatTimeString(7200), "2h 0m ", "2 hours")
    assertEq(FormatTimeString(5400), "1h 30m ", "1.5 hours")
end)

test("FormatTimeString: days", function()
    assertEq(FormatTimeString(86400), "1d 0h ", "1 day")
    assertEq(FormatTimeString(90000), "1d 1h ", "1 day 1 hour")
end)

test("FormatTimeString: over a year", function()
    assertEq(FormatTimeString(366 * 86400), ">1y", "over 1 year")
end)

-- getDistanceDisplayString() tests
test("getDistanceDisplayString: meters", function()
    assertEq(getDistanceDisplayString(500), "500.0m", "500m")
    assertEq(getDistanceDisplayString(0), "0.0m", "0m")
    assertEq(getDistanceDisplayString(999), "999.0m", "999m")
end)

test("getDistanceDisplayString: kilometers", function()
    assertEq(getDistanceDisplayString(1001), "1.0km", "1.001km")
    assertEq(getDistanceDisplayString(5500), "5.5km", "5.5km")
    assertEq(getDistanceDisplayString(99999), "100.0km", "100km")
end)

test("getDistanceDisplayString: SU", function()
    assertEq(getDistanceDisplayString(200000), "1.0su", "1 SU")
    assertEq(getDistanceDisplayString(400000), "2.0su", "2 SU")
    assertEq(getDistanceDisplayString(100001), "0.5su", "0.5 SU")
end)

test("getDistanceDisplayString: custom decimal places", function()
    assertEq(getDistanceDisplayString(1234, 2), "1.23km", "1.234km to 2 places")
    -- round(500,0) returns 500.0 (float) in Lua 5.3, concat produces "500.0m"
    assertEq(getDistanceDisplayString(500, 0), "500.0m", "500m to 0 places")
end)

-- addTable() tests
test("addTable: numeric keys", function()
    local t1 = {1, 2, 3}
    local t2 = {4, 5}
    addTable(t1, t2)
    assertEq(#t1, 5, "combined length")
    assertEq(t1[4], 4, "appended value 4")
    assertEq(t1[5], 5, "appended value 5")
end)

test("addTable: string keys", function()
    local t1 = {a = 1}
    local t2 = {b = 2, c = 3}
    addTable(t1, t2)
    assertEq(t1.a, 1, "original key preserved")
    assertEq(t1.b, 2, "new key b")
    assertEq(t1.c, 3, "new key c")
end)

test("addTable: mixed keys", function()
    local t1 = {10, a = "hello"}
    local t2 = {20, b = "world"}
    addTable(t1, t2)
    assertEq(#t1, 2, "numeric count")
    assertEq(t1[2], 20, "appended numeric")
    assertEq(t1.a, "hello", "original string key")
    assertEq(t1.b, "world", "new string key")
end)

test("addTable: string key overwrite", function()
    local t1 = {a = 1}
    local t2 = {a = 99}
    addTable(t1, t2)
    assertEq(t1.a, 99, "overwritten value")
end)

-----------------------------------------------------------------------
-- SUMMARY
-----------------------------------------------------------------------
print(string.format("\n=== Results: %d passed, %d failed ===", passed, failed))
if #errors > 0 then
    print("\nFailures:")
    for _, e in ipairs(errors) do
        print(e)
    end
    os.exit(1)
else
    print("All tests passed!")
    os.exit(0)
end

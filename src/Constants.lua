-- src/Constants.lua
-- Centralized constants for ArchHUD-CC
-- Grok suggestion: reduces magic numbers scattered throughout the code
-- Import with: local Constants = require('src.Constants')

local Constants = {
    -- ============================================
    -- Autopilot & Navigation
    -- ============================================
    AUTOPILOT_SPACE_DISTANCE = 5000,          -- meters from custom waypoint
    ATMO_SPEED_LIMIT = 1175,                  -- km/h
    SPACE_SPEED_LIMIT = 66000,                -- km/h
    TARGET_ORBIT_RADIUS = 1.3,                -- multiple of atmospheric height
    LOW_ORBIT_HEIGHT = 2000,                  -- meters above atmosphere
    REENTRY_HEIGHT = 100000,                  -- meters
    
    -- ============================================
    -- Flight Physics & Handling
    -- ============================================
    MAX_PITCH = 30,                           -- degrees
    REENTRY_PITCH_DEFAULT = -30,              -- degrees
    BRAKE_LANDING_RATE = 30,                  -- m/s safe descent
    YAW_STALL_ANGLE_DEFAULT = 35,             -- degrees (tune per ship)
    PITCH_STALL_ANGLE_DEFAULT = 35,           -- degrees (tune per ship)
    
    WARMUP_XS = 0.25,
    WARMUP_S = 1,
    WARMUP_M = 4,
    WARMUP_L = 16,
    WARMUP_XL = 32,
    
    -- ============================================
    -- HUD & Rendering
    -- ============================================
    CIRCLE_RAD_DEFAULT = 400,                 -- pixels for artificial horizon
    HUD_TICK_RATE = 0.0666667,                -- ~15 Hz
    
    -- ============================================
    -- Control & Mouse
    -- ============================================
    MOUSE_X_SENSITIVITY = 0.003,
    MOUSE_Y_SENSITIVITY = 0.003,
    
    -- Add more constants here as needed
}

return Constants

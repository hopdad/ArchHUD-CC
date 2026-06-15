#!/usr/bin/env lua5.3
--- Tree-wide syntax / compile check for ALL tracked Lua source.
---
--- Compiles every tracked *.lua file with loadfile() (parse only, no execution)
--- and reports any syntax errors. This is the portable CI gate that catches the
--- "won't even load" class of bug across the whole codebase — the kind a diff
--- against a known-good branch cannot.
---
--- NOTE: loadfile() only PARSES; it does not execute. So this will NOT catch
--- runtime errors such as nil-global access (e.g. the rejected Constants
--- refactor). Full load-execution would need the vendored DU emulator under
--- src/du/ (gitignored) — tracked separately as the "DU stub harness" idea.
---
--- Run from the repo root:  lua tests/test_syntax.lua

local function listLuaFiles()
    -- Prefer git: it lists tracked files and naturally skips gitignored paths
    -- such as the absent src/du/ emulator. (No stderr redirect — it must work on
    -- both POSIX sh and Windows cmd.exe, which io.popen uses on Windows.)
    local pipe = io.popen("git ls-files \"*.lua\"")
    if pipe then
        local out = pipe:read("*a")
        pipe:close()
        if out and out:match("%S") then
            local files = {}
            for line in out:gmatch("[^\r\n]+") do
                files[#files + 1] = line
            end
            return files
        end
    end
    error("could not list Lua files via 'git ls-files' — run this from the repo root")
end

local files = listLuaFiles()
local passed, failed = 0, 0
local failures = {}

for _, path in ipairs(files) do
    local chunk, err = loadfile(path)
    if chunk then
        passed = passed + 1
    else
        failed = failed + 1
        failures[#failures + 1] = string.format("  FAIL  %s\n    %s", path, tostring(err))
    end
end

print(string.format("=== Syntax check: %d files, %d ok, %d failed ===", #files, passed, failed))
if failed > 0 then
    print("\nSyntax errors:")
    for _, line in ipairs(failures) do print(line) end
    os.exit(1)
end
print("All tracked Lua files parse cleanly.")

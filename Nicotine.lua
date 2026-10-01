--// NICOTINE | Made by: Shaw | Discord: Shaw6000
--// Fixed bugs + Change Device button + Cool PC UI
print("[Nicotine] Loading...")

if getgenv().Nicotine then pcall(getgenv().Nicotine) end
getgenv().Nicotine = function() end

local LOADSTRING = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Shawu7373/Nicotine/main/Nicotine.lua"))()'

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 15)
if not PG then return end

for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "Nicotine" or v.Name == "NicotineSelector" then
        pcall(function() v:Destroy() end)
    end
end

local function notify(t, x, d)
    local ok = pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t or "Nicotine", Text = x or "", Duration = d or 3})
    end)
    if not ok then pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[Nicotine] " .. tostring(t) .. ": " .. tostring(x)})
    end) end
end

local function queueScript()
    if type(queue_on_teleport) == "function" then
        pcall(function() queue_on_teleport(LOADSTRING) end); return true
    elseif type(queueonteleport) == "function" then
        pcall(function() queueonteleport(LOADSTRING) end); return true
    end
    return false
end

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG_FOLDER = "Nicotine"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if type(makefolder) == "function" and type(isfolder) == "function" then
        if not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end
    end
end

local function loadConfig()
    ensureFolder()
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, exists = pcall(isfile, CONFIG_FILE)
        if ok and exists then
            local ok2, content = pcall(readfile, CONFIG_FILE)
            if ok2 then
                local ok3, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                if ok3 and type(decoded) == "table" then return decoded end
            end
        end
    end
    return {}
end

local function saveConfig(t)
    ensureFolder()
    if type(writefile) == "function" then
        local ok, encoded = pcall(function() return HttpService:JSONEncode(t) end)
        if ok then pcall(writefile, CONFIG_FILE, encoded); return true end
    end
    return false
end

local saved = loadConfig()

-- ============================================================
-- STATE
-- ============================================================
local S = {
    InfJump = saved.InfJump or false,
    ESP = saved.ESP or false,
    AntiKick = saved.AntiKick or false,
    AntiAFK = saved.AntiAFK or false,
    AutoGrab = saved.AutoGrab or false,
    PlatformSize = saved.PlatformSize or 50,
    Device = saved.Device or nil,
    Conn = {}, ESPObjects = {}, PlacedParts = {},
    CanInfJump = true, IsGrabbing = false,
    AutoGrabKey = Enum.KeyCode.F
}

local function saveCurrentState()
    saveConfig({
        InfJump = S.InfJump, ESP = S.ESP, AntiKick = S.AntiKick,
        AntiAFK = S.AntiAFK, AutoGrab = S.AutoGrab,
        PlatformSize = S.PlatformSize, Device = S.Device
    })
end

local function getChar() return LP.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getBP() return LP:FindFirstChild("Backpack") end
local function trk(c) table.insert(S.Conn, c); return c end

-- ============================================================
-- ANTI-CHEAT / ANTI-KICK / ANTI-AFK
-- ============================================================
local function applyAntiKick()
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and S.AntiKick then
                notify("Anti-Cheat", "Kick attempt blocked!", 3)
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function setupAntiAFK()
    trk(LP.Idled:Connect(function()
        if S.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end))
end

-- ============================================================
-- F3X
-- ============================================================
local TOOL_KW = {"building","f3x","btool","b tool","hammer","move","clone","destroy","import","wrench","lpi","resize"}
local GIVER_KW = {"giver","f3x","btool","b tool","building","wrench","lpi","import"}

local function isF3XTool(o)
    if not o or not o:IsA("Tool") then return false end
    local n = o.Name:lower()
    for _, kw in ipairs(TOOL_KW) do if n:find(kw) then return true end end
    return false
end

local function hasF3X()
    local c = LP.Character
    if c then for _, o in ipairs(c:GetChildren()) do if isF3XTool(o) then return o end end end
    local bp = getBP()
    if bp then for _, o in ipairs(bp:GetChildren()) do if isF3XTool(o) then return o end end end
    return nil
end

local function equipF3X()
    local t = hasF3X()
    if not t then return false end
    local h = getHum()
    if h then pcall(function() h:EquipTool(t) end); return true end
    return false
end

local function getF3XRemotes()
    local tool = hasF3X()
    if not tool then return nil, nil end
    local invokeRemote, eventRemote = nil, nil
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("server") or n:find("invoke") or n:find("sync") or n:find("endpoint") then invokeRemote = obj end
        elseif obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("server") or n:find("event") or n:find("sync") or n:find("endpoint") then eventRemote = obj end
        end
    end
    if not invokeRemote and not eventRemote then
        for _, obj in ipairs(tool:GetDescendants()) do
            if obj:IsA("RemoteFunction") then invokeRemote = obj; break end
            if obj:IsA("RemoteEvent") then eventRemote = obj; break end
        end
    end
    return invokeRemote, eventRemote
end

local function sendF3XCommand(command, args)
    local inv, ev = getF3XRemotes()
    if inv then pcall(function() inv:InvokeServer(command, args) end); return true
    elseif ev then pcall(function() ev:FireServer(command, args) end); return true end
    return false
end

-- ============================================================
-- HELPERS
-- ============================================================
local function makePart(size, color, transparency, material)
    local part = Instance.new("Part")
    part.Size = size; part.Anchored = true; part.CanCollide = true
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color or Color3.fromRGB(120, 120, 130)
    part.Transparency = transparency or 0
    part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = Workspace
    table.insert(S.PlacedParts, part)
    return part
end

local function makePartAt(pos, size, color, transparency, material)
    local p = makePart(size, color, transparency, material); p.Position = pos; return p
end

-- ============================================================
-- PLATFORM
-- ============================================================
local function platformAtMe(above)
    local root = getRoot()
    if not root then notify("Platform", "No character", 2); return end
    local size = S.PlatformSize or 50
    local pos = above and (root.Position + Vector3.new(0, 12, 0)) or (root.Position + Vector3.new(0, -4, 0))
    local inv, ev = getF3XRemotes()
    if inv or ev then
        sendF3XCommand("New", {{
            Size = Vector3.new(size, 3, size), CFrame = CFrame.new(pos),
            Color = Color3.fromRGB(255, 200, 0), Anchored = true,
            Material = "SmoothPlastic", Name = "NicotinePlatform_" .. tostring(math.random(1000, 9999))
        }})
        notify("Platform", "Server-sided Square spawned!", 3)
    else
        local part = makePart(Vector3.new(size, 3, size), Color3.fromRGB(255, 200, 0), 0.15)
        part.Position = pos
        notify("Platform", "Local Square spawned. Grab F3X for server-sided!", 5)
    end
end

local function circlePlatformAtMe(above)
    local root = getRoot()
    if not root then notify("Platform", "No character", 2); return end
    local size = S.PlatformSize or 50
    local pos = above and (root.Position + Vector3.new(0, 12, 0)) or (root.Position + Vector3.new(0, -4, 0))
    local inv, ev = getF3XRemotes()
    if inv or ev then
        sendF3XCommand("New", {{
            Size = Vector3.new(3, size, size), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
            Color = Color3.fromRGB(100, 200, 255), Anchored = true,
            Material = "SmoothPlastic", Shape = "Cylinder", Name = "NicotineCirclePlatform_" .. tostring(math.random(1000, 9999))
        }})
        notify("Platform", "Server-sided Circle spawned!", 3)
    else
        local cylinder = Instance.new("Part")
        cylinder.Shape = Enum.PartType.Cylinder
        cylinder.Size = Vector3.new(3, size, size)
        cylinder.Anchored = true; cylinder.CanCollide = true
        cylinder.Material = Enum.Material.SmoothPlastic
        cylinder.Color = Color3.fromRGB(100, 200, 255); cylinder.Transparency = 0.15
        cylinder.TopSurface = Enum.SurfaceType.Smooth; cylinder.BottomSurface = Enum.SurfaceType.Smooth
        cylinder.Parent = Workspace
        table.insert(S.PlacedParts, cylinder)
        cylinder.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
        notify("Platform", "Local Circle spawned. Grab F3X for server-sided!", 5)
    end
end

local function clearPlatforms()
    local n = 0
    for _, p in ipairs(S.PlacedParts) do
        if p and p.Parent then pcall(function() p:Destroy() end); n = n + 1 end
    end
    S.PlacedParts = {}
    notify("Platform", "Cleared " .. n .. " local parts", 3)
end

-- ============================================================
-- BUILDS
-- ============================================================
local function spawnHouse()
    local root = getRoot(); if not root then return end
    local base = root.Position + Vector3.new(0, 20, 0)
    local wall = Color3.fromRGB(220, 200, 160); local roof = Color3.fromRGB(180, 60, 60)
    local floor = Color3.fromRGB(120, 90, 60); local door = Color3.fromRGB(90, 60, 30)
    local win = Color3.fromRGB(150, 210, 255)
    makePartAt(base, Vector3.new(30, 1, 30), floor, 0)
    makePartAt(base + Vector3.new(0, 8, -15), Vector3.new(30, 16, 1), wall, 0)
    makePartAt(base + Vector3.new(-15, 8, 0), Vector3.new(1, 16, 30), wall, 0)
    makePartAt(base + Vector3.new(15, 8, 0), Vector3.new(1, 16, 30), wall, 0)
    makePartAt(base + Vector3.new(-9, 8, 15), Vector3.new(12, 16, 1), wall, 0)
    makePartAt(base + Vector3.new(9, 8, 15), Vector3.new(12, 16, 1), wall, 0)
    makePartAt(base + Vector3.new(0, 13, 15), Vector3.new(6, 6, 1), wall, 0)
    makePartAt(base + Vector3.new(0, 5, 15), Vector3.new(5, 10, 0.5), door, 0)
    makePartAt(base + Vector3.new(0, 10, -15), Vector3.new(8, 6, 0.5), win, 0.3)
    makePartAt(base + Vector3.new(-15, 10, 0), Vector3.new(0.5, 6, 8), win, 0.3)
    makePartAt(base + Vector3.new(15, 10, 0), Vector3.new(0.5, 6, 8), win, 0.3)
    makePartAt(base + Vector3.new(0, 17, 0), Vector3.new(32, 2, 32), roof, 0)
    makePartAt(base + Vector3.new(0, 20, 0), Vector3.new(24, 2, 24), roof, 0)
    notify("Builds", "House spawned", 2)
end

local function spawnTower()
    local root = getRoot(); if not root then return end
    local pos = root.Position + Vector3.new(0, 30, 0)
    local stone = Color3.fromRGB(140, 140, 150); local top = Color3.fromRGB(200, 180, 100)
    for i = 0, 4 do
        local y = pos.Y + (i * 18)
        makePartAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(20, 1, 20), stone, 0)
        makePartAt(Vector3.new(pos.X, y+8, pos.Z-10), Vector3.new(20, 16, 1), stone, 0)
        makePartAt(Vector3.new(pos.X, y+8, pos.Z+10), Vector3.new(20, 16, 1), stone, 0)
        makePartAt(Vector3.new(pos.X-10, y+8, pos.Z), Vector3.new(1, 16, 20), stone, 0)
        makePartAt(Vector3.new(pos.X+10, y+8, pos.Z), Vector3.new(1, 16, 20), stone, 0)
        makePartAt(Vector3.new(pos.X, y+16, pos.Z), Vector3.new(20, 1, 20), stone, 0)
    end
    makePartAt(Vector3.new(pos.X, pos.Y + 92, pos.Z), Vector3.new(24, 2, 24), top, 0)
    notify("Builds", "Tower spawned", 2)
end

local function spawnBridge()
    local root = getRoot(); if not root then return end
    local pos = root.Position + Vector3.new(0, 20, 0)
    local wood = Color3.fromRGB(140, 90, 50); local rail = Color3.fromRGB(100, 60, 30)
    makePartAt(pos, Vector3.new(60, 1, 10), wood, 0)
    makePartAt(pos + Vector3.new(0, 3, -5), Vector3.new(60, 5, 0.5), rail, 0)
    makePartAt(pos + Vector3.new(0, 3, 5), Vector3.new(60, 5, 0.5), rail, 0)
    for x = -25, 25, 25 do
        makePartAt(pos + Vector3.new(x, -15, -4), Vector3.new(3, 30, 3), wood, 0)
        makePartAt(pos + Vector3.new(x, -15, 4), Vector3.new(3, 30, 3), wood, 0)
    end
    notify("Builds", "Bridge spawned", 2)
end

local function spawnPyramid()
    local root = getRoot(); if not root then return end
    local base = root.Position + Vector3.new(0, 10, 0)
    local gold = Color3.fromRGB(230, 190, 80)
    for i = 0, 9 do
        local s = 40 - (i * 4); if s <= 0 then break end
        makePartAt(Vector3.new(base.X, base.Y + i * 3, base.Z), Vector3.new(s, 3, s), gold, 0)
    end
    notify("Builds", "Pyramid spawned", 2)
end

local function spawnWall()
    local root = getRoot(); if not root then return end
    local pos = root.Position + root.CFrame.LookVector * 20 + Vector3.new(0, 10, 0)
    local stone = Color3.fromRGB(160, 160, 170)
    local wall = makePartAt(pos, Vector3.new(40, 20, 2), stone, 0)
    wall.CFrame = CFrame.new(pos, pos + root.CFrame.LookVector)
    for x = -18, 18, 6 do
        local b = makePartAt(pos + Vector3.new(x, 12, 0), Vector3.new(3, 4, 2), stone, 0)
        b.CFrame = CFrame.new(b.Position, b.Position + root.CFrame.LookVector)
    end
    notify("Builds", "Wall spawned", 2)
end

local function spawnFountain()
    local root = getRoot(); if not root then return end
    local base = root.Position + Vector3.new(0, 5, 0)
    local stone = Color3.fromRGB(180, 180, 190); local water = Color3.fromRGB(100, 180, 255)
    local pool = makePart(Vector3.new(30, 4, 30), stone, 0)
    pool.Shape = Enum.PartType.Cylinder
    pool.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90))
    local w = makePart(Vector3.new(29, 0.5, 29), water, 0.3)
    w.Shape = Enum.PartType.Cylinder
    w.CFrame = CFrame.new(base + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
    makePartAt(base + Vector3.new(0, 15, 0), Vector3.new(4, 20, 4), stone, 0)
    local top = makePart(Vector3.new(15, 3, 15), stone, 0)
    top.Shape = Enum.PartType.Cylinder
    top.CFrame = CFrame.new(base + Vector3.new(0, 26, 0)) * CFrame.Angles(0, 0, math.rad(90))
    notify("Builds", "Fountain spawned", 2)
end

-- ============================================================
-- F3X GRABBER
-- ============================================================
local function partMatches(o)
    if not o or not o:IsA("BasePart") then return false end
    local n = o.Name:lower()
    for _, kw in ipairs(GIVER_KW) do if n:find(kw) then return true end end
    for _, ch in ipairs(o:GetChildren()) do
        local cn = ch.Name:lower()
        for _, kw in ipairs(GIVER_KW) do if cn:find(kw) then return true end end
    end
    return false
end

local function findGivers()
    local f = {}; local count = 0
    for _, o in ipairs(Workspace:GetDescendants()) do
        count = count + 1
        if partMatches(o) then table.insert(f, o) end
        if count % 500 == 0 then task.wait() end
    end
    return f
end

local function touch(giver)
    local r = getRoot()
    if not r or not giver then return false end
    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(giver, r, 0)
            task.wait(0.05)
            firetouchinterest(giver, r, 1)
        end)
        return true
    end
    return false
end

local function grabAndReturn()
    if S.IsGrabbing then return end
    S.IsGrabbing = true
    local root = getRoot()
    if not root then S.IsGrabbing = false; notify("Nicotine", "No character", 2); return end
    if hasF3X() then equipF3X(); S.IsGrabbing = false; notify("Nicotine", "Already have F3X", 2); return end
    notify("Nicotine", "Scanning map for Givers...", 3)
    local givers = findGivers()
    if #givers == 0 then S.IsGrabbing = false; notify("Nicotine", "No giver found", 4); return end
    local saved2 = root.CFrame
    notify("Nicotine", "Found " .. #givers .. " givers. Grabbing...", 2)
    for _, g in ipairs(givers) do
        pcall(function() root.CFrame = g.CFrame + Vector3.new(0, 1, 0) end)
        task.wait(0.2); touch(g); task.wait(0.3)
        if hasF3X() then
            equipF3X(); task.wait(0.2)
            pcall(function() root.CFrame = saved2 end)
            notify("Nicotine", "F3X grabbed!", 3)
            S.IsGrabbing = false; return
        end
    end
    pcall(function() root.CFrame = saved2 end)
    S.IsGrabbing = false
    notify("Nicotine", "Failed. Try again.", 4)
end

-- ============================================================
-- BTOOLS GRABBER
-- ============================================================
local function findBtoolsSources()
    local givers, templates = {}, {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("btool") or n:find("b tool") or n:find("building tool") or
               n:find("b-tool") or n:find("brick tool") then
                table.insert(givers, obj)
            end
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if pp then
                local a = (pp.ActionText .. " " .. pp.ObjectText):lower()
                if a:find("btool") or a:find("building tool") or a:find("get tool") then
                    table.insert(givers, obj)
                end
            end
            local cd = obj:FindFirstChildOfClass("ClickDetector")
            if cd and (n:find("giver") or n:find("btool") or n:find("tool")) then
                table.insert(givers, obj)
            end
        end
        if obj:IsA("Tool") and isF3XTool(obj) then
            table.insert(givers, obj)
        end
    end
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("btool") or n:find("b tool") or n:find("building tool") or
               n:find("hammer") or n:find("wrench") or n:find("resize") or
               n:find("move") or n:find("clone") or n:find("destroy") then
                table.insert(templates, obj)
            end
        end
    end
    return givers, templates
end

local function grabBtools()
    if S.IsGrabbing then return end
    S.IsGrabbing = true
    local root = getRoot()
    if not root then S.IsGrabbing = false; notify("Btools", "No character", 2); return end
    if hasF3X() then equipF3X(); S.IsGrabbing = false; notify("Btools", "Already have Btools!", 2); return end
    notify("Btools", "Deep-scanning game code...", 3)
    local givers, templates = findBtoolsSources()
    if #givers == 0 and #templates == 0 then
        notify("Btools", "No Btools found in this game", 5)
        S.IsGrabbing = false; return
    end
    notify("Btools", "Found " .. #givers .. " givers, " .. #templates .. " templates", 3)
    local savedPos = root.CFrame
    for _, giver in ipairs(givers) do
        pcall(function() root.CFrame = giver.CFrame + Vector3.new(0, 2, 0) end)
        task.wait(0.25)
        local pp = giver:FindFirstChildOfClass("ProximityPrompt")
        if pp then
            pcall(function()
                pp:InputHoldBegin()
                task.wait((pp.HoldDuration or 0) + 0.15)
                pp:InputHoldEnd()
            end)
            task.wait(0.2)
        end
        local cd = giver:FindFirstChildOfClass("ClickDetector")
        if cd and type(fireclickdetector) == "function" then
            pcall(function() fireclickdetector(cd) end)
            task.wait(0.2)
        end
        touch(giver)
        task.wait(0.3)
        if hasF3X() then
            equipF3X()
            pcall(function() root.CFrame = savedPos end)
            notify("Btools", "Btools grabbed!", 3)
            S.IsGrabbing = false; return
        end
    end
    pcall(function() root.CFrame = savedPos end)
    S.IsGrabbing = false
    notify("Btools", "Grab failed. Try manually touching the giver.", 5)
end

-- ============================================================
-- AUTO GRAB LOOP
-- ============================================================
task.spawn(function()
    while getgenv().Nicotine do
        task.wait(10)
        if S.AutoGrab and not S.IsGrabbing and not hasF3X() then
            task.spawn(grabAndReturn)
        end
    end
end)

-- ============================================================
-- GRIEFING
-- ============================================================
local function massDelete()
    local inv, ev = getF3XRemotes()
    if not inv and not ev then notify("Grief", "F3X not equipped.", 3); return end
    notify("Grief", "Mass deleting...", 3)
    local count = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChildOfClass("Humanoid") and part.Name ~= "HumanoidRootPart" then
            sendF3XCommand("Remove", {part})
            count = count + 1
            if count % 10 == 0 then task.wait(0.05) end
        end
    end
    notify("Grief", "Deleted " .. count .. " parts!", 3)
end

local function unanchorAll()
    local inv, ev = getF3XRemotes()
    if not inv and not ev then notify("Grief", "F3X not equipped.", 3); return end
    notify("Grief", "Unanchoring...", 3)
    local count = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChildOfClass("Humanoid") and part.Name ~= "HumanoidRootPart" then
            sendF3XCommand("SyncAnchor", {{Part = part, Anchored = false}})
            count = count + 1
            if count % 10 == 0 then task.wait(0.05) end
        end
    end
    notify("Grief", "Unanchored " .. count .. " parts!", 3)
end

local function flingParts()
    local inv, ev = getF3XRemotes()
    if not inv and not ev then notify("Grief", "F3X not equipped.", 3); return end
    notify("Grief", "Flinging...", 3)
    local count = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChildOfClass("Humanoid") and part.Name ~= "HumanoidRootPart" then
            sendF3XCommand("SyncAnchor", {{Part = part, Anchored = false}})
            pcall(function() part.Velocity = Vector3.new(math.random(-500,500), math.random(200,800), math.random(-500,500)) end)
            count = count + 1
            if count % 10 == 0 then task.wait(0.05) end
        end
    end
    notify("Grief", "Flinged " .. count .. " parts!", 3)
end

local function voidAll()
    local inv, ev = getF3XRemotes()
    if not inv and not ev then notify("Grief", "F3X not equipped.", 3); return end
    notify("Grief", "Voiding...", 3)
    local count = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChildOfClass("Humanoid") and part.Name ~= "HumanoidRootPart" then
            sendF3XCommand("SyncMove", {{Part = part, CFrame = CFrame.new(part.Position.X, -5000, part.Position.Z)}})
            count = count + 1
            if count % 10 == 0 then task.wait(0.05) end
        end
    end
    notify("Grief", "Voided " .. count .. " parts!", 3)
end

local function antiF3X()
    notify("Grief", "Hiding others' tools locally", 3)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            pcall(function()
                if player.Character then
                    for _, tool in ipairs(player.Character:GetChildren()) do
                        if isF3XTool(tool) then tool.Parent = nil end
                    end
                end
            end)
        end
    end
    notify("Grief", "Done!", 3)
end

-- ============================================================
-- SERVER
-- ============================================================
local function serverHop()
    saveCurrentState()
    if queueScript() then notify("Nicotine", "Will auto-reload after hop", 3) end
    task.wait(0.3)
    notify("Nicotine", "Finding most popular server...", 3)
    local ok, err = pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Desc")
        local data = HttpService:JSONDecode(req)
        if not data or not data.data then error("No server data") end
        local best, bestCount = nil, -1
        for _, srv in ipairs(data.data) do
            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                if srv.playing > bestCount then best = srv; bestCount = srv.playing end
            end
        end
        if not best then error("No available servers") end
        notify("Nicotine", "Joining server with " .. best.playing .. " players", 3)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LP)
    end)
    if not ok then notify("Nicotine", "Hop failed: " .. tostring(err), 4) end
end

local function rejoinServer()
    saveCurrentState(); queueScript()
    notify("Nicotine", "Rejoining...", 2); task.wait(0.3)
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
end

-- ============================================================
-- INFINITE JUMP
-- ============================================================
trk(UIS.JumpRequest:Connect(function()
    if not S.InfJump then return end
    local h = getHum(); if not h then return end
    local state = h:GetState()
    if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
        if S.CanInfJump then
            S.CanInfJump = false
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
            task.delay(0.15, function() S.CanInfJump = true end)
        end
    end
end))

-- ============================================================
-- ESP
-- ============================================================
local cleanESP = nil
local function makeESP(target, color)
    if not target or S.ESPObjects[target] then return end
    local root = target:FindFirstChild("HumanoidRootPart"); if not root then return end
    local hl = Instance.new("Highlight")
    hl.Name = "NicotineESP"; hl.Adornee = target
    hl.FillColor = color; hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 0
    hl.Parent = target
    local bb = Instance.new("BillboardGui")
    bb.Name = "NicotineESPLabel"; bb.Adornee = root
    bb.Size = UDim2.new(0, 200, 0, 40); bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true; bb.Parent = target
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0; lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold; lbl.Text = target.Name
    lbl.Parent = bb
    S.ESPObjects[target] = {hl = hl, bb = bb, lbl = lbl}
end

local function removeESP(target)
    if S.ESPObjects[target] then
        pcall(function() S.ESPObjects[target].hl:Destroy() end)
        pcall(function() S.ESPObjects[target].bb:Destroy() end)
        S.ESPObjects[target] = nil
    end
end

cleanESP = function()
    local snap = {}
    for t in pairs(S.ESPObjects) do table.insert(snap, t) end
    for _, t in ipairs(snap) do removeESP(t) end
    S.ESPObjects = {}
end

task.spawn(function()
    while getgenv().Nicotine do
        task.wait(0.5)
        for t in pairs(S.ESPObjects) do
            if not t or not t.Parent then removeESP(t) end
        end
        if S.ESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    makeESP(p.Character, Color3.fromRGB(255, 100, 100))
                    local e = S.ESPObjects[p.Character]
                    if e and e.lbl then
                        local r = getRoot()
                        local tr = p.Character:FindFirstChild("HumanoidRootPart")
                        if r and tr then
                            e.lbl.Text = p.Name .. " | " .. math.floor((r.Position - tr.Position).Magnitude) .. "m"
                        end
                    end
                end
            end
        else
            for t in pairs(S.ESPObjects) do
                if t:IsA("Model") then removeESP(t) end
            end
        end
    end
end)

-- ============================================================
-- PC KEYBINDS
-- ============================================================
trk(UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == S.AutoGrabKey then task.spawn(grabAndReturn) end
    if input.KeyCode == Enum.KeyCode.H then
        S.ESP = not S.ESP
        if not S.ESP and cleanESP then cleanESP() end
        saveCurrentState()
    end
    if input.KeyCode == Enum.KeyCode.J then
        S.InfJump = not S.InfJump; saveCurrentState()
    end
end))

-- ============================================================
-- DEVICE SELECTOR (FIXED - RETURNS VALUE CORRECTLY)
-- ============================================================
local function showDeviceSelector()
    local chosen = nil
    local sg = Instance.new("ScreenGui")
    sg.Name = "NicotineSelector"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = PG

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0; overlay.Parent = sg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
    frame.BorderSizePixel = 0; frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(120, 80, 200); stroke.Thickness = 2

    local grad = Instance.new("UIGradient", frame)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 22, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 16, 28))
    })
    grad.Rotation = 135

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50); title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1; title.Text = "NICOTINE"
    title.TextColor3 = Color3.fromRGB(200, 160, 255)
    title.Font = Enum.Font.GothamBold; title.TextSize = 30; title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -40, 0, 30); sub.Position = UDim2.new(0, 20, 0, 65)
    sub.BackgroundTransparency = 1
    sub.Text = "What device are you on?"
    sub.TextColor3 = Color3.fromRGB(200, 200, 210)
    sub.Font = Enum.Font.Gotham; sub.TextSize = 15; sub.Parent = frame

    local function makeBtn(text, yPos, color1, color2, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -50, 0, 60)
        btn.Position = UDim2.new(0, 25, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
        btn.Text = ""; btn.AutoButtonColor = false
        btn.BorderSizePixel = 0; btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local bGrad = Instance.new("UIGradient", btn)
        bGrad.Color = ColorSequence.new(color1, color2)
        bGrad.Rotation = 45
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = color1; bStroke.Thickness = 1.5

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 18; lbl.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(1, -40, 0, 64)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(1, -50, 0, 60)}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            if chosen then return end
            chosen = key
            S.Device = key
            saveCurrentState()
            sg:Destroy()
        end)
    end

    makeBtn("📱  Mobile (Phone / Tablet)", 110, Color3.fromRGB(90, 110, 220), Color3.fromRGB(140, 80, 220), "mobile")
    makeBtn("💻  PC / Laptop", 185, Color3.fromRGB(60, 160, 110), Color3.fromRGB(40, 120, 90), "pc")

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -40, 0, 18); hint.Position = UDim2.new(0, 20, 0, 262)
    hint.BackgroundTransparency = 1
    hint.Text = "You can change this later in the Credits tab."
    hint.TextColor3 = Color3.fromRGB(140, 140, 150)
    hint.Font = Enum.Font.Gotham; hint.TextSize = 11; hint.Parent = frame

    while not chosen do task.wait(0.1) end
    return chosen
end

-- ============================================================
-- MOBILE UI (RAYFIELD)
-- ============================================================
local RayfieldInstance = nil
local function buildMobileUI()
    local Rayfield
    local srcs = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/Footagesus/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/luau-libraries/Rayfield/main/source.lua"
    }
    for i, u in ipairs(srcs) do
        local ok, res = pcall(function()
            local s = game:HttpGet(u)
            if not s or #s < 100 then error("empty") end
            return loadstring(s)()
        end)
        local lib = res
        if not (lib and type(lib) == "table" and lib.CreateWindow) then lib = getgenv().Rayfield end
        if not (lib and type(lib) == "table" and lib.CreateWindow) then lib = rawget(_G, "Rayfield") end
        if lib and type(lib) == "table" and lib.CreateWindow then Rayfield = lib; break end
    end
    if not Rayfield then notify("Nicotine", "Rayfield failed", 6); return nil end
    RayfieldInstance = Rayfield

    local Window = Rayfield:CreateWindow({
        Name = "Nicotine", LoadingTitle = "Nicotine", LoadingSubtitle = "Mobile",
        KeySystem = false, ToggleUIKeybind = "K"
    })

    local MainTab = Window:CreateTab("Main", 4483362458)
    local GriefTab = Window:CreateTab("Grief", 4483362458)
    local PlatformTab = Window:CreateTab("Platform", 4483362458)
    local BuildsTab = Window:CreateTab("Builds", 4483362458)
    local CreditsTab = Window:CreateTab("Credits", 4483362458)

    MainTab:CreateSection("F3X / Btools")
    MainTab:CreateButton({Name = "Grab F3X & Return", Callback = function() task.spawn(grabAndReturn) end})
    MainTab:CreateButton({Name = "Grab Btools & Return", Callback = function() task.spawn(grabBtools) end})
    MainTab:CreateToggle({Name = "Auto Grab (every 10s)", CurrentValue = S.AutoGrab, Flag = "AutoGrabToggle",
        Callback = function(v) S.AutoGrab = v; saveCurrentState() end})
    MainTab:CreateSection("Movement")
    MainTab:CreateToggle({Name = "Infinite Jump", CurrentValue = S.InfJump, Flag = "InfJumpToggle",
        Callback = function(v) S.InfJump = v; saveCurrentState() end})
    MainTab:CreateSection("Visual")
    MainTab:CreateToggle({Name = "Player ESP", CurrentValue = S.ESP, Flag = "ESPToggle",
        Callback = function(v) S.ESP = v; if not v and cleanESP then cleanESP() end; saveCurrentState() end})
    MainTab:CreateSection("Anti-Cheat")
    MainTab:CreateToggle({Name = "Anti-Kick", CurrentValue = S.AntiKick, Flag = "AntiKickToggle",
        Callback = function(v) S.AntiKick = v; saveCurrentState() end})
    MainTab:CreateToggle({Name = "Anti-AFK", CurrentValue = S.AntiAFK, Flag = "AntiAFKToggle",
        Callback = function(v) S.AntiAFK = v; saveCurrentState() end})
    MainTab:CreateSection("Server")
    MainTab:CreateButton({Name = "Hop to Most Popular", Callback = function() serverHop() end})
    MainTab:CreateButton({Name = "Rejoin Server", Callback = function() rejoinServer() end})

    GriefTab:CreateSection("F3X Griefing")
    GriefTab:CreateButton({Name = "Mass Delete", Callback = function() massDelete() end})
    GriefTab:CreateButton({Name = "Unanchor All", Callback = function() unanchorAll() end})
    GriefTab:CreateButton({Name = "Fling Parts", Callback = function() flingParts() end})
    GriefTab:CreateButton({Name = "Void All", Callback = function() voidAll() end})
    GriefTab:CreateSection("Defense")
    GriefTab:CreateButton({Name = "Anti-F3X", Callback = function() antiF3X() end})

    PlatformTab:CreateSection("Size")
    PlatformTab:CreateSlider({Name = "Platform Size", Range = {10, 1000}, Increment = 25, Suffix = "studs",
        CurrentValue = S.PlatformSize, Flag = "PlatformSize",
        Callback = function(v) S.PlatformSize = v; saveCurrentState() end})
    PlatformTab:CreateSection("Square")
    PlatformTab:CreateButton({Name = "Square Below Me", Callback = function() platformAtMe(false) end})
    PlatformTab:CreateButton({Name = "Square Above Me", Callback = function() platformAtMe(true) end})
    PlatformTab:CreateSection("Circle")
    PlatformTab:CreateButton({Name = "Circle Below Me", Callback = function() circlePlatformAtMe(false) end})
    PlatformTab:CreateButton({Name = "Circle Above Me", Callback = function() circlePlatformAtMe(true) end})
    PlatformTab:CreateSection("Control")
    PlatformTab:CreateButton({Name = "Clear Local Platforms", Callback = function() clearPlatforms() end})

    BuildsTab:CreateSection("Builds")
    BuildsTab:CreateButton({Name = "Spawn House", Callback = function() spawnHouse() end})
    BuildsTab:CreateButton({Name = "Spawn Tower", Callback = function() spawnTower() end})
    BuildsTab:CreateButton({Name = "Spawn Bridge", Callback = function() spawnBridge() end})
    BuildsTab:CreateButton({Name = "Spawn Pyramid", Callback = function() spawnPyramid() end})
    BuildsTab:CreateButton({Name = "Spawn Wall", Callback = function() spawnWall() end})
    BuildsTab:CreateButton({Name = "Spawn Fountain", Callback = function() spawnFountain() end})
    BuildsTab:CreateButton({Name = "Clear All Builds", Callback = function() clearPlatforms() end})

    CreditsTab:CreateSection("Credits")
    CreditsTab:CreateParagraph({Title = "Creator", Content = "Shaw"})
    CreditsTab:CreateParagraph({Title = "Discord", Content = "Shaw6000"})
    CreditsTab:CreateSection("Settings")
    CreditsTab:CreateButton({Name = "Change Device (reloads UI)", Callback = function()
        S.Device = nil; saveCurrentState()
        notify("Nicotine", "Device reset. Re-execute to pick again.", 4)
        task.wait(1)
        if RayfieldInstance then pcall(function() RayfieldInstance:Destroy() end) end
        task.spawn(function()
            local c = showDeviceSelector()
            if c == "mobile" then buildMobileUI()
            elseif c == "pc" then buildPCUI() end
        end)
    end})

    return Rayfield
end

-- ============================================================
-- COOL PC UI
-- ============================================================
local pcUIInstance = nil

local function buildPCUI()
    -- palette
    local BG_DARK = Color3.fromRGB(14, 12, 20)
    local BG_MID = Color3.fromRGB(22, 18, 32)
    local BG_PANEL = Color3.fromRGB(28, 22, 44)
    local BG_HOVER = Color3.fromRGB(42, 32, 66)
    local ACCENT = Color3.fromRGB(160, 100, 255)
    local ACCENT2 = Color3.fromRGB(220, 100, 200)
    local TEXT = Color3.fromRGB(230, 225, 245)
    local TEXT_DIM = Color3.fromRGB(140, 130, 170)

    local sg = Instance.new("ScreenGui")
    sg.Name = "Nicotine"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = PG

    -- ambient glow behind window
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(0, 680, 0, 500)
    glow.Position = UDim2.new(0.5, -340, 0.5, -250)
    glow.BackgroundColor3 = ACCENT
    glow.BackgroundTransparency = 0.9
    glow.BorderSizePixel = 0; glow.ZIndex = 0; glow.Parent = sg
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 24)

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 660, 0, 480)
    win.Position = UDim2.new(0.5, -330, 0.5, -240)
    win.BackgroundColor3 = BG_DARK; win.BorderSizePixel = 0
    win.Active = true; win.Draggable = true
    win.ZIndex = 1; win.Parent = sg
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 14)
    local winStroke = Instance.new("UIStroke", win)
    winStroke.Color = ACCENT; winStroke.Thickness = 1.5
    winStroke.Transparency = 0.4

    local winGrad = Instance.new("UIGradient", win)
    winGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, BG_MID),
        ColorSequenceKeypoint.new(0.5, BG_DARK),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 12, 26))
    })
    winGrad.Rotation = 135

    -- animated top bar (gradient shifting)
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1, 0, 0, 44); tb.BackgroundColor3 = BG_MID
    tb.BorderSizePixel = 0; tb.ZIndex = 2; tb.Parent = win
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 14)
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 14); tbFix.Position = UDim2.new(0, 0, 1, -14)
    tbFix.BackgroundColor3 = BG_MID; tbFix.BorderSizePixel = 0; tbFix.ZIndex = 2; tbFix.Parent = tb
    local tbGrad = Instance.new("UIGradient", tb)
    tbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 30, 90)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 22, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 90))
    })
    tbGrad.Rotation = 0

    -- animated gradient shift
    task.spawn(function()
        local t = 0
        while win.Parent do
            t = t + 0.01
            tbGrad.Rotation = (math.sin(t) * 30) + 30
            task.wait(0.05)
        end
    end)

    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 26, 0, 26); logo.Position = UDim2.new(0, 14, 0, 9)
    logo.BackgroundColor3 = ACCENT; logo.BorderSizePixel = 0; logo.ZIndex = 3
    logo.Parent = tb
    Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 8)
    local logoTxt = Instance.new("TextLabel")
    logoTxt.Size = UDim2.new(1, 0, 1, 0); logoTxt.BackgroundTransparency = 1
    logoTxt.Text = "N"; logoTxt.TextColor3 = Color3.fromRGB(255,255,255)
    logoTxt.Font = Enum.Font.GothamBlack; logoTxt.TextSize = 14
    logoTxt.ZIndex = 4; logoTxt.Parent = logo

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 250, 1, 0); title.Position = UDim2.new(0, 48, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Nicotine"; title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold; title.TextSize = 16
    title.ZIndex = 3; title.Parent = tb

    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 100, 1, 0); version.Position = UDim2.new(0, 130, 0, 0)
    version.BackgroundTransparency = 1
    version.Text = "v3.0  •  PC"; version.TextColor3 = TEXT_DIM
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Font = Enum.Font.Gotham; version.TextSize = 11
    version.ZIndex = 3; version.Parent = tb

    -- status dot (blinks green = active)
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 10, 0, 10)
    statusDot.Position = UDim2.new(1, -110, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
    statusDot.BorderSizePixel = 0; statusDot.ZIndex = 3; statusDot.Parent = tb
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0, 70, 1, 0); statusLbl.Position = UDim2.new(1, -95, 0, 0)
    statusLbl.BackgroundTransparency = 1; statusLbl.Text = "Active"
    statusLbl.TextColor3 = Color3.fromRGB(80, 220, 120)
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Font = Enum.Font.GothamSemibold; statusLbl.TextSize = 11
    statusLbl.ZIndex = 3; statusLbl.Parent = tb
    task.spawn(function()
        while statusDot.Parent do
            TweenService:Create(statusDot, TweenInfo.new(0.6), {BackgroundTransparency = 0.5}):Play()
            task.wait(0.6)
            TweenService:Create(statusDot, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
            task.wait(0.6)
        end
    end)

    -- minimize / close
    local mini = Instance.new("TextButton")
    mini.Size = UDim2.new(0, 24, 0, 24); mini.Position = UDim2.new(1, -64, 0, 10)
    mini.BackgroundColor3 = Color3.fromRGB(90, 70, 130); mini.Text = "–"
    mini.TextColor3 = TEXT; mini.Font = Enum.Font.GothamBold; mini.TextSize = 16
    mini.BorderSizePixel = 0; mini.ZIndex = 3; mini.Parent = tb
    Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 6)

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 24, 0, 24); close.Position = UDim2.new(1, -34, 0, 10)
    close.BackgroundColor3 = Color3.fromRGB(200, 60, 90); close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255,255,255); close.Font = Enum.Font.GothamBold
    close.TextSize = 12; close.BorderSizePixel = 0; close.ZIndex = 3; close.Parent = tb
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

    -- sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 140, 1, -60); sidebar.Position = UDim2.new(0, 12, 0, 52)
    sidebar.BackgroundColor3 = BG_PANEL; sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2; sidebar.Parent = win
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
    local sGrad = Instance.new("UIGradient", sidebar)
    sGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 24, 52)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 16, 32))
    })
    sGrad.Rotation = 90
    local sl = Instance.new("UIListLayout", sidebar)
    sl.Padding = UDim.new(0, 5); sl.SortOrder = Enum.SortOrder.LayoutOrder
    local sp = Instance.new("UIPadding", sidebar)
    sp.PaddingTop = UDim.new(0, 8); sp.PaddingLeft = UDim.new(0, 8)
    sp.PaddingRight = UDim.new(0, 8)

    -- animated tab indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 0); indicator.BackgroundColor3 = ACCENT
    indicator.BorderSizePixel = 0; indicator.ZIndex = 5; indicator.Parent = sidebar
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    -- content scroller
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -172, 1, -70); content.Position = UDim2.new(0, 164, 0, 52)
    content.BackgroundTransparency = 1; content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = ACCENT
    content.ZIndex = 2; content.Parent = win
    local cl = Instance.new("UIListLayout", content)
    cl.Padding = UDim.new(0, 6); cl.SortOrder = Enum.SortOrder.LayoutOrder
    local cp = Instance.new("UIPadding", content)
    cp.PaddingTop = UDim.new(0, 4); cp.PaddingBottom = UDim.new(0, 12)
    cp.PaddingLeft = UDim.new(0, 4); cp.PaddingRight = UDim.new(0, 4)

    local pages, tabs = {}, {}
    local currentTabBtn = nil

    local function showPage(name)
        for n, f in pairs(pages) do f.Visible = (n == name) end
        for n, btn in pairs(tabs) do
            local isActive = (n == name)
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = isActive and BG_HOVER or Color3.fromRGB(36, 28, 56)
            }):Play()
            btn.TextColor3 = isActive and ACCENT or TEXT
        end
        local activeBtn = tabs[name]
        if activeBtn then
            TweenService:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Position = UDim2.new(0, 2, 0, activeBtn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y),
                Size = UDim2.new(0, 3, 0, activeBtn.AbsoluteSize.Y - 4)
            }):Play()
        end
    end

    local function createTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(36, 28, 56)
        btn.BorderSizePixel = 0; btn.Text = "  " .. name
        btn.TextColor3 = TEXT; btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
        btn.AutoButtonColor = false; btn.ZIndex = 3; btn.Parent = sidebar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        tabs[name] = btn

        btn.MouseEnter:Connect(function()
            if currentTabBtn ~= name then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(46, 36, 68)}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTabBtn ~= name then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(36, 28, 56)}):Play()
            end
        end)

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 0, 0); page.BackgroundTransparency = 1
        page.Visible = false; page.Parent = content
        local pl = Instance.new("UIListLayout", page)
        pl.Padding = UDim.new(0, 6); pl.SortOrder = Enum.SortOrder.LayoutOrder
        page.AutomaticSize = Enum.AutomaticSize.Y
        pages[name] = page

        btn.MouseButton1Click:Connect(function()
            currentTabBtn = name
            showPage(name)
        end)
        return page
    end

    local function makeSection(parent, text)
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 0, 22); wrap.BackgroundTransparency = 1; wrap.Parent = parent
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 1, 0); s.BackgroundTransparency = 1
        s.Text = "▎ " .. text; s.TextColor3 = ACCENT
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Font = Enum.Font.GothamBold; s.TextSize = 12; s.Parent = wrap
    end

    local function makeButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(36, 28, 56)
        btn.BorderSizePixel = 0; btn.Text = "  " .. text
        btn.TextColor3 = TEXT; btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13
        btn.AutoButtonColor = false; btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = ACCENT; stroke.Thickness = 0; stroke.Transparency = 0.7

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BG_HOVER}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {Thickness = 1}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(36, 28, 56)}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {Thickness = 0}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = ACCENT}):Play()
            task.delay(0.15, function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(36, 28, 56)}):Play()
            end)
            pcall(callback)
        end)
    end

    local function makeToggle(parent, text, initialState, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(36, 28, 56)
        frame.BorderSizePixel = 0; frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = text
        lbl.TextColor3 = TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13; lbl.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 44, 0, 22)
        track.Position = UDim2.new(1, -54, 0.5, -11)
        track.BackgroundColor3 = initialState and ACCENT or Color3.fromRGB(70, 60, 90)
        track.BorderSizePixel = 0; track.Parent = frame
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = initialState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        knob.BorderSizePixel = 0; knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = initialState
        local function toggle()
            state = not state
            TweenService:Create(track, TweenInfo.new(0.2), {
                BackgroundColor3 = state and ACCENT or Color3.fromRGB(70, 60, 90)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            }):Play()
            pcall(function() callback(state) end)
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then toggle() end
        end)
        lbl.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then toggle() end
        end)
    end

    local function makeSlider(parent, text, minVal, maxVal, initial, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 56)
        frame.BackgroundColor3 = Color3.fromRGB(36, 28, 56)
        frame.BorderSizePixel = 0; frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 22); lbl.Position = UDim2.new(0, 14, 0, 4)
        lbl.BackgroundTransparency = 1; lbl.Text = text .. "  •  " .. initial
        lbl.TextColor3 = TEXT; lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12; lbl.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -28, 0, 8); track.Position = UDim2.new(0, 14, 0, 34)
        track.BackgroundColor3 = Color3.fromRGB(58, 48, 82); track.BorderSizePixel = 0
        track.Parent = frame
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((initial - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = ACCENT; fill.BorderSizePixel = 0; fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local fillGrad = Instance.new("UIGradient", fill)
        fillGrad.Color = ColorSequence.new(ACCENT, ACCENT2)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((initial - minVal) / (maxVal - minVal), -8, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0; knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local knobStroke = Instance.new("UIStroke", knob)
        knobStroke.Color = ACCENT; knobStroke.Thickness = 2

        local dragging = false
        local function updateFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + rel * (maxVal - minVal))
            val = math.floor(val / 25) * 25
            local rel2 = (val - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(rel2, 0, 1, 0)
            knob.Position = UDim2.new(rel2, -8, 0.5, -8)
            lbl.Text = text .. "  •  " .. val
            pcall(function() callback(val) end)
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; updateFromX(i.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                updateFromX(i.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    local function makeParagraph(parent, title, content_text)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.BackgroundColor3 = Color3.fromRGB(28, 22, 44)
        frame.BorderSizePixel = 0; frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
        local p = Instance.new("UIPadding", frame)
        p.PaddingTop = UDim.new(0, 8); p.PaddingBottom = UDim.new(0, 8)
        p.PaddingLeft = UDim.new(0, 12); p.PaddingRight = UDim.new(0, 12)
        local l = Instance.new("UIListLayout", frame)
        l.Padding = UDim.new(0, 4); l.SortOrder = Enum.SortOrder.LayoutOrder

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, 0, 0, 18); t.BackgroundTransparency = 1
        t.Text = title; t.TextColor3 = ACCENT
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.Parent = frame

        local c = Instance.new("TextLabel")
        c.Size = UDim2.new(1, 0, 0, 0); c.AutomaticSize = Enum.AutomaticSize.Y
        c.BackgroundTransparency = 1; c.Text = content_text
        c.TextColor3 = TEXT_DIM; c.TextXAlignment = Enum.TextXAlignment.Left
        c.TextYAlignment = Enum.TextYAlignment.Top; c.TextWrapped = true
        c.Font = Enum.Font.Gotham; c.TextSize = 11; c.Parent = frame
    end

    -- build tabs
    local MainTab = createTab("Main")
    local GriefTab = createTab("Grief")
    local PlatformTab = createTab("Platform")
    local BuildsTab = createTab("Builds")
    local CreditsTab = createTab("Credits")

    makeSection(MainTab, "F3X / BTOOLS")
    makeButton(MainTab, "Grab F3X & Return", function() task.spawn(grabAndReturn) end)
    makeButton(MainTab, "Grab Btools & Return", function() task.spawn(grabBtools) end)
    makeToggle(MainTab, "Auto Grab (every 10s)", S.AutoGrab, function(v) S.AutoGrab = v; saveCurrentState() end)

    makeSection(MainTab, "MOVEMENT")
    makeToggle(MainTab, "Infinite Jump", S.InfJump, function(v) S.InfJump = v; saveCurrentState() end)

    makeSection(MainTab, "VISUAL")
    makeToggle(MainTab, "Player ESP", S.ESP, function(v)
        S.ESP = v; if not v and cleanESP then cleanESP() end; saveCurrentState()
    end)

    makeSection(MainTab, "ANTI-CHEAT")
    makeToggle(MainTab, "Anti-Kick", S.AntiKick, function(v) S.AntiKick = v; saveCurrentState() end)
    makeToggle(MainTab, "Anti-AFK", S.AntiAFK, function(v) S.AntiAFK = v; saveCurrentState() end)

    makeSection(MainTab, "SERVER")
    makeButton(MainTab, "Hop to Most Popular", function() serverHop() end)
    makeButton(MainTab, "Rejoin Server", function() rejoinServer() end)

    makeSection(MainTab, "KEYBINDS")
    makeParagraph(MainTab, "Shortcuts",
        "F = Grab F3X  •  H = ESP  •  J = Inf Jump  •  K = Toggle Menu")

    makeSection(GriefTab, "F3X GRIEFING")
    makeButton(GriefTab, "Mass Delete (ALL parts)", function() massDelete() end)
    makeButton(GriefTab, "Unanchor All (map falls)", function() unanchorAll() end)
    makeButton(GriefTab, "Fling Parts (chaos)", function() flingParts() end)
    makeButton(GriefTab, "Void All (to void)", function() voidAll() end)

    makeSection(GriefTab, "DEFENSE")
    makeButton(GriefTab, "Anti-F3X (hide others)", function() antiF3X() end)
    makeParagraph(GriefTab, "Warning", "These will lag or crash the server. Use at your own risk.")

    makeSection(PlatformTab, "SIZE")
    makeSlider(PlatformTab, "Platform Size", 10, 1000, S.PlatformSize, function(v)
        S.PlatformSize = v; saveCurrentState()
    end)
    makeSection(PlatformTab, "SQUARE")
    makeButton(PlatformTab, "Square Below Me", function() platformAtMe(false) end)
    makeButton(PlatformTab, "Square Above Me", function() platformAtMe(true) end)
    makeSection(PlatformTab, "CIRCLE")
    makeButton(PlatformTab, "Circle Below Me", function() circlePlatformAtMe(false) end)
    makeButton(PlatformTab, "Circle Above Me", function() circlePlatformAtMe(true) end)
    makeSection(PlatformTab, "CONTROL")
    makeButton(PlatformTab, "Clear Local Platforms", function() clearPlatforms() end)

    makeSection(BuildsTab, "SPAWN BUILDS")
    makeButton(BuildsTab, "House", function() spawnHouse() end)
    makeButton(BuildsTab, "Tower", function() spawnTower() end)
    makeButton(BuildsTab, "Bridge", function() spawnBridge() end)
    makeButton(BuildsTab, "Pyramid", function() spawnPyramid() end)
    makeButton(BuildsTab, "Wall", function() spawnWall() end)
    makeButton(BuildsTab, "Fountain", function() spawnFountain() end)
    makeSection(BuildsTab, "CONTROL")
    makeButton(BuildsTab, "Clear All Local", function() clearPlatforms() end)

    makeSection(CreditsTab, "CREDITS")
    makeParagraph(CreditsTab, "Creator", "Shaw")
    makeParagraph(CreditsTab, "Discord", "Shaw6000")

    makeSection(CreditsTab, "SETTINGS")
    makeButton(CreditsTab, "Change Device (reloads UI)", function()
        S.Device = nil; saveCurrentState()
        notify("Nicotine", "Device reset. Pick again in the prompt.", 3)
        task.wait(0.4)
        sg:Destroy()
        task.spawn(function()
            local c = showDeviceSelector()
            if c == "mobile" then buildMobileUI()
            elseif c == "pc" then buildPCUI() end
        end)
    end)

    -- auto-resize canvas
    local function updateCanvas()
        content.CanvasSize = UDim2.new(0, 0, 0, cl.AbsoluteContentSize.Y + 20)
    end
    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

    showPage("Main")
    task.wait(0.1)
    currentTabBtn = "Main"
    showPage("Main")

    -- toggle with K
    local visible = true
    trk(UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.K then
            visible = not visible
            win.Visible = visible
            glow.Visible = visible
        end
    end))

    mini.MouseButton1Click:Connect(function()
        visible = false
        win.Visible = false
        glow.Visible = false
    end)

    close.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    pcUIInstance = {Destroy = function() pcall(function() sg:Destroy() end) end}
    return pcUIInstance
end

-- ============================================================
-- MAIN LOAD (FIXED - PROPERLY AWAITS SELECTOR)
-- ============================================================
task.spawn(function()
    local choice = S.Device
    if not choice or (choice ~= "mobile" and choice ~= "pc") then
        choice = showDeviceSelector()
    end
    if choice == "mobile" then
        buildMobileUI()
        notify("Nicotine", "Loaded (Mobile UI)", 4)
    elseif choice == "pc" then
        buildPCUI()
        notify("Nicotine", "Loaded (PC UI) • Press K", 4)
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================
getgenv().Nicotine = function()
    S.InfJump = false; S.ESP = false; S.AntiKick = false
    S.AntiAFK = false; S.AutoGrab = false
    if cleanESP then cleanESP() end
    clearPlatforms()
    for _, c in ipairs(S.Conn) do pcall(function() c:Disconnect() end) end
    S.Conn = {}
    if RayfieldInstance then pcall(function() RayfieldInstance:Destroy() end) end
    for _, v in ipairs(PG:GetChildren()) do
        if v.Name == "Nicotine" or v.Name == "NicotineSelector" then
            pcall(function() v:Destroy() end)
        end
    end
    notify("Nicotine", "Unloaded.", 2)
end

applyAntiKick()
setupAntiAFK()
saveCurrentState()
print("[Nicotine] Done")

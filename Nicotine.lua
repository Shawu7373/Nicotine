--// NICOTINE | Made by: Shaw | Discord: Shaw6000
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
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 15)
if not PG then return end

for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "Nicotine" then pcall(function() v:Destroy() end) end
end

local function notify(t, x, d)
    local ok = pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t or "Nicotine", Text = x or "", Duration = d or 3})
    end)
    if not ok then pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[Nicotine] " .. tostring(t) .. ": " .. tostring(x)})
    end) end
end

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
        local fn = loadstring(s)
        if not fn then error("load") end
        return fn()
    end)
    local lib = res
    if not (lib and type(lib) == "table" and lib.CreateWindow) then lib = getgenv().Rayfield end
    if not (lib and type(lib) == "table" and lib.CreateWindow) then lib = rawget(_G, "Rayfield") end
    if lib and type(lib) == "table" and lib.CreateWindow then
        Rayfield = lib
        print("[Nicotine] Rayfield OK " .. i)
        break
    end
end
if not Rayfield then notify("Nicotine", "UI failed", 10); return end

-- ============================================================
-- QUEUE ON TELEPORT
-- ============================================================
local function queueScript()
    if type(queue_on_teleport) == "function" then
        pcall(function() queue_on_teleport(LOADSTRING) end)
        return true
    elseif type(queueonteleport) == "function" then
        pcall(function() queueonteleport(LOADSTRING) end)
        return true
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

local function saveConfig(stateTable)
    ensureFolder()
    if type(writefile) == "function" then
        local ok, encoded = pcall(function() return HttpService:JSONEncode(stateTable) end)
        if ok then
            pcall(writefile, CONFIG_FILE, encoded)
            return true
        end
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
    Conn = {},
    ESPObjects = {},
    PlacedParts = {},
    CanInfJump = true,
    AutoGrabKey = Enum.KeyCode.F,
    PlatformSize = 50
}

local function saveCurrentState()
    saveConfig({InfJump = S.InfJump, ESP = S.ESP})
end

local function getChar() return LP.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getBP() return LP:FindFirstChild("Backpack") end

local function trk(c) table.insert(S.Conn, c); return c end

-- ============================================================
-- BUILD HELPERS
-- ============================================================
local function makePart(size, color, transparency, material)
    local part = Instance.new("Part")
    part.Size = size
    part.Anchored = true
    part.CanCollide = true
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color or Color3.fromRGB(120, 120, 130)
    part.Transparency = transparency or 0
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = Workspace
    table.insert(S.PlacedParts, part)
    return part
end

local function makePartAt(pos, size, color, transparency, material)
    local p = makePart(size, color, transparency, material)
    p.Position = pos
    return p
end

-- ============================================================
-- PLATFORM BUILDER
-- ============================================================
local function platformAtMe(above)
    local root = getRoot()
    if not root then notify("Platform", "No character", 2); return end

    local size = S.PlatformSize or 50
    local part = makePart(Vector3.new(size, 3, size), Color3.fromRGB(255, 200, 0), 0.15)

    if above then
        part.Position = root.Position + Vector3.new(0, 12, 0)
        notify("Platform", "Square above you (" .. size .. ")", 2)
    else
        part.Position = root.Position + Vector3.new(0, -4, 0)
        notify("Platform", "Square below you (" .. size .. ")", 2)
    end
end

local function circlePlatformAtMe(above)
    local root = getRoot()
    if not root then notify("Platform", "No character", 2); return end

    local size = S.PlatformSize or 50
    local cylinder = Instance.new("Part")
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Size = Vector3.new(3, size, size)
    cylinder.Anchored = true
    cylinder.CanCollide = true
    cylinder.Material = Enum.Material.SmoothPlastic
    cylinder.Color = Color3.fromRGB(100, 200, 255)
    cylinder.Transparency = 0.15
    cylinder.TopSurface = Enum.SurfaceType.Smooth
    cylinder.BottomSurface = Enum.SurfaceType.Smooth
    cylinder.Parent = Workspace
    table.insert(S.PlacedParts, cylinder)

    if above then
        cylinder.CFrame = CFrame.new(root.Position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90))
        notify("Platform", "Circle above you (" .. size .. ")", 2)
    else
        cylinder.CFrame = CFrame.new(root.Position + Vector3.new(0, -4, 0)) * CFrame.Angles(0, 0, math.rad(90))
        notify("Platform", "Circle below you (" .. size .. ")", 2)
    end
end

local function clearPlatforms()
    local n = 0
    for _, p in ipairs(S.PlacedParts) do
        if p and p.Parent then
            pcall(function() p:Destroy() end)
            n = n + 1
        end
    end
    S.PlacedParts = {}
    notify("Platform", "Cleared " .. n .. " parts", 2)
end

-- ============================================================
-- BUILD HUB
-- ============================================================
local function spawnHouse()
    local root = getRoot()
    if not root then return end
    local pos = root.Position + Vector3.new(0, 20, 0)
    local base = pos

    local wallColor = Color3.fromRGB(220, 200, 160)
    local roofColor = Color3.fromRGB(180, 60, 60)
    local floorColor = Color3.fromRGB(120, 90, 60)
    local doorColor = Color3.fromRGB(90, 60, 30)
    local winColor = Color3.fromRGB(150, 210, 255)

    makePartAt(base, Vector3.new(30, 1, 30), floorColor, 0)
    makePartAt(base + Vector3.new(0, 8, -15), Vector3.new(30, 16, 1), wallColor, 0)
    makePartAt(base + Vector3.new(-15, 8, 0), Vector3.new(1, 16, 30), wallColor, 0)
    makePartAt(base + Vector3.new(15, 8, 0), Vector3.new(1, 16, 30), wallColor, 0)
    makePartAt(base + Vector3.new(-9, 8, 15), Vector3.new(12, 16, 1), wallColor, 0)
    makePartAt(base + Vector3.new(9, 8, 15), Vector3.new(12, 16, 1), wallColor, 0)
    makePartAt(base + Vector3.new(0, 13, 15), Vector3.new(6, 6, 1), wallColor, 0)
    makePartAt(base + Vector3.new(0, 5, 15), Vector3.new(5, 10, 0.5), doorColor, 0)
    makePartAt(base + Vector3.new(0, 10, -15), Vector3.new(8, 6, 0.5), winColor, 0.3)
    makePartAt(base + Vector3.new(-15, 10, 0), Vector3.new(0.5, 6, 8), winColor, 0.3)
    makePartAt(base + Vector3.new(15, 10, 0), Vector3.new(0.5, 6, 8), winColor, 0.3)
    makePartAt(base + Vector3.new(0, 17, 0), Vector3.new(32, 2, 32), roofColor, 0)
    makePartAt(base + Vector3.new(0, 20, 0), Vector3.new(24, 2, 24), roofColor, 0)

    notify("Builds", "House spawned", 2)
end

local function spawnTower()
    local root = getRoot()
    if not root then return end
    local pos = root.Position + Vector3.new(0, 30, 0)

    local stone = Color3.fromRGB(140, 140, 150)
    local top = Color3.fromRGB(200, 180, 100)

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
    local root = getRoot()
    if not root then return end
    local pos = root.Position + Vector3.new(0, 20, 0)

    local wood = Color3.fromRGB(140, 90, 50)
    local rail = Color3.fromRGB(100, 60, 30)

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
    local root = getRoot()
    if not root then return end
    local base = root.Position + Vector3.new(0, 10, 0)

    local gold = Color3.fromRGB(230, 190, 80)
    local layers = 10
    local size = 40
    for i = 0, layers - 1 do
        local s = size - (i * 4)
        if s <= 0 then break end
        makePartAt(Vector3.new(base.X, base.Y + i * 3, base.Z), Vector3.new(s, 3, s), gold, 0)
    end

    notify("Builds", "Pyramid spawned", 2)
end

local function spawnWall()
    local root = getRoot()
    if not root then return end
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
    local root = getRoot()
    if not root then return end
    local base = root.Position + Vector3.new(0, 5, 0)

    local stone = Color3.fromRGB(180, 180, 190)
    local water = Color3.fromRGB(100, 180, 255)

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
-- F3X
-- ============================================================
local TOOL_KW = {"building","f3x","btool","b tools","hammer","move","clone","destroy","import","wrench","lpi"}
local GIVER_KW = {"giver","f3x","btool","b tools","building","wrench","lpi","import"}

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
    local f = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if partMatches(o) then table.insert(f, o) end
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
    local root = getRoot()
    if not root then notify("Nicotine", "No character", 2); return end
    if hasF3X() then
        equipF3X()
        notify("Nicotine", "Already have F3X", 2)
        return
    end
    local givers = findGivers()
    if #givers == 0 then notify("Nicotine", "No giver found", 4); return end
    local saved2 = root.CFrame
    notify("Nicotine", "Grabbing F3X...", 2)
    for _, g in ipairs(givers) do
        pcall(function() root.CFrame = g.CFrame + Vector3.new(0, 1, 0) end)
        task.wait(0.2)
        touch(g)
        task.wait(0.3)
        if hasF3X() then
            equipF3X()
            task.wait(0.2)
            pcall(function() root.CFrame = saved2 end)
            notify("Nicotine", "F3X grabbed!", 3)
            return
        end
    end
    pcall(function() root.CFrame = saved2 end)
    notify("Nicotine", "Failed. Try again.", 4)
end

-- ============================================================
-- SERVER HOP (MOST POPULAR)
-- ============================================================
local function serverHop()
    saveCurrentState()
    if queueScript() then notify("Nicotine", "Script will auto-reload after hop", 3) end
    task.wait(0.3)
    notify("Nicotine", "Finding most popular server...", 3)

    local ok, err = pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Desc")
        local data = HttpService:JSONDecode(req)
        if not data or not data.data then error("No server data") end

        local best = nil
        local bestCount = -1
        for _, srv in ipairs(data.data) do
            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                if srv.playing > bestCount then
                    best = srv
                    bestCount = srv.playing
                end
            end
        end

        if not best then error("No available servers") end
        notify("Nicotine", "Joining server with " .. best.playing .. " players", 3)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LP)
    end)
    if not ok then notify("Nicotine", "Hop failed: " .. tostring(err), 4) end
end

local function rejoinServer()
    saveCurrentState()
    queueScript()
    notify("Nicotine", "Rejoining...", 2)
    task.wait(0.3)
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
end

-- ============================================================
-- INFINITE JUMP
-- ============================================================
trk(UIS.JumpRequest:Connect(function()
    if not S.InfJump then return end
    local h = getHum()
    if not h then return end
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
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end
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
        pcall(function() Rayfield.Flags["ESPToggle"]:Set(S.ESP) end)
    end
    if input.KeyCode == Enum.KeyCode.J then
        S.InfJump = not S.InfJump
        saveCurrentState()
        pcall(function() Rayfield.Flags["InfJumpToggle"]:Set(S.InfJump) end)
    end
end))

-- ============================================================
-- UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Nicotine",
    LoadingTitle = "Nicotine",
    LoadingSubtitle = "nicotine",
    KeySystem = false,
    ToggleUIKeybind = "K"
})

local MainTab = Window:CreateTab("Main", 4483362458)
local PlatformTab = Window:CreateTab("Platform", 4483362458)
local BuildsTab = Window:CreateTab("Builds Hub", 4483362458)
local CreditsTab = Window:CreateTab("Credits", 4483362458)

-- ========== MAIN TAB ==========
MainTab:CreateSection("F3X")
MainTab:CreateButton({Name = "Grab F3X & Return", Callback = function() grabAndReturn() end})

MainTab:CreateSection("Movement")
MainTab:CreateToggle({Name = "Infinite Jump", CurrentValue = S.InfJump, Flag = "InfJumpToggle",
    Callback = function(v) S.InfJump = v; saveCurrentState() end})

MainTab:CreateSection("Visual")
MainTab:CreateToggle({Name = "Player ESP", CurrentValue = S.ESP, Flag = "ESPToggle",
    Callback = function(v) S.ESP = v; if not v and cleanESP then cleanESP() end; saveCurrentState() end})

MainTab:CreateSection("Server")
MainTab:CreateButton({Name = "Hop to Most Popular Server", Callback = function() serverHop() end})
MainTab:CreateButton({Name = "Rejoin Server", Callback = function() rejoinServer() end})

MainTab:CreateSection("PC Keybinds")
MainTab:CreateParagraph({Title = "Keyboard shortcuts",
    Content = "F = Grab F3X\nH = Toggle ESP\nJ = Toggle Infinite Jump\nK = Show/Hide this menu\n\n(Mobile: just tap the buttons)"})

-- ========== PLATFORM TAB ==========
PlatformTab:CreateSection("Size")
PlatformTab:CreateSlider({
    Name = "Platform Size", Range = {10, 1000}, Increment = 25, Suffix = "studs",
    CurrentValue = 50, Flag = "PlatformSize",
    Callback = function(v) S.PlatformSize = v end
})

PlatformTab:CreateSection("Square Platform")
PlatformTab:CreateButton({Name = "Square Platform Below Me", Callback = function() platformAtMe(false) end})
PlatformTab:CreateButton({Name = "Square Platform Above Me", Callback = function() platformAtMe(true) end})

PlatformTab:CreateSection("Circle Platform")
PlatformTab:CreateButton({Name = "Circle Platform Below Me", Callback = function() circlePlatformAtMe(false) end})
PlatformTab:CreateButton({Name = "Circle Platform Above Me", Callback = function() circlePlatformAtMe(true) end})

PlatformTab:CreateSection("Control")
PlatformTab:CreateButton({Name = "Clear All Platforms", Callback = function() clearPlatforms() end})

-- ========== BUILDS HUB TAB ==========
BuildsTab:CreateSection("Builds")
BuildsTab:CreateButton({Name = "Spawn House", Callback = function() spawnHouse() end})
BuildsTab:CreateButton({Name = "Spawn Tower", Callback = function() spawnTower() end})
BuildsTab:CreateButton({Name = "Spawn Bridge", Callback = function() spawnBridge() end})
BuildsTab:CreateButton({Name = "Spawn Pyramid", Callback = function() spawnPyramid() end})
BuildsTab:CreateButton({Name = "Spawn Wall (with battlements)", Callback = function() spawnWall() end})
BuildsTab:CreateButton({Name = "Spawn Fountain", Callback = function() spawnFountain() end})

BuildsTab:CreateSection("Control")
BuildsTab:CreateButton({Name = "Clear All Builds & Platforms", Callback = function() clearPlatforms() end})

BuildsTab:CreateParagraph({Title = "How it works",
    Content = "Spawns pre-made builds at your position. All parts are anchored and stay until you clear them or leave."})

-- ========== CREDITS TAB ==========
CreditsTab:CreateSection("Credits")
CreditsTab:CreateParagraph({Title = "Creator", Content = "Shaw"})
CreditsTab:CreateParagraph({Title = "Discord", Content = "Shaw6000"})

-- ============================================================
-- CLEANUP
-- ============================================================
getgenv().Nicotine = function()
    S.InfJump = false
    S.ESP = false
    if cleanESP then cleanESP() end
    clearPlatforms()
    for _, c in ipairs(S.Conn) do pcall(function() c:Disconnect() end) end
    S.Conn = {}
    pcall(function() Rayfield:Destroy() end)
    notify("Nicotine", "Unloaded.", 2)
end

notify("Nicotine", "Loaded! Press K for UI.", 4)
print("[Nicotine] Done")

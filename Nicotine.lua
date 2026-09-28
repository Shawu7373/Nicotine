--// NICOTINE | Made by: Shaw | Discord: Shaw6000
print("[Nicotine] Loading...")

if getgenv().Nicotine then pcall(getgenv().Nicotine) end
getgenv().Nicotine = function() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
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
-- STATE
-- ============================================================
local S = {
    InfJump = false,
    ESP = false,
    Conn = {},
    ESPObjects = {},
    CanInfJump = true
}

local function getChar() return LP.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getBP() return LP:FindFirstChild("Backpack") end

local function trk(c) table.insert(S.Conn, c); return c end

-- ============================================================
-- F3X GRAB & RETURN
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

    local saved = root.CFrame
    notify("Nicotine", "Grabbing F3X...", 2)

    for _, g in ipairs(givers) do
        pcall(function() root.CFrame = g.CFrame + Vector3.new(0, 3, 0) end)
        task.wait(0.2)
        touch(g)
        task.wait(0.3)
        if hasF3X() then
            equipF3X()
            task.wait(0.2)
            pcall(function() root.CFrame = saved end)
            notify("Nicotine", "F3X grabbed!", 3)
            return
        end
    end

    pcall(function() root.CFrame = saved end)
    notify("Nicotine", "Failed. Try again.", 4)
end

-- ============================================================
-- SERVER HOP
-- ============================================================
local function serverHop()
    notify("Nicotine", "Finding new server...", 3)
    local ok, err = pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc")
        local data = HttpService:JSONDecode(req)
        if not data or not data.data then error("No server data") end
        local servers = {}
        for _, srv in ipairs(data.data) do
            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers and srv.playing > 0 then
                table.insert(servers, srv)
            end
        end
        if #servers == 0 then error("No available servers") end
        local picked = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, picked.id, LP)
    end)
    if not ok then
        notify("Nicotine", "Hop failed: " .. tostring(err), 4)
    end
end

local function rejoinServer()
    notify("Nicotine", "Rejoining...", 2)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end

-- ============================================================
-- INFINITE JUMP
-- ============================================================
trk(game:GetService("UserInputService").JumpRequest:Connect(function()
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
local function makeESP(target, color)
    if not target or S.ESPObjects[target] then return end
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.Name = "NicotineESP"
    hl.Adornee = target
    hl.FillColor = color
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0
    hl.Parent = target

    local bb = Instance.new("BillboardGui")
    bb.Name = "NicotineESPLabel"
    bb.Adornee = root
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = target

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = target.Name
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

local function cleanESP()
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

MainTab:CreateSection("F3X")

MainTab:CreateButton({
    Name = "Grab F3X & Return",
    Callback = function() grabAndReturn() end
})

MainTab:CreateSection("Movement")

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v)
        S.InfJump = v
        notify("Nicotine", "Infinite Jump " .. (v and "ON" or "OFF"), 2)
    end
})

MainTab:CreateSection("Visual")

MainTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(v)
        S.ESP = v
        if not v then cleanESP() end
        notify("Nicotine", "ESP " .. (v and "ON" or "OFF"), 2)
    end
})

MainTab:CreateSection("Server")

MainTab:CreateButton({
    Name = "Server Hop",
    Callback = function() serverHop() end
})

MainTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function() rejoinServer() end
})

-- ============================================================
-- CLEANUP
-- ============================================================
getgenv().Nicotine = function()
    S.InfJump = false
    S.ESP = false
    cleanESP()
    for _, c in ipairs(S.Conn) do pcall(function() c:Disconnect() end) end
    S.Conn = {}
    pcall(function() Rayfield:Destroy() end)
    notify("Nicotine", "Unloaded.", 2)
end

notify("Nicotine", "Loaded! Press K.", 4)
print("[Nicotine] Done")

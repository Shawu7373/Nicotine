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
-- CONFIG SAVE
-- ============================================================
local CONFIG_FOLDER = "Nicotine"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if type(makefolder) == "function" and type(isfolder) == "function" then
        if not isfolder(CONFIG_FOLDER) then
            pcall(function() makefolder(CONFIG_FOLDER) end)
        end
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
    CanInfJump = true,
    AutoGrabKey = Enum.KeyCode.F
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
-- FIX #1: Forward-declare cleanESP so PC keybinds can see it
-- ============================================================
local cleanESP = nil

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
        -- FIX #2: reduced offset from 3 to 1 stud for better contact
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
-- SERVER HOP
-- ============================================================
local function serverHop()
    saveCurrentState()
    if queueScript() then notify("Nicotine", "Script will auto-reload after hop", 3) end
    task.wait(0.3)
    notify("Nicotine", "Finding new server...", 3)
    local ok, err = pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&sortOrder=Asc")
        local data = HttpService:JSONDecode(req)
        if not data or not data.data then error("No server data") end
        local servers = {}
        for _, srv in ipairs(data.data) do
            -- FIX #3: removed "playing > 0" filter to allow hidden player counts
            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                table.insert(servers, srv)
            end
        end
        if #servers == 0 then error("No available servers") end
        local picked = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, picked.id, LP)
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
-- ESP (cleanESP is assigned here, not declared)
-- ============================================================
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

-- FIX #1 (cont): assign to the forward-declared local, not re-declare
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
-- PC KEYBINDS (now safe — cleanESP is in scope)
-- ============================================================
trk(UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == S.AutoGrabKey then
        task.spawn(grabAndReturn)
    end
    if input.KeyCode == Enum.KeyCode.H then
        S.ESP = not S.ESP
        if not S.ESP and cleanESP then cleanESP() end
        saveCurrentState()
        pcall(function() Rayfield.Flags["ESPToggle"]:Set(S.ESP) end)
        notify("Nicotine", "ESP " .. (S.ESP and "ON" or "OFF"), 2)
    end
    if input.KeyCode == Enum.KeyCode.J then
        S.InfJump = not S.InfJump
        saveCurrentState()
        pcall(function() Rayfield.Flags["InfJumpToggle"]:Set(S.InfJump) end)
        notify("Nicotine", "Infinite Jump " .. (S.InfJump and "ON" or "OFF"), 2)
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
local CreditsTab = Window:CreateTab("Credits", 4483362458)

-- ========== MAIN TAB ==========
MainTab:CreateSection("F3X")

MainTab:CreateButton({
    Name = "Grab F3X & Return",
    Callback = function() grabAndReturn() end
})

MainTab:CreateSection("Movement")

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = S.InfJump,
    Flag = "InfJumpToggle",
    Callback = function(v)
        S.InfJump = v
        saveCurrentState()
    end
})

MainTab:CreateSection("Visual")

MainTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = S.ESP,
    Flag = "ESPToggle",
    Callback = function(v)
        S.ESP = v
        if not v and cleanESP then cleanESP() end
        saveCurrentState()
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

MainTab:CreateSection("PC Keybinds")

MainTab:CreateParagraph({
    Title = "Keyboard shortcuts",
    Content = "F = Grab F3X\nH = Toggle ESP\nJ = Toggle Infinite Jump\nK = Show/Hide this menu\n\n(Mobile: just tap the buttons)"
})

-- ========== CREDITS TAB ==========
CreditsTab:CreateSection("Credits")

CreditsTab:CreateParagraph({
    Title = "Creator",
    Content = "Shaw"
})

CreditsTab:CreateParagraph({
    Title = "Discord",
    Content = "Shaw6000"
})

-- ============================================================
-- CLEANUP
-- ============================================================
getgenv().Nicotine = function()
    S.InfJump = false
    S.ESP = false
    if cleanESP then cleanESP() end
    for _, c in ipairs(S.Conn) do pcall(function() c:Disconnect() end) end
    S.Conn = {}
    pcall(function() Rayfield:Destroy() end)
    notify("Nicotine", "Unloaded.", 2)
end

notify("Nicotine", "Loaded! Press K for UI.", 4)
print("[Nicotine] Done")

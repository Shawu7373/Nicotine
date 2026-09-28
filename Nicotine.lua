--// ====================================================================
--// NICOTINE
--// Made by: Shaw | Discord: Shaw6000
--// F3X Auto Grab + Reteleport Protection
--// ====================================================================

print("[Nicotine] Loading...")

if getgenv().Nicotine then pcall(getgenv().Nicotine) end
getgenv().Nicotine = function() end

local ok, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 15)
if not PG then warn("[Nicotine] PlayerGui not found."); return end

for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "Nicotine" then pcall(function() v:Destroy() end) end
end

local function notify(title, text, dur)
    local ok2 = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Nicotine", Text = text or "", Duration = dur or 3
        })
    end)
    if not ok2 then
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", { Text = "[Nicotine] " .. tostring(title) .. ": " .. tostring(text) })
        end)
    end
end

print("[Nicotine] Loading Rayfield...")
local Rayfield
local sources = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/Footagesus/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/luau-libraries/Rayfield/main/source.lua"
}
for i, url in ipairs(sources) do
    local ok2, res = pcall(function()
        local s = game:HttpGet(url)
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
if not Rayfield then
    notify("Nicotine", "UI library failed", 10)
    return
end

local S = {
    AutoF3X = false,
    Reteleport = false,
    PrevPosition = nil,
    Threshold = 30,
    Conn = {},
    LastNotify = 0
}

local function getChar() return LP.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getBackpack() return LP:FindFirstChild("Backpack") end

local function trk(c) table.insert(S.Conn, c); return c end

-- ============================================================
-- F3X TOOL DETECTION
-- ============================================================
local TOOL_KEYWORDS = {"building","f3x","btool","b tools","hammer","move","clone","destroy","import","wrench","lpi"}

local function isF3XTool(obj)
    if not obj or not obj:IsA("Tool") then return false end
    local n = obj.Name:lower()
    for _, kw in ipairs(TOOL_KEYWORDS) do
        if n:find(kw) then return true end
    end
    return false
end

local function findF3XInChar()
    local c = getChar(); if not c then return nil end
    for _, o in ipairs(c:GetChildren()) do
        if isF3XTool(o) then return o end
    end
    return nil
end

local function findF3XInBP()
    local bp = getBackpack(); if not bp then return nil end
    for _, o in ipairs(bp:GetChildren()) do
        if isF3XTool(o) then return o end
    end
    return nil
end

local function findF3XAnywhere()
    return findF3XInChar() or findF3XInBP()
end

local function equipF3X()
    local t = findF3XAnywhere()
    if not t then return false end
    local h = getHum()
    if h then pcall(function() h:EquipTool(t) end); return true end
    return false
end

-- ============================================================
-- GIVER FINDER
-- ============================================================
local GIVER_KEYWORDS = {"giver","f3x","btool","b tools","building","wrench","lpi","import"}

local function partMatches(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    for _, kw in ipairs(GIVER_KEYWORDS) do
        if n:find(kw) then return true end
    end
    for _, child in ipairs(obj:GetChildren()) do
        local cn = child.Name:lower()
        for _, kw in ipairs(GIVER_KEYWORDS) do
            if cn:find(kw) then return true end
        end
    end
    return false
end

local function findF3XGivers()
    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if partMatches(obj) then table.insert(found, obj) end
    end
    return found
end

-- ============================================================
-- TOUCH GIVER
-- ============================================================
local function touchGiver(giver)
    local root = getRoot()
    if not root or not giver then return false end

    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(giver, root, 0)
            task.wait(0.05)
            firetouchinterest(giver, root, 1)
        end)
        return true
    end
    return false
end

-- ============================================================
-- GRAB AND RETURN (the button you asked for)
-- ============================================================
local function grabAndReturn()
    local root = getRoot()
    if not root then notify("Nicotine", "No character", 2); return end

    -- If already have F3X, just equip and finish
    if findF3XAnywhere() then
        if not findF3XInChar() then equipF3X() end
        notify("Nicotine", "Already have F3X", 2)
        return
    end

    -- Find giver
    local givers = findF3XGivers()
    if #givers == 0 then
        notify("Nicotine", "No F3X giver found in map", 4)
        return
    end

    -- Save current position
    local savedCFrame = root.CFrame
    notify("Nicotine", "Grabbing F3X...", 2)

    -- Try each giver
    for _, giver in ipairs(givers) do
        -- Teleport onto giver
        pcall(function()
            root.CFrame = giver.CFrame + Vector3.new(0, 3, 0)
        end)

        task.wait(0.2)

        -- Fire touch interest
        touchGiver(giver)
        task.wait(0.3)

        -- Did we get it?
        if findF3XAnywhere() then
            equipF3X()
            -- Return to saved position
            task.wait(0.2)
            pcall(function()
                root.CFrame = savedCFrame
            end)
            notify("Nicotine", "F3X grabbed and returned!", 3)
            return
        end
    end

    -- Failed — return to saved position anyway
    pcall(function()
        root.CFrame = savedCFrame
    end)
    notify("Nicotine", "Couldn't grab F3X. Try again.", 4)
end

-- ============================================================
-- AUTO F3X LOOP (background)
-- ============================================================
local function autoF3XLoop()
    while S.AutoF3X do
        task.wait(2)
        if not findF3XAnywhere() then
            -- Silent auto grab (no return — just teleport to giver)
            local givers = findF3XGivers()
            if #givers > 0 then
                for _, giver in ipairs(givers) do
                    local root = getRoot()
                    if root then
                        pcall(function()
                            root.CFrame = giver.CFrame + Vector3.new(0, 3, 0)
                        end)
                        task.wait(0.3)
                        touchGiver(giver)
                        task.wait(0.3)
                    end
                    if findF3XAnywhere() then
                        equipF3X()
                        break
                    end
                end
            end
        else
            if not findF3XInChar() then equipF3X() end
        end
    end
end

-- ============================================================
-- RETELEPORT PROTECTION
-- ============================================================
local function retpLoop()
    while S.Reteleport do
        RunService.Heartbeat:Wait()
        local root = getRoot()
        if not root then
            S.PrevPosition = nil
            continue
        end

        local currentPos = root.Position
        if S.PrevPosition then
            local delta = (currentPos - S.PrevPosition).Magnitude
            if delta > S.Threshold then
                local offset = S.PrevPosition - currentPos
                pcall(function() root.CFrame = root.CFrame + offset end)
                if tick() - S.LastNotify > 2 then
                    S.LastNotify = tick()
                    notify("Reteleport", "Teleport blocked!", 2)
                end
                S.PrevPosition = root.Position
                continue
            end
        end
        S.PrevPosition = currentPos
    end
end

-- ============================================================
-- UI (RAYFIELD)
-- ============================================================
print("[Nicotine] Building UI...")

local Window = Rayfield:CreateWindow({
    Name = "Nicotine",
    LoadingTitle = "Nicotine",
    LoadingSubtitle = "nicotine",
    ConfigurationSaving = { Enabled = true, FolderName = "Nicotine", FileName = "Config" },
    KeySystem = false,
    ToggleUIKeybind = "K"
})

local MainTab = Window:CreateTab("Main", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)

MainTab:CreateSection("F3X Tools")

MainTab:CreateButton({
    Name = "Grab F3X & Return",
    Callback = function()
        grabAndReturn()
    end
})

MainTab:CreateToggle({
    Name = "Auto Grab F3X Tool (background)",
    CurrentValue = false,
    Flag = "AutoF3X",
    Callback = function(v)
        S.AutoF3X = v
        if v then
            task.spawn(autoF3XLoop)
            notify("Nicotine", "Auto F3X ON", 2)
        else
            notify("Nicotine", "Auto F3X OFF", 2)
        end
    end
})

MainTab:CreateSection("Reteleport Protection")

MainTab:CreateToggle({
    Name = "Reteleport Protection",
    CurrentValue = false,
    Flag = "Reteleport",
    Callback = function(v)
        S.Reteleport = v
        if v then
            S.PrevPosition = nil
            task.spawn(retpLoop)
            notify("Nicotine", "Reteleport ON", 2)
        else
            S.PrevPosition = nil
            notify("Nicotine", "Reteleport OFF", 2)
        end
    end
})

MainTab:CreateSlider({
    Name = "Teleport Detection Threshold (studs)",
    Range = {10, 200},
    Increment = 5,
    Suffix = "studs",
    CurrentValue = 30,
    Flag = "Threshold",
    Callback = function(v) S.Threshold = v end
})

MainTab:CreateParagraph({
    Title = "How Reteleport works",
    Content = "Tracks your position every frame. If you move more than the threshold in one frame, you snap back to where you were."
})

InfoTab:CreateSection("About")
InfoTab:CreateParagraph({ Title = "Nicotine", Content = "F3X Auto Grab + Reteleport Protection" })
InfoTab:CreateSection("Credits")
InfoTab:CreateParagraph({ Title = "Made by", Content = "Shaw" })
InfoTab:CreateParagraph({ Title = "Discord", Content = "Shaw6000" })
InfoTab:CreateSection("How to use")
InfoTab:CreateParagraph({
    Title = "Grab F3X & Return",
    Content = "Click the button. It teleports you to the F3X giver, grabs the tool, then returns you to where you were standing."
})
InfoTab:CreateParagraph({
    Title = "Auto Grab",
    Content = "Toggle on for background grabbing. If you die or lose the tool, it re-acquires it automatically."
})

-- ============================================================
-- CLEANUP
-- ============================================================
getgenv().Nicotine = function()
    S.AutoF3X = false
    S.Reteleport = false
    S.PrevPosition = nil
    for _, c in ipairs(S.Conn) do pcall(function() c:Disconnect() end) end
    S.Conn = {}
    pcall(function() Rayfield:Destroy() end)
    notify("Nicotine", "Unloaded.", 2)
end

print("[Nicotine] Loaded successfully")
notify("Nicotine", "Loaded! Press K for UI.", 5)

end)

if not ok then
    warn("[Nicotine] FAILED: " .. tostring(err))
    pcall(function()
        if getgenv().Nicotine then getgenv().Nicotine() end
    end)
end

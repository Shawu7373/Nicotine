--// ====================================================================
--// NICOTINE v1.2
--// Made by: Shaw | Discord: Shaw6000
--// Auto F3X Grab (Giver-based) + Reteleport Protection
--// ====================================================================

print("[Nicotine] Loading...")

if getgenv().Nicotine then pcall(getgenv().Nicotine) end
getgenv().Nicotine = function() end

local ok, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Chat = game:GetService("Chat")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    LastRequest = 0,
    LastNotify = 0,
    GiverPart = nil
}

local function getChar() return LP.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHead() local c = getChar(); return c and c:FindFirstChild("Head") end
local function getBackpack() return LP:FindFirstChild("Backpack") end

local function trk(c) table.insert(S.Conn, c); return c end

-- ============================================================
-- F3X TOOL DETECTION
-- ============================================================
local function isF3XTool(obj)
    if not obj or not obj:IsA("Tool") then return false end
    local n = obj.Name:lower()
    return n:find("building") or n:find("f3x") or n:find("btool") or n:find("b tools") or n:find("hammer")
end

local function findF3XInCharacter()
    local char = getChar()
    if not char then return nil end
    for _, obj in ipairs(char:GetChildren()) do
        if isF3XTool(obj) then return obj end
    end
    return nil
end

local function findF3XInBackpack()
    local bp = getBackpack()
    if not bp then return nil end
    for _, obj in ipairs(bp:GetChildren()) do
        if isF3XTool(obj) then return obj end
    end
    return nil
end

local function findF3XAnywhere()
    return findF3XInCharacter() or findF3XInBackpack()
end

local function equipF3X()
    local tool = findF3XAnywhere()
    if not tool then return false end
    local hum = getHum()
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        return true
    end
    return false
end

-- ============================================================
-- GIVER FINDER (MAIN METHOD)
-- ============================================================
local function isF3XGiver(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    return n:find("f3x") or n:find("btool") or n:find("b tools") or n:find("giver") or n:find("building")
end

local function findF3XGiver()
    -- Search workspace for F3X giver
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isF3XGiver(obj) then
            -- Prefer parts with "f3x" or "building" specifically
            local n = obj.Name:lower()
            if n:find("f3x") or n:find("building") or n:find("btool") then
                return obj
            end
        end
    end
    -- Fallback: any giver part
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isF3XGiver(obj) then return obj end
    end
    return nil
end

local function teleportToGiver()
    local giver = S.GiverPart or findF3XGiver()
    if not giver then return false end
    S.GiverPart = giver

    local root = getRoot()
    if not root then return false end

    -- Save current position, teleport to giver, then it auto-touches
    pcall(function()
        root.CFrame = giver.CFrame + Vector3.new(0, 2, 0)
    end)

    -- Wait a moment for the touch to register
    task.wait(0.4)

    -- Move away slightly so we're not stuck inside
    pcall(function()
        root.CFrame = giver.CFrame + Vector3.new(0, 2, 5)
    end)

    return true
end

-- ============================================================
-- CHAT COMMAND (FALLBACK)
-- ============================================================
local function tryChatCommand()
    if tick() - S.LastRequest < 3 then return false end
    S.LastRequest = tick()

    local head = getHead()
    if not head then return false end

    local sent = false

    -- Try TextChatService first
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                local general = channels:FindFirstChild("RBXGeneral")
                if general and general.SendAsync then
                    general:SendAsync(":f3x")
                    sent = true
                end
            end
        end
    end)

    -- Legacy fallback
    if not sent then
        pcall(function()
            Chat:Chat(head, ":f3x")
        end)
    end

    return true
end

-- ============================================================
-- MAIN AUTO-GRAB LOGIC
-- ============================================================
local function attemptGrab()
    -- Already have it? Just equip it.
    if findF3XAnywhere() then
        local charTool = findF3XInCharacter()
        if not charTool then equipF3X() end
        return true
    end

    -- No tool in inventory — try the giver first (most reliable)
    if teleportToGiver() then
        task.wait(0.3)
        if findF3XAnywhere() then
            equipF3X()
            return true
        end
    end

    -- Giver didn't work — try chat command
    if tryChatCommand() then
        task.wait(0.5)
        if findF3XAnywhere() then
            equipF3X()
            return true
        end
    end

    return false
end

local function autoF3XLoop()
    local warned = false
    while S.AutoF3X do
        task.wait(1)
        if not findF3XAnywhere() then
            attemptGrab()
        else
            -- Already have it — make sure it's equipped
            if not findF3XInCharacter() then
                equipF3X()
            end
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
-- UI
-- ============================================================
print("[Nicotine] Building UI...")

local Window = Rayfield:CreateWindow({
    Name = "Nicotine",
    LoadingTitle = "Nicotine",
    LoadingSubtitle = "v1.2",
    ConfigurationSaving = { Enabled = true, FolderName = "Nicotine", FileName = "Config" },
    KeySystem = false,
    ToggleUIKeybind = "K"
})

local MainTab = Window:CreateTab("Main", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)

MainTab:CreateSection("F3X Tools")

MainTab:CreateToggle({
    Name = "Auto Grab F3X Tool",
    CurrentValue = false,
    Flag = "AutoF3X",
    Callback = function(v)
        S.AutoF3X = v
        if v then
            task.spawn(autoF3XLoop)
            notify("F3X", "Auto-grab ON", 2)
        else
            notify("F3X", "Auto-grab OFF", 2)
        end
    end
})

MainTab:CreateButton({
    Name = "Grab F3X Now (manual)",
    Callback = function()
        S.LastRequest = 0
        if attemptGrab() then
            notify("F3X", "F3X acquired!", 3)
        else
            notify("F3X", "Could not find F3X. Try touching the giver manually.", 4)
        end
    end
})

MainTab:CreateButton({
    Name = "Find and TP to F3X Giver",
    Callback = function()
        local giver = findF3XGiver()
        if giver then
            S.GiverPart = giver
            notify("F3X", "Giver found: " .. giver.Name, 3)
            pcall(function()
                local root = getRoot()
                if root then root.CFrame = giver.CFrame + Vector3.new(0, 3, 5) end
            end)
        else
            notify("F3X", "No F3X giver found in workspace", 4)
        end
    end
})

MainTab:CreateParagraph({
    Title = "How Auto Grab works",
    Content = "1. Finds the F3X giver in the map and touches it\n2. If no giver, tries the :f3x chat command\n3. Auto-equips the tool once acquired\n4. Re-acquires on respawn"
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
            notify("Reteleport", "ON", 3)
        else
            S.PrevPosition = nil
            notify("Reteleport", "OFF", 2)
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

InfoTab:CreateSection("About")
InfoTab:CreateParagraph({ Title = "Nicotine v1.2", Content = "Auto F3X grab (giver-based) + Reteleport protection." })
InfoTab:CreateSection("Credits")
InfoTab:CreateParagraph({ Title = "Made by", Content = "Shaw" })
InfoTab:CreateParagraph({ Title = "Discord", Content = "Shaw6000" })

-- Character respawn
trk(LP.CharacterAdded:Connect(function(char)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not root or not hum then return end
    S.PrevPosition = nil
    S.LastRequest = 0
    if S.AutoF3X then
        task.wait(1)
        attemptGrab()
    end
end))

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

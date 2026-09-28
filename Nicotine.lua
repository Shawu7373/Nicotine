--// NICOTINE | Made by: Shaw | Discord: Shaw6000
print("[Nicotine] Loading...")

if getgenv().Nicotine then pcall(getgenv().Nicotine) end
getgenv().Nicotine = function() end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
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

local function getRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getBP() return LP:FindFirstChild("Backpack") end

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
        if not equipF3X() then notify("Nicotine", "F3X equipped", 2) end
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

local Window = Rayfield:CreateWindow({
    Name = "Nicotine",
    LoadingTitle = "Nicotine",
    LoadingSubtitle = "nicotine",
    KeySystem = false,
    ToggleUIKeybind = "K"
})

local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateButton({
    Name = "Grab F3X & Return",
    Callback = function()
        grabAndReturn()
    end
})

getgenv().Nicotine = function()
    pcall(function() Rayfield:Destroy() end)
    notify("Nicotine", "Unloaded.", 2)
end

notify("Nicotine", "Loaded! Press K.", 4)
print("[Nicotine] Done")

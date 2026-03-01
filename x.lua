local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local FishingController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("FishingController"))

local LocalPlayer = Players.LocalPlayer
local ScriptActive = true
local Connections = {}

print("XAL: Headless Mode Started (Auto Click, No Popup, Anti-AFK)")

-- 1. Anti-AFK Secure (No VirtualUser)
task.spawn(function()
    local afkConn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            -- Simulate key press to prevent AFK
            UserInputService.InputBegan:Fire(Enum.KeyCode.F20, false)
        end)
    end)
    table.insert(Connections, afkConn)

    for i, v in pairs(getconnections(LocalPlayer.Idled)) do
        if v.Disable then v:Disable() end
    end
    print("XAL: Anti-AFK Secure Active")
end)

-- 2. Auto Click Fishing with Randomized Delay
task.spawn(function()
    local clickEffect = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("!!! Click Effect")
    if clickEffect then clickEffect.Enabled = false end
    
    print("XAL: Auto Click Fishing Active")
    while ScriptActive do
        local randomDelay = math.random(80, 150) / 1000 -- delay 0.08 s/d 0.15 detik
        pcall(function() 
            FishingController:RequestFishingMinigameClick() 
        end)
        task.wait(randomDelay)
    end
end)

-- 3. Remove Fish Notification Pop-up
task.spawn(function()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local SmallNotification = PlayerGui:WaitForChild("Small Notification", 10)
    
    if SmallNotification then
        print("XAL: Pop-up Blocker Active")
        local DisableNotificationConnection = RunService.RenderStepped:Connect(function()
            if not ScriptActive then return end
            SmallNotification.Enabled = false
        end)
        table.insert(Connections, DisableNotificationConnection)
    else
        warn("XAL: Could not find Small Notification UI")
    end
end)

-- In case you want to stop the script safely from your executor
if getgenv then
    getgenv().XAL_StopHeadless = function()
        ScriptActive = false
        for _, v in pairs(Connections) do
            if typeof(v) == "RBXScriptConnection" then
                v:Disconnect()
            end
        end
        print("XAL: Headless Mode Stopped")
    end
end

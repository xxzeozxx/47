local Settings = {
    -- Masukkan URL Webhook Anda di bawah ini
    WebhookUrl_Fish = "https://discord.com/api/webhooks/1454735553638563961/C0KfomZhdu3KjmaqPx4CTi6NHbhIjcLaX_HpeSKqs66HUc179MQ9Ha_weV_v8zl1MjYK",
    WebhookUrl_Leave = "https://discord.com/api/webhooks/1464227659461693575/kMJqqG1Rz5i8m9svsQr1aUXQacRaPueMBISTwUKr0wij5fT6Sqj5OzSUaGFYW_-o9gvp",
    
    -- Konfigurasi Pengingat (Otomatis Aktif)
    AutoClickEnabled = true,
    DisablePopups = true,
    SecretEnabled = true, 
    RubyEnabled = true,   
    MutationCrystalized = true,
    CaveCrystalEnabled = true,
    EvolvedEnabled = true,
    LeaveEnabled = true,
    
    -- Menyembunyikan nama pemain di Webhook?
    SpoilerName = false 
}

-- Jangan ubah apapun di bawah ini kecuali Anda mengerti
print("XAL: Starting Headless Edition...")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local ScriptActive = true
local Connections = {}
local FishingController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("FishingController"))

local SecretList = {
    "Crystal Crab", "Orca", "Zombie Shark", "Zombie Megalodon", "Dead Zombie Shark",
    "Blob Shark", "Ghost Shark", "Skeleton Narwhal", "Ghost Worm Fish", "Worm Fish",
    "Megalodon", "1x1x1x1 Comet Shark", "Bloodmoon Whale", "Lochness Monster",
    "Monster Shark", "Eerie Shark", "Great Whale", "Frostborn Shark", "Armored Shark",
    "Scare", "Queen Crab", "King Crab", "Cryoshade Glider", "Panther Eel",
    "Giant Squid", "Depthseeker Ray", "Robot Kraken", "Mosasaur Shark", "King Jelly",
    "Bone Whale", "Elshark Gran Maja", "Elpirate Gran Maja", "Ancient Whale", "Gladiator Shark",
    "Ancient Lochness Monster", "Talon Serpent", "Hacker Shark", "ElRetro Gran Maja",
    "Strawberry Choc Megalodon", "Krampus Shark", "Emerald Winter Whale",
    "Winter Frost Shark", "Icebreaker Whale", "Leviathan", "Pirate Megalodon", "Viridis Lurker",
    "Cursed Kraken", "Ancient Magma Whale",
}
local StoneList = { "Ruby" }


-- 1. Anti-AFK Secure
task.spawn(function()
    local afkConn = Players.LocalPlayer.Idled:Connect(function()
        pcall(function() UserInputService.InputBegan:Fire(Enum.KeyCode.F20, false) end)
    end)
    table.insert(Connections, afkConn)

    for i, v in pairs(getconnections(Players.LocalPlayer.Idled)) do
        if v.Disable then v:Disable() end
    end
    print("XAL: Anti-AFK Active")
end)

-- 2. Auto Click Fishing
task.spawn(function()
    local clickEffect = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("!!! Click Effect")
    if clickEffect then clickEffect.Enabled = false end
    
    if Settings.AutoClickEnabled then
        print("XAL: Auto Click Fishing Active")
        while ScriptActive do
            local randomDelay = math.random(80, 150) / 1000
            pcall(function() FishingController:RequestFishingMinigameClick() end)
            task.wait(randomDelay)
        end
    end
end)

-- 3. Block Notifications
task.spawn(function()
    if Settings.DisablePopups then
        local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        local SmallNotification = PlayerGui:WaitForChild("Small Notification", 10)
        
        if SmallNotification then
            print("XAL: Notification Blocker Active")
            local DisableConn = RunService.RenderStepped:Connect(function()
                if not ScriptActive then return end
                SmallNotification.Enabled = false
            end)
            table.insert(Connections, DisableConn)
        end
    end
end)

-- 4. Notification Logic & Webhooks
local function SendWebhook(data, category)
    if not ScriptActive then return end
    if category == "SECRET" and not Settings.SecretEnabled then return end
    if category == "STONE" and not Settings.RubyEnabled then return end
    if category == "EVOLVED" and not Settings.EvolvedEnabled then return end 
    if category == "CRYSTALIZED" and not Settings.MutationCrystalized then return end 
    if category == "CAVECRYSTAL" and not Settings.CaveCrystalEnabled then return end 
    if category == "LEAVE" and not Settings.LeaveEnabled then return end 

    local TargetURL = (category == "LEAVE") and Settings.WebhookUrl_Leave or Settings.WebhookUrl_Fish
    if not TargetURL or TargetURL == "" or string.find(TargetURL, "MASUKKAN_URL") then return end

    local embedTitle = ""
    local embedColor = 3447003
    local descriptionText = "" 
    local contentMsg = ""
    
    local pName = data.Player 
    if Settings.SpoilerName and pName then
        pName = "||`" .. pName .. "`||"
    elseif pName then
        pName = "`" .. pName .. "`"
    end

    if category == "STARTUP" then
        embedTitle = "Script Executed!"
        embedColor = 5763719
        descriptionText = "The XAL Headless Script is now active on **" .. Players.LocalPlayer.Name .. "**'s client.\nAuto Click, Anti-AFK, and Webhooks are monitoring..."
    elseif category == "SECRET" then
        embedTitle = "Secret Caught!"
        embedColor = 3447003
        local lines = { "⚓ Fish: " .. data.Item }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "🧬 Mutation: " .. data.Mutation) end
        table.insert(lines, "⚖️ Weight: " .. data.Weight)
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "STONE" then
        embedTitle = "Ruby Gemstone!"
        embedColor = 16753920
        local lines = { "💎 Stone: " .. data.Item }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "✨ Mutation: " .. data.Mutation) end
        table.insert(lines, "⚖️ Weight: " .. data.Weight)
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "EVOLVED" then
        embedTitle = "Evolved Stone!"
        embedColor = 10181046 
        local lines = { "🔮 Item: " .. data.Item }
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "CRYSTALIZED" then
        embedTitle = "CRYSTALIZED MUTATION!"
        embedColor = 3407871
        local lines = { "💎 Fish: " .. data.Item, "✨ Mutation: Crystalized", "⚖️ Weight: " .. data.Weight }
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "CAVECRYSTAL" then
        embedTitle = "💎 Cave Crystal Event!"
        embedColor = 16776960
        descriptionText = "Information\n" .. data.ListText
    elseif category == "LEAVE" then
        embedTitle = data.Player .. " Left the server."
        embedColor = 16711680
        descriptionText = "👤 **@" .. data.Player .. "**" 
    end
    
    local embedData = { 
        ["username"] = "XAL Notifications!", 
        ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", 
        ["content"] = contentMsg, 
        ["embeds"] = {{ 
            ["title"] = embedTitle, 
            ["description"] = descriptionText, 
            ["color"] = embedColor, 
            ["footer"] = { ["text"] = "XAL Headless Monitoring", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } 
        }} 
    }
    
    pcall(function() 
        httpRequest({ Url = TargetURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(embedData) }) 
    end)
end

local function StripTags(str) return string.gsub(str, "<[^>]+>", "") end

local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    local p, f, w = string.match(msg, "^(.*) obtained an? (.*) %((.*)%)")
    if not p then 
        p, f = string.match(msg, "^(.*) obtained an? (.*)")
        w = "N/A" 
    end

    if p and f then
        if string.sub(f, -1) == "!" or string.sub(f, -1) == "." then f = string.sub(f, 1, -2) end
        f = f:match("^%s*(.-)%s*$")
        local mutation = nil; local finalItem = f; local lowerFullItem = string.lower(f); local allTargets = {}
        
        for _, v in pairs(SecretList) do table.insert(allTargets, v) end
        for _, v in pairs(StoneList) do table.insert(allTargets, v) end
        table.insert(allTargets, "Evolved Enchant Stone") 

        for _, baseName in pairs(allTargets) do
            if string.find(lowerFullItem, string.lower(baseName) .. "$") then
                local s, e = string.find(lowerFullItem, string.lower(baseName) .. "$")
                if s > 1 then
                    local prefixRaw = string.sub(f, 1, s - 1); local checkMut = prefixRaw
                    checkMut = string.gsub(checkMut, "Big%s*", ""); checkMut = string.gsub(checkMut, "Shiny%s*", "")
                    checkMut = string.gsub(checkMut, "Sparkling%s*", ""); checkMut = string.gsub(checkMut, "Giant%s*", "")
                    checkMut = string.gsub(checkMut, "^%s*(.-)%s*$", "%1")
                    if checkMut == "" then mutation = nil; finalItem = f
                    else mutation = checkMut; finalItem = string.gsub(f, prefixRaw, ""); finalItem = string.gsub(finalItem, "^%s*(.-)%s*$", "%1") end
                else mutation = nil; finalItem = f end
                break
            end
        end
        return { Player = p, Item = finalItem, Mutation = mutation, Weight = w }
    end
    return nil
end

local function CheckAndSend(msg)
    if not ScriptActive then return end
    local cleanMsg = StripTags(msg); local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "evolved enchant stone") then
        local tempMsg = string.gsub(cleanMsg, "^%[Server%]:%s*", "") 
        local p = string.match(tempMsg, "^(.*) obtained an?")
        p = p and p:match("^%s*(.-)%s*$") or "Unknown Player" 
        SendWebhook({ Player = p, Item = "Evolved Enchant Stone", Mutation = "None", Weight = "N/A" }, "EVOLVED")
        return
    end

    if string.find(lowerMsg, "crystalized") then
        local tempMsg = string.gsub(cleanMsg, "^%[Server%]:%s*", "")
        local p, item_full, w = string.match(tempMsg, "^(.*) obtained an? (.*) %((.*)%)")
        if not p then p, item_full = string.match(tempMsg, "^(.*) obtained an? (.*)"); w = "N/A" end

        if p and item_full then
             local finalItem = item_full
             local s, e = string.find(string.lower(item_full), "crystalized")
             if s then
                 finalItem = string.sub(item_full, e + 1)
                 finalItem = string.gsub(finalItem, "^%s+", "")
             end

             local check = string.lower(finalItem)
             local allowed = {"bioluminescent octopus", "blossom jelly", "cute dumbo", "star snail", "blue sea dragon"}
             local isAllowed = false
             for _, v in ipairs(allowed) do if string.find(check, v) then isAllowed = true; break end end

             if isAllowed then SendWebhook({ Player = p, Item = finalItem, Mutation = "Crystalized", Weight = w }, "CRYSTALIZED"); return end
        end
    end

    if string.find(lowerMsg, "obtained an?") or string.find(lowerMsg, "chance!") then
        local data = ParseDataSmart(cleanMsg)
        if data then
            if data.Mutation and string.find(string.lower(data.Mutation), "crystalized") then SendWebhook(data, "CRYSTALIZED") return end
            if string.find(string.lower(data.Item), "evolved enchant stone") then SendWebhook(data, "EVOLVED") return end

            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    if string.find(string.lower(data.Item), "ruby") then
                        if data.Mutation and string.find(string.lower(data.Mutation), "gemstone") then SendWebhook(data, "STONE") end
                    else SendWebhook(data, "STONE") end
                    return
                end
            end
            
            for _, name in pairs(SecretList) do 
                if string.find(string.lower(data.Item), string.lower(name)) then 
                    SendWebhook(data, "SECRET") 
                    return 
                end 
            end
        end
    end
end

-- Hook Events
if TextChatService then 
    TextChatService.OnIncomingMessage = function(m) 
        if not ScriptActive then return end
        if m.TextSource == nil then CheckAndSend(m.Text) end 
    end 
end

local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3)
if ChatEvents then 
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 3) 
    if OnMessage then 
        table.insert(Connections, OnMessage.OnClientEvent:Connect(function(d) 
            if not ScriptActive then return end
            if d and d.Message then CheckAndSend(d.Message) end 
        end))
    end 
end

table.insert(Connections, Players.PlayerRemoving:Connect(function(p) 
    if not ScriptActive then return end
    task.spawn(function() SendWebhook({ Player = p.Name }, "LEAVE") end) 
end))

-- Send Startup Notification
task.spawn(function()
    task.wait(2) -- Wait for game to fully load just in case
    SendWebhook({}, "STARTUP")
end)

if getgenv then
    getgenv().XAL_StopHeadless = function()
        ScriptActive = false
        for _, v in pairs(Connections) do
            if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
        end
        print("XAL: Stopped Headless Script")
    end
end

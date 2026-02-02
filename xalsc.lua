local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "XALSC - Fish It",
    Icon = "rbxassetid://116236936447443",
    Author = "Premium Version",
    Folder = "XALSC",
    Size = UDim2.fromOffset(600, 360),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
    SideBarWidth = 190,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

local XALSCConfig = Window.ConfigManager:CreateConfig("XALSC")

local ElementRegistry = {} 

local function Reg(id, element)
    XALSCConfig:Register(id, element)
    
    ElementRegistry[id] = element 
    return element
end

local HttpService = game:GetService("HttpService")
local BaseFolder = "WindUI/" .. (Window.Folder or "XALSC") .. "/config/"

local function SmartLoadConfig(configName)
    local path = BaseFolder .. configName .. ".json"
    
    
    if not isfile(path) then 
        WindUI:Notify({ Title = "Gagal Load", Content = "File tidak ditemukan: " .. configName, Duration = 3, Icon = "x" })
        return 
    end

    
    local content = readfile(path)
    local success, decodedData = pcall(function() return HttpService:JSONDecode(content) end)

    if not success or not decodedData then 
        WindUI:Notify({ Title = "Gagal Load", Content = "File JSON rusak/kosong.", Duration = 3, Icon = "alert-triangle" })
        return 
    end

    
    local realData = decodedData
    if decodedData["__elements"] then
        realData = decodedData["__elements"]
    end

    local changeCount = 0
    local foundCount = 0

    
    for _ in pairs(ElementRegistry) do foundCount = foundCount + 1 end
    print("------------------------------------------------")
    print("[SmartLoad] Target Config: " .. configName)
    print("[SmartLoad] Elemen terdaftar di Script: " .. foundCount)

    
    for id, itemData in pairs(realData) do
        local element = ElementRegistry[id] 
        
        if element then
            
            
            local finalValue = itemData
            
            if type(itemData) == "table" and itemData.value ~= nil then
                finalValue = itemData.value
            end

            
            local currentVal = element.Value
            
            
            local isDifferent = false
            
            if type(finalValue) == "table" then
                
                
                isDifferent = true 
            elseif currentVal ~= finalValue then
                isDifferent = true
            end

            
            if isDifferent then
                pcall(function() 
                    element:Set(finalValue) 
                end)
                changeCount = changeCount + 1
                
                
                if changeCount % 10 == 0 then task.wait() end
            end
        end
    end

    print("[SmartLoad] Selesai. Total Update: " .. changeCount)
    print("------------------------------------------------")

    WindUI:Notify({ 
        Title = "Config Loaded", 
        Content = string.format("Updated: %d settings", changeCount), 
        Duration = 3, 
        Icon = "check" 
    })
end

local UserInputService = game:GetService("UserInputService")
local InfinityJumpConnection = nil
local LocalPlayer = game.Players.LocalPlayer
local RepStorage = game:GetService("ReplicatedStorage") 
local ItemUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

local DEFAULT_SPEED = 18
local DEFAULT_JUMP = 50

local function GetHumanoid()
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:FindFirstChildOfClass("Humanoid")
end

local InitialHumanoid = GetHumanoid()
local currentSpeed = DEFAULT_SPEED
local currentJump = DEFAULT_JUMP

if InitialHumanoid then
    currentSpeed = InitialHumanoid.WalkSpeed
    currentJump = InitialHumanoid.JumpPower
end

local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local PlayerDataReplion = nil

local function GetRemote(remotePath, name, timeout)
    local currentInstance = RepStorage
    for _, childName in ipairs(remotePath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

local function GetHRP()
    local Character = game.Players.LocalPlayer.Character
    if not Character then
        Character = game.Players.LocalPlayer.CharacterAdded:Wait()
    end
    return Character:WaitForChild("HumanoidRootPart", 5)
end

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    
    
    for i, v in pairs(getconnections(player.Idled)) do
        if v.Disable then
            v:Disable() 
            print("[XALSC Anti-AFK] ON")
        end
    end
end)

local function TeleportToLookAt(position, lookVector)
    local hrp = GetHRP()
    
    if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
        local targetCFrame = CFrame.new(position, position + lookVector)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
        
        WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin", })
    else
        WindUI:Notify({ Title = "Teleport Gagal", Content = "Data posisi tidak valid.", Duration = 3, Icon = "x", })
    end
end

local function GetPlayerDataReplion()
    if PlayerDataReplion then return PlayerDataReplion end
    local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then return nil end
    local ReplionClient = require(ReplionModule).Client
    PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
    return PlayerDataReplion
end

local RF_SellAllItems = GetRemote(RPath, "RF/SellAllItems", 5)

local function GetFishNameAndRarity(item)
    local name = item.Identifier or "Unknown"
    local rarity = item.Metadata and item.Metadata.Rarity or "COMMON"
    local itemID = item.Id

    local itemData = nil

    if ItemUtility and itemID then
        pcall(function()
            itemData = ItemUtility:GetItemData(itemID)
            if not itemData then
                local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                if numericID then
                    itemData = ItemUtility:GetItemData(numericID)
                end
            end
        end)
    end

    if itemData and itemData.Data and itemData.Data.Name then
        name = itemData.Data.Name
    end

    if item.Metadata and item.Metadata.Rarity then
        rarity = item.Metadata.Rarity
    elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
        local tierObj = nil
        pcall(function()
            tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
        end)

        if tierObj and tierObj.Name then
            rarity = tierObj.Name
        end
    end

    return name, rarity
end

local function GetItemMutationString(item)
    if item.Metadata and item.Metadata.Shiny == true then return "Shiny" end
    return item.Metadata and item.Metadata.VariantId or ""
end

local ShopItems = {
    ["Rods"] = {
        {Name = "Luck Rod", ID = 79, Price = 325}, {Name = "Carbon Rod", ID = 76, Price = 750},
        {Name = "Grass Rod", ID = 85, Price = 1500}, {Name = "Demascus Rod", ID = 77, Price = 3000},
        {Name = "Ice Rod", ID = 78, Price = 5000}, {Name = "Lucky Rod", ID = 4, Price = 15000},
        {Name = "Midnight Rod", ID = 80, Price = 50000}, {Name = "Steampunk Rod", ID = 6, Price = 215000},
        {Name = "Chrome Rod", ID = 7, Price = 437000}, {Name = "Flourescent Rod", ID = 255, Price = 715000},
        {Name = "Astral Rod", ID = 5, Price = 1000000}, {Name = "Ares Rod", ID = 126, Price = 3000000},
        {Name = "Angler Rod", ID = 168, Price = 8000000},{Name = "Bamboo Rod", ID = 258, Price = 12000000}
    },
    ["Bobbers"] = {
        {Name = "Floral Bait", ID = 20, Price = 4000000}, {Name = "Aether Bait", ID = 16, Price = 3700000},
        {Name = "Corrupt Bait", ID = 15, Price = 1148484}, {Name = "Dark Matter Bait", ID = 8, Price = 630000},
        {Name = "Chroma Bait", ID = 6, Price = 290000}, {Name = "Nature Bait", ID = 17, Price = 83500},
        {Name = "Midnight Bait", ID = 3, Price = 3000}, {Name = "Luck Bait", ID = 2, Price = 1000},
        {Name = "Topwater Bait", ID = 10, Price = 100},
    },
    ["Boats"] = {
        {Name = "Mini Yach", ID = 14, Price = 1200000}, {Name = "Fish Boat", ID = 6, Price = 180000},
        {Name = "Speed Boat", ID = 5, Price = 70000}, {Name = "Highfield Boat", ID = 4, Price = 25000},
        {Name = "Jetski", ID = 3, Price = 7500}, {Name = "Kayak", ID = 2, Price = 1100},
        {Name = "Small Boat", ID = 1, Price = 100},
    },
}

do
    local PromptController = nil
    local Promise = nil
    
    pcall(function()
        PromptController = require(RepStorage:WaitForChild("Controllers").PromptController)
        Promise = require(RepStorage:WaitForChild("Packages").Promise)
    end)
    
    _G.XALSC_AutoAcceptTradeEnabled = false 

    if PromptController and PromptController.FirePrompt and Promise then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            
            if _G.XALSC_AutoAcceptTradeEnabled and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
                
                local initiatorName = string.match(promptText, "from: ([^\n]+)") or "Seseorang"
                
                
                return Promise.new(function(resolve)
                    task.wait(2)
                    resolve(true)
                end)
            end
            
            return oldFirePrompt(self, promptText, ...)
        end
    else
        warn("[XALSC] Gagal memuat PromptController/Promise untuk Auto Accept Trade.")
    end
end

local ENCHANT_MAPPING = {
    ["Cursed I"] = 12,
    ["Big Hunter I"] = 3,
    ["Empowered I"] = 9,
    ["Glistening I"] = 1,
    ["Gold Digger I"] = 4,
    ["Leprechaun I"] = 5,
    ["Leprechaun II"] = 6,
    ["Mutation Hunter I"] = 7,
    ["Mutation Hunter II"] = 14,
    ["Perfection"] = 15,
    ["Prismatic I"] = 13,
    ["Reeler I"] = 2,
    ["Stargazer I"] = 8,
    ["Stormhunter I"] = 11,
    ["Experienced I"] = 10,
}
local ENCHANT_NAMES = {} 
for name, id in pairs(ENCHANT_MAPPING) do table.insert(ENCHANT_NAMES, name) end

local autoEnchantState = false
local autoEnchantThread = nil
local selectedRodUUID = nil
local selectedEnchantNames = {}

local ENCHANT_STONE_ID = 10
_G.XALSC_EnchantStoneUUIDs = {}

local function GetEnchantNameFromId(id)
    id = tonumber(id)
    if not id then return nil end
    for name, eid in pairs(ENCHANT_MAPPING) do
        if eid == id then
            return name
        end
    end
    return nil
end

local function GetRodOptions()
    local rodOptions = {}
    local replion = GetPlayerDataReplion()
    if not replion then return {"(Gagal memuat Inventory)"} end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData["Fishing Rods"] then
        return {"(Tidak ada Rod ditemukan)"}
    end

    local Rods = inventoryData["Fishing Rods"]
    for _, rod in ipairs(Rods) do
        local rodUUID = rod.UUID
        
        if typeof(rodUUID) ~= "string" or string.len(rodUUID) < 10 then
            continue
        end
        
        local rodName, _ = GetFishNameAndRarity(rod)
        
        if not string.find(rodName, "Rod", 1, true) then
            continue
        end

        local enchantStatus = ""
        local metadata = rod.Metadata or {}
        local enchants = {}

        if metadata.EnchantId then table.insert(enchants, metadata.EnchantId) end
        

        local resolvedEnchantNames = {}
        for _, eid in ipairs(enchants) do
            local name = GetEnchantNameFromId(eid) or "ID:" .. eid
            table.insert(resolvedEnchantNames, name)
        end
        
        if #resolvedEnchantNames > 0 then
            enchantStatus = " [" .. table.concat(resolvedEnchantNames, ", ") .. "]"
        end

        local shortUUID = string.sub(rodUUID, 1, 8) .. "..."
        table.insert(rodOptions, rodName .. " (" .. shortUUID .. ")" .. enchantStatus)
    end
    
    return rodOptions
end


local function GetUUIDFromFormattedName(formattedName)
    local uuidMatch = formattedName:match("%(([^%)]+)%.%.%.%)")
    if not uuidMatch then return nil end

    local replion = GetPlayerDataReplion()
    local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}

    for _, rod in ipairs(Rods) do
        if string.sub(rod.UUID, 1, 8) == uuidMatch then
            return rod.UUID
        end
    end
    return nil
end

local function CheckIfEnchantReached(rodUUID)
    local replion = GetPlayerDataReplion()
    local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
    
    local targetRod = nil
    for _, rod in ipairs(Rods) do
        if rod.UUID == rodUUID then
            targetRod = rod
            break
        end
    end

    if not targetRod then return true end
    
    local metadata = targetRod.Metadata or {}
    local currentEnchants = {}
    if metadata.EnchantId then table.insert(currentEnchants, metadata.EnchantId) end
    

    for _, targetName in ipairs(selectedEnchantNames) do
        local targetID = ENCHANT_MAPPING[targetName]
        if targetID and table.find(currentEnchants, targetID) then
            return true
        end
    end

    return false
end

local function GetFirstStoneUUID()
    local replion = GetPlayerDataReplion()
    if not replion then return nil end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then
        return nil
    end

    local GeneralItems = inventoryData.Items or {}
    for _, item in ipairs(GeneralItems) do
        if tonumber(item.Id) == ENCHANT_STONE_ID and item.UUID and item.Type ~= "Fishing Rods" and item.Type ~= "Bait" then
            return item.UUID
        end
    end
    return nil
end

local function UnequipAllEquippedItems()
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")
    if not RE_UnequipItem then 
        warn("[Auto Enchant] Gagal menemukan RE/UnequipItem remote.")
        return 
    end

    local replion = GetPlayerDataReplion()
    local EquippedItems = replion:GetExpect("EquippedItems") or {}
    local EquippedSkinUUID = replion:Get("EquippedSkinUUID")

    if EquippedSkinUUID and EquippedSkinUUID ~= "" then
         
         pcall(function() RE_UnequipItem:FireServer(EquippedSkinUUID) end)
         task.wait(0.1)
    end

    for _, uuid in ipairs(EquippedItems) do
        pcall(function() RE_UnequipItem:FireServer(uuid) end)
        task.wait(0.05)
    end
end

local ARTIFACT_IDS = {
    ["Arrow Artifact"] = 265,
    ["Crescent Artifact"] = 266,
    ["Diamond Artifact"] = 267,
    ["Hourglass Diamond Artifact"] = 271
}


local function HasArtifactItem(artifactName)
    local replion = GetPlayerDataReplion()
    if not replion then return false end
    
    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then return false end

    
    local targetId = ARTIFACT_IDS[artifactName]
    
    if not targetId then 
        warn("[Kaitun] ID untuk " .. artifactName .. " tidak ditemukan di tabel Hardcode!")
        return false 
    end

    
    for _, item in ipairs(inventoryData.Items) do
        
        if tonumber(item.Id) == targetId then 
            return true 
        end
    end
    
    return false
end


local function RunAutoEnchantLoop(rodUUID)
    if autoEnchantThread then task.cancel(autoEnchantThread) end
    
    local ENCHANT_ALTAR_POS = Vector3.new(3236.441, -1302.855, 1397.910)
    local ENCHANT_ALTAR_LOOK = Vector3.new(-0.954, -0.000, 0.299)
    
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem")
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RE_ActivateEnchantingAltar = GetRemote(RPath, "RE/ActivateEnchantingAltar")

    if not (RE_UnequipItem and RE_EquipItem and RE_EquipToolFromHotbar and RE_ActivateEnchantingAltar) then
        WindUI:Notify({ Title = "Error Remote", Content = "Remote Enchanting tidak ditemukan.", Duration = 4, Icon = "x" })
        autoEnchantState = false
        return
    end

    autoEnchantThread = task.spawn(function()
        
        UnequipAllEquippedItems()

        task.wait(2.5) 

        TeleportToLookAt(ENCHANT_ALTAR_POS, ENCHANT_ALTAR_LOOK)
        task.wait(1.5)

        WindUI:Notify({ Title = "Auto Enchant Started", Content = "Memulai Roll Enchant...", Duration = 2, Icon = "zap" })

        while autoEnchantState do
            
            if CheckIfEnchantReached(rodUUID) then
                WindUI:Notify({ Title = "Enchant Selesai!", Content = "Rod mencapai salah satu target enchant.", Duration = 5, Icon = "check" })
                break
            end
            
            local enchantStoneUUID = GetFirstStoneUUID() 
            if not enchantStoneUUID then
                WindUI:Notify({ Title = "Stone Habis!", Content = "Tidak ada Enchant Stone yang tersisa di inventaris.", Duration = 5, Icon = "stop-circle" })
                break
            end

            pcall(function() RE_EquipItem:FireServer(rodUUID, "Fishing Rods") end)
            task.wait(0.2)

            pcall(function() RE_EquipItem:FireServer(enchantStoneUUID, "Enchant Stones") end)
            task.wait(0.2)
            
            pcall(function() RE_EquipToolFromHotbar:FireServer(2) end)
            task.wait(0.3)

            pcall(function() RE_ActivateEnchantingAltar:FireServer() end)
            
            task.wait(tradeDelay) 

            pcall(function() RE_EquipToolFromHotbar:FireServer(0) end) 
            
            task.wait(0.5)
        end

        autoEnchantState = false
        local toggle = Window:GetElementByTitle("Enable Auto Enchant") 
        if toggle and toggle.Set then toggle:Set(false) end
        
        WindUI:Notify({ Title = "Auto Enchant Berhenti", Duration = 3, Icon = "x" })
    end)
end

local eventsList = { 
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", 
    "Ghost Worm", "Meteor Rain", "Megalodon Hunt", "Treasure Event"
}

local autoEventTargetName = nil 
local autoEventTeleportState = false
local autoEventTeleportThread = nil


local function FindAndTeleportToTargetEvent()
    local targetName = autoEventTargetName
    if not targetName or targetName == "" then return false end
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local eventModel = nil
    
    if targetName == "Treasure Event" then
        local sunkenFolder = workspace:FindFirstChild("Sunken Wreckage")
        if sunkenFolder then
            eventModel = sunkenFolder:FindFirstChild("Treasure")
        end
    
    elseif targetName == "Worm Hunt" then
        local menuRingsFolder = workspace:FindFirstChild("!!! MENU RINGS")
        if menuRingsFolder then
            for _, child in ipairs(menuRingsFolder:GetChildren()) do
                if child.Name == "Props" then
                    local specificModel = child:FindFirstChild("Model")
                    if specificModel then
                        eventModel = specificModel
                        break
                    end
                end
            end
        end

    else
        local menuRingsFolder = workspace:FindFirstChild("!!! MENU RINGS") 
        if menuRingsFolder then
            for _, container in ipairs(menuRingsFolder:GetChildren()) do
                if container:FindFirstChild(targetName) then
                    eventModel = container:FindFirstChild(targetName)
                    break
                end
            end
        end
    end
    
    if not eventModel then return false end 

    local targetPart = nil
    local positionOffset = Vector3.new(0, 15, 0) 
    
    if targetName == "Megalodon Hunt" then
        targetPart = eventModel:FindFirstChild("Top") 
        if targetPart then positionOffset = Vector3.new(0, 3, 0) end
    elseif targetName == "Treasure Event" then
        targetPart = eventModel
        positionOffset = Vector3.new(0, 5, 0)
    else
        targetPart = eventModel:FindFirstChild("Fishing Boat")
        if not targetPart then targetPart = eventModel end
        positionOffset = Vector3.new(0, 15, 0)
    end

    if not targetPart then return false end

    local targetCFrame = nil
    
    local success = pcall(function()
        if targetPart:IsA("Model") then
             targetCFrame = targetPart:GetPivot()
        elseif targetPart:IsA("BasePart") then
             targetCFrame = targetPart.CFrame
        end
    end)

    if success and targetCFrame and typeof(targetCFrame) == "CFrame" then
        local position = targetCFrame.p + positionOffset
        local lookVector = targetCFrame.LookVector
        
        TeleportToLookAt(position, lookVector)
        
        WindUI:Notify({
            Title = "Event Found!",
            Content = "Teleported to: " .. targetName,
            Icon = "map-pin",
            Duration = 3
        })
        return true
    end
    
    return false
end

local function RunAutoEventTeleportLoop()
    if autoEventTeleportThread then task.cancel(autoEventTeleportThread) end

    autoEventTeleportThread = task.spawn(function()
        WindUI:Notify({ Title = "Auto Event TP ON", Content = "Mulai memindai event terpilih.", Duration = 3, Icon = "search" })
        
        while autoEventTeleportState do
            
            if FindAndTeleportToTargetEvent() then
                
                task.wait(900) 
            else
                
                task.wait(10)
            end
        end
        
        WindUI:Notify({ Title = "Auto Event TP OFF", Duration = 3, Icon = "x" })
    end)
end

local function CensorName(name)
    if not name or type(name) ~= "string" or #name < 1 then
        return "N/A" 
    end
    
    if #name <= 3 then
        return name
    end

    local prefix = name:sub(1, 3)
    
    local censureLength = #name - 3
    
    local censorString = string.rep("*", censureLength)
    
    return prefix .. censorString
end

local FishingAreas = {
        ["Iron Cavern"] = {Pos = Vector3.new(-8792.546, -588.000, 230.642), Look = Vector3.new(0.718, 0.000, 0.696)},
        ["Classic Island"] = {Pos = Vector3.new(1440.843, 46.062, 2777.175), Look = Vector3.new(0.940, -0.000, 0.342)},
        ["Ancient Jungle"] = {Pos = Vector3.new(1535.639, 3.159, -193.352), Look = Vector3.new(0.505, -0.000, 0.863)},
        ["Coral Reef"] = {Pos = Vector3.new(-3207.538, 6.087, 2011.079), Look = Vector3.new(0.973, 0.000, 0.229)},
        ["Crater Island"] = {Pos = Vector3.new(1058.976, 2.330, 5032.878), Look = Vector3.new(-0.789, 0.000, 0.615)},
        ["Crystalline Passage"] = {Pos = Vector3.new(6051.567, -538.900, 4370.979), Look = Vector3.new(0.109, 0.000, 0.994)},
        ["Ancient Ruin"] = {Pos = Vector3.new(6031.981, -585.924, 4713.157), Look = Vector3.new(0.316, -0.000, -0.949)},
        ["Enchant Room"] = {Pos = Vector3.new(3255.670, -1301.530, 1371.790), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Esoteric Island"] = {Pos = Vector3.new(2164.470, 3.220, 1242.390), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Fisherman Island"] = {Pos = Vector3.new(74.030, 9.530, 2705.230), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Kohana"] = {Pos = Vector3.new(-668.732, 3.000, 681.580), Look = Vector3.new(0.889, -0.000, 0.458)},
        ["Lost Isle"] = {Pos = Vector3.new(-3804.105, 2.344, -904.653), Look = Vector3.new(-0.901, -0.000, 0.433)},
        ["Sacred Temple"] = {Pos = Vector3.new(1461.815, -22.125, -670.234), Look = Vector3.new(-0.990, -0.000, 0.143)},
        ["Second Enchant Altar"] = {Pos = Vector3.new(1479.587, 128.295, -604.224), Look = Vector3.new(-0.298, 0.000, -0.955)},
        ["Sisyphus Statue"] = {Pos = Vector3.new(-3743.745, -135.074, -1007.554), Look = Vector3.new(0.310, 0.000, 0.951)},
        ["Treasure Room"] = {Pos = Vector3.new(-3598.440, -281.274, -1645.855), Look = Vector3.new(-0.065, 0.000, -0.998)},
        ["Tropical Island"] = {Pos = Vector3.new(-2162.920, 2.825, 3638.445), Look = Vector3.new(0.381, -0.000, 0.925)},
        ["Underground Cellar"] = {Pos = Vector3.new(2118.417, -91.448, -733.800), Look = Vector3.new(0.854, 0.000, 0.521)},
        ["Volcano"] = {Pos = Vector3.new(-605.121, 19.516, 160.010), Look = Vector3.new(0.854, 0.000, 0.520)},
    }
    local AreaNames = {}
    for name, _ in pairs(FishingAreas) do
        table.insert(AreaNames, name)
    end

do
    local player = Window:Tab({
        Title = "Player",
        Icon = "user",
        Locked = false,
    })

    
    local movement = player:Section({
        Title = "Movement",
        TextSize = 20,
    })

    
    local SliderSpeed = Reg("Walkspeed",movement:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = {
            Min = 16,
            Max = 200,
            Default = currentSpeed,
        },
        Callback = function(value)
            local speedValue = tonumber(value)
            if speedValue and speedValue >= 0 then
                local Humanoid = GetHumanoid()
                if Humanoid then
                    Humanoid.WalkSpeed = speedValue
                end
            end
        end,
    }))

    
    local SliderJump = Reg("slidjump",movement:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = {
            Min = 50,
            Max = 200,
            Default = currentJump,
        },
        Callback = function(value)
            local jumpValue = tonumber(value)
            if jumpValue and jumpValue >= 50 then
                local Humanoid = GetHumanoid()
                if Humanoid then
                    Humanoid.JumpPower = jumpValue
                end
            end
        end,
    }))
    
    
    local reset = movement:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Locked = false,
        Callback = function()
            local Humanoid = GetHumanoid()
            if Humanoid then
                Humanoid.WalkSpeed = DEFAULT_SPEED
                Humanoid.JumpPower = DEFAULT_JUMP
                SliderSpeed:Set(DEFAULT_SPEED)
                SliderJump:Set(DEFAULT_JUMP)
                WindUI:Notify({
                    Title = "Movement Direset",
                    Content = "WalkSpeed & JumpPower Reset to default",
                    Duration = 3,
                    Icon = "check",
                })
            end
        end
    })

    
    local freezeplr = Reg("frezee",movement:Toggle({
        Title = "Freeze Player",
        Desc = "Membekukan karakter di posisi saat ini (Anti-Push).",
        Value = false,
        Callback = function(state)
            local character = LocalPlayer.Character
            if not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                
                hrp.Anchored = state
                
                if state then
                    
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    
                    WindUI:Notify({ 
                        Title = "Player Frozen", 
                        Content = "Posisi dikunci (Anchored).", 
                        Duration = 2, 
                        Icon = "lock" 
                    })
                else
                    WindUI:Notify({ 
                        Title = "Player Unfrozen", 
                        Content = "Gerakan kembali normal.", 
                        Duration = 2, 
                        Icon = "unlock" 
                    })
                end
            else
                WindUI:Notify({ Title = "Error", Content = "HumanoidRootPart tidak ditemukan.", Duration = 3, Icon = "alert-triangle" })
            end
        end
    }))

    
    local ability = player:Section({
        Title = "Abilities",
        TextSize = 20,
    })

    
    local infjump = Reg("infj", ability:Toggle({
        Title = "Infinite Jump",
        Value = false,
        Callback = function(state)
            if state then
                WindUI:Notify({ Title = "Infinite Jump ON!", Duration = 3, Icon = "check", })
                InfinityJumpConnection = UserInputService.JumpRequest:Connect(function()
                    local Humanoid = GetHumanoid()
                    if Humanoid and Humanoid.Health > 0 then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                WindUI:Notify({ Title = "Infinite Jump OFF!", Duration = 3, Icon = "check", })
                if InfinityJumpConnection then
                    InfinityJumpConnection:Disconnect()
                    InfinityJumpConnection = nil
                end
            end
        end
    }))

    
    local noclipConnection = nil
    local isNoClipActive = false
    local noclip = Reg("nclip",ability:Toggle({
        Title = "No Clip",
        Value = false,
        Callback = function(state)
            isNoClipActive = state
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            if state then
                WindUI:Notify({ Title = "No Clip ON!", Duration = 3, Icon = "check", })
                noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                    if isNoClipActive and character then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                WindUI:Notify({ Title = "No Clip OFF!", Duration = 3, Icon = "x", })
                if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end

                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    }))

    
    local flyConnection = nil
    local isFlying = false
    local flySpeed = 60
    local bodyGyro, bodyVel
    local flytog = Reg("flym",ability:Toggle({
        Title = "Fly Mode",
        Value = false,
        Callback = function(state)
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")

            if state then
                WindUI:Notify({ Title = "Fly Mode ON!", Duration = 3, Icon = "check", })
                isFlying = true

                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = humanoidRootPart.CFrame
                bodyGyro.Parent = humanoidRootPart

                bodyVel = Instance.new("BodyVelocity")
                bodyVel.Velocity = Vector3.zero
                bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVel.Parent = humanoidRootPart

                local cam = workspace.CurrentCamera
                local moveDir = Vector3.zero
                local jumpPressed = false

                UserInputService.JumpRequest:Connect(function()
                    if isFlying then jumpPressed = true task.delay(0.2, function() jumpPressed = false end) end
                end)

                flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    if not isFlying or not humanoidRootPart or not bodyGyro or not bodyVel then return end
                    
                    bodyGyro.CFrame = cam.CFrame
                    moveDir = humanoid.MoveDirection

                    if jumpPressed then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                    end

                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * flySpeed end

                    bodyVel.Velocity = moveDir
                end)

            else
                WindUI:Notify({ Title = "Fly Mode OFF!", Duration = 3, Icon = "x", })
                isFlying = false

                if flyConnection then flyConnection:Disconnect() flyConnection = nil end
                if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
                if bodyVel then bodyVel:Destroy() bodyVel = nil end
            end
        end
    }))

   
    local walkOnWaterConnection = nil
    local isWalkOnWater = false
    local waterPlatform = nil
    
    local walkon = Reg("walkwat",ability:Toggle({
        Title = "Walk on Water",
        Value = false,
        Callback = function(state)
            

            if state then
                WindUI:Notify({ Title = "Walk on Water ON!", Duration = 3, Icon = "check", })
                isWalkOnWater = true
                
                
                if not waterPlatform then
                    waterPlatform = Instance.new("Part")
                    waterPlatform.Name = "WaterPlatform"
                    waterPlatform.Anchored = true
                    waterPlatform.CanCollide = true
                    waterPlatform.Transparency = 1 
                    waterPlatform.Size = Vector3.new(15, 1, 15) 
                    waterPlatform.Parent = workspace
                end

                
                if walkOnWaterConnection then walkOnWaterConnection:Disconnect() end

                walkOnWaterConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    
                    local character = LocalPlayer.Character
                    if not isWalkOnWater or not character then return end
                    
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    
                    if not waterPlatform or not waterPlatform.Parent then
                        waterPlatform = Instance.new("Part")
                        waterPlatform.Name = "WaterPlatform"
                        waterPlatform.Anchored = true
                        waterPlatform.CanCollide = true
                        waterPlatform.Transparency = 1 
                        waterPlatform.Size = Vector3.new(15, 1, 15)
                        waterPlatform.Parent = workspace
                    end

                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {workspace.Terrain} 
                    rayParams.FilterType = Enum.RaycastFilterType.Include 
                    rayParams.IgnoreWater = false 

                    
                    local rayOrigin = hrp.Position + Vector3.new(0, 5, 0) 
                    local rayDirection = Vector3.new(0, -500, 0)

                    local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                    
                    if result and result.Material == Enum.Material.Water then
                        
                        local waterSurfaceHeight = result.Position.Y
                        
                        
                        waterPlatform.Position = Vector3.new(hrp.Position.X, waterSurfaceHeight, hrp.Position.Z)
                        
                        
                        if hrp.Position.Y < (waterSurfaceHeight + 2) and hrp.Position.Y > (waterSurfaceHeight - 5) then
                             
                            if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                                hrp.CFrame = CFrame.new(hrp.Position.X, waterSurfaceHeight + 3.2, hrp.Position.Z)
                            end
                        end
                    else
                        
                        waterPlatform.Position = Vector3.new(hrp.Position.X, -500, hrp.Position.Z)
                    end
                end)

            else
                WindUI:Notify({ Title = "Walk on Water OFF!", Duration = 3, Icon = "x", })
                isWalkOnWater = false
                if walkOnWaterConnection then walkOnWaterConnection:Disconnect() walkOnWaterConnection = nil end
                if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
            end
        end
    }))
    
end


do
    local farm = Window:Tab({
        Title = "Fishing",
        Icon = "fish",
        Locked = false,
    })

    
    
    
    
    local legitAutoState = false
    local normalInstantState = false
    local blatantInstantState = false
    
    
    local normalLoopThread = nil
    local blatantLoopThread = nil
    
    
    local normalEquipThread = nil
    local blatantEquipThread = nil
    local legitEquipThread = nil 

    local NormalInstantSlider = nil

    
    local isTeleportFreezeActive = false
    local freezeToggle = nil
    local selectedArea = nil
    
    local savedPosition = nil 

    
    
    
    
    local function GetHRP()
        local Character = game.Players.LocalPlayer.Character
        if not Character then
            Character = game.Players.LocalPlayer.CharacterAdded:Wait()
        end
        return Character:WaitForChild("HumanoidRootPart", 5)
    end
    
    local function TeleportToLookAt(position, lookVector)
        local hrp = GetHRP()
        
        if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
            local targetCFrame = CFrame.new(position, position + lookVector)
            hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
            
            WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin", })
        else
            WindUI:Notify({ Title = "Teleport Gagal", Duration = 3, Icon = "x", })
        end
    end
    
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
    local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")

    local function checkFishingRemotes(silent)
        local remotes = { RE_EquipToolFromHotbar, RF_ChargeFishingRod, RF_RequestFishingMinigameStarted,
                          RE_FishingCompleted, RF_CancelFishingInputs, RF_UpdateAutoFishingState }
        for _, remote in ipairs(remotes) do
            if not remote then
                if not silent then
                    WindUI:Notify({ Title = "Remote Error!", Content = "Remote Fishing tidak ditemukan! Cek jalur RPath.", Duration = 5, Icon = "x", })
                end
                return false
            end
        end
        return true
    end

    local function disableOtherModes(currentMode)
        pcall(function()
            
            local toggleLegit = farm:GetElementByTitle("Auto Fish (Legit)")
            local toggleNormal = farm:GetElementByTitle("Normal Instant Fish")
            local toggleBlatant = farm:GetElementByTitle("Instant Fishing (Blatant)")

            if currentMode ~= "legit" and legitAutoState then 
                legitAutoState = false
                if toggleLegit and toggleLegit.Set then toggleLegit:Set(false) end
                if legitClickThread then task.cancel(legitClickThread) legitClickThread = nil end
                if legitEquipThread then task.cancel(legitEquipThread) legitEquipThread = nil end 
            end
            if currentMode ~= "normal" and normalInstantState then 
                normalInstantState = false
                if toggleNormal and toggleNormal.Set then toggleNormal:Set(false) end
                if normalLoopThread then task.cancel(normalLoopThread) normalLoopThread = nil end
                if normalEquipThread then task.cancel(normalEquipThread) normalEquipThread = nil end
            end
            if currentMode ~= "blatant" and blatantInstantState then 
                blatantInstantState = false
                if toggleBlatant and toggleBlatant.Set then toggleBlatant:Set(false) end
                if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
                if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end 
            end
        end)
        
        
        if currentMode ~= "legit" then
            pcall(function() if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end end)
        end
    end
    
    
    
    

    local FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
    local AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)

    local AutoFishState = {
        IsActive = false,
        MinigameActive = false
    }

    local SPEED_LEGIT = 0.05
    local legitClickThread = nil

    local function performClick()
        if FishingController then
            FishingController:RequestFishingMinigameClick()
            task.wait(SPEED_LEGIT)
        end
    end
    
    
    local originalRodStarted = FishingController.FishingRodStarted
    FishingController.FishingRodStarted = function(self, arg1, arg2)
        originalRodStarted(self, arg1, arg2)

        if AutoFishState.IsActive and not AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = true

            if legitClickThread then
                task.cancel(legitClickThread)
            end

            legitClickThread = task.spawn(function()
                while AutoFishState.IsActive and AutoFishState.MinigameActive do
                    performClick()
                end
            end)
        end
    end

    
    local originalFishingStopped = FishingController.FishingStopped
    FishingController.FishingStopped = function(self, arg1)
        originalFishingStopped(self, arg1)

        if AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = false
        end
    end

    local function ensureServerAutoFishingOn()
        local replionClient = require(RepStorage:WaitForChild("Packages").Replion).Client
        local replionData = replionClient:WaitReplion("Data", 5)

        local remoteFunctionName = "RF/UpdateAutoFishingState"
        local UpdateAutoFishingRemote = GetRemote(RPath, remoteFunctionName)

        if UpdateAutoFishingRemote then
            pcall(function()
                UpdateAutoFishingRemote:InvokeServer(true)
            end)
        end
    end
    
    local function ToggleAutoClick(shouldActivate)
        if not FishingController or not AutoFishingController then
            WindUI:Notify({ Title = "Error", Content = "Gagal memuat Fishing Controllers.", Duration = 4, Icon = "x" })
            return
        end
        
        AutoFishState.IsActive = shouldActivate

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local fishingGui = playerGui:FindFirstChild("Fishing") and playerGui.Fishing:FindFirstChild("Main")
        local chargeGui = playerGui:FindFirstChild("Charge") and playerGui.Charge:FindFirstChild("Main")


        if shouldActivate then
            
            pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
            
            
            ensureServerAutoFishingOn()
            
            
            if fishingGui then fishingGui.Visible = false end
            if chargeGui then chargeGui.Visible = false end

            WindUI:Notify({ Title = "Auto Fish Legit ON!", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "check" })

        else
            if legitClickThread then
                task.cancel(legitClickThread)
                legitClickThread = nil
            end
            AutoFishState.MinigameActive = false
            
            
            if fishingGui then fishingGui.Visible = true end
            if chargeGui then chargeGui.Visible = true end

            WindUI:Notify({ Title = "Auto Fish Legit OFF!", Duration = 3, Icon = "x" })
        end
    end

    
    
    
    local autofish = farm:Section({
        Title = "Auto Fishing",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    
    local slidlegit = Reg("klikd",autofish:Slider({
        Title = "Legit Click Speed (Delay)",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = SPEED_LEGIT },
        Callback = function(value)
            local newSpeed = tonumber(value)
            if newSpeed and newSpeed >= 0.01 then
                SPEED_LEGIT = newSpeed
            end
        end
    }))

    local toglegit = Reg("legit",autofish:Toggle({
        Title = "Auto Fish (Legit)",
        Value = false,
        Callback = function(state)
            if not checkFishingRemotes() then return false end
            disableOtherModes("legit")
            legitAutoState = state
            ToggleAutoClick(state)

            
            if state then
                if legitEquipThread then task.cancel(legitEquipThread) end
                legitEquipThread = task.spawn(function()
                    while legitAutoState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                        task.wait(0.1) 
                    end
                end)
            else
                if legitEquipThread then task.cancel(legitEquipThread) legitEquipThread = nil end
            end
        end
    }))

    farm:Divider()
    
    
    local normalCompleteDelay = 1.50

    NormalInstantSlider = Reg("normalslid",autofish:Slider({
        Title = "Normal Complete Delay",
        Step = 0.05,
        Value = { Min = 0.5, Max = 5.0, Default = normalCompleteDelay },
        Callback = function(value) normalCompleteDelay = tonumber(value) end
    }))

    
    local function runNormalInstant()
        if not normalInstantState then return end
        if not checkFishingRemotes(true) then normalInstantState = false return end
        
        local timestamp = os.time() + os.clock()
        pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
        pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797) end)
        
        task.wait(normalCompleteDelay)
        
        pcall(function() RE_FishingCompleted:FireServer() end)
        task.wait(0.3)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
    end

    local normalins = Reg("tognorm",autofish:Toggle({
        Title = "Normal Instant Fish",
        Value = false,
        Callback = function(state)
            if not checkFishingRemotes() then return end
            disableOtherModes("normal")
            normalInstantState = state
            
            if state then
                
                normalLoopThread = task.spawn(function()
                    while normalInstantState do
                        runNormalInstant()
                        task.wait(0.1) 
                    end
                end)

                
                if normalEquipThread then task.cancel(normalEquipThread) end
                normalEquipThread = task.spawn(function()
                    while normalInstantState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                        task.wait(0.1) 
                    end
                end)
                
                WindUI:Notify({ Title = "Auto Fish ON", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "fish" })
            else
                
                if normalLoopThread then task.cancel(normalLoopThread) normalLoopThread = nil end
                if normalEquipThread then task.cancel(normalEquipThread) normalEquipThread = nil end
                
                pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
                WindUI:Notify({ Title = "Auto Fish OFF", Duration = 3, Icon = "x" })
            end
        end
    }))


    
    local blatant = farm:Section({ Title = "Blatant Mode", TextSize = 20, })

    local completeDelay = 3.055
    local cancelDelay = 0.3
    local loopInterval = 1.715
    
    _G.XALSC_BlatantActive = false

    
    task.spawn(function()
        local S1, FishingController = pcall(function() return require(game:GetService("ReplicatedStorage").Controllers.FishingController) end)
        if S1 and FishingController then
            local Old_Charge = FishingController.RequestChargeFishingRod
            local Old_Cast = FishingController.SendFishingRequestToServer
            
            
            FishingController.RequestChargeFishingRod = function(...)
                if _G.XALSC_BlatantActive then return end 
                return Old_Charge(...)
            end
            FishingController.SendFishingRequestToServer = function(...)
                if _G.XALSC_BlatantActive then return false, "Blocked by XALSC" end
                return Old_Cast(...)
            end
        end
    end)

    
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if _G.XALSC_BlatantActive and not checkcaller() then
            
            if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then
                return nil 
            end
            if method == "FireServer" and self.Name == "FishingCompleted" then
                return nil
            end
        end
        return old_namecall(self, ...)
    end)
    setreadonly(mt, true)

    
    
    local function SuppressGameVisuals(active)
        
        local Succ, TextController = pcall(function() return require(game.ReplicatedStorage.Controllers.TextNotificationController) end)
        if Succ and TextController then
            if active then
                if not TextController._OldDeliver then TextController._OldDeliver = TextController.DeliverNotification end
                TextController.DeliverNotification = function(self, data)
                    
                    if data and data.Text and (string.find(tostring(data.Text), "Auto Fishing") or string.find(tostring(data.Text), "Reach Level")) then
                        return 
                    end
                    return TextController._OldDeliver(self, data)
                end
            elseif TextController._OldDeliver then
                TextController.DeliverNotification = TextController._OldDeliver
                TextController._OldDeliver = nil
            end
        end

        
        if active then
            task.spawn(function()
                local RunService = game:GetService("RunService")
                local CollectionService = game:GetService("CollectionService")
                local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
                
                
                local InactiveColor = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("ff5d60")), 
                    ColorSequenceKeypoint.new(1, Color3.fromHex("ff2256"))
                })

                while _G.XALSC_BlatantActive do
                    
                    local targets = {}
                    
                    
                    for _, btn in ipairs(CollectionService:GetTagged("AutoFishingButton")) do
                        table.insert(targets, btn)
                    end
                    
                    
                    if #targets == 0 then
                        local btn = PlayerGui:FindFirstChild("Backpack") and PlayerGui.Backpack:FindFirstChild("AutoFishingButton")
                        if btn then table.insert(targets, btn) end
                    end

                    
                    for _, btn in ipairs(targets) do
                        local grad = btn:FindFirstChild("UIGradient")
                        if grad then
                            grad.Color = InactiveColor 
                        end
                    end
                    
                    RunService.RenderStepped:Wait()
                end
            end)
        end
    end

    
    local LoopIntervalInput = Reg("blatantint", blatant:Input({
        Title = "Blatant Interval", Value = tostring(loopInterval), Icon = "fast-forward", Type = "Input", Placeholder = "1.58",
        Callback = function(input)
            local newInterval = tonumber(input)
            if newInterval and newInterval >= 0.5 then loopInterval = newInterval end
        end
    }))

    local CompleteDelayInput = Reg("blatantcom", blatant:Input({
        Title = "Complete Delay", Value = tostring(completeDelay), Icon = "loader", Type = "Input", Placeholder = "2.75",
        Callback = function(input)
            local newDelay = tonumber(input)
            if newDelay and newDelay >= 0.5 then completeDelay = newDelay end
        end
    }))

    local CancelDelayInput = Reg("blatantcanc",blatant:Input({
        Title = "Cancel Delay", Value = tostring(cancelDelay), Icon = "clock", Type = "Input", Placeholder = "0.3", Flag = "canlay",
        Callback = function(input)
            local newDelay = tonumber(input)
            if newDelay and newDelay >= 0.1 then cancelDelay = newDelay end
        end
    }))

    local function runBlatantInstant()
        if not blatantInstantState then return end
        if not checkFishingRemotes(true) then blatantInstantState = false return end

        task.spawn(function()
            local startTime = os.clock()
            local timestamp = os.time() + os.clock()
            
            
            pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
            task.wait(0.001)
            pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797) end)
            
            local completeWaitTime = completeDelay - (os.clock() - startTime)
            if completeWaitTime > 0 then task.wait(completeWaitTime) end
            
            pcall(function() RE_FishingCompleted:FireServer() end)
            task.wait(cancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        end)
    end

    local togblat = Reg("blatantt",blatant:Toggle({
        Title = "Instant Fishing (Blatant)",
        Value = false,
        Callback = function(state)
            if not checkFishingRemotes() then return end
            disableOtherModes("blatant")
            blatantInstantState = state
            _G.XALSC_BlatantActive = state
            
            
            SuppressGameVisuals(state)
            
            if state then
                
                if RF_UpdateAutoFishingState then
                    pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
                end
                task.wait(0.5)
                if RF_UpdateAutoFishingState then
                    pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
                end
                if RF_UpdateAutoFishingState then
                    pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
                end

                
                blatantLoopThread = task.spawn(function()
                    while blatantInstantState do
                        runBlatantInstant()
                        task.wait(loopInterval)
                    end
                end)

                
                if blatantEquipThread then task.cancel(blatantEquipThread) end
                blatantEquipThread = task.spawn(function()
                    while blatantInstantState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                        task.wait(0.1) 
                    end
                end)
                
                WindUI:Notify({ Title = "Blatant Mode ON", Duration = 3, Icon = "zap" })
            else
                
                if RF_UpdateAutoFishingState then
                    pcall(function() RF_UpdateAutoFishingState:InvokeServer(false) end)
                end

                if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
                if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end
                
                WindUI:Notify({ Title = "Stopped", Duration = 2 })
            end
        end
    }))

    farm:Divider()

    
    
    
    local areafish = farm:Section({
        Title = "Fishing Area",
        TextSize = 20,
    })

    
    local choosearea = areafish:Dropdown({
        Title = "Choose Area",
        Values = AreaNames,
        AllowNone = true,
        Value = nil,
        Callback = function(option)
            selectedArea = option
            local display = option or "None"
        end
    })

    local freezeToggle = areafish:Toggle({
        Title = "Teleport & Freeze at Area (Fix Server Lag)",
        Desc = "Teleport -> Tunggu Sync Server -> Freeze.",
        Value = false,
        Callback = function(state)
            isTeleportFreezeActive = state
            
            local hrp = GetHRP()
            if not hrp then
                if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end
                return
            end

            if state then
                if not selectedArea then
                    WindUI:Notify({ Title = "Aksi Gagal", Content = "Pilih Area dulu di Dropdown!", Duration = 3, Icon = "alert-triangle", })
                    if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end
                    return
                end
                
                local areaData = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]

                if not areaData or not areaData.Pos or not areaData.Look then
                    WindUI:Notify({ Title = "Aksi Gagal", Duration = 3, Icon = "alert-triangle", })
                    if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end
                    return
                end
                
                
                hrp.Anchored = false
                
                
                TeleportToLookAt(areaData.Pos, areaData.Look)
                
                
                WindUI:Notify({ Title = "Syncing Zone...", Content = "Menahan posisi agar server membaca lokasi baru...", Duration = 1.5, Icon = "wifi" })
                
                local startTime = os.clock()
                
                while (os.clock() - startTime) < 1.5 and isTeleportFreezeActive do
                    if hrp then
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        
                        hrp.CFrame = CFrame.new(areaData.Pos, areaData.Pos + areaData.Look) * CFrame.new(0, 0.5, 0)
                    end
                    game:GetService("RunService").Heartbeat:Wait()
                end
                
                
                if isTeleportFreezeActive and hrp then
                    hrp.Anchored = true
                    WindUI:Notify({ Title = "Ready to Fish", Content = "Posisi dikunci & Zona terupdate.", Duration = 2, Icon = "check" })
                end
                
            else
                
                if hrp then hrp.Anchored = false end
                WindUI:Notify({ Title = "Unfrozen", Content = "Gerakan kembali normal.", Duration = 2, Icon = "unlock" })
            end
        end
    })

    local teleto = areafish:Button({
        Title = "Teleport to Choosen Area",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedArea then
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Pilih Area dulu di Dropdown.", Duration = 3, Icon = "alert-triangle", })
                return
            end

            local areaData = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]
            
            if not areaData or not areaData.Pos or not areaData.Look then
                WindUI:Notify({ Title = "Teleport Gagal",Duration = 3, Icon = "alert-triangle", })
                return
            end

            if isTeleportFreezeActive and freezeToggle then
                freezeToggle:Set(false)
                task.wait(0.1)
            end
            
            TeleportToLookAt(areaData.Pos, areaData.Look)
        end
    })

    farm:Divider()

    
    local savepos = areafish:Button({
        Title = "Save Current Position",
        Icon = "map-pin",
        Callback = function()
            local hrp = GetHRP()
            if hrp then
                savedPosition = {
                    Pos = hrp.Position,
                    Look = hrp.CFrame.LookVector
                }
                FishingAreas["Custom: Saved"] = savedPosition
                WindUI:Notify({
                    Title = "Posisi Disimpan!",
                    Duration = 3,
                    Icon = "save",
                })
            else
                WindUI:Notify({ Title = "Gagal Simpan", Duration = 3, Icon = "x", })
            end
        end
    })

    
    
    local teletosave = areafish:Button({
        Title = "Teleport to SAVED Pos",
        Icon = "navigation",
        Callback = function()
            if not savedPosition then
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Belum ada posisi yang disimpan.", Duration = 3, Icon = "alert-triangle", })
                return
            end
            
            local areaData = savedPosition
            
            if isTeleportFreezeActive and freezeToggle then
                freezeToggle:Set(false)
                task.wait(0.1)
            end
            
            TeleportToLookAt(areaData.Pos, areaData.Look)
        end
    })
end

do
    local automatic = Window:Tab({
        Title = "Automatic",
        Icon = "loader",
        Locked = false,
    })

    
    local sellDelay = 50
    local autoSellDelayState = false
    local autoSellDelayThread = nil
    local sellCount = 50
    local autoSellCountState = false
    local autoSellCountThread = nil

    
    local autoFavoriteState = false
    local autoFavoriteThread = nil
    local autoUnfavoriteState = false
    local autoUnfavoriteThread = nil
    local selectedRarities = {}
    local selectedItemNames = {}
    local selectedMutations = {}

    local RE_FavoriteItem = GetRemote(RPath, "RE/FavoriteItem")

    
    local function GetFishCount()
        local replion = GetPlayerDataReplion()
        if not replion then return 0 end

        local totalFishCount = 0
        local success, inventoryData = pcall(function()
            return replion:GetExpect("Inventory")
        end)
        
        if not success or not inventoryData or not inventoryData.Items or typeof(inventoryData.Items) ~= "table" then
            return 0
        end

        for _, item in ipairs(inventoryData.Items) do
            local isSellableFish = false

            
            if item.Type == "Fishing Rods" or item.Type == "Boats" or item.Type == "Bait" or item.Type == "Pets" or item.Type == "Chests" or item.Type == "Crates" or item.Type == "Totems" then
                continue
            end
            if item.Identifier and (item.Identifier:match("Artifact") or item.Identifier:match("Key") or item.Identifier:match("Token") or item.Identifier:match("Booster") or item.Identifier:match("hourglass")) then
                continue
            end
            
            
            if item.Metadata and item.Metadata.Weight then
                isSellableFish = true
            elseif item.Type == "Fish" or (item.Identifier and item.Identifier:match("fish")) then
                isSellableFish = true
            end

            if isSellableFish then
                totalFishCount = totalFishCount + (item.Count or 1)
            end
        end
        
        return totalFishCount
    end

    
    local function disableOtherAutoSell(currentMode)
        if currentMode ~= "delay" and autoSellDelayState then
            autoSellDelayState = false
            local toggle = automatic:GetElementByTitle("Auto Sell All (Delay)")
            if toggle and toggle.Set then toggle:Set(false) end
            if autoSellDelayThread then task.cancel(autoSellDelayThread) autoSellDelayThread = nil end
        end
        if currentMode ~= "count" and autoSellCountState then
            autoSellCountState = false
            local toggle = automatic:GetElementByTitle("Auto Sell by Count")
            if toggle and toggle.Set then toggle:Set(false) end
            if autoSellCountThread then task.cancel(autoSellCountThread) autoSellCountThread = nil end
        end
    end

    
    local function RunAutoSellDelayLoop()
        if autoSellDelayThread then task.cancel(autoSellDelayThread) end
        autoSellDelayThread = task.spawn(function()
            while autoSellDelayState do
                if RF_SellAllItems then
                    pcall(function() RF_SellAllItems:InvokeServer() end)
                end
                task.wait(math.max(sellDelay, 1))
            end
        end)
    end
    
    
    local function RunAutoSellCountLoop()
        if autoSellCountThread then task.cancel(autoSellCountThread) end
        autoSellCountThread = task.spawn(function()
            while autoSellCountState do
                local currentCount = GetFishCount()
                
                if currentCount >= sellCount then
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                        task.wait(1)
                    end
                end
                task.wait(1)
            end
        end)
    end


   
    
    
    local sellall = automatic:Section({ Title = "Autosell Fish", TextSize = 20 })

    
    local autoSellMethod = "Delay" 
    local autoSellValue = 50       
    local autoSellState = false
    local autoSellThread = nil

    
    local function RunAutoSellLoop()
        if autoSellThread then task.cancel(autoSellThread) end
        
        autoSellThread = task.spawn(function()
            while autoSellState do
                if autoSellMethod == "Delay" then
                    
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                    end
                    
                    task.wait(math.max(autoSellValue, 1))

                elseif autoSellMethod == "Count" then
                    
                    local currentCount = GetFishCount() 
                    
                    if currentCount >= autoSellValue then
                        if RF_SellAllItems then
                            pcall(function() RF_SellAllItems:InvokeServer() end)
                            WindUI:Notify({ Title = "Auto Sell", Content = "Menjual " .. currentCount .. " items.", Duration = 2, Icon = "dollar-sign" })
                            task.wait(2) 
                        end
                    end
                    task.wait(1) 
                end
            end
        end)
    end

    
    
    
    local inputElement 
    
    local dropMethod = sellall:Dropdown({
        Title = "Select Method",
        Values = {"Delay", "Count"},
        Value = "Delay",
        Multi = false,
        AllowNone = false,
        Callback = function(val)
            autoSellMethod = val
            
            
            if inputElement then
                if val == "Delay" then
                    inputElement:SetTitle("Sell Delay (Seconds)")
                    inputElement:SetPlaceholder("e.g. 50")
                else
                    inputElement:SetTitle("Sell at Item Count")
                    inputElement:SetPlaceholder("e.g. 100")
                end
            end
            
            
            if autoSellState then
                RunAutoSellLoop()
            end
        end
    })

    
    inputElement = Reg("sellval",sellall:Input({
        Title = "Sell Delay (Seconds)", 
        Value = tostring(autoSellValue),
        Placeholder = "50",
        Icon = "hash",
        Callback = function(text)
            local num = tonumber(text)
            if num then
                autoSellValue = num
            end
        end
    }))

    
    local CurrentCountDisplay = sellall:Paragraph({ Title = "Current Fish Count: 0", Icon = "package" })
    task.spawn(function() 
        while true do 
            if CurrentCountDisplay and GetPlayerDataReplion() then 
                local count = GetFishCount() 
                CurrentCountDisplay:SetTitle("Current Fish Count: " .. tostring(count)) 
            end 
            task.wait(1) 
        end 
    end)

    
    local togSell = Reg("tsell",sellall:Toggle({
        Title = "Enable Auto Sell",
        Desc = "Menjalankan auto sell sesuai metode di atas.",
        Value = false,
        Callback = function(state)
            autoSellState = state
            if state then
                if not RF_SellAllItems then
                    WindUI:Notify({ Title = "Error", Content = "Remote Sell tidak ditemukan.", Duration = 3, Icon = "x" })
                    return false
                end
                
                local msg = (autoSellMethod == "Delay") and ("Setiap " .. autoSellValue .. " detik.") or ("Saat jumlah >= " .. autoSellValue)
                WindUI:Notify({ Title = "Auto Sell ON (" .. autoSellMethod .. ")", Content = msg, Duration = 3, Icon = "check" })
                RunAutoSellLoop()
            else
                WindUI:Notify({ Title = "Auto Sell OFF", Duration = 3, Icon = "x" })
                if autoSellThread then task.cancel(autoSellThread) autoSellThread = nil end
            end
        end
    }))
    
    local favsec = automatic:Section({ Title = "Auto Favorite / Unfavorite", TextSize = 20, })
    
    
    local function getAutoFavoriteItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")

        if not itemsContainer then
            return {"(Kontainer 'Items' di ReplicatedStorage Tidak Ditemukan)"}
        end

        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            
            if type(itemName) == "string" and #itemName >= 3 then
                
                local prefix = itemName:sub(1, 3)
                
                if prefix ~= "!!!" then
                    table.insert(itemNames, itemName)
                end
            end
        end

        table.sort(itemNames)
        
        if #itemNames == 0 then
            return {"(Kontainer 'Items' Kosong atau Semua Item '!!!')"}
        end
        
        return itemNames
    end
    
    local allItemNames = getAutoFavoriteItemOptions()
    
    
    

local function GetItemsToFavorite()
    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then return {} end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then return {} end

    local itemsToFavorite = {}
    
    
    local isRarityFilterActive = #selectedRarities > 0
    local isNameFilterActive = #selectedItemNames > 0
    local isMutationFilterActive = #selectedMutations > 0

    if not (isRarityFilterActive or isNameFilterActive or isMutationFilterActive) then
        return {} 
    end

    for _, item in ipairs(inventoryData.Items) do
        
        if item.IsFavorite or item.Favorited then continue end
        
        local itemUUID = item.UUID
        if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then continue end
        
        local name, rarity = GetFishNameAndRarity(item)
        local mutationFilterString = GetItemMutationString(item)
        
        
        local isMatch = false

        
        if isRarityFilterActive and table.find(selectedRarities, rarity) then
            isMatch = true
        end

        
        
        if not isMatch and isNameFilterActive and table.find(selectedItemNames, name) then
            isMatch = true
        end

        
        if not isMatch and isMutationFilterActive and table.find(selectedMutations, mutationFilterString) then
            isMatch = true
        end

        
        if isMatch then
            table.insert(itemsToFavorite, itemUUID)
        end
    end

    return itemsToFavorite
end
    
    
    local function GetItemsToUnfavorite()
        local replion = GetPlayerDataReplion()
        if not replion or not ItemUtility or not TierUtility then return {} end

        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end

        local itemsToUnfavorite = {}
        
        for _, item in ipairs(inventoryData.Items) do
            
            if not (item.IsFavorite or item.Favorited) then
                continue
            end
            local itemUUID = item.UUID
            if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then
                continue
            end
            
            
            local name, rarity = GetFishNameAndRarity(item)
            local mutationFilterString = GetItemMutationString(item)
            
            local passesRarity = #selectedRarities > 0 and table.find(selectedRarities, rarity)
            local passesName = #selectedItemNames > 0 and table.find(selectedItemNames, name)
            local passesMutation = #selectedMutations > 0 and table.find(selectedMutations, mutationFilterString)
            
            
            local isTargetedForUnfavorite = passesRarity or passesName or passesMutation
            
            if isTargetedForUnfavorite then
                table.insert(itemsToUnfavorite, itemUUID)
            end
        end

        return itemsToUnfavorite
    end

    
    local function SetItemFavoriteState(itemUUID, isFavorite)
        if not RE_FavoriteItem then return false end
        pcall(function() RE_FavoriteItem:FireServer(itemUUID) end)
        return true
    end

    
    local function RunAutoFavoriteLoop()
        if autoFavoriteThread then task.cancel(autoFavoriteThread) end
        
        autoFavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoFavoriteState do
                local itemsToFavorite = GetItemsToFavorite()
                
                if #itemsToFavorite > 0 then
                    WindUI:Notify({ Title = "Auto Favorite", Content = string.format("Mem-favorite %d item...", #itemsToFavorite), Duration = 1, Icon = "star" })
                    for _, itemUUID in ipairs(itemsToFavorite) do
                        SetItemFavoriteState(itemUUID, true)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end

    
    local function RunAutoUnfavoriteLoop()
        if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) end
        
        autoUnfavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoUnfavoriteState do
                local itemsToUnfavorite = GetItemsToUnfavorite()
                
                if #itemsToUnfavorite > 0 then
                    WindUI:Notify({ Title = "Auto Unfavorite", Content = string.format("Menghapus favorite dari %d item yang dipilih...", #itemsToUnfavorite), Duration = 1, Icon = "x" })
                    for _, itemUUID in ipairs(itemsToUnfavorite) do
                        SetItemFavoriteState(itemUUID, false)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end


    
    
    local RarityDropdown = Reg("drer",favsec:Dropdown({
        Title = "by Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedRarities = values or {} end
    }))

    local ItemNameDropdown = Reg("dtem",favsec:Dropdown({
        Title = "by Item Name",
        Values = allItemNames, 
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedItemNames = values or {} end 
    }))

    local MutationDropdown = Reg("dmut",favsec:Dropdown({
        Title = "by Mutation",
        Values = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen","Noob"},
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedMutations = values or {} end
    }))

    
    local togglefav = Reg("tvav",favsec:Toggle({
        Title = "Enable Auto Favorite",
        Value = false,
        Callback = function(state)
            autoFavoriteState = state
            if state then
                if autoUnfavoriteState then 
                    autoUnfavoriteState = false
                    local unfavToggle = automatic:GetElementByTitle("Enable Auto Unfavorite")
                    if unfavToggle and unfavToggle.Set then unfavToggle:Set(false) end
                    if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
                end

                if not GetPlayerDataReplion() or not ItemUtility or not TierUtility then WindUI:Notify({ Title = "Error", Content = "Gagal memuat data ItemUtility/TierUtility/Replion.", Duration = 3, Icon = "x" }) return false end
                
                WindUI:Notify({ Title = "Auto Favorite ON!", Duration = 3, Icon = "check", })
                RunAutoFavoriteLoop()
            else
                WindUI:Notify({ Title = "Auto Favorite OFF!", Duration = 3, Icon = "x", })
                if autoFavoriteThread then task.cancel(autoFavoriteThread) autoFavoriteThread = nil end
            end
        end
    }))
    
    
    local toggleunfav = Reg("tunfa",favsec:Toggle({
        Title = "Enable Auto Unfavorite",
        Value = false,
        Callback = function(state)
            autoUnfavoriteState = state
            if state then
                if autoFavoriteState then 
                    autoFavoriteState = false
                    local favToggle = automatic:GetElementByTitle("Enable Auto Favorite")
                    if favToggle and favToggle.Set then favToggle:Set(false) end
                    if autoFavoriteThread then task.cancel(autoFavoriteThread) autoFavoriteThread = nil end
                end
                
                if #selectedRarities == 0 and #selectedItemNames == 0 and #selectedMutations == 0 then
                    WindUI:Notify({ Title = "Peringatan!", Content = "Semua filter kosong. Non-aktifkan toggle ini.", Duration = 5, Icon = "alert-triangle" })
                    return false 
                end

                WindUI:Notify({ Title = "Auto Unfavorite ON!", Content = "Menghapus favorit item yang dipilih.", Duration = 3, Icon = "check", })
                RunAutoUnfavoriteLoop()
            else
                WindUI:Notify({ Title = "Auto Unfavorite OFF!", Duration = 3, Icon = "x", })
                if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
            end
        end
    }))
    
    automatic:Divider()

    local trade = automatic:Section({ Title = "Auto Trade", TextSize = 20})

    
    local autoTradeState = false
    local autoTradeThread = nil
    local tradeHoldFavorite = false
    local selectedTradeTargetId = nil
    local selectedTradeItemName = nil
    local selectedTradeRarity = nil
    local tradeDelay = 1.0
    local tradeAmount = 0
    local tradeStopAtCoins = 0
    local isTradeByCoinActive = false

    
    local PlayerList = {}
    local function GetPlayerOptions()
        local options = {}
        PlayerList = {} 
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(options, player.Name)
                PlayerList[player.Name] = player.UserId
            end
        end
        return options
    end

    local PlayerDropdown
    PlayerDropdown = trade:Dropdown({
        Title = "Pilih Pemain Target",
        Values = GetPlayerOptions(),
        Value = false,
        Multi = false,
        AllowNone = false,
        Callback = function(name) 
            local player = game.Players:FindFirstChild(name)
            
            if player and player.UserId then
                selectedTradeTargetId = player.UserId
                WindUI:Notify({ Title = "Target Dipilih", Content = "Target set: " .. player.Name, Duration = 2, Icon = "user" })
            else
                selectedTradeTargetId = nil
            end
        end
    })

    local listplay = trade:Button({
        Title = "Refresh Player List",
        Icon = "refresh-ccw",
        Callback = function()
            
            local newOptions = GetPlayerOptions()
            
            
            pcall(function() PlayerDropdown:Refresh(newOptions) end) 
            
            
            task.wait(0.05)
            
            
            pcall(function() PlayerDropdown:Set(false) end)
            
            
            selectedTradeTargetId = nil
            
            
            if #newOptions > 0 then
                WindUI:Notify({ Title = "List Diperbarui", Content = string.format("%d pemain ditemukan.", #newOptions), Duration = 2, Icon = "check" })
            else
                WindUI:Notify({ Title = "List Diperbarui", Content = "Tidak ada pemain lain di server.", Duration = 2, Icon = "check" })
            end
        end
    })
    
    automatic:Divider()
    
    
    local function getTradeableItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")

        if not itemsContainer then
            return {"(Kontainer 'Items' di ReplicatedStorage Tidak Ditemukan)"}
        end

        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            
            if type(itemName) == "string" and #itemName >= 3 then
                local prefix = itemName:sub(1, 3)
                
                if prefix ~= "!!!" then
                    table.insert(itemNames, itemName)
                end
            end
        end

        table.sort(itemNames)
        
        if #itemNames == 0 then
            return {"(Kontainer 'Items' Kosong atau Semua Item '!!!')"}
        end
        
        return itemNames
    end

    local ItemNameDropdown
    ItemNameDropdown = trade:Dropdown({
        Title = "Filter Item Name",
        Values = getTradeableItemOptions(),
        Value = false,
        Multi = false,
        AllowNone = true,
        Callback = function(name)
            selectedTradeItemName = name or nil 
        end
    })

    
    local raretrade = trade:Dropdown({
        Title = "Filter Item Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Trophy", "Collectible", "DEV", "Default"},
        Value = false,
        Multi = false,
        AllowNone = true,
        Callback = function(rarity)
            selectedTradeRarity = rarity or nil 
        end
    })

    local ToggleCoinStop = trade:Toggle({
        Title = "Stop at Coin Amount",
        Desc = "Berhenti trade jika koin mencapai target.",
        Value = false,
        Callback = function(state) isTradeByCoinActive = state end
    })

    local inputcoint = trade:Input({
        Title = "Target Coin Amount",
        Placeholder = "1000000",
        Value = "0",
        Icon = "dollar-sign",
        Callback = function(val)
            tradeStopAtCoins = tonumber(val) or 0
        end
    })
    
    
    
    local InputAmount = trade:Input({
        Title = "Trade Amount (0 = Unlimited)",
        Value = tostring(tradeAmount),
        Placeholder = "0 (Unlimited)",
        Icon = "hash",
        Callback = function(input)
            local newAmount = tonumber(input)
            if newAmount == nil or newAmount < 0 then
                tradeAmount = 0
            else
                tradeAmount = math.floor(newAmount)
            end
        end
    })

    
    local DelaySlider = trade:Slider({
        Title = "Trade Delay (Seconds)",
        Step = 0.1,
        Value = { Min = 0.5, Max = 5.0, Default = tradeDelay },
        Callback = function(value)
            local newDelay = tonumber(value)
            if newDelay and newDelay >= 0.5 then
                tradeDelay = newDelay
            else
                tradeDelay = 1.0
            end
        end
    })


    local function GetItemsToTrade()
        local replion = GetPlayerDataReplion()
        if not replion then return {} end

        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end

        local itemsToTrade = {}
        
        for _, item in ipairs(inventoryData.Items) do
            
            local isFavorited = item.IsFavorite or item.Favorited
            if tradeHoldFavorite and isFavorited then
                continue 
            end
            
            if typeof(item.UUID) ~= "string" or item.UUID:len() < 10 then continue end
            
            local name, rarity = GetFishNameAndRarity(item)
            local itemRarity = (rarity and rarity:upper() ~= "COMMON") and rarity or "Default"
            
            
            local passesRarity = not selectedTradeRarity or (selectedTradeRarity and itemRarity:upper() == selectedTradeRarity:upper())
            local passesName = not selectedTradeItemName or (name == selectedTradeItemName)
            
            if passesRarity and passesName then
                
                table.insert(itemsToTrade, { 
                    UUID = item.UUID, 
                    Name = name, 
                    Rarity = rarity, 
                    Identifier = item.Identifier,
                    Id = item.Id,
                    Metadata = item.Metadata or {}
                })
            end
        end
        return itemsToTrade
    end

    
    local function IsItemStillInInventory(targetUUID)
        local replion = GetPlayerDataReplion()
        if not replion then return true end 
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return true end

        for _, item in ipairs(inventoryData.Items) do
            if item.UUID == targetUUID then
                return true 
            end
        end
        return false 
    end

    
    local function RunAutoTradeLoop()
        if autoTradeThread then task.cancel(autoTradeThread) end
        
        autoTradeThread = task.spawn(function()
            local tradeCount = 0
            local accumulatedValue = 0 
            local targetId = selectedTradeTargetId
            
            if not targetId or typeof(targetId) ~= "number" then
                WindUI:Notify({ Title = "Trade Gagal", Content = "Pilih Target valid.", Duration = 5, Icon = "x" })
                local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                if toggle and toggle.Set then toggle:Set(false) end
                return
            end

            local RF_InitiateTrade_Local = GetRemote(RPath, "RF/InitiateTrade", 5)
            if not RF_InitiateTrade_Local then return end

            WindUI:Notify({ Title = "Auto Trade ON", Content = "Tracking Value dimulai (0/"..tradeStopAtCoins..")", Duration = 2, Icon = "zap" })

            while autoTradeState do
                
                if isTradeByCoinActive and tradeStopAtCoins > 0 then
                    if accumulatedValue >= tradeStopAtCoins then
                        WindUI:Notify({ 
                            Title = "Target Value Tercapai!", 
                            Content = string.format("Total Trade: %s coins.", accumulatedValue), 
                            Duration = 5, 
                            Icon = "dollar-sign" 
                        })
                        local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                        if toggle and toggle.Set then toggle:Set(false) end
                        break
                    end
                end

                
                if tradeAmount > 0 and tradeCount >= tradeAmount then
                    WindUI:Notify({ Title = "Limit Item Tercapai", Content = "Batas jumlah item terpenuhi.", Duration = 5, Icon = "stop-circle" })
                    local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                    if toggle and toggle.Set then toggle:Set(false) end
                    break
                end

                
                local itemsToTrade = GetItemsToTrade()
                
                if #itemsToTrade > 0 then
                    local itemToTrade = itemsToTrade[1]
                    local targetUUID = itemToTrade.UUID
                    
                    
                    local itemBasePrice = 0
                    if ItemUtility then
                        local iData = ItemUtility:GetItemData(itemToTrade.Id)
                        if iData then itemBasePrice = iData.SellPrice or 0 end
                    end
                    local multiplier = itemToTrade.Metadata.SellMultiplier or 1
                    local itemValue = math.floor(itemBasePrice * multiplier)

                    
                    local successCall = pcall(function()
                        RF_InitiateTrade_Local:InvokeServer(targetId, targetUUID)
                    end)

                    if successCall then
                        
                        local startTime = os.clock()
                        local isTraded = false
                        repeat
                            task.wait(0.5)
                            if not IsItemStillInInventory(targetUUID) then isTraded = true end
                        until isTraded or (os.clock() - startTime > 5)
                        
                        if isTraded then
                            tradeCount = tradeCount + 1
                            
                            
                            accumulatedValue = accumulatedValue + itemValue
                            
                            WindUI:Notify({
                                Title = "Trade Sukses!",
                                Content = string.format("Item: %s\nValue: %d | Total: %d/%d", itemToTrade.Name, itemValue, accumulatedValue, (isTradeByCoinActive and tradeStopAtCoins or 0)),
                                Duration = 2,
                                Icon = "check"
                            })
                            task.wait(tradeDelay)
                        else
                            WindUI:Notify({ Title = "Trade Gagal/Lag", Content = "Item tidak terkirim.", Duration = 2, Icon = "alert-triangle" })
                            task.wait(1.5)
                        end
                    else
                        task.wait(1)
                    end
                else
                    task.wait(2)
                end
            end
            WindUI:Notify({ Title = "Auto Trade Berhenti", Duration = 3, Icon = "x" })
        end)
    end
    
    local togglehold = trade:Toggle({
        Title = "Hold Favorite Items",
        Desc = "Jika ON, item yang di-Favorite tidak akan ikut di-trade.",
        Value = false,
        Callback = function(state)
            tradeHoldFavorite = state
            if state then
                WindUI:Notify({ Title = "Safe Mode", Content = "Item Favorite aman dari Auto Trade.", Duration = 2, Icon = "lock" })
            else
                WindUI:Notify({ Title = "Warning", Content = "Item Favorite bisa ikut ter-trade!", Duration = 2, Icon = "alert-triangle" })
            end
        end
    })

    
    local autotrd = trade:Toggle({
        Title = "Enable Auto Trade",
        Icon = "arrow-right-left",
        Value = false,
        Callback = function(state)
            autoTradeState = state
            
            if state then
                
                if not selectedTradeTargetId or typeof(selectedTradeTargetId) ~= "number" then
                    WindUI:Notify({ Title = "Error", Content = "Pilih pemain target yang valid terlebih dahulu!", Duration = 3, Icon = "alert-triangle" })
                    return false
                end

                
                local targetPlayer = game.Players:GetPlayerByUserId(selectedTradeTargetId)
                
                if targetPlayer then
                    local targetChar = targetPlayer.Character
                    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    
                    local myChar = LocalPlayer.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

                    if targetHRP and myHRP then
                        WindUI:Notify({ Title = "Teleporting...", Content = "Menuju ke posisi " .. targetPlayer.Name, Duration = 2, Icon = "map-pin" })
                        
                        
                        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
                        
                        
                        task.wait(0.5)
                    else
                        WindUI:Notify({ Title = "Teleport Gagal", Content = "Karakter target tidak ditemukan (Mungkin mati/belum load).", Duration = 3, Icon = "alert-triangle" })
                    end
                else
                    WindUI:Notify({ Title = "Teleport Gagal", Content = "Pemain target sudah keluar server.", Duration = 3, Icon = "x" })
                    return false
                end

                
                RunAutoTradeLoop()
            else
                if autoTradeThread then task.cancel(autoTradeThread) autoTradeThread = nil end
            end
        end
    })


    
    local accept = trade:Toggle({
        Title = "Enable Auto Accept Trade",
        Icon = "arrow-right-left",
        Value = false,
        Callback = function(state)
            _G.XALSC_AutoAcceptTradeEnabled = state
            
            if state then
                WindUI:Notify({
                    Title = "Auto Accept Trade ON! ✅",
                    Content = "Menerima semua permintaan trade secara otomatis.",
                    Duration = 3,
                    Icon = "check"
                })
            else
                WindUI:Notify({
                    Title = "Auto Accept Trade OFF! ❌",
                    Content = "Menerima trade secara manual.",
                    Duration = 3,
                    Icon = "x"
                })
            end
        end
    })


    local enchant = automatic:Section({ Title = "Auto Enchant Rod", TextSize = 20,})
    
    
    local ENCHANT_ROD_LIST = {
        {Name = "Luck Rod", ID = 79}, {Name = "Carbon Rod", ID = 76}, {Name = "Grass Rod", ID = 85}, 
        {Name = "Demascus Rod", ID = 77}, {Name = "Ice Rod", ID = 78}, {Name = "Lucky Rod", ID = 4}, 
        {Name = "Midnight Rod", ID = 80}, {Name = "Steampunk Rod", ID = 6}, {Name = "Chrome Rod", ID = 7}, 
        {Name = "Flourescent Rod", ID = 255}, {Name = "Astral Rod", ID = 5}, {Name = "Ares Rod", ID = 126}, 
        {Name = "Angler Rod", ID = 168}, {Name = "Ghostfin Rod", ID = 169}, {Name = "Element Rod", ID = 257},
        {Name = "Hazmat Rod", ID = 256}, {Name = "Bamboo Rod", ID = 258}
    }

    local function GetHardcodedRodNames()
        local names = {}
        for _, v in ipairs(ENCHANT_ROD_LIST) do
            table.insert(names, v.Name)
        end
        return names
    end

    
    local function GetUUIDByRodID(targetID)
        local replion = GetPlayerDataReplion()
        if not replion then return nil end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData["Fishing Rods"] then return nil end

        for _, rod in ipairs(inventoryData["Fishing Rods"]) do
            if tonumber(rod.Id) == targetID then
                return rod.UUID 
            end
        end
        return nil
    end

    local RodDropdown = enchant:Dropdown({
        Title = "Select Rod",
        Desc = "Pilih jenis Rod yang ingin di-enchant.",
        Values = GetHardcodedRodNames(),
        Multi = false,
        AllowNone = true,
        Callback = function(name)
            selectedRodUUID = nil
            
            for _, v in ipairs(ENCHANT_ROD_LIST) do
                if v.Name == name then
                    
                    local foundUUID = GetUUIDByRodID(v.ID)
                    if foundUUID then
                        selectedRodUUID = foundUUID
                        WindUI:Notify({ Title = "Rod Ditemukan", Content = "UUID tersimpan untuk " .. name, Duration = 2, Icon = "check" })
                    else
                        WindUI:Notify({ Title = "Rod Tidak Ada", Content = "Kamu tidak memiliki " .. name .. " di inventory.", Duration = 3, Icon = "x" })
                    end
                    break
                end
            end
        end
    })

    
    local rodlist = enchant:Button({
        Title = "Re-Check Selected Rod",
        Icon = "refresh-ccw",
        Callback = function()
            local currentName = RodDropdown.Value
            if currentName then
                
                for _, v in ipairs(ENCHANT_ROD_LIST) do
                    if v.Name == currentName then
                        local foundUUID = GetUUIDByRodID(v.ID)
                        if foundUUID then
                            selectedRodUUID = foundUUID
                            WindUI:Notify({ Title = "Re-Check Sukses", Content = "UUID Updated.", Duration = 2, Icon = "check" })
                        else
                            selectedRodUUID = nil
                            WindUI:Notify({ Title = "Hilang", Content = "Rod tidak ditemukan di tas.", Duration = 2, Icon = "x" })
                        end
                        break
                    end
                end
            else
                WindUI:Notify({ Title = "Info", Content = "Pilih Rod di dropdown dulu.", Duration = 2 })
            end
        end 
    })

    
    local dropenchant = enchant:Dropdown({
        Title = "Enchant To Apply (stop when reached)",
        Desc = "Pilih enchant yang diinginkan. Auto-roll akan berhenti jika salah satu enchant ini didapat.",
        Values = ENCHANT_NAMES,
        Multi = true,
        AllowNone = false,
        Callback = function(names)
            selectedEnchantNames = names or {}
        end
    })

    
    local autoenc = enchant:Toggle({
        Title = "Enable Auto Enchant",
        Value = false,
        Callback = function(state)
            autoEnchantState = state
            if state then
                if not selectedRodUUID then
                    WindUI:Notify({ Title = "Error", Content = "Pilih Rod target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                if #selectedEnchantNames == 0 then
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal satu Enchant target.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                
                
                RunAutoEnchantLoop(selectedRodUUID)
            else
                if autoEnchantThread then task.cancel(autoEnchantThread) autoEnchantThread = nil end
                WindUI:Notify({ Title = "Auto Enchant OFF!", Duration = 3, Icon = "x",})
            end
        end
    })


    
    
    automatic:Divider()
    local enchant2 = automatic:Section({ Title = "Second Enchant Rod", TextSize = 20})

    
    local makeStoneState = false
    local makeStoneThread = nil
    local secondEnchantState = false
    local secondEnchantThread = nil
    
    local selectedSecretFishUUIDs = {} 
    local targetStoneAmount = 1 
    
    local TRANSCENDED_STONE_ID = 246
    local SECOND_ALTAR_POS = FishingAreas["Second Enchant Altar"].Pos
    local SECOND_ALTAR_LOOK = FishingAreas["Second Enchant Altar"].Look

    
    local RF_CreateTranscendedStone = GetRemote(RPath, "RF/CreateTranscendedStone")
    local RE_ActivateSecondEnchantingAltar = GetRemote(RPath, "RE/ActivateSecondEnchantingAltar")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem")
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")

    
    local function GetSecretFishOptions()
        local options = {}
        local uuidMap = {} 
        
        local replion = GetPlayerDataReplion()
        if not replion then return {}, {} end

        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {}, {} end

        for _, item in ipairs(inventoryData.Items) do
            
            
            local hasWeight = item.Metadata and item.Metadata.Weight
            
            
            local isFishType = item.Type == "Fish" or (item.Identifier and tostring(item.Identifier):lower():find("fish"))
            
            if not hasWeight and not isFishType then continue end

            
            local _, rarity = GetFishNameAndRarity(item)
            
            if not rarity or rarity:upper() ~= "SECRET" then continue end

            
            local name = item.Identifier or "Unknown"
            if ItemUtility then
                local itemData = ItemUtility:GetItemData(item.Id)
                if itemData and itemData.Data and itemData.Data.Name then
                    name = itemData.Data.Name
                end
            end

            if item.Metadata and item.Metadata.Weight then
                name = string.format("%s (%.1fkg)", name, item.Metadata.Weight)
            end
            
            
            if item.IsFavorite or item.Favorited then
                name = name .. " [⭐]"
            end

            table.insert(options, name)
            uuidMap[name] = item.UUID
        end
        
        table.sort(options) 
        return options, uuidMap
    end

    local secretFishOptions, secretFishUUIDMap = GetSecretFishOptions()

    
    local function CheckIfSecondEnchantReached(rodUUID)
        local replion = GetPlayerDataReplion()
        local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
        
        local targetRod = nil
        for _, rod in ipairs(Rods) do
            if rod.UUID == rodUUID then
                targetRod = rod
                break
            end
        end

        if not targetRod then return true end 
        
        local metadata = targetRod.Metadata or {}
        
        
        local currentEnchant2 = metadata.EnchantId2
        
        if not currentEnchant2 then return false end 

        
        for _, targetName in ipairs(selectedEnchantNames) do
            local targetID = ENCHANT_MAPPING[targetName]
            if targetID and currentEnchant2 == targetID then
                return true 
            end
        end

        return false
    end

    
    local function GetTranscendedStoneUUID()
        local replion = GetPlayerDataReplion()
        if not replion then return nil end
        local inventoryData = replion:GetExpect("Inventory")
        
        if inventoryData and inventoryData.Items then
            for _, item in ipairs(inventoryData.Items) do
                if tonumber(item.Id) == TRANSCENDED_STONE_ID and item.UUID then
                    return item.UUID
                end
            end
        end
        return nil
    end

    
    local function RunMakeStoneLoop()
        if makeStoneThread then task.cancel(makeStoneThread) end

        makeStoneThread = task.spawn(function()
            local createdCount = 0
            
            
            TeleportToLookAt(SECOND_ALTAR_POS, SECOND_ALTAR_LOOK)
            task.wait(1)

            while makeStoneState and createdCount < targetStoneAmount do
                
                local _, currentMap = GetSecretFishOptions()
                local fishToSacrifice = nil
                
                
                for name, uuid in pairs(currentMap) do
                    
                    if table.find(selectedSecretFishUUIDs, name) then
                        fishToSacrifice = uuid
                        break
                    end
                end

                if not fishToSacrifice then
                    WindUI:Notify({ Title = "Selesai / Habis", Content = "Tidak ada ikan target tersisa.", Duration = 5, Icon = "check" })
                    break
                end

                
                WindUI:Notify({ Title = "Sacrificing...", Content = "Memproses ikan...", Duration = 1, Icon = "refresh-cw" })

                
                UnequipAllEquippedItems()
                task.wait(0.3)

                
                pcall(function() 
                    RE_EquipItem:FireServer(fishToSacrifice, "Fish") 
                end)
                task.wait(0.5)

                
                pcall(function() 
                    RE_EquipToolFromHotbar:FireServer(2) 
                end)
                task.wait(0.8) 

                
                local success = pcall(function() 
                    RF_CreateTranscendedStone:InvokeServer() 
                end)

                if success then
                    createdCount = createdCount + 1
                    WindUI:Notify({ Title = "Stone Created!", Content = string.format("Total: %d / %d", createdCount, targetStoneAmount), Duration = 2, Icon = "gem" })
                else
                    WindUI:Notify({ Title = "Gagal", Content = "Gagal membuat batu (Mungkin bukan secret?).", Duration = 2, Icon = "x" })
                end

                task.wait(1.5) 
            end

            makeStoneState = false
            local toggle = automatic:GetElementByTitle("Start Make Stones")
            if toggle and toggle.Set then toggle:Set(false) end
            
            
            pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
        end)
    end

    
    local function RunSecondEnchantLoop(rodUUID)
        if secondEnchantThread then task.cancel(secondEnchantThread) end

        secondEnchantThread = task.spawn(function()
            
            UnequipAllEquippedItems()
            task.wait(0.5)

            
            TeleportToLookAt(SECOND_ALTAR_POS, SECOND_ALTAR_LOOK)
            task.wait(1.5)

            WindUI:Notify({ Title = "2nd Enchant Started", Content = "Rolling Slot 2...", Duration = 2, Icon = "sparkles" })

            while secondEnchantState do
                
                if CheckIfSecondEnchantReached(rodUUID) then
                    WindUI:Notify({ Title = "GG!", Content = "Enchant ke-2 didapatkan!", Duration = 5, Icon = "check" })
                    break
                end

                
                local stoneUUID = GetTranscendedStoneUUID()
                if not stoneUUID then
                    WindUI:Notify({ Title = "Stone Habis!", Content = "Butuh Transcended Stone", Duration = 5, Icon = "stop-circle" })
                    break
                end

                
                
                
                pcall(function() RE_EquipItem:FireServer(rodUUID, "Fishing Rods") end)
                task.wait(0.2)

                
                pcall(function() RE_EquipItem:FireServer(stoneUUID, "Enchant Stones") end)
                task.wait(0.2)

                
                pcall(function() RE_EquipToolFromHotbar:FireServer(2) end)
                task.wait(0.3)

                
                pcall(function() RE_ActivateSecondEnchantingAltar:FireServer() end)

                
                task.wait(tradeDelay)

                
                pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
                task.wait(0.5)
            end

            secondEnchantState = false
            local toggle = automatic:GetElementByTitle("Start Second Enchant")
            if toggle and toggle.Set then toggle:Set(false) end
        end)
    end


    

    
    local SecretFishDropdown = enchant2:Dropdown({
        Title = "Select Secret Fish (Sacrifice)",
        Desc = "Pilih ikan SECRET untuk dijadikan Transcended Stone.",
        Values = secretFishOptions,
        Multi = true,
        AllowNone = true,
        Callback = function(values)
            
            
            selectedSecretFishUUIDs = values or {} 
        end
    })

    local butfish = enchant2:Button({
        Title = "Refresh Secret Fish List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions, newMap = GetSecretFishOptions()
            secretFishUUIDMap = newMap 
            pcall(function() SecretFishDropdown:Refresh(newOptions) end)
            pcall(function() SecretFishDropdown:Set(false) end)
            selectedSecretFishUUIDs = {}
            WindUI:Notify({ Title = "Refreshed", Content = #newOptions .. " ikan secret ditemukan.", Duration = 2, Icon = "check" })
        end
    })

    local amountmake = enchant2:Input({
        Title = "Amount to Make",
        Desc = "Berapa banyak batu yang ingin dibuat?",
        Value = "1",
        Placeholder = "1",
        Icon = "hash",
        Callback = function(input)
            targetStoneAmount = tonumber(input) or 1
        end
    })

    local togglestone = enchant2:Toggle({
        Title = "Start Make Stones",
        Desc = "Otomatis ubah ikan terpilih menjadi Transcended Stone.",
        Value = false,
        Callback = function(state)
            makeStoneState = state
            if state then
                if #selectedSecretFishUUIDs == 0 then
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal 1 jenis ikan secret.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                RunMakeStoneLoop()
            else
                if makeStoneThread then task.cancel(makeStoneThread) end
                WindUI:Notify({ Title = "Stopped", Duration = 2, Icon = "x" })
            end
        end
    })

    automatic:Divider()
    
    
    
    local SecondRodDropdown = enchant2:Dropdown({
        Title = "Select Rod for 2nd Enchant",
        Desc = "Pilih Rod target. Pastikan Rod ada di inventory.",
        Values = GetHardcodedRodNames(), 
        Multi = false,
        AllowNone = true,
        Callback = function(name)
            selectedRodUUID = nil
            
            for _, v in ipairs(ENCHANT_ROD_LIST) do
                if v.Name == name then
                    local foundUUID = GetUUIDByRodID(v.ID)
                    if foundUUID then
                        selectedRodUUID = foundUUID
                        WindUI:Notify({ Title = "Rod Dipilih", Content = "Target: " .. name, Duration = 2, Icon = "check" })
                    else
                        WindUI:Notify({ Title = "Gagal", Content = name .. " tidak ditemukan di tas.", Duration = 3, Icon = "x" })
                    end
                    break
                end
            end
        end
    })

    local rodlist2 = enchant2:Button({
        Title = "Re-Check Selected Rod",
        Icon = "refresh-ccw",
        Callback = function()
             local currentName = SecondRodDropdown.Value
             if currentName then
                 
                 for _, v in ipairs(ENCHANT_ROD_LIST) do
                    if v.Name == currentName then
                        local foundUUID = GetUUIDByRodID(v.ID)
                        if foundUUID then
                            selectedRodUUID = foundUUID
                            WindUI:Notify({ Title = "Sync", Content = "UUID Verified.", Duration = 1, Icon = "check" })
                        else
                            WindUI:Notify({ Title = "Missing", Content = "Rod hilang/tidak ada.", Duration = 2, Icon = "x" })
                        end
                        break
                    end
                 end
             else
                WindUI:Notify({ Title = "Info", Content = "Pilih rod dulu.", Duration = 2 })
             end
        end
    })

    local targetenchant2 = enchant2:Dropdown({
        Title = "Target 2nd Enchant",
        Desc = "Pilih enchant yang diinginkan di slot ke-2.",
        Values = ENCHANT_NAMES,
        Multi = true,
        AllowNone = false,
        Callback = function(names)
            selectedEnchantNames = names or {}
        end
    })

    local start2ndenchant = enchant2:Toggle({
        Title = "Start Second Enchant",
        Desc = "Auto roll slot ke-2 menggunakan Transcended Stone.",
        Value = false,
        Callback = function(state)
            secondEnchantState = state
            if state then
                if not selectedRodUUID then
                    WindUI:Notify({ Title = "Error", Content = "Pilih Rod terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                if #selectedEnchantNames == 0 then
                    WindUI:Notify({ Title = "Error", Content = "Pilih target enchant.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                RunSecondEnchantLoop(selectedRodUUID)
            else
                if secondEnchantThread then task.cancel(secondEnchantThread) end
                WindUI:Notify({ Title = "Stopped", Duration = 2, Icon = "x" })
            end
        end
    })
    
end

do
    local teleport = Window:Tab({
        Title = "Teleport",
        Icon = "map-pin",
        Locked = false,
        
    })

    local selectedTargetPlayer = nil 
    local selectedTargetArea = nil 

    
    local function GetPlayerListOptions()
        local options = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(options, player.Name)
            end
        end
        return options
    end

    
    local function GetTargetHRP(playerName)
        local targetPlayer = game.Players:FindFirstChild(playerName)
        local character = targetPlayer and targetPlayer.Character
        if character then
            return character:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end


    
    
    
    local teleplay = teleport:Section({
        Title = "Teleport to Player",
        TextSize = 20,
    })

    local PlayerDropdown = teleplay:Dropdown({
        Title = "Select Target Player",
        Values = GetPlayerListOptions(),
        AllowNone = true,
        Callback = function(name)
            selectedTargetPlayer = name
        end
    })

    local listplaytel = teleplay:Button({
        Title = "Refresh Player List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions = GetPlayerListOptions()
            pcall(function() PlayerDropdown:Refresh(newOptions) end)
            task.wait(0.1)
            pcall(function() PlayerDropdown:Set(false) end)
            selectedTargetPlayer = nil
            WindUI:Notify({ Title = "List Diperbarui", Content = string.format("%d pemain ditemukan.", #newOptions), Duration = 2, Icon = "check" })
        end
    })

    local teletoplay = teleplay:Button({
        Title = "Teleport to Player (One-Time)",
        Content = "Teleport satu kali ke lokasi pemain yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            local hrp = GetHRP()
            local targetHRP = GetTargetHRP(selectedTargetPlayer)
            
            if not selectedTargetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih pemain target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end

            if hrp and targetHRP then
                
                local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                local lookVector = (targetHRP.Position - hrp.Position).Unit 
                
                hrp.CFrame = CFrame.new(targetPos, targetPos + lookVector)
                
                WindUI:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetPlayer, Duration = 3, Icon = "user-check" })
            else
                 WindUI:Notify({ Title = "Error", Content = "Gagal menemukan target atau karakter Anda.", Duration = 3, Icon = "x" })
            end
        end
    })
    
    teleport:Divider()

    
    
    
    
    local telearea = teleport:Section({
        Title = "Teleport to Fishing Area",
        TextSize = 20,
    })

    local AreaDropdown = telearea:Dropdown({
        Title = "Select Target Area",
        Values = AreaNames, 
        AllowNone = true,
        Callback = function(name)
            selectedTargetArea = name
        end
    })

    local butelearea = telearea:Button({
        Title = "Teleport to Area (One-Time)",
        Content = "Teleport satu kali ke area yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedTargetArea or not FishingAreas[selectedTargetArea] then
                WindUI:Notify({ Title = "Error", Content = "Pilih area target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            local areaData = FishingAreas[selectedTargetArea]
            
            TeleportToLookAt(areaData.Pos, areaData.Look)
            WindUI:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetArea, Duration = 3, Icon = "map" })
        end
    })

    teleport:Divider()

    local televent = teleport:Section({
        Title = "Auto Teleport Event",
        TextSize = 20,
    })

    local dropvent = televent:Dropdown({
        Title = "Select Target Event",
        Content = "Pilih event yang ingin di-monitor secara otomatis.",
        Values = eventsList,
        AllowNone = true,
        Value = false,
        Callback = function(option)
            autoEventTargetName = option 
            if autoEventTeleportState then
                 
                 autoEventTeleportState = false
                 if autoEventTeleportThread then task.cancel(autoEventTeleportThread) autoEventTeleportThread = nil end
                 Window:GetElementByTitle("Enable Auto Event Teleport"):Set(false)
            end
        end
    })

    local tovent = televent:Button({
        Title = "Teleport to Chosen Event (Once)",
        Icon = "corner-down-right",
        Callback = function()
            if not autoEventTargetName then
                WindUI:Notify({ Title = "Error", Content = "Pilih event dulu di dropdown!", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            WindUI:Notify({ Title = "Searching...", Content = "Mencari keberadaan event...", Duration = 2, Icon = "search" })
            
            local found = FindAndTeleportToTargetEvent()
            if not found then
                WindUI:Notify({ Title = "Gagal", Content = "Event tidak ditemukan / belum spawn.", Duration = 3, Icon = "x" })
            end
        end
    })


    local togventel = televent:Toggle({
        Title = "Enable Auto Event Teleport",
        Content = "Secara otomatis mencari dan teleport ke event yang dipilih.",
        Value = false,
        Callback = function(state)
            if not autoEventTargetName then
                 WindUI:Notify({ Title = "Error", Content = "Pilih Event Target terlebih dahulu di dropdown.", Duration = 3, Icon = "alert-triangle" })
                 return false
            end
            
            autoEventTeleportState = state
            if state then
                RunAutoEventTeleportLoop()
            else
                if autoEventTeleportThread then task.cancel(autoEventTeleportThread) autoEventTeleportThread = nil end
                WindUI:Notify({ Title = "Auto Event TP OFF", Duration = 3, Icon = "x" })
            end
        end
    })
    
end

do
    local shop = Window:Tab({
        Title = "Shop",
        Icon = "shopping-bag",
        Locked = false,
    })

    local MerchantButtons = {}
    
    
    local MerchantReplion = nil
    local UpdateCleanupFunction = nil
    local MainDisplayElement = nil
    local UpdateThread = nil
    
    
    local selectedStaticItemName = nil
    local autoBuySelectedState = false
    local autoBuyStockState = false
    local autoBuyThread = nil

    
    local function FormatNumber(n)
        if n >= 1000000000 then return string.format("%.1fB", n / 1000000000)
        elseif n >= 1000000 then return string.format("%.1fM", n / 1000000)
        elseif n >= 1000 then return string.format("%.1fK", n / 1000)
        else return tostring(n) end
    end

    

    
    local function GetReplions()
        if MerchantReplion then return true end
        local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
        if not ReplionModule then return false end
        local ReplionClient = require(ReplionModule).Client
        MerchantReplion = ReplionClient:WaitReplion("Merchant", 5)
        return MerchantReplion
    end

    local function getNextRefreshTimeString()
        local serverTime = workspace:GetServerTimeNow()
        local secondsInDay = 86400
        local nextRefreshTime = (math.floor(serverTime / secondsInDay) + 1) * secondsInDay
        local timeRemaining = math.max(nextRefreshTime - serverTime, 0)
        local h = math.floor(timeRemaining / 3600)
        local m = math.floor((timeRemaining % 3600) / 60)
        local s = math.floor(timeRemaining % 60)
        local timeString = string.format("Next Refresh: %dH, %dM, %dS", h, m, s)
        return timeString
    end
    
    
    local function GetMerchantStockDetails(merchantData)
        local itemDetails = {}
        local MarketItemData = RepStorage:WaitForChild("Shared"):WaitForChild("MarketItemData", 0.1) and require(RepStorage.Shared.MarketItemData)
        
        if merchantData and merchantData.Items and type(merchantData.Items) == "table" and MarketItemData and ItemUtility then
            for _, itemID in ipairs(merchantData.Items) do
                local marketData = nil
                for _, data in ipairs(MarketItemData) do
                    if data.Id == itemID then marketData = data; break end
                end

                if marketData and not marketData.SkinCrate and marketData.Price and marketData.Currency then
                    local itemDetail = nil
                    pcall(function() itemDetail = ItemUtility:GetItemDataFromItemType(marketData.Type, marketData.Identifier) end)
                    
                    local name = (itemDetail and itemDetail.Data and itemDetail.Data.Name) or marketData.Identifier or "Unknown Item"
                    
                    table.insert(itemDetails, {
                        Name = name,
                        ID = itemID,
                        Price = marketData.Price,
                        Currency = marketData.Currency,
                    })
                end
            end
        end
        return itemDetails
    end

    
    local function BuyMerchantItem(itemID, itemName)
        if not RF_PurchaseMarketItem then
            WindUI:Notify({ Title = "Purchase Failed", Content = "Remote Purchase Market Item tidak ditemukan.", Duration = 4, Icon = "x", })
            return false
        end
        
        local success, result = pcall(function()
            return RF_PurchaseMarketItem:InvokeServer(itemID)
        end)

        if success then
            WindUI:Notify({ Title = "Purchase Attempted!", Content = "Mencoba membeli: " .. itemName, Duration = 1.5, Icon = "check", })
            return true
        else
            WindUI:Notify({ Title = "Purchase Failed", Content = "Gagal: " .. (result or "Unknown Error"), Duration = 2, Icon = "x", })
            return false
        end
    end
    
    
    local function ClearOldMerchantButtons()
        for _, btn in ipairs(MerchantButtons) do
            if btn and type(btn) == "table" and btn.Destroy then
                pcall(function()
                    btn:Destroy()
                end)
            end
        end
        MerchantButtons = {}
    end

    
    local function CreateStockListString(itemDetails)
        local list = {"--- CURRENT STOCK ---"}
        if #itemDetails == 0 then
            table.insert(list, "Stok Item unik kosong saat ini.")
            return table.concat(list, "\n")
        end

        for _, item in ipairs(itemDetails) do
            local formattedPrice = FormatNumber(item.Price)
            local currency = item.Currency or "Coins"
            table.insert(list, string.format(" • %s: %s %s", item.Name, formattedPrice, currency))
        end
        
        return table.concat(list, "\n")
    end

    
    local function RedrawMerchantButtons(itemDetails)
        ClearOldMerchantButtons()
        
        if #itemDetails > 0 then
            for _, item in ipairs(itemDetails) do
                local formattedPrice = FormatNumber(item.Price)
                local currency = item.Currency or "Coins"
                
                local newButton = shop:Button({
                    Title = string.format("BUY: %s", item.Name),
                    Desc = string.format("Price: %s %s", formattedPrice, currency),
                    Icon = "shopping-cart",
                    Callback = function()
                        BuyMerchantItem(item.ID, item.Name)
                    end
                })
                table.insert(MerchantButtons, newButton)
            end
        else
            local noStockIndicator = shop:Paragraph({
                Title = "No Buyable Items",
                Desc = "Tidak ada tombol yang tersedia.",
                Icon = "info",
            })
            table.insert(MerchantButtons, noStockIndicator)
        end
    end

    
    local function RunAutoBuyStockLoop()
        if autoBuyThread then task.cancel(autoBuyThread) end
        
        autoBuyThread = task.spawn(function()
            while autoBuyStockState do
                if MerchantReplion then
                    local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
                    for _, item in ipairs(currentDetails) do
                        BuyMerchantItem(item.ID, item.Name)
                        task.wait(0.5)
                    end
                end
                task.wait(3)
            end
        end)
    end

    
    local function RunAutoBuySelectedLoop(itemID, itemName)
        if autoBuyThread then task.cancel(autoBuyThread) end

        autoBuyThread = task.spawn(function()
            while autoBuySelectedState do
                BuyMerchantItem(itemID, itemName)
                task.wait(1)
            end
        end)
    end


    local function RunMerchantSyncLoop(mainDisplay)
        if UpdateThread then task.cancel(UpdateThread) end

        local initialDetails = GetMerchantStockDetails(MerchantReplion.Data)
        RedrawMerchantButtons(initialDetails)
        
        local stockUpdateConnection = MerchantReplion:OnChange("Items", function(newItems)
            local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
            RedrawMerchantButtons(currentDetails)
            
            local timeString = getNextRefreshTimeString()
            local stockListString = CreateStockListString(currentDetails)
            mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
        end)
        
        local isRunning = true
        
        UpdateThread = task.spawn(function()
            while isRunning do
                local timeString = getNextRefreshTimeString()
                local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
                local stockListString = CreateStockListString(currentDetails)
                
                mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
                
                task.wait(1)
            end
            if stockUpdateConnection then stockUpdateConnection:Disconnect() end
            ClearOldMerchantButtons()
        end)
        
        return function()
            isRunning = false
            if UpdateThread then task.cancel(UpdateThread) UpdateThread = nil end
            if stockUpdateConnection then stockUpdateConnection:Disconnect() end
            ClearOldMerchantButtons()
        end
    end
    
    local function ToggleMerchantSync(state, mainDisplay)
        if state then
            task.spawn(function()
                if not GetReplions() then
                    WindUI:Notify({ Title = "Sync Gagal", Content = "Gagal memuat Replion Merchant.", Duration = 4, Icon = "x", })
                    mainDisplay:SetTitle("Sync Gagal: Merchant Replion missing/timeout.")
                    mainDisplay:SetDesc("Toggle OFF dan coba lagi.")
                    return
                end

                WindUI:Notify({ Title = "Sync ON!", Content = "Memulai live update stok dan tombol beli.", Duration = 2, Icon = "check", })
                mainDisplay:SetDesc("Waktu refresh dihitung akurat dari server.")
                UpdateCleanupFunction = RunMerchantSyncLoop(mainDisplay)
            end)
            
            return true
        else
            WindUI:Notify({ Title = "Sync OFF!", Duration = 3, Icon = "x", })
            
            if UpdateCleanupFunction then
                UpdateCleanupFunction()
                UpdateCleanupFunction = nil
            end
            
            mainDisplay:SetTitle("Merchant Live Data OFF.")
            mainDisplay:SetDesc("Toggle ON untuk melihat status live.")
            ClearOldMerchantButtons()
            
            return false
        end
    end

    

    local WeatherList = { "Storm", "Cloudy", "Snow", "Wind", "Radiant", "Shark Hunt" }
    local AutoWeatherState = false
    local AutoWeatherThread = nil
    
    local SelectedWeatherTypes = { WeatherList[1] }
    
    local function RunAutoBuyWeatherLoop(weatherTypes)
    
    
    local PurchaseRemote = RF_PurchaseWeatherEvent
    if not PurchaseRemote then
        PurchaseRemote = GetRemote(RPath, "RF/PurchaseWeatherEvent", 1)
        
        if not PurchaseRemote then
            WindUI:Notify({ Title = "Weather Buy Error", Content = "Remote RF/PurchaseWeatherEvent tidak ditemukan setelah coba agresif!", Duration = 5, Icon = "x" })
            AutoWeatherState = false
            return
        end
    end

    if AutoWeatherThread then task.cancel(AutoWeatherThread) end

    print("[DEBUG WEATHER] Starting MULTI-BUY loop for: " .. table.concat(weatherTypes, ", "))
    
    AutoWeatherThread = task.spawn(function()
        local successfulBuyTime = 10 
        local attempts = 0
        
        while AutoWeatherState and #weatherTypes > 0 do
            local totalSuccessfulBuysInCycle = 0
            local weatherBought = {}

            
            for i, weatherToBuy in ipairs(weatherTypes) do
                
                attempts = attempts + 1
                
                
                task.wait(0.05)
                
                local success_buy, err_msg = pcall(function()
                    return PurchaseRemote:InvokeServer(weatherToBuy)
                end)

                if success_buy then
                    
                    totalSuccessfulBuysInCycle = totalSuccessfulBuysInCycle + 1
                    table.insert(weatherBought, weatherToBuy)
                    
                end
            end
            
            
            if totalSuccessfulBuysInCycle > 0 then
                
                local boughtList = table.concat(weatherBought, ", ")
                
                attempts = 0 
                task.wait(successfulBuyTime) 
            else
                task.wait(5)
            end
        end
        AutoWeatherThread = nil
        local toggle = shop:GetElementByTitle("Enable Auto Buy Weather")
        if toggle and toggle.Set then toggle:Set(false) end
    end)
end
    
    
    local weathershop = shop:Section({ Title = "Auto Buy Weather", TextSize = 20, })
    
    local WeatherDropdown = Reg("weahterd", weathershop:Dropdown({
        Title = "Select Weather Type",
        Values = WeatherList,
        Value = SelectedWeatherTypes, 
        Multi = true, 
        AllowNone = false,
        Callback = function(selected)
            SelectedWeatherTypes = selected or {} 
            if #SelectedWeatherTypes == 0 then
                
                SelectedWeatherTypes = { WeatherList[1] }
            end
            if AutoWeatherState then
                
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
            end
        end
    }))
    
    local ToggleAutoBuy = Reg("shopweath",weathershop:Toggle({
        Title = "Enable Auto Buy Weather",
        Value = false,
        Callback = function(state)
            AutoWeatherState = state
            if state then
                if #SelectedWeatherTypes == 0 then
                    
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal satu jenis Weather terlebih dahulu.", Duration = 3, Icon = "x" })
                    AutoWeatherState = false
                    return false
                end
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
                
            else
                if AutoWeatherThread then task.cancel(AutoWeatherThread) end
                
                WindUI:Notify({ Title = "Auto Weather", Content = "Auto Buy dimatikan.", Duration = 3, Icon = "x" })
            end
        end
    }))

    local merchant = shop:Section({
        Title = "Traveling Merchant",
        TextSize = 20,
    })
    shop:Divider()

    
    MainDisplayElement = merchant:Paragraph({
        Title = "Merchant Live Data OFF.",
        Desc = "Toggle ON untuk melihat status live.",
        Icon = "clock"
    })

    

    local tlive = merchant:Toggle({
        Title = "Live Stock & Buy Actions",
        Icon = "rotate-ccw",
        Value = true,
        Callback = function(state)
            return ToggleMerchantSync(state, MainDisplayElement)
        end,
    })


    local tcurst = merchant:Toggle({
        Title = "Auto Buy Current Stock",
        Value = false,
        Callback = function(state)
            autoBuyStockState = state
            if state then
                RunAutoBuyStockLoop()
                if autoBuySelectedState then
                    autoBuySelectedState = false
                    shop:GetElementByTitle("Auto Buy Item Terpilih"):Set(false)
                end
            else
                if autoBuyThread then task.cancel(autoBuyThread) autoBuyThread = nil end
            end
        end
    })
    
end




do
    local premium = Window:Tab({
        Title = "Premium",
        Icon = "star",
        Locked = false,
    })

    
    
    
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    local RepStorage = game:GetService("ReplicatedStorage")
    local ItemUtility = require(RepStorage.Shared.ItemUtility)

    local function GetRemote(remotePath, name, timeout)
        local currentInstance = RepStorage
        for _, childName in ipairs(remotePath) do
            currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
            if not currentInstance then return nil end
        end
        return currentInstance:FindFirstChild(name)
    end

    
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem") 
    local RE_EquipBait = GetRemote(RPath, "RE/EquipBait") 
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")
    
    local RF_PurchaseFishingRod = GetRemote(RPath, "RF/PurchaseFishingRod")
    local RF_PurchaseBait = GetRemote(RPath, "RF/PurchaseBait")
    local RF_SellAllItems = GetRemote(RPath, "RF/SellAllItems")
    
    local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
    local RE_ObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification") 

    local RF_PlaceLeverItem = GetRemote(RPath, "RE/PlaceLeverItem")
    local RE_SpawnTotem = GetRemote(RPath, "RE/SpawnTotem")
    local RF_CreateTranscendedStone = GetRemote(RPath, "RF/CreateTranscendedStone")
    local RF_ConsumePotion = GetRemote(RPath, "RF/ConsumePotion")
    local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")
    
    


    premium:Divider()

    local totem = premium:Section({ Title = "Auto Spawn Totem", TextSize = 20})
    local TOTEM_STATUS_PARAGRAPH = totem:Paragraph({ Title = "Status", Content = "Waiting...", Icon = "clock" })
    
    local TOTEM_DATA = {
        ["Luck Totem"]={Id=1,Duration=3601}, 
        ["Mutation Totem"]={Id=2,Duration=3601}, 
        ["Shiny Totem"]={Id=3,Duration=3601}
    }
    local TOTEM_NAMES = {"Luck Totem", "Mutation Totem", "Shiny Totem"}
    local selectedTotemName = "Luck Totem"
    local currentTotemExpiry = 0
    local AUTO_TOTEM_ACTIVE = false
    local AUTO_TOTEM_THREAD = nil

    local RunService = game:GetService("RunService")

    
    local REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
    local REF_SPOTS = {
        
        Vector3.new(45.0468979, 9.51625347, 2730.19067),   
        Vector3.new(145.644608, 9.51625347, 2721.90747),   
        Vector3.new(84.6406631, 10.2174253, 2636.05786),   
        Vector3.new(45.0468979, 110.516253, 2730.19067),   
        Vector3.new(145.644608, 110.516253, 2721.90747),   
        Vector3.new(84.6406631, 111.217425, 2636.05786),   
        Vector3.new(45.0468979, -92.483747, 2730.19067),   
        Vector3.new(145.644608, -92.483747, 2721.90747),   
        Vector3.new(84.6406631, -93.782575, 2636.05786),   
    }

    local AUTO_9_TOTEM_ACTIVE = false
    local AUTO_9_TOTEM_THREAD = nil
    local stateConnection = nil 
    
    local function GetFlyPart()
        local char = game.Players.LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end

    local function MaintainAntiFallState(enable)
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then return end

        if enable then
            
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) 
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

            
            
            if not stateConnection then
                stateConnection = RunService.Heartbeat:Connect(function()
                    if hum and AUTO_9_TOTEM_ACTIVE then
                        hum:ChangeState(Enum.HumanoidStateType.Swimming)
                        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
                    end
                end)
            end
        else
            
            if stateConnection then stateConnection:Disconnect(); stateConnection = nil end
            
            
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end
    end

    local function EnableV3Physics()
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local mainPart = GetFlyPart()
        
        if not mainPart or not hum then return end

        
        if char:FindFirstChild("Animate") then char.Animate.Disabled = true end
        hum.PlatformStand = true 
        
        
        MaintainAntiFallState(true)

        
        local bg = mainPart:FindFirstChild("FlyGuiGyro") or Instance.new("BodyGyro", mainPart)
        bg.Name = "FlyGuiGyro"
        bg.P = 9e4 
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = mainPart.CFrame

        local bv = mainPart:FindFirstChild("FlyGuiVelocity") or Instance.new("BodyVelocity", mainPart)
        bv.Name = "FlyGuiVelocity"
        bv.velocity = Vector3.new(0, 0.1, 0) 
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

        
        task.spawn(function()
            while AUTO_9_TOTEM_ACTIVE and char do
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
                task.wait(0.1)
            end
        end)
    end

    local function DisableV3Physics()
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local mainPart = GetFlyPart() 

        if mainPart then
            
            if mainPart:FindFirstChild("FlyGuiGyro") then mainPart.FlyGuiGyro:Destroy() end
            if mainPart:FindFirstChild("FlyGuiVelocity") then mainPart.FlyGuiVelocity:Destroy() end
            
            
            mainPart.Velocity = Vector3.zero
            mainPart.RotVelocity = Vector3.zero
            mainPart.AssemblyLinearVelocity = Vector3.zero 
            mainPart.AssemblyAngularVelocity = Vector3.zero

            local x, y, z = mainPart.CFrame:ToEulerAnglesYXZ()
            mainPart.CFrame = CFrame.new(mainPart.Position) * CFrame.fromEulerAnglesYXZ(0, y, 0)
            
            local ray = Ray.new(mainPart.Position, Vector3.new(0, -5, 0))
            local hit, pos = workspace:FindPartOnRay(ray, char)
            if hit then
                mainPart.CFrame = mainPart.CFrame + Vector3.new(0, 3, 0)
            end
        end

        if hum then 
            
            hum.PlatformStand = false 
            
            
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        
        
        MaintainAntiFallState(false) 
        
        
        if char and char:FindFirstChild("Animate") then char.Animate.Disabled = false end
        
        
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end

    
    local function FlyPhysicsTo(targetPos)
        local mainPart = GetFlyPart()
        if not mainPart then return end
        
        local bv = mainPart:FindFirstChild("FlyGuiVelocity")
        local bg = mainPart:FindFirstChild("FlyGuiGyro")
        if not bv or not bg then EnableV3Physics(); bv = mainPart.FlyGuiVelocity; bg = mainPart.FlyGuiGyro end

        local SPEED = 80 
        
        while AUTO_9_TOTEM_ACTIVE do
            local currentPos = mainPart.Position
            local diff = targetPos - currentPos
            local dist = diff.Magnitude
            
            bg.CFrame = CFrame.lookAt(currentPos, targetPos)

            if dist < 1.0 then 
                bv.velocity = Vector3.new(0, 0.1, 0)
                break
            else
                bv.velocity = diff.Unit * SPEED
            end
            RunService.Heartbeat:Wait()
        end
    end
    
    local function GetTotemUUID(name)
        local r = GetPlayerDataReplion() if not r then return nil end
        local s, d = pcall(function() return r:GetExpect("Inventory") end)
        if s and d.Totems then 
            for _, i in ipairs(d.Totems) do 
                if tonumber(i.Id) == TOTEM_DATA[name].Id and (i.Count or 1) >= 1 then return i.UUID end 
            end 
        end
    end

    
    local RF_EquipOxygenTank = GetRemote(RPath, "RF/EquipOxygenTank")
    local RF_UnequipOxygenTank = GetRemote(RPath, "RF/UnequipOxygenTank")

    local function Run9TotemLoop()
        if AUTO_9_TOTEM_THREAD then task.cancel(AUTO_9_TOTEM_THREAD) end
        
        AUTO_9_TOTEM_THREAD = task.spawn(function()
            local uuid = GetTotemUUID(selectedTotemName)
            if not uuid then 
                WindUI:Notify({ Title = "No Stock", Content = "Isi inventory dulu!", Duration = 3, Icon = "x" })
                local t = totem:GetElementByTitle("Spawn 9 Totem Formation")
                if t then t:Set(false) end
                return 
            end

            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp then return end
            
            local myStartPos = hrp.Position 

            WindUI:Notify({ Title = "Started", Content = "V3 Engine + Oxygen Protection!", Duration = 3, Icon = "zap" })
            
            
            if RF_EquipOxygenTank then
                pcall(function() RF_EquipOxygenTank:InvokeServer(105) end)
            end
            
            
            if hum then hum.Health = hum.MaxHealth end

            EnableV3Physics()

            for i, refSpot in ipairs(REF_SPOTS) do
                if not AUTO_9_TOTEM_ACTIVE then break end
                
                local relativePos = refSpot - REF_CENTER
                local targetPos = myStartPos + relativePos
                
                TOTEM_STATUS_PARAGRAPH:SetDesc(string.format("Flying to #%d...", i))
                FlyPhysicsTo(targetPos) 
                
                
                task.wait(0.6) 

                uuid = GetTotemUUID(selectedTotemName)
                if uuid then
                    TOTEM_STATUS_PARAGRAPH:SetDesc(string.format("Spawning #%d...", i))
                    pcall(function() RE_SpawnTotem:FireServer(uuid) end)
                    
                    task.spawn(function() 
                        for k=1,5 do RE_EquipToolFromHotbar:FireServer(1); task.wait(0.1) end 
                    end)
                else
                    break
                end
                
                task.wait(1.5) 
            end

            if AUTO_9_TOTEM_ACTIVE then
                TOTEM_STATUS_PARAGRAPH:SetDesc("Returning...")
                FlyPhysicsTo(myStartPos)
                task.wait(0.5)
                WindUI:Notify({ Title = "Selesai", Content = "Landing...", Duration = 3, Icon = "check" })
            end
            
            
            if RF_UnequipOxygenTank then
                pcall(function() RF_UnequipOxygenTank:InvokeServer() end)
            end

            DisableV3Physics() 
            AUTO_9_TOTEM_ACTIVE = false
            local t = totem:GetElementByTitle("Spawn 9 Totem Formation")
            if t then t:Set(false) end
        end)
    end

    local function RunAutoTotemLoop()
        if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end
        AUTO_TOTEM_THREAD = task.spawn(function()
            while AUTO_TOTEM_ACTIVE do
                local timeLeft = currentTotemExpiry - os.time()
                if timeLeft > 0 then
                    local m = math.floor((timeLeft % 3600) / 60); local s = math.floor(timeLeft % 60)
                    TOTEM_STATUS_PARAGRAPH:SetDesc(string.format("Next Spawn: %02d:%02d", m, s))
                else
                    TOTEM_STATUS_PARAGRAPH:SetDesc("Spawning Single...")
                    local uuid = GetTotemUUID(selectedTotemName)
                    if uuid then
                        pcall(function() RE_SpawnTotem:FireServer(uuid) end)
                        currentTotemExpiry = os.time() + TOTEM_DATA[selectedTotemName].Duration
                        task.spawn(function() for i=1,3 do task.wait(0.2) pcall(function() RE_EquipToolFromHotbar:FireServer(1) end) end end)
                    end
                end
                task.wait(1)
            end
        end)
    end

    local choosetot = totem:Dropdown({ Title = "Pilih Jenis Totem", Values = TOTEM_NAMES, Value = selectedTotemName, Multi = false, Callback = function(n) selectedTotemName = n; currentTotemExpiry = 0 end })

    local togtot = totem:Toggle({ Title = "Enable Auto Totem (Single)", Desc = "Mode Normal", Value = false, Flag = "toggletotem", Callback = function(s) AUTO_TOTEM_ACTIVE = s; if s then RunAutoTotemLoop() else if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end end end })

    local tog9tot = totem:Toggle({
        Title = "Auto Spawn 9 Totem",
        Value = false,
        Flag = "toggle9totem",
        Callback = function(s)
            AUTO_9_TOTEM_ACTIVE = s
            if s then
                Run9TotemLoop()
            else
                if AUTO_9_TOTEM_THREAD then task.cancel(AUTO_9_TOTEM_THREAD) end
                DisableV3Physics()
                WindUI:Notify({ Title = "Stopped", Content = "Berhenti.", Duration = 2, Icon = "x" })
            end
        end
    })

    premium:Divider()
    local potion = premium:Section({ Title = "Auto Consume Potions", TextSize = 20})
    POTION_STATUS_PARAGRAPH = potion:Paragraph({ Title = "Potion Status", Content = "Status: OFF", Icon = "timer" })

    local function GetPotionUUID(name)
        local r = GetPlayerDataReplion() if not r then return nil end
        local s, d = pcall(function() return r:GetExpect("Inventory") end)
        if s and d.Potions then for _, i in ipairs(d.Potions) do if tonumber(i.Id) == POTION_DATA[name].Id and (i.Count or 1) >= 1 then return i.UUID end end end
    end

    local function RunAutoPotionLoop()
        if AUTO_POTION_THREAD then task.cancel(AUTO_POTION_THREAD) end
        AUTO_POTION_THREAD = task.spawn(function()
            while AUTO_POTION_ACTIVE do
                local cur = os.time()
                for _, name in ipairs(selectedPotions) do
                    local exp = potionTimers[name] or 0
                    if cur >= exp then
                        local uuid = GetPotionUUID(name)
                        if uuid then
                            pcall(function() RF_ConsumePotion:InvokeServer(uuid, 1) end)
                            potionTimers[name] = cur + POTION_DATA[name].Duration + 2
                        end
                    end
                end
                
                if POTION_STATUS_PARAGRAPH then
                    local txt = ""
                    for _, n in ipairs(selectedPotions) do
                        local lf = (potionTimers[n] or 0) - cur
                        if lf > 0 then txt = txt .. string.format("🟢 %s: %ds\n", n, lf) else txt = txt .. string.format("🟡 %s: Checking...\n", n) end
                    end
                    POTION_STATUS_PARAGRAPH:SetDesc(txt~="" and txt or "No Potion Selected")
                end
                task.wait(1)
            end
        end)
    end

    local choosepot = potion:Dropdown({ Title = "Select Potions", Values = POTION_NAMES_LIST, Multi = true, AllowNone = true, Callback = function(v) selectedPotions = v or {} end })
    local togpot = potion:Toggle({ Title = "Enable Auto Potion", Value = false, Callback = function(s) AUTO_POTION_ACTIVE = s if s then RunAutoPotionLoop() else if AUTO_POTION_THREAD then task.cancel(AUTO_POTION_THREAD) end end end })
end

do
    local quest = Window:Tab({
        Title = "Quests",
        Icon = "scroll",
        Locked = false,
    })

    local ID_GHOSTFIN_ROD = 169
    local GHOSTFIN_QUEST_ACTIVE = false
    local GHOSTFIN_MAIN_THREAD = nil
    local ELEMENT_QUEST_ACTIVE = false
    local ELEMENT_MAIN_THREAD = nil
    local QUEST_AUTO_EQUIP_THREAD = nil 

    
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    
    local function GetRemote(remotePath, name, timeout)
        local currentInstance = game:GetService("ReplicatedStorage")
        for _, childName in ipairs(remotePath) do
            currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
            if not currentInstance then return nil end
        end
        return currentInstance:FindFirstChild(name)
    end

    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
    local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")
    local RF_CreateTranscendedStone = GetRemote(RPath, "RF/CreateTranscendedStone")
    local RF_PlaceLeverItem = GetRemote(RPath, "RE/PlaceLeverItem")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem")
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")

    
    local TREASURE_ROOM_POS = Vector3.new(-3598.440, -281.274, -1645.855)
    local TREASURE_ROOM_LOOK = Vector3.new(-0.065, 0.000, -0.998)
    local SISYPHUS_POS = Vector3.new(-3743.745, -135.074, -1007.554)
    local SISYPHUS_LOOK = Vector3.new(0.310, 0.000, 0.951)
    local ANCIENT_JUNGLE_POS = Vector3.new(1535.639, 3.159, -193.352)
    local ANCIENT_JUNGLE_LOOK = Vector3.new(0.505, -0.000, 0.863)
    local SACRED_TEMPLE_POS = Vector3.new(1461.815, -22.125, -670.234)
    local SACRED_TEMPLE_LOOK = Vector3.new(-0.990, -0.000, 0.143)
    local SECOND_ALTAR_POS = Vector3.new(1479.587, 128.295, -604.224)
    local SECOND_ALTAR_LOOK = Vector3.new(-0.298, 0.000, -0.955)

    
    local ArtifactData = {
        ["Hourglass Diamond Artifact"] = {
            ItemName = "Hourglass Diamond Artifact", LeverName = "Hourglass Diamond Lever", ChildReference = 6, CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(255, 248, 49),
            FishingPos = {Pos = Vector3.new(1490.144, 3.312, -843.171), Look = Vector3.new(0.115, 0.000, 0.993)},
        },
        ["Diamond Artifact"] = {
            ItemName = "Diamond Artifact", LeverName = "Diamond Lever", ChildReference = "TempleLever", CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(219, 38, 255),
            FishingPos = {Pos = Vector3.new(1844.159, 2.530, -288.755), Look = Vector3.new(0.981, 0.000, -0.193)},
        },
        ["Arrow Artifact"] = {
            ItemName = "Arrow Artifact", LeverName = "Arrow Lever", ChildReference = 5, CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(255, 47, 47),
            FishingPos = {Pos = Vector3.new(874.365, 2.530, -358.484), Look = Vector3.new(-0.990, 0.000, 0.144)},
        },
        ["Crescent Artifact"] = {
            ItemName = "Crescent Artifact", LeverName = "Crescent Lever", ChildReference = 4, CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(112, 255, 69),
            FishingPos = {Pos = Vector3.new(1401.070, 6.489, 116.738), Look = Vector3.new(-0.500, -0.000, 0.866)},
        },
    }
    local ArtifactOrder = {"Hourglass Diamond Artifact", "Diamond Artifact", "Arrow Artifact", "Crescent Artifact"}

    local SPECIAL_ROD_IDS = {[169] = {Name = "Ghostfin Rod", Price = 99999999}, [257] = {Name = "Element Rod", Price = 999999999}}
    local ShopItems = {
        ["Rods"] = {
            {Name="Luck Rod",ID=79,Price=325},{Name="Carbon Rod",ID=76,Price=750},{Name="Grass Rod",ID=85,Price=1500},{Name="Demascus Rod",ID=77,Price=3000},
            {Name="Ice Rod",ID=78,Price=5000},{Name="Lucky Rod",ID=4,Price=15000},{Name="Midnight Rod",ID=80,Price=50000},{Name="Steampunk Rod",ID=6,Price=215000},
            {Name="Chrome Rod",ID=7,Price=437000},{Name="Flourescent Rod",ID=255,Price=715000},{Name="Astral Rod",ID=5,Price=1000000},
            {Name="Ares Rod",ID=126,Price=3000000},{Name="Angler Rod",ID=168,Price=8000000},{Name = "Bamboo Rod", ID = 258, Price = 12000000}
        }
    }
    
    local ROD_DELAYS = {
    
    [79]  = 4.6, 
    [76]  = 4.35, 
    [85]  = 4.2, 
    [77]  = 4.35, 
    [78]  = 3.85, 
    
    
    [4]   = 3.5, 
    [80]  = 2.7, 
    
    
    [6]   = 2.3, 
    [7]   = 2.2, 
    [255] = 2.2, 
    [5]   = 1.85, 
    
    
    [126] = 1.7, 
    [168] = 1.6, 
    
    
    [169] = 1.2, 
    [257] = 1, 
}

local DEFAULT_ROD_DELAY = 3.85

    local function GetRodPriceByID(id)
        id = tonumber(id)
        if SPECIAL_ROD_IDS[id] then return SPECIAL_ROD_IDS[id].Price, SPECIAL_ROD_IDS[id].Name end
        for _, item in ipairs(ShopItems["Rods"]) do if item.ID == id then return item.Price, item.Name end end
        return 0, "Unknown Rod"
    end

    local function EquipBestRod()
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return DEFAULT_ROD_DELAY end 
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData then return DEFAULT_ROD_DELAY end

        
        local bestRodUUID, bestRodPrice = nil, -1
        local bestRodId = nil 

        if inventoryData["Fishing Rods"] then
            for _, rod in ipairs(inventoryData["Fishing Rods"]) do
                local price = GetRodPriceByID(rod.Id)
                if price > bestRodPrice then 
                    bestRodPrice = price
                    bestRodUUID = rod.UUID 
                    bestRodId = tonumber(rod.Id) 
                end
            end
        end

        
        if bestRodUUID then 
            pcall(function() RE_EquipItem:FireServer(bestRodUUID, "Fishing Rods") end) 
        end
        
        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)

        if bestRodId and ROD_DELAYS[bestRodId] then
            return ROD_DELAYS[bestRodId]
        else
            return DEFAULT_ROD_DELAY
        end
    end
    
    local function RunQuestInstantFish(dynamicDelay)
        if not (RE_EquipToolFromHotbar and RF_ChargeFishingRod and RF_RequestFishingMinigameStarted and RE_FishingCompleted and RF_CancelFishingInputs) then return end
        
        
        local timestamp = os.time() + os.clock()
        pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
        
        
        pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797) end)
        
        
        task.wait(dynamicDelay)
        
        
        pcall(function() RE_FishingCompleted:FireServer() end)
        task.wait(0.3)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
    end

    
    local function StartQuestAutoEquip()
        if QUEST_AUTO_EQUIP_THREAD then task.cancel(QUEST_AUTO_EQUIP_THREAD) end
        QUEST_AUTO_EQUIP_THREAD = task.spawn(function()
            local tick = 0
            while GHOSTFIN_QUEST_ACTIVE or ELEMENT_QUEST_ACTIVE do
                
                pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                
                
                if tick % 10 == 0 then
                    EquipBestRod() 
                end
                
                tick = tick + 1
                task.wait(0.5)
            end
        end)
    end

    local function StopQuestAutoEquip()
        if QUEST_AUTO_EQUIP_THREAD then task.cancel(QUEST_AUTO_EQUIP_THREAD) QUEST_AUTO_EQUIP_THREAD = nil end
        pcall(function() RE_EquipToolFromHotbar:FireServer(0) end) 
    end

    local function HasGhostfinRod()
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return false end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData["Fishing Rods"] then return false end
        for _, rod in ipairs(inventoryData["Fishing Rods"]) do
            if tonumber(rod.Id) == ID_GHOSTFIN_ROD then return true end
        end
        return false
    end

    local function GetLowestWeightSecrets(limit)
        local secrets = {}
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return {} end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if success and inventoryData and inventoryData.Items then
            for _, item in ipairs(inventoryData.Items) do
                local rarity = item.Metadata and item.Metadata.Rarity or "Unknown"
                if rarity:upper() == "SECRET" and item.Metadata and item.Metadata.Weight then
                    if not (item.IsFavorite or item.Favorited or item.Locked) then
                        table.insert(secrets, {UUID = item.UUID, Weight = item.Metadata.Weight})
                    end
                end
            end
        end
        table.sort(secrets, function(a, b) return a.Weight < b.Weight end)
        local result = {}
        for i = 1, math.min(limit, #secrets) do table.insert(result, secrets[i].UUID) end
        return result
    end

    local function IsLeverUnlocked(artifactName)
        local JUNGLE_INTERACTIONS = workspace:FindFirstChild("JUNGLE INTERACTIONS")
        if not JUNGLE_INTERACTIONS then return false end
        local data = ArtifactData[artifactName]
        if not data then return false end
        
        local leverFolder = nil
        if type(data.ChildReference) == "string" then leverFolder = JUNGLE_INTERACTIONS:FindFirstChild(data.ChildReference) end
        if not leverFolder and type(data.ChildReference) == "number" then local c = JUNGLE_INTERACTIONS:GetChildren() leverFolder = c[data.ChildReference] end
        if not leverFolder then return false end
        
        local crystal = leverFolder:FindFirstChild(data.CrystalPathSuffix)
        if not crystal or not crystal:IsA("BasePart") then return false end
        
        local cC, tC = crystal.Color, data.UnlockColor
        return (math.abs(cC.R*255 - tC.R*255) < 1.1 and math.abs(cC.G*255 - tC.G*255) < 1.1 and math.abs(cC.B*255 - tC.B*255) < 1.1)
    end

end

local lastPositionBeforeEvent = nil
local autoJoinEventActive = false
local LOCHNESS_POS = Vector3.new(6063.347, -585.925, 4713.696)
local LOCHNESS_LOOK = Vector3.new(-0.376, -0.000, -0.927)
local AUTO_UNLOCK_STATE = false
local AUTO_UNLOCK_THREAD = nil
local AUTO_UNLOCK_ATTEMPT_THREAD = nil 
local RUIN_COMPLETE_DELAY = 1.5
local RUIN_DOOR_PATH = workspace["RUIN INTERACTIONS"] and workspace["RUIN INTERACTIONS"].Door
local ITEM_FISH_NAMES = {"Freshwater Piranha", "Goliath Tiger", "Sacred Guardian Squid", "Crocodile"}
local SACRED_TEMPLE_POS = FishingAreas["Sacred Temple"].Pos
local SACRED_TEMPLE_LOOK = FishingAreas["Sacred Temple"].Look
local RUIN_DOOR_REMOTE = GetRemote(RPath, "RE/PlacePressureItem")
local RUIN_DOOR_STATUS_PARAGRAPH
local RUIN_AUTO_UNLOCK_TOGGLE
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")
local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")


local function GetEventGUI()
	local success, gui = pcall(function()
		local menuRings = workspace:WaitForChild("!!! MENU RINGS", 5)
		local eventTracker = menuRings:WaitForChild("Event Tracker", 5)
		local contentItems = eventTracker.Main.Gui.Content.Items

		local countdown = contentItems.Countdown:WaitForChild("Label")	
		local statsContainer = contentItems:WaitForChild("Stats")	
		local timer = statsContainer.Timer:WaitForChild("Label")	
		
		local quantity = statsContainer:WaitForChild("Quantity")	
		local odds = statsContainer:WaitForChild("Odds")

		return {
			Countdown = countdown,
			Timer = timer,
			Quantity = quantity,
			Odds = odds,
		}
	end)
	
	if success and gui then
		return gui
	end
	return nil
end


local function GetRuinDoorStatus()
	local ruinDoor = RUIN_DOOR_PATH 
	local status = "LOCKED 🔒"
	
	if ruinDoor and ruinDoor:FindFirstChild("RuinDoor") then
		local LDoor = ruinDoor.RuinDoor:FindFirstChild("LDoor")
		
		if LDoor then
			local currentX = nil
			
			if LDoor:IsA("BasePart") then
				currentX = LDoor.Position.X
			elseif LDoor:IsA("Model") then
				
				local success, pivot = pcall(function() return LDoor:GetPivot() end)
                if success and pivot then
                    currentX = pivot.Position.X
                end
			end
			
			if currentX ~= nil then
				
				if currentX > 6075 then
					status = "UNLOCKED ✅"
				end
			end
		end
	end
	
    
	RUIN_DOOR_STATUS_PARAGRAPH:SetTitle("Ruin Door Status: " .. status)
	return status
end



local function IsItemAvailable(itemName)
	local replion = GetPlayerDataReplion()
	if not replion then return false end
	local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
	if not success or not inventoryData or not inventoryData.Items then return false end

	for _, item in ipairs(inventoryData.Items) do
		if item.Identifier == itemName then
			return true
		end
		
		local name, _ = GetFishNameAndRarity(item)
		if name == itemName and (item.Count or 1) >= 1 then
			return true
		end
	end
	return false
end

local function GetMissingItem()
	for _, name in ipairs(ITEM_FISH_NAMES) do
		if not IsItemAvailable(name) then
			return name
		end
	end
	return nil
end

local function runInstantFish()
	if not (RE_EquipToolFromHotbar and RF_ChargeFishingRod and RF_RequestFishingMinigameStarted and RE_FishingCompleted and RF_CancelFishingInputs) then
		return false
	end
	
	pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
	
	local timestamp = os.time() + os.clock()
	pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
	pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797) end)
	
	task.wait(RUIN_COMPLETE_DELAY)

	pcall(function() RE_FishingCompleted:FireServer() end)
	task.wait(0.3)
	pcall(function() RF_CancelFishingInputs:FireServer() end)
	
	return true
end

local function RunRuinDoorUnlockAttemptLoop()
	if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) end

	if not RUIN_DOOR_REMOTE then
		WindUI:Notify({ Title = "Error Remote", Content = "Remote Ruin Door (RE/PlacePressureItem) tidak ditemukan.", Duration = 4, Icon = "x" })
		return
	end
	
	AUTO_UNLOCK_ATTEMPT_THREAD = task.spawn(function()
		local RUIN_DOOR_POS = FishingAreas["Ancient Ruin"].Pos
		local RUIN_DOOR_LOOK = FishingAreas["Ancient Ruin"].Look
		
		TeleportToLookAt(RUIN_DOOR_POS, RUIN_DOOR_LOOK)
		task.wait(1.5)
		
		WindUI:Notify({ Title = "Unlock Attempt ON", Content = "Mulai agresif kirim remote PlacePressureItem...", Duration = 3, Icon = "zap" })

		while AUTO_UNLOCK_STATE and GetRuinDoorStatus() == "LOCKED 🔒" do
			for i, name in ipairs(ITEM_FISH_NAMES) do
				task.wait(2.1)
				pcall(function() RUIN_DOOR_REMOTE:FireServer(name) end)
			end
			
			task.wait(5)
		end
	end)
end

local function RunAutoUnlockLoop()
	if AUTO_UNLOCK_THREAD then task.cancel(AUTO_UNLOCK_THREAD) end
	if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) end
	
	pcall(function()
		local toggleLegit = Window:GetElementByTitle("Auto Fish (Legit)")
		local toggleNormal = Window:GetElementByTitle("Normal Instant Fish")
		local toggleBlatant = Window:GetElementByTitle("Instant Fishing (Blatant)")
		
		if toggleLegit and toggleLegit.Value then toggleLegit:Set(false) end
		if toggleNormal and toggleNormal.Value then toggleNormal:Set(false) end
		if toggleBlatant and toggleBlatant.Value then toggleBlatant:Set(false) end
		if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end
	end)

	AUTO_UNLOCK_THREAD = task.spawn(function()
		local isFarming = false
		local lastPositionBeforeEvent_Ruin = nil
		
		RunRuinDoorUnlockAttemptLoop()
		
		while AUTO_UNLOCK_STATE do
			local doorStatus = GetRuinDoorStatus()
			RUIN_DOOR_STATUS_PARAGRAPH:SetTitle("Ruin Door Status: " .. doorStatus)

			if doorStatus == "LOCKED 🔒" then
				local missingItem = GetMissingItem()

				if missingItem then
					
					if not isFarming then
						local hrp = GetHRP()
						if hrp and lastPositionBeforeEvent_Ruin == nil then
							lastPositionBeforeEvent_Ruin = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
							WindUI:Notify({ Title = "Posisi Disimpan", Content = "Posisi sebelum Ruin Door farm disimpan.", Duration = 2, Icon = "save" })
						end
						TeleportToLookAt(SACRED_TEMPLE_POS, SACRED_TEMPLE_LOOK)
						task.wait(1.5)
						isFarming = true
						WindUI:Notify({ Title = "Ruin Door: Farming", Content = "Mencari " .. missingItem .. ". Fishing ON (Delay: "..RUIN_COMPLETE_DELAY.."s).", Duration = 4, Icon = "fish" })
					end
					
					RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Mencari item: " .. missingItem .. ". Fishing...")
					runInstantFish()
					task.wait(RUIN_COMPLETE_DELAY + 0.5)
					
				else
					RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Semua item ada! Loop Unlock Agresif berjalan...")
					isFarming = false
					
					task.wait(1)
				end
				
			elseif doorStatus == "UNLOCKED ✅" then
				RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Pintu sudah tidak terkunci. Auto Unlock berhenti.")
				
				if lastPositionBeforeEvent_Ruin then
					TeleportToLookAt(lastPositionBeforeEvent_Ruin.Pos, lastPositionBeforeEvent_Ruin.Look)
					lastPositionBeforeEvent_Ruin = nil
					WindUI:Notify({ Title = "Kembali ke Posisi Awal", Content = "Door UNLOCKED, melanjutkan farm.", Duration = 4, Icon = "repeat" })
				end
				break
				
			else
				RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Status Pintu tidak terdeteksi. Memeriksa ulang...")
				task.wait(5)
			end
		end
		
		pcall(function()
			if RE_EquipToolFromHotbar then RE_EquipToolFromHotbar:FireServer(0) end
		end)
		
		AUTO_UNLOCK_STATE = false
		if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) AUTO_UNLOCK_ATTEMPT_THREAD = nil end
		if RUIN_AUTO_UNLOCK_TOGGLE and RUIN_AUTO_UNLOCK_TOGGLE.Set then RUIN_AUTO_UNLOCK_TOGGLE:Set(false) end
		WindUI:Notify({ Title = "Auto Unlock OFF", Content = "Proses Ruin Door dihentikan.", Duration = 3, Icon = "x" })
	end)
end

do
	local Event = Window:Tab({
		Title = "Events",
		Icon = "calendar",
		Locked = false,
	})

	local EventSyncThread = nil
    local loknes = Event:Section({
        Title = "Ancient Lochness Event",
        TextSize = 20,
    })
	local CountdownParagraph = loknes:Paragraph({
		Title = "Event Countdown: Waiting...",
		Content = "Status: Mencoba sinkronisasi event...",
		Icon = "clock"
	})
	local StatsParagraph = loknes:Paragraph({
		Title = "Event Stats: N/A",
		Content = "Timer: N/A\nCaught: N/A\nChance: N/A",
		Icon = "trending-up"
	})
	
	local LochnessToggle
	
	local function UpdateEventStats()
		local gui = GetEventGUI()
		
		if not gui then
			CountdownParagraph:SetTitle("Event Countdown: GUI Not Found ❌")
			CountdownParagraph:SetDesc("Pastikan 'Event Tracker' sudah dimuat di workspace.")
			StatsParagraph:SetTitle("Event Stats: N/A")
			StatsParagraph:SetDesc("Timer: N/A\nCaught: N/A\nChance: N/A")
			return false
		end
		
		local countdownText = gui.Countdown and (gui.Countdown.ContentText or gui.Countdown.Text) or "N/A"
		local timerText = gui.Timer and (gui.Timer.ContentText or gui.Timer.Text) or "N/A"
		local quantityText = gui.Quantity and (gui.Quantity.ContentText or gui.Quantity.Text) or "N/A"
		local oddsText = gui.Odds and (gui.Odds.ContentText or gui.Odds.Text) or "N/A"

		CountdownParagraph:SetTitle("Ancient Lochness Start In:")
		CountdownParagraph:SetDesc(countdownText)

		StatsParagraph:SetTitle("Ancient Lochness Stats")
		StatsParagraph:SetDesc(string.format("- Timer: %s\n- Caught: %s\n- Chance: %s",
			timerText, quantityText, oddsText))

		local isEventActive = timerText:find("M") and timerText:find("S") and not timerText:match("^0M 0S")
		
		return isEventActive
	end

	local function RunEventSyncLoop()
	if EventSyncThread then task.cancel(EventSyncThread) end

	EventSyncThread = task.spawn(function()
		local isTeleportedToEvent = false
		
		while true do
			local isEventActive = UpdateEventStats()
			
			if autoJoinEventActive then
				if isEventActive and not isTeleportedToEvent then
					if lastPositionBeforeEvent == nil then
						local hrp = GetHRP()
						if hrp then
							lastPositionBeforeEvent = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
							WindUI:Notify({ Title = "Posisi Disimpan", Content = "Posisi sebelum Event disimpan.", Duration = 2, Icon = "save" })
						end
					end
					
					TeleportToLookAt(LOCHNESS_POS, LOCHNESS_LOOK)
					isTeleportedToEvent = true
					WindUI:Notify({ Title = "Auto Join ON", Content = "Teleport ke Ancient Lochness.", Duration = 4, Icon = "zap" })

				elseif isTeleportedToEvent and not isEventActive and lastPositionBeforeEvent ~= nil then
                
                WindUI:Notify({ Title = "Event Selesai", Content = "Menunggu 15 detik sebelum kembali...", Duration = 5, Icon = "clock" })
                task.wait(15) 
                
                TeleportToLookAt(lastPositionBeforeEvent.Pos, lastPositionBeforeEvent.Look)
                lastPositionBeforeEvent = nil
                isTeleportedToEvent = false
                WindUI:Notify({ Title = "Teleport Back", Content = "Kembali ke posisi semula.", Duration = 3, Icon = "repeat" })
            end
		end

			task.wait(0.5)
		end
	end)
end
	
	RunEventSyncLoop()
	
	local LochnessToggle = Reg("tloknes",loknes:Toggle({
		Title = "Auto Join Ancient Lochness Event",
		Desc = "Otomatis Teleport ke event saat aktif, dan kembali saat event berakhir.",
		Value = false,
		Callback = function(state)
			autoJoinEventActive = state
			if state then
				WindUI:Notify({ Title = "Auto Join ON", Content = "Mulai memantau event Ancient Lochness.", Duration = 3, Icon = "check" })
			else
				WindUI:Notify({ Title = "Auto Join OFF", Content = "Pemantauan dihentikan.", Duration = 3, Icon = "x" })
			end
		end
	}))

	
	RUIN_DOOR_STATUS_PARAGRAPH = loknes:Paragraph({
		Title = "Ruin Door Status: N/A",
		Content = "Status Locked/Unlocked. Tekan Toggle untuk memulai monitor."
	})

	local lochnessdelay = loknes:Input({
		Title = "Ruin Door Instant Delay",
		Desc = "Delay (dalam detik) untuk Normal Instant Fish saat farming item Ruin Door. Default: 1.5s.",
		Value = tostring(RUIN_COMPLETE_DELAY),
		Placeholder = "1.5",
		Callback = function(input)
			local newDelay = tonumber(input)
			if newDelay and newDelay >= 0.5 then
				RUIN_COMPLETE_DELAY = newDelay
			else
				WindUI:Notify({ Title = "Input Invalid", Content = "Minimal delay 0.5 detik.", Duration = 2, Icon = "alert-triangle" })
			end
		end
	})

	local RUIN_AUTO_UNLOCK_TOGGLE = loknes:Toggle({
		Title = "Auto Unlock Ruin Door",
		Desc = "Otomatis memfarm 4 item yang hilang menggunakan Normal Instant Fish, lalu unlock pintu.",
		Value = false,
		Callback = function(state)
		AUTO_UNLOCK_STATE = state
		if state then
			if GetRuinDoorStatus() == "UNLOCKED ✅" then
				WindUI:Notify({ Title = "Ruin Door", Content = "Pintu sudah terbuka. Auto Unlock tidak berjalan.", Duration = 4, Icon = "info" })
					return false
			end	
			WindUI:Notify({ Title = "Auto Unlock ON", Content = "Mulai memantau Ruin Door dan Inventory.", Duration = 3, Icon = "check" })
			RunAutoUnlockLoop()
			else
					if AUTO_UNLOCK_THREAD then task.cancel(AUTO_UNLOCK_THREAD) AUTO_UNLOCK_THREAD = nil end
					if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) AUTO_UNLOCK_ATTEMPT_THREAD = nil end
			WindUI:Notify({ Title = "Auto Unlock OFF", Content = "Proses Ruin Door dihentikan.", Duration = 3, Icon = "x" })
		end
end
	})
	
    Event:Divider()

    local autoClaimClassicState = false
    local autoClaimClassicThread = nil    
    local RE_ClaimEventReward = nil
    pcall(function()
        RE_ClaimEventReward = game:GetService("ReplicatedStorage")
            :WaitForChild("Packages", 10)
            :WaitForChild("_Index", 10)
            :WaitForChild("sleitnick_net@0.2.0", 10)
            :WaitForChild("net", 10)
            :WaitForChild("RE/ClaimEventReward", 10)
    end)

end

GetRuinDoorStatus()

do
local utility = Window:Tab({
    Title = "Tools",
    Icon = "box",
    Locked = false,
})

local backpack = utility:Section({ Title = "Backpack Scanner", TextSize = 20, })
local FishScanDisplay = backpack:Paragraph({
    Title = "Status: Scan untuk melihat detail item...",
    Desc = "Klik tombol 'Scan Backpack' untuk mendapatkan daftar ikan di inventaris Anda.",
    Icon = "clipboard-list"
})

local function RunBackpackScan()
    local fishData = {}
    local totalCount = 0

    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then
        FishScanDisplay:SetTitle("Scan Gagal: Data Utility/Replion Missing.")
        FishScanDisplay:SetDesc("Pastikan ItemUtility & TierUtility sudah di-require & Replion aktif.")
        return
    end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)

    if not success or not inventoryData or not inventoryData.Items then
        FishScanDisplay:SetTitle("Scan Gagal: Gagal membaca Inventory.")
        return
    end

    
    for _, item in ipairs(inventoryData.Items) do
        if item.Metadata and item.Metadata.Weight then
            local name, rarity = GetFishNameAndRarity(item)
            
            local mutation = GetItemMutationString(item)
            local count = item.Count or 1
            local favoriteStatus = (item.IsFavorite or item.Favorited) and "⭐" or " "
            
            local key = name .. rarity .. mutation
            
            if not fishData[key] then
                fishData[key] = { Count = 0, Rarity = rarity, Mutation = mutation, Favorite = favoriteStatus, Name = name }
            end

            fishData[key].Count = fishData[key].Count + count
            totalCount = totalCount + count
        end
    end

    
    local details = {"\n**--- FISH DETAILS (" .. totalCount .. " items) ---**"}
    
    local sortedFish = {}
    for _, data in pairs(fishData) do table.insert(sortedFish, data) end
    
    local rarityOrder = { ["COMMON"] = 1, ["UNCOMMON"] = 2, ["RARE"] = 3, ["EPIC"] = 4, ["LEGENDARY"] = 5, ["MYTHIC"] = 6, ["SECRET"] = 7, ["TROPHY"] = 8, ["COLLECTIBLE"] = 9, ["DEV"] = 10 }
    table.sort(sortedFish, function(a, b)
        local orderA = rarityOrder[a.Rarity:upper()] or 0
        local orderB = rarityOrder[b.Rarity:upper()] or 0
        return orderA > orderB
    end)
    
    for _, item in ipairs(sortedFish) do
        local mutationString = item.Mutation ~= "" and string.format(" [%s]", item.Mutation) or ""
        
        table.insert(details, string.format("%s %s%s (%s) x%d",
            item.Favorite, item.Name, mutationString, item.Rarity, item.Count
        ))
    end
    
    FishScanDisplay:SetTitle(string.format("Scan Selesai! Total Ikan: %d", totalCount))
    FishScanDisplay:SetDesc(table.concat(details, "\n"))
    
    WindUI:Notify({ Title = "Backpack Scanned!", Content = "Lihat detail di UI.", Duration = 3, Icon = "package" })
end

local scanow = backpack:Button({ Title = "Scan Backpack Now", Icon = "search", Callback = RunBackpackScan })

utility:Divider()

local misc = utility:Section({ Title = "Misc. Area", TextSize = 20})
local RF_UpdateFishingRadar = GetRemote(RPath, "RF/UpdateFishingRadar")
local tfishradar = misc:Toggle({
    Title = "Enable Fishing Radar",
    Desc = "ON/OFF Fishing Radar",
    Value = false,
    Icon = "compass",
    Callback = function(state)
        if not RF_UpdateFishingRadar then
            WindUI:Notify({ Title = "Error", Content = "Remote 'RF/UpdateFishingRadar' tidak ditemukan.", Duration = 3, Icon = "x" })
            return false
        end

        pcall(function()
            RF_UpdateFishingRadar:InvokeServer(state)
        end)

        if state then
            WindUI:Notify({ Title = "Fishing Radar ON", Content = "Fishing Radar diaktifkan.", Duration = 3, Icon = "check" })
        else
            WindUI:Notify({ Title = "Fishing Radar OFF", Content = "Fishing Radar dinonaktifkan.", Duration = 3, Icon = "x" })
        end
    end
})


local RF_EquipOxygenTank = GetRemote(RPath, "RF/EquipOxygenTank")
local RF_UnequipOxygenTank = GetRemote(RPath, "RF/UnequipOxygenTank")
local ttank = Reg("infox", misc:Toggle({
    Title = "Equip Oxigen Tank",
    Desc = "infinite oxygen",
    Value = false,
    Icon = "life-buoy",
    Callback = function(state)
        if state then
            if not RF_EquipOxygenTank then
                WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                return false
            end
            
            pcall(function()
                RF_EquipOxygenTank:InvokeServer(105) 
            end)
            WindUI:Notify({ Title = "Oxygen Tank Equipped", Duration = 3, Icon = "check" })
        else
            if not RF_UnequipOxygenTank then
                WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                return true 
            end
            
            pcall(function()
                RF_UnequipOxygenTank:InvokeServer()
            end)
            WindUI:Notify({ Title = "Oxygen Tank Unequipped", Content = "Oxygen Tank dilepas.", Duration = 3, Icon = "x" })
        end
    end
}))

local REObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")
local RunService = game:GetService("RunService")
local notif = Reg("togglenot",misc:Toggle({
    Title = "Remove Fish Notification Pop-up",
    Value = false,
    Icon = "slash",
    Callback = function(state)
        local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
        local SmallNotification = PlayerGui:FindFirstChild("Small Notification")
        
        if not SmallNotification then
            SmallNotification = PlayerGui:WaitForChild("Small Notification", 5)
            if not SmallNotification then
                WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                return false
            end
        end

        if state then
            
            DisableNotificationConnection = RunService.RenderStepped:Connect(function()
                
                SmallNotification.Enabled = false
            end)
            
            WindUI:Notify({ Title = "Pop-up Diblokir",Duration = 3, Icon = "check" })
        else
            
            if DisableNotificationConnection then
                DisableNotificationConnection:Disconnect()
                DisableNotificationConnection = nil
            end

            
            SmallNotification.Enabled = true
            
            WindUI:Notify({ Title = "Pop-up Diaktifkan", Content = "Notifikasi kembali normal.", Duration = 3, Icon = "x" })
        end
    end
}))


local isNoAnimationActive = false
local originalAnimator = nil
local originalAnimateScript = nil

local function DisableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not humanoid then return end

    local animateScript = character:FindFirstChild("Animate")
    if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
        originalAnimateScript = animateScript.Enabled
        animateScript.Enabled = false
    end

    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        
        originalAnimator = animator 
        animator:Destroy()
    end
end

local function EnableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and originalAnimateScript ~= nil then
        animateScript.Enabled = originalAnimateScript
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    
    local existingAnimator = humanoid:FindFirstChildOfClass("Animator")
    if not existingAnimator then
        
        if originalAnimator and not originalAnimator.Parent then
            originalAnimator.Parent = humanoid
        else
            
            Instance.new("Animator").Parent = humanoid
        end
    end
    originalAnimator = nil 
end

local function OnCharacterAdded(newCharacter)
    if isNoAnimationActive then
        task.wait(0.2) 
        DisableAnimations()
    end
end


LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

local anim = Reg("Toggleanim",misc:Toggle({
    Title = "No Animation",
    Value = false,
    Icon = "skull",
    Callback = function(state)
        isNoAnimationActive = state
        if state then
            DisableAnimations()
            WindUI:Notify({ Title = "No Animation ON!", Duration = 3, Icon = "zap" })
        else
            EnableAnimations()
            WindUI:Notify({ Title = "No Animation OFF!", Duration = 3, Icon = "x" })
        end
    end
}))

local VFXControllerModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").VFXController)
local originalVFXHandle = VFXControllerModule.Handle
local originalPlayVFX = VFXControllerModule.PlayVFX.Fire 
local isVFXDisabled = false
local tskin = Reg("toggleskin",misc:Toggle({
    Title = "Remove Skin Effect",
    Value = false,
    Icon = "slash",
    Callback = function(state)
        isVFXDisabled = state

        if state then
            
            VFXControllerModule.Handle = function(...) 
                
            end

            
            VFXControllerModule.RenderAtPoint = function(...) end
            VFXControllerModule.RenderInstance = function(...) end
            
            
            local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
            if cosmeticFolder then
                pcall(function() cosmeticFolder:ClearAllChildren() end)
            end

            WindUI:Notify({ Title = "No Skin Effect ON", Duration = 3, Icon = "eye-off" })
        else
            
            VFXControllerModule.Handle = originalVFXHandle
        end
    end
}))

local CutsceneController = nil
    local OldPlayCutscene = nil
    local isNoCutsceneActive = false
    pcall(function()
        CutsceneController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("CutsceneController"))
        if CutsceneController and CutsceneController.Play then
            OldPlayCutscene = CutsceneController.Play
            
            
            CutsceneController.Play = function(self, ...)
                if isNoCutsceneActive then
                    
                    return 
                end
                
                return OldPlayCutscene(self, ...)
            end
        end
    end)

    local tcutscen = Reg("tnocut",misc:Toggle({
        Title = "No Cutscene",
        Value = false,
        Icon = "film", 
        Callback = function(state)
            isNoCutsceneActive = state
            
            if not CutsceneController then
                WindUI:Notify({ Title = "Gagal Hook", Content = "Module CutsceneController tidak ditemukan.", Duration = 3, Icon = "x" })
                return
            end

            if state then
                WindUI:Notify({ Title = "No Cutscene ON", Content = "Animasi tangkapan dimatikan.", Duration = 3, Icon = "video-off" })
            else
                WindUI:Notify({ Title = "No Cutscene OFF", Content = "Animasi kembali normal.", Duration = 3, Icon = "video" })
            end
        end
    }))

    local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance or 128
    local zoomLoopConnection = nil
    local tzoom = Reg("infzoom",misc:Toggle({
        Title = "Infinite Zoom Out",
        Value = false,
        Icon = "maximize",
        Callback = function(state)
            if state then
                
                defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
                
                
                LocalPlayer.CameraMaxZoomDistance = 100000
                
                
                
                if zoomLoopConnection then zoomLoopConnection:Disconnect() end
                zoomLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    LocalPlayer.CameraMaxZoomDistance = 100000
                end)
                
                WindUI:Notify({ Title = "Zoom Unlocked", Content = "Sekarang bisa zoom out sejauh mungkin.", Duration = 3, Icon = "maximize" })
            else
                
                if zoomLoopConnection then 
                    zoomLoopConnection:Disconnect() 
                    zoomLoopConnection = nil
                end
                
                
                LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
                
                WindUI:Notify({ Title = "Zoom Normal", Content = "Limit zoom dikembalikan.", Duration = 3, Icon = "minimize" })
            end
        end
    }))

    local t3d = Reg("t3drend",misc:Toggle({
        Title = "Disable 3D Rendering",
        Value = false,
        Callback = function(state)
            local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            local Camera = workspace.CurrentCamera
            local LocalPlayer = game.Players.LocalPlayer
            
            if state then
                
                if not _G.BlackScreenGUI then
                    _G.BlackScreenGUI = Instance.new("ScreenGui")
                    _G.BlackScreenGUI.Name = "XALSC_BlackBackground"
                    _G.BlackScreenGUI.IgnoreGuiInset = true
                    
                    _G.BlackScreenGUI.DisplayOrder = -999 
                    _G.BlackScreenGUI.Parent = PlayerGui
                    
                    local Frame = Instance.new("Frame")
                    Frame.Size = UDim2.new(1, 0, 1, 0)
                    Frame.BackgroundColor3 = Color3.new(0, 0, 0) 
                    Frame.BorderSizePixel = 0
                    Frame.Parent = _G.BlackScreenGUI
                    
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0.1, 0)
                    Label.Position = UDim2.new(0, 0, 0.1, 0) 
                    Label.BackgroundTransparency = 1
                    Label.Text = "Saver Mode Active"
                    Label.TextColor3 = Color3.fromRGB(60, 60, 60) 
                    Label.TextSize = 16
                    Label.Font = Enum.Font.GothamBold
                    Label.Parent = Frame
                end
                
                _G.BlackScreenGUI.Enabled = true

                
                _G.OldCamType = Camera.CameraType

                
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.new(0, 100000, 0) 
                
                WindUI:Notify({
                    Title = "Saver Mode ON",
                    Duration = 3,
                    Icon = "battery-charging",
                })
            else
                
                if _G.OldCamType then
                    Camera.CameraType = _G.OldCamType
                else
                    Camera.CameraType = Enum.CameraType.Custom
                end
                
                
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                end

                
                if _G.BlackScreenGUI then
                    _G.BlackScreenGUI.Enabled = false
                end
                
                WindUI:Notify({
                    Title = "Saver Mode OFF",
                    Content = "Visual kembali normal.",
                    Duration = 3,
                    Icon = "eye",
                })
            end
        end
    }))

local isBoostActive = false
local originalLightingValues = {}
local function ToggleFPSBoost(enabled)
    isBoostActive = enabled
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    if enabled then
        
        if not next(originalLightingValues) then
            originalLightingValues.GlobalShadows = Lighting.GlobalShadows
            originalLightingValues.FogEnd = Lighting.FogEnd
            originalLightingValues.Brightness = Lighting.Brightness
            originalLightingValues.ClockTime = Lighting.ClockTime
            originalLightingValues.Ambient = Lighting.Ambient
            originalLightingValues.OutdoorAmbient = Lighting.OutdoorAmbient
        end
        
        
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                    v.Enabled = false
                elseif v:IsA("Beam") or v:IsA("Light") then
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1 
                end
            end
        end)
        
        
        pcall(function()
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = false end
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0 
            Lighting.ClockTime = 14 
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        end)
        
        
        if Terrain then
            pcall(function()
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
                Terrain.Decoration = false
            end)
        end
        
        
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.TextureQuality = Enum.TextureQuality.Low
        end)

        if type(setfpscap) == "function" then pcall(function() setfpscap(100) end) end 
        if type(collectgarbage) == "function" then collectgarbage("collect") end

        WindUI:Notify({ Title = "FPS Boost", Content = "Maximum FPS mode enabled (Minimal Graphics).", Duration = 3, Icon = "zap" })
    else
        
        pcall(function()
            if originalLightingValues.GlobalShadows ~= nil then
                Lighting.GlobalShadows = originalLightingValues.GlobalShadows
                Lighting.FogEnd = originalLightingValues.FogEnd
                Lighting.Brightness = originalLightingValues.Brightness
                Lighting.ClockTime = originalLightingValues.ClockTime
                Lighting.Ambient = originalLightingValues.Ambient
                Lighting.OutdoorAmbient = originalLightingValues.OutdoorAmbient
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = true end
            end
        end)
        
        if type(setfpscap) == "function" then pcall(function() setfpscap(60) end) end
        
        WindUI:Notify({ Title = "FPS Boost", Content = "Graphics reset to default/automatic. Rejoin recommended.", Duration = 3, Icon = "rotate-ccw" })
    end
end

    local tfps = Reg("togfps",misc:Toggle({
        Title = "FPS Ultra Boost",
        Value = false,
        Callback = function(state)
            ToggleFPSBoost(state)
        end
    }))

utility:Divider()

    local serverm = utility:Section({ Title = "Server Management", TextSize = 20})
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local brejoin = serverm:Button({
        Title = "Rejoin Server",
        Desc = "Masuk ulang ke server ini (Refresh game).",
        Icon = "rotate-cw",
        Callback = function()
            WindUI:Notify({ Title = "Rejoining...", Content = "Tunggu sebentar...", Duration = 3, Icon = "loader" })
            
            
            if syn and syn.queue_on_teleport then
                syn.queue_on_teleport('loadstring(game:HttpGet("URL_SCRIPT_KAMU_DISINI"))()')
            elseif queue_on_teleport then
                queue_on_teleport('loadstring(game:HttpGet("URL_SCRIPT_KAMU_DISINI"))()')
            end

            if #Players:GetPlayers() <= 1 then
                
                Players.LocalPlayer:Kick("\n[XALSC] Rejoining...")
                task.wait()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            else
                
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            end
        end
    })

    
    local bhop = serverm:Button({
        Title = "Server Hop (Random)",
        Desc = "Pindah ke server lain secara acak.",
        Icon = "arrow-right-circle",
        Callback = function()
            WindUI:Notify({ Title = "Hopping...", Content = "Mencari server baru...", Duration = 3, Icon = "search" })
            
            task.spawn(function()
                local PlaceId = game.PlaceId
                local JobId = game.JobId
                
                local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
                local req = game:HttpGet(string.format(sfUrl, PlaceId))
                local body = HttpService:JSONDecode(req)
        
                if body and body.data then
                    local servers = {}
                    for _, v in ipairs(body.data) do
                        
                        if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= JobId then
                            table.insert(servers, v.id)
                        end
                    end
        
                    if #servers > 0 then
                        local randomServerId = servers[math.random(1, #servers)]
                        WindUI:Notify({ Title = "Server Found", Content = "Teleporting...", Duration = 3, Icon = "plane" })
                        TeleportService:TeleportToPlaceInstance(PlaceId, randomServerId, Players.LocalPlayer)
                    else
                        WindUI:Notify({ Title = "Gagal Hop", Content = "Tidak menemukan server lain yang cocok.", Duration = 3, Icon = "x" })
                    end
                else
                    WindUI:Notify({ Title = "API Error", Content = "Gagal mengambil daftar server.", Duration = 3, Icon = "alert-triangle" })
                end
            end)
        end
    })

    
    local hoplow = serverm:Button({
        Title = "Server Hop (Low Player)",
        Desc = "Mencari server yang sepi (cocok buat farming).",
        Icon = "user-minus",
        Callback = function()
            WindUI:Notify({ Title = "Searching Low Server...", Content = "Mencari server sepi...", Duration = 3, Icon = "search" })
            
            task.spawn(function()
                local PlaceId = game.PlaceId
                local JobId = game.JobId
                
                
                local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"
                local req = game:HttpGet(string.format(sfUrl, PlaceId))
                local body = HttpService:JSONDecode(req)
        
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= JobId and v.playing >= 1 then
                            
                            WindUI:Notify({ Title = "Low Server Found!", Content = "Players: " .. tostring(v.playing), Duration = 3, Icon = "check" })
                            TeleportService:TeleportToPlaceInstance(PlaceId, v.id, Players.LocalPlayer)
                            return 
                        end
                    end
                    WindUI:Notify({ Title = "Gagal", Content = "Tidak ada server sepi ditemukan.", Duration = 3, Icon = "x" })
                else
                    WindUI:Notify({ Title = "API Error", Content = "Gagal mengambil daftar server.", Duration = 3, Icon = "alert-triangle" })
                end
            end)
        end
    })

    
    local copyjobid = serverm:Button({
        Title = "Copy Current Job ID",
        Desc = "Salin ID Server ini ke clipboard.",
        Icon = "copy",
        Callback = function()
            local jobId = game.JobId
            setclipboard(jobId)
            WindUI:Notify({ 
                Title = "Copied!", 
                Content = "Job ID disalin ke clipboard.", 
                Duration = 3, 
                Icon = "check" 
            })
        end
    })

    
    local targetJoinID = ""

    
    local injobid = serverm:Input({
        Title = "Target Job ID",
        Desc = "Paste Job ID server tujuan di sini.",
        Value = "",
        Placeholder = "Paste Job ID here...",
        Icon = "keyboard",
        Callback = function(text)
            targetJoinID = text
        end
    })

    
    local joinid = serverm:Button({
        Title = "Join Server by ID",
        Desc = "Teleport ke Job ID yang dimasukkan di atas.",
        Icon = "log-in",
        Callback = function()
            if targetJoinID == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan Job ID dulu di kolom input!", Duration = 3, Icon = "alert-triangle" })
                return
            end

            
            if targetJoinID == game.JobId then
                WindUI:Notify({ Title = "Info", Content = "Kamu sudah berada di server ini!", Duration = 3, Icon = "info" })
                return
            end

            WindUI:Notify({ Title = "Joining...", Content = "Mencoba masuk ke server ID...", Duration = 3, Icon = "plane" })
            
            
            local success, err = pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetJoinID, game.Players.LocalPlayer)
            end)

            if not success then
                WindUI:Notify({ Title = "Gagal", Content = "ID Server Salah / Server Penuh / Expired.", Duration = 5, Icon = "x" })
            end
        end
    })

    utility:Divider()

utility:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open/close ui",
    Value = "F",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})
end

do
    local webhook = Window:Tab({
        Title = "Webhook",
        Icon = "send",
        Locked = false,
    })

    
    local WEBHOOK_URL = ""
    local WEBHOOK_USERNAME = "XALSC Notify" 
    local isWebhookEnabled = false
    local SelectedRarityCategories = {}
    local SelectedWebhookItemNames = {} 
    
    
    local function getWebhookItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
        if itemsContainer then
            for _, itemObject in ipairs(itemsContainer:GetChildren()) do
                local itemName = itemObject.Name
                if type(itemName) == "string" and #itemName >= 3 and itemName:sub(1, 3) ~= "!!!" then
                    table.insert(itemNames, itemName)
                end
            end
        end
        table.sort(itemNames)
        return itemNames
    end
    
    
    local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1438756450972471387/gHuV9K4UmiTjqK3F9KRt720HkGvLJGogwJ9uh17b7QpqMd1ieBC_UdKAX95ozTanWH37"
    local GLOBAL_WEBHOOK_USERNAME = "XALSC | Community"
    local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}

    local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Trophy", "Collectible", "DEV"}
    
    local REObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")
    local HttpService = game:GetService("HttpService")
    local WebhookStatusParagraph 

    
    
    
    local ImageURLCache = {} 

    
    local function FormatNumber(n)
        n = math.floor(n) 
        
        local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
        
        return formatted:gsub("^%.", "")
    end
    
    local function UpdateWebhookStatus(title, content, icon)
        if WebhookStatusParagraph then
            WebhookStatusParagraph:SetTitle(title)
            WebhookStatusParagraph:SetDesc(content)
        end
    end

    
    local function GetRobloxAssetImage(assetId)
        if not assetId or assetId == 0 then return nil end
        
        
        if ImageURLCache[assetId] then
            return ImageURLCache[assetId]
        end
        
        
        local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", assetId)
        local success, response = pcall(game.HttpGet, game, url)
        
        if success then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
            if ok and data and data.data and data.data[1] and data.data[1].imageUrl then
                local finalUrl = data.data[1].imageUrl
                
                
                ImageURLCache[assetId] = finalUrl
                return finalUrl
            end
        end
        return nil
    end

    local function sendExploitWebhook(url, username, embed_data)
        local payload = {
            username = username,
            embeds = {embed_data} 
        }
        
        local json_data = HttpService:JSONEncode(payload)
        
        if typeof(request) == "function" then
            local success, response = pcall(function()
                return request({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = json_data
                })
            end)
            
            if success and (response.StatusCode == 200 or response.StatusCode == 204) then
                 return true, "Sent"
            elseif success and response.StatusCode then
                return false, "Failed: " .. response.StatusCode
            elseif not success then
                return false, "Error: " .. tostring(response)
            end
        end
        return false, "No Request Func"
    end
    
    local function getRarityColor(rarity)
        local r = rarity:upper()
        if r == "SECRET" then return 0xFFD700 end
        if r == "MYTHIC" then return 0x9400D3 end
        if r == "LEGENDARY" then return 0xFF4500 end
        if r == "EPIC" then return 0x8A2BE2 end
        if r == "RARE" then return 0x0000FF end
        if r == "UNCOMMON" then return 0x00FF00 end
        return 0x00BFFF
    end

    local function shouldNotify(fishRarityUpper, fishMetadata, fishName)
        
        if #SelectedRarityCategories > 0 and table.find(SelectedRarityCategories, fishRarityUpper) then
            return true
        end

        
        if #SelectedWebhookItemNames > 0 and table.find(SelectedWebhookItemNames, fishName) then
            return true
        end

        
        if _G.NotifyOnMutation and (fishMetadata.Shiny or fishMetadata.VariantId) then
             return true
        end
        
        return false
    end
    
    
    local function onFishObtained(itemId, metadata, fullData)
        local success, results = pcall(function()
            local dummyItem = {Id = itemId, Metadata = metadata}
            local fishName, fishRarity = GetFishNameAndRarity(dummyItem)
            local fishRarityUpper = fishRarity:upper()

            
            local fishWeight = string.format("%.2fkg", metadata.Weight or 0)
            local mutationString = GetItemMutationString(dummyItem)
            local mutationDisplay = mutationString ~= "" and mutationString or "N/A"
            local itemData = ItemUtility:GetItemData(itemId)
            
            
            local assetId = nil
            if itemData and itemData.Data then
                local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
                if iconRaw then
                    assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
                end
            end

            local imageUrl = assetId and GetRobloxAssetImage(assetId)
            if not imageUrl then
                imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png" 
            end
            
            local basePrice = itemData and itemData.SellPrice or 0
            local sellPrice = basePrice * (metadata.SellMultiplier or 1)
            local formattedSellPrice = string.format("%s$", FormatNumber(sellPrice))
            
            
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local caughtStat = leaderstats and leaderstats:FindFirstChild("Caught")
            local caughtDisplay = caughtStat and FormatNumber(caughtStat.Value) or "N/A"

            
            local currentCoins = 0
            local replion = GetPlayerDataReplion()
            
            if replion then
                
                local success_curr, CurrencyConfig = pcall(function()
                    return require(game:GetService("ReplicatedStorage").Modules.CurrencyUtility.Currency)
                end)

                if success_curr and CurrencyConfig and CurrencyConfig["Coins"] then
                    
                    
                    currentCoins = replion:Get(CurrencyConfig["Coins"].Path) or 0
                else
                    
                    
                    currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
                end
            else
                
                if leaderstats then
                    local coinStat = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("C$")
                    currentCoins = coinStat and coinStat.Value or 0
                end
            end

            local formattedCoins = FormatNumber(currentCoins)
            

            
            
            
            
            local isUserFilterMatch = shouldNotify(fishRarityUpper, metadata, fishName)

            if isWebhookEnabled and WEBHOOK_URL ~= "" and isUserFilterMatch then
                local title_private = string.format("<:TEXTURENOBG:1438662703722790992> XALSC | Webhook\n\n<a:ChipiChapa:1438661193857503304> New Fish Caught! (%s)", fishName)
                
                local embed = {
                    title = title_private,
                    description = string.format("Found by **%s**.", LocalPlayer.DisplayName or LocalPlayer.Name),
                    color = getRarityColor(fishRarityUpper),
                    fields = {
                        { name = "<a:ARROW:1438758883203223605> Fish Name", value = string.format("`%s`", fishName), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                        
                        { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                        { name = "<a:coines:1438758976992051231> Sell Price", value = string.format("`%s`", formattedSellPrice), inline = true },
                        { name = "<a:coines:1438758976992051231> Current Coins", value = string.format("`%s`", formattedCoins), inline = true },
                    },
                    thumbnail = { url = imageUrl },
                    footer = {
                        text = string.format("XALSC Webhook • Total Caught: %s • %s", caughtDisplay, os.date("%Y-%m-%d %H:%M:%S"))
                    }
                }
                local success_send, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, embed)
                
                if success_send then
                    UpdateWebhookStatus("Webhook Aktif", "Terkirim: " .. fishName, "check")
                else
                    UpdateWebhookStatus("Webhook Gagal", "Error: " .. message, "x")
                end
            end

            
            
            
            local isGlobalTarget = table.find(GLOBAL_RARITY_FILTER, fishRarityUpper)

            if isGlobalTarget and GLOBAL_WEBHOOK_URL ~= "" then 
                local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
                local censoredPlayerName = CensorName(playerName)
                
                local title_global = string.format("<:TEXTURENOBG:1438662703722790992> XALSC | Global Tracker\n\n<a:globe:1438758633151266818> GLOBAL CATCH! %s", fishName)

                local globalEmbed = {
                    title = title_global,
                    description = string.format("Pemain **%s** baru saja menangkap ikan **%s**!", censoredPlayerName, fishRarityUpper),
                    color = getRarityColor(fishRarityUpper),
                    fields = {
                        { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                    },
                    thumbnail = { url = imageUrl },
                    footer = {
                        text = string.format("XALSC Community| Player: %s | %s", censoredPlayerName, os.date("%Y-%m-%d %H:%M:%S"))
                    }
                }
                
                sendExploitWebhook(GLOBAL_WEBHOOK_URL, GLOBAL_WEBHOOK_USERNAME, globalEmbed)
            end
            
            return true
        end)
        
        if not success then
            warn("[XALSC Webhook] Error processing fish data:", results)
        end
    end
    
    if REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
            pcall(function() onFishObtained(itemId, metadata, fullData) end)
        end)
    end

    local webhooksec = webhook:Section({
        Title = "Webhook Setup",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })

   local inputweb = Reg("inptweb",webhooksec:Input({
        Title = "Discord Webhook URL",
        Desc = "URL tempat notifikasi akan dikirim.",
        Value = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Icon = "link",
        Type = "Input",
        Callback = function(input)
            WEBHOOK_URL = input
        end
    }))

    webhook:Divider()
    
   local ToggleNotif = Reg("tweb",webhooksec:Toggle({
        Title = "Enable Fish Notifications",
        Desc = "Aktifkan/nonaktifkan pengiriman notifikasi ikan.",
        Value = false,
        Icon = "cloud-upload",
        Callback = function(state)
            isWebhookEnabled = state
            if state then
                if WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord.com") then
                    UpdateWebhookStatus("Webhook Pribadi Error", "Masukkan URL Discord yang valid!", "alert-triangle")
                    return false
                end
                WindUI:Notify({ Title = "Webhook ON!", Duration = 4, Icon = "check" })
                UpdateWebhookStatus("Status: Listening", "Menunggu tangkapan ikan...", "ear")
            else
                WindUI:Notify({ Title = "Webhook OFF!", Duration = 4, Icon = "x" })
                UpdateWebhookStatus("Webhook Status", "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.", "info")
            end
        end
    }))

    local dwebname = Reg("drweb", webhooksec:Dropdown({
        Title = "Filter by Specific Name",
        Desc = "Notifikasi khusus untuk nama ikan tertentu",
        Values = getWebhookItemOptions(),
        Value = SelectedWebhookItemNames,
        Multi = true,
        AllowNone = true,
        Callback = function(names)
            SelectedWebhookItemNames = names or {} 
        end
    }))

    local dwebrar = Reg("rarwebd", webhooksec:Dropdown({
        Title = "Rarity to Notify",
        Desc = "Hanya notifikasi ikan rarity yang dipilih.",
        Values = RarityList, 
        Value = SelectedRarityCategories,
        Multi = true,
        AllowNone = true,
        Callback = function(categories)
            SelectedRarityCategories = {}
            for _, cat in ipairs(categories or {}) do
                table.insert(SelectedRarityCategories, cat:upper()) 
            end
        end
    }))

    WebhookStatusParagraph = webhooksec:Paragraph({
        Title = "Webhook Status",
        Content = "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.",
        Icon = "info",
    })
    

    local teswebbut = webhooksec:Button({
        Title = "Test Webhook ",
        Icon = "send",
        Desc = "Mengirim Webhook Test",
        Callback = function()
            if WEBHOOK_URL == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan URL Webhook terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            local testEmbed = {
                title = "XALSC Webhook Test",
                description = "Success <a:ChipiChapa:1438661193857503304>",
                color = 0x00FF00,
                fields = {
                    { name = "Name Player", value = LocalPlayer.DisplayName or LocalPlayer.Name, inline = true },
                    { name = "Status", value = "Success", inline = true },
                    { name = "Cache System", value = "Active ✅", inline = true }
                },
                footer = {
                    text = "XALSC Webhook Test"
                }
            }
            local success, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
            if success then
                 WindUI:Notify({ Title = "Test Sukses!", Content = "Cek channel Discord Anda. " .. message, Duration = 4, Icon = "check" })
            else
                 WindUI:Notify({ Title = "Test Gagal!", Content = "Cek console (Output) untuk error. " .. message, Duration = 5, Icon = "x" })
            end
        end
    })
end

do
    local SettingsTab = Window:Tab({
        Title = "Configuration",
        Icon = "settings",
        Locked = false,
    })

    local ConfigSection = SettingsTab:Section({
        Title = "Config Manager",
        TextSize = 20,
    })

    
    local ConfigManager = Window.ConfigManager
    local SelectedConfigName = "XALSC" 
    local BaseFolder = "WindUI/" .. (Window.Folder or "XALSC") .. "/config/"

    
    local function RefreshConfigList(dropdown)
        local list = ConfigManager:AllConfigs()
        if #list == 0 then list = {"None"} end
        pcall(function() dropdown:Refresh(list) end)
    end

    local ConfigNameInput = ConfigSection:Input({
        Title = "Config Name",
        Desc = "Nama config baru/yang akan disimpan.",
        Value = "XALSC",
        Placeholder = "e.g. LegitFarming",
        Icon = "file-pen",
        Callback = function(text)
            SelectedConfigName = text
        end
    })

    local ConfigDropdown = ConfigSection:Dropdown({
        Title = "Available Configs",
        Desc = "Pilih file config yang ada.",
        Values = ConfigManager:AllConfigs() or {"None"},
        Value = "XALSC",
        AllowNone = true,
        Callback = function(val)
            if val and val ~= "None" then
                SelectedConfigName = val
                ConfigNameInput:Set(val)
            end
        end
    })

    ConfigSection:Button({
        Title = "Refresh List",
        Icon = "refresh-ccw",
        Callback = function() RefreshConfigList(ConfigDropdown) end
    })

    ConfigSection:Divider()

    
    ConfigSection:Button({
        Title = "Save Config",
        Desc = "Simpan settingan saat ini.",
        Icon = "save",
        Color = Color3.fromRGB(0, 255, 127),
        Callback = function()
            if SelectedConfigName == "" then return end
            
            
            XALSCConfig:Save()
            task.wait(0.1)

            
            if SelectedConfigName ~= "XALSC" then
                local success, err = pcall(function()
                    local mainContent = readfile(BaseFolder .. "XALSC.json")
                    writefile(BaseFolder .. SelectedConfigName .. ".json", mainContent)
                end)
                
                if not success then
                    WindUI:Notify({ Title = "Error Write", Content = "Gagal menyalin file.", Duration = 3, Icon = "x" })
                    return
                end
            end

            WindUI:Notify({ Title = "Saved!", Content = "Config: " .. SelectedConfigName, Duration = 2, Icon = "check" })
            RefreshConfigList(ConfigDropdown)
        end
    })

    
    ConfigSection:Button({
        Title = "Load Config",
        Icon = "download",
        Callback = function()
            if SelectedConfigName == "" then return end
            
            
            SmartLoadConfig(SelectedConfigName)
        end
    })

    
    ConfigSection:Button({
        Title = "Delete Config",
        Icon = "trash-2",
        Color = Color3.fromRGB(255, 80, 80),
        Callback = function()
            if SelectedConfigName == "" or SelectedConfigName == "XALSC" then 
                WindUI:Notify({ Title = "Gagal", Content = "Tidak bisa hapus config default/kosong.", Duration = 3 })
                return 
            end
            
            local path = BaseFolder .. SelectedConfigName .. ".json"
            
            if isfile(path) then
                delfile(path)
                WindUI:Notify({ Title = "Deleted", Content = SelectedConfigName .. " dihapus.", Duration = 2, Icon = "trash" })
                RefreshConfigList(ConfigDropdown)
                ConfigNameInput:Set("XALSC")
                SelectedConfigName = "XALSC"
            else
                WindUI:Notify({ Title = "Error", Content = "File tidak ditemukan.", Duration = 3, Icon = "x" })
            end
        end
    })
    
end

do
    local about = Window:Tab({
        Title = "About",
        Icon = "info",
        Locked = false,
    })

    about:Section({
        Title = "Join Discord Server XALSC",
        TextSize = 20,
    })

    about:Paragraph({
        Title = "XALSC Community",
        Desc = "Join Our Community Discord Server to get the latest updates, support, and connect with other users!",
        Image = "rbxassetid://122210708834535",
        ImageSize = 24,
        Buttons = {
            {
                Title = "Copy Link",
                Icon = "link",
                Callback = function()
                    setclipboard("https://dsc.gg/XALSC")
                    WindUI:Notify({
                        Title = "Link Disalin!",
                        Content = "Link Discord XALSC berhasil disalin.",
                        Duration = 3,
                        Icon = "copy",
                    })
                end,
            }
        }
    })

    about:Divider()
    
    about:Section({
        Title = "What's New?",
        TextSize = 24,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    about:Image({
        Image = "rbxassetid://122210708834535",
        AspectRatio = "16:9",
        Radius = 9,
    })

    about:Space()

    about:Paragraph({
        Title = "Version 1.0.0",
        Desc = "- 28 Nov 2025 Release Premium Version",
    })
    about:Paragraph({
        Title = "Version 1.0.1",
        Desc = "[~] Fix stuck at farming artifact\n[~] Fix auto sell issue\n[~] Fix Legit Fishing Stuck Issue\n[~] Fix & change method kaitun mode\n[+] Add missing mutation\n[+] add auto trade by coin\n[+] Add filter by name at webhook\n",
    })
    about:Paragraph({
        Title = "Version 1.0.2",
        Desc = "[~] Fix 3D Rendering Force Close Issue\n[~] Fix Teleport & Freeze Detect Old Position\n[~] Improve Load UI\n[+] Add Freeze Player\n[+] Add Detect Enchant Perfection On Blatant Mode\n[+] Add Auto Spawn 9 Totem\n[+] Bring Back 3 Setting On Blatant Mode",
    })
end

Window:Tag({
    Title = "V 1.0.2",
    Color = Color3.fromHex("#F5C527"),
    Radius = 9,
})

Window:EditOpenButton({
    Title = "XALSC - Fish It",
    Icon = "rbxassetid://116236936447443",
    CornerRadius = UDim.new(0,30),
    StrokeThickness = 1.5,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})




local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")


local uisConnection = nil


local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function CreateFloatingIcon()
    local existingGui = PlayerGui:FindFirstChild("CustomFloatingIcon_XALSC")
    if existingGui then existingGui:Destroy() end

    local FloatingIconGui = Instance.new("ScreenGui")
    FloatingIconGui.Name = "CustomFloatingIcon_XALSC"
    FloatingIconGui.DisplayOrder = 999
    FloatingIconGui.ResetOnSpawn = false 

    local FloatingFrame = Instance.new("Frame")
    FloatingFrame.Name = "FloatingFrame"
    
    FloatingFrame.Position = UDim2.new(0, 50, 0.4, 0) 
    FloatingFrame.Size = UDim2.fromOffset(45, 45) 
    FloatingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    FloatingFrame.BackgroundTransparency = 0 
    FloatingFrame.BorderSizePixel = 0
    FloatingFrame.Parent = FloatingIconGui

    
    local FrameStroke = Instance.new("UIStroke")
    FrameStroke.Color = Color3.fromHex("FF0F7B")
    FrameStroke.Thickness = 2
    FrameStroke.Transparency = 0
    FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FrameStroke.Parent = FloatingFrame

    
    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 12) 
    FrameCorner.Parent = FloatingFrame

    
    local IconImage = Instance.new("ImageLabel")
    IconImage.Name = "Icon"
    IconImage.Image = "rbxassetid://122210708834535"
    IconImage.BackgroundTransparency = 1
    IconImage.Size = UDim2.new(1, -4, 1, -4) 
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Parent = FloatingFrame

    
    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(0, 10)
    ImageCorner.Parent = IconImage
    
    FloatingIconGui.Parent = PlayerGui
    return FloatingIconGui, FloatingFrame
end

local function SetupFloatingIcon(FloatingIconGui, FloatingFrame)
    
    if uisConnection then 
        uisConnection:Disconnect() 
        uisConnection = nil
    end

    local function update(input)
        local delta = input.Position - dragStart
        FloatingFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    
    FloatingFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatingFrame.Position
            
            local didMove = false

            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                    
                    
                    if not didMove then
                        if Window and Window.Toggle then
                            Window:Toggle()
                        end
                    end
                end
            end)
            
            
            local moveConnection
            moveConnection = input.Changed:Connect(function()
                 if dragging and (input.Position - dragStart).Magnitude > 5 then
                     didMove = true
                     moveConnection:Disconnect()
                 end
            end)
        end
    end)

    
    FloatingFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    
    uisConnection = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    
    if Window then
        Window:OnOpen(function()
            FloatingIconGui.Enabled = false
        end)
        Window:OnClose(function()
            FloatingIconGui.Enabled = true
        end)
    end
end

local function InitializeIcon()
    
    if not game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.CharacterAdded:Wait()
    end
    
    local gui, frame = CreateFloatingIcon()
    if gui and frame then
        SetupFloatingIcon(gui, frame)
    end
end


game.Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) 
    InitializeIcon()
end)

WindUI:Notify({ Title = "XALSC Was Loaded", Content = "Press [F] to open/close the menu", Duration = 5, Icon = "info" })

task.spawn(function()
    task.wait(2) 
    
    
    
    SmartLoadConfig("XALSC") 
    
    
    while true do
         task.wait(10)
         pcall(function() XALSCConfig:Save() end)
    end
end)
InitializeIcon()

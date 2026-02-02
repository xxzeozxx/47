--[[
    XAL HUB - Fish It
    Custom UI Version (Replaces OrionLib)
]]

-- // CORE SERVICES //
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local InitHttp = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- // GAME SPECIFICS //
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = Packages._Index["sleitnick_net@0.2.0"].net
local FishingController = require(ReplicatedStorage.Controllers.FishingController)
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local Events = {
    REEquip = Net["RE/EquipToolFromHotbar"],
    REFishDone = Net["RE/FishingCompleted"],
    REPlayFishEffect = Net["RE/PlayFishingEffect"],
    RETextEffect = Net["RE/ReplicateTextEffect"],
    REObtainedNewFishNotification = Net["RE/ObtainedNewFishNotification"],
    Totem = Net["RE/SpawnTotem"],
    UpdateOxygen = Net["URE/UpdateOxygen"]
}

local Functions = {
    BuyWeather = Net["RF/PurchaseWeatherEvent"],
    UpdateRadar = Net["RF/UpdateFishingRadar"],
    SellAll = Net["RF/SellAllItems"]
}

local State = {
    autoShake = false,
    autoSell = false,
    sellDelay = 60,
    walkOnWater = false,
    frozen = false,
    autoBuyWeather = false,
    selectedEvents = {},
    totemActive = false,
    disableNotifs = false,
    deleteEffects = false,
    detectorStuck = false,
    stuckThreshold = 15,
    fishingTimer = 0,
    lastBagCount = 0,
    waterConnection = nil,
    webhookEnabled = false,
    webhookURL = "",
    webhookRarities = {},
    fishDatabase = {}
}

-- // UI LIBRARY //
local Library = {}
local UISetting = {
    MainColor = Color3.fromRGB(35, 35, 45),
    AccentColor = Color3.fromRGB(0, 120, 215),
    TextColor = Color3.fromRGB(240, 240, 240),
    ItemColor = Color3.fromRGB(45, 45, 55),
    Font = Enum.Font.GothamBold -- Using a standard font that looks good
}

function Library:Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

function Library:CreateWindow(Config)
    local Name = Config.Name or "XAL HUB"
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XALHub_UI"
    -- Attempt to parent to CoreGui for security, fallback to PlayerGui
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
    MainFrame.BackgroundColor3 = UISetting.MainColor
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    -- Corner
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = MainFrame

    -- Dragging
    local DragInput, DragStart, StartPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            DragStart = input.Position
            StartPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    DragStart = nil
                end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and DragStart then
            local Delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 6)
    HeaderCorner.Parent = Header
    
    -- Fix Bottom Corners of Header
    local HeaderCover = Instance.new("Frame")
    HeaderCover.Size = UDim2.new(1, 0, 0, 10)
    HeaderCover.Position = UDim2.new(0,0,1,-10)
    HeaderCover.BorderSizePixel = 0
    HeaderCover.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    HeaderCover.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Text = Name
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = UISetting.TextColor
    Title.Font = UISetting.Font
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    -- Restore Button (The Floating Icon)
    local RestoreBtn = Instance.new("TextButton")
    RestoreBtn.Name = "RestoreBtn"
    RestoreBtn.Size = UDim2.new(0, 40, 0, 40)
    RestoreBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
    RestoreBtn.BackgroundColor3 = UISetting.MainColor
    RestoreBtn.Text = "XAL"
    RestoreBtn.TextColor3 = UISetting.AccentColor
    RestoreBtn.Font = UISetting.Font
    RestoreBtn.TextSize = 12
    RestoreBtn.Visible = false
    RestoreBtn.Parent = ScreenGui
    
    local RestoreCorner = Instance.new("UICorner")
    RestoreCorner.CornerRadius = UDim.new(0, 8) 
    RestoreCorner.Parent = RestoreBtn
    
    local RestoreStroke = Instance.new("UIStroke")
    RestoreStroke.Color = UISetting.AccentColor
    RestoreStroke.Thickness = 2
    RestoreStroke.Parent = RestoreBtn

    -- Make Restore Button Draggable
    local RDragInput, RDragStart, RStartPos
    RestoreBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            RDragStart = input.Position
            RStartPos = RestoreBtn.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    RDragStart = nil
                end
            end)
        end
    end)
    RestoreBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and RDragStart then
            local Delta = input.Position - RDragStart
            RestoreBtn.Position = UDim2.new(RStartPos.X.Scale, RStartPos.X.Offset + Delta.X, RStartPos.Y.Scale, RStartPos.Y.Offset + Delta.Y)
        end
    end)

    RestoreBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        RestoreBtn.Visible = false
    end)

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "-"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -60, 0, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.TextColor3 = UISetting.TextColor
    MinBtn.Font = UISetting.Font
    MinBtn.TextSize = 20
    MinBtn.Parent = Header
    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        RestoreBtn.Visible = true
    end)

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "X"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -30, 0, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Font = UISetting.Font
    CloseBtn.TextSize = 14
    CloseBtn.Parent = Header
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Tab Container
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(0, 120, 1, -40)
    TabContainer.Position = UDim2.new(0, 10, 0, 35)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabContainer

    -- Page Container
    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -145, 1, -40)
    PageContainer.Position = UDim2.new(0, 135, 0, 35)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    local WindowObj = {}
    local FirstTab = true

    function WindowObj:MakeTab(TabConfig)
        local TabName = TabConfig.Name
        
        -- Tab Button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = TabName
        TabBtn.Text = TabName
        TabBtn.Size = UDim2.new(1, 0, 0, 30)
        TabBtn.BackgroundColor3 = UISetting.ItemColor
        TabBtn.TextColor3 = UISetting.TextColor
        TabBtn.Font = UISetting.Font
        TabBtn.TextSize = 13
        TabBtn.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabBtn

        -- Page
        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabName .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.Visible = false
        Page.Parent = PageContainer
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 5)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page
        
        -- Auto Resize
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- Tab Selection Logic
        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(PageContainer:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            Page.Visible = true
            
            -- Visual Update
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    Library:Tween(v, {BackgroundColor3 = UISetting.ItemColor})
                end
            end
            Library:Tween(TabBtn, {BackgroundColor3 = UISetting.AccentColor})
        end)

        if FirstTab then
            Page.Visible = true
            TabBtn.BackgroundColor3 = UISetting.AccentColor
            FirstTab = false
        end

        local TabObj = {}

        function TabObj:AddSection(SectionConfig)
            local SectionName = SectionConfig.Name
            
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, -6, 0, 25)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.Parent = Page
            
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Text = SectionName
            SectionLabel.Size = UDim2.new(1, 0, 1, 0)
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            SectionLabel.Font = UISetting.Font
            SectionLabel.TextSize = 12
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.Parent = SectionFrame
        end

        function TabObj:AddLabel(Text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, -6, 0, 25)
            LabelFrame.BackgroundColor3 = UISetting.ItemColor
            LabelFrame.Parent = Page
            
            local LabelCorner = Instance.new("UICorner")
            LabelCorner.CornerRadius = UDim.new(0, 4)
            LabelCorner.Parent = LabelFrame
            
            local TextLabel = Instance.new("TextLabel")
            TextLabel.Text = Text
            TextLabel.Size = UDim2.new(1, -10, 1, 0)
            TextLabel.Position = UDim2.new(0, 10, 0, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextColor3 = UISetting.TextColor
            TextLabel.Font = UISetting.Font
            TextLabel.TextSize = 13
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Parent = LabelFrame
            
            local LabelObj = {}
            function LabelObj:Set(NewText)
                TextLabel.Text = NewText
            end
            return LabelObj
        end
        
        function TabObj:AddParagraph(Title, Content)
             -- Simple implementation reusing Label for now
             TabObj:AddLabel(Title .. ": " .. Content)
        end

        function TabObj:AddButton(ButtonConfig)
            local ButtonName = ButtonConfig.Name
            local Callback = ButtonConfig.Callback or function() end
            
            local Button = Instance.new("TextButton")
            Button.Text = ButtonName
            Button.Size = UDim2.new(1, -6, 0, 30)
            Button.BackgroundColor3 = UISetting.ItemColor
            Button.TextColor3 = UISetting.TextColor
            Button.Font = UISetting.Font
            Button.TextSize = 13
            Button.Parent = Page
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 4)
            ButtonCorner.Parent = Button
            
            Button.MouseButton1Click:Connect(function()
                Library:Tween(Button, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.1)
                task.wait(0.1)
                Library:Tween(Button, {BackgroundColor3 = UISetting.ItemColor}, 0.1)
                Callback()
            end)
        end

        function TabObj:AddToggle(ToggleConfig)
            local ToggleName = ToggleConfig.Name
            local Default = ToggleConfig.Default or false
            local Callback = ToggleConfig.Callback or function() end
            
            local Toggled = Default
            
            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Text = ""
            ToggleFrame.Size = UDim2.new(1, -6, 0, 30)
            ToggleFrame.BackgroundColor3 = UISetting.ItemColor
            ToggleFrame.Parent = Page
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 4)
            ToggleCorner.Parent = ToggleFrame
            
            local NameLabel = Instance.new("TextLabel")
            NameLabel.Text = ToggleName
            NameLabel.Size = UDim2.new(0.8, 0, 1, 0)
            NameLabel.Position = UDim2.new(0, 10, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.TextColor3 = UISetting.TextColor
            NameLabel.Font = UISetting.Font
            NameLabel.TextSize = 13
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = ToggleFrame
            
            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 20, 0, 20)
            Indicator.Position = UDim2.new(1, -30, 0.5, -10)
            Indicator.BackgroundColor3 = Toggled and UISetting.AccentColor or Color3.fromRGB(60, 60, 60)
            Indicator.Parent = ToggleFrame
            
            local IndCorner = Instance.new("UICorner")
            IndCorner.CornerRadius = UDim.new(0, 4)
            IndCorner.Parent = Indicator
            
            ToggleFrame.MouseButton1Click:Connect(function()
                Toggled = not Toggled
                Library:Tween(Indicator, {BackgroundColor3 = Toggled and UISetting.AccentColor or Color3.fromRGB(60, 60, 60)}, 0.2)
                Callback(Toggled)
            end)
            
            -- Initialize
            if Default then Callback(true) end
        end

        function TabObj:AddSlider(SliderConfig)
            local SliderName = SliderConfig.Name
            local Min = SliderConfig.Min or 0
            local Max = SliderConfig.Max or 100
            local Default = SliderConfig.Default or Min
            local Callback = SliderConfig.Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, -6, 0, 45)
            SliderFrame.BackgroundColor3 = UISetting.ItemColor
            SliderFrame.Parent = Page
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 4)
            SliderCorner.Parent = SliderFrame
            
            local NameLabel = Instance.new("TextLabel")
            NameLabel.Text = SliderName
            NameLabel.Size = UDim2.new(1, -20, 0, 20)
            NameLabel.Position = UDim2.new(0, 10, 0, 5)
            NameLabel.BackgroundTransparency = 1
            NameLabel.TextColor3 = UISetting.TextColor
            NameLabel.Font = UISetting.Font
            NameLabel.TextSize = 13
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = SliderFrame
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(Default)
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -60, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.TextColor3 = UISetting.TextColor
            ValueLabel.Font = UISetting.Font
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame
            
            local BarBG = Instance.new("Frame")
            BarBG.Size = UDim2.new(1, -20, 0, 6)
            BarBG.Position = UDim2.new(0, 10, 0, 30)
            BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            BarBG.Parent = SliderFrame
            
            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 3)
            BarCorner.Parent = BarBG
            
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
            Fill.BackgroundColor3 = UISetting.AccentColor
            Fill.Parent = BarBG
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 3)
            FillCorner.Parent = Fill
            
            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Parent = BarBG
            
            local function Update(Input)
                local SizeX = math.clamp((Input.Position.X - BarBG.AbsolutePosition.X) / BarBG.AbsoluteSize.X, 0, 1)
                Fill.Size = UDim2.new(SizeX, 0, 1, 0)
                local Value = math.floor(Min + ((Max - Min) * SizeX))
                ValueLabel.Text = tostring(Value)
                Callback(Value)
            end
            
            local Dragging = false
            Trigger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = true
                    Update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
        end

        function TabObj:AddDropdown(DropdownConfig)
            local DropdownName = DropdownConfig.Name
            local Options = DropdownConfig.Options or {}
            local Default = DropdownConfig.Default or ""
            local Multi = DropdownConfig.Multi or false
            local Callback = DropdownConfig.Callback or function() end
            
            local DropdownOpen = false
            local SelectedItems = {}
            if Multi and type(Default) == "table" then
                for _, v in pairs(Default) do table.insert(SelectedItems, v) end
            end
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, -6, 0, 30)
            DropdownFrame.BackgroundColor3 = UISetting.ItemColor
            DropdownFrame.Parent = Page
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 4)
            DropdownCorner.Parent = DropdownFrame
            
            local NameLabel = Instance.new("TextLabel")
            NameLabel.Text = DropdownName .. (Multi and " (Multi)" or "")
            NameLabel.Size = UDim2.new(0.6, 0, 1, 0)
            NameLabel.Position = UDim2.new(0, 10, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.TextColor3 = UISetting.TextColor
            NameLabel.Font = UISetting.Font
            NameLabel.TextSize = 13
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = DropdownFrame
            
            local SelectedLabel = Instance.new("TextLabel")
            SelectedLabel.Text = Multi and "..." or Default
            SelectedLabel.Size = UDim2.new(0.4, -35, 1, 0)
            SelectedLabel.Position = UDim2.new(0.6, 0, 0, 0)
            SelectedLabel.BackgroundTransparency = 1
            SelectedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            SelectedLabel.Font = UISetting.Font
            SelectedLabel.TextSize = 12
            SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
            SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedLabel.Parent = DropdownFrame
            
            local Arrow = Instance.new("TextLabel")
            Arrow.Text = "+"
            Arrow.Size = UDim2.new(0, 30, 1, 0)
            Arrow.Position = UDim2.new(1, -30, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.TextColor3 = UISetting.TextColor
            Arrow.Font = UISetting.Font
            Arrow.TextSize = 18
            Arrow.Parent = DropdownFrame
            
            -- Interaction
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 1, 0)
            Button.BackgroundTransparency = 1
            Button.Text = ""
            Button.Parent = DropdownFrame
            
            -- Options Container
            local OptionsFrame = Instance.new("Frame")
            OptionsFrame.Size = UDim2.new(1, -6, 0, 0)
            OptionsFrame.Visible = false
            OptionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            OptionsFrame.Parent = Page
            
            local OptList = Instance.new("UIListLayout")
            OptList.Padding = UDim.new(0, 2)
            OptList.Parent = OptionsFrame
            
            local function RefreshOptions()
                -- Clear old
                for _, v in pairs(OptionsFrame:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                
                -- Resize
                OptionsFrame.Size = UDim2.new(1, -6, 0, math.min(#Options * 25, 150)) -- Max height 150
                
                for _, opt in pairs(Options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Text = opt
                    OptBtn.Size = UDim2.new(1, 0, 0, 25)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    OptBtn.TextColor3 = UISetting.TextColor
                    OptBtn.Font = UISetting.Font
                    OptBtn.TextSize = 12
                    OptBtn.Parent = OptionsFrame
                    
                    if Multi then
                         if table.find(SelectedItems, opt) then
                             OptBtn.TextColor3 = UISetting.AccentColor
                         end
                    end
                    
                    OptBtn.MouseButton1Click:Connect(function()
                        if Multi then
                             -- Toggle Logic for Multi
                             local idx = table.find(SelectedItems, opt)
                             if idx then
                                 table.remove(SelectedItems, idx)
                                 OptBtn.TextColor3 = UISetting.TextColor
                             else
                                 table.insert(SelectedItems, opt)
                                 OptBtn.TextColor3 = UISetting.AccentColor
                             end
                             Callback(SelectedItems)
                        else
                             -- Single Select
                             SelectedLabel.Text = opt
                             DropdownOpen = false
                             OptionsFrame.Visible = false
                             Arrow.Text = "+"
                             Callback(opt)
                        end
                    end)
                end
            end
            
            Button.MouseButton1Click:Connect(function()
                DropdownOpen = not DropdownOpen
                OptionsFrame.Visible = DropdownOpen
                Arrow.Text = DropdownOpen and "-" or "+"
                if DropdownOpen then
                    RefreshOptions()
                end
            end)
        end
        
        function TabObj:AddInput(InputConfig)
             local InputName = InputConfig.Name
             local Placeholder = InputConfig.Placeholder or "Input..."
             local Default = InputConfig.Default or ""
             local Callback = InputConfig.Callback or function() end
             
             local InputFrame = Instance.new("Frame")
             InputFrame.Size = UDim2.new(1, -6, 0, 50)
             InputFrame.BackgroundColor3 = UISetting.ItemColor
             InputFrame.Parent = Page
             
             local InputCorner = Instance.new("UICorner")
             InputCorner.CornerRadius = UDim.new(0, 4)
             InputCorner.Parent = InputFrame
             
             local NameLabel = Instance.new("TextLabel")
             NameLabel.Text = InputName
             NameLabel.Size = UDim2.new(1, -10, 0, 20)
             NameLabel.Position = UDim2.new(0, 10, 0, 5)
             NameLabel.BackgroundTransparency = 1
             NameLabel.TextColor3 = UISetting.TextColor
             NameLabel.Font = UISetting.Font
             NameLabel.TextSize = 13
             NameLabel.TextXAlignment = Enum.TextXAlignment.Left
             NameLabel.Parent = InputFrame
             
             local TextBox = Instance.new("TextBox")
             TextBox.Size = UDim2.new(1, -20, 0, 20)
             TextBox.Position = UDim2.new(0, 10, 0, 25)
             TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
             TextBox.BackgroundTransparency = 0
             TextBox.TextColor3 = UISetting.TextColor
             TextBox.Font = UISetting.Font
             TextBox.TextSize = 13
             TextBox.Text = Default
             TextBox.PlaceholderText = Placeholder
             TextBox.TextXAlignment = Enum.TextXAlignment.Left
             TextBox.ClearTextOnFocus = false
             TextBox.Parent = InputFrame

             local TBCorner = Instance.new("UICorner")
             TBCorner.CornerRadius = UDim.new(0, 4)
             TBCorner.Parent = TextBox
             
             local Padding = Instance.new("UIPadding")
             Padding.PaddingLeft = UDim.new(0, 5)
             Padding.Parent = TextBox

             TextBox.FocusLost:Connect(function(enterPressed)
                 Callback(TextBox.Text)
             end)
        end
        
        return TabObj
    end
    
    return WindowObj
end

-- // APP INITIALIZATION //
local Window = Library:CreateWindow({Name = "XALSC | Fish It (Beta)"})

-- // HELPERS //
local function getFishCount()
    local gui = PlayerGui:FindFirstChild("Inventory") 
    if gui and gui:FindFirstChild("Main") then
        local label = gui.Main.Top.Options.Fish.Label.BagSize
        return tonumber((label and label.Text or "0/???"):match("(%d+)/")) or 0
    end
    return 0
end

local function toggleWalkOnWater(enable)
    local char = LocalPlayer.Character
    if not char then return end
    
    if enable then
        local floatPart = char:FindFirstChild("FloatPart") or Instance.new("Part")
        floatPart.Name = "FloatPart"
        floatPart.Size = Vector3.new(10, 1, 10)
        floatPart.Transparency = 0.5
        floatPart.Anchored = true
        floatPart.CanCollide = true
        floatPart.Parent = char
        
        State.waterConnection = RunService.Heartbeat:Connect(function()
             if char and char:FindFirstChild("HumanoidRootPart") and floatPart then
                floatPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, -3.5, 0)
            end
        end)
    else
        if State.waterConnection then State.waterConnection:Disconnect() end
        local floatPart = char:FindFirstChild("FloatPart")
        if floatPart then floatPart:Destroy() end
    end
end

local function getThumbnailURL(assetId)
    if not assetId then return nil end
    local id = assetId:match("rbxassetid://(%d+)")
    if not id then return nil end
    
    local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png", id)
    local success, response = pcall(function()
        return InitHttp:JSONDecode(game:HttpGet(url))
    end)
    
    if success and response and response.data and response.data[1] then
        return response.data[1].imageUrl
    end
    return nil
end

local function buildFishDatabase()
    for _, folder in pairs(ReplicatedStorage.Items:GetChildren()) do
        if folder.Name == "Fish" then
            for _, item in pairs(folder:GetChildren()) do
                local success, config = pcall(function() return require(item) end)
                if success and config then
                   State.fishDatabase[config.Id] = {
                       Name = config.Name,
                       Tier = config.Tier,
                       Icon = config.Icon,
                       SellPrice = config.Price
                   }
                end
            end
        end
    end
end

local function sendNewFishWebhook(fishData)
    if not State.webhookEnabled or State.webhookURL == "" then return end
    
    local fishInfo = State.fishDatabase[fishData.Id]
    if not fishInfo then return end
    
    -- Rarity Filter
    local rarity = fishInfo.Tier or "Unknown"
    local allowed = false
    if #State.webhookRarities > 0 then
        for _, r in pairs(State.webhookRarities) do
            if r == rarity then allowed = true break end
        end
    else
        allowed = true -- No filter means all
    end
    
    if not allowed then return end
    
    local weight = fishData.Metadata and fishData.Metadata.Weight and string.format("%.2f Kg", fishData.Metadata.Weight) or "N/A"
    local mutation = fishData.Metadata and fishData.Metadata.VariantId and tostring(fishData.Metadata.VariantId) or "None"
    local price = fishInfo.SellPrice and ("$" .. tostring(fishInfo.SellPrice)) or "N/A"
    
    local embed = {
        title = "XAL HUB | Fish Caught",
        description = string.format("Congratulations! **%s** caught a **%s** fish!", LocalPlayer.Name, rarity),
        color = 52221,
        fields = {
            {name = "Fish Name", value = "```" .. fishInfo.Name .. "```", inline = true},
            {name = "Tier", value = "```" .. rarity .. "```", inline = true},
            {name = "Weight", value = "```" .. weight .. "```", inline = true},
            {name = "Mutation", value = "```" .. mutation .. "```", inline = true},
            {name = "Price", value = "```" .. price .. "```", inline = true}
        },
        footer = { text = "XAL HUB Webhook" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }
    
    local thumb = getThumbnailURL(fishInfo.Icon)
    if thumb then
        embed.thumbnail = { url = thumb }
    end
    
    local payload = {
        username = "XAL HUB Notification",
        embeds = {embed}
    }
    
    if request then
        request({
            Url = State.webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = InitHttp:JSONEncode(payload)
        })
    end
end

local function testCustomWebhook()
    if State.webhookURL == "" then return end
    
    local payload = {
        content = "Webhook Connected Successfully!",
        username = "XAL HUB Test"
    }
    
    if request then
        request({
            Url = State.webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = InitHttp:JSONEncode(payload)
        })
    end
end

-- // TABS //
local HomeTab = Window:MakeTab({Name = "Home"})
local TeleportTab = Window:MakeTab({Name = "Teleport"})
local FishingTab = Window:MakeTab({Name = "Fishing"})
local AutoTab = Window:MakeTab({Name = "Automatically"})
local WebhookTab = Window:MakeTab({Name = "Webhook"})
local MiscTab = Window:MakeTab({Name = "Misc"})

-- // HOME //
HomeTab:AddLabel("Welcome to XAL HUB for Fish It!")
HomeTab:AddLabel("Status: Custom UI Loaded Successfully")
HomeTab:AddLabel("Enjoy your fishing :)")

-- // TELEPORT //
local Locations = {
    ["Treasure Room"] = Vector3.new(-3602.01, -266.57, -1577.18),
    ["Sisyphus Statue"] = Vector3.new(-3703.69, -135.57, -1017.17),
    ["Crater Island Top"] = Vector3.new(1011.29, 22.68, 5076.27),
    ["Crater Island Ground"] = Vector3.new(1079.57, 3.64, 5080.35),
    ["Coral Reefs SPOT 1"] = Vector3.new(-3031.88, 2.52, 2276.36),
    ["Coral Reefs SPOT 2"] = Vector3.new(-3270.86, 2.5, 2228.1),
    ["Coral Reefs SPOT 3"] = Vector3.new(-3136.1, 2.61, 2126.11),
    ["Lost Shore"] = Vector3.new(-3737.97, 5.43, -854.68),
    ["Weather Machine"] = Vector3.new(-1524.88, 2.87, 1915.56),
    ["Kohana Volcano"] = Vector3.new(-561.81, 21.24, 156.72),
    ["Kohana SPOT 1"] = Vector3.new(-367.77, 6.75, 521.91),
    ["Kohana SPOT 2"] = Vector3.new(-623.96, 19.25, 419.36),
    ["Stingray Shores"] = Vector3.new(44.41, 28.83, 3048.93),
    ["Tropical Grove"] = Vector3.new(-2018.91, 9.04, 3750.59),
    ["Ice Sea"] = Vector3.new(2164, 7, 3269),
    ["Secred Temple"] = Vector3.new(1475, -22, -632),
    ["Ancient Jungle Outside"] = Vector3.new(1488, 8, -392),
    ["Ancient Jungle"] = Vector3.new(1274, 8, -184),
    ["Underground Cellar"] = Vector3.new(2136, -91, -699),
    ["Mount Hallow"] = Vector3.new(2123, 80, 3265),
    ["Hallow Bay"] = Vector3.new(1730, 8, 3046),
    ["Underground Hallow"] = Vector3.new(2167, 8, 3008)
}

local locNames = {}
for name, _ in pairs(Locations) do table.insert(locNames, name) end
table.sort(locNames)

TeleportTab:AddDropdown({
    Name = "Select Location",
    Options = locNames,
    Callback = function(Value)
        State.selectedLoc = Value
    end
})

TeleportTab:AddButton({
    Name = "Teleport Now",
    Callback = function()
        if State.selectedLoc and Locations[State.selectedLoc] then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(Locations[State.selectedLoc] + Vector3.new(0, 3, 0))
            end
        end
    end
})

-- // FISHING //
FishingTab:AddSection({Name = "Detector Stuck"})
local DetectorLabel = FishingTab:AddLabel("Status: Idle")

FishingTab:AddSlider({
    Name = "Stuck Threshold (s)",
    Min = 10, Max = 60, Default = 15,
    Callback = function(Value)
        State.stuckThreshold = Value
    end    
})

FishingTab:AddToggle({
    Name = "Enable Detector",
    Default = false,
    Callback = function(Value)
        State.detectorStuck = Value
        if Value then
            State.lastBagCount = getFishCount()
            State.fishingTimer = 0
            State.savedCFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
            
            task.spawn(function()
                while State.detectorStuck do
                    task.wait(1)
                    State.fishingTimer = State.fishingTimer + 1
                    local currentBag = getFishCount()
                    
                    if currentBag > State.lastBagCount then
                        State.lastBagCount = currentBag
                        State.fishingTimer = 0
                        DetectorLabel:Set("Status: Caught Fish!")
                    elseif State.fishingTimer >= State.stuckThreshold then
                        DetectorLabel:Set("Status: Stuck! Resetting...")
                        local char = LocalPlayer.Character
                        if char then
                            if char:FindFirstChild("HumanoidRootPart") then
                                State.savedCFrame = char.HumanoidRootPart.CFrame
                            end
                            char:BreakJoints()
                            LocalPlayer.CharacterAdded:Wait()
                            task.wait(0.5)
                            LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = State.savedCFrame
                            task.wait(0.5)
                            Events.REEquip:FireServer(1)
                        end
                        State.fishingTimer = 0
                    else
                         DetectorLabel:Set("Status: Idle (" .. tostring(State.fishingTimer) .. "s)")
                    end
                end
                 DetectorLabel:Set("Status: Disabled")
            end)
        end
    end
})

FishingTab:AddSection({Name = "Automation"})
FishingTab:AddToggle({
    Name = "Auto Shake",
    Default = false,
    Callback = function(Value)
        State.autoShake = Value
        if Value then
            task.spawn(function()
                while State.autoShake do
                    pcall(function()
                        FishingController:RequestFishingMinigameClick()
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

FishingTab:AddToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(Value)
        State.autoSell = Value
        if Value then
            task.spawn(function()
                 while State.autoSell do
                    Functions.SellAll:InvokeServer()
                    task.wait(State.sellDelay)
                 end
            end)
        end
    end
})

FishingTab:AddSlider({
    Name = "Sell Delay (s)",
    Min = 5, Max = 300, Default = 60,
    Callback = function(Value)
        State.sellDelay = Value
    end    
})



-- // AUTOMATICALLY //
AutoTab:AddToggle({
    Name = "Auto Buy Weather (Wind, Cloudy, Storm)",
    Default = false,
    Callback = function(Value)
        State.autoBuyWeather = Value
        if Value then
            task.spawn(function()
                while State.autoBuyWeather do
                     local targetWeathers = {"Wind", "Cloudy", "Storm"}
                     for _, weather in pairs(targetWeathers) do
                         if not State.autoBuyWeather then break end
                         pcall(function()
                             Functions.BuyWeather:InvokeServer(weather)
                         end)
                         task.wait(2)
                     end
                     task.wait(2)
                end
            end)
        end
    end
})

AutoTab:AddSection({Name = "Totem"})
AutoTab:AddToggle({
    Name = "Auto Totem",
    Default = false,
    Callback = function(Value)
        State.totemActive = Value
        if Value then
             task.spawn(function()
                while State.totemActive do
                    -- Find UUID of totem
                    local success, replion = pcall(function() 
                        return require(Packages._Index["ytrev_replion@2.0.0-rc.3"].replion)
                    end)
                    if success and replion then
                        local data = replion.Client:WaitReplion("Data")
                        if data then
                            local inventory = data:Get({ "Inventory", "Totems" }) or {}
                            for _, item in pairs(inventory) do
                                 pcall(function()
                                     Events.Totem:FireServer(item.UUID)
                                 end)
                                 task.wait(1)
                            end
                        end
                    end
                    task.wait(3600) -- Wait 1 hour
                end
             end)
        end
    end
})

-- // WEBHOOK //
WebhookTab:AddSection({Name = "Configuration"})

WebhookTab:AddLabel("Status: " .. (request and "Http Supported" or "Http Not Supported (Executor Issue)"))

WebhookTab:AddToggle({
    Name = "Enable Webhook",
    Default = false,
    Callback = function(Value)
        State.webhookEnabled = Value
    end
})

WebhookTab:AddInput({
    Name = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Text)
        State.webhookURL = Text
    end
})

WebhookTab:AddDropdown({
    Name = "Rarity Filter (Multi)",
    Options = {"Mythic", "Secret", "Exotic", "Event", "Legendary", "Epic", "Rare", "Uncommon", "Common"},
    Multi = true,
    Default = {"Mythic", "Secret", "Exotic", "Event"}, 
    Callback = function(Value)
        State.webhookRarities = Value
    end
})

WebhookTab:AddButton({
    Name = "Test Webhook",
    Callback = function()
        testCustomWebhook()
    end
})

-- // MISC //
MiscTab:AddSection({Name = "Server"})
MiscTab:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:AddButton({
    Name = "Server Hop",
    Callback = function()
         local Api = "https://games.roblox.com/v1/games/"
         local _place = game.PlaceId
         local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
         
         local function List()
             local success, result = pcall(function() return InitHttp:JSONDecode(game:HttpGet(_servers)) end)
             return success and result or {}
         end
         
         local ServerList = List()
         if ServerList.data then
             for _, v in pairs(ServerList.data) do
                 if v.playing < v.maxPlayers and v.id ~= game.JobId then
                     TeleportService:TeleportToPlaceInstance(_place, v.id, LocalPlayer)
                     break
                 end
             end
         end
    end
})

MiscTab:AddSection({Name = "Game Features"})
MiscTab:AddToggle({
    Name = "Delete Fishing Effects",
    Default = false,
    Callback = function(Value)
        State.deleteEffects = Value
        if Value then
            task.spawn(function()
                while State.deleteEffects do
                    local cos = workspace:FindFirstChild("CosmeticFolder")
                    if cos then cos:Destroy() end
                    task.wait(5)
                end
            end)
        end
    end
})

MiscTab:AddToggle({
    Name = "No Fishing Animation",
    Default = false,
    Callback = function(Value)
        State.frozen = Value
        if Value then
             task.spawn(function()
                while State.frozen do
                     local char = LocalPlayer.Character
                     if char then
                        for _, v in pairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.Anchored = true
                            end
                        end
                     end
                     task.wait(1)
                end
                 local char = LocalPlayer.Character
                 if char then
                    for _, v in pairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.Anchored = false
                        end
                    end
                 end
             end)
        end
    end
})

MiscTab:AddToggle({
    Name = "Walk on Water",
    Default = false,
    Callback = function(Value)
        toggleWalkOnWater(Value)
    end
})

-- End of Misc Tab

-- // INITIALIZATION //
task.spawn(function()
    buildFishDatabase()
end)

-- // EVENTS //
if Events.REObtainedNewFishNotification then
    Events.REObtainedNewFishNotification.OnClientEvent:Connect(function(fishData)
        sendNewFishWebhook(fishData)
    end)
end

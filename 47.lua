local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService") 

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local ScriptActive = true
local Connections = {}
local ScreenGui
local VirtualUser = game:GetService("VirtualUser")

local SafeName = "RobloxReplicatedService"
local ProtectGui = protectgui or (syn and syn.protect_gui) or (gethui and function(g) g.Parent = gethui() end) or function(g) g.Parent = CoreGui end

task.spawn(function()
    while ScriptActive do
        task.wait(5)
        local success, err = pcall(function()
            local core = game:GetService("CoreGui")
            if core:FindFirstChild("DarkDetex") or core:FindFirstChild("RemoteSpy") or core:FindFirstChild("TurtleSpy") then

            end
        end)
    end
end)

if getgenv and getgenv().XAL_Stop then
    pcall(getgenv().XAL_Stop)
end

local function CleanupScript()
    ScriptActive = false
    for _, v in pairs(Connections) do
        pcall(function() v:Disconnect() end)
    end
    Connections = {}
    
    if TextChatService then
        TextChatService.OnIncomingMessage = nil
    end
    
    if ScreenGui then ScreenGui:Destroy() end
    
    print("❌ XAL System: Script closed and cleanup complete.")
    if getgenv then getgenv().XAL_Stop = nil end
end

if getgenv then
    getgenv().XAL_Stop = CleanupScript
end

if not isfolder("XAL_Configs") then 
    pcall(function() makefolder("XAL_Configs") end)
end

local Theme = {
    Background = Color3.fromRGB(20, 22, 28),
    Header = Color3.fromRGB(25, 28, 35),
    Sidebar = Color3.fromRGB(18, 20, 25),
    Content = Color3.fromRGB(22, 24, 30),
    Accent = Color3.fromRGB(0, 139, 139), 
    AccentHover = Color3.fromRGB(0, 160, 160), 
    TextPrimary = Color3.fromRGB(240, 240, 240),
    TextSecondary = Color3.fromRGB(160, 165, 175),
    Border = Color3.fromRGB(45, 50, 60),
    Input = Color3.fromRGB(15, 16, 20),
    Success = Color3.fromRGB(75, 185, 115),
    Error = Color3.fromRGB(235, 85, 85)
}

local Current_Webhook_Fish = ""
local Current_Webhook_Leave = ""
local Current_Webhook_List = ""
local Current_Webhook_Admin = ""

local LastDisconnectTime = 0

local AdminID_1 = ""
local AdminID_2 = ""

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
    "Cursed Kraken", "Glowspore Toad", "Sapphyra",
}

local StoneList = { "Ruby" }

local Settings = { 
    SecretEnabled = false, 
    RubyEnabled = false, 
    EvolvedEnabled = false, 
    LeviathanRageEnabled = false,
    MutationCrystalized = false,
    CaveCrystalEnabled = false,
    LeaveEnabled = false, 
    PlayerNonPSAuto = false,
    ForeignDetection = false,
    SpoilerName = true,
    PingMonitor = false
}

local TagList = {} 
local TagUIElements = {} 
local UI_FishInput, UI_LeaveInput, UI_ListInput, UI_AdminInput

local SessionStart = tick()
local SessionStats = {
    Secret = 0,
    Ruby = 0,
    Evolved = 0,
    Rage = 0,
    Crystalized = 0,
    CaveCrystal = 0,
    TotalSent = 0
}
local UI_StatsLabels = {}


local ShowNotification 

local function UpdateTagData()
    if #TagList == 0 then
        for i = 1, 20 do TagList[i] = {"", ""} end
    end

    if #TagUIElements > 0 then
        for i = 1, 20 do
            if TagUIElements[i] then
                TagUIElements[i].User.Text = TagList[i][1] or ""
                TagUIElements[i].ID.Text = TagList[i][2] or ""
            end
        end
    end
end

UpdateTagData() 

local oldUI = CoreGui:FindFirstChild(SafeName) or CoreGui:FindFirstChild("XAL_System")
if oldUI then oldUI:Destroy() task.wait(0.1) end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SafeName
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() 
    ProtectGui(ScreenGui) 
end)
if not ScreenGui.Parent then ScreenGui.Parent = CoreGui end
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function AddStroke(instance, color, thickness)
    local s = Instance.new("UIStroke", instance)
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function AddPadding(instance, amount)
    local p = Instance.new("UIPadding", instance)
    p.PaddingLeft = UDim.new(0, amount)
    p.PaddingRight = UDim.new(0, amount)
    p.PaddingTop = UDim.new(0, amount)
    p.PaddingBottom = UDim.new(0, amount)
    return p
end

function ShowNotification(msg, isError)
    if not ScriptActive then return end
    local NotifFrame = Instance.new("Frame", ScreenGui)
    NotifFrame.BackgroundColor3 = Theme.Background
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Position = UDim2.new(0.5, -110, 0.1, 0)
    NotifFrame.Size = UDim2.new(0, 220, 0, 40)
    NotifFrame.ZIndex = 200
    
    Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 8)
    AddStroke(NotifFrame, isError and Theme.Error or Theme.Accent, 1.5)
    
    local Icon = Instance.new("Frame", NotifFrame) 
    Icon.BackgroundColor3 = isError and Theme.Error or Theme.Accent
    Icon.Size = UDim2.new(0, 4, 1, -10)
    Icon.Position = UDim2.new(0, 8, 0.5, -((40-10)/2))
    Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)

    local Label = Instance.new("TextLabel", NotifFrame)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 20, 0, 0)
    Label.Size = UDim2.new(1, -25, 1, 0)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = msg
    Label.TextColor3 = Theme.TextPrimary
    Label.TextSize = 13
    Label.ZIndex = 201
    
    NotifFrame.BackgroundTransparency = 1
    Label.TextTransparency = 1
    Icon.BackgroundTransparency = 1
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(Label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(Icon, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -110, 0.15, 0)}):Play()
    
    task.delay(2.5, function()
        if NotifFrame then
            TweenService:Create(NotifFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1, Position = UDim2.new(0.5, -110, 0.1, 0)}):Play()
            TweenService:Create(Label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            TweenService:Create(Icon, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            NotifFrame:Destroy()
        end
    end)
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -140) 
MainFrame.Size = UDim2.new(0, 480, 0, 300) 
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false 
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
AddStroke(MainFrame, Theme.Border, 1)

local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 60, 1, 60)
Shadow.ZIndex = -1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.4
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceScale = 1

local Header = Instance.new("Frame", MainFrame)
Header.BackgroundColor3 = Theme.Header
Header.Size = UDim2.new(1, 0, 0, 36) 
Header.BorderSizePixel = 0
Header.ZIndex = 5
local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 8)

local HeaderSquare = Instance.new("Frame", Header)
HeaderSquare.BackgroundColor3 = Theme.Header
HeaderSquare.BorderSizePixel = 0
HeaderSquare.Position = UDim2.new(0,0,1,-8)
HeaderSquare.Size = UDim2.new(1,0,0,8)

local HeaderLine = Instance.new("Frame", Header)
HeaderLine.BackgroundColor3 = Theme.Border
HeaderLine.BorderSizePixel = 0
HeaderLine.Position = UDim2.new(0, 0, 1, 0)
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.ZIndex = 6

local TitleLab = Instance.new("TextLabel", Header)
TitleLab.BackgroundTransparency = 1
TitleLab.Position = UDim2.new(0, 15, 0, 0)
TitleLab.Size = UDim2.new(0, 200, 1, 0)
TitleLab.Font = Enum.Font.GothamBold
TitleLab.Text = "XAL SERVER MONITORING" 
TitleLab.TextColor3 = Theme.Accent 
TitleLab.TextSize = 14 
TitleLab.TextXAlignment = "Left"
TitleLab.ZIndex = 6

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Name = "Close"
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Size = UDim2.new(0, 30, 1, 0) 
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×" 
CloseBtn.TextColor3 = Theme.TextSecondary
CloseBtn.TextSize = 22
CloseBtn.ZIndex = 6
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Error end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextSecondary end)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Name = "Minimize"
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "−" 
MinBtn.TextColor3 = Theme.TextSecondary
MinBtn.TextSize = 22
MinBtn.ZIndex = 6
MinBtn.MouseEnter:Connect(function() MinBtn.TextColor3 = Theme.TextPrimary end)
MinBtn.MouseLeave:Connect(function() MinBtn.TextColor3 = Theme.TextSecondary end)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.Position = UDim2.new(0, 0, 0, 36)
Sidebar.Size = UDim2.new(0, 110, 1, -36) 
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
local SideCorner = Instance.new("UICorner", Sidebar)
SideCorner.CornerRadius = UDim.new(0, 8)
local SideSquare = Instance.new("Frame", Sidebar)
SideSquare.BackgroundColor3 = Theme.Sidebar
SideSquare.BorderSizePixel = 0
SideSquare.Position = UDim2.new(1,-8,0,0)
SideSquare.Size = UDim2.new(0,8,1,0)

local SideLine = Instance.new("Frame", Sidebar)
SideLine.BackgroundColor3 = Theme.Border
SideLine.BorderSizePixel = 0
SideLine.Position = UDim2.new(1, -1, 0, 0)
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.ZIndex = 3

local MenuContainer = Instance.new("Frame", Sidebar)
MenuContainer.BackgroundTransparency = 1
MenuContainer.Size = UDim2.new(1, 0, 1, -25) 
MenuContainer.Position = UDim2.new(0, 0, 0, 5)

local SideLayout = Instance.new("UIListLayout", MenuContainer)
SideLayout.Padding = UDim.new(0, 2) 
SideLayout.HorizontalAlignment = "Center"
Instance.new("UIPadding", MenuContainer).PaddingTop = UDim.new(0, 8)

local Watermark = Instance.new("TextLabel", Sidebar)
Watermark.Name = "Watermark"
Watermark.BackgroundColor3 = Theme.Background 
Watermark.BackgroundTransparency = 1 
Watermark.BorderSizePixel = 0
Watermark.Position = UDim2.new(0, 0, 1, -25) 
Watermark.Size = UDim2.new(1, 0, 0, 20) 
Watermark.Font = Enum.Font.GothamBold
Watermark.Text = "ALgiFH"
Watermark.TextColor3 = Theme.Accent 
Watermark.TextSize = 11 
Watermark.ZIndex = 5

local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 115, 0, 42) 
ContentContainer.Size = UDim2.new(1, -120, 1, -48) 
ContentContainer.ZIndex = 3

local ModalFrame = Instance.new("Frame", ScreenGui)
ModalFrame.Name = "ModalConfirm"
ModalFrame.BackgroundColor3 = Theme.Header
ModalFrame.Size = UDim2.new(0, 240, 0, 110)
ModalFrame.Position = UDim2.new(0.5, -120, 0.5, -55) 
ModalFrame.BorderSizePixel = 0
ModalFrame.ZIndex = 100 
ModalFrame.Visible = false
ModalFrame.Active = true 
Instance.new("UICorner", ModalFrame).CornerRadius = UDim.new(0, 8)
AddStroke(ModalFrame, Theme.Border, 1)

local ModalShadow = Instance.new("ImageLabel", ModalFrame)
ModalShadow.Name = "Shadow"
ModalShadow.AnchorPoint = Vector2.new(0.5, 0.5)
ModalShadow.BackgroundTransparency = 1
ModalShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
ModalShadow.Size = UDim2.new(1, 40, 1, 40)
ModalShadow.ZIndex = 99
ModalShadow.Image = "rbxassetid://6014261993"
ModalShadow.ImageColor3 = Color3.new(0, 0, 0)
ModalShadow.ImageTransparency = 0.5
ModalShadow.SliceCenter = Rect.new(49, 49, 450, 450)

local ModalTitle = Instance.new("TextLabel", ModalFrame)
ModalTitle.BackgroundTransparency = 1
ModalTitle.Position = UDim2.new(0, 0, 0, 18)
ModalTitle.Size = UDim2.new(1, 0, 0, 20)
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.Text = "Close Script?"
ModalTitle.TextColor3 = Theme.TextPrimary
ModalTitle.TextSize = 16 
ModalTitle.ZIndex = 102

local BtnYes = Instance.new("TextButton", ModalFrame)
BtnYes.BackgroundColor3 = Theme.Error
BtnYes.Position = UDim2.new(0, 20, 1, -40)
BtnYes.Size = UDim2.new(0, 95, 0, 28)
BtnYes.Font = Enum.Font.GothamBold 
BtnYes.Text = "Yes"
BtnYes.TextColor3 = Color3.new(1, 1, 1)
BtnYes.TextSize = 13 
BtnYes.ZIndex = 102
BtnYes.Active = true
Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 6)

local BtnNo = Instance.new("TextButton", ModalFrame)
BtnNo.BackgroundColor3 = Theme.Content
BtnNo.Position = UDim2.new(1, -115, 1, -40)
BtnNo.Size = UDim2.new(0, 95, 0, 28)
BtnNo.Font = Enum.Font.GothamBold 
BtnNo.Text = "No"
BtnNo.TextColor3 = Theme.TextPrimary
BtnNo.TextSize = 13 
BtnNo.ZIndex = 102
BtnNo.Active = true
Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 6)
AddStroke(BtnNo, Theme.Border, 1)

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentContainer)
    Page.Name = "Page_" .. name
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = "Y"
    Page.ZIndex = 4
    
    local layout = Instance.new("UIListLayout", Page)
    layout.Padding = UDim.new(0, 6) 
    layout.SortOrder = Enum.SortOrder.LayoutOrder 
    
    return Page
end

local Page_Webhook = CreatePage("Webhook")
local Page_Config = CreatePage("Config") 
local Page_Save = CreatePage("SaveConfig") 
local Page_Url = CreatePage("UrlWebhook") 
local Page_Tag = CreatePage("TagDiscord")
local Page_AdminBoost = CreatePage("AdminBoost")
local Page_SessionStats = CreatePage("SessionStats")

Page_Webhook.Visible = true

local function CreateTab(name, target, isDefault)
    local TabBtn = Instance.new("TextButton", MenuContainer) 
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) 
    TabBtn.BackgroundTransparency = 1 
    TabBtn.Size = UDim2.new(1, -10, 0, 26) 
    TabBtn.Font = Enum.Font.GothamMedium 
    TabBtn.Text = name
    TabBtn.TextColor3 = Theme.TextSecondary
    TabBtn.TextSize = 12 
    TabBtn.ZIndex = 3
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)
    
    local Indicator = Instance.new("Frame", TabBtn)
    Indicator.Name = "ActiveIndicator"
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Position = UDim2.new(0, 2, 0.5, -8) 
    Indicator.Size = UDim2.new(0, 3, 0, 16) 
    Indicator.Visible = false 
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    TabBtn.MouseButton1Click:Connect(function()
        Page_Webhook.Visible = false; Page_Config.Visible = false; Page_Tag.Visible = false; Page_Url.Visible = false; Page_Save.Visible = false; Page_AdminBoost.Visible = false; Page_SessionStats.Visible = false
        target.Visible = true

        
        for _, child in pairs(MenuContainer:GetChildren()) do
            if child:IsA("TextButton") then 
                child.TextColor3 = Theme.TextSecondary
                child.Font = Enum.Font.GothamMedium 
                child.BackgroundTransparency = 1
                local line = child:FindFirstChild("ActiveIndicator")
                if line then line.Visible = false end
            end
        end
        
        TabBtn.TextColor3 = Theme.TextPrimary
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.BackgroundTransparency = 0.95 
        TabBtn.BackgroundColor3 = Theme.TextPrimary
        Indicator.Visible = true 
    end)

    if isDefault then
        TabBtn.TextColor3 = Theme.TextPrimary
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.BackgroundTransparency = 0.95
        TabBtn.BackgroundColor3 = Theme.TextPrimary
        Indicator.Visible = true
        target.Visible = true
    end
end

CreateTab("Notification", Page_Webhook, true) 

CreateTab("Admin Boost", Page_AdminBoost)

CreateTab("Session Stats", Page_SessionStats)
CreateTab("Webhook", Page_Url)

CreateTab("List Player", Page_Tag)
CreateTab("Import List", Page_Config) 
CreateTab("Save Config", Page_Save) 

local function CreateToggle(parent, text, default, callback, validationFunc)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Theme.Content
    Frame.BackgroundTransparency = 0
    Frame.Size = UDim2.new(1, -5, 0, 36) 
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    AddStroke(Frame, Theme.Border, 1)

    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 10, 0, 0); Label.Size = UDim2.new(0, 180, 1, 0)
    Label.Font = Enum.Font.GothamBold; Label.Text = text; Label.TextColor3 = Theme.TextPrimary; Label.TextSize = 12; Label.TextXAlignment = "Left"
    
    local Switch = Instance.new("TextButton", Frame)
    Switch.BackgroundColor3 = default and Theme.Success or Theme.Input
    Switch.BackgroundTransparency = 0; Switch.Position = UDim2.new(1, -45, 0.5, -10); Switch.Size = UDim2.new(0, 36, 0, 20); Switch.Text = ""
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame", Switch)
    Circle.BackgroundColor3 = Color3.new(1,1,1)
    Circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Circle.Size = UDim2.new(0, 16, 0, 16)
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    Switch.MouseButton1Click:Connect(function()
        local n = not (Switch.BackgroundColor3 == Theme.Success)
        if n and validationFunc and not validationFunc() then ShowNotification("Webhook Empty!", true) return end
        
        local targetColor = n and Theme.Success or Theme.Input
        local targetPos = n and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        Circle:TweenPosition(targetPos, "Out", "Sine", 0.15, true)
        
        callback(n); ShowNotification(text .. (n and " Enabled" or " Disabled"))
    end)
end

local function CreateActionWithLabel(parent, labelText, btnText, btnColor, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Theme.Content
    Frame.BackgroundTransparency = 0
    Frame.Size = UDim2.new(1, -5, 0, 36) 
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    AddStroke(Frame, Theme.Border, 1)

    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 10, 0, 0); Label.Size = UDim2.new(0, 180, 1, 0)
    Label.Font = Enum.Font.GothamBold; Label.Text = labelText; Label.TextColor3 = Theme.TextPrimary; Label.TextSize = 12; Label.TextXAlignment = "Left"
    
    local Btn = Instance.new("TextButton", Frame)
    Btn.BackgroundColor3 = btnColor; Btn.BackgroundTransparency = 0.1; Btn.Position = UDim2.new(1, -80, 0.5, -11); Btn.Size = UDim2.new(0, 70, 0, 22)
    Btn.Font = Enum.Font.GothamBold; Btn.Text = btnText; Btn.TextColor3 = Color3.new(1, 1, 1); Btn.TextSize = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    Btn.MouseButton1Click:Connect(callback)
end

local function CreateInput(parent, placeholder, default, callback, height)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Theme.Content
    local finalHeight = height and (height - 2) or 32 
    Frame.Size = UDim2.new(1, -5, 0, finalHeight); Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    AddStroke(Frame, Theme.Border, 1)

    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0, 10, 0, 0); Label.Size = UDim2.new(0, 140, 1, 0)
    Label.Font = Enum.Font.GothamBold; Label.Text = placeholder; Label.TextColor3 = Theme.TextSecondary; Label.TextSize = 12; Label.TextXAlignment = "Left"
    
    local inputX = (finalHeight > 34) and 160 or 150
    local inputWidth = (finalHeight > 34) and 170 or 160
    
    local InputBg = Instance.new("Frame", Frame)
    InputBg.BackgroundColor3 = Theme.Input
    InputBg.Position = UDim2.new(0, inputX, 0.5, -10)
    InputBg.Size = UDim2.new(1, -inputWidth, 0, 20)
    InputBg.ClipsDescendants = true
    Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0, 4)
    AddStroke(InputBg, Theme.Border, 1)

    local Input = Instance.new("TextBox", InputBg)
    Input.BackgroundTransparency = 1; Input.Position = UDim2.new(0, 5, 0, 0); Input.Size = UDim2.new(1, -10, 1, 0)
    Input.Font = Enum.Font.GothamMedium; Input.Text = default; Input.PlaceholderText = "Paste here..."; Input.TextColor3 = Theme.TextPrimary; Input.TextSize = 11; Input.TextXAlignment = "Left"; Input.ClearTextOnFocus = false
    
    Input.Focused:Connect(function() AddStroke(InputBg, Theme.Accent, 1) end)
    Input.FocusLost:Connect(function() AddStroke(InputBg, Theme.Border, 1) callback(Input.Text, Input) end)
    return Input
end

local BulkLabel = Instance.new("TextLabel", Page_Config)
BulkLabel.BackgroundTransparency = 1; BulkLabel.Size = UDim2.new(1, 0, 0, 20)
BulkLabel.Font = Enum.Font.GothamBold; BulkLabel.Text = "Bulk Input (Format: User:DiscordID)"; BulkLabel.TextColor3 = Theme.TextSecondary; BulkLabel.TextSize = 11; BulkLabel.TextXAlignment = "Left"

local BulkContainer = Instance.new("Frame", Page_Config)
BulkContainer.BackgroundColor3 = Theme.Content; BulkContainer.Size = UDim2.new(1, -5, 0, 100); BulkContainer.BorderSizePixel = 0
Instance.new("UICorner", BulkContainer).CornerRadius = UDim.new(0, 6)
AddStroke(BulkContainer, Theme.Border, 1)

local BulkInput = Instance.new("TextBox", BulkContainer)
BulkInput.BackgroundTransparency = 1; BulkInput.Position = UDim2.new(0, 8, 0, 8); BulkInput.Size = UDim2.new(1, -16, 1, -16)
BulkInput.Font = Enum.Font.GothamMedium; BulkInput.Text = ""; BulkInput.PlaceholderText = "Username:DiscordID\nUsername:DiscordID"; BulkInput.TextColor3 = Theme.TextPrimary; BulkInput.TextSize = 11; BulkInput.TextXAlignment = "Left"; BulkInput.TextYAlignment = "Top"; BulkInput.MultiLine = true; BulkInput.ClearTextOnFocus = false; BulkInput.TextWrapped = true

local ImportBtnWrapper = Instance.new("Frame", Page_Config)
ImportBtnWrapper.BackgroundTransparency = 1; ImportBtnWrapper.Size = UDim2.new(1, -5, 0, 26); ImportBtnWrapper.Position = UDim2.new(0, 0, 0, 110)

local ImportBtn = Instance.new("TextButton", ImportBtnWrapper)
ImportBtn.BackgroundColor3 = Theme.Success; ImportBtn.BackgroundTransparency = 0.1; ImportBtn.Size = UDim2.new(1, 0, 0, 26)
ImportBtn.Font = Enum.Font.GothamBold; ImportBtn.Text = "IMPORT BULK DATA"; ImportBtn.TextColor3 = Color3.new(1, 1, 1); ImportBtn.TextSize = 11
Instance.new("UICorner", ImportBtn).CornerRadius = UDim.new(0, 6)

ImportBtn.MouseButton1Click:Connect(function()
    local text = BulkInput.Text
    local addedCount = 0; local listFull = false; local currentIndex = 3
    
    while currentIndex <= 20 and TagList[currentIndex][1] ~= "" do currentIndex = currentIndex + 1 end
    
    if currentIndex > 20 then ShowNotification("List Player Full!", true) return end
    
    local maxImport = 18
    local processed = 0
    
    for line in text:gmatch("[^\r\n]+") do
        if currentIndex > 20 or processed >= maxImport then listFull = true; break end
        local split = string.split(line, ":"); local user = split[1] or ""; local id = split[2] or ""
        user = user:match("^%s*(.-)%s*$"); id = id:match("^%s*(.-)%s*$")
        if user ~= "" then
            TagList[currentIndex] = {user, id}
            if TagUIElements[currentIndex] then TagUIElements[currentIndex].User.Text = user; TagUIElements[currentIndex].ID.Text = id end
            currentIndex = currentIndex + 1; addedCount = addedCount + 1; processed = processed + 1
        end
    end
    if addedCount > 0 then BulkInput.Text = ""; ShowNotification("Imported " .. addedCount .. " Players!") else if not listFull then ShowNotification("No Data Found!", true) end end
    if listFull then ShowNotification("List Full (Max 18 Imported)", true) end
end)

local SaveInput = CreateInput(Page_Save, "Config Name", "", function(v) end, 36)

local SaveBtnWrapper = Instance.new("Frame", Page_Save)
SaveBtnWrapper.BackgroundTransparency = 1; SaveBtnWrapper.Size = UDim2.new(1, -5, 0, 30)
local SaveBtn = Instance.new("TextButton", SaveBtnWrapper)
SaveBtn.BackgroundColor3 = Theme.Accent
SaveBtn.Size = UDim2.new(1, 0, 0, 28); SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE CONFIG"; SaveBtn.TextColor3 = Color3.new(1,1,1); SaveBtn.TextSize = 11
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

local ListLabel = Instance.new("TextLabel", Page_Save)
ListLabel.BackgroundTransparency = 1; ListLabel.Size = UDim2.new(1, 0, 0, 20)
ListLabel.Font = Enum.Font.GothamBold; ListLabel.Text = "Saved Configs"; ListLabel.TextColor3 = Theme.TextSecondary; ListLabel.TextSize = 11; ListLabel.TextXAlignment = "Left"

local ConfigList = Instance.new("ScrollingFrame", Page_Save)
ConfigList.BackgroundColor3 = Theme.Content; ConfigList.Size = UDim2.new(1, -5, 0, 80); ConfigList.BorderSizePixel = 0
ConfigList.ScrollBarThickness = 3; ConfigList.ScrollBarImageColor3 = Theme.Accent
ConfigList.CanvasSize = UDim2.new(0,0,0,0); ConfigList.AutomaticCanvasSize = "Y"
Instance.new("UICorner", ConfigList).CornerRadius = UDim.new(0, 6)
AddStroke(ConfigList, Theme.Border, 1)
local ConfigLayout = Instance.new("UIListLayout", ConfigList)
ConfigLayout.Padding = UDim.new(0, 2)
Instance.new("UIPadding", ConfigList).PaddingLeft = UDim.new(0, 4)
Instance.new("UIPadding", ConfigList).PaddingTop = UDim.new(0, 4)

local ActionWrapper = Instance.new("Frame", Page_Save)
ActionWrapper.BackgroundTransparency = 1; ActionWrapper.Size = UDim2.new(1, -5, 0, 28)
ActionWrapper.LayoutOrder = 10 

local LoadBtn = Instance.new("TextButton", ActionWrapper)
LoadBtn.BackgroundColor3 = Theme.Success
LoadBtn.Size = UDim2.new(0.48, 0, 1, 0); LoadBtn.Font = Enum.Font.GothamBold
LoadBtn.Text = "LOAD"; LoadBtn.TextColor3 = Color3.new(1,1,1); LoadBtn.TextSize = 11
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 6)

local DeleteBtn = Instance.new("TextButton", ActionWrapper)
DeleteBtn.BackgroundColor3 = Theme.Error
DeleteBtn.Position = UDim2.new(0.52, 0, 0, 0)
DeleteBtn.Size = UDim2.new(0.48, 0, 1, 0); DeleteBtn.Font = Enum.Font.GothamBold
DeleteBtn.Text = "DELETE"; DeleteBtn.TextColor3 = Color3.new(1,1,1); DeleteBtn.TextSize = 11
Instance.new("UICorner", DeleteBtn).CornerRadius = UDim.new(0, 6)

local selectedConfig = nil

local function RefreshConfigList()
    for _, v in pairs(ConfigList:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    selectedConfig = nil
    LoadBtn.BackgroundColor3 = Theme.Input 
    
    local success, files = pcall(function() return listfiles("XAL_Configs") end)
    if not success or not files then files = {} end

    for _, file in pairs(files) do
        local name = file:match("([^/\\]+)$") or file
        name = name:gsub("%.json$", "")
        
        local Btn = Instance.new("TextButton", ConfigList)
        Btn.BackgroundColor3 = Theme.Background
        Btn.Size = UDim2.new(1, -8, 0, 24); Btn.Font = Enum.Font.GothamMedium
        Btn.Text = "  " .. name; Btn.TextColor3 = Theme.TextSecondary
        Btn.TextSize = 11; Btn.TextXAlignment = "Left"
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        
        Btn.MouseButton1Click:Connect(function()
            for _, b in pairs(ConfigList:GetChildren()) do
                if b:IsA("TextButton") then b.BackgroundColor3 = Theme.Background; b.TextColor3 = Theme.TextSecondary end
            end
            Btn.BackgroundColor3 = Theme.Accent
            Btn.TextColor3 = Color3.new(1, 1, 1)
            selectedConfig = name
            LoadBtn.BackgroundColor3 = Theme.Success 
        end)
    end
end

SaveBtn.MouseButton1Click:Connect(function()
    local name = SaveInput.Text
    if name == "" then ShowNotification("Name cannot be empty!", true) return end
    
    local saveData = {
        Webhooks = {
            Fish = Current_Webhook_Fish,
            Leave = Current_Webhook_Leave,
            List = Current_Webhook_List,
            Admin = Current_Webhook_Admin
        },
        Players = TagList
    }
    
    local success, err = pcall(function()
        writefile("XAL_Configs/" .. name .. ".json", HttpService:JSONEncode(saveData))
    end)
    
    if success then
        ShowNotification("Config Saved!", false)
        RefreshConfigList()
    else
        ShowNotification("Save Failed!", true)
    end
end)

LoadBtn.MouseButton1Click:Connect(function()
    if not selectedConfig then ShowNotification("Select a config!", true) return end
    
    local success, content = pcall(function() return readfile("XAL_Configs/" .. selectedConfig .. ".json") end)
    if not success then ShowNotification("Read Failed!", true) return end

    local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(content) end)
    
    if decodeSuccess and data then
        if data.Webhooks then
            Current_Webhook_Fish = data.Webhooks.Fish or ""
            Current_Webhook_Leave = data.Webhooks.Leave or ""
            Current_Webhook_List = data.Webhooks.List or ""
            
            if UI_FishInput then UI_FishInput.Text = Current_Webhook_Fish end
            if UI_LeaveInput then UI_LeaveInput.Text = Current_Webhook_Leave end
            if UI_ListInput then UI_ListInput.Text = Current_Webhook_List end
            
            Current_Webhook_Admin = data.Webhooks.Admin or ""
            if UI_AdminInput then UI_AdminInput.Text = Current_Webhook_Admin end
        end
                
        if data.Players then
            TagList = data.Players
            for i = 1, 20 do
                if not TagList[i] or type(TagList[i]) ~= "table" then TagList[i] = {"", ""} end
            end
            if #TagUIElements > 0 then
                for i = 1, 20 do
                    if TagUIElements[i] then
                        TagUIElements[i].User.Text = TagList[i][1] or ""
                        TagUIElements[i].ID.Text = TagList[i][2] or ""
                    end
                end
            end
        end
        ShowNotification("Config Loaded!", false)
    else
        ShowNotification("JSON Error!", true)
    end
end)

DeleteBtn.MouseButton1Click:Connect(function()
    if not selectedConfig then return end
    delfile("XAL_Configs/" .. selectedConfig .. ".json")
    ShowNotification("Deleted!", false)
    RefreshConfigList()
end)

RefreshConfigList() 

local function TestWebhook(url, name)
    if not ScriptActive then return end
    if url == "" then ShowNotification("URL Empty!", true) return end
    ShowNotification("Sending Test...", false)
    task.spawn(function()
        local p = { content = "✅ **TEST:** " .. name .. " Connected!", username = "XAL Notifications!", avatar_url = "https://i.imgur.com/GWx0mX9.jpeg" }
        httpRequest({ Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end

local TestAllBtn = Instance.new("TextButton", Page_Url)
TestAllBtn.BackgroundColor3 = Theme.Accent
TestAllBtn.Size = UDim2.new(1, -5, 0, 30)
TestAllBtn.Font = Enum.Font.GothamBold
TestAllBtn.Text = "TEST ALL CONNECTION"
TestAllBtn.TextColor3 = Color3.new(1, 1, 1)
TestAllBtn.TextSize = 12
TestAllBtn.LayoutOrder = -1
Instance.new("UICorner", TestAllBtn).CornerRadius = UDim.new(0, 6)

TestAllBtn.MouseButton1Click:Connect(function()
    local c = 0
    if Current_Webhook_Fish ~= "" then TestWebhook(Current_Webhook_Fish, "Fish"); c=c+1 end
    if Current_Webhook_Leave ~= "" then TestWebhook(Current_Webhook_Leave, "Leave"); c=c+1 end
    if Current_Webhook_List ~= "" then TestWebhook(Current_Webhook_List, "Player List"); c=c+1 end
    if Current_Webhook_Admin ~= "" then TestWebhook(Current_Webhook_Admin, "Admin"); c=c+1 end
    if c == 0 then ShowNotification("No Webhooks Set!", true) else ShowNotification("Testing " .. c .. " Webhooks...", false) end
end)

local SpacerW = Instance.new("Frame", Page_Url); SpacerW.BackgroundTransparency=1; SpacerW.Size=UDim2.new(1,0,0,10); SpacerW.LayoutOrder = -1

UI_FishInput = CreateInput(Page_Url, "Fish Caught", Current_Webhook_Fish, function(v) Current_Webhook_Fish = v end)
UI_LeaveInput = CreateInput(Page_Url, "Player Leave", Current_Webhook_Leave, function(v) Current_Webhook_Leave = v end)
UI_ListInput = CreateInput(Page_Url, "Player List", Current_Webhook_List, function(v) Current_Webhook_List = v end)
UI_AdminInput = CreateInput(Page_Url, "Admin Host", Current_Webhook_Admin, function(v) Current_Webhook_Admin = v end)

for i = 1, 20 do
    local rowData = TagList[i]
    local Row = Instance.new("Frame", Page_Tag)
    Row.BackgroundColor3 = Theme.Content; Row.BackgroundTransparency = 0; Row.Size = UDim2.new(1, -5, 0, 28) 
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 5)
    
    local labelText = "List " .. i .. ":"
    if i == 1 then labelText = "Host 1:" end
    if i == 2 then labelText = "Host 2:" end

    local Num = Instance.new("TextLabel", Row)
    Num.BackgroundTransparency = 1; Num.Position = UDim2.new(0, 8, 0, 0); Num.Size = UDim2.new(0, 15, 1, 0)
    Num.Font = Enum.Font.GothamBold; Num.Text = labelText; Num.TextColor3 = (i <= 2) and Theme.Accent or Theme.TextSecondary; Num.TextSize = 11; Num.TextXAlignment = "Left"
    
    local numWidth = 50
    Num.Size = UDim2.new(0, numWidth, 1, 0)

    local UserInput = Instance.new("TextBox", Row)
    UserInput.BackgroundTransparency = 1; UserInput.Position = UDim2.new(0, numWidth + 5, 0, 0); UserInput.Size = UDim2.new(0.45, -numWidth, 1, 0)
    UserInput.Font = Enum.Font.GothamBold; UserInput.Text = rowData[1]; UserInput.PlaceholderText = "Username"; UserInput.TextColor3 = Theme.TextPrimary; UserInput.TextSize = 12; UserInput.TextXAlignment = "Left"; UserInput.ClearTextOnFocus = false; UserInput.ClipsDescendants = true
    
    local Sep = Instance.new("Frame", Row)
    Sep.BackgroundColor3 = Theme.Border; Sep.BorderSizePixel = 0; Sep.Position = UDim2.new(0.45, 5, 0.2, 0); Sep.Size = UDim2.new(0, 1, 0.6, 0)
    
    local IDInput = Instance.new("TextBox", Row)
    IDInput.BackgroundTransparency = 1; IDInput.Position = UDim2.new(0.45, 15, 0, 0); IDInput.Size = UDim2.new(0.55, -15, 1, 0)
    IDInput.Font = Enum.Font.GothamBold; IDInput.Text = rowData[2]; IDInput.PlaceholderText = "Discord ID (Optional)"; IDInput.TextColor3 = Theme.TextSecondary; IDInput.TextSize = 12; IDInput.TextXAlignment = "Left"; IDInput.ClearTextOnFocus = false; IDInput.ClipsDescendants = true
    
    TagUIElements[i] = {User = UserInput, ID = IDInput}
    local function Sync() TagList[i] = {UserInput.Text, IDInput.Text} end
    UserInput.FocusLost:Connect(Sync); IDInput.FocusLost:Connect(Sync)
end

CreateToggle(Page_Webhook, "Secret Fish Caught", Settings.SecretEnabled, function(v) Settings.SecretEnabled = v end, function() return Current_Webhook_Fish ~= "" end)
CreateToggle(Page_Webhook, "Ruby Gemstone", Settings.RubyEnabled, function(v) Settings.RubyEnabled = v end, function() return Current_Webhook_Fish ~= "" end)
CreateToggle(Page_Webhook, "Notif Cave Crystal", Settings.CaveCrystalEnabled, function(v) Settings.CaveCrystalEnabled = v end, function() return Current_Webhook_Fish ~= "" end)
CreateToggle(Page_Webhook, "Evolved Enchant Stone", Settings.EvolvedEnabled, function(v) Settings.EvolvedEnabled = v end, function() return Current_Webhook_Fish ~= "" end)
CreateToggle(Page_Webhook, "Mutation Leviathan Rage", Settings.LeviathanRageEnabled, function(v) Settings.LeviathanRageEnabled = v end, function() return Current_Webhook_Fish ~= "" end)
CreateToggle(Page_Webhook, "Mutation Crystalized (Mythic)", Settings.MutationCrystalized, function(v) Settings.MutationCrystalized = v end, function() return Current_Webhook_Fish ~= "" end)
CreateToggle(Page_Webhook, "Player Leave Server", Settings.LeaveEnabled, function(v) Settings.LeaveEnabled = v end, function() return Current_Webhook_Leave ~= "" end)
CreateToggle(Page_Webhook, "Player Not On Server (Auto)", Settings.PlayerNonPSAuto, function(v) Settings.PlayerNonPSAuto = v end, function() return Current_Webhook_List ~= "" end)




local function CheckAndSendNonPS(isManual)
    if not ScriptActive then return end
    if Current_Webhook_List == "" then 
        if isManual then ShowNotification("Webhook Missing!", true) end
        return 
    end
    
    if isManual then ShowNotification("Checking Players...", false) end
    
    local current = {}
    for _, p in ipairs(Players:GetPlayers()) do current[string.lower(p.Name)] = true end
    local missingNames = {}; local missingTags = {}
    for i = 1, 20 do
        local name = TagList[i][1]; local discId = TagList[i][2]
        if name ~= "" and not current[string.lower(name)] then 
            table.insert(missingNames, name)
            if discId and discId ~= "" then table.insert(missingTags, "<@" .. discId .. ">") end
        end
    end
    
    if not isManual and #missingNames == 0 then
        return
    end
    
    local txt = "Missing Players (" .. #missingNames .. "):\n\n"
    if #missingNames == 0 then txt = "All tagged players are in the server!" else for i, v in ipairs(missingNames) do txt = txt .. i .. ". " .. v .. "\n" end end
    
    local contentMsg = ""
    if #missingTags > 0 then contentMsg = " **Peringatan:** " .. table.concat(missingTags, " ") .. " belum masuk server!" end
    
    task.spawn(function()
        local p = { ["username"] = "XAL Notifications!", ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", ["content"] = contentMsg, ["embeds"] = {{ ["title"] = "Player Not On Server", ["description"] = "Information\n```\n" .. txt .. "\n```", ["color"] = 16733440, ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } }} }
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end

local AdminBtnContainer = Instance.new("Frame", Page_AdminBoost)
AdminBtnContainer.BackgroundTransparency = 1
AdminBtnContainer.Size = UDim2.new(1, -5, 0, 32)
AdminBtnContainer.LayoutOrder = -1 

local AdminGrid = Instance.new("UIGridLayout", AdminBtnContainer)
AdminGrid.CellSize = UDim2.new(0.5, -3, 1, 0)
AdminGrid.CellPadding = UDim2.new(0, 5, 0, 0)

local BtnPS = Instance.new("TextButton", AdminBtnContainer)
BtnPS.BackgroundColor3 = Theme.Accent
BtnPS.Font = Enum.Font.GothamBold
BtnPS.Text = "Player On Server"
BtnPS.TextColor3 = Color3.new(1, 1, 1)
BtnPS.TextSize = 10
Instance.new("UICorner", BtnPS).CornerRadius = UDim.new(0, 6)

BtnPS.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if Current_Webhook_List == "" then ShowNotification("Webhook Missing!", true) return end
    ShowNotification("Sending List...", false)
    local all = Players:GetPlayers(); local str = "Current Players (" .. #all .. "):\n\n"
    for i, p in ipairs(all) do str = str .. i .. ". " .. p.DisplayName .. " (@" .. p.Name .. ")\n" end
    task.spawn(function()
        local p = { ["username"] = "XAL Notifications!", ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", ["embeds"] = {{ ["title"] = " Manual Player List", ["description"] = "Information\n```\n" .. str .. "\n```", ["color"] = 5763719, ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } }} }
        httpRequest({ Url = Current_Webhook_List, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(p) })
    end)
end)

local BtnNonPS = Instance.new("TextButton", AdminBtnContainer)
BtnNonPS.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
BtnNonPS.Font = Enum.Font.GothamBold
BtnNonPS.Text = "Player NOT On Server"
BtnNonPS.TextColor3 = Color3.new(1, 1, 1)
BtnNonPS.TextSize = 10
Instance.new("UICorner", BtnNonPS).CornerRadius = UDim.new(0, 6)

BtnNonPS.MouseButton1Click:Connect(function()
    if Current_Webhook_List == "" then ShowNotification("Webhook Player List Empty!", true) return end
    CheckAndSendNonPS(true) 
end)

local SpacerAdmin = Instance.new("Frame", Page_AdminBoost)
SpacerAdmin.BackgroundTransparency = 1; SpacerAdmin.Size = UDim2.new(1,0,0,5)

CreateToggle(Page_AdminBoost, "Deteksi Player Asing", Settings.ForeignDetection, function(v) Settings.ForeignDetection = v end, function() return Current_Webhook_Admin ~= "" end)
CreateToggle(Page_AdminBoost, "Hide Player Name (Spoiler)", Settings.SpoilerName, function(v) Settings.SpoilerName = v end, nil)
CreateToggle(Page_AdminBoost, "Lag Detector (Ping > 500ms)", Settings.PingMonitor, function(v) Settings.PingMonitor = v end, function() return Current_Webhook_Admin ~= "" end)




local LastPingAlert = 0
task.spawn(function()
    while ScriptActive do
        task.wait(5)
        if Settings.PingMonitor and ScriptActive then
             local success, ping = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
             if success and ping > 500 then
                 if tick() - LastPingAlert > 60 then
                     LastPingAlert = tick()
                     task.spawn(function()
                         if Current_Webhook_Admin == "" then return end
                         local embed = {
                             ["username"] = "XAL Security",
                             ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
                             ["content"] = "⚠️ **HIGH PING DETECTED!**",
                             ["embeds"] = {{
                                 ["title"] = "Server Lag Alert",
                                 ["description"] = "Information\n```\nCurrent Ping: " .. math.floor(ping) .. " ms\n```",
                                 ["color"] = 16776960,
                                 ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }
                             }}
                         }
                         pcall(function() httpRequest({ Url = Current_Webhook_Admin, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(embed) }) end)
                     end)
                 end
             end
        end
    end
end)

task.spawn(function()

    while ScriptActive do
        task.wait(1800) 
        if Settings.PlayerNonPSAuto and ScriptActive then
            CheckAndSendNonPS(false)
        end
    end
end)

local IconPath = "XAL_Min_Icon.jpg"
local IconUrl = "https://i.imgur.com/Z92uLfK.jpeg"
local RealIconAsset = ""

if not isfile(IconPath) then
    local success, response = pcall(function()
        return httpRequest({Url = IconUrl, Method = "GET"})
    end)
    if success and response.Body then
        writefile(IconPath, response.Body)
    end
end

if isfile(IconPath) and (getcustomasset or getsynasset) then
    RealIconAsset = (getcustomasset or getsynasset)(IconPath)
end

if RealIconAsset == "" then RealIconAsset = "rbxassetid://0" end 

local OpenBtn = Instance.new("ImageButton", ScreenGui) 
OpenBtn.Name = "OpenBtn"
OpenBtn.BackgroundColor3 = Theme.Background
OpenBtn.Size = UDim2.new(0, 40, 0, 40) 
OpenBtn.Position = UDim2.new(0, 22, 0, 75) 
OpenBtn.Image = RealIconAsset 
OpenBtn.Visible = true
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.ScaleType = Enum.ScaleType.Fit 
OpenBtn.SliceScale = 1

Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 8)
AddStroke(OpenBtn, Theme.Border, 1)

OpenBtn.MouseButton1Click:Connect(function()
     MainFrame.Visible = not MainFrame.Visible
end)

-- Session Stats UI Helper
local function CreateStatItem(parent, label, key)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Theme.Content; Frame.Size = UDim2.new(1, -5, 0, 24); Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
    
    local Title = Instance.new("TextLabel", Frame)
    Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 8, 0, 0); Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Font = Enum.Font.GothamMedium; Title.Text = label; Title.TextColor3 = Theme.TextSecondary; Title.TextSize = 11; Title.TextXAlignment = "Left"
    
    local Value = Instance.new("TextLabel", Frame)
    Value.BackgroundTransparency = 1; Value.Position = UDim2.new(0.7, 0, 0, 0); Value.Size = UDim2.new(0.3, -8, 1, 0)
    Value.Font = Enum.Font.GothamBold; Value.Text = "0"; Value.TextColor3 = Theme.Accent; Value.TextSize = 11; Value.TextXAlignment = "Right"
    
    UI_StatsLabels[key] = Value
end

local StatsHeader = Instance.new("Frame", Page_SessionStats)
StatsHeader.BackgroundTransparency = 1
StatsHeader.Size = UDim2.new(1, -5, 0, 32)
StatsHeader.LayoutOrder = -1

local UptimeLabel = Instance.new("TextLabel", StatsHeader)
UptimeLabel.BackgroundTransparency = 1
UptimeLabel.Size = UDim2.new(0.5, -5, 1, 0)
UptimeLabel.Font = Enum.Font.GothamBold
UptimeLabel.Text = "Uptime: 00h 00m 00s"
UptimeLabel.TextColor3 = Theme.TextPrimary
UptimeLabel.TextSize = 13
UptimeLabel.TextXAlignment = "Left"
UI_StatsLabels["Uptime"] = UptimeLabel

local SendStatsBtn = Instance.new("TextButton", StatsHeader)
SendStatsBtn.BackgroundColor3 = Theme.Accent
SendStatsBtn.Position = UDim2.new(0.5, 0, 0, 0)
SendStatsBtn.Size = UDim2.new(0.5, 0, 1, 0)
SendStatsBtn.Font = Enum.Font.GothamBold
SendStatsBtn.Text = "SEND STATS"
SendStatsBtn.TextColor3 = Color3.new(1, 1, 1)
SendStatsBtn.TextSize = 11
Instance.new("UICorner", SendStatsBtn).CornerRadius = UDim.new(0, 6)

CreateStatItem(Page_SessionStats, "Total Webhooks Sent", "TotalSent")
CreateStatItem(Page_SessionStats, "Secret Fish Caught", "Secret")
CreateStatItem(Page_SessionStats, "Ruby Gemstones", "Ruby")
CreateStatItem(Page_SessionStats, "Evolved Stones", "Evolved")
CreateStatItem(Page_SessionStats, "Leviathan Rage", "Rage")
CreateStatItem(Page_SessionStats, "Crystalized Mutations", "Crystalized")
CreateStatItem(Page_SessionStats, "Cave Crystals Found", "CaveCrystal")


SendStatsBtn.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if Current_Webhook_Admin == "" then ShowNotification("Admin Webhook Empty!", true) return end
    
    ShowNotification("Sending Stats...", false)
    
    local diff = tick() - SessionStart
    local h = math.floor(diff / 3600); local m = math.floor((diff % 3600) / 60); local s = math.floor(diff % 60)
    local timeStr = string.format("%02dh %02dm %02ds", h, m, s)
    
    local contentStr = "**📊 SESSION STATISTICS**\n"
    contentStr = contentStr .. "⏱️ Uptime: " .. timeStr .. "\n"
    contentStr = contentStr .. "📡 Total Webhooks: " .. SessionStats.TotalSent .. "\n\n"
    contentStr = contentStr .. "⚓ Secrets: " .. SessionStats.Secret .. "\n"
    contentStr = contentStr .. "💎 Rubies: " .. SessionStats.Ruby .. "\n"
    contentStr = contentStr .. "🔮 Evolved: " .. SessionStats.Evolved .. "\n"
    contentStr = contentStr .. "🔥 Rage: " .. SessionStats.Rage .. "\n"
    contentStr = contentStr .. "✨ Crystalized: " .. SessionStats.Crystalized .. "\n"
    contentStr = contentStr .. "⛏️ Cave Crystals: " .. SessionStats.CaveCrystal
    
    task.spawn(function()
         local embed = {
             ["username"] = "XAL Stats",
             ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
             ["embeds"] = {{
                 ["title"] = "Session Report",
                 ["description"] = "Information\n```\n" .. contentStr .. "\n```",
                 ["color"] = 5763719,
                 ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }
             }}
         }
         httpRequest({ Url = Current_Webhook_Admin, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(embed) })
    end)
end)

task.spawn(function()
    while ScriptActive do
        if UI_StatsLabels["Uptime"] then
            local diff = tick() - SessionStart
            local h = math.floor(diff / 3600); local m = math.floor((diff % 3600) / 60); local s = math.floor(diff % 60)
            UI_StatsLabels["Uptime"].Text = string.format("Uptime: %02dh %02dm %02ds", h, m, s)
        end
        task.wait(1)
    end
end)


CloseBtn.MouseButton1Click:Connect(function() ModalFrame.Visible = true end)
BtnNo.MouseButton1Click:Connect(function() ModalFrame.Visible = false end)

BtnYes.MouseButton1Click:Connect(function() 
    if ScreenGui then ScreenGui:Destroy() end
    ScriptActive = false
    
    if getgenv and getgenv().XAL_Stop then
        pcall(getgenv().XAL_Stop)
    end
end)

MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end) 

local function StripTags(str) return string.gsub(str, "<[^>]+>", "") end
local function GetUsername(chatName) 
    local trimmedChatName = chatName:match("^%s*(.-)%s*$")
    for _, p in ipairs(Players:GetPlayers()) do 
        if p.DisplayName == trimmedChatName or p.Name == trimmedChatName then 
            return p.Name 
        end 
    end
    return trimmedChatName 
end

local function ParseDataSmart(cleanMsg)
    local msg = string.gsub(cleanMsg, "%[Server%]: ", "")
    local p, f, w = string.match(msg, "^(.*) obtained an? (.*) %((.*)%)")
    
    if not p then 
        p, f = string.match(msg, "^(.*) obtained an? (.*)")
        w = "N/A" 
    end

    if p and f then
        if string.sub(f, -1) == "!" or string.sub(f, -1) == "." then 
            f = string.sub(f, 1, -2) 
        end
        
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

local function SendWebhook(data, category)
    if not ScriptActive then return end
    if category == "SECRET" and not Settings.SecretEnabled then return end
    if category == "STONE" and not Settings.RubyEnabled then return end
    if category == "EVOLVED" and not Settings.EvolvedEnabled then return end 
    if category == "RAGE" and not Settings.LeviathanRageEnabled then return end 
    if category == "CRYSTALIZED" and not Settings.MutationCrystalized then return end 
    if category == "CAVECRYSTAL" and not Settings.CaveCrystalEnabled then return end 
    if category == "LEAVE" and not Settings.LeaveEnabled then return end 
    local TargetURL = ""; local contentMsg = ""; local realUser = GetUsername(data.Player)
    local discordId = nil
    for i = 1, 20 do if TagList[i][1] ~= "" and string.lower(TagList[i][1]) == string.lower(realUser) then discordId = TagList[i][2]; break end end
    if discordId and discordId ~= "" then if category == "LEAVE" then contentMsg = "User Left: <@" .. discordId .. ">" else contentMsg = "GG! <@" .. discordId .. ">" end end
    if category == "LEAVE" then TargetURL = Current_Webhook_Leave elseif category == "PLAYERS" then TargetURL = Current_Webhook_List else TargetURL = Current_Webhook_Fish end
    if not TargetURL or TargetURL == "" or string.find(TargetURL, "MASUKKAN_URL") then return end
    local embedTitle = ""; local embedColor = 3447003; local descriptionText = "" 
    local pName = Settings.SpoilerName and ("||`" .. data.Player .. "`||") or ("`" .. data.Player .. "`") 
    if category == "SECRET" then
        SessionStats.Secret = SessionStats.Secret + 1
        embedTitle = "Secret Caught!"
        embedColor = 3447003; local lines = { "⚓ Fish: " .. data.Item }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "🧬 Mutation: " .. data.Mutation) end
        table.insert(lines, "⚖️ Weight: " .. data.Weight); descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "STONE" then
        SessionStats.Ruby = SessionStats.Ruby + 1
        embedTitle = "Ruby Gemstone!"
        embedColor = 16753920; local lines = { "💎 Stone: " .. data.Item }
        if data.Mutation and data.Mutation ~= "None" then table.insert(lines, "✨ Mutation: " .. data.Mutation) end
        table.insert(lines, "⚖️ Weight: " .. data.Weight); descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "EVOLVED" then
        SessionStats.Evolved = SessionStats.Evolved + 1
        embedTitle = "Evolved Stone!"
        embedColor = 10181046 
        local lines = { "🔮 Item: " .. data.Item }
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "RAGE" then
        SessionStats.Rage = SessionStats.Rage + 1
        embedTitle = "LEVIATHAN RAGE!"
        embedColor = 10038562 
        local lines = { "🔥 Fish: " .. data.Item }
        table.insert(lines, "🧬 Mutation: Leviathan Rage")
        table.insert(lines, "⚖️ Weight: " .. data.Weight)
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "CRYSTALIZED" then
        SessionStats.Crystalized = SessionStats.Crystalized + 1
        embedTitle = "CRYSTALIZED MUTATION!"
        embedColor = 3407871
        local lines = { "💎 Fish: " .. data.Item }
        table.insert(lines, "✨ Mutation: Crystalized")
        table.insert(lines, "⚖️ Weight: " .. data.Weight)
        descriptionText = "Player: " .. pName .. "\n\n```\n" .. table.concat(lines, "\n") .. "\n```"
    elseif category == "LEAVE" then
        local dispName = data.DisplayName or data.Player; embedTitle = dispName .. " Left the server."; embedColor = 16711680; descriptionText = "Information\n👤 **@" .. data.Player .. "**" 
    elseif category == "PLAYERS" then
        embedTitle = "👥 List Player In Server"; embedColor = 5763719; descriptionText = "Information\n" .. data.ListText
    elseif category == "CAVECRYSTAL" then
        SessionStats.CaveCrystal = SessionStats.CaveCrystal + 1
        embedTitle = "💎 Cave Crystal Event!"; embedColor = 16776960; descriptionText = "Information\n" .. data.ListText
    end
    
    SessionStats.TotalSent = SessionStats.TotalSent + 1
    if UI_StatsLabels["TotalSent"] then UI_StatsLabels["TotalSent"].Text = tostring(SessionStats.TotalSent) end
    if UI_StatsLabels["Secret"] then UI_StatsLabels["Secret"].Text = tostring(SessionStats.Secret) end
    if UI_StatsLabels["Ruby"] then UI_StatsLabels["Ruby"].Text = tostring(SessionStats.Ruby) end
    if UI_StatsLabels["Evolved"] then UI_StatsLabels["Evolved"].Text = tostring(SessionStats.Evolved) end
    if UI_StatsLabels["Rage"] then UI_StatsLabels["Rage"].Text = tostring(SessionStats.Rage) end
    if UI_StatsLabels["Crystalized"] then UI_StatsLabels["Crystalized"].Text = tostring(SessionStats.Crystalized) end
    if UI_StatsLabels["CaveCrystal"] then UI_StatsLabels["CaveCrystal"].Text = tostring(SessionStats.CaveCrystal) end
    
    local embedData = { ["username"] = "XAL Notifications!", ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg", ["content"] = contentMsg, ["embeds"] = {{ ["title"] = embedTitle, ["description"] = descriptionText, ["color"] = embedColor, ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" } }} }
    pcall(function() httpRequest({ Url = TargetURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(embedData) }) end)
end


local function CheckAndSend(msg)
    if not ScriptActive then return end
    local cleanMsg = StripTags(msg); local lowerMsg = string.lower(cleanMsg)
    
    if string.find(lowerMsg, "evolved enchant stone") then
        local tempMsg = string.gsub(cleanMsg, "^%[Server%]:%s*", "") 
        local p = string.match(tempMsg, "^(.*) obtained an?")
        if p then 
            p = p:match("^%s*(.-)%s*$")
        else 
            p = "Unknown Player" 
        end
        
        local data = { Player = p, Item = "Evolved Enchant Stone", Mutation = "None", Weight = "N/A" }
        SendWebhook(data, "EVOLVED")
        return
    end

    if string.find(lowerMsg, "leviathan rage") then
        local p, item_full, w = string.match(cleanMsg, "^(.*) obtained a (.*) %((.*)%)")
        if p and item_full then
             local finalFishName = item_full
             local s_rage, e_rage = string.find(string.lower(item_full), "leviathan rage")
             if s_rage then
                 finalFishName = string.sub(item_full, e_rage + 1)
                 finalFishName = string.gsub(finalFishName, "^%s+", "")
             end
             local data = { Player = p, Item = finalFishName, Mutation = "Leviathan Rage", Weight = w }
             SendWebhook(data, "RAGE")
             return
        end
    end

    if string.find(lowerMsg, "crystalized") then
        local tempMsg = string.gsub(cleanMsg, "^%[Server%]:%s*", "")
        local p, item_full, w = string.match(tempMsg, "^(.*) obtained an? (.*) %((.*)%)")
        if not p then 
             p, item_full = string.match(tempMsg, "^(.*) obtained an? (.*)")
             w = "N/A"
        end

        if p and item_full then
             local finalItem = item_full
             local s, e = string.find(string.lower(item_full), "crystalized")
             if s then
                 finalItem = string.sub(item_full, e + 1)
                 finalItem = string.gsub(finalItem, "^%s+", "")
             end

             local check = string.lower(finalItem)
             if string.find(check, "bioluminescent manta ray") or string.find(check, "abyr squid") then
                 local data = { Player = p, Item = finalItem, Mutation = "Crystalized", Weight = w }
                 SendWebhook(data, "CRYSTALIZED")
                 return
             end
        end
    end

    if string.find(lowerMsg, "obtained an?") or string.find(lowerMsg, "chance!") then
        local data = ParseDataSmart(cleanMsg)
        if data then
            if data.Mutation and string.find(string.lower(data.Mutation), "crystalized") then
                SendWebhook(data, "CRYSTALIZED")
                return
            end

            if string.find(string.lower(data.Item), "evolved enchant stone") then
                SendWebhook(data, "EVOLVED")
                return
            end

            for _, name in pairs(StoneList) do
                if string.find(string.lower(data.Item), string.lower(name)) then
                    if string.find(string.lower(data.Item), "ruby") then
                        if data.Mutation and string.find(string.lower(data.Mutation), "gemstone") then SendWebhook(data, "STONE") end
                    else SendWebhook(data, "STONE") end
                    return
                end
            end
            for _, name in pairs(SecretList) do if string.find(string.lower(data.Item), string.lower(name)) then SendWebhook(data, "SECRET") return end end
        end
    end
end

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
    task.spawn(function() SendWebhook({ Player = p.Name, DisplayName = p.DisplayName }, "LEAVE") end) 
end))

table.insert(Connections, Players.PlayerAdded:Connect(function(p)
    if not ScriptActive then return end
    if Settings.ForeignDetection then
        local isWhitelisted = false
        local checkName = string.lower(p.Name)
        
        for i = 1, 20 do
             local wlName = TagList[i][1] or ""
             if wlName ~= "" and string.lower(wlName) == checkName then
                 isWhitelisted = true
                 break
             end
        end
        
        if not isWhitelisted then
            task.spawn(function()
                 if Current_Webhook_Admin == "" then return end
                 local adminTags = ""
                 
                 local id1 = (TagList[1] and TagList[1][2]) or ""
                 local id2 = (TagList[2] and TagList[2][2]) or ""
                 
                 if id1 ~= "" then adminTags = adminTags .. "<@" .. id1 .. "> " end
                 if id2 ~= "" then adminTags = adminTags .. "<@" .. id2 .. "> " end
                 
                 local contentStr = "Foreign Player Detected!" .. adminTags
                 local embed = {
                    ["username"] = "XAL Security",
                    ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
                    ["content"] = contentStr,
                    ["embeds"] = {{
                        ["title"] = "Player Information",
                        ["description"] = "Information\n```\nName: " .. p.DisplayName .. "\nUsername: " .. p.Name .. "\n```",
                        ["color"] = 16711680,
                        ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }
                    }}
                 }
                 pcall(function() 
                    httpRequest({ 
                        Url = Current_Webhook_Admin, 
                        Method = "POST", 
                        Headers = {["Content-Type"]="application/json"}, 
                        Body = HttpService:JSONEncode(embed) 
                    }) 
                 end)
            end)
        end
    end
end))

local targetPlaceId = game.PlaceId
local targetJobId = game.JobId
local function FastInfiniteRejoin()
    if not ScriptActive then return end
    print("🔄 XAL: Mencoba reconnect setiap 5 detik...")
    while ScriptActive do
        local success, err = pcall(function() TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, game.Players.LocalPlayer) end)
        if success then print("✅ XAL: Perintah reconnect berhasil dikirim!") break else warn("⚠️ XAL: Gagal, mencoba lagi dalam 5 detik...") end
        task.wait(5)
    end
end

local function SendDisconnectWebhook(reason)
    if not ScriptActive then return end
    if Current_Webhook_List == "" then return end
    if tick() - LastDisconnectTime < 30 then 
        print("⚠️ XAL: Disconnect Webhook Cooldown Active")
        return 
    end
    LastDisconnectTime = tick()
    
    print("⚠️ XAL: Sending Disconnect Webhook (Reason: " .. tostring(reason) .. ")")
    
    local adminTags = ""
    local id1 = (TagList[1] and TagList[1][2]) or ""
    local id2 = (TagList[2] and TagList[2][2]) or ""
    
    if id1 ~= "" then adminTags = adminTags .. "<@" .. id1 .. "> " end
    if id2 ~= "" then adminTags = adminTags .. "<@" .. id2 .. "> " end

    local contentMsg = ""
    if adminTags ~= "" then 
        contentMsg = "**DISCONNECT ALERT:** " .. adminTags 
    end
    
    local embed = {
        ["username"] = "XAL Notifications!",
        ["avatar_url"] = "https://i.imgur.com/GWx0mX9.jpeg",
        ["content"] = contentMsg,
        ["embeds"] = {{
            ["title"] = "LocalPlayer Disconnected",
            ["description"] = "Information\nUser: **" .. Players.LocalPlayer.Name .. "** (@" .. Players.LocalPlayer.DisplayName .. ") has disconnected.\n**Reason:** " .. tostring(reason),
            ["color"] = 16711680,
            ["footer"] = { ["text"] = "XAL Server Monitoring | bit.ly/xalserver", ["icon_url"] = "https://i.imgur.com/GWx0mX9.jpeg" }
        }}
    }
    
    pcall(function() 
        httpRequest({ 
            Url = Current_Webhook_List, 
            Method = "POST", 
            Headers = {["Content-Type"]="application/json"}, 
            Body = HttpService:JSONEncode(embed) 
        }) 
    end)
end

table.insert(Connections, GuiService.ErrorMessageChanged:Connect(function(errMsg) 
    if not ScriptActive then return end
    if errMsg and errMsg ~= "" then
        SendDisconnectWebhook("Error Message: " .. errMsg)
    end
    task.wait(2); FastInfiniteRejoin() 
end))

local promptOverlay = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 5)
if promptOverlay then
    promptOverlay = promptOverlay:WaitForChild("promptOverlay", 5)
end

if promptOverlay then
    table.insert(Connections, promptOverlay.ChildAdded:Connect(function(child) 
        if not ScriptActive then return end
        if child.Name == "ErrorPrompt" then 
            SendDisconnectWebhook("Error Prompt Detected")
            task.wait(2); FastInfiniteRejoin() 
        end 
    end))
end

game:BindToClose(function()
    SendDisconnectWebhook("Script/Game Closed Gracefully")
    task.wait(1)
end)

local CaveCrystalDebounce = 0
local function StartInventoryWatcher()
    local Backpack = Players.LocalPlayer:WaitForChild("Backpack", 10)
    if not Backpack then return end

    table.insert(Connections, Backpack.ChildAdded:Connect(function(child)
        if not ScriptActive then return end
        if child.Name == "Cave Crystal" then 
             if tick() - CaveCrystalDebounce > 10 then
                 CaveCrystalDebounce = tick()
                 SendWebhook({ Player = Players.LocalPlayer.Name, ListText = "⛏️ **Found a Cave Crystal!**" }, "CAVECRYSTAL")
             end
        end
    end))
end
task.spawn(StartInventoryWatcher)

print("✅ XAL System Session v1.3 Loaded!")

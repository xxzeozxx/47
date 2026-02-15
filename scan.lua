
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Fungsi untuk membuat UI
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TeleportCoordGetter"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Coba masukkan ke CoreGui agar tidak hilang saat mati, jika executor mendukung
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    MainFrame.Size = UDim2.new(0, 300, 0, 250)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local UICorner = Instance.new("UICorner")
    UICorner.Parent = MainFrame
    UICorner.CornerRadius = UDim.new(0, 8)

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = MainFrame
    UIStroke.Color = Color3.fromRGB(0, 170, 255)
    UIStroke.Thickness = 2

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1.000
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Get Teleport Coordinates"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18.000

    -- Input Nama Lokasi
    local NameInput = Instance.new("TextBox")
    NameInput.Parent = MainFrame
    NameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    NameInput.Position = UDim2.new(0.05, 0, 0.2, 0)
    NameInput.Size = UDim2.new(0.9, 0, 0, 35)
    NameInput.Font = Enum.Font.Gotham
    NameInput.PlaceholderText = "Enter Location Name (e.g. Secret Spot)"
    NameInput.Text = ""
    NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameInput.TextSize = 14.000
    
    local NICorner = Instance.new("UICorner")
    NICorner.Parent = NameInput
    NICorner.CornerRadius = UDim.new(0, 6)

    -- Tombol Copy
    local CopyButton = Instance.new("TextButton")
    CopyButton.Parent = MainFrame
    CopyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    CopyButton.Position = UDim2.new(0.05, 0, 0.4, 0)
    CopyButton.Size = UDim2.new(0.9, 0, 0, 40)
    CopyButton.Font = Enum.Font.GothamBold
    CopyButton.Text = "Get Coordinates"
    CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyButton.TextSize = 16.000
    
    local CBCorner = Instance.new("UICorner")
    CBCorner.Parent = CopyButton
    CBCorner.CornerRadius = UDim.new(0, 6)

    -- Output Text Box (Agar bisa dicopy manual di HP)
    local OutputBox = Instance.new("TextBox")
    OutputBox.Parent = MainFrame
    OutputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    OutputBox.Position = UDim2.new(0.05, 0, 0.6, 0)
    OutputBox.Size = UDim2.new(0.9, 0, 0, 60)
    OutputBox.Font = Enum.Font.Code
    OutputBox.Text = "Coordinates will appear here..."
    OutputBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    OutputBox.TextSize = 12.000
    OutputBox.TextWrapped = true
    OutputBox.ClearTextOnFocus = false
    OutputBox.TextEditable = false -- User hanya bisa select/copy
    
    local OBCorner = Instance.new("UICorner")
    OBCorner.Parent = OutputBox
    OBCorner.CornerRadius = UDim.new(0, 6)
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.BackgroundTransparency = 1.000
    StatusLabel.Position = UDim2.new(0, 0, 0.88, 0)
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 12.000

    -- Tombol Close
    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = MainFrame
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseButton.Position = UDim2.new(1, -30, 0, 5)
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 14.000
    
    local CLCorner = Instance.new("UICorner")
    CLCorner.Parent = CloseButton
    CLCorner.CornerRadius = UDim.new(0, 4)
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Fungsi untuk mengambil kordinat
    CopyButton.MouseButton1Click:Connect(function()
        local Character = Players.LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local HRP = Character.HumanoidRootPart
            local Pos = HRP.Position
            local Look = HRP.CFrame.LookVector
            
            local LocationName = NameInput.Text
            if LocationName == "" or LocationName == " " then 
                LocationName = "Location_" .. tostring(math.random(1000,9999)) 
            end
            
            -- Format sesuai dengan script 47.lua
            -- ["Name"] = {Pos = Vector3.new(x, y, z), Look = Vector3.new(x, y, z)},
            
            local PosString = string.format("Vector3.new(%.3f, %.3f, %.3f)", Pos.X, Pos.Y, Pos.Z)
            local LookString = string.format("Vector3.new(%.3f, %.3f, %.3f)", Look.X, Look.Y, Look.Z)
            
            local FinalString = string.format('["%s"] = {Pos = %s, Look = %s},', LocationName, PosString, LookString)
            
            -- Tampilkan di OutputBox agar user HP bisa copy manual
            OutputBox.Text = FinalString
            OutputBox.TextEditable = true -- Biarkan user select text
            OutputBox:CaptureFocus() -- Fokus ke box agar keyboard muncul/bisa langsung select
            
            -- Coba copy ke clipboard juga sebagai backup
            if setclipboard then
                pcall(function() setclipboard(FinalString) end)
                StatusLabel.Text = "Copied to Clipboard & Displayed above!"
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            else
                StatusLabel.Text = "Displayed above! Please copy manually."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
            
            task.delay(3, function()
                StatusLabel.Text = "Ready"
                StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            end)
        else
            StatusLabel.Text = "Error: Character/RootPart not found!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end

CreateUI()

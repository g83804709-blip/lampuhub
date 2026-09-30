-- ============================================
-- PETAPETA PVP: CLOWN MENU HACK
-- Speed Level System + ESP Toggle (Player/Monster)
-- Berdasarkan scan game ID 125297666294119
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- KONFIGURASI
-- ============================================
local CONFIG = {
    SpeedLevel = 1,
    ESPPlayer = false,
    ESPMonster = true,
    ESPItem = false,
    ESPHideSpot = false,
    ESPRange = 800,
    ESPColorMonster = Color3.fromRGB(255, 0, 0),
    ESPColorItem = Color3.fromRGB(0, 255, 0),
    ESPColorPlayer = Color3.fromRGB(0, 150, 255),
    ESPColorSafe = Color3.fromRGB(255, 255, 0)
}

-- Speed per level (makin tinggi makin cepet)
local SPEED_LEVELS = {
    [1] = {speed = 16, jump = 50},
    [2] = {speed = 30, jump = 70},
    [3] = {speed = 50, jump = 100},
    [4] = {speed = 80, jump = 130},
    [5] = {speed = 120, jump = 160},
    [6] = {speed = 180, jump = 200},
    [7] = {speed = 250, jump = 250},
    [8] = {speed = 350, jump = 300},
    [9] = {speed = 500, jump = 350},
    [10] = {speed = 700, jump = 400},
}

-- ============================================
-- SPEED HACK (via RemoteEvent SetWalkSpeed)
-- ============================================
local function ApplySpeed()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    local level = SPEED_LEVELS[CONFIG.SpeedLevel]
    if not level then return end

    -- Server-side speed via remote
    local setSpeedRemote = ReplicatedStorage:FindFirstChild("SetWalkSpeed")
    if setSpeedRemote then
        pcall(function()
            setSpeedRemote:FireServer(level.speed)
        end)
    end

    -- Client-side speed
    hum.WalkSpeed = level.speed
    hum.JumpPower = level.jump
    hum.UseJumpPower = true
end

ApplySpeed()

LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    ApplySpeed()
    task.spawn(function()
        while char.Parent do
            task.wait(3)
            pcall(ApplySpeed)
        end
    end)
end)

-- ============================================
-- ESP SYSTEM
-- ============================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PetaPetaESP"
ESPFolder.Parent = Workspace

local espObjects = {}

local function CreateESP(object, color, label)
    if not object or not object:IsA("BasePart") then return end
    if espObjects[object] then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_" .. object.Name
    box.Adornee = object
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = object.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Color3 = color
    box.Transparency = 0.5
    box.Parent = ESPFolder
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPLabel"
    billboard.Adornee = object
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ESPFolder
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = color
    text.TextStrokeTransparency = 0
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
    
    espObjects[object] = {box = box, billboard = billboard}
end

local function RemoveESP(object)
    if espObjects[object] then
        if espObjects[object].box then espObjects[object].box:Destroy() end
        if espObjects[object].billboard then espObjects[object].billboard:Destroy() end
        espObjects[object] = nil
    end
end

local function ClearAllESP()
    for obj, _ in pairs(espObjects) do
        RemoveESP(obj)
    end
end

local function GetBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj:FindFirstChildWhichIsA("BasePart") end
    return nil
end

local function ScanObjects()
    if not CONFIG.ESPPlayer and not CONFIG.ESPMonster and not CONFIG.ESPItem and not CONFIG.ESPHideSpot then return end
    
    -- 1. ESP MONSTER
    if CONFIG.ESPMonster then
        local enemyFolder = Workspace:FindFirstChild("DummyEnemy")
        if enemyFolder then
            for _, obj in pairs(enemyFolder:GetChildren()) do
                local part = GetBasePart(obj)
                if part then
                    CreateESP(part, CONFIG.ESPColorMonster, "MONSTER: " .. obj.Name)
                end
            end
        end
        -- Deteksi monster via nama
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("petapeta") or name:find("monster") or name:find("ghost") 
                   or name:find("hantu") or name:find("evil") or name:find("enemy") then
                    CreateESP(obj, CONFIG.ESPColorMonster, "MONSTER: " .. obj.Name)
                end
            end
        end
    end
    
    -- 2. ESP ITEM
    if CONFIG.ESPItem then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("ofuda") or name:find("pill") or name:find("cracker") 
                   or name:find("spirit") or name:find("item") or name:find("pickup")
                   or name:find("key") or name:find("kunci") or name:find("hint")
                   or name:find("paper") or name:find("doll") then
                    CreateESP(obj, CONFIG.ESPColorItem, "ITEM: " .. obj.Name)
                end
            end
        end
    end
    
    -- 3. ESP HIDE SPOT
    if CONFIG.ESPHideSpot then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("hidepoint") or name:find("hidetansu") or name:find("p_in") then
                    CreateESP(obj, CONFIG.ESPColorSafe, "HIDE: " .. obj.Name)
                end
            end
        end
    end
    
    -- 4. ESP PLAYER
    if CONFIG.ESPPlayer then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    CreateESP(hrp, CONFIG.ESPColorPlayer, player.Name)
                end
            end
        end
    end
end

task.wait(2)
ScanObjects()

task.spawn(function()
    while true do
        task.wait(5)
        pcall(ScanObjects)
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(2)
        if CONFIG.ESPPlayer then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                CreateESP(hrp, CONFIG.ESPColorPlayer, player.Name)
            end
        end
    end)
end)

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.5)
    pcall(ScanObjects)
end)

-- ============================================
-- CLOWN MENU GUI 🤡
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ClownMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

-- Tombol Clown (toggle menu)
local ClownButton = Instance.new("TextButton")
ClownButton.Size = UDim2.new(0, 60, 0, 60)
ClownButton.Position = UDim2.new(0, 20, 0.5, -30)
ClownButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ClownButton.BorderSizePixel = 0
ClownButton.Text = "🤡"
ClownButton.TextSize = 36
ClownButton.Font = Enum.Font.GothamBold
ClownButton.Parent = ScreenGui

local ClownCorner = Instance.new("UICorner")
ClownCorner.CornerRadius = UDim.new(0, 30)
ClownCorner.Parent = ClownButton

local ClownStroke = Instance.new("UIStroke")
ClownStroke.Color = Color3.fromRGB(255, 255, 255)
ClownStroke.Thickness = 2
ClownStroke.Parent = ClownButton

-- Main Menu Frame (bentuk clown face)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 420)
MainFrame.Position = UDim2.new(0, 90, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 245, 240)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 50, 50)
MainStroke.Thickness = 3
MainStroke.Parent = MainFrame

-- Header Clown (mata + hidung)
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 80)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
HeaderFrame.BorderSizePixel = 0
HeaderFrame.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 20)
HeaderCorner.Parent = HeaderFrame

-- Mata kiri
local EyeLeft = Instance.new("TextLabel")
EyeLeft.Size = UDim2.new(0, 30, 0, 30)
EyeLeft.Position = UDim2.new(0.15, 0, 0.15, 0)
EyeLeft.BackgroundTransparency = 1
EyeLeft.Text = "👁"
EyeLeft.TextSize = 24
EyeLeft.Parent = HeaderFrame

-- Mata kanan
local EyeRight = Instance.new("TextLabel")
EyeRight.Size = UDim2.new(0, 30, 0, 30)
EyeRight.Position = UDim2.new(0.7, 0, 0.15, 0)
EyeRight.BackgroundTransparency = 1
EyeRight.Text = "👁"
EyeRight.TextSize = 24
EyeRight.Parent = HeaderFrame

-- Hidung
local Nose = Instance.new("TextLabel")
Nose.Size = UDim2.new(0, 30, 0, 30)
Nose.Position = UDim2.new(0.42, 0, 0.35, 0)
Nose.BackgroundTransparency = 1
Nose.Text = "🔴"
Nose.TextSize = 20
Nose.Parent = HeaderFrame

-- Judul
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.Position = UDim2.new(0, 0, 0.7, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🤡 CLOWN HACK 🤡"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = HeaderFrame

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = HeaderFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- ============================================
-- SPEED LEVEL SECTION
-- ============================================
local SpeedSection = Instance.new("Frame")
SpeedSection.Size = UDim2.new(1, -20, 0, 90)
SpeedSection.Position = UDim2.new(0, 10, 0, 90)
SpeedSection.BackgroundColor3 = Color3.fromRGB(255, 230, 230)
SpeedSection.BorderSizePixel = 0
SpeedSection.Parent = MainFrame

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 10)
SpeedCorner.Parent = SpeedSection

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 25)
SpeedLabel.Position = UDim2.new(0, 0, 0, 5)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "⚡ SPEED LEVEL ⚡"
SpeedLabel.TextColor3 = Color3.fromRGB(200, 30, 30)
SpeedLabel.TextSize = 13
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.Parent = SpeedSection

-- Speed Slider (level display)
local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Size = UDim2.new(0, 80, 0, 25)
SpeedDisplay.Position = UDim2.new(0.5, -40, 0, 30)
SpeedDisplay.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
SpeedDisplay.BorderSizePixel = 0
SpeedDisplay.Text = "Lv 1"
SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedDisplay.TextSize = 14
SpeedDisplay.Font = Enum.Font.GothamBold
SpeedDisplay.Parent = SpeedSection

local SpeedDisplayCorner = Instance.new("UICorner")
SpeedDisplayCorner.CornerRadius = UDim.new(0, 6)
SpeedDisplayCorner.Parent = SpeedDisplay

-- Minus Button
local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 35, 0, 35)
MinusBtn.Position = UDim2.new(0, 10, 0, 30)
MinusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MinusBtn.BorderSizePixel = 0
MinusBtn.Text = "−"
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.TextSize = 20
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.Parent = SpeedSection

local MinusCorner = Instance.new("UICorner")
MinusCorner.CornerRadius = UDim.new(0, 8)
MinusCorner.Parent = MinusBtn

-- Plus Button
local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 35, 0, 35)
PlusBtn.Position = UDim2.new(1, -45, 0, 30)
PlusBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
PlusBtn.BorderSizePixel = 0
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.TextSize = 20
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.Parent = SpeedSection

local PlusCorner = Instance.new("UICorner")
PlusCorner.CornerRadius = UDim.new(0, 8)
PlusCorner.Parent = PlusBtn

-- Speed Info
local SpeedInfo = Instance.new("TextLabel")
SpeedInfo.Size = UDim2.new(1, 0, 0, 20)
SpeedInfo.Position = UDim2.new(0, 0, 0, 68)
SpeedInfo.BackgroundTransparency = 1
SpeedInfo.Text = "Speed: 16 | Jump: 50"
SpeedInfo.TextColor3 = Color3.fromRGB(100, 100, 100)
SpeedInfo.TextSize = 11
SpeedInfo.Font = Enum.Font.Gotham
SpeedInfo.Parent = SpeedSection

local function UpdateSpeedDisplay()
    local level = SPEED_LEVELS[CONFIG.SpeedLevel]
    SpeedDisplay.Text = "Lv " .. CONFIG.SpeedLevel
    SpeedInfo.Text = "Speed: " .. level.speed .. " | Jump: " .. level.jump
    ApplySpeed()
end

MinusBtn.MouseButton1Click:Connect(function()
    if CONFIG.SpeedLevel > 1 then
        CONFIG.SpeedLevel = CONFIG.SpeedLevel - 1
        UpdateSpeedDisplay()
    end
end)

PlusBtn.MouseButton1Click:Connect(function()
    if CONFIG.SpeedLevel < 10 then
        CONFIG.SpeedLevel = CONFIG.SpeedLevel + 1
        UpdateSpeedDisplay()
    end
end)

-- ============================================
-- ESP SECTION
-- ============================================
local ESPSection = Instance.new("Frame")
ESPSection.Size = UDim2.new(1, -20, 0, 230)
ESPSection.Position = UDim2.new(0, 10, 0, 190)
ESPSection.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
ESPSection.BorderSizePixel = 0
ESPSection.Parent = MainFrame

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 10)
ESPCorner.Parent = ESPSection

local ESPLabel = Instance.new("TextLabel")
ESPLabel.Size = UDim2.new(1, 0, 0, 25)
ESPLabel.Position = UDim2.new(0, 0, 0, 5)
ESPLabel.BackgroundTransparency = 1
ESPLabel.Text = "👁 ESP SETTINGS 👁"
ESPLabel.TextColor3 = Color3.fromRGB(30, 30, 150)
ESPLabel.TextSize = 13
ESPLabel.Font = Enum.Font.GothamBold
ESPLabel.Parent = ESPSection

local function CreateToggle(text, yPos, initial, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 35)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BorderSizePixel = 0
    container.Parent = ESPSection
    
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(50, 50, 50)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 60, 0, 25)
    toggle.Position = UDim2.new(1, -70, 0.5, -12)
    toggle.BackgroundColor3 = initial and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = initial and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = container
    
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 12)
    tCorner.Parent = toggle
    
    toggle.MouseButton1Click:Connect(function()
        local state = toggle.Text == "ON"
        local newState = not state
        toggle.Text = newState and "ON" or "OFF"
        toggle.BackgroundColor3 = newState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        callback(newState)
    end)
    
    return toggle
end

CreateToggle("ESP Player", 35, CONFIG.ESPPlayer, function(state)
    CONFIG.ESPPlayer = state
    if not state then
        for obj, _ in pairs(espObjects) do
            if obj.Parent and obj.Parent:IsA("Model") and obj.Parent:FindFirstChild("Humanoid") then
                RemoveESP(obj)
            end
        end
    else
        ScanObjects()
    end
end)

CreateToggle("ESP Monster", 75, CONFIG.ESPMonster, function(state)
    CONFIG.ESPMonster = state
    if not state then
        for obj, _ in pairs(espObjects) do
            if espObjects[obj] and espObjects[obj].billboard then
                local txt = espObjects[obj].billboard:FindFirstChild("TextLabel")
                if txt and txt.Text:find("MONSTER") then
                    RemoveESP(obj)
                end
            end
        end
    else
        ScanObjects()
    end
end)

CreateToggle("ESP Item", 115, CONFIG.ESPItem, function(state)
    CONFIG.ESPItem = state
    if not state then
        for obj, _ in pairs(espObjects) do
            if espObjects[obj] and espObjects[obj].billboard then
                local txt = espObjects[obj].billboard:FindFirstChild("TextLabel")
                if txt and txt.Text:find("ITEM") then
                    RemoveESP(obj)
                end
            end
        end
    else
        ScanObjects()
    end
end)

CreateToggle("ESP Hide Spot", 155, CONFIG.ESPHideSpot, function(state)
    CONFIG.ESPHideSpot = state
    if not state then
        for obj, _ in pairs(espObjects) do
            if espObjects[obj] and espObjects[obj].billboard then
                local txt = espObjects[obj].billboard:FindFirstChild("TextLabel")
                if txt and txt.Text:find("HIDE") then
                    RemoveESP(obj)
                end
            end
        end
    else
        ScanObjects()
    end
end)

-- Unload Button
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0.9, 0, 0, 30)
UnloadBtn.Position = UDim2.new(0.05, 0, 0, 195)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
UnloadBtn.BorderSizePixel = 0
UnloadBtn.Text = "UNLOAD SCRIPT"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadBtn.TextSize = 12
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.Parent = ESPSection

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 8)
UnloadCorner.Parent = UnloadBtn

UnloadBtn.MouseButton1Click:Connect(function()
    ClearAllESP()
    ScreenGui:Destroy()
end)

-- ============================================
-- TOGGLE MENU DENGAN TOMBOL CLOWN
-- ============================================
local menuOpen = false

ClownButton.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    MainFrame.Visible = menuOpen
    
    if menuOpen then
        -- Animasi muncul
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0, 90, 0.5, -210)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 420)
        }):Play()
    end
end)

-- ============================================
-- HOTKEY
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- F1: Speed Up
    if input.KeyCode == Enum.KeyCode.F1 then
        if CONFIG.SpeedLevel < 10 then
            CONFIG.SpeedLevel = CONFIG.SpeedLevel + 1
            UpdateSpeedDisplay()
        end
    end
    
    -- F2: Speed Down
    if input.KeyCode == Enum.KeyCode.F2 then
        if CONFIG.SpeedLevel > 1 then
            CONFIG.SpeedLevel = CONFIG.SpeedLevel - 1
            UpdateSpeedDisplay()
        end
    end
    
    -- F3: Toggle ESP Player
    if input.KeyCode == Enum.KeyCode.F3 then
        CONFIG.ESPPlayer = not CONFIG.ESPPlayer
        if CONFIG.ESPPlayer then ScanObjects() end
    end
    
    -- F4: Toggle ESP Monster
    if input.KeyCode == Enum.KeyCode.F4 then
        CONFIG.ESPMonster = not CONFIG.ESPMonster
        if CONFIG.ESPMonster then ScanObjects() end
    end
    
    -- RightControl: Toggle Menu
    if input.KeyCode == Enum.KeyCode.RightControl then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
    end
end)

print("[READY] 🤡 CLOWN MENU PETAPETA PVP aktif!")
print("[HOTKEY] F1 = Speed Up | F2 = Speed Down")
print("[HOTKEY] F3 = ESP Player | F4 = ESP Monster")
print("[HOTKEY] RightControl = Toggle Menu")
print("[INFO] Speed Level 1-10 | ESP Player/Monster/Item/HideSpot")

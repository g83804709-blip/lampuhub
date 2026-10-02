-- ============================================
-- PETAPETA PVP: 🤡 MENU + SPEED + ESP + LOW GFX
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local LP = Players.LocalPlayer

-- ============================================
-- KONFIGURASI
-- ============================================
local CONFIG = {
    SpeedLevel = 3,
    ESPMonster = true,
    ESPPlayer = false,
    LowGFX = false,
}

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

-- Simpan setting awal buat restore
local ORIGINAL_LIGHTING = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}

-- ============================================
-- SPEED
-- ============================================
local lastRemoteSent = 0

local function ApplySpeed()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    local level = SPEED_LEVELS[CONFIG.SpeedLevel]
    if not level then return end

    hum.WalkSpeed = level.speed
    hum.JumpPower = level.jump
    hum.UseJumpPower = true

    local now = tick()
    if now - lastRemoteSent > 5 then
        lastRemoteSent = now
        local remote = ReplicatedStorage:FindFirstChild("SetWalkSpeed")
        if remote then
            pcall(function() remote:FireServer(level.speed) end)
        end
    end
end

ApplySpeed()
LP.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySpeed()
end)

task.spawn(function()
    while true do
        task.wait(5)
        pcall(ApplySpeed)
    end
end)

-- ============================================
-- LOW GRAPHICS MODE
-- ============================================
local function SetLowGFX()
    CONFIG.LowGFX = true

    -- Lighting
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.ClockTime = 14

    -- Hapus efek post-processing
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
            pcall(function() obj:Destroy() end)
        end
    end

    -- Terrain: matiin dekorasi
    if Terrain then
        pcall(function()
            Terrain.Decoration = false
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end)
    end

    -- Matiin semua ParticleEmitter, Trail, Beam, Smoke, Fire, Sparkles
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
               or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")
               or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj.Enabled = false
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            end
        end)
    end

    -- Setting render Roblox
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function RestoreGFX()
    CONFIG.LowGFX = false
    Lighting.Ambient = ORIGINAL_LIGHTING.Ambient
    Lighting.OutdoorAmbient = ORIGINAL_LIGHTING.OutdoorAmbient
    Lighting.Brightness = ORIGINAL_LIGHTING.Brightness
    Lighting.GlobalShadows = ORIGINAL_LIGHTING.GlobalShadows
    Lighting.FogEnd = ORIGINAL_LIGHTING.FogEnd
    Lighting.FogStart = ORIGINAL_LIGHTING.FogStart
    Lighting.EnvironmentDiffuseScale = ORIGINAL_LIGHTING.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = ORIGINAL_LIGHTING.EnvironmentSpecularScale

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
end

-- ============================================
-- ESP
-- ============================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PetaPetaESP"
ESPFolder.Parent = Workspace

local espObjects = {}

local function CreateESP(part, color)
    if not part or not part:IsA("BasePart") then return end
    if espObjects[part] then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = part.Size + Vector3.new(0.4, 0.4, 0.4)
    box.Color3 = color
    box.Transparency = 0.5
    box.Parent = ESPFolder

    espObjects[part] = box
end

local function ClearAllESP()
    for part, box in pairs(espObjects) do
        if box then box:Destroy() end
    end
    espObjects = {}
end

local function ScanMonster()
    local folder = Workspace:FindFirstChild("DummyEnemy")
    if folder then
        for _, obj in pairs(folder:GetChildren()) do
            if obj:IsA("Model") then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    CreateESP(part, Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end
end

local function ScanPlayer()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                CreateESP(hrp, Color3.fromRGB(0, 150, 255))
            end
        end
    end
end

local function ScanAll()
    if CONFIG.ESPMonster then pcall(ScanMonster) end
    if CONFIG.ESPPlayer then pcall(ScanPlayer) end
end

task.wait(2)
pcall(ScanAll)

task.spawn(function()
    while true do
        task.wait(6)
        pcall(ScanAll)
    end
end)

-- ============================================
-- GUI: TOMBOL 🤡 + MENU
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PetaPetaMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

-- Tombol Clown (emoji di tengah)
local ClownButton = Instance.new("TextButton")
ClownButton.Size = UDim2.new(0, 60, 0, 60)
ClownButton.Position = UDim2.new(0, 20, 0.5, -30)
ClownButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
ClownButton.BorderSizePixel = 0
ClownButton.Text = "🤡"
ClownButton.TextSize = 36
ClownButton.Font = Enum.Font.GothamBold
ClownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClownButton.AutoButtonColor = false
ClownButton.Parent = ScreenGui

local ClownCorner = Instance.new("UICorner")
ClownCorner.CornerRadius = UDim.new(0, 30)
ClownCorner.Parent = ClownButton

local ClownStroke = Instance.new("UIStroke")
ClownStroke.Color = Color3.fromRGB(255, 255, 255)
ClownStroke.Thickness = 2
ClownStroke.Parent = ClownButton

-- Main Menu
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 300)
MainFrame.Position = UDim2.new(0, 90, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 80, 80)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
Header.BorderSizePixel = 0
Header.Text = "🤡 PETAPETA MENU"
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.TextSize = 15
Header.Font = Enum.Font.GothamBold
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Speed Section
local SpeedBox = Instance.new("Frame")
SpeedBox.Size = UDim2.new(1, -20, 0, 90)
SpeedBox.Position = UDim2.new(0, 10, 0, 45)
SpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SpeedBox.BorderSizePixel = 0
SpeedBox.Parent = MainFrame

local SpeedBoxCorner = Instance.new("UICorner")
SpeedBoxCorner.CornerRadius = UDim.new(0, 10)
SpeedBoxCorner.Parent = SpeedBox

local SpeedTitle = Instance.new("TextLabel")
SpeedTitle.Size = UDim2.new(1, 0, 0, 20)
SpeedTitle.Position = UDim2.new(0, 0, 0, 5)
SpeedTitle.BackgroundTransparency = 1
SpeedTitle.Text = "⚡ SPEED LEVEL"
SpeedTitle.TextColor3 = Color3.fromRGB(255, 200, 200)
SpeedTitle.TextSize = 12
SpeedTitle.Font = Enum.Font.GothamBold
SpeedTitle.Parent = SpeedBox

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 40, 0, 40)
MinusBtn.Position = UDim2.new(0, 15, 0, 30)
MinusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MinusBtn.BorderSizePixel = 0
MinusBtn.Text = "−"
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.TextSize = 22
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.Parent = SpeedBox

local MinusCorner = Instance.new("UICorner")
MinusCorner.CornerRadius = UDim.new(0, 10)
MinusCorner.Parent = MinusBtn

local LevelDisplay = Instance.new("TextLabel")
LevelDisplay.Size = UDim2.new(0, 90, 0, 40)
LevelDisplay.Position = UDim2.new(0.5, -45, 0, 30)
LevelDisplay.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
LevelDisplay.BorderSizePixel = 0
LevelDisplay.Text = "Lv 3"
LevelDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
LevelDisplay.TextSize = 16
LevelDisplay.Font = Enum.Font.GothamBold
LevelDisplay.Parent = SpeedBox

local LevelCorner = Instance.new("UICorner")
LevelCorner.CornerRadius = UDim.new(0, 10)
LevelCorner.Parent = LevelDisplay

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 40, 0, 40)
PlusBtn.Position = UDim2.new(1, -55, 0, 30)
PlusBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
PlusBtn.BorderSizePixel = 0
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.TextSize = 22
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.Parent = SpeedBox

local PlusCorner = Instance.new("UICorner")
PlusCorner.CornerRadius = UDim.new(0, 10)
PlusCorner.Parent = PlusBtn

local SpeedInfo = Instance.new("TextLabel")
SpeedInfo.Size = UDim2.new(1, 0, 0, 15)
SpeedInfo.Position = UDim2.new(0, 0, 0, 72)
SpeedInfo.BackgroundTransparency = 1
SpeedInfo.Text = "Speed: 50 | Jump: 100"
SpeedInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
SpeedInfo.TextSize = 10
SpeedInfo.Font = Enum.Font.Gotham
SpeedInfo.Parent = SpeedBox

local function UpdateSpeedDisplay()
    local level = SPEED_LEVELS[CONFIG.SpeedLevel]
    LevelDisplay.Text = "Lv " .. CONFIG.SpeedLevel
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

-- ESP Section
local ESPBox = Instance.new("Frame")
ESPBox.Size = UDim2.new(1, -20, 0, 105)
ESPBox.Position = UDim2.new(0, 10, 0, 145)
ESPBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ESPBox.BorderSizePixel = 0
ESPBox.Parent = MainFrame

local ESPBoxCorner = Instance.new("UICorner")
ESPBoxCorner.CornerRadius = UDim.new(0, 10)
ESPBoxCorner.Parent = ESPBox

local ESPTitle = Instance.new("TextLabel")
ESPTitle.Size = UDim2.new(1, 0, 0, 20)
ESPTitle.Position = UDim2.new(0, 0, 0, 5)
ESPTitle.BackgroundTransparency = 1
ESPTitle.Text = "👁 ESP"
ESPTitle.TextColor3 = Color3.fromRGB(200, 220, 255)
ESPTitle.TextSize = 12
ESPTitle.Font = Enum.Font.GothamBold
ESPTitle.Parent = ESPBox

local function CreateToggle(parent, text, yPos, initial, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 30)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 55, 0, 24)
    toggle.Position = UDim2.new(1, -55, 0.5, -12)
    toggle.BackgroundColor3 = initial and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 100)
    toggle.BorderSizePixel = 0
    toggle.Text = initial and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 11
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 10)
    tCorner.Parent = toggle

    toggle.MouseButton1Click:Connect(function()
        local state = toggle.Text == "ON"
        local newState = not state
        toggle.Text = newState and "ON" or "OFF"
        toggle.BackgroundColor3 = newState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 100)
        callback(newState)
    end)
end

CreateToggle(ESPBox, "ESP Monster", 28, CONFIG.ESPMonster, function(state)
    CONFIG.ESPMonster = state
    if state then pcall(ScanMonster) end
end)

CreateToggle(ESPBox, "ESP Player", 60, CONFIG.ESPPlayer, function(state)
    CONFIG.ESPPlayer = state
    if state then pcall(ScanPlayer) end
end)

-- Low GFX Button
local LowGfxBtn = Instance.new("TextButton")
LowGfxBtn.Size = UDim2.new(0.9, 0, 0, 30)
LowGfxBtn.Position = UDim2.new(0.05, 0, 0, 255)
LowGfxBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
LowGfxBtn.BorderSizePixel = 0
LowGfxBtn.Text = "LOW GRAPHICS: OFF"
LowGfxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LowGfxBtn.TextSize = 11
LowGfxBtn.Font = Enum.Font.GothamBold
LowGfxBtn.Parent = MainFrame

local LowGfxCorner = Instance.new("UICorner")
LowGfxCorner.CornerRadius = UDim.new(0, 8)
LowGfxCorner.Parent = LowGfxBtn

LowGfxBtn.MouseButton1Click:Connect(function()
    if CONFIG.LowGFX then
        RestoreGFX()
        LowGfxBtn.Text = "LOW GRAPHICS: OFF"
        LowGfxBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
    else
        SetLowGFX()
        LowGfxBtn.Text = "LOW GRAPHICS: ON"
        LowGfxBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    end
end)

-- Unload Button
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0.9, 0, 0, 28)
UnloadBtn.Position = UDim2.new(0.05, 0, 0, 290)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
UnloadBtn.BorderSizePixel = 0
UnloadBtn.Text = "UNLOAD"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadBtn.TextSize = 11
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.Parent = MainFrame

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 8)
UnloadCorner.Parent = UnloadBtn

UnloadBtn.MouseButton1Click:Connect(function()
    ClearAllESP()
    if CONFIG.LowGFX then RestoreGFX() end
    ScreenGui:Destroy()
end)

-- Toggle Menu
local menuOpen = false

ClownButton.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    MainFrame.Visible = menuOpen
end)

-- ============================================
-- HOTKEY
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.F1 then
        if CONFIG.SpeedLevel < 10 then
            CONFIG.SpeedLevel = CONFIG.SpeedLevel + 1
            UpdateSpeedDisplay()
        end
    end

    if input.KeyCode == Enum.KeyCode.F2 then
        if CONFIG.SpeedLevel > 1 then
            CONFIG.SpeedLevel = CONFIG.SpeedLevel - 1
            UpdateSpeedDisplay()
        end
    end

    if input.KeyCode == Enum.KeyCode.RightControl then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
    end
end)

print("[READY] 🤡 PETAPETA Menu aktif!")
print("[INFO] Klik tombol 🤡 buat buka menu")
print("[INFO] Low Graphics = boost FPS drastis")

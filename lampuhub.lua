-- ============================================
-- PETAPETA SPEED HACK + ESP
-- Berdasarkan scan struktur game
-- ============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- KONFIGURASI
-- ============================================
local CONFIG = {
    WalkSpeed = 60,
    JumpPower = 120,
    ESPEnabled = true,
    ESPRange = 500,
    ESPColorMonster = Color3.fromRGB(255, 0, 0),
    ESPColorItem = Color3.fromRGB(0, 255, 0),
    ESPColorPlayer = Color3.fromRGB(0, 150, 255)
}

-- ============================================
-- SPEED HACK
-- ============================================
local function ApplySpeed()
    local char = LP.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = CONFIG.WalkSpeed
            hum.JumpPower = CONFIG.JumpPower
            hum.UseJumpPower = true
        end
    end
end

ApplySpeed()
LP.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySpeed()
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
    billboard.Size = UDim2.new(0, 100, 0, 30)
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

-- ============================================
-- SCAN & TAGGING OBJECT
-- ============================================
local function ScanObjects()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            
            -- Deteksi monster/hantu PETAPETA
            if name:find("petapeta") or name:find("monster") or name:find("ghost") or name:find("hantu") or name:find("evil") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    CreateESP(part, CONFIG.ESPColorMonster, "MONSTER: " .. obj.Name)
                end
            end
            
            -- Deteksi item penting
            if name:find("key") or name:find("kunci") or name:find("item") or name:find("ritual") or name:find("paper") or name:find("hint") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    CreateESP(part, CONFIG.ESPColorItem, "ITEM: " .. obj.Name)
                end
            end
        end
    end
    
    -- ESP untuk player lain
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                CreateESP(hrp, CONFIG.ESPColorPlayer, player.Name)
            end
        end
    end
end

-- Scan awal
ScanObjects()

-- Update scan tiap 3 detik
task.spawn(function()
    while CONFIG.ESPEnabled do
        task.wait(3)
        pcall(ScanObjects)
    end
end)

-- Deteksi player baru
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(2)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and CONFIG.ESPEnabled then
            CreateESP(hrp, CONFIG.ESPColorPlayer, player.Name)
        end
    end)
end)

-- Deteksi object baru di workspace
Workspace.DescendantAdded:Connect(function(obj)
    if not CONFIG.ESPEnabled then return end
    task.wait(0.5)
    pcall(ScanObjects)
end)

-- ============================================
-- GUI CONTROL
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PetaPetaHack"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 220)
Frame.Position = UDim2.new(0.5, -110, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Text = "PETAPETA Hack"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local function CreateButton(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Parent = Frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    
    return btn
end

local speedBtn = CreateButton("Speed: ON (60)", 45, function(btn)
    if CONFIG.WalkSpeed > 30 then
        CONFIG.WalkSpeed = 16
        CONFIG.JumpPower = 50
        btn.Text = "Speed: OFF (16)"
        btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    else
        CONFIG.WalkSpeed = 60
        CONFIG.JumpPower = 120
        btn.Text = "Speed: ON (60)"
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    end
    ApplySpeed()
end)
speedBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

local espBtn = CreateButton("ESP: ON", 90, function(btn)
    CONFIG.ESPEnabled = not CONFIG.ESPEnabled
    if CONFIG.ESPEnabled then
        btn.Text = "ESP: ON"
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        ScanObjects()
    else
        btn.Text = "ESP: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        for obj, _ in pairs(espObjects) do
            RemoveESP(obj)
        end
    end
end)
espBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

local clearBtn = CreateButton("Clear ESP", 135, function()
    for obj, _ in pairs(espObjects) do
        RemoveESP(obj)
    end
end)

local destroyBtn = CreateButton("Unload", 180, function()
    CONFIG.ESPEnabled = false
    for obj, _ in pairs(espObjects) do
        RemoveESP(obj)
    end
    ScreenGui:Destroy()
end)
destroyBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)

-- ============================================
-- HOTKEY
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- F1: Toggle Speed
    if input.KeyCode == Enum.KeyCode.F1 then
        if CONFIG.WalkSpeed > 30 then
            CONFIG.WalkSpeed = 16
            CONFIG.JumpPower = 50
        else
            CONFIG.WalkSpeed = 60
            CONFIG.JumpPower = 120
        end
        ApplySpeed()
    end
    
    -- F2: Toggle ESP
    if input.KeyCode == Enum.KeyCode.F2 then
        CONFIG.ESPEnabled = not CONFIG.ESPEnabled
        if CONFIG.ESPEnabled then
            ScanObjects()
        else
            for obj, _ in pairs(espObjects) do
                RemoveESP(obj)
            end
        end
    end
end)

print("[READY] PETAPETA Speed + ESP aktif!")
print("[HOTKEY] F1 = Speed | F2 = ESP")

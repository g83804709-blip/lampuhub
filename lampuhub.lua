-- Steal an Egg - Auto-Scan Guard + Anti Hit Guard
-- Delta Executor Compatible

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- CONFIG
local SAFE_ZONE_CFRAME = CFrame.new(0, 50, 0) -- auto-update nanti
local TELEPORT_DURATION = 0.1
local GUARD_RANGE = 50
local SCAN_INTERVAL = 2 -- rescan nama guard tiap 2 detik
local CHECK_INTERVAL = 0.05

local isActive = false
local isTeleporting = false
local originalCFrame = nil
local lastEggDetection = 0
local lastScan = 0

-- CACHE NAMA GUARD YANG KETEMU
local guardNames = {}
local guardCache = {} -- [Model] = true

-- ============================================
-- AUTO SCAN GUARD NAMA
-- ============================================
local function AutoScanGuards()
    guardNames = {}
    guardCache = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if not obj:IsA("Model") then continue end
        if obj == Character then continue end
        
        local hum = obj:FindFirstChildOfClass("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart")
        if not hum or not root then continue end
        
        -- FILTER 1: Skip kalau ini player
        local isPlayer = Players:GetPlayerFromCharacter(obj)
        if isPlayer then continue end
        
        -- FILTER 2: Skip kalau NPC pasif (Health 0 atau MaxHealth rendah banget)
        if hum.MaxHealth <= 0 then continue end
        
        -- FILTER 3: Skip kalau Humanoid di folder yang jelas bukan guard
        -- (misal: folder "Pets", "NPCs_Passive", "Vendors")
        local parentName = obj.Parent and obj.Parent.Name:lower() or ""
        if parentName:find("pet") or parentName:find("vendor") or 
           parentName:find("shop") or parentName:find("passive") or
           parentName:find("npc_aman") then
            continue
        end
        
        -- FILTER 4: Cek apakah punya ciri-ciri hostile
        local hasHostileTrait = false
        
        -- Trait A: Punya DamageScript / AttackScript
        for _, child in pairs(obj:GetDescendants()) do
            local n = child.Name:lower()
            if n:find("attack") or n:find("damage") or n:find("hitbox") or 
               n:find("chase") or n:find("aggro") or n:find("detect") then
                hasHostileTrait = true
                break
            end
        end
        
        -- Trait B: Punya tag/attribute hostile
        if obj:GetAttribute("Hostile") or obj:GetAttribute("IsGuard") or 
           obj:GetAttribute("Damage") or obj:GetAttribute("Aggro") then
            hasHostileTrait = true
        end
        
        -- Trait C: Punya humanoid yang punya "MoveTo" behavior aktif
        -- (kita deteksi via nama internal, tapi ini opsional)
        
        -- Kalau lolos filter, masuk ke daftar
        if hasHostileTrait or hum.MaxHealth > 100 then
            table.insert(guardNames, obj.Name)
            guardCache[obj] = true
        end
    end
    
    print("[AutoScan] Guard terdeteksi: " .. tostring(#guardNames))
    for i, n in ipairs(guardNames) do
        print("  [" .. i .. "] " .. n)
    end
end

-- ============================================
-- AUTO DETECT SAFE ZONE
-- ============================================
local function AutoDetectSafeZone()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("safezone") or n:find("safe_zone") or 
               n:find("spawn") or n:find("baseplate") or
               n:find("lobby") or n:find("base") then
                SAFE_ZONE_CFRAME = obj.CFrame + Vector3.new(0, 5, 0)
                print("[SafeZone] Terdeteksi: " .. obj:GetFullName())
                return
            end
        end
    end
    -- fallback: pakai SpawnLocation
    local sp = workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then
        SAFE_ZONE_CFRAME = sp.CFrame + Vector3.new(0, 5, 0)
    end
end

-- ============================================
-- DETEKSI EGG DI TANGAN
-- ============================================
local function FindEggInHands()
    for _, item in pairs(Character:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") then
            if item.Name:lower():find("egg") then
                return item
            end
        end
    end
    return nil
end

-- ============================================
-- TELEPORT & RETURN
-- ============================================
local function TeleportAndReturn()
    if isTeleporting then return end
    if not RootPart or not RootPart.Parent then return end
    
    originalCFrame = RootPart.CFrame
    isTeleporting = true
    
    RootPart.CFrame = SAFE_ZONE_CFRAME
    task.wait(TELEPORT_DURATION)
    
    if originalCFrame and RootPart and RootPart.Parent then
        RootPart.CFrame = originalCFrame
    end
    
    isTeleporting = false
end

-- ============================================
-- MAIN LOOP
-- ============================================
local function OnHeartbeat()
    if not isActive then return end
    if isTeleporting then return end
    
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        return
    end
    
    local now = tick()
    
    -- RESCAN GUARD PERIODIK
    if now - lastScan > SCAN_INTERVAL then
        lastScan = now
        task.spawn(AutoScanGuards)
    end
    
    if now - lastEggDetection < CHECK_INTERVAL then return end
    lastEggDetection = now
    
    local egg = FindEggInHands()
    if not egg then return end
    
    -- HEALTH DROP FALLBACK
    if Humanoid.Health < Humanoid.MaxHealth then
        TeleportAndReturn()
        return
    end
    
    -- PROXIMITY CHECK KE SEMUA GUARD YANG KEScan
    for guard in pairs(guardCache) do
        if not guard.Parent then
            guardCache[guard] = nil
            continue
        end
        
        local gRoot = guard:FindFirstChild("HumanoidRootPart")
        if gRoot then
            local dist = (RootPart.Position - gRoot.Position).Magnitude
            if dist < GUARD_RANGE then
                TeleportAndReturn()
                return
            end
        end
    end
end

-- ============================================
-- GUI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoGuardScan"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 220, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0, 100)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BorderSizePixel = 0
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "Anti-Hit Guard: OFF"
ToggleButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0, 220, 0, 30)
InfoLabel.Position = UDim2.new(0, 20, 0, 155)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.TextSize = 12
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Text = "Guards: 0"
InfoLabel.Parent = ScreenGui

local loopConn

ToggleButton.MouseButton1Click:Connect(function()
    isActive = not isActive
    
    if isActive then
        ToggleButton.Text = "Anti-Hit Guard: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        
        AutoDetectSafeZone()
        AutoScanGuards()
        
        loopConn = RunService.Heartbeat:Connect(OnHeartbeat)
    else
        ToggleButton.Text = "Anti-Hit Guard: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        if loopConn then loopConn:Disconnect() end
    end
end)

-- Update counter guard di UI
spawn(function()
    while task.wait(1) do
        local count = 0
        for g in pairs(guardCache) do
            if g.Parent then count = count + 1 end
        end
        InfoLabel.Text = "Guards: " .. count .. " (scanned: " .. #guardNames .. ")"
    end
end)

-- Refresh safe zone tiap 5 detik
spawn(function()
    while task.wait(5) do
        AutoDetectSafeZone()
    end
end)

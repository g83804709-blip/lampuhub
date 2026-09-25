-- LampuHub v2
-- UI + auto egg system + adaptive fly speed

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- =========================================================
-- STATE
-- =========================================================

local enabled = false
local flySpeed = 300
local dropPoint = nil
local currentEgg = nil

local connections = {}
local characterConnections = {}
local heartbeatConn = nil

-- =========================================================
-- CONFIG — SESUAIKAN NAMA OBJECT DI GAME LU
-- =========================================================

local CONFIG = {
    -- Nama folder yang isinya semua egg di Workspace
    EggFolderName = "Eggs",

    -- Nama attribute untuk rarity (bisa "Rarity", "Tier", "Quality")
    RarityAttribute = "Rarity",

    -- Nama attribute untuk income per detik (bisa "Income", "Value", "Earnings")
    IncomeAttribute = "Income",

    -- Nama guardian yang ngejar (bisa string tunggal atau tabel)
    GuardianNames = {"Guardian", "Boss", "Chaser"},

    -- Jarak aman dari drop point biar gak overshoot
    DropPointOffset = Vector3.new(0, 4, 0),

    -- Margin kecepatan di atas guardian (semakin besar semakin aman)
    SpeedMargin = 8,

    -- Jarak maksimal untuk deteksi touch egg
    GrabRange = 8,

    -- Interval loop utama (detik)
    LoopInterval = 0.15,
}

local biomes = {
    "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano",
    "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom",
    "Titan Temple", "Angels & Demons"
}

-- =========================================================
-- CLEANUP
-- =========================================================

local function disconnectList(list)
    for _, connection in ipairs(list) do
        if connection then
            pcall(function() connection:Disconnect() end)
        end
    end
    table.clear(list)
end

local function cleanup()
    disconnectList(connections)
    disconnectList(characterConnections)

    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end

    if currentEgg then
        currentEgg = nil
    end
end

-- =========================================================
-- CHARACTER
-- =========================================================

local function getCharacter()
    local character = LP.Character
    if not character then return nil, nil, nil end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    return character, hrp, humanoid
end

local function setupCharacter(character)
    disconnectList(characterConnections)

    local humanoid = character:WaitForChild("Humanoid", 10)

    if humanoid then
        table.insert(characterConnections,
            humanoid.Died:Connect(function()
                enabled = false
                currentEgg = nil
                if toggleBtn then
                    toggleBtn.Text = "System: OFF"
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
                end
            end)
        )
    end
end

-- =========================================================
-- GUI (sama seperti sebelumnya)
-- =========================================================

local oldGui = PlayerGui:FindFirstChild("LampuHub")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LampuHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local mainBtn = Instance.new("TextButton")
mainBtn.Name = "MainButton"
mainBtn.Size = UDim2.fromOffset(58, 58)
mainBtn.Position = UDim2.new(0, 18, 0.5, -29)
mainBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
mainBtn.Text = "LH"
mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainBtn.TextSize = 18
mainBtn.Font = Enum.Font.GothamBold
mainBtn.AutoButtonColor = false
mainBtn.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(1, 0)
mainCorner.Parent = mainBtn

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 210, 60)
mainStroke.Thickness = 2
mainStroke.Parent = mainBtn

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Size = UDim2.fromOffset(235, 220)
panel.Position = UDim2.new(0, -250, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
panel.BorderSizePixel = 0
panel.Visible = true
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(65, 65, 75)
panelStroke.Thickness = 1
panelStroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 28)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Text = "LampuHub"
title.TextColor3 = Color3.fromRGB(255, 215, 70)
title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -24, 0, 18)
subtitle.Position = UDim2.fromOffset(12, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Auto Egg System"
subtitle.TextColor3 = Color3.fromRGB(145, 145, 155)
subtitle.TextSize = 11
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Position = UDim2.new(1, -31, 0, 9)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = panel

local function createButton(name, text, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -24, 0, 34)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(235, 235, 240)
    button.TextSize = 13
    button.Font = Enum.Font.GothamMedium
    button.AutoButtonColor = false
    button.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Thickness = 1
    stroke.Parent = button

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12),
            {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12),
            {BackgroundColor3 = Color3.fromRGB(38, 38, 45)}):Play()
    end)

    return button
end

local toggleBtn = createButton("ToggleButton", "System: OFF", 60)
local dropBtn = createButton("DropPointButton", "Set Drop Point", 101)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.45, 0, 0, 20)
speedLabel.Position = UDim2.fromOffset(12, 143)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 300"
speedLabel.TextColor3 = Color3.fromRGB(210, 210, 215)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = panel

local minusBtn = createButton("MinusButton", "−", 141)
minusBtn.Size = UDim2.fromOffset(34, 30)
minusBtn.Position = UDim2.new(1, -86, 0, 139)

local plusBtn = createButton("PlusButton", "+", 141)
plusBtn.Size = UDim2.fromOffset(34, 30)
plusBtn.Position = UDim2.new(1, -48, 0, 139)

-- Status label baru
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 16)
statusLabel.Position = UDim2.fromOffset(12, 178)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

local function setStatus(text)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = "Status: " .. text
    end
end

-- =========================================================
-- PANEL ANIMATION
-- =========================================================

local panelOpen = false

local function setPanel(open)
    panelOpen = open
    local target
    if open then
        target = UDim2.new(0, 88, 0.5, 0)
    else
        target = UDim2.new(0, -250, 0.5, 0)
    end
    TweenService:Create(panel,
        TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = target}):Play()
end

mainBtn.MouseButton1Click:Connect(function()
    setPanel(not panelOpen)
end)

closeBtn.MouseButton1Click:Connect(function()
    setPanel(false)
end)

-- =========================================================
-- CORE: FLY / MOVEMENT
-- =========================================================

local flyBV = nil
local flyBG = nil

local function initFly(hrp)
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.P = 10000
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 10000
    flyBG.D = 100
    flyBG.Parent = hrp
end

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

-- =========================================================
-- CORE: GUARDIAN DETECTION
-- =========================================================

local function findGuardian()
    local _, myHrp = getCharacter()
    if not myHrp then return nil end

    local closest = nil
    local closestDist = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, name in ipairs(CONFIG.GuardianNames) do
                if obj.Name:lower():find(name:lower()) then
                    local gHrp = obj:FindFirstChild("HumanoidRootPart")
                        or obj:FindFirstChildWhichIsA("BasePart")
                    if gHrp then
                        local dist = (gHrp.Position - myHrp.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = gHrp
                        end
                    end
                    break
                end
            end
        end
    end

    return closest
end

local function getGuardianSpeed(guardianPart)
    if not guardianPart then return 0 end

    local humanoid = guardianPart.Parent
        and guardianPart.Parent:FindFirstChildOfClass("Humanoid")

    if humanoid then
        return humanoid.WalkSpeed
    end

    return 0
end

-- =========================================================
-- CORE: EGG SCANNER
-- =========================================================

local function getEggValue(egg)
    -- Coba berbagai nama attribute yang umum
    local rarity = egg:GetAttribute(CONFIG.RarityAttribute)
        or egg:GetAttribute("Tier")
        or egg:GetAttribute("Quality")
        or 0

    local income = egg:GetAttribute(CONFIG.IncomeAttribute)
        or egg:GetAttribute("Value")
        or egg:GetAttribute("Earnings")
        or egg:GetAttribute("IncomePerSecond")
        or 0

    -- Skor gabungan: utamakan rarity, income sebagai tie-breaker
    return (tonumber(rarity) or 0) * 1000000 + (tonumber(income) or 0)
end

local function getEggPart(egg)
    if egg:IsA("BasePart") then return egg end

    return egg:FindFirstChild("Handle")
        or egg:FindFirstChild("Egg")
        or egg:FindFirstChildWhichIsA("BasePart")
end

local function scanEggs()
    local folder = workspace:FindFirstChild(CONFIG.EggFolderName)

    -- Kalau folder "Eggs" gak ada, scan seluruh workspace
    local pool = folder and folder:GetChildren() or workspace:GetChildren()

    local best = nil
    local bestScore = -math.huge

    for _, obj in ipairs(pool) do
        local part = getEggPart(obj)
        if part and part:IsA("BasePart") then
            local score = getEggValue(part)
            if score > bestScore then
                bestScore = score
                best = part
            end
        end
    end

    return best, bestScore
end

-- =========================================================
-- CORE: GRAB EGG
-- =========================================================

local function grabEgg(eggPart)
    local character, myHrp = getCharacter()
    if not character or not myHrp or not eggPart then return false end

    -- Touch interest dua arah (fire touch begin + end)
    pcall(function()
        firetouchinterest(myHrp, eggPart, 0)
        task.wait(0.05)
        firetouchinterest(myHrp, eggPart, 1)
    end)

    -- Fallback: fire proximity prompt kalau ada
    local prompt = eggPart:FindFirstChildWhichIsA("ProximityPrompt")
        or (eggPart.Parent and eggPart.Parent:FindFirstChildWhichIsA("ProximityPrompt"))

    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    end

    return true
end

-- =========================================================
-- CORE: FLY TO TARGET
-- =========================================================

local function flyTo(targetCFrame, speed)
    local _, myHrp = getCharacter()
    if not myHrp or not flyBV or not flyBG then return end

    local direction = targetCFrame.Position - myHrp.Position
    local distance = direction.Magnitude

    if distance < 1 then
        flyBV.Velocity = Vector3.zero
        return
    end

    flyBV.Velocity = direction.Unit * math.min(speed, distance * 8)
    flyBG.CFrame = CFrame.new(myHrp.Position, targetCFrame.Position)
end

-- =========================================================
-- CORE: MAIN LOOP
-- =========================================================

local function mainLoop()
    if not enabled then return end

    local character, myHrp, humanoid = getCharacter()
    if not character or not myHrp or not humanoid then return end

    -- Init fly kalau belum
    if not flyBV or not flyBV.Parent then
        initFly(myHrp)
    end

    -- Hitung kecepatan adaptif dari guardian
    local guardian = findGuardian()
    local guardianSpeed = getGuardianSpeed(guardian)
    local adaptiveSpeed = math.max(flySpeed, guardianSpeed + CONFIG.SpeedMargin)

    -- FASE 1: belum punya egg → scan & ambil
    if not currentEgg or not currentEgg.Parent then
        setStatus("Scanning eggs...")

        local bestEgg = scanEggs()
        if not bestEgg then
            setStatus("No egg found")
            return
        end

        currentEgg = bestEgg
        setStatus("Flying to egg...")

        local dist = (bestEgg.Position - myHrp.Position).Magnitude
        if dist > CONFIG.GrabRange then
            flyTo(CFrame.new(bestEgg.Position), adaptiveSpeed)
            return
        end

        -- Udah deket, ambil
        setStatus("Grabbing egg...")
        flyBV.Velocity = Vector3.zero
        grabEgg(bestEgg)
        task.wait(0.2)

        if currentEgg and currentEgg.Parent then
            setStatus("Egg grabbed")
        else
            setStatus("Egg obtained, returning...")
        end
        return
    end

    -- FASE 2: udah bawa egg → balik ke drop point
    if dropPoint then
        setStatus("Returning to drop point...")
        flyTo(dropPoint + CONFIG.DropPointOffset, adaptiveSpeed)

        local dist = ((dropPoint + CONFIG.DropPointOffset).Position - myHrp.Position).Magnitude
        if dist < 4 then
            setStatus("Dropping egg...")
            flyBV.Velocity = Vector3.zero

            -- Drop = touch drop point
            local dropPart = workspace:FindFirstChild("DropZone")
                or workspace:FindFirstChild("DropPoint")

            if dropPart and dropPart:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(myHrp, dropPart, 0)
                    task.wait(0.05)
                    firetouchinterest(myHrp, dropPart, 1)
                end)
            end

            currentEgg = nil
            task.wait(0.3)
            setStatus("Cycle complete")
        end
    else
        setStatus("Set drop point first!")
    end
end

-- =========================================================
-- ENABLE / DISABLE
-- =========================================================

local function startSystem()
    enabled = true
    cleanup()
    setStatus("Starting...")

    if heartbeatConn then heartbeatConn:Disconnect() end

    -- Loop utama pakai heartbeat + interval
    local lastTick = 0
    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not enabled then return end
        lastTick = lastTick + dt
        if lastTick >= CONFIG.LoopInterval then
            lastTick = 0
            pcall(mainLoop)
        end
    end)
end

local function stopSystem()
    enabled = false
    currentEgg = nil
    stopFly()
    setStatus("Stopped")

    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    if enabled then
        stopSystem()
        toggleBtn.Text = "System: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    else
        startSystem()
        toggleBtn.Text = "System: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 115, 70)
    end
end)

-- =========================================================
-- DROP POINT
-- =========================================================

dropBtn.MouseButton1Click:Connect(function()
    local _, hrp = getCharacter()
    if not hrp then return end

    dropPoint = hrp.CFrame
    dropBtn.Text = "Drop Point: Set"
    dropBtn.BackgroundColor3 = Color3.fromRGB(30, 115, 70)

    task.delay(1.2, function()
        if dropBtn and dropBtn.Parent then
            dropBtn.Text = "Set Drop Point"
            dropBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
        end
    end)
end)

-- =========================================================
-- SPEED
-- =========================================================

local function updateSpeed()
    speedLabel.Text = "Speed: " .. tostring(flySpeed)
end

minusBtn.MouseButton1Click:Connect(function()
    flySpeed = math.max(50, flySpeed - 50)
    updateSpeed()
end)

plusBtn.MouseButton1Click:Connect(function()
    flySpeed = math.min(1000, flySpeed + 50)
    updateSpeed()
end)

-- =========================================================
-- DRAG MAIN BUTTON
-- =========================================================

local dragging = false
local dragStart
local startPosition

mainBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = mainBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local delta = input.Position - dragStart
    mainBtn.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- =========================================================
-- CHARACTER RESPAWN
-- =========================================================

table.insert(connections,
    LP.CharacterAdded:Connect(function(character)
        dropPoint = nil
        currentEgg = nil
        stopFly()
        setupCharacter(character)
    end)
)

if LP.Character then
    setupCharacter(LP.Character)
end

updateSpeed()
setStatus("Idle")
print("LampuHub v2 loaded.")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LogService = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- State
local autoEnabled = false
local flying = false
local currentTween = nil
local dropPoint = nil
local monitorConnection = nil
local flySpeed = 300
local eggQueue = {}
local currentEggIndex = 1
local isExecuting = false

-- Biome names
local biomes = {
    "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano",
    "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom",
    "Titan Temple", "Angels & Demons", "Angels and Demons"
}

-- ========== UI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "LampuHub"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

local mainBtn = Instance.new("TextButton")
mainBtn.Size = UDim2.new(0, 70, 0, 70)
mainBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
mainBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
mainBtn.Text = "LampuHub"
mainBtn.TextColor3 = Color3.new(1, 1, 1)
mainBtn.TextScaled = true
mainBtn.Font = Enum.Font.GothamBold
mainBtn.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(1, 0)
mainCorner.Parent = mainBtn

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 0)
mainStroke.Thickness = 3
mainStroke.Parent = mainBtn

local colors = {
    Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255)
}
task.spawn(function()
    local i = 1
    while gui.Parent do
        i = i % #colors + 1
        mainBtn.BackgroundColor3 = colors[i]
        task.wait(0.35)
    end
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 260, 0, 200)
panel.Position = UDim2.new(-0.3, 0, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(255, 255, 0)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "LampuHub Menu"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextScaled = true
titleLabel.Parent = panel

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtn.Text = "Auto Drop Egg: OFF"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local setDropBtn = Instance.new("TextButton")
setDropBtn.Size = UDim2.new(0.9, 0, 0, 35)
setDropBtn.Position = UDim2.new(0.05, 0, 0, 90)
setDropBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
setDropBtn.Text = "Set Drop Point"
setDropBtn.TextColor3 = Color3.new(1, 1, 1)
setDropBtn.TextScaled = true
setDropBtn.Font = Enum.Font.Gotham
setDropBtn.Parent = panel

local setDropCorner = Instance.new("UICorner")
setDropCorner.CornerRadius = UDim.new(0, 8)
setDropCorner.Parent = setDropBtn

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.9, 0, 0, 25)
speedLabel.Position = UDim2.new(0.05, 0, 0, 135)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 300"
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextScaled = true
speedLabel.Parent = panel

local speedSlider = Instance.new("TextButton")
speedSlider.Size = UDim2.new(0.9, 0, 0, 30)
speedSlider.Position = UDim2.new(0.05, 0, 0, 162)
speedSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedSlider.Text = "+ / -"
speedSlider.TextColor3 = Color3.new(1, 1, 1)
speedSlider.TextScaled = true
speedSlider.Font = Enum.Font.Gotham
speedSlider.Parent = panel

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 8)
speedCorner.Parent = speedSlider

mainBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
    local targetPos = panel.Visible and UDim2.new(0.07, 0, 0.35, 0) or UDim2.new(-0.3, 0, 0.35, 0)
    TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end)

-- ========== HELPERS ==========
local function getCharacter()
    local char = LP.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

local function tweenTo(targetPos, callback)
    local _, hrp, hum = getCharacter()
    if not hrp or not hum or hum.Health <= 0 then
        if callback then callback(false) end
        return
    end

    flying = true
    local startPos = hrp.Position
    local distance = (targetPos - startPos).Magnitude
    local duration = distance / flySpeed

    if duration < 0.05 then
        hrp.CFrame = CFrame.new(targetPos)
        flying = false
        if callback then callback(true) end
        return
    end

    currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(targetPos)
    })

    currentTween.Completed:Connect(function()
        flying = false
        currentTween = nil
        if callback then callback(true) end
    end)

    currentTween:Play()
end

local function stopFlying()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    flying = false
end

local function findBiomePosition(biomeName)
    local searchName = biomeName:lower():gsub("&", "and")
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find(searchName) or searchName:find(name) then
                if obj:IsA("BasePart") then
                    return obj.Position + Vector3.new(0, 10, 0)
                elseif obj:IsA("Model") then
                    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        return primary.Position + Vector3.new(0, 10, 0)
                    end
                end
            end
        end
    end
    return nil
end

local function findEggsInArea(areaPos, radius)
    local eggs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - areaPos).Magnitude
                if dist <= radius then
                    table.insert(eggs, {prompt = obj, part = part, distance = dist})
                end
            end
        end
    end
    table.sort(eggs, function(a, b) return a.distance < b.distance end)
    return eggs
end

local function scanAllEggs()
    local eggs = {}
    local _, hrp, _ = getCharacter()
    if not hrp then return eggs end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - hrp.Position).Magnitude
                local hasGlow = false
                local hasEffect = false
                for _, child in pairs(part:GetChildren()) do
                    if child:IsA("ParticleEmitter") or child:IsA("PointLight") or child:IsA("SpotLight") then
                        hasGlow = true
                    end
                end
                for _, child in pairs(part:GetChildren()) do
                    if child.Name:lower():find("effect") or child.Name:lower():find("glow") or child.Name:lower():find("aura") then
                        hasEffect = true
                    end
                end
                table.insert(eggs, {
                    prompt = obj,
                    part = part,
                    distance = dist,
                    hasGlow = hasGlow or hasEffect,
                    size = part.Size.Magnitude
                })
            end
        end
    end

    table.sort(eggs, function(a, b)
        if a.hasGlow ~= b.hasGlow then
            return a.hasGlow
        end
        return a.size > b.size
    end)

    local top5 = {}
    for i = 1, math.min(5, #eggs) do
        table.insert(top5, eggs[i])
    end
    return top5
end

local function pickUpEgg(eggData)
    if not eggData or not eggData.prompt then return false end
    local prompt = eggData.prompt
    local success = pcall(function()
        if prompt.HoldDuration > 0 then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.05)
            prompt:InputHoldEnd()
        else
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
        end
    end)
    return success
end

local function dropEgg()
    local char, _, _ = getCharacter()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local backpack = LP:FindFirstChild("Backpack")
        if backpack then
            tool.Parent = backpack
        end
    end
end

-- ========== ANTI SYSTEMS ==========
local antiRagdollConnection = nil

local function enableAntiRagdoll()
    if antiRagdollConnection then return end
    antiRagdollConnection = LP.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        hum.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.Ragdoll then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end
        end)
    end)
    
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.StateChanged:Connect(function(old, new)
                if new == Enum.HumanoidStateType.Ragdoll then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                end
            end)
        end
    end
end

local function checkThreats()
    local _, hrp, _ = getCharacter()
    if not hrp then return false end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local enemyHrp = char:FindFirstChild("HumanoidRootPart")
                if enemyHrp then
                    local dist = (enemyHrp.Position - hrp.Position).Magnitude
                    if dist < 30 then
                        return true
                    end
                end
            end
        end
    end
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("trap") or obj.Name:lower():find("bear")) then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < 20 then
                return true
            end
        end
    end
    
    return false
end

local function escapeThreat()
    local _, hrp, _ = getCharacter()
    if not hrp then return end
    local escapePos = hrp.Position + Vector3.new(0, 150, 0)
    tweenTo(escapePos, function()
        task.wait(1)
    end)
end

-- ========== EGG EXECUTION ==========
local function executeEgg(eggData)
    if not eggData or not autoEnabled then return end
    
    isExecuting = true
    
    local _, hrp, _ = getCharacter()
    if not hrp then 
        isExecuting = false
        return 
    end
    
    if checkThreats() then
        escapeThreat()
        while flying do task.wait(0.1) end
    end
    
    local eggPos = eggData.part.Position + Vector3.new(0, 5, 0)
    tweenTo(eggPos, function()
        task.wait(0.2)
        
        if checkThreats() then
            escapeThreat()
            while flying do task.wait(0.1) end
        end
        
        pickUpEgg(eggData)
        task.wait(0.5)
    end)
    
    while flying do task.wait(0.05) end
    task.wait(0.3)
    
    if checkThreats() then
        escapeThreat()
        while flying do task.wait(0.1) end
    end
    
    if dropPoint then
        tweenTo(dropPoint, function()
            task.wait(0.2)
        end)
        
        while flying do task.wait(0.05) end
        task.wait(0.3)
        
        dropEgg()
        task.wait(0.3)
    end
    
    isExecuting = false
end

local function processNotification(biomeName)
    if not autoEnabled or isExecuting then return end
    
    task.spawn(function()
        local biomePos = findBiomePosition(biomeName)
        if not biomePos then return end
        
        local eggs = findEggsInArea(biomePos, 500)
        if #eggs == 0 then return end
        
        for _, egg in pairs(eggs) do
            if not autoEnabled then break end
            if not egg.prompt or not egg.prompt.Parent then
                egg = eggs[#eggs]
                if egg and egg.prompt and egg.prompt.Parent then
                    executeEgg(egg)
                end
                break
            end
            executeEgg(egg)
        end
    end)
end

local function startMonitoring()
    if monitorConnection then return end
    
    monitorConnection = LogService.MessageOut:Connect(function(message, messageType)
        if not autoEnabled then return end
        
        local lowerMsg = message:lower()
        
        local hasRarity = lowerMsg:find("secret") or lowerMsg:find("eternal") or lowerMsg:find("divine")
        if not hasRarity then return end
        
        local hasSpawn = lowerMsg:find("spawned") or lowerMsg:find("spawn")
        if not hasSpawn then return end
        
        for _, biome in pairs(biomes) do
            if lowerMsg:find(biome:lower()) then
                processNotification(biome)
                break
            end
        end
    end)
end

local function stopMonitoring()
    if monitorConnection then
        monitorConnection:Disconnect()
        monitorConnection = nil
    end
end

local function fallbackLoop()
    while autoEnabled do
        if not isExecuting then
            local eggs = scanAllEggs()
            if #eggs > 0 then
                for i, egg in pairs(eggs) do
                    if not autoEnabled then break end
                    if egg.prompt and egg.prompt.Parent then
                        executeEgg(egg)
                    else
                        egg = eggs[#eggs]
                        if egg and egg.prompt and egg.prompt.Parent then
                            executeEgg(egg)
                        end
                        break
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ========== BUTTONS ==========
toggleBtn.MouseButton1Click:Connect(function()
    autoEnabled = not autoEnabled
    
    if autoEnabled then
        toggleBtn.Text = "Auto Drop Egg: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
        enableAntiRagdoll()
        startMonitoring()
        task.spawn(fallbackLoop)
    else
        toggleBtn.Text = "Auto Drop Egg: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        stopFlying()
        stopMonitoring()
    end
end)

setDropBtn.MouseButton1Click:Connect(function()
    local _, hrp, _ = getCharacter()
    if hrp then
        dropPoint = hrp.Position
        setDropBtn.Text = "Drop Point Set!"
        setDropBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
        task.wait(1)
        setDropBtn.Text = "Set Drop Point"
        setDropBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

speedSlider.MouseButton1Click:Connect(function()
    local _, hrp, _ = getCharacter()
    if not hrp then return end
    
    local mouse = UserInputService:GetMouseLocation()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    if mouse.X < viewportSize.X / 2 then
        flySpeed = math.max(100, flySpeed - 50)
    else
        flySpeed = math.min(1000, flySpeed + 50)
    end
    
    speedLabel.Text = "Speed: " .. flySpeed
end)

LP.CharacterAdded:Connect(function()
    if autoEnabled then
        stopFlying()
    end
end)

print("LampuHub loaded - Auto Drop Egg ready")

-- LampuHub
-- UI + state/connection cleanup
-- Tidak termasuk auto-farm / auto-pickup / teleport exploit.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- =========================================================
-- STATE
-- =========================================================

local enabled = false
local flySpeed = 300
local dropPoint = nil

local connections = {}
local characterConnections = {}

-- Nama biome yang sudah diperbaiki
local biomes = {
    "Forest",
    "Lake",
    "Desert",
    "Jungle",
    "Snow",
    "Volcano",
    "Abyss Ocean",
    "Prehistoric",
    "Cosmic",
    "Cherry Blossom",
    "Titan Temple",
    "Angels & Demons"
}

-- =========================================================
-- CLEANUP
-- =========================================================

local function disconnectList(list)
    for _, connection in ipairs(list) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    table.clear(list)
end

local function cleanup()
    disconnectList(connections)
    disconnectList(characterConnections)
end

-- =========================================================
-- CHARACTER
-- =========================================================

local function getCharacter()
    local character = LP.Character
    if not character then
        return nil, nil, nil
    end

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
            end)
        )
    end
end

-- =========================================================
-- GUI
-- =========================================================

local oldGui = PlayerGui:FindFirstChild("LampuHub")

if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LampuHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

-- =========================================================
-- MAIN BUTTON
-- =========================================================

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

-- =========================================================
-- PANEL
-- =========================================================

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Size = UDim2.fromOffset(235, 190)
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

-- =========================================================
-- TITLE
-- =========================================================

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
subtitle.Text = "Control Panel"
subtitle.TextColor3 = Color3.fromRGB(145, 145, 155)
subtitle.TextSize = 11
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

-- =========================================================
-- CLOSE BUTTON
-- =========================================================

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Position = UDim2.new(1, -31, 0, 9)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = panel

-- =========================================================
-- BUTTON CREATOR
-- =========================================================

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
        TweenService:Create(
            button,
            TweenInfo.new(0.12),
            {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.12),
            {BackgroundColor3 = Color3.fromRGB(38, 38, 45)}
        ):Play()
    end)

    return button
end

-- =========================================================
-- TOGGLE
-- =========================================================

local toggleBtn = createButton(
    "ToggleButton",
    "System: OFF",
    60
)

-- =========================================================
-- DROP POINT
-- =========================================================

local dropBtn = createButton(
    "DropPointButton",
    "Set Drop Point",
    101
)

-- =========================================================
-- SPEED
-- =========================================================

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

local minusBtn = createButton(
    "MinusButton",
    "−",
    141
)

minusBtn.Size = UDim2.fromOffset(34, 30)
minusBtn.Position = UDim2.new(1, -86, 0, 139)

local plusBtn = createButton(
    "PlusButton",
    "+",
    141
)

plusBtn.Size = UDim2.fromOffset(34, 30)
plusBtn.Position = UDim2.new(1, -48, 0, 139)

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

    TweenService:Create(
        panel,
        TweenInfo.new(
            0.22,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {
            Position = target
        }
    ):Play()
end

mainBtn.MouseButton1Click:Connect(function()
    setPanel(not panelOpen)
end)

closeBtn.MouseButton1Click:Connect(function()
    setPanel(false)
end)

-- =========================================================
-- TOGGLE STATE
-- =========================================================

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled

    if enabled then
        toggleBtn.Text = "System: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 115, 70)
    else
        toggleBtn.Text = "System: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    end
end)

-- =========================================================
-- DROP POINT
-- =========================================================

dropBtn.MouseButton1Click:Connect(function()
    local _, hrp = getCharacter()

    if not hrp then
        return
    end

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
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

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

table.insert(
    connections,
    LP.CharacterAdded:Connect(function(character)
        dropPoint = nil
        setupCharacter(character)
    end)
)

if LP.Character then
    setupCharacter(LP.Character)
end

-- =========================================================
-- INITIAL STATE
-- =========================================================

updateSpeed()

print("LampuHub loaded successfully.")

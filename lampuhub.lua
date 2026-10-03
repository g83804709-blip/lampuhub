-- == CONFIG == --
local CONFIG = {
    EggContainer = workspace:WaitForChild("Eggs", 10),
    ScanInterval = 4,
    SortMode = "rarity",
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EggList = {}
local SelectedEgg = nil
local IsOpen = false
local Stealing = false

local RarityOrder = {
    ["Secret"]=1, ["Eternal"]=2, ["Divine"]=3, ["Cosmic"]=4,
    ["Mythic"]=5, ["Mythical"]=5, ["Legendary"]=6, ["Epic"]=7,
    ["VeryRare"]=8, ["Rare"]=9, ["Uncommon"]=10, ["Common"]=11,
}

-- == AMBIL DATA EGG == --
local function GetEggData(egg)
    local rarity, size, price = "Common", 1, 0

    local ok, v = pcall(function() return egg:GetAttribute("Rarity") end)
    if ok and v then rarity = v
    elseif egg:FindFirstChild("Rarity") then rarity = egg.Rarity.Value end

    ok, v = pcall(function() return egg:GetAttribute("Size") end)
    if ok and v then size = v
    elseif egg:FindFirstChild("Size") then size = egg.Size.Value end

    ok, v = pcall(function() return egg:GetAttribute("Price") end)
    if ok and v then price = v
    elseif egg:FindFirstChild("Price") then price = egg.Price.Value end

    local part = egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart")
    if not part then return nil end

    return {
        Instance = egg,
        Name = egg.Name,
        Rarity = rarity,
        Size = size,
        Price = price,
        Position = part.Position,
    }
end

local function ScanEggs()
    EggList = {}
    if not CONFIG.EggContainer then return end
    for _, egg in ipairs(CONFIG.EggContainer:GetChildren()) do
        if egg:IsA("Model") or egg:IsA("BasePart") then
            local data = GetEggData(egg)
            if data then table.insert(EggList, data) end
        end
    end
end

local function SortEggs()
    table.sort(EggList, function(a, b)
        if CONFIG.SortMode == "rarity" then
            local ra = RarityOrder[a.Rarity] or 99
            local rb = RarityOrder[b.Rarity] or 99
            if ra ~= rb then return ra < rb end
            return a.Size > b.Size
        elseif CONFIG.SortMode == "size" then
            return a.Size > b.Size
        elseif CONFIG.SortMode == "price" then
            return a.Price > b.Price
        end
        return a.Name < b.Name
    end)
end

-- == GUI ROOT == --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkullEggUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- == IKON ☠️ FLOATING (TANPA BACKGROUND) == --
local SkullIcon = Instance.new("TextButton")
SkullIcon.Size = UDim2.new(0, 60, 0, 60)
SkullIcon.Position = UDim2.new(0.05, 0, 0.4, 0)
SkullIcon.BackgroundTransparency = 1
SkullIcon.Text = "☠️"
SkullIcon.TextSize = 48
SkullIcon.Font = Enum.Font.FredokaOne
SkullIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
SkullIcon.AutoButtonColor = false
SkullIcon.Active = true
SkullIcon.Draggable = true
SkullIcon.Parent = ScreenGui

-- == FRAME UTAMA (MUNCUL SAAT ICON DI TAP) == --
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 420)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(255, 200, 60)
FrameStroke.Thickness = 1.5
FrameStroke.Transparency = 0.3
FrameStroke.Parent = MainFrame

-- Header dengan ikon skull kecil
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, -80, 0, 36)
Header.Position = UDim2.new(0, 44, 0, 8)
Header.BackgroundTransparency = 1
Header.Text = "EGG SCANNER"
Header.TextColor3 = Color3.fromRGB(255, 200, 60)
Header.TextSize = 16
Header.Font = Enum.Font.FredokaOne
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.Parent = MainFrame

local MiniSkull = Instance.new("TextLabel")
MiniSkull.Size = UDim2.new(0, 40, 0, 40)
MiniSkull.Position = UDim2.new(0, 4, 0, 6)
MiniSkull.BackgroundTransparency = 1
MiniSkull.Text = "☠️"
MiniSkull.TextSize = 28
MiniSkull.Font = Enum.Font.FredokaOne
MiniSkull.Parent = MainFrame

-- Tombol close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Tombol sort
local SortBtn = Instance.new("TextButton")
SortBtn.Size = UDim2.new(1, -20, 0, 34)
SortBtn.Position = UDim2.new(0, 10, 0, 50)
SortBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
SortBtn.Text = "Sort: Rarity > Size"
SortBtn.TextColor3 = Color3.fromRGB(255, 200, 60)
SortBtn.TextSize = 13
SortBtn.Font = Enum.Font.GothamBold
SortBtn.Parent = MainFrame
Instance.new("UICorner", SortBtn).CornerRadius = UDim.new(0, 6)

-- List egg
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -130)
ScrollFrame.Position = UDim2.new(0, 10, 0, 92)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 6)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 26)
StatusLabel.Position = UDim2.new(0, 10, 1, -30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Scanning..."
StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- == RENDER LIST == --
local function RenderEggList()
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for idx, data in ipairs(EggList) do
        local Entry = Instance.new("TextButton")
        Entry.Size = UDim2.new(1, -8, 0, 50)
        Entry.BackgroundColor3 = (SelectedEgg == data.Instance) and Color3.fromRGB(55, 70, 130) or Color3.fromRGB(28, 28, 38)
        Entry.Text = ""
        Entry.Parent = ScrollFrame
        Instance.new("UICorner", Entry).CornerRadius = UDim.new(0, 6)

        local RarityColor = Color3.fromRGB(200, 200, 200)
        local r = tostring(data.Rarity):lower()
        if r:find("divine") then RarityColor = Color3.fromRGB(255, 215, 0)
        elseif r:find("secret") then RarityColor = Color3.fromRGB(255, 50, 50)
        elseif r:find("eternal") then RarityColor = Color3.fromRGB(200, 100, 255)
        elseif r:find("cosmic") then RarityColor = Color3.fromRGB(100, 200, 255)
        elseif r:find("myth") then RarityColor = Color3.fromRGB(255, 100, 200)
        elseif r:find("legend") then RarityColor = Color3.fromRGB(255, 200, 50)
        elseif r:find("epic") then RarityColor = Color3.fromRGB(180, 80, 255)
        elseif r:find("rare") then RarityColor = Color3.fromRGB(80, 150, 255)
        end

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -16, 0, 18)
        NameLabel.Position = UDim2.new(0, 8, 0, 3)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = idx .. ". " .. data.Name
        NameLabel.TextColor3 = RarityColor
        NameLabel.TextSize = 12
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Entry

        local InfoLabel = Instance.new("TextLabel")
        InfoLabel.Size = UDim2.new(1, -16, 0, 15)
        InfoLabel.Position = UDim2.new(0, 8, 0, 24)
        InfoLabel.BackgroundTransparency = 1
        InfoLabel.Text = data.Rarity .. " | Size: " .. data.Size .. " | $" .. data.Price
        InfoLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
        InfoLabel.TextSize = 10
        InfoLabel.Font = Enum.Font.Gotham
        InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
        InfoLabel.Parent = Entry

        Entry.MouseButton1Click:Connect(function()
            SelectedEgg = data.Instance
            StatusLabel.Text = "Target: " .. data.Name
            RenderEggList()

            if Stealing then return end
            Stealing = true

            task.spawn(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then Stealing = false; return end

                local part = data.Instance:IsA("BasePart") and data.Instance or data.Instance:FindFirstChildWhichIsA("BasePart")
                if not part then Stealing = false; return end

                local original = hrp.CFrame
                hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
                task.wait(0.15)

                if part:FindFirstChildOfClass("ClickDetector") then
                    fireclickdetector(part:FindFirstChildOfClass("ClickDetector"))
                end
                if part:FindFirstChildOfClass("ProximityPrompt") then
                    fireproximityprompt(part:FindFirstChildOfClass("ProximityPrompt"))
                end
                pcall(function() firetouchinterest(hrp, part, 0) end)
                task.wait(0.1)
                pcall(function() firetouchinterest(hrp, part, 1) end)

                task.wait(0.4)
                hrp.CFrame = original
                StatusLabel.Text = "Done: " .. data.Name
                Stealing = false
            end)
        end)

        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 15)
    end
end

-- == TOGGLE OPEN/CLOSE == --
SkullIcon.MouseButton1Click:Connect(function()
    IsOpen = not IsOpen
    MainFrame.Visible = IsOpen
end)

CloseBtn.MouseButton1Click:Connect(function()
    IsOpen = false
    MainFrame.Visible = false
end)

-- == SORT BUTTON == --
SortBtn.MouseButton1Click:Connect(function()
    local modes = {"rarity", "size", "price"}
    local labels = {"Rarity > Size", "Size (Besar)", "Price (Mahal)"}
    local idx = table.find(modes, CONFIG.SortMode) or 1
    idx = idx % 3 + 1
    CONFIG.SortMode = modes[idx]
    SortBtn.Text = "Sort: " .. labels[idx]
    SortEggs()
    RenderEggList()
end)

-- == LOOP SCAN == --
task.spawn(function()
    while task.wait(CONFIG.ScanInterval) do
        ScanEggs()
        SortEggs()
        RenderEggList()
        StatusLabel.Text = #EggList .. " egg di field"
    end
end)

ScanEggs()
SortEggs()
RenderEggList()
StatusLabel.Text = #EggList .. " egg di field"

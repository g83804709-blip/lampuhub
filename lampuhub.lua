-- == KONFIGURASI MOBILE == --
local CONFIG = {
    EggContainer = workspace:WaitForChild("Eggs", 10),
    ScanInterval = 4,
    SortMode = "rarity",
    AutoStealEnabled = true,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local EggList = {}
local SelectedEgg = nil
local IsGuiOpen = true
local Stealing = false

local RarityOrder = {
    ["Secret"] = 1, ["Eternal"] = 2, ["Divine"] = 3,
    ["Cosmic"] = 4, ["Mythic"] = 5, ["Mythical"] = 5,
    ["Legendary"] = 6, ["Epic"] = 7, ["VeryRare"] = 8,
    ["Rare"] = 9, ["Uncommon"] = 10, ["Common"] = 11,
}

local function GetEggData(egg)
    local rarity = "Common"
    local size = 1
    local price = 0

    local ok, val = pcall(function() return egg:GetAttribute("Rarity") end)
    if ok and val then rarity = val
    elseif egg:FindFirstChild("Rarity") then rarity = egg.Rarity.Value end

    ok, val = pcall(function() return egg:GetAttribute("Size") end)
    if ok and val then size = val
    elseif egg:FindFirstChild("Size") then size = egg.Size.Value end

    ok, val = pcall(function() return egg:GetAttribute("Price") end)
    if ok and val then price = val
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

-- == GUI MOBILE-OPTIMIZED == --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggScannerMobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.45, 0, 0.7, 0)
MainFrame.Position = UDim2.new(0, 10, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 34)
Title.Position = UDim2.new(0, 10, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "EGG SCANNER"
Title.TextColor3 = Color3.fromRGB(255, 200, 60)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 36, 0, 36)
ToggleBtn.Position = UDim2.new(1, -46, 0, 4)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ToggleBtn.Text = "X"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.TextSize = 18
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local SortBtn = Instance.new("TextButton")
SortBtn.Size = UDim2.new(1, -20, 0, 34)
SortBtn.Position = UDim2.new(0, 10, 0, 44)
SortBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
SortBtn.Text = "Sort: Rarity > Size"
SortBtn.TextColor3 = Color3.fromRGB(255, 200, 60)
SortBtn.TextSize = 13
SortBtn.Font = Enum.Font.GothamBold
SortBtn.Parent = MainFrame
Instance.new("UICorner", SortBtn).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -130)
ScrollFrame.Position = UDim2.new(0, 10, 0, 84)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
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

-- == RENDER == --
local function RenderEggList()
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for idx, data in ipairs(EggList) do
        local Entry = Instance.new("TextButton")
        Entry.Size = UDim2.new(1, -8, 0, 50)
        Entry.BackgroundColor3 = (SelectedEgg == data.Instance) and Color3.fromRGB(55, 70, 130) or Color3.fromRGB(30, 30, 40)
        Entry.Text = ""
        Entry.Parent = ScrollFrame
        Instance.new("UICorner", Entry).CornerRadius = UDim.new(0, 6)

        local RarityColor = Color3.fromRGB(200, 200, 200)
        local r = data.Rarity:lower()
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
        InfoLabel.Text = data.Rarity .. " | " .. data.Size .. " | $" .. data.Price
        InfoLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
        InfoLabel.TextSize = 10
        InfoLabel.Font = Enum.Font.Gotham
        InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
        InfoLabel.Parent = Entry

        Entry.MouseButton1Click:Connect(function()
            SelectedEgg = data.Instance
            StatusLabel.Text = "Target: " .. data.Name
            RenderEggList()
            if CONFIG.AutoStealEnabled then
                task.spawn(function()
                    if Stealing then return end
                    Stealing = true
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
                    firetouchinterest(hrp, part, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, part, 1)

                    task.wait(0.4)
                    hrp.CFrame = original
                    StatusLabel.Text = "Done: " .. data.Name
                    Stealing = false
                end)
            end
        end)

        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 15)
    end
end

-- == TOMBOL == --
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

ToggleBtn.MouseButton1Click:Connect(function()
    IsGuiOpen = not IsGuiOpen
    MainFrame.Visible = IsGuiOpen
end)

-- == LOOP == --
task.spawn(function()
    while task.wait(CONFIG.ScanInterval) do
        ScanEggs()
        SortEggs()
        RenderEggList()
        StatusLabel.Text = #EggList .. " eggs found"
    end
end)

ScanEggs()
SortEggs()
RenderEggList()
StatusLabel.Text = #EggList .. " eggs found"

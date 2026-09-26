-- LOW POP SERVER HOPPER + FLOATING GUI
-- Universal — auto baca PlaceId

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local MIN_PLAYERS = 1
local MAX_PLAYERS = 3
local MAX_ATTEMPTS = 100
local RETRY_DELAY = 2
-- =================================

-- HAPUS GUI LAMA KALAU ADA
if CoreGui:FindFirstChild("HopGui") then
    CoreGui.HopGui:Destroy()
end

-- ============ BUILD GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HopGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 240, 0, 200)
Main.Position = UDim2.new(0, 20, 0, 100)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 200, 255)
Stroke.Thickness = 1.5
Stroke.Parent = Main

-- HEADER
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Hop Panel"
Title.TextColor3 = Color3.fromRGB(80, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- TOMBOL MINIMIZE
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -30, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- STATUS TEXT
local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -20, 0, 40)
Status.Position = UDim2.new(0, 10, 0, 40)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextWrapped = true
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Top
Status.Parent = Main

-- INFO SERVER
local Info = Instance.new("TextLabel")
Info.Name = "Info"
Info.Size = UDim2.new(1, -20, 0, 50)
Info.Position = UDim2.new(0, 10, 0, 82)
Info.BackgroundTransparency = 1
Info.Text = "Server: -\nPlayer: -/-"
Info.TextColor3 = Color3.fromRGB(150, 220, 255)
Info.Font = Enum.Font.Code
Info.TextSize = 11
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.Parent = Main

-- TOMBOL START
local StartBtn = Instance.new("TextButton")
StartBtn.Name = "StartBtn"
StartBtn.Size = UDim2.new(0.5, -14, 0, 34)
StartBtn.Position = UDim2.new(0, 10, 1, -44)
StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
StartBtn.Text = "▶ START"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 12
StartBtn.BorderSizePixel = 0
StartBtn.Parent = Main

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 8)
StartCorner.Parent = StartBtn

-- TOMBOL STOP
local StopBtn = Instance.new("TextButton")
StopBtn.Name = "StopBtn"
StopBtn.Size = UDim2.new(0.5, -14, 0, 34)
StopBtn.Position = UDim2.new(0.5, 4, 1, -44)
StopBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
StopBtn.Text = "■ STOP"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
StopBtn.BorderSizePixel = 0
StopBtn.Parent = Main

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 8)
StopCorner.Parent = StopBtn

-- MINIMIZE LOGIC
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = UDim2.new(0, 240, 0, 32)
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 240, 0, 200)
        MinBtn.Text = "–"
    end
end)

-- ============ HELPER UPDATE ============
local function setStatus(text, color)
    Status.Text = "Status: " .. text
    Status.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

local function setInfo(jobId, playing, maxPlayers)
    if jobId then
        Info.Text = string.format("Server: %s\nPlayer: %d/%d", string.sub(jobId, 1, 12) .. "...", playing, maxPlayers)
    else
        Info.Text = "Server: -\nPlayer: -/-"
    end
end

-- ============ CORE FUNCTIONS ============
local running = false

local function fetchServers(placeId)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        placeId
    )
    local ok, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not response or not response.data then
        return {}
    end
    return response.data
end

local function filterServers(servers)
    local out = {}
    for _, srv in ipairs(servers) do
        if srv.id
            and srv.playing
            and srv.playing >= MIN_PLAYERS
            and srv.playing <= MAX_PLAYERS
            and srv.id ~= game.JobId
        then
            table.insert(out, srv)
        end
    end
    return out
end

local function sortServers(servers)
    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)
    return servers
end

local function hopToServer(jobId)
    local opts = Instance.new("TeleportOptions")
    opts.ServerInstanceId = jobId
    opts.ShouldReserveServer = false

    local ok, err = pcall(function()
        TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, opts)
    end)

    if not ok then
        warn("[Hop] Teleport gagal: " .. tostring(err))
        return false
    end
    return true
end

-- ============ MAIN LOOP ============
local function main()
    running = true
    StartBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 60)
    setStatus("Mencari server 1-3 player...", Color3.fromRGB(255, 220, 100))

    local attempt = 0
    while running and attempt < MAX_ATTEMPTS do
        attempt += 1
        setStatus(string.format("Attempt #%d — scanning...", attempt), Color3.fromRGB(255, 220, 100))

        local servers = fetchServers(game.PlaceId)
        local candidates = sortServers(filterServers(servers))

        if #candidates > 0 then
            local target = candidates[1]
            setInfo(target.id, target.playing, target.maxPlayers)
            setStatus(string.format("Ketemu! Teleport ke %d player...", target.playing), Color3.fromRGB(100, 255, 150))

            if hopToServer(target.id) then
                setStatus("Teleport sukses!", Color3.fromRGB(100, 255, 150))
                return
            end
        else
            setStatus(string.format("Attempt #%d — belum ada, retry...", attempt), Color3.fromRGB(255, 180, 100))
        end

        task.wait(RETRY_DELAY)
    end

    if running then
        setStatus("Gagal nemu server. Naikin MAX_PLAYERS.", Color3.fromRGB(255, 120, 120))
    else
        setStatus("Dihentikan user.", Color3.fromRGB(180, 180, 180))
    end
    StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
    running = false
end

-- ============ BUTTON EVENTS ============
StartBtn.MouseButton1Click:Connect(function()
    if running then return end
    task.spawn(main)
end)

StopBtn.MouseButton1Click:Connect(function()
    running = false
    setStatus("Dihentikan user.", Color3.fromRGB(180, 180, 180))
    StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
end)

setStatus("Idle — pencet START", Color3.fromRGB(200, 200, 200))
setInfo(nil)

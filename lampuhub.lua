--[[
    SERVER HOP PANEL — FULL VERSION (FIXED)
    Floating GUI + Manual Teleport + Live Validation + Realistic Success Detection

    PERUBAHAN DARI VERSI ASLI:
    1. Sistem drag: dulu tiap InputBegan bikin koneksi input.Changed baru
       tanpa pernah disconnect -> numpuk terus tiap kali drag (leak).
       Sekarang pakai satu koneksi UserInputService.InputEnded aja.
    2. Deteksi gagal teleport: dulu cuma nebak "gagal" kalau masih di
       JobId yang sama setelah N detik. Sekarang dengar event resmi
       TeleportService.TeleportInitFailed, jadi tahu PERSIS alasannya
       (server penuh / flood / dll) dan bisa react lebih cepat, gak
       harus nunggu penuh TELEPORT_CHECK_TIME tiap kali.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local MIN_PLAYERS = 1
local MAX_PLAYERS = 3
local SCAN_DELAY = 5
local MAX_ATTEMPTS = 20
local TELEPORT_CHECK_TIME = 4 -- detik nunggu konfirmasi teleport

-- true  = Roblox public API (game publik / executor)
-- false = custom (game sendiri / Studio)
local USE_ROBLOX_API = true

--==================================================
-- GUI
--==================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("ServerHopGui")
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

--==================================================
-- MAIN FRAME
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(280, 270)
Main.Position = UDim2.new(0, 20, 0.5, -135)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 200, 255)
Stroke.Thickness = 1.5
Stroke.Parent = Main

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Server Hop"
Title.TextColor3 = Color3.fromRGB(80, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -33, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header

Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 42)
Status.Position = UDim2.fromOffset(10, 48)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle"
Status.TextColor3 = Color3.fromRGB(200,200,200)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextWrapped = true
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Top
Status.Parent = Main

--==================================================
-- SERVER INFO
--==================================================

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 55)
Info.Position = UDim2.fromOffset(10, 92)
Info.BackgroundTransparency = 1
Info.Text = "Server: -\nPlayers: -/-\nScan: -"
Info.TextColor3 = Color3.fromRGB(150,220,255)
Info.Font = Enum.Font.Code
Info.TextSize = 11
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.Parent = Main

--==================================================
-- TELEPORT BUTTON
--==================================================

local TpBtn = Instance.new("TextButton")
TpBtn.Name = "TeleportButton"
TpBtn.Size = UDim2.new(1, -20, 0, 38)
TpBtn.Position = UDim2.fromOffset(10, 152)
TpBtn.BackgroundColor3 = Color3.fromRGB(55,55,70)
TpBtn.Text = "📡  TELEPORT KE SERVER"
TpBtn.TextColor3 = Color3.fromRGB(150,150,150)
TpBtn.Font = Enum.Font.GothamBold
TpBtn.TextSize = 11
TpBtn.BorderSizePixel = 0
TpBtn.AutoButtonColor = true
TpBtn.Parent = Main

Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 8)

--==================================================
-- START BUTTON
--==================================================

local StartBtn = Instance.new("TextButton")
StartBtn.Name = "StartButton"
StartBtn.Size = UDim2.new(0.5, -15, 0, 38)
StartBtn.Position = UDim2.new(0, 10, 1, -48)
StartBtn.BackgroundColor3 = Color3.fromRGB(40,160,90)
StartBtn.Text = "▶ START"
StartBtn.TextColor3 = Color3.fromRGB(255,255,255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 12
StartBtn.BorderSizePixel = 0
StartBtn.Parent = Main

Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

--==================================================
-- STOP BUTTON
--==================================================

local StopBtn = Instance.new("TextButton")
StopBtn.Name = "StopButton"
StopBtn.Size = UDim2.new(0.5, -15, 0, 38)
StopBtn.Position = UDim2.new(0.5, 5, 1, -48)
StopBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
StopBtn.Text = "■ STOP"
StopBtn.TextColor3 = Color3.fromRGB(255,255,255)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
StopBtn.BorderSizePixel = 0
StopBtn.Parent = Main

Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 8)

--==================================================
-- DRAG SYSTEM (FIXED: gak numpuk koneksi lagi)
--==================================================

local dragging = false
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end)

--==================================================
-- STATE
--==================================================

local running = false
local minimized = false
local tpEnabled = false
local teleporting = false

local currentServerId = nil
local currentPlayers = nil
local currentMaxPlayers = nil

local normalHeight = 270

--==================================================
-- HELPERS
--==================================================

local function setStatus(text, color)
    Status.Text = "Status: " .. text
    Status.TextColor3 = color or Color3.fromRGB(200,200,200)
end

local function updateInfo(scan)
    local serverText = "-"
    if currentServerId then
        serverText = string.sub(currentServerId, 1, 12) .. "..."
    end

    local playersText = "-/-"
    if currentPlayers and currentMaxPlayers then
        playersText = tostring(currentPlayers) .. "/" .. tostring(currentMaxPlayers)
    end

    Info.Text = "Server: " .. serverText
        .. "\nPlayers: " .. playersText
        .. "\nScan: " .. tostring(scan or "-")
end

local function enableTeleport(enabled)
    tpEnabled = enabled

    if enabled then
        TpBtn.BackgroundColor3 = Color3.fromRGB(70,130,220)
        TpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    else
        TpBtn.BackgroundColor3 = Color3.fromRGB(55,55,70)
        TpBtn.TextColor3 = Color3.fromRGB(150,150,150)
    end
end

--==================================================
-- MINIMIZE
--==================================================

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        Main.Size = UDim2.fromOffset(280, 38)
        MinBtn.Text = "+"

        Status.Visible = false
        Info.Visible = false
        TpBtn.Visible = false
        StartBtn.Visible = false
        StopBtn.Visible = false
    else
        Main.Size = UDim2.fromOffset(280, normalHeight)
        MinBtn.Text = "−"

        Status.Visible = true
        Info.Visible = true
        TpBtn.Visible = true
        StartBtn.Visible = true
        StopBtn.Visible = true
    end
end)

--==================================================
-- SERVER LIST PROVIDERS
--==================================================

local function getAvailableServersCustom()
    return {}
end

local function getAvailableServersAPI()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )

    local ok, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not response or not response.data then
        return {}
    end

    return response.data
end

local function getAvailableServers()
    if USE_ROBLOX_API then
        return getAvailableServersAPI()
    else
        return getAvailableServersCustom()
    end
end

--==================================================
-- LIVE VALIDATION
--==================================================

local function isServerStillAvailable(serverId)
    local servers = getAvailableServers()

    for _, srv in ipairs(servers) do
        if srv.id == serverId then
            local p = tonumber(srv.playing) or 0
            local mp = tonumber(srv.maxPlayers) or 0

            if p >= MIN_PLAYERS and p <= MAX_PLAYERS then
                return true, p, mp
            else
                return false, nil, nil, string.format("Server udah %d/%d", p, mp)
            end
        end
    end

    return false, nil, nil, "Server udah gak ada di list"
end

local function findNewServer()
    local servers = getAvailableServers()

    local best = nil
    local bestPlayers = math.huge

    for _, srv in ipairs(servers) do
        if srv.id
            and srv.playing
            and srv.playing >= MIN_PLAYERS
            and srv.playing <= MAX_PLAYERS
            and srv.id ~= game.JobId then
            if srv.playing < bestPlayers then
                bestPlayers = srv.playing
                best = srv
            end
        end
    end

    return best
end

--==================================================
-- TELEPORT FAILURE TRACKING (BARU)
-- Ganti tebakan "masih di server yang sama = gagal" dengan
-- event resmi Roblox, jadi tahu ALASAN gagalnya secara pasti.
--==================================================

local lastTeleportResult = nil
local lastTeleportError = nil

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        lastTeleportResult = teleportResult
        lastTeleportError = errorMessage
    end
end)

local function teleportResultToText(result)
    if result == Enum.TeleportResult.GameFull then
        return "Server sudah penuh"
    elseif result == Enum.TeleportResult.Flooded then
        return "Kebanyakan request teleport, coba lagi sebentar"
    elseif result == Enum.TeleportResult.GameNotFound then
        return "Server gak ketemu lagi"
    elseif result == Enum.TeleportResult.GameEnded then
        return "Server udah berakhir"
    elseif result == Enum.TeleportResult.Unauthorized then
        return "Gak diizinkan teleport ke server ini"
    else
        return "Teleport gagal"
    end
end

-- Nunggu event TeleportInitFailed sampai `seconds` detik.
-- return true  -> gak ada event gagal dalam waktu itu (dianggap berhasil;
--                 kalau BENERAN berhasil, script ini duluan berhenti jalan
--                 karena server client-nya udah pindah)
-- return false, result, errMsg -> ketauan gagal, lengkap sama alasannya
local function waitForTeleportOutcome(seconds)
    lastTeleportResult = nil
    lastTeleportError = nil

    local elapsed = 0
    while elapsed < seconds do
        if lastTeleportResult then
            return false, lastTeleportResult, lastTeleportError
        end
        task.wait(0.25)
        elapsed += 0.25
    end

    return true, nil, nil
end

--==================================================
-- TELEPORT — REALISTIC DETECTION
--==================================================

local function tryTeleport(serverId)
    local success, err = pcall(function()
        local options = Instance.new("TeleportOptions")
        options.ServerInstanceId = serverId
        TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, options)
    end)

    if success then
        return true, nil
    end

    warn("[ServerHop] TeleportAsync error: " .. tostring(err))

    local ok2, err2 = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)

    if ok2 then
        return true, nil
    end

    return false, tostring(err2 or err)
end

local function teleportToServer(serverId)
    if not serverId then
        setStatus("Belum ada server target.", Color3.fromRGB(255,120,120))
        return
    end

    if teleporting then return end
    teleporting = true

    setStatus("Validasi server...", Color3.fromRGB(255,220,100))
    task.wait(0.3)

    -- VALIDASI LIVE
    local stillOk = isServerStillAvailable(serverId)

    if not stillOk then
        setStatus("Server penuh! Cari pengganti...", Color3.fromRGB(255,180,100))
        task.wait(0.5)

        local replacement = findNewServer()
        if replacement then
            currentServerId = replacement.id
            currentPlayers = replacement.playing
            currentMaxPlayers = replacement.maxPlayers
            updateInfo("-")
            setStatus(
                string.format("Pengganti: %d player. Klik TELEPORT lagi!", replacement.playing),
                Color3.fromRGB(100,255,150)
            )
        else
            setStatus("Gak ada pengganti. Scan ulang.", Color3.fromRGB(255,120,120))
            currentServerId = nil
            enableTeleport(false)
        end

        teleporting = false
        return
    end

    -- TELEPORT
    setStatus("Mengirim request teleport...", Color3.fromRGB(255,220,100))

    local ok, errMsg = tryTeleport(serverId)

    if not ok then
        setStatus("Request teleport ditolak.", Color3.fromRGB(255,120,120))
        teleporting = false
        return
    end

    -- KONFIRMASI (pakai event resmi, bukan tebakan lagi)
    setStatus("Nunggu konfirmasi teleport...", Color3.fromRGB(255,220,100))

    local success2, failResult, failMsg = waitForTeleportOutcome(TELEPORT_CHECK_TIME)

    if success2 then
        setStatus("Teleport berhasil!", Color3.fromRGB(100,255,150))
        teleporting = false
        return
    end

    -- GAGAL — CARI PENGGANTI
    local reasonText = teleportResultToText(failResult)
    warn("[ServerHop] TeleportInitFailed: " .. reasonText .. " - " .. tostring(failMsg))
    setStatus(reasonText .. ". Cari pengganti...", Color3.fromRGB(255,180,100))
    task.wait(0.5)

    local replacement = findNewServer()
    if replacement then
        currentServerId = replacement.id
        currentPlayers = replacement.playing
        currentMaxPlayers = replacement.maxPlayers
        updateInfo("-")
        setStatus(
            string.format("Pengganti: %d player. Klik TELEPORT lagi!", replacement.playing),
            Color3.fromRGB(100,255,150)
        )
    else
        setStatus("Gak ada pengganti. Scan ulang.", Color3.fromRGB(255,120,120))
        currentServerId = nil
        enableTeleport(false)
    end

    teleporting = false
end

--==================================================
-- SCAN
--==================================================

local function scanServers()
    if running then return end
    running = true

    currentServerId = nil
    currentPlayers = nil
    currentMaxPlayers = nil

    enableTeleport(false)
    StartBtn.BackgroundColor3 = Color3.fromRGB(30,100,60)
    setStatus("Memulai pencarian...", Color3.fromRGB(255,220,100))

    for attempt = 1, MAX_ATTEMPTS do
        if not running then break end

        setStatus(
            "Scanning... " .. tostring(attempt) .. "/" .. tostring(MAX_ATTEMPTS),
            Color3.fromRGB(255,220,100)
        )
        updateInfo(attempt)

        local servers = getAvailableServers()
        local target = nil

        for _, server in ipairs(servers) do
            if not running then break end

            local players = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0
            local serverId = server.id

            if serverId
                and serverId ~= game.JobId
                and players >= MIN_PLAYERS
                and players <= MAX_PLAYERS then
                target = server
                break
            end
        end

        if target then
            currentServerId = target.id
            currentPlayers = target.playing
            currentMaxPlayers = target.maxPlayers

            updateInfo(attempt)
            setStatus("Server ditemukan! Klik TELEPORT.", Color3.fromRGB(100,255,150))
            enableTeleport(true)

            running = false
            StartBtn.BackgroundColor3 = Color3.fromRGB(40,160,90)
            return
        end

        if attempt < MAX_ATTEMPTS then
            for second = SCAN_DELAY, 1, -1 do
                if not running then break end
                setStatus(
                    "Belum ditemukan. Scan lagi dalam " .. tostring(second) .. " detik...",
                    Color3.fromRGB(255,180,100)
                )
                task.wait(1)
            end
        end
    end

    if running then
        setStatus("Pencarian selesai. Server tidak ditemukan.", Color3.fromRGB(255,120,120))
    else
        setStatus("Scan dihentikan.", Color3.fromRGB(180,180,180))
    end

    running = false
    StartBtn.BackgroundColor3 = Color3.fromRGB(40,160,90)
end

--==================================================
-- BUTTON EVENTS
--==================================================

StartBtn.MouseButton1Click:Connect(function()
    if running then return end
    task.spawn(scanServers)
end)

StopBtn.MouseButton1Click:Connect(function()
    if not running then
        setStatus("Tidak ada scan yang berjalan.", Color3.fromRGB(180,180,180))
        return
    end

    running = false
    setStatus("Menghentikan scan...", Color3.fromRGB(180,180,180))
    StartBtn.BackgroundColor3 = Color3.fromRGB(40,160,90)
end)

TpBtn.MouseButton1Click:Connect(function()
    if not tpEnabled then
        setStatus("Belum ada target server.", Color3.fromRGB(255,120,120))
        return
    end

    if not currentServerId then
        setStatus("Belum ada target server.", Color3.fromRGB(255,120,120))
        return
    end

    task.spawn(function()
        teleportToServer(currentServerId)
    end)
end)

--==================================================
-- INITIAL STATE
--==================================================

enableTeleport(false)
setStatus("Idle — tekan START.", Color3.fromRGB(200,200,200))
updateInfo("-")

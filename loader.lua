-- ============================================
-- SCRIPT LOADER + BROADCAST + AUTO-UPDATE
-- Taruh script ini di GitHub raw, user cuma load 1x
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer

-- ============================================
-- KONFIGURASI
-- ============================================
local CONFIG = {
    ScriptURL = "https://raw.githubusercontent.com/g83804709-blip/lampuhub/refs/heads/main/lampuhub.lua",
    VersionURL = "https://raw.githubusercontent.com/USERNAME/REPO/main/version.txt",
    BroadcastURL = "https://raw.githubusercontent.com/USERNAME/REPO/main/broadcast.txt",
    CurrentVersion = "1.0.0",
    CheckInterval = 60, -- cek update tiap 60 detik
    BroadcastInterval = 30, -- cek broadcast tiap 30 detik
}

-- ============================================
-- FUNGSI FETCH (HTTP GET)
-- ============================================
local function FetchURL(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if success then
        return result
    else
        warn("[LOADER] Gagal fetch: " .. url)
        return nil
    end
end

-- ============================================
-- AUTO-UPDATE SYSTEM
-- ============================================
local function CheckUpdate()
    local latestVersion = FetchURL(CONFIG.VersionURL)
    if not latestVersion then return end
    
    latestVersion = latestVersion:gsub("%s+", "") -- hapus whitespace
    
    if latestVersion ~= CONFIG.CurrentVersion then
        -- Ada update baru
        StarterGui:SetCore("SendNotification", {
            Title = "Update Tersedia!",
            Text = "Versi " .. latestVersion .. " siap di-download. Mengupdate...",
            Duration = 5
        })
        
        -- Download script baru
        local newScript = FetchURL(CONFIG.ScriptURL)
        if newScript then
            CONFIG.CurrentVersion = latestVersion
            local func, err = loadstring(newScript)
            if func then
                pcall(func)
                print("[LOADER] Berhasil update ke versi " .. latestVersion)
            else
                warn("[LOADER] Gagal load script baru: " .. tostring(err))
            end
        end
    end
end

-- ============================================
-- BROADCAST SYSTEM (Pesan dari Owner)
-- ============================================
local function CheckBroadcast()
    local broadcastMsg = FetchURL(CONFIG.BroadcastURL)
    if not broadcastMsg or broadcastMsg == "" then return end
    
    broadcastMsg = broadcastMsg:gsub("^%s+", ""):gsub("%s+$", "")
    
    if broadcastMsg ~= "" and broadcastMsg ~= "_lastBroadcast" then
        _lastBroadcast = broadcastMsg
        
        -- Kirim ke GUI player (pakai SetCore)
        StarterGui:SetCore("SendNotification", {
            Title = "📢 Pengumuman",
            Text = broadcastMsg,
            Duration = 10
        })
        
        print("[BROADCAST] " .. broadcastMsg)
    end
end

-- ============================================
-- CUSTOM CHAT (biar kayak screenshot)
-- ============================================
local function ShowCustomMessage(title, text, duration)
    local ScreenGui = LP:WaitForChild("PlayerGui"):FindFirstChild("BroadcastGui")
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "BroadcastGui"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = LP:WaitForChild("PlayerGui")
    end
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 400, 0, 120)
    Frame.Position = UDim2.new(0.5, -200, 0, 100)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame
    
    -- Header
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Header.BorderSizePixel = 0
    Header.Text = title
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold
    Header.Parent = Frame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header
    
    -- Isi pesan
    local Content = Instance.new("TextLabel")
    Content.Size = UDim2.new(1, -20, 0, 70)
    Content.Position = UDim2.new(0, 10, 0, 40)
    Content.BackgroundTransparency = 1
    Content.Text = text
    Content.TextColor3 = Color3.fromRGB(220, 220, 220)
    Content.TextSize = 13
    Content.Font = Enum.Font.Gotham
    Content.TextWrapped = true
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.TextYAlignment = Enum.TextYAlignment.Top
    Content.Parent = Frame
    
    -- Auto close
    task.delay(duration or 10, function()
        if Frame.Parent then
            Frame:Destroy()
        end
    end)
end

-- ============================================
-- LOOP CEK UPDATE & BROADCAST
-- ============================================
task.spawn(function()
    while true do
        task.wait(CONFIG.CheckInterval)
        pcall(CheckUpdate)
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.BroadcastInterval)
        pcall(CheckBroadcast)
    end
end)

-- Cek sekali di awal
pcall(CheckUpdate)
pcall(CheckBroadcast)

print("[LOADER] Script Loader aktif. Versi: " .. CONFIG.CurrentVersion)

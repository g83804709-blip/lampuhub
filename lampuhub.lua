-- LOW POP SERVER HOPPER (1-3 PLAYER)
-- Universal — auto baca PlaceId, cocok untuk "Steal an Egg"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local MIN_PLAYERS = 1      -- minimal 1 player di server target
local MAX_PLAYERS = 3      -- maksimal 3 player di server target
local MAX_ATTEMPTS = 100    -- berapa kali cek sebelum nyerah
local RETRY_DELAY = 2      -- jeda antar percobaan (detik)
-- =================================

-- AMBIL DAFTAR SERVER DARI ROBLOX API
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

-- FILTER: player 1-3, bukan server sendiri
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

-- SORT: paling sedikit player di depan
local function sortServers(servers)
    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)
    return servers
end

-- TELEPORT KE SERVER TARGET
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

-- MAIN
local function main()
    print(string.format("[Hop] Cari server dengan %d-%d player...", MIN_PLAYERS, MAX_PLAYERS))
    local attempt = 0

    while attempt < MAX_ATTEMPTS do
        attempt += 1

        local servers = fetchServers(game.PlaceId)
        local candidates = sortServers(filterServers(servers))

        if #candidates > 0 then
            local target = candidates[1]
            print(string.format(
                "[Hop] Ketemu! Server %s | %d/%d player | Attempt #%d",
                target.id, target.playing, target.maxPlayers, attempt
            ))
            if hopToServer(target.id) then
                return
            end
        else
            print(string.format("[Hop] Attempt #%d — belum ada server 1-3 player, retry...", attempt))
        end

        task.wait(RETRY_DELAY)
    end

    warn("[Hop] Gagal nemu server 1-3 player setelah " .. MAX_ATTEMPTS .. " percobaan.")
    warn("[Hop] Coba lagi nanti atau naikin MAX_ATTEMPTS / MAX_PLAYERS.")
end

main()

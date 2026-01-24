-- Script Pemindai Ikan Secret & Pengirim Webhook
-- Dibuat berdasarkan logika database game Fisch

local WEBHOOK_URL = "https://discord.com/api/webhooks/1461657990762594405/hy05f2f7jevgMXwnNpfpKmx9fYZT9_NkvvdTtkxa4eL_wa7F9AQ4Mvh1N_EpXPXTX3eo" -- [[ GANTI INI DENGAN URL WEBHOOK KAMU ]]

-- Layanan yang dibutuhkan
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui") -- Ditambahkan untuk notifikasi layar

-- Fungsi request HTTP (Kompatibilitas berbagai eksekutor)
local httpRequest = (syn and syn.request) or (http and http.request) or (http_request) or (fluxus and fluxus.request) or request

-- Daftar Tier berdasarkan script asli game
local TierList = {
    "Uncommon",
    "Common",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Secret" -- Kita menargetkan index ini
}

-- Fungsi Notifikasi Visual
local function notify(judul, pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = judul;
            Text = pesan;
            Duration = 5;
        })
    end)
    -- Tetap print ke console untuk debugging
    if judul == "Error" or judul == "Peringatan" then
        warn(judul .. ": " .. pesan)
    else
        print(judul .. ": " .. pesan)
    end
end

-- Fungsi utama
local function scanAndSend()
    if not httpRequest then
        notify("Error", "Eksekutor kamu tidak mendukung HTTP Request!")
        return
    end

    if WEBHOOK_URL == "" or WEBHOOK_URL == "MASUKKAN_WEBHOOK_URL_DISINI" then
        notify("Peringatan", "Mohon masukkan Webhook URL di script!")
        return
    end

    notify("Status", "Sedang memindai database...")

    local itemsFolder = ReplicatedStorage:WaitForChild("Items", 10)
    if not itemsFolder then
        notify("Error", "Folder Items tidak ditemukan/gagal dimuat!")
        return
    end

    local secretFishes = {}
    local counter = 0

    -- Loop melalui semua ModuleScript di folder Items
    for _, itemModule in ipairs(itemsFolder:GetChildren()) do
        if itemModule:IsA("ModuleScript") then
            -- Gunakan pcall agar jika ada error pada satu item, script tidak berhenti
            local success, result = pcall(require, itemModule)
            
            if success and type(result) == "table" and result.Data then
                local data = result.Data
                
                -- Cek apakah tipe item adalah "Fishes"
                if data.Type == "Fishes" then
                    -- Cek Tier-nya
                    local tierName = TierList[data.Tier]
                    
                    -- Jika Tier adalah "Secret", simpan namanya
                    if tierName == "Secret" then
                        table.insert(secretFishes, data.Name)
                        counter = counter + 1
                        print("Ditemukan Ikan Secret: " .. data.Name)
                    end
                end
            end
        end
    end

    -- Jika tidak ada ikan secret ditemukan
    if #secretFishes == 0 then
        notify("Info", "Tidak ada ikan Secret ditemukan di database.")
        return
    end

    -- Format pesan untuk Discord
    local fishListString = table.concat(secretFishes, "\n- ")
    
    local embedData = {
        ["username"] = "Fish Scanner Bot",
        ["avatar_url"] = "https://i.imgur.com/WltO8IG.png", -- Ikon pancing
        ["embeds"] = {{
            ["title"] = "Database Ikan Secret Ditemukan",
            ["description"] = string.format("Berhasil memindai **%d** ikan dengan rarity **Secret** dari file game.", counter),
            ["color"] = 16711680, -- Warna Merah
            ["fields"] = {
                {
                    ["name"] = "Daftar Nama Ikan:",
                    ["value"] = "```\n- " .. fishListString .. "\n```",
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Fisch Database Scanner"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }}
    }

    -- Mengirim ke Webhook
    local response = httpRequest({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(embedData)
    })

    if response and (response.StatusCode == 200 or response.StatusCode == 204) then
        notify("Sukses", "Data berhasil dikirim ke Discord!")
    else
        notify("Gagal", "Gagal kirim Webhook. Code: " .. (response and response.StatusCode or "Unknown"))
    end
end

-- Jalankan fungsi
scanAndSend()

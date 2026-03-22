--[[---------------------------------------------------------------------------
Z-Grad RP — Donate System (Server)
Серверная часть: SQLite база, покупка скинов, инвентарь, экипировка,
администраторские команды, применение скинов при спавне.
---------------------------------------------------------------------------]]

print("[Z-Grad RP] Donate System (Server) LOADING...")

-- =============================================
-- БАЗА ДАННЫХ (SQLite)
-- =============================================
local function InitDB()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS zgrad_donate_coins (
            steamid TEXT PRIMARY KEY,
            coins INTEGER DEFAULT 0
        )
    ]])

    sql.Query([[
        CREATE TABLE IF NOT EXISTS zgrad_donate_inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            steamid TEXT NOT NULL,
            skin_id TEXT NOT NULL,
            equipped INTEGER DEFAULT 0,
            UNIQUE(steamid, skin_id)
        )
    ]])

    print("[Z-Grad RP] Donate DB initialized")
end
InitDB()

-- =============================================
-- УТИЛИТЫ БАЗЫ
-- =============================================
local function GetCoins(steamid)
    local row = sql.QueryRow("SELECT coins FROM zgrad_donate_coins WHERE steamid = " .. sql.SQLStr(steamid))
    if row then
        return tonumber(row.coins) or 0
    end
    return 0
end

local function SetCoins(steamid, amount)
    amount = math.max(0, math.floor(amount))
    sql.Query("INSERT OR REPLACE INTO zgrad_donate_coins (steamid, coins) VALUES (" .. sql.SQLStr(steamid) .. ", " .. amount .. ")")
end

local function AddCoins(steamid, amount)
    local current = GetCoins(steamid)
    SetCoins(steamid, current + amount)
end

local function HasSkin(steamid, skinID)
    local row = sql.QueryRow("SELECT id FROM zgrad_donate_inventory WHERE steamid = " .. sql.SQLStr(steamid) .. " AND skin_id = " .. sql.SQLStr(skinID))
    return row ~= nil
end

local function GiveSkin(steamid, skinID)
    if HasSkin(steamid, skinID) then return false end
    sql.Query("INSERT INTO zgrad_donate_inventory (steamid, skin_id, equipped) VALUES (" .. sql.SQLStr(steamid) .. ", " .. sql.SQLStr(skinID) .. ", 0)")
    return true
end

local function GetInventory(steamid)
    local rows = sql.Query("SELECT skin_id, equipped FROM zgrad_donate_inventory WHERE steamid = " .. sql.SQLStr(steamid))
    if not rows then return {} end
    
    local inv = {}
    for _, row in ipairs(rows) do
        inv[row.skin_id] = (tonumber(row.equipped) or 0) == 1
    end
    return inv
end

local function SetEquipped(steamid, skinID, equipped)
    local val = equipped and 1 or 0
    sql.Query("UPDATE zgrad_donate_inventory SET equipped = " .. val .. " WHERE steamid = " .. sql.SQLStr(steamid) .. " AND skin_id = " .. sql.SQLStr(skinID))
end

-- Снять все скины для конкретной профессии
local function UnequipAllForJob(steamid, jobCommand)
    local inv = GetInventory(steamid)
    for skinID, isEquipped in pairs(inv) do
        if isEquipped then
            local skinData = ZGRAD_GetSkinByID(skinID)
            if skinData and skinData.job == jobCommand then
                SetEquipped(steamid, skinID, false)
            end
        end
    end
end

-- Получить экипированный скин для профессии
local function GetEquippedSkinForJob(steamid, jobCommand)
    local inv = GetInventory(steamid)
    for skinID, isEquipped in pairs(inv) do
        if isEquipped then
            local skinData = ZGRAD_GetSkinByID(skinID)
            if skinData and skinData.job == jobCommand then
                return skinData
            end
        end
    end
    return nil
end

-- =============================================
-- СЕТЕВЫЕ СООБЩЕНИЯ
-- =============================================
util.AddNetworkString("ZGrad_Donate_SyncCoins")
util.AddNetworkString("ZGrad_Donate_SyncInventory")
util.AddNetworkString("ZGrad_Donate_BuySkin")
util.AddNetworkString("ZGrad_Donate_EquipSkin")
util.AddNetworkString("ZGrad_Donate_UnequipSkin")
util.AddNetworkString("ZGrad_Donate_Notify")
util.AddNetworkString("ZGrad_Donate_RequestSync")

-- Отправить монеты клиенту
local function SyncCoins(ply)
    local coins = GetCoins(ply:SteamID())
    net.Start("ZGrad_Donate_SyncCoins")
        net.WriteInt(coins, 32)
    net.Send(ply)
end

-- Отправить инвентарь клиенту
local function SyncInventory(ply)
    local inv = GetInventory(ply:SteamID())
    net.Start("ZGrad_Donate_SyncInventory")
        net.WriteUInt(table.Count(inv), 16)
        for skinID, equipped in pairs(inv) do
            net.WriteString(skinID)
            net.WriteBool(equipped)
        end
    net.Send(ply)
end

-- Уведомление
local function NotifyDonate(ply, msg, isError)
    net.Start("ZGrad_Donate_Notify")
        net.WriteString(msg)
        net.WriteBool(isError or false)
    net.Send(ply)
end

-- =============================================
-- ОБРАБОТКА СЕТЕВЫХ ЗАПРОСОВ
-- =============================================

-- Запрос синхронизации
net.Receive("ZGrad_Donate_RequestSync", function(len, ply)
    SyncCoins(ply)
    SyncInventory(ply)
end)

-- Покупка скина
net.Receive("ZGrad_Donate_BuySkin", function(len, ply)
    local skinID = net.ReadString()
    local steamid = ply:SteamID()
    
    -- Валидация
    local skinData = ZGRAD_GetSkinByID(skinID)
    if not skinData then
        NotifyDonate(ply, "Скин не найден!", true)
        return
    end
    
    -- Уже куплен?
    if HasSkin(steamid, skinID) then
        NotifyDonate(ply, "Вы уже владеете этим скином!", true)
        return
    end
    
    -- Достаточно монет?
    local coins = GetCoins(steamid)
    if coins < skinData.price then
        NotifyDonate(ply, "У вас недостаточно Donate Coins!", true)
        return
    end
    
    -- Покупка
    SetCoins(steamid, coins - skinData.price)
    GiveSkin(steamid, skinID)
    
    NotifyDonate(ply, "Скин \"" .. skinData.name .. "\" куплен!")
    SyncCoins(ply)
    SyncInventory(ply)
    
    print("[Z-Grad RP] " .. ply:Nick() .. " (" .. steamid .. ") bought donate skin: " .. skinData.name)
end)

-- Экипировка скина
net.Receive("ZGrad_Donate_EquipSkin", function(len, ply)
    local skinID = net.ReadString()
    local steamid = ply:SteamID()
    
    -- Валидация
    if not HasSkin(steamid, skinID) then
        NotifyDonate(ply, "У вас нет этого скина!", true)
        return
    end
    
    local skinData = ZGRAD_GetSkinByID(skinID)
    if not skinData then
        NotifyDonate(ply, "Скин не найден!", true)
        return
    end
    
    -- Снять все скины для этой профессии (только один может быть надет)
    UnequipAllForJob(steamid, skinData.job)
    
    -- Надеть этот скин
    SetEquipped(steamid, skinID, true)
    
    NotifyDonate(ply, "Скин \"" .. skinData.name .. "\" экипирован!")
    SyncInventory(ply)
    
    -- Если игрок уже на этой профессии — сменить модель сразу
    local job = RPExtraTeams[ply:Team()]
    if job and job.command == skinData.job then
        ply:SetModel(skinData.model)
        ply:SetupHands()
    end
end)

-- Снятие скина
net.Receive("ZGrad_Donate_UnequipSkin", function(len, ply)
    local skinID = net.ReadString()
    local steamid = ply:SteamID()
    
    if not HasSkin(steamid, skinID) then
        NotifyDonate(ply, "У вас нет этого скина!", true)
        return
    end
    
    SetEquipped(steamid, skinID, false)
    
    local skinData = ZGRAD_GetSkinByID(skinID)
    local name = skinData and skinData.name or skinID
    
    NotifyDonate(ply, "Скин \"" .. name .. "\" снят!")
    SyncInventory(ply)
    
    -- Если игрок на этой профессии — вернуть стандартную модель
    if skinData then
        local job = RPExtraTeams[ply:Team()]
        if job and job.command == skinData.job then
            local model = job.model
            if istable(model) then
                model = model[math.random(#model)]
            end
            if isstring(model) then
                ply:SetModel(model)
                ply:SetupHands()
            end
        end
    end
end)

-- =============================================
-- ПРИМЕНЕНИЕ СКИНОВ ПРИ СПАВНЕ
-- =============================================
hook.Add("PlayerSpawn", "ZGrad_DonateSkinsOnSpawn", function(ply)
    timer.Simple(0.15, function()
        if not IsValid(ply) then return end
        
        local job = RPExtraTeams[ply:Team()]
        if not job then return end
        
        local steamid = ply:SteamID()
        local equipped = GetEquippedSkinForJob(steamid, job.command)
        
        if equipped then
            ply:SetModel(equipped.model)
            ply:SetupHands()
        end
    end)
end)

-- =============================================
-- СИНХРОНИЗАЦИЯ ПРИ ВХОДЕ
-- =============================================
hook.Add("PlayerInitialSpawn", "ZGrad_DonateSyncOnJoin", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        SyncCoins(ply)
        SyncInventory(ply)
    end)
end)

-- =============================================
-- АДМИН КОМАНДЫ
-- =============================================

-- zgrad_set_donate <SteamID или Ник> <Количество>
concommand.Add("zgrad_set_donate", function(ply, cmd, args)
    -- Проверка прав (консоль сервера или суперадмин)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        if IsValid(ply) then
            ply:ChatPrint("[Z-Grad RP] Только для суперадминов!")
        end
        return
    end
    
    if #args < 2 then
        local msg = "[Z-Grad RP] Использование: zgrad_set_donate <SteamID или Ник> <Количество>"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    
    local amount = tonumber(args[#args])
    
    if not amount then
        local msg = "[Z-Grad RP] Количество должно быть числом! (Получено: " .. tostring(args[#args]) .. ")"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    
    table.remove(args, #args)
    local target = table.concat(args, " ")
    
    -- Поиск игрока по нику или SteamID
    local targetPly = nil
    local targetSteamID = nil
    
    local targLower = string.lower(target)
    for _, p in ipairs(player.GetAll()) do
        local pNick = string.lower(p:Nick())
        if p:SteamID() == target or p:SteamID64() == target or string.find(pNick, targLower, 1, true) then
            targetPly = p
            targetSteamID = p:SteamID()
            if pNick == targLower then break end -- Точное совпадение приоритетнее
        end
    end
    
    if not targetSteamID then
        -- Может быть оффлайн SteamID или SteamID64
        if string.find(target, "^STEAM_%d:%d:%d+$") then
            targetSteamID = target
        elseif string.find(target, "^7656119%d+$") then
            targetSteamID = util.SteamIDFrom64(target)
        else
            local msg = "[Z-Grad RP] Игрок не найден: " .. target .. " (онлайн не найден, либо неверный формат SteamID)"
            if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
            return
        end
    end
    
    SetCoins(targetSteamID, amount)
    
    local displayName = IsValid(targetPly) and targetPly:Nick() or target
    local msg = "[Z-Grad RP] Установлено " .. amount .. " Donate Coins для " .. displayName
    if IsValid(ply) then ply:ChatPrint(msg) end
    print(msg)
    
    -- Синхронизация если онлайн
    if IsValid(targetPly) then
        SyncCoins(targetPly)
        targetPly:ChatPrint("[Z-Grad RP] Ваш баланс Donate Coins установлен: " .. amount)
    end
end)

-- zgrad_give_donate <SteamID или Ник> <Количество>
concommand.Add("zgrad_give_donate", function(ply, cmd, args)
    -- Проверка прав
    if IsValid(ply) and not ply:IsSuperAdmin() then
        if IsValid(ply) then
            ply:ChatPrint("[Z-Grad RP] Только для суперадминов!")
        end
        return
    end
    
    if #args < 2 then
        local msg = "[Z-Grad RP] Использование: zgrad_give_donate <SteamID или Ник> <Количество>"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    
    local amount = tonumber(args[#args])
    
    if not amount then
        local msg = "[Z-Grad RP] Количество должно быть числом! (Получено: " .. tostring(args[#args]) .. ")"
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end
    
    table.remove(args, #args)
    local target = table.concat(args, " ")
    
    -- Поиск игрока
    local targetPly = nil
    local targetSteamID = nil
    
    local targLower = string.lower(target)
    for _, p in ipairs(player.GetAll()) do
        local pNick = string.lower(p:Nick())
        if p:SteamID() == target or p:SteamID64() == target or string.find(pNick, targLower, 1, true) then
            targetPly = p
            targetSteamID = p:SteamID()
            if pNick == targLower then break end -- Точное совпадение приоритетнее
        end
    end
    
    if not targetSteamID then
        -- Может быть оффлайн SteamID или SteamID64
        if string.find(target, "^STEAM_%d:%d:%d+$") then
            targetSteamID = target
        elseif string.find(target, "^7656119%d+$") then
            targetSteamID = util.SteamIDFrom64(target)
        else
            local msg = "[Z-Grad RP] Игрок не найден: " .. target .. " (онлайн не найден, либо неверный формат SteamID)"
            if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
            return
        end
    end
    
    AddCoins(targetSteamID, amount)
    local newTotal = GetCoins(targetSteamID)
    
    local displayName = IsValid(targetPly) and targetPly:Nick() or target
    local msg = "[Z-Grad RP] Добавлено " .. amount .. " Donate Coins для " .. displayName .. " (Итого: " .. newTotal .. ")"
    if IsValid(ply) then ply:ChatPrint(msg) end
    print(msg)
    
    if IsValid(targetPly) then
        SyncCoins(targetPly)
        targetPly:ChatPrint("[Z-Grad RP] Вам начислено " .. amount .. " Donate Coins! (Итого: " .. newTotal .. ")")
    end
end)

print("[Z-Grad RP] Donate System (Server) loaded")

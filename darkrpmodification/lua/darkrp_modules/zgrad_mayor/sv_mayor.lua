--[[---------------------------------------------------------------------------
Z-Grad RP — Система Мэра (Сервер)
- Выдача/снятие лицензий
- Увольнение полиции/ФБР
- Управление зарплатами
- Редактирование законов
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_Mayor_GetPlayers")
util.AddNetworkString("ZGrad_Mayor_License")
util.AddNetworkString("ZGrad_Mayor_Fire")
util.AddNetworkString("ZGrad_Mayor_Salaries")
util.AddNetworkString("ZGrad_Mayor_SetSalary")
util.AddNetworkString("ZGrad_Mayor_Laws")
util.AddNetworkString("ZGrad_Mayor_SaveLaws")
util.AddNetworkString("ZGrad_Mayor_RequestLaws")
util.AddNetworkString("ZGrad_Mayor_LawsUpdate")
util.AddNetworkString("ZGrad_Mayor_UpdateSalaries")
util.AddNetworkString("ZGrad_Mayor_ToggleLockdown")
util.AddNetworkString("ZGrad_Mayor_LockdownState")
util.AddNetworkString("ZGrad_Mayor_DoAnnouncement")
util.AddNetworkString("ZGrad_Mayor_Announcement")
util.AddNetworkString("ZGrad_Mayor_RequestLockdownState")

-- =============================================
-- Законы (хранятся на сервере)
-- =============================================
local ZGrad_Laws = {}
local LawsSaveFile = "zgrad/laws/" .. game.GetMap() .. ".json"

local function LoadLaws()
    if not file.Exists(LawsSaveFile, "DATA") then
        ZGrad_Laws = {
            "Запрещено убивать граждан",
            "Запрещено воровать имущество",
            "Запрещено носить оружие без лицензии",
        }
        return
    end
    local data = file.Read(LawsSaveFile, "DATA")
    ZGrad_Laws = util.JSONToTable(data) or {}
end

local function SaveLaws()
    if not file.Exists("zgrad/laws", "DATA") then
        file.CreateDir("zgrad/laws")
    end
    file.Write(LawsSaveFile, util.TableToJSON(ZGrad_Laws))
end

LoadLaws()

-- Отправка текущих законов игроку
local function SendLawsToPlayer(ply)
    net.Start("ZGrad_Mayor_LawsUpdate")
        net.WriteUInt(#ZGrad_Laws, 8)
        for _, law in ipairs(ZGrad_Laws) do
            net.WriteString(law)
        end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Запрос законов клиентом
net.Receive("ZGrad_Mayor_RequestLaws", function(len, ply)
    SendLawsToPlayer(ply)
end)

-- Отправить свежий список при заходе
hook.Add("PlayerInitialSpawn", "ZGrad_Mayor_InitPlayer", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) then 
            SendLawsToPlayer(ply)
            if SendSalariesToPlayer then SendSalariesToPlayer(ply) end
        end
    end)
end)

-- =============================================
-- Баны на профессии (увольнение)
-- =============================================
local FiredPlayers = {} -- [SteamID] = { expiry = CurTime() + 300 }

-- =============================================
-- Выдача / Снятие лицензии
-- =============================================
net.Receive("ZGrad_Mayor_License", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end

    local target = net.ReadEntity()
    local grant  = net.ReadBool() -- true = выдать, false = забрать

    if not IsValid(target) or not target:IsPlayer() then return end

    if grant then
        target:setDarkRPVar("HasGunlicense", true)
        DarkRP.notify(target, 0, 5, "Мэр выдал вам лицензию на оружие!")
        DarkRP.notify(ply, 0, 4, "Лицензия выдана: " .. target:Nick())
    else
        target:setDarkRPVar("HasGunlicense", false)
        DarkRP.notify(target, 1, 5, "Мэр забрал вашу лицензию на оружие!")
        DarkRP.notify(ply, 0, 4, "Лицензия забрана: " .. target:Nick())
    end
end)

-- =============================================
-- Увольнение
-- =============================================
net.Receive("ZGrad_Mayor_Fire", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end

    local target = net.ReadEntity()
    local reason = net.ReadString()

    if not IsValid(target) or not target:IsPlayer() then return end

    local targetTeam = target:Team()
    if targetTeam ~= TEAM_POLICE and targetTeam ~= TEAM_FBI then
        DarkRP.notify(ply, 1, 4, "Можно уволить только Полицию или ФБР!")
        return
    end

    -- Запоминаем бан
    FiredPlayers[target:SteamID()] = {
        expiry = CurTime() + 300 -- 5 минут
    }

    -- Меняем на гражданского
    target:changeTeam(TEAM_CITIZEN, true)
    DarkRP.notify(target, 1, 6, "Вы были уволены Мэром! Причина: " .. reason)
    DarkRP.notify(ply, 0, 4, "Уволен: " .. target:Nick())

    -- Уведомляем всех
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p ~= target then
            DarkRP.notify(p, 0, 5, target:Nick() .. " был уволен Мэром.")
        end
    end
end)

-- Проверка при смене профессии
hook.Add("playerCanChangeTeam", "ZGrad_Mayor_FireBan", function(ply, teamID)
    if (teamID == TEAM_POLICE or teamID == TEAM_FBI) and FiredPlayers[ply:SteamID()] then
        local data = FiredPlayers[ply:SteamID()]
        if CurTime() < data.expiry then
            local remaining = math.ceil(data.expiry - CurTime())
            return false, "Вы были уволены Мэром! Подождите " .. remaining .. " сек."
        else
            FiredPlayers[ply:SteamID()] = nil
        end
    end
end)

-- =============================================
-- Управление зарплатами
-- =============================================
local CustomSalaries = {} -- [teamID] = salary

function SendSalariesToPlayer(ply)
    local toSend = {}
    for teamID, salary in pairs(CustomSalaries) do
        table.insert(toSend, {teamID, salary})
    end
    net.Start("ZGrad_Mayor_UpdateSalaries")
        net.WriteUInt(#toSend, 8)
        for _, tbl in ipairs(toSend) do
            net.WriteUInt(tbl[1], 16)
            net.WriteUInt(tbl[2], 16)
        end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

net.Receive("ZGrad_Mayor_SetSalary", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end

    local count = net.ReadUInt(8)
    local newSalaries = {}
    local totalSum = 0

    for i = 1, count do
        local teamID = net.ReadUInt(16)
        local salary = net.ReadUInt(16)
        newSalaries[teamID] = salary
        totalSum = totalSum + salary
    end

    if totalSum > 500 then
        DarkRP.notify(ply, 1, 5, "Общая сумма зарплат не может превышать $500!")
        return
    end

    -- Применяем зарплаты
    for teamID, salary in pairs(newSalaries) do
        if teamID ~= TEAM_MAYOR then
            RPExtraTeams[teamID].salary = salary
            CustomSalaries[teamID] = salary
        end
    end

    SendSalariesToPlayer(nil)
    DarkRP.notify(ply, 0, 4, "Зарплаты обновлены!")
end)

-- =============================================
-- Сохранение законов
-- =============================================
net.Receive("ZGrad_Mayor_SaveLaws", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end

    local count = net.ReadUInt(8)
    local newLaws = {}
    for i = 1, count do
        local law = net.ReadString()
        if law and law ~= "" then
            table.insert(newLaws, law)
        end
    end

    ZGrad_Laws = newLaws
    SaveLaws()
    DarkRP.notify(ply, 0, 4, "Законы сохранены!")

    -- Рассылаем всем
    SendLawsToPlayer(nil)
end)

-- =============================================
-- Запрос списка игроков
-- =============================================
net.Receive("ZGrad_Mayor_GetPlayers", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end

    local action = net.ReadString()

    if action == "license_grant" then
        -- Показать игроков без лицензии
        local targets = {}
        for _, p in ipairs(player.GetAll()) do
            if not p:getDarkRPVar("HasGunlicense") then
                table.insert(targets, p)
            end
        end
        net.Start("ZGrad_Mayor_GetPlayers")
            net.WriteString("license_grant")
            net.WriteUInt(#targets, 8)
            for _, t in ipairs(targets) do
                net.WriteEntity(t)
                net.WriteString(t:Nick())
                net.WriteString(team.GetName(t:Team()) or "???")
            end
        net.Send(ply)

    elseif action == "license_revoke" then
        local targets = {}
        for _, p in ipairs(player.GetAll()) do
            if p:getDarkRPVar("HasGunlicense") and p ~= ply then
                table.insert(targets, p)
            end
        end
        net.Start("ZGrad_Mayor_GetPlayers")
            net.WriteString("license_revoke")
            net.WriteUInt(#targets, 8)
            for _, t in ipairs(targets) do
                net.WriteEntity(t)
                net.WriteString(t:Nick())
                net.WriteString(team.GetName(t:Team()) or "???")
            end
        net.Send(ply)

    elseif action == "fire" then
        local targets = {}
        for _, p in ipairs(player.GetAll()) do
            if p:Team() == TEAM_POLICE or p:Team() == TEAM_FBI then
                table.insert(targets, p)
            end
        end
        net.Start("ZGrad_Mayor_GetPlayers")
            net.WriteString("fire")
            net.WriteUInt(#targets, 8)
            for _, t in ipairs(targets) do
                net.WriteEntity(t)
                net.WriteString(t:Nick())
                net.WriteString(team.GetName(t:Team()) or "???")
            end
        net.Send(ply)

    elseif action == "salaries" then
        -- Отправить зарплаты Гражданских и Правительства
        local salaryData = {}
        for id, jobData in pairs(RPExtraTeams) do
            local cat = jobData.category or ""
            if (cat == "Гражданские" or cat == "Правительство") and id ~= TEAM_MAYOR then
                table.insert(salaryData, {
                    teamID = id,
                    name = jobData.name or "???",
                    salary = jobData.salary or 0,
                    category = cat,
                })
            end
        end
        net.Start("ZGrad_Mayor_GetPlayers")
            net.WriteString("salaries")
            net.WriteUInt(#salaryData, 8)
            for _, d in ipairs(salaryData) do
                net.WriteUInt(d.teamID, 16)
                net.WriteString(d.name)
                net.WriteUInt(d.salary, 16)
                net.WriteString(d.category)
            end
        net.Send(ply)

    elseif action == "laws" then
        net.Start("ZGrad_Mayor_GetPlayers")
            net.WriteString("laws")
            net.WriteUInt(#ZGrad_Laws, 8)
            for _, law in ipairs(ZGrad_Laws) do
                net.WriteString(law)
            end
        net.Send(ply)
    end
end)

-- =============================================
-- Управление: Комендантский час и Объявления
-- =============================================
local ZGrad_LockdownActive = false
local ZGrad_LockdownCooldown = 0
local ZGrad_LockdownEndTime = 0
local ZGrad_CurrentCooldownValue = 600 -- Запоминаем КД в зависимости от выбора

local function SendLockdownState(ply)
    net.Start("ZGrad_Mayor_LockdownState")
        net.WriteBool(ZGrad_LockdownActive)
        net.WriteFloat(ZGrad_LockdownCooldown)
        net.WriteFloat(ZGrad_LockdownEndTime)
    if ply then net.Send(ply) else net.Broadcast() end
end

local function EndLockdown()
    if not ZGrad_LockdownActive then return end
    ZGrad_LockdownActive = false
    ZGrad_LockdownCooldown = CurTime() + ZGrad_CurrentCooldownValue
    ZGrad_LockdownEndTime = 0
    timer.Remove("ZGrad_Mayor_LockdownTimer")
    
    SendLockdownState(nil)
end

-- Глобальные функции для КЧ (чтобы вызывать из хуков или переворотов)
function ZGrad_ForceStartLockdown(duration)
    ZGrad_LockdownActive = true
    ZGrad_LockdownEndTime = duration > 0 and (CurTime() + (duration * 60)) or 0
    SendLockdownState(nil)
    
    if duration > 0 then
        timer.Create("ZGrad_Mayor_LockdownTimer", duration * 60, 1, function()
            EndLockdown()
        end)
    else
        timer.Remove("ZGrad_Mayor_LockdownTimer")
    end
end

function ZGrad_ForceStopLockdown()
    EndLockdown()
end

net.Receive("ZGrad_Mayor_ToggleLockdown", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end

    local val = net.ReadUInt(8) -- Выбор (0 - стоп, 1-3 - мин)

    if ZGrad_LockdownActive then
        EndLockdown()
        DarkRP.notify(ply, 0, 4, "Вы завершили комендантский час.")
        return -- Выходим после выключения
    end

    -- Если включаем:
    if val < 1 or val > 3 then return end

    if CurTime() < ZGrad_LockdownCooldown then
        local left = math.ceil(ZGrad_LockdownCooldown - CurTime())
        DarkRP.notify(ply, 1, 4, "Комендантский час на перезарядке! Осталось: " .. left .. " сек.")
        return
    end
    
    -- Устанавливаем параметры на основе выбора
    local duration = val
    local kdTable = { [1] = 300, [2] = 480, [3] = 600 }
    ZGrad_CurrentCooldownValue = kdTable[duration]

    ZGrad_ForceStartLockdown(duration)
    DarkRP.notify(ply, 0, 4, "Комендантский час запущен на " .. duration .. " мин.")
end)

net.Receive("ZGrad_Mayor_DoAnnouncement", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_MAYOR then return end
    
    if ply.ZGrad_NextAnnouncement and ply.ZGrad_NextAnnouncement > CurTime() then
        DarkRP.notify(ply, 1, 4, "Подождите перед следующим объявлением!")
        return
    end
    
    local msg = net.ReadString()
    if msg == "" then return end
    
    ply.ZGrad_NextAnnouncement = CurTime() + 10
    
    net.Start("ZGrad_Mayor_Announcement")
        net.WriteString(msg)
    net.Broadcast()
end)

net.Receive("ZGrad_Mayor_RequestLockdownState", function(len, ply)
    SendLockdownState(ply)
end)

hook.Add("PlayerInitialSpawn", "ZGrad_Mayor_LockdownInit", function(ply)
    timer.Simple(5, function()
        if IsValid(ply) then SendLockdownState(ply) end
    end)
end)

print("[Z-Grad RP] Mayor System (Server) Loaded")

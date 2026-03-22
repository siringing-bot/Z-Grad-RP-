--[[---------------------------------------------------------------------------
Z-Grad RP — Cleanup & Limit System (Ultimate Fix)
---------------------------------------------------------------------------]]

ZGrad_Utility = ZGrad_Utility or {}

-- Глобальная защита от краша DarkRP (bad argument #1 to 'Player')
-- DarkRP в EntityRemoved вызывает Player(ent.SID or 0). Если SID - строка, всё падает.
local oldPlayer = _G.Player
_G.Player = function(id)
    if isstring(id) then 
        -- Если пришла строка (SteamID), пытаемся найти игрока по SteamID
        return player.GetBySteamID(id) or oldPlayer(0)
    end
    return oldPlayer(id or 0)
end

-- Функция проверки лимита (совместима с DarkRP)
function ZGrad_Utility.CheckLimit(ply, class)
    if not IsValid(ply) then return true end
    
    -- Проверка через Sandbox лимиты
    local max = 0
    if DarkRPEntities then
        for _, e in pairs(DarkRPEntities) do
            if e.ent == class then
                max = e.max
                break
            end
        end
    end

    if max > 0 and ply:GetCount(class) >= max then
        return false, max
    end

    -- Дополнительная проверка через DarkRP внутренние лимиты
    if ply.customEntityCount then
        for _, e in pairs(DarkRPEntities) do
            if e.ent == class then
                if ply:customEntityLimitReached(e) then
                    return false, e.max
                end
                break
            end
        end
    end

    return true
end

-- Функция проверки лимита на предметы от НПС (Глобально, по классу + подтип)
function ZGrad_Utility.CheckNpcLimit(ply, class, subType)
    if not IsValid(ply) or not class then return true, 0 end
    
    local count = 0
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.ZGrad_NpcBought and ent:GetClass() == class and (ent.ZGrad_Owner == ply or ent:GetNW2Entity("owner") == ply) then
            -- Если указан подтип (например, ID ингредиента), проверяем его
            if subType and ent.ZGrad_NpcSubType != subType then continue end
            count = count + 1
        end
    end
    
    return count < 2, count
end

-- Хук передачи собственности при поднятии оружия
hook.Add("WeaponEquip", "ZGrad_NpcWeaponTransfer", function(wep, ply)
    if not IsValid(wep) or not wep.ZGrad_NpcBought then return end
    
    -- Передаем владение новому хозяину
    wep.ZGrad_Owner = ply
    wep:SetNW2Entity("owner", ply)
    wep.SID = ply:SteamID()
    
    print("[ZGrad Limits] Weapon " .. wep:GetClass() .. " became owned by " .. ply:Nick() .. " (Transfer)")
end)

-- Функция для очистки всех сущностей игрока
function ZGrad_Utility.CleanUpPlayerEntities(ply)
    if not IsValid(ply) then return end
    
    local count = 0
    -- Используем GetCount класса если возможно, но пройдемся по всем для надежности
    for _, ent in ipairs(ents.GetAll()) do
        if not IsValid(ent) then continue end
        
        local owner = ent.ZGrad_Owner or ent:GetNW2Entity("owner")
        if not IsValid(owner) then owner = ent.Getowning_ent and ent:Getowning_ent() end
        
        if owner == ply then
            local class = ent:GetClass()
            if class == "zgrad_crate_small" or class == "zgrad_crate_large" or class == "zgrad_inventory" then continue end
            
            ent:Remove()
            count = count + 1
        end
    end
    
    if ply.Cleanup then ply:Cleanup("props") end
    return count
end

-- Кэшируем владельца и прописываем SID для DarkRP
hook.Add("OnEntityCreated", "ZGrad_TrackOwner", function(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local owner = ent:GetNW2Entity("owner")
        if not IsValid(owner) then owner = ent.Getowning_ent and ent:Getowning_ent() end
        
        if IsValid(owner) and owner:IsPlayer() then
            ent.ZGrad_Owner = owner
            ent.SID = owner:SteamID() -- DarkRP использует это в EntityRemoved
            
            -- Если это энтити DarkRP, пытаемся найти описание для лимитов
            if not ent.DarkRPItem and DarkRPEntities then
                local class = ent:GetClass()
                for _, e in pairs(DarkRPEntities) do
                    if e.ent == class then
                        ent.DarkRPItem = e
                        break
                    end
                end
            end
        end
    end)
end)

-- ФИКС ЛИМИТОВ ПРИ УДАЛЕНИИ (Принудительный)
hook.Add("EntityRemoved", "ZGrad_FixEntityLimits", function(ent)
    local owner = ent.ZGrad_Owner or ent:GetNW2Entity("owner")
    if not IsValid(owner) then owner = ent.Getowning_ent and ent:Getowning_ent() end
    
    -- Убеждаемся, что у DarkRP есть всё необходимое для своего хука
    if IsValid(owner) and owner:IsPlayer() and not ent.SID then
        ent.SID = owner:SteamID()
    end

    -- ВАЖНО: Мы БОЛЬШЕ НЕ вызываем removeCustomEntity здесь сам.
    -- Это предотвращает двойной вычет (баг, когда лимит увеличивался при продаже/удалении).
    -- DarkRP сам сделает это в своем хуке, найдя игрока через ent.SID.
end)

-- Хуки очистки
hook.Add("OnPlayerChangedTeam", "ZGrad_JobCleanup", function(ply, oldTeam, newTeam)
    ZGrad_Utility.CleanUpPlayerEntities(ply)
    DarkRP.notify(ply, 0, 4, "Ваши купленные предметы были удалены (смена профессии).")
end)

hook.Add("PlayerDisconnected", "ZGrad_DisconnectCleanup", function(ply)
    ZGrad_Utility.CleanUpPlayerEntities(ply)
end)

-- Команда для ручного сброса лимитов (если игрок уже "забагался" до установки фикса)
DarkRP.defineChatCommand("fixlimits", function(ply)
    if not IsValid(ply) then return "" end
    
    -- Сброс DarkRP счетчиков
    if ply.customEntityCount then
        ply.customEntityCount = {}
    end
    
    -- Сброс GMod счетчиков (если есть)
    -- ply:GetCount возвращает значения из внутренней таблицы, которую сложно сбросить целиком,
    -- но обычно баг именно в customEntityCount.
    
    DarkRP.notify(ply, 0, 4, "Ваши лимиты предметов были сброшены. Теперь вы можете достать предметы из инвентаря.")
    return ""
end)

print("[Z-Grad RP] Cleanup & Limit System (Ultimate Fix) Loaded")

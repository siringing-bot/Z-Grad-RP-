--[[---------------------------------------------------------------------------
Z-Grad RP — Hitman Module (Server)
---------------------------------------------------------------------------]]

ZGrad_Hitman.ActiveHits = ZGrad_Hitman.ActiveHits or {}

-- Broadcast hit updates to all hitmen
local function BroadcastHits()
    net.Start("ZGrad_HitUpdate")
    net.WriteTable(ZGrad_Hitman.ActiveHits)
    
    local hitmen = {}
    for _, ply in ipairs(player.GetAll()) do
        if ZGrad_Hitman.IsHitman(ply) then
            table.insert(hitmen, ply)
        end
    end
    
    if #hitmen > 0 then
        net.Send(hitmen)
    end
end

-- Force update hits for a player (e.g. when they join or change job)
hook.Add("OnPlayerChangedTeam", "ZGrad_HitUpdateOnJob", function(ply, old, new)
    if new == TEAM_KILLER then
        timer.Simple(1, function()
            if IsValid(ply) then
                net.Start("ZGrad_HitUpdate")
                net.WriteTable(ZGrad_Hitman.ActiveHits)
                net.Send(ply)
            end
        end)
    end
end)

-- Receive hit order
net.Receive("ZGrad_HitOrder", function(len, ply)
    local target = net.ReadEntity()
    local price = net.ReadInt(32)

    -- 1. Hitman cannot order a hit
    if ZGrad_Hitman.IsHitman(ply) then
        DarkRP.notify(ply, 1, 4, "Наемные убийцы не могут заказывать убийства!")
        return
    end

    -- 2. Cannot order a hit on self
    if target == ply then
        DarkRP.notify(ply, 1, 4, "Вы не можете заказать самого себя!")
        return
    end

    -- 3. Min price
    if price < ZGrad_Hitman.MinPrice then
        DarkRP.notify(ply, 1, 4, "Минимальная цена заказа " .. DarkRP.formatMoney(ZGrad_Hitman.MinPrice) .. "!")
        return
    end

    if not IsValid(target) or not target:IsPlayer() then return end

    -- Check if already has a hit
    if ZGrad_Hitman.ActiveHits[target:SteamID()] then
        DarkRP.notify(ply, 1, 4, "На этого игрока уже заказано убийство!")
        return
    end

    -- Check funds
    if not ply:canAfford(price) then
        DarkRP.notify(ply, 1, 4, "У вас недостаточно денег!")
        return
    end

    -- Process hit
    ply:addMoney(-price)
    ZGrad_Hitman.ActiveHits[target:SteamID()] = {
        targetName = target:Nick(),
        price = price,
        customer = ply:SteamID()
    }

    DarkRP.notify(ply, 0, 4, "Заказ на " .. target:Nick() .. " принят за " .. DarkRP.formatMoney(price))
    
    BroadcastHits()
end)

-- 1. ГЛОБАЛЬНЫЙ ТРЕКЕР УРОНА (Для Homigrad и кастомных систем)
hook.Add("EntityTakeDamage", "ZGrad_Hitman_DamageTracker", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and not attacker:IsPlayer() then
        if attacker.GetPlayer and IsValid(attacker:GetPlayer()) then attacker = attacker:GetPlayer()
        elseif IsValid(attacker.Owner) and attacker.Owner:IsPlayer() then attacker = attacker.Owner end
    end

    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then
        local sid = target:SteamID()
        local sid64 = target:SteamID64()
        
        if ZGrad_Hitman.ActiveHits[sid] or ZGrad_Hitman.ActiveHits[sid64] then
            target.ZGrad_LastHitmanAttacker = attacker
            target.ZGrad_LastDamageTime = CurTime()
        end
    end
end)

-- Вспомогательная функция для сверх-точной проверки на профессию киллера
local function IsReallyHitman(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    
    local job = ply:getJobTable()
    local name = job and string.lower(job.name or "") or ""
    local cmd = job and string.lower(job.command or "") or ""
    
    if name:find("киллер") or name:find("hitman") or name:find("убийца") then return true end
    if cmd:find("killer") or cmd:find("hitman") then return true end
    
    local t = ply:Team()
    if (_G.TEAM_KILLER and t == _G.TEAM_KILLER) or (_G.TEAM_HITMAN and t == _G.TEAM_HITMAN) then return true end
    
    return false
end

-- 2. ВЫПЛАТА (С ПРОВЕРКОЙ ВСЕХ ВОЗМОЖНЫХ УБИЙЦ)
hook.Add("PlayerDeath", "ZGrad_HitPayout_Ultimate", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    
    local sid = victim:SteamID()
    local sid64 = victim:SteamID64()
    local hit = ZGrad_Hitman.ActiveHits[sid] or ZGrad_Hitman.ActiveHits[sid64]
    
    if hit then
        print("[Hitman] Цель '" .. victim:Nick() .. "' погибла. Ищем убийцу...")

        -- Составляем список ПОДОЗРЕВАЕМЫХ
        local suspects = {
            attacker,
            victim.ZGrad_LastHitmanAttacker,
            victim.LastAttacker,
            victim.last_attacker,
            inflictor
        }
        
        -- Если урон был недавно (до 60 сек), трекер в приоритете
        if victim.ZGrad_LastDamageTime and (CurTime() - victim.ZGrad_LastDamageTime) < 60 then
            table.insert(suspects, 1, victim.ZGrad_LastHitmanAttacker)
        end

        local winner = nil
        for _, suspect in ipairs(suspects) do
            local p = suspect
            if IsValid(p) and not p:IsPlayer() then
                 if p.GetPlayer and IsValid(p:GetPlayer()) then p = p:GetPlayer()
                 elseif IsValid(p.Owner) and p.Owner:IsPlayer() then p = p.Owner end
            end

            if IsValid(p) and p:IsPlayer() and p ~= victim then
                if IsReallyHitman(p) then
                    winner = p
                    break
                end
            end
        end

        if IsValid(winner) and winner ~= victim then
            print("[Hitman] Ура! Деньги выданы: " .. winner:Nick())
            winner:addMoney(hit.price)
            DarkRP.notify(winner, 0, 6, "КОНТРАКТ ВЫПОЛНЕН! Вы получили " .. DarkRP.formatMoney(hit.price))
            
            for _, ply in ipairs(player.GetAll()) do
                if ply:SteamID() == hit.customer or ply:SteamID64() == hit.customer then
                    DarkRP.notify(ply, 0, 6, "Ваш заказ на '" .. victim:Nick() .. "' успешно выполнен!")
                    break
                end
            end
        else
            print("[Hitman] Убийца не найден или киллер убил сам себя.")
        end

        -- Очистка контракта
        ZGrad_Hitman.ActiveHits[sid] = nil
        ZGrad_Hitman.ActiveHits[sid64] = nil
        BroadcastHits()
    end
end)

-- Команда для админа, чтобы глянуть активные заказы (для тестов)
concommand.Add("zgrad_hit_debug", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    print("--- АКТИВНЫЕ КОНТРАКТЫ ---")
    PrintTable(ZGrad_Hitman.ActiveHits)
end)

-- Clear hit if target leaves
hook.Add("PlayerDisconnected", "ZGrad_HitClearOnLeave", function(ply)
    if ZGrad_Hitman.ActiveHits[ply:SteamID()] then
        ZGrad_Hitman.ActiveHits[ply:SteamID()] = nil
        BroadcastHits()
    end
end)

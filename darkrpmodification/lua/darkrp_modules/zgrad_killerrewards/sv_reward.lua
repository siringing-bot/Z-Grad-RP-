--[[---------------------------------------------------------------------------
Z-Grad RP — Killer Rewards (Server)
Награда Маньяку за убийства
---------------------------------------------------------------------------]]

local KILL_REWARD = 1000

hook.Add("EntityTakeDamage", "ZGrad_Maniac_LastHitTracker", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        target.ZGrad_LastAttacker = attacker
    end
end)

hook.Add("PlayerDeath", "ZGrad_ManiacReward", function(victim, inflictor, attacker)
    -- Берем последнего ударившего, если текущий убийца не игрок или это суицид/кровотечение ZCity
    local actualAttacker = attacker
    if not IsValid(actualAttacker) or not actualAttacker:IsPlayer() or actualAttacker == victim then
        actualAttacker = victim.ZGrad_LastAttacker
    end

    -- Проверяем, что убийца — игрок
    if not IsValid(actualAttacker) or not actualAttacker:IsPlayer() then return end
    
    -- Проверяем, что убийца — маньяк и он не убил сам себя
    if actualAttacker:Team() == TEAM_MANIAC and actualAttacker != victim then
        -- Выдаем деньги через DarkRP
        actualAttacker:addMoney(KILL_REWARD)
        
        -- Уведомление игроку
        DarkRP.notify(actualAttacker, 0, 4, "Вы получили $" .. KILL_REWARD .. " за убийство жертвы!")
        
        -- Опционально: звук получения денег (если у вас есть net-сообщение для этого)
        -- net.Start("ZGrad_MoneyNotify") -- Если используется кастомный HUD
        --     net.WriteInt(KILL_REWARD, 32)
        -- net.Send(actualAttacker)
    end
end)

print("[Z-Grad RP] Maniac Rewards Module LOADED")

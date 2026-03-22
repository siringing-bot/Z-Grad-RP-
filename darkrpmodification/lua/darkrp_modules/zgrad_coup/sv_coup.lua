--[[---------------------------------------------------------------------------
Z-Grad RP — Coup Act (Server)
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_Coup_Start")
util.AddNetworkString("ZGrad_Coup_Notify")
util.AddNetworkString("ZGrad_Coup_Result")

local COUP_CD = 3600 -- 1 час (3600 секунд)
local lastCoupTime = -COUP_CD
-- ... (rest of preamble)

-- (Inside death check and disconnect checks, replace notifyAll with HUD and notify)
local LOCKDOWN_COOLDOWN = 300 -- 5 минут кулдаун на коммендантский час после переворота

-- Локальные переменные для отслеживания текущего переворота
local activeCoup = false
local coupInitiator = nil
local currentMayor = nil

-- Функция для проверки, активен ли переворот
function ZGrad_Coup_IsActive()
    return activeCoup
end

-- Обработка запроса на начало
net.Receive("ZGrad_Coup_Start", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Проверка на профу Глава Мафии (TEAM_MAFIA_BOSS)
    if ply:Team() ~= (TEAM_MAFIA_BOSS or -1) then
        DarkRP.notify(ply, 1, 4, "Только Глава мафии может устроить гос. переворот!")
        return
    end
    
    -- Проверка времени
    if CurTime() < lastCoupTime + COUP_CD then
        local cd = math.ceil((lastCoupTime + COUP_CD) - CurTime())
        local mins = math.floor(cd / 60)
        DarkRP.notify(ply, 1, 4, string.format("Гос. переворот на кулдауне! Осталось: %d мин.", mins))
        return
    end

    -- Проверка на уже идущий переворот
    if activeCoup then
        DarkRP.notify(ply, 1, 4, "Гос. переворот уже идет!")
        return
    end

    -- Проверка на мэра (чтобы было кого свергать)
    local hasMayor = false
    local mayorEnt = nil
    for _, v in ipairs(player.GetAll()) do
        if v:Team() == TEAM_MAYOR then
            hasMayor = true
            mayorEnt = v
            break
        end
    end

    if not hasMayor then
        DarkRP.notify(ply, 1, 4, "В городе нет мэра, некого свергать!")
        return
    end

    local reason = net.ReadString() or "Свержение власти!"
    if string.len(string.Trim(reason)) < 5 then
        DarkRP.notify(ply, 1, 4, "Укажите весомую причину для переворота!")
        return
    end
    
    -- Начало переворота
    activeCoup = true
    coupInitiator = ply
    currentMayor = mayorEnt

    lastCoupTime = CurTime()
    SetGlobalFloat("ZGrad_CoupCD", lastCoupTime + COUP_CD)
    SetGlobalBool("ZGrad_CoupActive", true)
    
    -- Объявляем бесконечный коммендантский час (до завершения переворота)
    if ZGrad_ForceStartLockdown then
        ZGrad_ForceStartLockdown(0) 
    else
        RunConsoleCommand("darkrp", "lockdown")
    end
    
    -- Специальный HUD
    net.Start("ZGrad_Coup_Notify")
        net.WriteEntity(ply)
        net.WriteString(reason)
    net.Broadcast()
    
    DarkRP.notifyAll(0, 5, "ВНИМАНИЕ! Глава мафии " .. ply:Nick() .. " начал гос. переворот! Причина: " .. reason)
end)

-- Проверка смертей для окончания переворота
hook.Add("PlayerDeath", "ZGrad_Coup_DeathCheck", function(victim, inflictor, attacker)
    if not activeCoup then return end

    if IsValid(victim) then
        -- Если умер мэр
        if victim == currentMayor then
            activeCoup = false
            SetGlobalBool("ZGrad_CoupActive", false)
            
            local msg = "МЭР МЕРТВ! Мафия победила в гос. перевороте!"
            net.Start("ZGrad_Coup_Result")
                net.WriteString("mafia")
                net.WriteString(msg)
            net.Broadcast()
            
            DarkRP.notifyAll(0, 8, msg)
            
            if ZGrad_ForceStopLockdown then ZGrad_ForceStopLockdown() else RunConsoleCommand("darkrp", "unlockdown") end
            SetGlobalFloat("DarkRP_LockDown_Cooldown", CurTime() + LOCKDOWN_COOLDOWN)
            
            coupInitiator = nil
            currentMayor = nil

        -- Если умер организатор переворота
        elseif victim == coupInitiator then
            activeCoup = false
            SetGlobalBool("ZGrad_CoupActive", false)
            
            local msg = "ГЛАВА МАФИИ МЕРТВ! Власти отбили гос. переворот!"
            net.Start("ZGrad_Coup_Result")
                net.WriteString("government")
                net.WriteString(msg)
            net.Broadcast()

            DarkRP.notifyAll(0, 8, msg)
            
            if ZGrad_ForceStopLockdown then ZGrad_ForceStopLockdown() else RunConsoleCommand("darkrp", "unlockdown") end
            SetGlobalFloat("DarkRP_LockDown_Cooldown", CurTime() + LOCKDOWN_COOLDOWN)
            
            coupInitiator = nil
            currentMayor = nil
        end
    end
end)

-- Защита от смены профы / выхода организатора во время переворота
hook.Add("PlayerDisconnected", "ZGrad_Coup_DisconnectCheck", function(ply)
    if activeCoup and ply == coupInitiator then
         activeCoup = false
         SetGlobalBool("ZGrad_CoupActive", false)
         
         local msg = "Организатор гос. переворота сбежал! Власти победили!"
         net.Start("ZGrad_Coup_Result")
            net.WriteString("government")
            net.WriteString(msg)
         net.Broadcast()

         DarkRP.notifyAll(0, 8, msg)
         if ZGrad_ForceStopLockdown then ZGrad_ForceStopLockdown() else RunConsoleCommand("darkrp", "unlockdown") end
         SetGlobalFloat("DarkRP_LockDown_Cooldown", CurTime() + LOCKDOWN_COOLDOWN)
         coupInitiator = nil
         currentMayor = nil
    elseif activeCoup and ply == currentMayor then
         activeCoup = false
         SetGlobalBool("ZGrad_CoupActive", false)
         
         local msg = "ТРУСЛИВЫЙ МЭР СБЕЖАЛ! Мафия победила!"
         net.Start("ZGrad_Coup_Result")
            net.WriteString("mafia")
            net.WriteString(msg)
         net.Broadcast()

         DarkRP.notifyAll(0, 8, msg)
         if ZGrad_ForceStopLockdown then ZGrad_ForceStopLockdown() else RunConsoleCommand("darkrp", "unlockdown") end
         SetGlobalFloat("DarkRP_LockDown_Cooldown", CurTime() + LOCKDOWN_COOLDOWN)
         coupInitiator = nil
         currentMayor = nil
    end
end)

hook.Add("OnPlayerChangedTeam", "ZGrad_Coup_JobCheck", function(ply, oldTeam, newTeam)
    if activeCoup and ply == coupInitiator then
         activeCoup = false
         SetGlobalBool("ZGrad_CoupActive", false)
         
         local msg = "Организатор гос. переворота сдался (сменил профессию)! Власти победили!"
         net.Start("ZGrad_Coup_Result")
            net.WriteString("government")
            net.WriteString(msg)
         net.Broadcast()

         DarkRP.notifyAll(0, 8, msg)
         if ZGrad_ForceStopLockdown then ZGrad_ForceStopLockdown() else RunConsoleCommand("darkrp", "unlockdown") end
         SetGlobalFloat("DarkRP_LockDown_Cooldown", CurTime() + LOCKDOWN_COOLDOWN)
         coupInitiator = nil
         currentMayor = nil
    end
end)

-- Блокировка ручного снятия КЧ мэром во время переворота (опционально, можно хукнуть canLockdown)
hook.Add("canLockdown", "ZGrad_Coup_LockdownControl", function(ply, lockdown)
    -- Если хотят снять локдаун (lockdown = false/nil), и идет переворот, запрещаем
    if activeCoup and (not lockdown) then
        DarkRP.notify(ply, 1, 4, "Вы не можете снять коммендантский час во время гос. переворота!")
        return false, "Вы не можете снять коммендантский час во время гос. переворота!"
    end

    -- Проверка на наш 5 минутный кулдаун (DarkRP не имеет встроенного общего кулдауна на КЧ, поэтому мы его симулируем)
    if lockdown and GetGlobalFloat("DarkRP_LockDown_Cooldown", 0) > CurTime() then
        local cd = math.ceil(GetGlobalFloat("DarkRP_LockDown_Cooldown", 0) - CurTime())
        DarkRP.notify(ply, 1, 4, "Коммендантский час на перезарядке! Осталось: " .. cd .. " сек.")
        return false, "Коммендантский час на перезарядке"
    end
end)

print("[Z-Grad RP] Coup System Loaded")

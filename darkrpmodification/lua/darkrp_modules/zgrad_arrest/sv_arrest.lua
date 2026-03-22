--[[---------------------------------------------------------------------------
Z-Grad RP — Arrest System (Server)
Обработка нажатия E по закованному, телепортация, изъятие, таймер
---------------------------------------------------------------------------]]

-- Хранилище: кто сейчас сидит в тюрьме
ZGrad_Arrest.Prisoners = ZGrad_Arrest.Prisoners or {}

-- Кулдаун на открытие меню (чтобы не спамить)
local arrestCooldown = {}

-- =============================================
-- Проверка: закован ли игрок в наручники
-- =============================================
local function IsHandcuffed(ply)
    if not IsValid(ply) then return false end

    -- Способ 1: Кастомный SetNetVar от Z-City/homigrad (weapon_handcuffs.lua ставит именно через это)
    if ply.GetNetVar and ply:GetNetVar("handcuffed", false) then return true end

    -- Способ 2: Проверяем organism.handcuffed напрямую (тоже ставится наручниками)
    if ply.organism and ply.organism.handcuffed then return true end

    -- Способ 3: NWBool от стандартных аддонов наручников (fallback)
    if ply:GetNWBool("handcuffed", false) then return true end
    if ply:GetNWBool("isHandcuffed", false) then return true end
    if ply:GetNWBool("Handcuffed", false) then return true end
    if ply:GetNWBool("ply_handcuffed", false) then return true end

    -- Способ 4: DarkRP стандартный арест
    if ply.isArrested and ply:isArrested() then return true end

    return false
end

-- Делаем функцию доступной глобально для дебага
ZGrad_Arrest.IsHandcuffed = IsHandcuffed

-- =============================================
-- Обработка нажатия E по игроку (через KeyPress)
-- =============================================
hook.Add("KeyPress", "ZGrad_Arrest_UseCheck", function(ply, key)
    if key ~= IN_USE then return end
    if not ZGrad_Arrest.CanArrest(ply) then return end

    -- Кулдаун
    if arrestCooldown[ply] and arrestCooldown[ply] > CurTime() then return end

    -- Ищем игрока на которого смотрим
    local trace = ply:GetEyeTrace()
    local target = trace.Entity

    if not IsValid(target) then return end

    -- В Z-City/homigrad игроки управляются через рэгдоллы
    -- Если цель — рэгдолл, находим реального игрока через hg.RagdollOwner
    local actualPlayer = target
    if not target:IsPlayer() then
        if hg and hg.RagdollOwner then
            local owner = hg.RagdollOwner(target)
            if IsValid(owner) and owner:IsPlayer() then
                actualPlayer = owner
            else
                return -- Ни игрок, ни рэгдолл с владельцем
            end
        else
            return -- Ни игрок, ни рэгдолл
        end
    end

    if ply:GetPos():DistToSqr(target:GetPos()) > 22500 then return end -- ~150 юнитов

    -- Проверяем что цель в наручниках (проверяем реального игрока)
    if not IsHandcuffed(actualPlayer) then return end

    -- Проверяем что цель не сидит уже в тюрьме
    if ZGrad_Arrest.Prisoners[actualPlayer:SteamID64()] then
        DarkRP.notify(ply, 1, 4, "Этот игрок уже отбывает срок!")
        return
    end

    -- Ставим кулдаун
    arrestCooldown[ply] = CurTime() + 2

    -- Отправляем клиенту меню выбора статьи
    net.Start("ZGrad_Arrest_OpenMenu")
        net.WriteEntity(actualPlayer)
    net.Send(ply)

    print("[Z-Grad RP] Arrest menu sent to " .. ply:Nick() .. " for target " .. actualPlayer:Nick())
end)

-- =============================================
-- Обновляем NWBool для подсказки "Нажмите E" на клиенте
-- Проверяем для каждого копа кто рядом в наручниках
-- =============================================
timer.Create("ZGrad_Arrest_HintUpdate", 0.3, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ZGrad_Arrest.CanArrest(ply) then
            local trace = ply:GetEyeTrace()
            local target = trace.Entity

            local canArrestTarget = false
            if IsValid(target) then
                -- Резолвим рэгдолл в реального игрока
                local actualPlayer = target
                if not target:IsPlayer() and hg and hg.RagdollOwner then
                    local owner = hg.RagdollOwner(target)
                    if IsValid(owner) and owner:IsPlayer() then
                        actualPlayer = owner
                    end
                end

                if actualPlayer:IsPlayer()
                    and ply:GetPos():DistToSqr(target:GetPos()) <= 22500
                    and IsHandcuffed(actualPlayer)
                    and not ZGrad_Arrest.Prisoners[actualPlayer:SteamID64()] then
                    canArrestTarget = true
                end
            end

            ply:SetNWBool("ZGrad_CanArrestTarget", canArrestTarget)
        end
    end
end)

-- =============================================
-- Получаем выбор статьи от полицейского
-- =============================================
-- =============================================
-- Общая функция ареста (используется и confirm, и тест-командой)
-- =============================================
function ZGrad_Arrest.ArrestPlayer(target, crime, jailTime, arrestedBy)
    if not IsValid(target) or not target:IsPlayer() then return false end

    -- Проверяем что цель не сидит уже
    if ZGrad_Arrest.Prisoners[target:SteamID64()] then
        if IsValid(arrestedBy) then
            DarkRP.notify(arrestedBy, 1, 4, "Этот игрок уже в тюрьме!")
        end
        return false
    end

    -- ==================
    -- АРЕСТ
    -- ==================

    -- 1. Снимаем наручники (убираем флаги handcuffed)
    if target.GetNetVar then
        target:SetNetVar("handcuffed", false)
    end
    target:SetNWBool("handcuffed", false)
    if target.organism then
        target.organism.handcuffed = false
    end

    -- 2. Если игрок в рэгдолле (FakeRagdoll) — поднимаем его
    if hg and hg.FakeUp and IsValid(target.FakeRagdoll) then
        hg.FakeUp(target, true, true) -- forced=true, instant=true
    end

    -- 3. Изымаем всё оружие
    target:StripWeapons()

    -- 4. Выбираем случайную точку тюрьмы
    local jailSpawns = ZGrad_Arrest.JailPositions
    local jailPos = jailSpawns[math.random(#jailSpawns)]

    -- 5. Телепортируем (с задержкой чтобы FakeUp успел отработать)
    timer.Simple(0.2, function()
        if not IsValid(target) then return end

        -- Ещё раз убеждаемся что рэгдолл убран
        if hg and hg.FakeUp and IsValid(target.FakeRagdoll) then
            hg.FakeUp(target, true, true)
        end

        target:SetPos(jailPos)
        target:SetEyeAngles(Angle(0, 0, 0))
        target:SetMoveType(MOVETYPE_WALK)
        target:SetCollisionGroup(COLLISION_GROUP_PLAYER)

        -- Замораживаем (чтобы не убежал в момент телепорта)
        target:Freeze(true)
        timer.Simple(1, function()
            if IsValid(target) then
                target:Freeze(false)
            end
        end)
    end)

    -- 6. Устанавливаем флаг арестованного
    target:SetNWBool("ZGrad_IsJailed", true)
    target:SetNWFloat("ZGrad_JailEnd", CurTime() + jailTime)
    target:SetNWFloat("ZGrad_JailDuration", jailTime)
    target:SetNWString("ZGrad_JailCrime", crime)

    ZGrad_Arrest.Prisoners[target:SteamID64()] = {
        endTime = CurTime() + jailTime,
        crime = crime,
    }

    -- 7. Отправляем таймер клиенту с задержкой (чтобы NWSync дошел гарантированно)
    timer.Simple(0.5, function()
        if not IsValid(target) then return end
        net.Start("ZGrad_Arrest_Timer")
            net.WriteFloat(jailTime)
            net.WriteString(crime)
        net.Send(target)
    end)

    -- 8. Уведомления
    if IsValid(arrestedBy) then
        DarkRP.notify(arrestedBy, 0, 5, "Вы посадили " .. target:Nick() .. " за: " .. crime .. " (" .. jailTime .. " сек.)")
    end
    DarkRP.notify(target, 1, 5, "Вы арестованы за: " .. crime .. " | Срок: " .. jailTime .. " сек.")
    DarkRP.notifyAll(0, 5, target:Nick() .. " арестован за: " .. crime .. " (" .. jailTime .. " сек.)")

    -- 9. Таймер освобождения
    local timerName = "ZGrad_JailTimer_" .. target:SteamID64()
    timer.Create(timerName, jailTime, 1, function()
        if IsValid(target) then
            ZGrad_Arrest.ReleasePlayer(target)
        end
    end)

    print("[Z-Grad RP] " .. (IsValid(arrestedBy) and arrestedBy:Nick() or "SYSTEM") .. " arrested " .. target:Nick() .. " for: " .. crime .. " (" .. jailTime .. "s)")
    
    -- Выдаем копу новые наручники после успешной посадки
    if IsValid(arrestedBy) and arrestedBy:IsPlayer() then
        arrestedBy:Give("weapon_handcuffs")
    end

    return true
end

net.Receive("ZGrad_Arrest_Confirm", function(len, ply)
    if not ZGrad_Arrest.CanArrest(ply) then return end

    local crimeIndex = net.ReadUInt(8)
    local target = net.ReadEntity()

    if not IsValid(target) or not target:IsPlayer() then return end
    if not ZGrad_Arrest.Crimes[crimeIndex] then return end

    local crime = ZGrad_Arrest.Crimes[crimeIndex]

    -- Проверяем расстояние (на случай дублирования запроса)
    if ply:GetPos():DistToSqr(target:GetPos()) > 40000 then
        DarkRP.notify(ply, 1, 4, "Слишком далеко от преступника!")
        return
    end

    ZGrad_Arrest.ArrestPlayer(target, crime.name, crime.time, ply)
end)

-- =============================================
-- Освобождение игрока
-- =============================================
function ZGrad_Arrest.ReleasePlayer(ply)
    if not IsValid(ply) then return end

    -- 1. Убираем флаги арестованного
    ply:SetNWBool("ZGrad_IsJailed", false)
    ply:SetNWFloat("ZGrad_JailEnd", 0)
    ply:SetNWString("ZGrad_JailCrime", "")

    -- 2. Убираем из списка заключенных
    ZGrad_Arrest.Prisoners[ply:SteamID64()] = nil

    -- 3. Уничтожаем таймер
    local timerName = "ZGrad_JailTimer_" .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end

    -- 4. Уведомляем об освобождении
    net.Start("ZGrad_Arrest_TimerEnd")
    net.Send(ply)

    DarkRP.notify(ply, 0, 5, "Вы освобождены! Ваш срок отбыт.")

    -- 5. Если игрок в рэгдолле — поднимаем его
    if hg and hg.FakeUp and IsValid(ply.FakeRagdoll) then
        hg.FakeUp(ply, true, true)
    end

    -- 6. Снимаем заморозку если она есть
    ply:Freeze(false)

    -- 7. Респаун игрока
    timer.Simple(0.3, function()
        if not IsValid(ply) then return end

        -- Ещё раз убеждаемся что рэгдолл убран
        if hg and hg.FakeUp and IsValid(ply.FakeRagdoll) then
            hg.FakeUp(ply, true, true)
        end

        ply:Spawn()

        -- После спауна телепортируем на точку спауна (Spawn сам должен это сделать,
        -- но для надёжности делаем через таймер)
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            ply:SetMoveType(MOVETYPE_WALK)
            ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
            ply:DrawWorldModel(true)
            ply:DrawShadow(true)
            ply:SetRenderMode(RENDERMODE_NORMAL)
            print("[Z-Grad RP] " .. ply:Nick() .. " released from jail and respawned.")
        end)
    end)

    print("[Z-Grad RP] " .. ply:Nick() .. " released from jail.")
end

-- =============================================
-- Если игрок отключился — чистим данные
-- =============================================
hook.Add("PlayerDisconnected", "ZGrad_Arrest_Cleanup", function(ply)
    local sid = ply:SteamID64()
    if ZGrad_Arrest.Prisoners[sid] then
        local timerName = "ZGrad_JailTimer_" .. sid
        if timer.Exists(timerName) then
            timer.Remove(timerName)
        end
        ZGrad_Arrest.Prisoners[sid] = nil
    end
end)

-- =============================================
-- Запрещаем арестованному менять профессию
-- =============================================
hook.Add("playerCanChangeTeam", "ZGrad_Arrest_BlockJobChange", function(ply, teamID)
    if ply:GetNWBool("ZGrad_IsJailed", false) then
        return false, "Вы не можете менять профессию, пока отбываете срок!"
    end
end)

-- =============================================
-- Запрещаем суицид в тюрьме
-- =============================================
hook.Add("CanPlayerSuicide", "ZGrad_Arrest_BlockSuicide", function(ply)
    if ply:GetNWBool("ZGrad_IsJailed", false) then
        DarkRP.notify(ply, 1, 4, "Вы не можете покончить с собой в тюрьме!")
        return false
    end
end)

-- =============================================
-- Если игрок умер в тюрьме — продолжаем срок
-- =============================================
hook.Add("PlayerDeath", "ZGrad_Arrest_DeathInJail", function(ply)
    if not ply:GetNWBool("ZGrad_IsJailed", false) then return end

    -- Респауним его обратно в тюрьму с небольшой задержкой
    timer.Simple(3, function()
        if IsValid(ply) and ply:GetNWBool("ZGrad_IsJailed", false) then
            ply:Spawn()

            timer.Simple(0.1, function()
                if IsValid(ply) and ply:GetNWBool("ZGrad_IsJailed", false) then
                    local jailSpawns = ZGrad_Arrest.JailPositions
                    local jailPos = jailSpawns[math.random(#jailSpawns)]
                    ply:SetPos(jailPos)
                    ply:StripWeapons()
                end
            end)
        end
    end)
end)

-- =============================================
-- Команда !testarrest для суперадминов
-- =============================================
hook.Add("PlayerSay", "ZGrad_Arrest_TestCommand", function(ply, text)
    local cmd = string.lower(string.Trim(text))

    if cmd == "!testarrest" then
        if not ply:IsSuperAdmin() then
            DarkRP.notify(ply, 1, 4, "Только для суперадминов!")
            return ""
        end

        -- Арестовываем самого себя с тестовой статьёй на 15 секунд
        local success = ZGrad_Arrest.ArrestPlayer(ply, "ТЕСТ (суперадмин)", 15, ply)
        if success then
            ply:ChatPrint("[Z-Grad RP] Тестовый арест запущен! Срок: 15 секунд.")
        else
            ply:ChatPrint("[Z-Grad RP] Не удалось арестовать (возможно, вы уже в тюрьме).")
        end

        return ""
    end

    if cmd == "!testrelease" then
        if not ply:IsSuperAdmin() then
            DarkRP.notify(ply, 1, 4, "Только для суперадминов!")
            return ""
        end

        if ZGrad_Arrest.Prisoners[ply:SteamID64()] then
            ZGrad_Arrest.ReleasePlayer(ply)
            ply:ChatPrint("[Z-Grad RP] Вы освобождены принудительно.")
        else
            ply:ChatPrint("[Z-Grad RP] Вы не в тюрьме.")
        end

        return ""
    end
end)

-- Консольные команды для надежности (прописывать в консоль ~)
if SERVER then
    concommand.Add("test_arrest", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        
        local target = ply
        if args[1] then
            -- Если указан ID или часть имени (простой поиск)
            for _, v in ipairs(player.GetAll()) do
                if string.find(string.lower(v:Nick()), string.lower(args[1])) or v:UserID() == tonumber(args[1]) then
                    target = v
                    break
                end
            end
        end

        local success = ZGrad_Arrest.ArrestPlayer(target, "ТЕСТ (Консоль)", 15, ply)
        if IsValid(ply) then
            if success then
                ply:ChatPrint("[Z-Grad RP] Тестовый арест запущен для " .. target:Nick() .. "!")
            else
                ply:ChatPrint("[Z-Grad RP] Не удалось выполнить арест.")
            end
        end
    end)

    concommand.Add("test_release", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        
        local target = ply
        if args[1] then
            for _, v in ipairs(player.GetAll()) do
                if string.find(string.lower(v:Nick()), string.lower(args[1])) or v:UserID() == tonumber(args[1]) then
                    target = v
                    break
                end
            end
        end

        if ZGrad_Arrest.Prisoners[target:SteamID64()] then
            ZGrad_Arrest.ReleasePlayer(target)
            if IsValid(ply) then ply:ChatPrint("[Z-Grad RP] Игрок " .. target:Nick() .. " освобожден.") end
        else
            if IsValid(ply) then ply:ChatPrint("[Z-Grad RP] Игрок " .. target:Nick() .. " не в тюрьме.") end
        end
    end)
end

-- =============================================
-- Консольная команда для освобождения (unarest / unarrest)
-- =============================================
local function unArrestConsole(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Эта команда доступна только суперадминам!")
        return
    end

    local targetName = args[1]
    if not targetName or string.Trim(targetName) == "" then
        if IsValid(ply) then
            ply:ChatPrint("Укажите ник или ID игрока: unarest <ник>")
        else
            print("Укажите ник или ID игрока: unarest <ник>")
        end
        return
    end

    local target = nil
    if DarkRP and DarkRP.findPlayer then
        target = DarkRP.findPlayer(targetName)
    else
        local findStr = string.lower(string.Trim(targetName))
        for _, v in ipairs(player.GetAll()) do
            if string.find(string.lower(v:Nick()), findStr, 1, true) or tostring(v:UserID()) == findStr then
                target = v
                break
            end
        end
    end

    if not IsValid(target) or not target:IsPlayer() then
        if IsValid(ply) then ply:ChatPrint("Игрок не найден!") else print("Игрок не найден!") end
        return
    end

    if not ZGrad_Arrest.Prisoners[target:SteamID64()] then
        if IsValid(ply) then
            ply:ChatPrint("Игрок " .. target:Nick() .. " не в тюрьме!")
        else
            print("Игрок " .. target:Nick() .. " не в тюрьме!")
        end
        return
    end

    ZGrad_Arrest.ReleasePlayer(target)
    
    if IsValid(ply) then
        ply:ChatPrint("Вы досрочно освободили " .. target:Nick())
    else
        print("Вы досрочно освободили " .. target:Nick())
    end
    
    DarkRP.notify(target, 0, 5, "Вы были досрочно освобождены администратором!")
end

concommand.Add("unarest", unArrestConsole)
concommand.Add("unarrest", unArrestConsole)

print("[Z-Grad RP] Arrest System (Server) Loaded")

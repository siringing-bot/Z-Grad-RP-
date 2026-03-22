--[[---------------------------------------------------------------------------
Z-Grad RP — Crates System (Server)
---------------------------------------------------------------------------]]

-- Добавление предмета в ящик
function ZGrad_Crates.AddItem(crate, ent)
    if not IsValid(crate) or not IsValid(ent) then return false end
    if ent:IsPlayer() or ent:IsNPC() or ent.IsCrate then return false end -- Защита от игроков и самих ящиков

    -- Проверка на 5-секундный кулдаун после извлечения
    if ent.ZGrad_Crate_TakeTime and (ent.ZGrad_Crate_TakeTime + 5 > CurTime()) then
        return false
    end

    local class = ent:GetClass()
    if class == "zgrad_trash_can" or class == "zgrad_contraband_dealer" then
        local owner = ent.Getowning_ent and ent:Getowning_ent() or ent:GetNW2Entity("owner")
        if IsValid(owner) and owner:IsPlayer() then
            DarkRP.notify(owner, 1, 4, "Этот предмет нельзя класть в ящик!")
        end
        return false
    end

    -- ЗАПРЕТ ПРОПОВ (Любых физических пропов)
    if string.StartWith(class, "prop_") or class == "prop_ragdoll" then 
        local owner = ent.Getowning_ent and ent:Getowning_ent() or ent:GetNW2Entity("owner")
        if IsValid(owner) and owner:IsPlayer() then
            if not owner._ZGrad_CrateNotify or owner._ZGrad_CrateNotify < CurTime() then
                DarkRP.notify(owner, 1, 4, "В ящик нельзя класть пропы!")
                owner._ZGrad_CrateNotify = CurTime() + 2
            end
        end
        return false 
    end

    local typeData = ZGrad_Crates.Types[crate:GetClass()]
    if not typeData then 
        print("[Z-Grad Crate] Error: No type data for " .. crate:GetClass())
        return false 
    end
    
    crate.CrateItems = crate.CrateItems or {}
    
    -- Проверка на лимит
    if #crate.CrateItems >= typeData.capacity then 
        local owner = ent.Getowning_ent and ent:Getowning_ent() or ent:GetNW2Entity("owner")
        if IsValid(owner) and owner:IsPlayer() then
            if not owner._ZGrad_CrateFullNotify or owner._ZGrad_CrateFullNotify < CurTime() then
                DarkRP.notify(owner, 1, 4, "Ящик переполнен!")
                owner._ZGrad_CrateFullNotify = CurTime() + 2
            end
        end
        return false 
    end
    
    -- Проверка на типы (не ящик и не рагдолл)
    if ent:IsRagdoll() or ent:IsVehicle() then return false end
    if string.find(class, "door") then return false end
    if ZGrad_Crates.Types[class] then return false end
    
    -- Сохраняем данные
    local item = {
        class = class,
        model = ent:GetModel(),
        skin = ent:GetSkin() or 0,
        name = ent.PrintName or (ent:IsWeapon() and ent.PrintName) or (ent.GetModel and ent:GetModel():match(".*/(.*)%.mdl") or class),
        npcBought = ent.ZGrad_NpcBought,
        npcSubType = ent.ZGrad_NpcSubType
    }
    
    -- СПЕЦИАЛЬНАЯ ОБРАБОТКА МЕТА (Сохранение данных)
    if class == "zgrad_meth_ingredient" then
        item.meth_data = {
            id = ent:GetIngredientID(),
            grams = ent:GetGrams()
        }
        if ZGRAD_METH and ZGRAD_METH.Ingredients[item.meth_data.id] then
            item.name = ZGRAD_METH.Ingredients[item.meth_data.id].name .. " (" .. item.meth_data.grams .. "г)"
        end
    elseif class == "zgrad_meth_product" or scripted_ents.IsBasedOn(class, "zgrad_meth_product") then
        item.meth_data = {
            type = ent:GetMethType(),
            grams = ent:GetGrams(),
            quality = ent:GetQuality()
        }
        local recipeName = item.name
        if ZGRAD_METH and ZGRAD_METH.Recipes[item.meth_data.type] then
            recipeName = ZGRAD_METH.Recipes[item.meth_data.type].name
        end
        item.name = recipeName .. " (" .. item.meth_data.grams .. "г, " .. item.meth_data.quality .. "%)"
    elseif class == "zgrad_meth_pot" then
        item.meth_data = {
            contents = ent.Contents or {},
            contentsList = ent.ContentsList or {},
            recipe = ent:GetSelectedRecipe(),
            step = ent:GetCurrentStep(),
            ready = ent:GetIsReady(),
            quality = ent:GetCookQuality(),
            display = ent:GetContentsDisplay()
        }
        if item.meth_data.recipe ~= "" and ZGRAD_METH and ZGRAD_METH.Recipes[item.meth_data.recipe] then
            item.name = "Кастрюля: " .. ZGRAD_METH.Recipes[item.meth_data.recipe].name
        end
    elseif class == "zgrad_meth_basin" then
        item.meth_data = {
            contentsList = ent.ContentsList or {},
            step = ent:GetCurrentStep(),
            ready = ent:GetIsReady(),
            display = ent:GetContentsDisplay()
        }
        if item.meth_data.ready then
            item.name = "Тазик: Готовый Fury-13"
        end
    end
    
    -- Специальная обработка для оружия
    if ent:IsWeapon() then
        item.name = ent.PrintName or class
        item.model = ent:GetInternalVariable("m_ModelName") or ent:GetModel()
    end
    
    table.insert(crate.CrateItems, item)
    
    -- Удаляем энтити (лимит сбросится автоматически через хук EntityRemoved в sv_cleanup.lua)
    ent:Remove()
    
    -- Звук
    crate:EmitSound("physics/wood/wood_box_impact_soft1.wav")
    
    -- Обновляем NWVar для HUD
    crate:SetNWInt("ZGrad_CrateCount", #crate.CrateItems)
    
    return true
end

-- Извлечение предмета
net.Receive("ZGrad_Crates_TakeItem", function(len, ply)
    local crate = net.ReadEntity()
    local index = net.ReadUInt(8)
    
    if not IsValid(crate) or not ZGrad_Crates.Types[crate:GetClass()] then return end
    if ply:GetPos():DistToSqr(crate:GetPos()) > 62500 then return end
    
    -- Проверка: закрыт ли ящик? (из DarkRP)
    if ZGrad_Crates.IsLocked(crate) then
        DarkRP.notify(ply, 1, 4, "Ящик закрыт!")
        return
    end
    
    crate.CrateItems = crate.CrateItems or {}
    local item = crate.CrateItems[index]
    
    -- ПРОВЕРКА ЛИМИТА
    local canSpawn, maxLimit = ZGrad_Utility.CheckLimit(ply, item.class)
    if not canSpawn then
        DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете достать больше " .. (item.name or item.class) .. " (" .. maxLimit .. ")!")
        return
    end

    -- ПРОВЕРКА ЛИМИТА NPC
    if item.npcBought then
        local canSpawnNpc, count = ZGrad_Utility.CheckNpcLimit(ply, item.class, item.npcSubType)
        if not canSpawnNpc then
            DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете достать еще один такой предмет от торговца (Макс 2 в мире)!")
            return
        end
    end

    -- Поиск таблицы энтити для DarkRP
    local entTable = nil
    if DarkRPEntities then
        for _, e in pairs(DarkRPEntities) do
            if e.ent == item.class then
                entTable = e
                break
            end
        end
    end

    -- Создаем предмет
    local ent = ents.Create(item.class)
    if IsValid(ent) then
        ent:SetModel(item.model)
        ent:SetSkin(item.skin)
        
        -- УПРАВЛЕНИЕ ВЛАДЕНИЕМ И ЛИМИТАМИ
        if ent.Setowning_ent then ent:Setowning_ent(ply) end
        ent:SetNW2Entity("owner", ply)
        ent.ZGrad_Owner = ply
        ent.DarkRPItem = entTable
        ent.ZGrad_NpcBought = item.npcBought
        ent.ZGrad_NpcSubType = item.npcSubType

        -- Регистрируем в системах лимитов
        ply:AddCount(item.class, ent)
        if entTable and ply.addCustomEntity then
            ply:addCustomEntity(entTable)
        end

        ent:SetPos(ply:GetShootPos() + ply:GetForward() * 20)
        ent:Spawn()

        -- ВОССТАНОВЛЕНИЕ ДАННЫХ МЕТА
        if item.meth_data then
            if item.class == "zgrad_meth_ingredient" then
                if ent.SetIngredient then
                    ent:SetIngredient(item.meth_data.id, item.meth_data.grams)
                else
                    ent:SetIngredientID(item.meth_data.id or "")
                    ent:SetGrams(item.meth_data.grams or 0)
                end
            elseif item.class == "zgrad_meth_product" or (scripted_ents and scripted_ents.IsBasedOn(item.class, "zgrad_meth_product")) then
                if ent.SetMethData then
                     ent:SetMethData(item.meth_data.type, item.meth_data.grams, item.meth_data.quality)
                else
                    ent:SetMethType(item.meth_data.type or "")
                    ent:SetGrams(item.meth_data.grams or 0)
                    ent:SetQuality(item.meth_data.quality or 0)
                end
            elseif item.class == "zgrad_meth_pot" then
                ent.Contents = item.meth_data.contents or {}
                ent.ContentsList = item.meth_data.contentsList or {}
                ent:SetSelectedRecipe(item.meth_data.recipe or "")
                ent:SetCurrentStep(item.meth_data.step or 0)
                ent:SetIsReady(item.meth_data.ready or false)
                ent:SetCookQuality(item.meth_data.quality or 100)
                ent:SetContentsDisplay(item.meth_data.display or "")
                ent:SetIsCooking(false)
            elseif item.class == "zgrad_meth_basin" then
                ent.ContentsList = item.meth_data.contentsList or {}
                ent:SetCurrentStep(item.meth_data.step or 0)
                ent:SetIsReady(item.meth_data.ready or false)
                ent:SetContentsDisplay(item.meth_data.display or "")
            end
        end

        ent.ZGrad_Crate_TakeTime = CurTime() -- Устанавливаем время извлечения
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
        
        table.remove(crate.CrateItems, index)
        crate:SetNWInt("ZGrad_CrateCount", #crate.CrateItems)
        crate:EmitSound("physics/wood/wood_box_impact_soft2.wav")
        
        -- Повторно шлем список чтобы обновить список у игрока
        net.Start("ZGrad_Crates_OpenMenu")
            net.WriteEntity(crate)
            net.WriteTable(crate.CrateItems or {})
        net.Send(ply)
    end
end)

-- Проверка владения
local function IsCrateOwner(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return false end
    
    -- Проверка через наш кастомный NW-параметр
    if ent:GetNW2Entity("owner") == ply then return true end
    
    -- Проверка через стандартный DarkRP
    if ent.Getowning_ent and ent:Getowning_ent() == ply then return true end
    
    -- Проверка через CPPI (если есть)
    if ent.CPPIGetOwner and ent:CPPIGetOwner() == ply then return true end
    
    -- Проверка через ключи (DarkRP внутреннее)
    if ent.isKeysOwnedBy and ent:isKeysOwnedBy(ply) then return true end

    return false
end

hook.Add("CanKeysUnlock", "ZGrad_Crates_Unlock", function(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        if IsCrateOwner(ent, ply) then return true end
        return false, "Вы не владелец этого ящика!"
    end
end)

hook.Add("CanKeysLock", "ZGrad_Crates_Lock", function(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        if IsCrateOwner(ent, ply) then return true end
        return false, "Вы не владелец этого ящика!"
    end
end)

-- =============================================
-- Обработка зажатия кнопки E для закрытия/открытия
-- =============================================

-- New logic handled by KeyPress/KeyRelease below

-- =============================================
-- Обработка перемещения гравпушкой / физпушкой / руками (Сброс приварки)
-- =============================================
hook.Add("PhysgunPickup", "ZGrad_Crates_UnweldOnGrab", function(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        ent._ZGrad_IsBeingHeld = true
        constraint.RemoveAll(ent) -- Снимаем приварку при поднятии
    end
end)

hook.Add("PhysgunDrop", "ZGrad_Crates_UnweldOffGrab", function(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        ent._ZGrad_IsBeingHeld = false
    end
end)

hook.Add("GravGunOnPickedUp", "ZGrad_Crates_GravUnweld", function(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        constraint.RemoveAll(ent)
    end
end)

-- Поддержка отсоединения руками (Z-City Hands)
hook.Add("Think", "ZGrad_Crates_HandsMonitor", function()
    for _, ply in ipairs(player.GetAll()) do
        -- В Z-City руках энтити записывается в NetVar "carryent"
        local carried = ply:GetNetVar("carryent")
        if IsValid(carried) and (carried:GetClass() == "zgrad_crate_small" or carried:GetClass() == "zgrad_crate_large") then
            if constraint.HasConstraints(carried) then
                constraint.RemoveAll(carried)
            end
        end
    end
end)
hook.Add("KeyPress", "ZGrad_Crates_Interactions_Press", function(ply, key)
    if key ~= IN_USE then return end
    
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        if ply:GetPos():DistToSqr(ent:GetPos()) > 22500 then return end -- 150 units range
        
        ply._ZGrad_CrateHoldTime = CurTime()
        ply._ZGrad_CrateHoldEnt = ent
    end
end)

hook.Add("KeyRelease", "ZGrad_Crates_Interactions_Release", function(ply, key)
    if key ~= IN_USE then return end
    if not ply._ZGrad_CrateHoldTime or not IsValid(ply._ZGrad_CrateHoldEnt) then return end
    
    local ent = ply._ZGrad_CrateHoldEnt
    local duration = CurTime() - ply._ZGrad_CrateHoldTime
    
    ply._ZGrad_CrateHoldTime = nil
    ply._ZGrad_CrateHoldEnt = nil
    
    if ply:GetPos():DistToSqr(ent:GetPos()) > 22500 then return end

    -- Hold E for 0.5s to Toggle Lock
    if duration >= 0.5 then
        if IsCrateOwner(ent, ply) then
            local isLocked = ent:GetNWBool("locked", false)
            if isLocked then
                ent:SetNWBool("locked", false)
                ent:EmitSound("doors/door_stop1.wav")
                DarkRP.notify(ply, 0, 4, "Ящик открыт (Разблокирован).")
            else
                ent:SetNWBool("locked", true)
                ent:EmitSound("doors/door_latch3.wav")
                DarkRP.notify(ply, 0, 4, "Ящик закрыт (Заблокирован).")
            end
        else
            DarkRP.notify(ply, 1, 4, "Вы не владелец этого ящика!")
        end
        return
    end
    
    -- Quick press to Open UI
    if ZGrad_Crates.IsLocked(ent) then
        DarkRP.notify(ply, 1, 4, "Ящик закрыт! Зажмите E на 0.5 сек чтобы его открыть.")
        return
    end

    net.Start("ZGrad_Crates_OpenMenu")
        net.WriteEntity(ent)
        net.WriteTable(ent.CrateItems or {})
    net.Send(ply)
    
    ent:EmitSound("physics/wood/wood_box_impact_soft3.wav")
end)

-- Disable standard PlayerUse for crates to ensure only KeyRelease triggers UI/Toggle
hook.Add("PlayerUse", "ZGrad_Crates_DisableUse", function(ply, ent)
    if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
        return false 
    end
end)

print("[Z-Grad RP] Crates System (Server) Loaded")

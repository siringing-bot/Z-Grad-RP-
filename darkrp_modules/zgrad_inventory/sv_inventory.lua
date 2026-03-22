--[[---------------------------------------------------------------------------
Z-Grad RP — Inventory System (Server)
---------------------------------------------------------------------------]]

-- Добавить предмет в инвентарь
function ZGrad_Inventory.AddItem(ply, ent)
    local inv = ZGrad_Inventory.GetPlayerInv(ply)
    
    -- Ищем свободный слот
    local slot = -1
    for i = 1, ZGrad_Inventory.MaxSlots do
        if not inv[i] then
            slot = i
            break
        end
    end
    
    if slot == -1 then return false end
    
    local class = ent:GetClass()
    if class == "zgrad_trash_can" then
        DarkRP.notify(ply, 1, 4, "Эту мусорку нельзя класть в инвентарь!")
        return false
    end

    if class == "prop_physics" then
        DarkRP.notify(ply, 1, 4, "Пропы нельзя класть в инвентарь!")
        return false
    end

    if class == "zgrad_noodle_vending" then
        DarkRP.notify(ply, 1, 4, "Автомат нельзя класть в инвентарь!")
        return false
    end

    if class == "zgrad_crate_large" then
        DarkRP.notify(ply, 1, 4, "Большой ящик не влезает в инвентарь!")
        return false
    end

    if class == "zgrad_crate_small" then
        DarkRP.notify(ply, 1, 4, "Маленький ящик слишком громоздкий для инвентаря!")
        return false
    end

    if class == "zgrad_contraband_dealer" then
        DarkRP.notify(ply, 1, 4, "Вы не можете положить живого человека в инвентарь!")
        return false
    end


    -- Сохраняем данные предмета
    inv[slot] = {
        class = class,
        model = ent:GetModel(),
        skin = ent:GetSkin() or 0,
        name = ent.PrintName or class,
        isWeapon = ent:IsWeapon(),
        npcBought = ent.ZGrad_NpcBought,
        npcSubType = ent.ZGrad_NpcSubType
    }

    -- СПЕЦИАЛЬНАЯ ОБРАБОТКА МЕТА (Сохранение данных)
    if class == "zgrad_meth_product" or scripted_ents.IsBasedOn(class, "zgrad_meth_product") then
        inv[slot].meth_data = {
            type = ent:GetMethType(),
            grams = ent:GetGrams(),
            quality = ent:GetQuality()
        }
        -- Обновляем имя для отображения в инвентаре
        local recipeName = inv[slot].name
        if ZGRAD_METH and ZGRAD_METH.Recipes[inv[slot].meth_data.type] then
            recipeName = ZGRAD_METH.Recipes[inv[slot].meth_data.type].name
        end
        inv[slot].name = recipeName .. " (" .. inv[slot].meth_data.grams .. "г, " .. inv[slot].meth_data.quality .. "%)"
    elseif class == "zgrad_meth_ingredient" then
        inv[slot].meth_data = {
            id = ent:GetIngredientID(),
            grams = ent:GetGrams()
        }
        if ZGRAD_METH and ZGRAD_METH.Ingredients[inv[slot].meth_data.id] then
            inv[slot].name = ZGRAD_METH.Ingredients[inv[slot].meth_data.id].name .. " (" .. inv[slot].meth_data.grams .. "г)"
        end
    end

    -- Специальная обработка для оружия
    if ent:IsWeapon() then
        inv[slot].name = ent.PrintName or class
        -- Для оружия GetModel() часто возвращает вьюмодель, пробуем найти ворлдмодель
        inv[slot].model = ent:GetInternalVariable("m_ModelName") or ent:GetModel()
    end
    
    -- Если это проп, пытаемся вытянуть имя покрасивее
    if class == "prop_physics" then
        inv[slot].name = "Проп (" .. (ent:GetModel():match(".*/(.*)%.mdl") or "prop") .. ")"
    end

    ZGrad_Inventory.Sync(ply)
    ZGrad_Inventory.Save(ply)

    -- ПОДГОТОВКА К УДАЛЕНИЮ (Важно для корректного сброса лимитов)
    local owner = ent.ZGrad_Owner or ent:GetNW2Entity("owner") or (ent.Getowning_ent and ent:Getowning_ent())
    if not IsValid(owner) then owner = ply end

    ent.ZGrad_Owner = owner
    ent.SID = owner:SteamID() -- Позволяет DarkRP найти владельца при удалении

    if not ent.DarkRPItem and DarkRPEntities then
        for _, e in pairs(DarkRPEntities) do
            if e.ent == class then
                ent.DarkRPItem = e
                break
            end
        end
    end

    -- Удаляем из мира (лимит сбросится через встроенный хук DarkRP)
    ent:Remove()

    return true, slot
end

-- Синхронизация с клиентом
function ZGrad_Inventory.Sync(ply)
    local inv = ZGrad_Inventory.GetPlayerInv(ply)
    net.Start("ZGrad_Inventory_Sync")
    net.WriteTable(inv)
    net.Send(ply)
end

-- Выкинуть предмет
function ZGrad_Inventory.DropItem(ply, slot)
    local inv = ZGrad_Inventory.GetPlayerInv(ply)
    local item = inv[slot]
    
    if not item then return end
    
    -- ПРОВЕРКА ЛИМИТА
    local canSpawn, maxLimit = ZGrad_Utility.CheckLimit(ply, item.class)
    if not canSpawn then
        DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете достать больше " .. item.class .. " (" .. maxLimit .. ")!")
        ZGrad_Inventory.Sync(ply) -- Возвращаем предмет в инвентарь на клиенте (если он его локально скрыл)
        return
    end

    -- ПРОВЕРКА ЛИМИТА NPC
    if item.npcBought then
        local canSpawnNpc, count = ZGrad_Utility.CheckNpcLimit(ply, item.class, item.npcSubType)
        if not canSpawnNpc then
            DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете достать еще один такой предмет от торговца (Макс 2 в мире)!")
            ZGrad_Inventory.Sync(ply)
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

    -- Создаем энтити
    local ent = ents.Create(item.class)
    if not IsValid(ent) then return end
    
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

    -- Позиция
    local pos = (ply.getItemDropPos and ply:getItemDropPos()) or (ply:GetShootPos() + ply:GetForward() * 50)
    ent:SetPos(pos)
    ent:Spawn()
    
    -- ВОССТАНОВЛЕНИЕ ДАННЫХ МЕТА
    if item.meth_data then
        if item.class == "zgrad_meth_product" or scripted_ents.IsBasedOn(item.class, "zgrad_meth_product") then
            if ent.SetMethData then
                ent:SetMethData(item.meth_data.type, item.meth_data.grams, item.meth_data.quality)
            else
                -- Фоллбэк если метода нет (хотя должен быть)
                if ent.SetMethType then ent:SetMethType(item.meth_data.type or "") end
                if ent.SetGrams then ent:SetGrams(item.meth_data.grams or 0) end
                if ent.SetQuality then ent:SetQuality(item.meth_data.quality or 0) end
            end
        elseif item.class == "zgrad_meth_ingredient" then
            if ent.SetIngredient then
                ent:SetIngredient(item.meth_data.id, item.meth_data.grams)
            else
                if ent.SetIngredientID then ent:SetIngredientID(item.meth_data.id or "") end
                if ent.SetGrams then ent:SetGrams(item.meth_data.grams or 0) end
            end
        end
    end

    -- Физика
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    -- Удаляем из инвентаря
    inv[slot] = nil
    ZGrad_Inventory.Sync(ply)
    ZGrad_Inventory.Save(ply)
    
    ply:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav")
end

-- Обработка запроса на выброс
net.Receive("ZGrad_Inventory_Drop", function(len, ply)
    local slot = net.ReadUInt(4)
    ZGrad_Inventory.DropItem(ply, slot)
end)



-- Глобальный запрет на выброс самого свепа инвентаря
hook.Add("canDropWeapon", "ZGrad_Inventory_PreventDrop", function(ply, wep)
    if IsValid(wep) and wep:GetClass() == "zgrad_inventory" then
        return false
    end
end)

-- ПЕРСИСТЕНТНОСТЬ (СОХРАНЕНИЕ)

local function GetSavePath(ply)
    return "zgrad/inventory/" .. ply:SteamID64() .. ".json"
end

-- Сохранение
function ZGrad_Inventory.Save(ply)
    if not IsValid(ply) then return end
    local inv = ZGrad_Inventory.GetPlayerInv(ply)
    
    if not file.Exists("zgrad/inventory", "DATA") then
        file.CreateDir("zgrad/inventory")
    end
    
    file.Write(GetSavePath(ply), util.TableToJSON(inv))
end

-- Загрузка
function ZGrad_Inventory.Load(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    if not sid or sid == "0" then return end
    
    local path = GetSavePath(ply)
    
    if file.Exists(path, "DATA") then
        local data = file.Read(path, "DATA")
        local inv = util.JSONToTable(data)
        if inv then
            -- Превращаем ключи обратно в числа (JSON часто превращает их в строки)
            local cleanInv = {}
            for k, v in pairs(inv) do
                cleanInv[tonumber(k) or k] = v
            end
            
            ply.ZGrad_Inventory = cleanInv
            ZGrad_Inventory.Sync(ply)
            print("[Z-Grad Inventory] Loaded " .. table.Count(cleanInv) .. " items for " .. ply:Nick())
        end
    else
        print("[Z-Grad Inventory] No save found for " .. ply:Nick())
        ply.ZGrad_Inventory = {}
    end
end

-- Загрузка при входе (PlayerAuthed надежнее для SteamID)
hook.Add("PlayerAuthed", "ZGrad_Inventory_LoadPersist", function(ply, steamID, uniqueID)
    timer.Simple(1, function()
        if IsValid(ply) then
            ZGrad_Inventory.Load(ply)
        end
    end)
end)

-- На случай если PlayerAuthed не сработал или это локальный сервер
hook.Add("PlayerInitialSpawn", "ZGrad_Inventory_LoadFallback", function(ply)
    timer.Simple(5, function()
        if IsValid(ply) and (not ply.ZGrad_Inventory or table.Count(ply.ZGrad_Inventory) == 0) then
            ZGrad_Inventory.Load(ply)
        end
    end)
end)

-- Мы убираем PlayerDeath очистку, чтобы предметы были настоящим "тайником", 
-- который сохраняется даже после смерти (если нужно иное - верни хук очистки)
-- hook.Remove("PlayerDeath", "ZGrad_Inventory_Clear")

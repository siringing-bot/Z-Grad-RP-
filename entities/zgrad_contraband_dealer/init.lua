AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local ShopItems = ENT.ShopItems

util.AddNetworkString("ZGrad_Contraband_OpenShop")
util.AddNetworkString("ZGrad_Contraband_BuyItem")

function ENT:Initialize()
    self:SetModel("models/player/phoenix.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE)
    self:CapabilitiesAdd(CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetMaxYawSpeed(90)

    -- Включаем продвижение кадров
    self:SetAutomaticFrameAdvance(true)
    
    -- Ищем индекс анимации. Для CSS моделей это почти всегда "idle_all_01"
    local animIndex = self:LookupSequence("idle_all_01")
    if animIndex == -1 then animIndex = self:LookupSequence("idle") end
    
    if animIndex != -1 then
        self:SetSequence(animIndex)
    end
end

function ENT:Think()
    -- Для моделей игроков (Playermodels) нужно постоянно обновлять цикл анимации
    self:FrameAdvance(CurTime()) 

    -- Если NPC почему-то сбросился в 0-ю последовательность (Т-поза)
    if self:GetSequence() == 0 then
        local animIndex = self:LookupSequence("idle_all_01")
        if animIndex != -1 then
            self:SetSequence(animIndex)
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(caller) and caller:IsPlayer() then
        -- Открываем меню
        net.Start("ZGrad_Contraband_OpenShop")
        net.Send(caller)
    end
end

-- Обработка покупки
net.Receive("ZGrad_Contraband_BuyItem", function(len, ply)
    local category = net.ReadString()
    local index = net.ReadUInt(8)
    
    -- Валидация
    local shopTable = ShopItems[category]
    if not shopTable then return end
    
    
    local item = shopTable[index]
    if not item then return end

    -- Расчет цены: х3 для всех, кроме TEAM_GUN
    local finalPrice = item.price
    if ply:Team() ~= TEAM_GUN then
        finalPrice = item.price * 3
    end
    
    if item.isCriminal and not ZGrad_Utility.IsCriminal(ply) then
        DarkRP.notify(ply, 1, 4, "Только криминальные личности могут покупать это!")
        return
    end

    -- Проверка лимита (Макс 2 предмета одного вида от NPC)
    local canBuy, count = ZGrad_Utility.CheckNpcLimit(ply, item.class or item.ammoType)
    if not canBuy then
        DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете иметь больше 2-х " .. item.name .. " от торговцев.")
        return
    end

    -- Проверка денег
    if not ply:canAfford(finalPrice) then
        DarkRP.notify(ply, 1, 4, "У вас недостаточно средств!")
        return
    end
    
    -- Покупка
    ply:addMoney(-finalPrice)
    DarkRP.notify(ply, 0, 4, "Вы купили " .. item.name .. " за " .. DarkRP.formatMoney(finalPrice))
    
    -- Функция спавна энтити перед игроком
    local function SpawnItem(class, model)
        local trace = {}
        trace.start = ply:EyePos()
        trace.endpos = trace.start + ply:GetAimVector() * 50
        trace.filter = ply
        local tr = util.TraceLine(trace)

        local ent = ents.Create(class)
        if not IsValid(ent) then 
            print("[ZGrad Shop] Failed to create entity: " .. tostring(class))
            return nil 
        end
        
        ent:SetPos(tr.HitPos + tr.HitNormal * 10)
        
        -- Если это оружие, и у него нет модели в shared.lua (на всякий случай), 
        -- то модель сама проставится самим энтити.
        -- Но если мы спавним spawned_weapon, ему нужна модель.
        -- DarkRP обычно спавнит 'spawned_weapon' для оружия.
        -- Но пользователь просил "как энтити". Если оружие имеет свой энтити (как weapon_ak47), оно само заспавнится.
        -- Стандартное оружие (weapon_pistol) тоже спавнится как энтити.
        
        ent:Spawn()
        ent:Activate()
        
        ent.ZGrad_NpcBought = true
        ent.ZGrad_Owner = ply

        return ent
    end

    -- Выдача предмета (Логика в зависимости от категории)
    if category == "Weapons" then
        -- Поиск таблицы энтити для проверки лимитов
        local entTable = nil
        if DarkRPEntities then
            for _, e in pairs(DarkRPEntities) do
                if e.ent == item.class then entTable = e break end
            end
        end

        -- Проверка лимитов (если это не просто оружие, а DarkRP энтити)
        if entTable then
            local canSpawn, limit = ZGrad_Utility.CheckLimit(ply, item.class)
            if not canSpawn then
                DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете иметь больше " .. limit .. " " .. item.name)
                ply:addMoney(finalPrice) -- Возврат денег
                return
            end
        end

        -- Спавним само оружие как энтити
        local ent = SpawnItem(item.class)
        if not IsValid(ent) then
             print("[ZGrad Shop] FAILED to spawn weapon " .. item.class)
             DarkRP.notify(ply, 1, 4, "Ошибка: Не удалось создать предмет!")
             ply:addMoney(finalPrice) -- Возврат денег
             return
        end

        -- Установка владения и лимитов
        if ent.Setowning_ent then ent:Setowning_ent(ply) end
        ent:SetNW2Entity("owner", ply)
        ent.ZGrad_Owner = ply
        ent.SID = ply:SteamID() -- Позволяет DarkRP отслеживать лимиты
        if entTable then
            ent.DarkRPItem = entTable
            ply:AddCount(item.class, ent)
            if ply.addCustomEntity then ply:addCustomEntity(entTable) end
        end

        DarkRP.notify(ply, 0, 4, "Вы купили предмет. Он лежит перед вами.")
        
    elseif category == "Ammo" then
        -- Прямая выдача патронов обычно не имеет лимита энтити
        -- (Код спавна патронов остается прежним)
        if string.find(item.ammoType, "^ent_") then
            local ent = SpawnItem(item.ammoType)
            if not IsValid(ent) then
                 print("[ZGrad Shop] FAILED to spawn ammo entity: " .. tostring(item.ammoType))
                 DarkRP.notify(ply, 1, 4, "Ошибка: Не удалось создать патроны " .. tostring(item.ammoType))
                 ply:addMoney(finalPrice)
                 return
            end
            
            if ent.Setowning_ent then ent:Setowning_ent(ply) end
            ent.ZGrad_Owner = ply
            ent.SID = ply:SteamID()
            
            DarkRP.notify(ply, 0, 4, "Патроны лежат перед вами.")
        else
            -- Стандартные патроны
            local trace = {}
            trace.start = ply:EyePos()
            trace.endpos = trace.start + ply:GetAimVector() * 50
            trace.filter = ply
            local tr = util.TraceLine(trace)

            local ammo = ents.Create("spawned_ammo")
            if IsValid(ammo) then
                ammo:SetPos(tr.HitPos + tr.HitNormal * 10)
                ammo.nodupe = true
                ammo.amountGiven = item.amount
                ammo.ammoType = item.ammoType
                ammo:SetModel(item.model or "models/Items/BoxSRounds.mdl")
                
                ammo:Spawn()
                if ammo.Setowning_ent then ammo:Setowning_ent(ply) end
                ammo.ZGrad_NpcBought = true
                ammo.ZGrad_Owner = ply
                ammo.SID = ply:SteamID()
                DarkRP.notify(ply, 0, 4, "Патроны сброшены перед вами.")
            else
                ply:addMoney(finalPrice)
                DarkRP.notify(ply, 1, 4, "Ошибка создания патронов!")
            end
        end

    elseif category == "Attachments" then
        if item.class then
             -- Поиск таблицы энтити для проверки лимитов
             local entTable = nil
             if DarkRPEntities then
                 for _, e in pairs(DarkRPEntities) do
                     if e.ent == item.class then entTable = e break end
                 end
             end

             if entTable then
                 local canSpawn, limit = ZGrad_Utility.CheckLimit(ply, item.class)
                 if not canSpawn then
                     DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете иметь больше " .. limit .. " " .. item.name)
                     ply:addMoney(finalPrice)
                     return
                 end
             end

             local ent = SpawnItem(item.class)
             if not IsValid(ent) then
                 ply:addMoney(finalPrice)
                 DarkRP.notify(ply, 1, 4, "Ошибка создания предмета!")
             else
                 if ent.Setowning_ent then ent:Setowning_ent(ply) end
                 ent:SetNW2Entity("owner", ply)
                 ent.ZGrad_Owner = ply
                 ent.SID = ply:SteamID()
                 if entTable then
                     ent.DarkRPItem = entTable
                     ply:AddCount(item.class, ent)
                     if ply.addCustomEntity then ply:addCustomEntity(entTable) end
                 end
                 DarkRP.notify(ply, 0, 4, "Предмет лежит перед вами.")
             end
        end
    end
    
    -- Звук покупки
    ply:EmitSound("items/ammo_pickup.wav")
end)




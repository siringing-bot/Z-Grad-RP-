AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local ShopItems = ENT.ShopItems

util.AddNetworkString("ZGrad_WeaponSeller_OpenShop")
util.AddNetworkString("ZGrad_WeaponSeller_BuyItem")

function ENT:Initialize()
    self:SetModel("models/monk.mdl") -- Скин Священника Григория
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_SCRIPT)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE)
    self:CapabilitiesAdd(CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetMaxYawSpeed(90)
    
    -- Animation Fix
    self:SetAutomaticFrameAdvance(true)
    local seq = self:LookupSequence("idle_all_01")
    if seq == -1 then seq = self:LookupSequence("idle") end
    if seq ~= -1 then
        self:SetSequence(seq)
    end
end

function ENT:Think()
    self:FrameAdvance(CurTime())

    if self:GetSequence() == 0 then
        local seq = self:LookupSequence("idle_all_01")
        if seq ~= -1 then self:SetSequence(seq) end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(caller) and caller:IsPlayer() then
        -- Открываем меню
        net.Start("ZGrad_WeaponSeller_OpenShop")
        net.Send(caller)
    end
end

-- Обработка покупки
net.Receive("ZGrad_WeaponSeller_BuyItem", function(len, ply)
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
    
    print("[ZGrad Shop] Player " .. ply:Nick() .. " trying to buy " .. tostring(item.class) .. " for " .. finalPrice)

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
        -- Спавним само оружие как энтити
        -- В DarkRP часто используют spawned_weapon, но если мы заспавним weapon_ak47, 
        -- он просто будет лежать и его можно подобрать.
        local ent = SpawnItem(item.class)
        if not IsValid(ent) then
             print("[ZGrad Shop] FAILED to spawn weapon " .. item.class)
             DarkRP.notify(ply, 1, 4, "Ошибка: Не удалось создать предмет!")
             ply:addMoney(item.price) -- Возврат денег
             return
        end
        DarkRP.notify(ply, 0, 4, "Вы купили предмет. Он лежит перед вами.")
        
    elseif category == "Ammo" then
        -- Check if it's a specific ammo entity (starts with ent_) or assume it is if it's in this list now
        if string.find(item.ammoType, "^ent_") then
            local ent = SpawnItem(item.ammoType)
            if not IsValid(ent) then
                 print("[ZGrad Shop] FAILED to spawn ammo entity: " .. tostring(item.ammoType))
                 DarkRP.notify(ply, 1, 4, "Ошибка: Не удалось создать патроны " .. tostring(item.ammoType))
                 ply:addMoney(item.price)
                 return
            end
            DarkRP.notify(ply, 0, 4, "Патроны лежат перед вами.")
        else
            -- Fallback to standard DarkRP spawned_ammo for standard types like "Pistol"
            local trace = {}
            trace.start = ply:EyePos()
            trace.endpos = trace.start + ply:GetAimVector() * 50
            trace.filter = ply
            local tr = util.TraceLine(trace)

            local ammo = ents.Create("spawned_ammo")
            if IsValid(ammo) then
                ammo:SetPos(tr.HitPos + tr.HitNormal * 10)
                ammo.nodupe = true
                ammo.amountGiven = item.amount -- DarkRP specific
                ammo.ammoType = item.ammoType
                if item.model then
                    ammo:SetModel(item.model)
                else
                    ammo:SetModel("models/Items/BoxSRounds.mdl") -- Fallback model
                end
                
                ammo:Spawn()
                ammo.ZGrad_NpcBought = true
                ammo.ZGrad_Owner = ply
                DarkRP.notify(ply, 0, 4, "Патроны сброшены перед вами.")
            else
                ply:addMoney(item.price)
                DarkRP.notify(ply, 1, 4, "Ошибка создания патронов!")
            end
        end

    elseif category == "Attachments" then
        if item.class then
             local ent = SpawnItem(item.class)
             if not IsValid(ent) then
                 ply:addMoney(item.price)
                 DarkRP.notify(ply, 1, 4, "Ошибка создания предмета!")
             else
                 DarkRP.notify(ply, 0, 4, "Предмет лежит перед вами.")
             end
        end
    end
    
    -- Звук покупки
    ply:EmitSound("items/ammo_pickup.wav")
end)




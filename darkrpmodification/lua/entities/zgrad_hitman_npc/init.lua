AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Регистрируем названия сетевых сообщений
util.AddNetworkString("ZGrad_HitOrder") -- Для открытия меню у заказчика
util.AddNetworkString("ZGrad_SendHitToKiller") -- Для отправки данных киллеру

function ENT:Initialize()
    self:SetModel("models/player/gman_high.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_IDLE)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE + CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()

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
    if name == "Use" and IsValid(activator) and activator:IsPlayer() then
        net.Start("ZGrad_HitOrder")
        net.WriteBool(true)
        net.Send(activator)
    end
end

-- Принимаем данные от клиента (заказчика), который выбрал жертву
net.Receive("ZGrad_HitOrder", function(len, ply)
    local target = net.ReadEntity() -- Кого заказали
    local price = net.ReadInt(32)   -- За сколько

    -- Проверка: Киллер не может заказывать
    if ply:Team() == TEAM_KILLER or (ZGrad_Hitman and ZGrad_Hitman.IsHitman and ZGrad_Hitman.IsHitman(ply)) then
        DarkRP.notify(ply, 1, 4, "Киллеры не могут заказывать убийства!")
        return
    end

    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Проверка минимальной цены
    if not price or price < 2000 then
        DarkRP.notify(ply, 1, 4, "Минимальная цена заказа 2000!")
        return
    end

    -- Логика перебивания заказа (Outbidding)
    if ZGrad_Hitman and ZGrad_Hitman.ActiveHits then
        local existingHit = ZGrad_Hitman.ActiveHits[target:SteamID()]
        if existingHit then
            if existingHit.price >= price then
                DarkRP.notify(ply, 1, 4, "На этого игрока уже есть заказ на сумму " .. DarkRP.formatMoney(existingHit.price) .. ". Вы должны предложить больше!")
                return
            end
            -- Если цена выше, уведомляем, что заказ перебит
            DarkRP.notify(ply, 0, 4, "Вы перебили предыдущий заказ на этого игрока!")
        end
    end

    -- Проверка на деньги (DarkRP)
    if not ply:canAfford(price) then
        DarkRP.notify(ply, 1, 4, "У вас недостаточно денег!")
        return
    end

    ply:addMoney(-price)
    DarkRP.notify(ply, 0, 4, "Заказ на " .. target:Nick() .. " оформлен за " .. DarkRP.formatMoney(price) .. "!")

    -- Регистрируем заказ в общей системе Hitman (чтобы работала выплата и список заказов)
    if ZGrad_Hitman and ZGrad_Hitman.ActiveHits then
        ZGrad_Hitman.ActiveHits[target:SteamID()] = {
            targetName = target:Nick(),
            price = price,
            customer = ply:SteamID()
        }
        
        -- Если есть функция обновления списка у всех киллеров
        local function BroadcastHits()
            net.Start("ZGrad_HitUpdate")
            net.WriteTable(ZGrad_Hitman.ActiveHits)
            local hitmen = {}
            for _, p in ipairs(player.GetAll()) do
                if ZGrad_Hitman.IsHitman(p) then table.insert(hitmen, p) end
            end
            if #hitmen > 0 then net.Send(hitmen) end
        end
        BroadcastHits()
    end

    -- Ищем киллеров на сервере и отправляем им уведомление
    for _, v in ipairs(player.GetAll()) do
        -- Используем правильное название команды (TEAM_KILLER) или вспомогательную функцию
        if v:Team() == TEAM_KILLER or (ZGrad_Hitman and ZGrad_Hitman.IsHitman and ZGrad_Hitman.IsHitman(v)) then 
            net.Start("ZGrad_SendHitToKiller")
            net.WriteEntity(target) -- Передаем киллеру жертву
            net.WriteEntity(ply)    -- Передаем киллеру заказчика
            net.WriteInt(price, 32) -- Передаем цену
            net.Send(v)
        end
    end
end)
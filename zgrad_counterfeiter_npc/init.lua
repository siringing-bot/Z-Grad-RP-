--[[---------------------------------------------------------------------------
    Zgrad — НПС "Фальшивомонетчик"
    Продаёт: Чернила (300$), Бумага (100$), Канистра (150$)
    Открывает магазин при нажатии E
---------------------------------------------------------------------------]]
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("ZGrad_CounterfeiterShop")
util.AddNetworkString("ZGrad_CounterfeiterBuy")

local SHOP_ITEMS = {
    {
        name    = "Чернила",
        ent     = "zgrad_ink_item",
        model   = "models/props_junk/plasticbucket001a.mdl",
        price   = 300,
        desc    = "20 единиц чернил для принтера"
    },
    {
        name    = "Бумага",
        ent     = "zgrad_paper_item",
        model   = "models/props_junk/garbage_newspaper001a.mdl",
        price   = 100,
        desc    = "10 листов бумаги для принтера"
    },
    {
        name    = "Канистра бензина",
        ent     = "zgrad_gascan",
        model   = "models/props_junk/gascan001a.mdl",
        price   = 150,
        desc    = "1 литр бензина для генератора"
    },
    {
        name    = "Hyper Injector",
        ent     = "zgrad_upgrade_speed",
        model   = "models/props_lab/reciever01d.mdl",
        price   = 2000,
        desc    = "Увеличение скорости печати в 2 раза"
    },
    {
        name    = "Large Storage Module",
        ent     = "zgrad_upgrade_storage",
        model   = "models/props_lab/reciever01b.mdl",
        price   = 2000,
        desc    = "Увеличение хранилища ресурсов в 2 раза"
    },
    {
        name    = "Production Boost",
        ent     = "zgrad_upgrade_boost",
        model   = "models/props_lab/reciever01a.mdl",
        price   = 2000,
        desc    = "Увеличение прибыли в 2 раза"
    },
}

function ENT:Initialize()
    self:SetModel("models/kennet/dealer_07.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_IDLE)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE)
    self:CapabilitiesAdd(CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetMaxYawSpeed(90)
    self:SetAutomaticFrameAdvance(true)

    local seq = self:LookupSequence("idle_all_01")
    if seq == -1 then seq = self:LookupSequence("idle") end
    if seq ~= -1 then self:SetSequence(seq) end
    
    -- Force collision refresh
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
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
    if name ~= "Use" then return end
    
    local ply = IsValid(caller) and caller:IsPlayer() and caller or activator
    if not IsValid(ply) or not ply:IsPlayer() then return end

    print("[Counterfeiter] AcceptInput 'Use' from " .. ply:Nick())
    self:OpenShop(ply)
end

function ENT:Use(activator, caller)
    local ply = IsValid(activator) and activator:IsPlayer() and activator or caller
    if not IsValid(ply) or not ply:IsPlayer() then return end

    print("[Counterfeiter] ENT:Use from " .. ply:Nick())
    self:OpenShop(ply)
end

function ENT:OpenShop(ply)
    -- Смотрит на игрока
    local dir = (ply:GetPos() - self:GetPos()):Angle()
    self:SetAngles(Angle(0, dir.y, 0))

    net.Start("ZGrad_CounterfeiterShop")
        net.WriteEntity(self)
        -- Отправляем список товаров
        net.WriteInt(#SHOP_ITEMS, 8)
        for _, item in ipairs(SHOP_ITEMS) do
            net.WriteString(item.name)
            net.WriteString(item.ent)
            net.WriteInt(item.price, 32)
            net.WriteString(item.desc)
            net.WriteString(item.model)
        end
        net.WriteInt(ply:getDarkRPVar("money") or 0, 32)
    net.Send(ply)
end

net.Receive("ZGrad_CounterfeiterBuy", function(len, ply)
    local npc   = net.ReadEntity()
    local entCls = net.ReadString()

    if not IsValid(npc) or npc:GetClass() ~= "zgrad_counterfeiter_npc" then return end

    -- Найти предмет
    local item = nil
    for _, v in ipairs(SHOP_ITEMS) do
        if v.ent == entCls then item = v break end
    end
    if not item then return end

    -- Проверка лимита (Макс 2 предмета одного вида от NPC)
    local canBuy, count = ZGrad_Utility.CheckNpcLimit(ply, item.ent)
    if not canBuy then
        DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете иметь больше 2-х " .. item.name .. " от торговца.")
        return
    end

    -- Списываем деньги
    ply:addMoney(-item.price)
    
    -- Спавним entity перед игроком
    local spawnPos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 10)
    local ent = ents.Create(item.ent)
    if IsValid(ent) then
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:Activate()
        
        -- Помечаем как товар от НПС
        ent.ZGrad_NpcBought = true
        ent.ZGrad_Owner = ply
        ent.SID = ply:SteamID()

        if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
    end

    npc:EmitSound("items/ammo_pickup.wav", 70, 100)
    DarkRP.notify(ply, 0, 4, "Куплено: " .. item.name .. " за $" .. item.price)
end)

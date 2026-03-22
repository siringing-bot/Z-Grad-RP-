AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("ZGrad_Meth_ScientistShop")
util.AddNetworkString("ZGrad_Meth_BuyIngredient")

function ENT:Initialize()
    self:SetModel("models/player/hostage/hostage_01.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_IDLE)
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
        net.Start("ZGrad_Meth_ScientistShop")
        net.Send(caller)
    end
end

-- Buy ingredient handler
net.Receive("ZGrad_Meth_BuyIngredient", function(len, ply)
    local ingredientID = net.ReadString()
    
    if not ZGRAD_METH or not ZGRAD_METH.Ingredients[ingredientID] then
        DarkRP.notify(ply, 1, 4, "Ошибка: неизвестный ингредиент!")
        return
    end
    
    local data = ZGRAD_METH.Ingredients[ingredientID]
    
    -- Check money
    if not ply:canAfford(data.price) then
        DarkRP.notify(ply, 1, 4, "У вас недостаточно средств!")
        return
    end
    
    -- Проверка лимита (Макс 2 предмета одного вида от NPC)
    local canBuy, count = ZGrad_Utility.CheckNpcLimit(ply, "zgrad_meth_ingredient", ingredientID)
    if not canBuy then
        DarkRP.notify(ply, 1, 4, "Лимит! Вы не можете иметь больше 2-х " .. data.name .. " от Ученого.")
        return
    end

    -- Take money
    ply:addMoney(-data.price)
    
    -- Spawn ingredient in front of player
    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 60
    trace.filter = ply
    local tr = util.TraceLine(trace)
    
    local ent = ents.Create("zgrad_meth_ingredient")
    if IsValid(ent) then
        ent:SetPos(tr.HitPos + tr.HitNormal * 10)
        ent:Spawn()
        ent:SetIngredient(ingredientID, data.grams)
        
        -- Помечаем как товар от НПС
        ent.ZGrad_NpcBought = true
        ent.ZGrad_NpcSubType = ingredientID -- Указываем ID ингредиента как подтип
        ent.ZGrad_Owner = ply
        ent.SID = ply:SteamID()
    end
    
    DarkRP.notify(ply, 0, 4, "Вы купили " .. data.name .. " за " .. DarkRP.formatMoney(data.price))
    ply:EmitSound("items/ammo_pickup.wav")
end)

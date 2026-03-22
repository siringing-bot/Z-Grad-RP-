AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/player/Group03/male_01.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_IDLE)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE)
    self:CapabilitiesAdd(CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetMaxYawSpeed(90)
    self:SetTrigger(true)

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

-- When meth touches the buyer NPC, buy it
function ENT:StartTouch(other)
    if not IsValid(other) then return end
    if other:GetClass() ~= "zgrad_meth_product" then return end
    
    local methType = other:GetMethType()
    local grams = other:GetGrams()
    local quality = other:GetQuality()
    
    if methType == "" or grams <= 0 then return end
    
    -- Calculate price
    local pricePerGram = 0
    local methName = "Метамфетамин"
    
    if ZGRAD_METH and ZGRAD_METH.Recipes[methType] then
        pricePerGram = ZGRAD_METH.Recipes[methType].pricePerGram
        methName = ZGRAD_METH.Recipes[methType].name
    end
    
    -- Quality affects price: -1% per quality point lost
    local qualityMultiplier = quality / 100
    local totalPrice = math.floor(pricePerGram * grams * qualityMultiplier)
    
    -- Find closest player (the one who dropped it)
    local closestPly = nil
    local closestDist = 500 -- max distance to receive payment
    
    for _, ply in ipairs(player.GetAll()) do
        local dist = ply:GetPos():Distance(self:GetPos())
        if dist < closestDist then
            closestDist = dist
            closestPly = ply
        end
    end
    
    if IsValid(closestPly) then
        closestPly:addMoney(totalPrice)
        DarkRP.notify(closestPly, 0, 4, "Продано " .. grams .. "г " .. methName .. " (Качество: " .. quality .. "%) за " .. DarkRP.formatMoney(totalPrice))
        closestPly:EmitSound("ambient/levels/canals/windchime2.wav", 60)
    end
    
    -- Play transaction sound
    self:EmitSound("items/ammo_pickup.wav", 70)
    
    -- Remove the meth
    other:Remove()
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(caller) and caller:IsPlayer() then
        DarkRP.notify(caller, 0, 4, "Бросьте мет на скупщика для продажи.")
    end
end

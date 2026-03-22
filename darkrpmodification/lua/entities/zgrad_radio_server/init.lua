AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetWaveName("Новая волна")
    self:SetWavePrice(0)
    self:SetIsMicConnected(false)
    
    local owner = self:Getowning_ent()
    if IsValid(owner) then
        self.SID = owner:SteamID()
    end

    -- Регистрация в глобальной таблице
    local idx = self:EntIndex()
    ZGrad_Radio.Waves[idx] = {
        name = self:GetWaveName(),
        price = 0,
        owner = self:Getowning_ent(),
        mic = nil
    }
end

function ENT:Think()
    -- Поиск ближайшего микрофона (10 метров = 393 юнита)
    local foundMic = nil
    for _, mic in ipairs(ents.FindByClass("zgrad_radio_mic")) do
        if mic:GetPos():DistToSqr(self:GetPos()) <= (393 * 393) then
            foundMic = mic
            break -- Только 1 микрофон
        end
    end

    self:SetIsMicConnected(IsValid(foundMic))
    
    local idx = self:EntIndex()
    if ZGrad_Radio.Waves[idx] then
        local owner = self:Getowning_ent()
        if IsValid(owner) then
            self.SID = owner:SteamID()
        end
        
        ZGrad_Radio.Waves[idx].mic = foundMic
        ZGrad_Radio.Waves[idx].owner = owner
    end

    self:NextThink(CurTime() + 1)
    return true
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    
    local owner = self:Getowning_ent()
    local isOwner = (IsValid(owner) and owner == caller) or (self.SID == caller:SteamID())
    
    if not isOwner and not caller:IsSuperAdmin() then 
        DarkRP.notify(caller, 1, 4, "Только владелец может настраивать сервер!")
        return 
    end

    net.Start("ZGrad_Radio_OpenServerMenu")
        net.WriteEntity(self)
    net.Send(caller)
end

function ENT:OnRemove()
    ZGrad_Radio.Waves[self:EntIndex()] = nil
end

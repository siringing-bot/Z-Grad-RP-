AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/SuitCase_Passenger_Physics.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if not ZGrad_Utility.IsCriminal(activator) then
        DarkRP.notify(activator, 1, 4, "Только криминальные деятели могут использовать это!")
        return
    end

    if ZGrad_Masking and ZGrad_Masking.ApplyMask then
        ZGrad_Masking.ApplyMask(activator, self)
    end
end

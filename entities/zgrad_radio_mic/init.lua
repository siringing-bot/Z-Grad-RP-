AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/ivancorn/microphone_hyperx_s_gaming.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetIsOn(false)
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    
    local newState = not self:GetIsOn()
    self:SetIsOn(newState)

    if newState then
        self:EmitSound("buttons/button1.wav", 60, 100)
    else
        self:EmitSound("buttons/button8.wav", 60, 100)
    end
    
    DarkRP.notify(caller, 0, 3, "Микрофон: " .. (newState and "ВКЛ" or "ВЫКЛ"))
end

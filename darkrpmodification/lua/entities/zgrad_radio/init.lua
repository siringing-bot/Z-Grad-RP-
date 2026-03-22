AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/cs_office/radio.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetIsOn(false)
    self:SetStationIndex(0)
    self.PaidPlayers = {}
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end

    -- Отправляем список активных волн
    local activeWaves = {}
    for serverIdx, wave in pairs(ZGrad_Radio.Waves) do
        if IsValid(ents.GetByIndex(serverIdx)) then
            activeWaves[serverIdx] = {
                name = wave.name or "Неизвестная станция",
                price = wave.price or 0
            }
        end
    end

    net.Start("ZGrad_Radio_OpenRadioMenu")
        net.WriteEntity(self)
        net.WriteTable(activeWaves)
    net.Send(caller)
end

function ENT:OnRemove()
    -- Остановка звуков если будут
end

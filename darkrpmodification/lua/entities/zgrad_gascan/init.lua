AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/gascan001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetFuelAmount(1.0) -- 1 литр
    self.IsLeaking = false
end

function ENT:OnTakeDamage(dmginfo)
    if self.IsLeaking then return end
    
    local dmgType = dmginfo:GetDamageType()
    -- Если попали пулей или чем-то острым
    if dmgType == DMG_BULLET or dmgType == DMG_CLUB or dmgType == DMG_SLASH then
        self:StartLeaking()
    end
end

function ENT:StartLeaking()
    if self.IsLeaking then return end
    self.IsLeaking = true

    -- Звук пробития
    self:EmitSound("ambient/water/drip" .. math.random(1, 4) .. ".wav", 75, 100)
    
    local timerName = "GascanLeak_" .. self:EntIndex()
    timer.Create(timerName, 0.5, 0, function()
        if not IsValid(self) then
            timer.Remove(timerName)
            return
        end

        local current = self:GetFuelAmount()
        if current <= 0 then
            self:SetFuelAmount(0)
            self.IsLeaking = false
            timer.Remove(timerName)
            return
        end

        -- Уменьшаем на 0.05 литра каждые 0.5 сек (полный литр за 10 сек)
        local amount = 0.05
        self:SetFuelAmount(math.max(0, current - amount))

        -- Эффект вытекания (визуальный)
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetNormal(self:GetUp() * -1)
        util.Effect("WaterSurfaceExplosion", effectdata) -- Небольшой всплеск/брызги
        
        if math.random(1, 4) == 1 then
            self:EmitSound("ambient/water/drip" .. math.random(1, 4) .. ".wav", 60, 100)
        end
    end)
end

function ENT:OnRemove()
    timer.Remove("GascanLeak_" .. self:EntIndex())
end

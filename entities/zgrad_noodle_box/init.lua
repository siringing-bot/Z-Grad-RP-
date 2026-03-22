AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/props_junk/garbage_takeoutcarton001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    local state = self:GetFoodState()
    
    if state == 0 then
        -- Сырая, есть нельзя
        DarkRP.notify(activator, 1, 4, "Эта лапша еще сырая! Ее нужно приготовить в микроволновке.")
        return
    end
    
    if state == 1 then
        -- Готовая
        local energy = activator:getDarkRPVar("energy") or 100
        activator:setDarkRPVar("energy", math.Clamp(energy + 30, 0, 100))
        DarkRP.notify(activator, 0, 4, "Вы съели вкусную горячую лапшу!")
        
        -- Homigrad Satiety
        if activator.organism then
            activator.organism.satiety = math.min((activator.organism.satiety or 0) + 20, 100)
            
            -- Poison effect
            if self.IsPoisonedTubik and hg.organism.module.tuberculosis then
                hg.organism.module.tuberculosis.InfectPlayer(activator)
            end
            if self.IsPoisonedRicin and hg.organism.module.ricin then
                hg.organism.module.ricin.InfectPlayer(activator, "food")
            end
        end
        
        -- Звук еды
        activator:EmitSound("npc/barnacle/barnacle_crunch2.wav", 60, 100)
        
        self:Remove()
    elseif state == 2 then
        -- Сгоревшая
        DarkRP.notify(activator, 1, 4, "Фу, какая гадость! Лапша сгорела.")
        
        -- Звук еды
        activator:EmitSound("npc/barnacle/barnacle_crunch2.wav", 60, 80)
        
        self:Remove()
    end
end

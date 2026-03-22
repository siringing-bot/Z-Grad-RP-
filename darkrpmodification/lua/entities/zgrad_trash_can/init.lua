AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/TrashDumpster01a.mdl") -- Green dumpster
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false) -- Make static
    end
    
    self.RewardAmount = 100
end

-- Function to find who 'owns' the dragging action
local function FindRagdollOwner(ragdoll)
    -- 1. Check if being held by Physgun
    if ragdoll:IsPlayerHolding() then
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetActiveWeapon() and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_physgun" then
                 -- Simplified check. Ideally we trace.
                if ply:GetEyeTrace().Entity == ragdoll then
                    return ply
                end
            end
        end
    end

    -- 2. Fallback: Closest player within short distance
    local closestPly = nil
    local minDst = 200^2 -- 200 units squared
    
    for _, ply in ipairs(player.GetAll()) do
        local dst = ply:GetPos():DistToSqr(ragdoll:GetPos())
        if dst < minDst then
            minDst = dst
            closestPly = ply
        end
    end
    
    return closestPly
end

function ENT:StartTouch(ent)
    if not IsValid(ent) then return end
    
    -- Must be a ragdoll
    if ent:GetClass() ~= "prop_ragdoll" then return end

    -- Helper to find player associated with ragdoll
    local function GetRagdollPlayer(e)
        -- 1. Try DarkRP standard
        if CORPSE and CORPSE.GetPlayer then
            local ply = CORPSE.GetPlayer(e)
            if IsValid(ply) then return ply end
        end
        
        -- 2. Try Owner property (common in many scripts)
        if IsValid(e.Owner) and e.Owner:IsPlayer() then return e.Owner end
        if IsValid(e:GetOwner()) and e:GetOwner():IsPlayer() then return e:GetOwner() end
        
        -- 3. Try networking (some knockout scripts use this)
        if e.GetRagdollPlayer then 
             local ply = e:GetRagdollPlayer()
             if IsValid(ply) then return ply end
        end
        
        return nil
    end

    local ply = GetRagdollPlayer(ent)
    
    -- Check if IT IS A LIVING PLAYER
    if IsValid(ply) and ply:Alive() then
        -- It's a living player (knocked out, etc). DO NOT EAT.
        -- BUT only if it's their current active fake ragdoll!
        -- If they respawned, their old corpse should still be eaten.
        if ply:GetNWEntity("FakeRagdoll") == ent then
            return
        end
    end

    -- If we fell through here:
    -- 1. It's a dead player's corpse.
    -- 2. It's a generic ragdoll prop (no player found).
    -- In both cases, we eat it.
    
    -- Reward Logic
    local benefactor = FindRagdollOwner(ent)
    
    if IsValid(benefactor) and benefactor:IsPlayer() then
        benefactor:addMoney(self.RewardAmount)
        DarkRP.notify(benefactor, 0, 4, "Вы получили $" .. self.RewardAmount .. " за утилизацию тела.")
        benefactor:EmitSound("mvm/mvm_money_pickup.wav")
    end
    
    -- Effect
    local effectdata = EffectData()
    effectdata:SetOrigin(ent:GetPos())
    util.Effect("bloodspray", effectdata)
    
    self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav")
    
    -- Remove Body
    ent:Remove()
end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Маленький ящик"
ENT.Author = "Z-Grad"
ENT.Spawnable = true
ENT.Category = "Z-Grad Ящики"

function ENT:isKeysOwnable() return true end
function ENT:getKeysNonOwnable() return false end
function ENT:isKeysOwnedBy(ply)
    local owner = self:GetNW2Entity("owner")
    if IsValid(owner) and owner == ply then return true end
    if self.Getowning_ent and self:Getowning_ent() == ply then return true end
    return false
end

function ENT:isKeysLocked()
    return self:GetNWBool("locked", false)
end

function ENT:lock()
    self:SetNWBool("locked", true)
end

function ENT:unlock()
    self:SetNWBool("locked", false)
end

function ENT:isDoor() return true end

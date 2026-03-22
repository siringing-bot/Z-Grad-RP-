ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Газовая плита"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Meth"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsActive") -- stove has a pot cooking on it
end

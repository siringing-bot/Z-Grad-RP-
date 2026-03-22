ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Микрофон"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Radio"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsOn")
end

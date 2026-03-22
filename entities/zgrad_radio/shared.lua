ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Радио"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Radio"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsOn")
    self:NetworkVar("Int", 0, "StationIndex") -- Index of the server entity
end

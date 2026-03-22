ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Канистра с бензином"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Mafia"

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "FuelAmount") -- литров в канистре
end

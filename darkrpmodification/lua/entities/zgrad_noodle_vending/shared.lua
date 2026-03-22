ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Торговый автомат с лапшой"
ENT.Author = "Z-Grad"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "NoodleCount")
    self:NetworkVar("Int", 1, "NoodlePrice")
end

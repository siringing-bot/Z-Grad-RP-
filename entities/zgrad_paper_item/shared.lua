ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Бумага"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Mafia"

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "PaperAmount") -- количество бумаги в пачке
end

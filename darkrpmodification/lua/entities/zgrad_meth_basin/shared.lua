ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Тазик для смешивания"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Meth"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ContentsDisplay")
    self:NetworkVar("Int", 0, "CurrentStep")
    self:NetworkVar("Bool", 0, "IsReady")
end

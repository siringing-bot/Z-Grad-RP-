ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Метамфетамин"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "Z-Grad Meth"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "MethType")    -- meth, blue_meth, red_meth
    self:NetworkVar("Int", 0, "Grams")
    self:NetworkVar("Int", 1, "Quality")         -- 0-100%
end

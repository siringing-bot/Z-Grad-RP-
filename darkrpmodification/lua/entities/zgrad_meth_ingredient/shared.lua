ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ингредиент"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "IngredientID")
    self:NetworkVar("Int", 0, "Grams")
end

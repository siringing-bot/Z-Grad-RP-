ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Лапша"
ENT.Author = "Z-Grad"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "FoodState") -- 0 = Сырая, 1 = Готовая, 2 = Сгоревшая
end

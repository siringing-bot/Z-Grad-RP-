ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Выдача снаряжения"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true -- Нужно для анимаций

function ENT:SetAutomaticFrameAdvance(bUsingAnim)
    self.AutomaticFrameAdvance = bUsingAnim
end

ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Наемный убийца (NPC)"
ENT.Author = "Z-Grad"
ENT.Spawnable = true
ENT.AdminOnly = false -- Если хочешь, чтобы спавнили только админы, поставь true
ENT.Category = "Z-Grad RP"

-- Включаем анимации, чтобы NPC "дышал"
ENT.AutomaticFrameAdvance = true 

function ENT:SetAutomaticFrameAdvance(b)
    self.AutomaticFrameAdvance = b
end
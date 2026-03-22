ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Ученый (Покупка крови)"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

function ENT:SetAutomaticFrameAdvance(bUsingAnim)
    self.AutomaticFrameAdvance = bUsingAnim
end

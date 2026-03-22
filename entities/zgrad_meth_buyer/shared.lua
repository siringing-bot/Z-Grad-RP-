ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Скупщик мета"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

function ENT:SetAutomaticFrameAdvance(bUsingAnim)
    self.AutomaticFrameAdvance = bUsingAnim
end

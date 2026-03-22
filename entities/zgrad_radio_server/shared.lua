ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Радио Сервер"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Radio"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "WaveName")
    self:NetworkVar("Int", 0, "WavePrice")
    self:NetworkVar("Bool", 0, "IsMicConnected")
end

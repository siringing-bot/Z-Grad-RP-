ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Генератор"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Mafia"

function ENT:SetupDataTables()
    self:NetworkVar("Bool",  0, "IsOn")          -- Включён
    self:NetworkVar("Float", 0, "Fuel")          -- Топливо (0.0 - 5.0 литров)
    self:NetworkVar("Int",   0, "PoweredPrinters") -- Сколько принтеров запитано
end

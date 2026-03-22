ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Манипринтер"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Mafia"

function ENT:SetupDataTables()
    self:NetworkVar("Bool",   0, "IsOn")       -- Включён/выключен
    self:NetworkVar("Int",    0, "Paper")       -- Кол-во бумаги (0-20)
    self:NetworkVar("Int",    1, "Ink")         -- Кол-во чернил (0-40)
    self:NetworkVar("Bool",   1, "HasPower")    -- Есть энергия
    self:NetworkVar("Int",    2, "Money")       -- Накопленные деньги

    -- Улучшения
    self:NetworkVar("Bool",   2, "HasUpgradeSpeed")   -- Hyper Injector
    self:NetworkVar("Bool",   3, "HasUpgradeStorage") -- Large Storage
    self:NetworkVar("Bool",   4, "HasUpgradeBoost")   -- Production Boost
end

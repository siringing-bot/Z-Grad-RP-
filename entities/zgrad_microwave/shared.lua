ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Микроволновка"
ENT.Author = "Z-Grad"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "HasFood")
    self:NetworkVar("Bool", 1, "IsCooking")
    self:NetworkVar("Bool", 2, "IsBurned")
    self:NetworkVar("Float", 0, "CookEndTime")
    self:NetworkVar("Float", 1, "BurnEndTime")
end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Кастрюля"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Z-Grad Meth"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ContentsDisplay") -- display string of contents
    self:NetworkVar("Int", 0, "CurrentStep")        -- current recipe step index
    self:NetworkVar("String", 1, "SelectedRecipe")  -- selected recipe id
    self:NetworkVar("Bool", 0, "IsCooking")         -- is currently on stove
    self:NetworkVar("Float", 0, "CookEndTime")      -- when cooking ends
    self:NetworkVar("Int", 1, "CookQuality")        -- current quality
    self:NetworkVar("Bool", 1, "IsReady")           -- cooking done, waiting for pickup
end

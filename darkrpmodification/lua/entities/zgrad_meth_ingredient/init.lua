AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/jar01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:SetIngredient(ingredientID, grams)
    self:SetIngredientID(ingredientID)
    self:SetGrams(grams or 0)
    
    if ZGRAD_METH and ZGRAD_METH.Ingredients[ingredientID] then
        local data = ZGRAD_METH.Ingredients[ingredientID]
        self:SetModel(data.model)
        self:SetGrams(grams or data.grams)
    end
end

-- Stacking: when touching another ingredient of same type
function ENT:StartTouch(other)
    if not IsValid(other) then return end
    if other:GetClass() ~= "zgrad_meth_ingredient" then return end
    if other:GetIngredientID() ~= self:GetIngredientID() then return end
    if self.ZGrad_Merging or other.ZGrad_Merging then return end
    
    -- Merge into this one
    other.ZGrad_Merging = true
    self:SetGrams(self:GetGrams() + other:GetGrams())
    other:Remove()
end

function ENT:Use(activator, caller)
    -- Picking up ingredient
    if IsValid(caller) and caller:IsPlayer() then
        -- Nothing special on use for ingredients
    end
end

function ENT:OnRemove()
end

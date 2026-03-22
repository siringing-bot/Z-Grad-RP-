AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/garbage_bag001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetQuality(100)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:SetMethData(methType, grams, quality)
    self:SetMethType(methType)
    self:SetGrams(grams)
    self:SetQuality(quality or 100)
    
    -- Set color based on meth type
    if methType == "blue_meth" then
        self:SetColor(Color(100, 180, 255))
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    elseif methType == "red_meth" then
        self:SetColor(Color(255, 80, 80))
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    end
    -- Normal meth: default color (no change)
end

-- Use = consume the meth
function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    
    local methType = self:GetMethType()
    local grams = self:GetGrams()
    local quality = self:GetQuality()
    
    if methType == "" then return end
    
    -- Apply the drug effect
    if ZGRAD_METH and ZGRAD_METH.ApplyEffect then
        ZGRAD_METH.ApplyEffect(caller, methType, grams, quality)
    end
    
    local recipeName = "Метамфетамин"
    if ZGRAD_METH and ZGRAD_METH.Recipes[methType] then
        recipeName = ZGRAD_METH.Recipes[methType].name
    end
    
    DarkRP.notify(caller, 0, 4, "Вы употребили " .. recipeName .. " (" .. grams .. "г, " .. quality .. "%)")
    
    caller:EmitSound("npc/barnacle/barnacle_crunch2.wav", 50)
    self:Remove()
end

-- Stacking: when touching another meth of same type
function ENT:StartTouch(other)
    if not IsValid(other) then return end
    if other:GetClass() ~= "zgrad_meth_product" then return end
    if other:GetMethType() ~= self:GetMethType() then return end
    if self.ZGrad_Merging or other.ZGrad_Merging then return end
    
    -- Only merge if same quality (or average it)
    other.ZGrad_Merging = true
    local totalGrams = self:GetGrams() + other:GetGrams()
    local avgQuality = math.floor((self:GetQuality() * self:GetGrams() + other:GetQuality() * other:GetGrams()) / totalGrams)
    self:SetGrams(totalGrams)
    self:SetQuality(avgQuality)
    other:Remove()
end

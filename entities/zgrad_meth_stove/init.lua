AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/furnitureStove001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetIsActive(false)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false) -- Stove stays in place
    end
end

-- Find a ready pot nearby
function ENT:FindNearbyPot()
    local nearbyEnts = ents.FindInSphere(self:GetPos(), 100)
    for _, ent in ipairs(nearbyEnts) do
        if IsValid(ent) and ent:GetClass() == "zgrad_meth_pot" then
            if not ent:GetIsCooking() then
                local recipeID = ent:GetSelectedRecipe()
                if recipeID ~= "" then
                    local recipe = ZGRAD_METH and ZGRAD_METH.Recipes[recipeID]
                    if recipe and ent.ContentsList and #ent.ContentsList >= #recipe.steps then
                        return ent
                    end
                end
            end
        end
    end
    return nil
end

-- Place pot on stove
function ENT:PlacePot(pot)
    if not IsValid(pot) then return false end
    if self:GetIsActive() then return false end
    
    -- Snap pot to burner position (top of stove)
    local stovePos = self:GetPos()
    local stoveAng = self:GetAngles()
    -- Position on top of the stove model
    local burnerOffset = Vector(0, 0, 40)
    
    pot:SetPos(stovePos + burnerOffset)
    pot:SetAngles(Angle(0, stoveAng.y, 0))
    
    -- Disable pot physics so it stays on the stove
    local phys = pot:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
    
    -- Start cooking
    local success = pot:StartCooking(self)
    if success then
        self:SetIsActive(true)
        self.CookingPot = pot
        self:EmitSound("ambient/fire/fire_small1.wav", 60)
        return true
    end
    
    return false
end

-- Player presses E on stove -> place nearby pot or show status
function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    
    if self:GetIsActive() then
        DarkRP.notify(caller, 0, 4, "Плита уже работает! Дождитесь окончания варки.")
        return
    end
    
    -- Look for ready pot nearby
    local pot = self:FindNearbyPot()
    if IsValid(pot) then
        local success = self:PlacePot(pot)
        if success then
            DarkRP.notify(caller, 0, 4, "Кастрюля поставлена на плиту! Варка началась.")
        else
            DarkRP.notify(caller, 1, 4, "Не удалось начать варку!")
        end
    else
        DarkRP.notify(caller, 1, 4, "Поставьте кастрюлю с ингредиентами рядом с плитой и нажмите E.")
    end
end

function ENT:Think()
    -- Auto-detect: check if a pot landed on top of the stove
    if not self:GetIsActive() then
        if not self.LastProximityCheck or CurTime() - self.LastProximityCheck >= 1 then
            self.LastProximityCheck = CurTime()
            
            -- Check for pots very close to the top of the stove
            local topPos = self:GetPos() + Vector(0, 0, 35)
            local nearbyEnts = ents.FindInSphere(topPos, 30)
            for _, ent in ipairs(nearbyEnts) do
                if IsValid(ent) and ent:GetClass() == "zgrad_meth_pot" and not ent:GetIsCooking() then
                    local recipeID = ent:GetSelectedRecipe()
                    if recipeID ~= "" then
                        local recipe = ZGRAD_METH and ZGRAD_METH.Recipes[recipeID]
                        if recipe and ent.ContentsList and #ent.ContentsList >= #recipe.steps then
                            self:PlacePot(ent)
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Monitor active cooking pot
    if self:GetIsActive() then
        if IsValid(self.CookingPot) then
            if not self.CookingPot:GetIsCooking() then
                self:SetIsActive(false)
                self.CookingPot = nil
            end
        else
            self:SetIsActive(false)
            self.CookingPot = nil
        end
    end
    
    self:NextThink(CurTime() + 0.5)
    return true
end

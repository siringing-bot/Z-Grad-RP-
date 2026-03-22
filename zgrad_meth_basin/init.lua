AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/MetalBucket02a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetTrigger(true)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    self.Contents = {}
    self.ContentsList = {}
    self:SetCurrentStep(0)
    self:SetContentsDisplay("")
    self:SetIsReady(false)
end

function ENT:UpdateDisplay()
    local display = ""
    for _, entry in ipairs(self.ContentsList) do
        local name = entry.id
        if ZGRAD_METH and ZGRAD_METH.Ingredients[entry.id] then
            name = ZGRAD_METH.Ingredients[entry.id].name
        elseif entry.methType then
            if ZGRAD_METH and ZGRAD_METH.Recipes[entry.methType] then
                name = ZGRAD_METH.Recipes[entry.methType].name
            end
        end
        if display ~= "" then display = display .. "\n" end
        display = display .. name .. "(" .. entry.grams .. "г)"
    end
    self:SetContentsDisplay(display)
end

function ENT:Explode()
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetScale(2)
    util.Effect("Explosion", effectdata)
    util.BlastDamage(self, self, self:GetPos(), 200, 50)
    self:EmitSound("ambient/explosions/explode_4.wav", 100)
    self:Remove()
end

-- The Fury-13 recipe requires meth products and solvent
function ENT:StartTouch(other)
    if not IsValid(other) then return end
    if self:GetIsReady() then return end
    
    local fury13Recipe = ZGRAD_METH and ZGRAD_METH.Recipes["fury13"]
    if not fury13Recipe then return end
    
    local isProduct = other:GetClass() == "zgrad_meth_product"
    local isIngredient = other:GetClass() == "zgrad_meth_ingredient"
    
    if not isProduct and not isIngredient then return end

    -- Find which step this item could potentially fill
    local foundStepIdx = -1
    local identifier = isProduct and "meth_product" or other:GetIngredientID()

    for i, step in ipairs(fury13Recipe.steps) do
        -- Check if this step is already filled
        local alreadyFilled = false
        for _, content in ipairs(self.ContentsList) do
            if content.stepIdx == i then
                alreadyFilled = true
                break
            end
        end

        if not alreadyFilled then
            if isProduct then
                if step.id == "meth_product" and (not step.methType or other:GetMethType() == step.methType) then
                    if other:GetGrams() >= step.grams then
                        foundStepIdx = i
                        break
                    end
                end
            else
                if step.id == identifier then
                    foundStepIdx = i
                    break
                end
            end
        end
    end

    if foundStepIdx == -1 then
        -- Explode if too many items OR wrong item for the current "free" spots
        -- If we already have items and this one doesn't fit, it might be an error
        if #self.ContentsList >= #fury13Recipe.steps then
            timer.Simple(0.5, function()
                if IsValid(self) then self:Explode() end
            end)
            return
        end
        
        -- Special feedback for low grams
        if isProduct and other:GetGrams() < 50 then
             local owner = other.Getowning_ent and other:Getowning_ent() or nil
             DarkRP.notify(owner, 1, 4, "Слишком мало грамм в пакете!")
        end
        return 
    end

    -- Add to contents
    if isProduct then
        table.insert(self.ContentsList, { id = "meth_product", grams = other:GetGrams(), methType = other:GetMethType(), stepIdx = foundStepIdx })
    else
        table.insert(self.ContentsList, { id = identifier, grams = other:GetGrams(), stepIdx = foundStepIdx })
    end
    
    other:Remove()
    
    self:SetCurrentStep(#self.ContentsList)
    self:UpdateDisplay()
    self:EmitSound("ambient/water/drip" .. math.random(1, 4) .. ".wav", 60)
    
    -- Check if recipe complete
    if #self.ContentsList >= #fury13Recipe.steps then
        self:SetIsReady(true)
        self:EmitSound("buttons/button9.wav", 60)
        
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():DistToSqr(self:GetPos()) < 250000 then
                DarkRP.notify(ply, 0, 4, "Fury-13 готов! Нажмите E на тазик.")
            end
        end
    end
end

function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    
    if self:GetIsReady() then
        -- Spawn Fury-13 weapon
        local fury = ents.Create("weapon_fury13")
        if IsValid(fury) then
            fury:SetPos(self:GetPos() + Vector(0, 0, 20))
            fury:Spawn()
        end
        
        DarkRP.notify(caller, 0, 4, "Fury-13 готов!")
        caller:EmitSound("items/ammo_pickup.wav")
        
        -- Reset basin
        self.Contents = {}
        self.ContentsList = {}
        self:SetCurrentStep(0)
        self:SetContentsDisplay("")
        self:SetIsReady(false)
    end
end

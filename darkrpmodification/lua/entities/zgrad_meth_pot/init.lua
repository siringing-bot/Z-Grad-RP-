AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/metalPot001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetTrigger(true)  -- Enable touch events
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    self.Contents = {}         -- { [ingredientID] = grams }
    self.ContentsList = {}     -- ordered list of added ingredients
    self:SetCurrentStep(0)
    self:SetSelectedRecipe("")
    self:SetContentsDisplay("")
    self:SetIsCooking(false)
    self:SetCookQuality(100)
    self:SetIsReady(false)
end

function ENT:UpdateDisplay()
    local display = ""
    for id, grams in pairs(self.Contents) do
        local name = id
        if ZGRAD_METH and ZGRAD_METH.Ingredients[id] then
            name = ZGRAD_METH.Ingredients[id].name
        end
        if display ~= "" then display = display .. "\n" end
        display = display .. name .. "(" .. grams .. "г)"
    end
    self:SetContentsDisplay(display)
end

function ENT:TryAutoDetectRecipe()
    -- Try to figure out which recipe the player is following
    if self:GetSelectedRecipe() ~= "" then return end
    
    -- We need at least 2 ingredients to distinguish between recipes
    -- since all pot recipes start with distilled_water
    if #self.ContentsList < 2 then return end
    
    local secondIngredient = self.ContentsList[2]
    
    for recipeID, recipe in pairs(ZGRAD_METH.Recipes) do
        if recipe.container == "pot" and recipe.steps[2] then
            -- Check if first AND second ingredient match
            if recipe.steps[1].id == self.ContentsList[1].id and
               recipe.steps[2].id == secondIngredient.id then
                self:SetSelectedRecipe(recipeID)
                return
            end
        end
    end
end

function ENT:Explode()
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetScale(2)
    util.Effect("Explosion", effectdata)
    
    -- Damage nearby players
    util.BlastDamage(self, self, self:GetPos(), 200, 50)
    
    self:EmitSound("ambient/explosions/explode_4.wav", 100)
    self:Remove()
end

function ENT:StartTouch(other)
    if not IsValid(other) then return end
    if self:GetIsCooking() then return end
    if self:GetIsReady() then return end
    
    -- Check if it's an ingredient
    if other:GetClass() == "zgrad_meth_ingredient" then
        local ingredientID = other:GetIngredientID()
        local grams = other:GetGrams()
        
        if ingredientID == "" or grams <= 0 then return end
        
        -- Add to contents
        self.Contents[ingredientID] = (self.Contents[ingredientID] or 0) + grams
        table.insert(self.ContentsList, { id = ingredientID, grams = grams })
        
        other:Remove()
        self:UpdateDisplay()
        
        -- Try to auto-detect recipe after first ingredient
        self:TryAutoDetectRecipe()
        
        -- Validate sequence
        local recipeID = self:GetSelectedRecipe()
        if recipeID ~= "" and ZGRAD_METH.Recipes[recipeID] then
            local recipe = ZGRAD_METH.Recipes[recipeID]
            local stepIdx = #self.ContentsList
            
            if stepIdx <= #recipe.steps then
                local expectedStep = recipe.steps[stepIdx]
                if expectedStep.id ~= ingredientID then
                    -- Wrong sequence! Explode!
                    timer.Simple(0.5, function()
                        if IsValid(self) then
                            self:Explode()
                        end
                    end)
                    return
                end
                
                -- Check if we need specific grams
                -- Allow extra grams (they just used more ingredients)
            else
                -- Too many ingredients for this recipe, explode
                timer.Simple(0.5, function()
                    if IsValid(self) then
                        self:Explode()
                    end
                end)
                return
            end
            
            self:SetCurrentStep(stepIdx)
            
            -- Check if all steps complete
            if stepIdx == #recipe.steps then
                -- All ingredients added! Ready for stove
                self:SetIsReady(false) -- not ready until cooked
                self:EmitSound("buttons/button9.wav", 60)
                
                -- Notify nearby players
                for _, ply in ipairs(player.GetAll()) do
                    if ply:GetPos():DistToSqr(self:GetPos()) < 250000 then -- ~500 units
                        DarkRP.notify(ply, 0, 4, "Все ингредиенты добавлены! Поставьте кастрюлю на плиту.")
                    end
                end
            end
        else
            -- No recipe detected yet, that's fine for first ingredient
            if #self.ContentsList > 1 and recipeID == "" then
                -- Still no recipe matched after 2+ ingredients, explode
                timer.Simple(0.5, function()
                    if IsValid(self) then
                        self:Explode()
                    end
                end)
            end
        end
        
        self:EmitSound("ambient/water/drip" .. math.random(1, 4) .. ".wav", 60)
        return
    end
    
    -- Block meth products from being added to the pot (only basin accepts them for Fury-13)
    if other:GetClass() == "zgrad_meth_product" then
        if not self.LastNotify or CurTime() - self.LastNotify > 2 then
            DarkRP.notify(other:Getowning_ent() or nil, 1, 4, "В кастрюлю нельзя ложить готовый мет! Используйте тазик.")
            self.LastNotify = CurTime()
        end
        return
    end
end

-- Use: pick up the finished product when ready
function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    
    if self:GetIsReady() then
        local recipeID = self:GetSelectedRecipe()
        if recipeID == "" then return end
        
        local recipe = ZGRAD_METH.Recipes[recipeID]
        if not recipe then return end
        
        local quality = self:GetCookQuality()
        
        -- Spawn the meth product
        local product = ents.Create("zgrad_meth_product")
        if IsValid(product) then
            product:SetPos(self:GetPos() + Vector(0, 0, 20))
            product:Spawn()
            product:SetMethData(recipeID, recipe.outputGrams, quality)
        end
        
        DarkRP.notify(caller, 0, 4, recipe.name .. " готов! Качество: " .. quality .. "%")
        caller:EmitSound("items/ammo_pickup.wav")
        
        -- Stop cooking sounds
        if self.BubbleSound then
            self.BubbleSound:Stop()
            self.BubbleSound = nil
        end
        
        -- Reset pot
        self.Contents = {}
        self.ContentsList = {}
        self:SetCurrentStep(0)
        self:SetSelectedRecipe("")
        self:SetContentsDisplay("")
        self:SetIsCooking(false)
        self:SetCookQuality(100)
        self:SetIsReady(false)
        
        -- Re-enable physics
        self:SetMoveType(MOVETYPE_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:Wake()
        end
    end
end

-- Called by the stove when pot is placed on it
function ENT:StartCooking(stove)
    local recipeID = self:GetSelectedRecipe()
    if recipeID == "" then return false end
    
    local recipe = ZGRAD_METH.Recipes[recipeID]
    if not recipe then return false end
    
    -- Check all steps are complete
    if #self.ContentsList < #recipe.steps then return false end
    
    self:SetIsCooking(true)
    self:SetCookQuality(100)
    self:SetCookEndTime(CurTime() + recipe.cookTime)
    
    -- Lock pot in place
    self:SetMoveType(MOVETYPE_NONE)
    
    -- Start bubbling sound
    self.BubbleSound = CreateSound(self, "ambient/water/water_flow_loop1.wav")
    if self.BubbleSound then
        self.BubbleSound:Play()
        self.BubbleSound:ChangeVolume(0.5)
        self.BubbleSound:ChangePitch(120)
    end
    
    return true
end

function ENT:Think()
    if not self:GetIsCooking() then return end
    
    local cookEnd = self:GetCookEndTime()
    local quality = self:GetCookQuality()
    
    if CurTime() >= cookEnd and not self:GetIsReady() then
        -- Cooking done — stop bubbling sound
        if self.BubbleSound then
            self.BubbleSound:Stop()
            self.BubbleSound = nil
        end
        
        if quality > 0 then
            self:SetIsReady(true)
            
            -- Play completion sound
            self:EmitSound("buttons/button9.wav", 75)
            
            -- Notify nearby players
            for _, ply in ipairs(player.GetAll()) do
                if ply:GetPos():DistToSqr(self:GetPos()) < 250000 then
                    DarkRP.notify(ply, 0, 4, "Варка завершена! Нажмите E на кастрюлю.")
                end
            end
        end
    end
    
    -- Quality degradation after cook time ended
    if CurTime() > cookEnd and self:GetIsReady() then
        -- Lose 1% per second after completion
        if not self.LastQualityTick or CurTime() - self.LastQualityTick >= 1 then
            self.LastQualityTick = CurTime()
            quality = quality - 1
            self:SetCookQuality(math.max(quality, 0))
            
            -- Send timer update to clients
            net.Start("ZGrad_Meth_CookingTimer")
                net.WriteUInt(self:EntIndex(), 16)
                net.WriteFloat(0) -- already done
                net.WriteString(ZGRAD_METH.Recipes[self:GetSelectedRecipe()].name or "")
                net.WriteUInt(quality, 8)
            net.Broadcast()
            
            if quality <= 0 then
                -- Quality reached 0, stove explodes
                if self.BubbleSound then
                    self.BubbleSound:Stop()
                end
                self:Explode()
                return
            end
        end
    elseif self:GetIsCooking() and not self:GetIsReady() then
        -- Send timer updates while cooking
        if not self.LastTimerUpdate or CurTime() - self.LastTimerUpdate >= 1 then
            self.LastTimerUpdate = CurTime()
            local timeLeft = math.max(0, cookEnd - CurTime())
            
            net.Start("ZGrad_Meth_CookingTimer")
                net.WriteUInt(self:EntIndex(), 16)
                net.WriteFloat(timeLeft)
                net.WriteString(ZGRAD_METH.Recipes[self:GetSelectedRecipe()].name or "")
                net.WriteUInt(quality, 8)
            net.Broadcast()
        end
    end
    
    self:NextThink(CurTime() + 0.5)
    return true
end

function ENT:OnRemove()
    if self.BubbleSound then
        self.BubbleSound:Stop()
    end
end

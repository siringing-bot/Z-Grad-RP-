--[[---------------------------------------------------------------------------
Z-Grad RP — Meth Cooking System (Server Module)
---------------------------------------------------------------------------]]

-- Network strings
util.AddNetworkString("ZGrad_Meth_ScientistShop")
util.AddNetworkString("ZGrad_Meth_BuyIngredient")
util.AddNetworkString("ZGrad_Meth_RecipeBook")
util.AddNetworkString("ZGrad_Meth_DrugEffect")
util.AddNetworkString("ZGrad_Meth_CookingTimer")

-- ============================================================
-- SHARED CONFIG (accessible from server)
-- ============================================================

ZGRAD_METH = ZGRAD_METH or {}

ZGRAD_METH.Ingredients = {
    ["red_phosphorus"]  = { name = "Красный фосфор",      grams = 50,  price = 1500, model = "models/props_lab/jar01a.mdl" },
    ["solvent"]         = { name = "Растворитель",         grams = 200, price = 400,  model = "models/props_junk/garbage_plasticbottle001a.mdl" },
    ["distilled_water"] = { name = "Дистиллированная вода",grams = 300, price = 600,  model = "models/props_junk/plasticbucket001a.mdl" },
    ["lithium"]         = { name = "Литий",                grams = 60,  price = 800,  model = "models/props_junk/garbage_metalcan001a.mdl" },
    ["pseudoephedrine"] = { name = "Псевдоэфедрин",        grams = 80,  price = 1400, model = "models/props_junk/garbage_milkcarton001a.mdl" },
    ["methylamine"]     = { name = "Метиламин",            grams = 80,  price = 1000, model = "models/props_junk/garbage_plasticbottle002a.mdl" },
    ["crimson_x"]       = { name = 'Реагент "Crimson-X"',  grams = 20,  price = 3000, model = "models/props_junk/garbage_bag001a.mdl" },
}

-- Recipes: ordered list of ingredient steps
-- Each step = { id = ingredient_id, grams = amount needed }
-- container: "pot" or "basin"
ZGRAD_METH.Recipes = {
    ["meth"] = {
        name = "Метамфетамин",
        container = "pot",
        pricePerGram = 250,
        cookTime = 60,
        outputGrams = 50,
        color = Color(255, 255, 255),
        steps = {
            { id = "distilled_water", grams = 300 },
            { id = "red_phosphorus",  grams = 50  },
            { id = "lithium",         grams = 60  },
            { id = "pseudoephedrine", grams = 80  },
            { id = "solvent",         grams = 200 },
        }
    },
    ["blue_meth"] = {
        name = "Синий Метамфетамин",
        container = "pot",
        pricePerGram = 500,
        cookTime = 120,
        outputGrams = 50,
        color = Color(0, 150, 255),
        steps = {
            { id = "distilled_water", grams = 300 },
            { id = "methylamine",     grams = 160 },
            { id = "lithium",         grams = 120 },
            { id = "red_phosphorus",  grams = 100 },
            { id = "solvent",         grams = 400 },
        }
    },
    ["red_meth"] = {
        name = "Красный Метамфетамин",
        container = "pot",
        pricePerGram = 1000,
        cookTime = 240,
        outputGrams = 50,
        color = Color(255, 50, 50),
        steps = {
            { id = "distilled_water", grams = 600 },
            { id = "lithium",         grams = 120 },
            { id = "red_phosphorus",  grams = 200 },
            { id = "crimson_x",       grams = 20  },
            { id = "solvent",         grams = 600 },
        }
    },
    ["fury13"] = {
        name = "Fury-13",
        container = "basin",
        pricePerGram = 100000, -- per syringe
        cookTime = 0, -- no cooking needed, instant mix
        outputGrams = 1, -- 1 syringe
        color = Color(255, 170, 80),
        steps = {
            { id = "meth_product",      grams = 50, methType = "meth" },
            { id = "meth_product",      grams = 50, methType = "blue_meth" },
            { id = "meth_product",      grams = 50, methType = "red_meth" },
            { id = "solvent",           grams = 800 },
        }
    },
}

-- ============================================================
-- DRUG EFFECTS (Server-Side)
-- ============================================================

-- Apply meth effect to player
function ZGRAD_METH.ApplyEffect(ply, methType, grams, quality)
    if not IsValid(ply) then return end
    
    quality = quality or 100
    local duration = grams -- 1 gram = 1 second base
    
    -- Adjust duration by quality
    duration = duration * (quality / 100)
    
    -- Poison chance for low quality meth
    if quality <= 50 then
        local poisonChance = (50 - quality) / 50 -- 0% at 50 quality, 100% at 0 quality
        if math.random() < poisonChance then
            -- Apply poison effect
            if ply.organism then
                ply.organism.poison1 = CurTime()
                ply:EmitSound("vo/npc/male01/moan0" .. math.random(1,5) .. ".wav")
            end
            DarkRP.notify(ply, 1, 4, "Вы отравились некачественным мётом!")
            return
        end
    end
    
    -- Give infinite stamina
    ply.ZGrad_MethStamina = true
    ply.ZGrad_MethEnd = CurTime() + duration
    
    if methType == "meth" then
        -- Normal meth: screen sway, infinite stamina
        net.Start("ZGrad_Meth_DrugEffect")
            net.WriteString("meth")
            net.WriteFloat(duration)
        net.Send(ply)
        
        -- Infinite stamina for Homigrad organism
        if ply.organism and ply.organism.stamina then
            ply.organism.stamina[1] = ply.organism.stamina.max or 180
        end
        
    elseif methType == "blue_meth" then
        -- Blue meth: white screen, muted audio, +5% speed, infinite stamina
        net.Start("ZGrad_Meth_DrugEffect")
            net.WriteString("blue_meth")
            net.WriteFloat(duration)
        net.Send(ply)
        
        -- Infinite stamina for Homigrad organism
        if ply.organism and ply.organism.stamina then
            ply.organism.stamina[1] = ply.organism.stamina.max or 180
        end
        
        local origSpeed = ply:GetRunSpeed()
        ply.ZGrad_OrigRunSpeed = origSpeed
        ply:SetRunSpeed(origSpeed * 1.05)
        
    elseif methType == "red_meth" then
        -- Red meth: screen effect, restore hunger, hunger immunity
        net.Start("ZGrad_Meth_DrugEffect")
            net.WriteString("red_meth")
            net.WriteFloat(duration)
        net.Send(ply)
        
        -- Restore hunger to 100
        ply:setDarkRPVar("energy", 100)
        
        -- Hunger immunity for (grams / 2) minutes
        local immunityDuration = (grams / 2) * 60
        ply.ZGrad_HungerImmune = true
        ply.ZGrad_HungerImmuneEnd = CurTime() + immunityDuration
        ply:setDarkRPVar("hungerImmuneEnd", ply.ZGrad_HungerImmuneEnd)
        
    elseif methType == "fury13" then
        -- Fury-13: +2 berserk, 30 min hunger immunity, +5% speed
        if ply.organism then
            ply.organism.berserk = (ply.organism.berserk or 0) + 2
        end
        
        -- Hunger immunity for 30 minutes
        ply.ZGrad_HungerImmune = true
        ply.ZGrad_HungerImmuneEnd = CurTime() + (30 * 60)
        ply:setDarkRPVar("hungerImmuneEnd", ply.ZGrad_HungerImmuneEnd)
        
        -- Speed boost
        local origSpeed = ply:GetRunSpeed()
        ply.ZGrad_OrigRunSpeed = origSpeed
        ply:SetRunSpeed(origSpeed * 1.05)
        
        -- Duration for stamina
        duration = 120 -- 2 minutes for fury
        
        -- Send screen effect
        net.Start("ZGrad_Meth_DrugEffect")
            net.WriteString("red_meth")
            net.WriteFloat(duration)
        net.Send(ply)
    end
    
    -- Timer to remove effects
    local timerName = "ZGrad_MethEffect_" .. ply:SteamID64()
    timer.Create(timerName, duration, 1, function()
        if not IsValid(ply) then return end
        
        ply.ZGrad_MethStamina = false
        
        -- Hunger drop for normal meth
        if methType == "meth" then
            ply:setDarkRPVar("energy", 5)
            DarkRP.notify(ply, 1, 4, "Вы чувствуете сильное истощение после действия мёта...")
        end
        
        if ply.ZGrad_OrigRunSpeed then
            ply:SetRunSpeed(ply.ZGrad_OrigRunSpeed)
            ply.ZGrad_OrigRunSpeed = nil
        end
    end)
end

-- Think hook for stamina management
hook.Add("Think", "ZGrad_Meth_StaminaManagement", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.ZGrad_MethStamina and ply.ZGrad_MethEnd and CurTime() < ply.ZGrad_MethEnd then
            -- Keep stamina full during meth effect
            if ply.organism and ply.organism.stamina then
                ply.organism.stamina[1] = ply.organism.stamina.max or 180
            end
            
            if ply.SetRunSpeed and ply:GetNWFloat("stamina", 100) then
                ply:SetNWFloat("stamina", 100)
            end
        end
        
        -- Hunger immunity check
        if ply.ZGrad_HungerImmune and ply.ZGrad_HungerImmuneEnd then
            if CurTime() > ply.ZGrad_HungerImmuneEnd then
                ply.ZGrad_HungerImmune = false
                ply.ZGrad_HungerImmuneEnd = nil
                ply:setDarkRPVar("hungerImmuneEnd", 0)
            else
                -- Keep hunger at current level
                local energy = ply:getDarkRPVar("energy")
                if energy then
                    ply.ZGrad_LastEnergy = energy
                end
            end
        end
    end
end)

-- Prevent hunger drain when immune
hook.Add("DarkRPVarChanged", "ZGrad_Meth_HungerImmunity", function(ply, varname, oldvalue, newvalue)
    if varname == "energy" and ply.ZGrad_HungerImmune then
        if newvalue < (oldvalue or 100) then
            ply:setDarkRPVar("energy", oldvalue)
        end
    end
end)

-- Clean up on death
hook.Add("PlayerDeath", "ZGrad_Meth_CleanupEffects", function(ply)
    ply.ZGrad_MethStamina = false
    
    if ply.ZGrad_OrigRunSpeed then
        ply:SetRunSpeed(ply.ZGrad_OrigRunSpeed)
        ply.ZGrad_OrigRunSpeed = nil
    end
    
    local timerName = "ZGrad_MethEffect_" .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end)

print("[Z-Grad RP] Meth system (server) loaded")

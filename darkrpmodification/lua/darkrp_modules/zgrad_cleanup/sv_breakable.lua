--[[---------------------------------------------------------------------------
Z-Grad RP — Breakable Entities
---------------------------------------------------------------------------]]

hook.Add("EntityTakeDamage", "ZGrad_Entities_Breakable", function(ent, dmg)
    if not IsValid(ent) or ent:IsPlayer() or ent:IsNPC() then return end
    
    local class = ent:GetClass()
    
    -- Список классов, которые точно НЕ должны ломаться (если нужно)
    if class == "func_breakable" or class == "func_door" or class == "prop_door_rotating" or class == "prop_ragdoll" then return end
    
    -- Исключение для ящиков: ломаются только если пусты
    local isCrate = (class == "zgrad_crate_small" or class == "zgrad_crate_large")
    if isCrate then
        if ent.CrateItems and #ent.CrateItems > 0 then
            -- Если в ящике есть вещи — он бессмертен
            return
        end
    end

    -- Не трогаем пропы физики (их ломать не просили, просили "ентити" — обычно купленные в F4)
    if class == "prop_physics" then return end

    -- Инициализация здоровья при первом ударе
    if not ent.ZGrad_Health then
        local hp = 100
        
        -- Пытаемся взять цену из DarkRP для расчета HP
        if ent.DarkRPItem and ent.DarkRPItem.price then
            hp = math.Clamp(ent.DarkRPItem.price / 5, 50, 1000)
        end
        
        -- Специальные HP для некоторых вещей
        if isCrate then hp = 150 end
        if class == "zgrad_meth_pot" then hp = 80 end
        
        ent.ZGrad_Health = hp
        ent.ZGrad_MaxHealth = hp
    end

    -- Наносим урон
    ent.ZGrad_Health = ent.ZGrad_Health - dmg:GetDamage()
    
    -- Эффект попадания (искры/щепки)
    local effect = EffectData()
    effect:SetOrigin(dmg:GetDamagePosition())
    effect:SetNormal(dmg:GetDamageForce():GetNormalized())
    util.Effect("MetalSpark", effect)
    
    if ent.ZGrad_Health <= 0 then
        -- Эффект разрушения
        local boom = EffectData()
        boom:SetOrigin(ent:GetPos())
        util.Effect("Explosion", boom)
        
        ent:EmitSound("physics/wood/wood_box_break" .. math.random(1, 2) .. ".wav")
        ent:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav")
        
        -- Уведомление владельцу
        local owner = ent.ZGrad_Owner or ent:GetNW2Entity("owner")
        if IsValid(owner) and owner:IsPlayer() then
            DarkRP.notify(owner, 1, 4, "Ваш предмет (" .. (ent.PrintName or class) .. ") был уничтожен!")
        end
        
        ent:Remove()
    end
end)

print("[Z-Grad RP] Breakable Entities Module Loaded")

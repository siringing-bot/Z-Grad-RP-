--[[---------------------------------------------------------------------------
Z-Grad RP — Meth Cooking System (Client Module)
Drug visual effects (ENHANCED - жёсткие эффекты)
---------------------------------------------------------------------------]]

local effectActive = false
local effectType = ""
local effectEnd = 0
local effectDuration = 0

-- Receive drug effect from server
net.Receive("ZGrad_Meth_DrugEffect", function()
    effectType = net.ReadString()
    effectDuration = net.ReadFloat()
    effectEnd = CurTime() + effectDuration
    effectActive = true
end)

-- Screen effects (УСИЛЕННЫЕ)
hook.Add("RenderScreenspaceEffects", "ZGrad_Meth_ScreenEffects", function()
    if not effectActive then return end
    if CurTime() > effectEnd then
        effectActive = false
        return
    end
    
    local timeLeft = effectEnd - CurTime()
    local progress = timeLeft / effectDuration -- 1 = just started, 0 = ending
    
    if effectType == "meth" then
        -- УСИЛЕННЫЙ: Мощная пульсация цвета, сильное размытие, шатание экрана
        local sway = math.sin(CurTime() * 4) * 0.08 * progress
        local pulse = math.abs(math.sin(CurTime() * 2.5)) * 0.15 * progress
        local flicker = math.random() * 0.03 * progress
        local tab = {
            ["$pp_colour_addr"] = sway * 0.4 + pulse + flicker,
            ["$pp_colour_addg"] = -0.03 * progress + flicker,
            ["$pp_colour_addb"] = -0.05 * progress,
            ["$pp_colour_brightness"] = sway * 0.8 + 0.05 * progress,
            ["$pp_colour_contrast"] = 1 + math.sin(CurTime() * 3) * 0.25 * progress,
            ["$pp_colour_colour"] = 1.4 + 0.3 * progress,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0,
        }
        DrawColorModify(tab)
        
        -- Сильное размытие в движении
        DrawMotionBlur(0.2, 0.85 * progress, 0.01)
        
        -- Дополнительный блум эффект
        DrawBloom(0.5 * progress, 1.5 * progress, 6, 6, 3, 1, 1, 1, 1)
        
    elseif effectType == "blue_meth" then
        -- УСИЛЕННЫЙ: Сильное побеление экрана, тяжёлая десатурация, замедление
        local intensity = progress * 0.7
        local flicker = math.sin(CurTime() * 6) * 0.04 * progress
        local tab = {
            ["$pp_colour_addr"] = intensity * 0.8 + flicker,
            ["$pp_colour_addg"] = intensity * 0.8 + flicker,
            ["$pp_colour_addb"] = intensity + flicker,
            ["$pp_colour_brightness"] = intensity * 0.5,
            ["$pp_colour_contrast"] = 1 - intensity * 0.35,
            ["$pp_colour_colour"] = 1 - intensity * 0.8, -- сильная десатурация
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0,
        }
        DrawColorModify(tab)
        
        -- Блюр/блум для ощущения "трипа"
        DrawBloom(0.8 * progress, 2.5 * progress, 8, 8, 4, 1, 1, 1, 1)
        
        -- Слабое размытие в движении
        DrawMotionBlur(0.15, 0.7 * progress, 0.01)
        
    elseif effectType == "red_meth" then
        -- УСИЛЕННЫЙ: Агрессивная красная пульсация, вспышки, экстремальное обострение
        local pulse = math.sin(CurTime() * 5) * 0.12 * progress
        local hardPulse = math.max(0, math.sin(CurTime() * 8)) * 0.08 * progress
        local flash = 0
        -- Периодические вспышки красного
        if math.sin(CurTime() * 3) > 0.9 then
            flash = 0.15 * progress
        end
        local tab = {
            ["$pp_colour_addr"] = 0.25 * progress + pulse + flash,
            ["$pp_colour_addg"] = -0.08 * progress - hardPulse,
            ["$pp_colour_addb"] = -0.08 * progress - hardPulse,
            ["$pp_colour_brightness"] = 0.1 * progress + flash * 0.5,
            ["$pp_colour_contrast"] = 1.4 + 0.3 * progress,
            ["$pp_colour_colour"] = 1.5 + 0.2 * progress,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0,
        }
        DrawColorModify(tab)
        
        -- Очень сильное обострение (sharpening)
        DrawSharpen(2.5 * progress, 1.2 * progress)
        
        -- Агрессивный блум для "виньетки"  
        DrawBloom(0.3 * progress, 1.0 * progress, 4, 4, 2, 1, 0.3, 0.3, 1)
    end
end)

-- View manipulation - сильный sway + FOV эффекты
hook.Add("CalcView", "ZGrad_Meth_ViewSway", function(ply, pos, angles, fov)
    if not effectActive then return end
    if CurTime() > effectEnd then return end
    
    local progress = (effectEnd - CurTime()) / effectDuration
    
    if effectType == "meth" then
        -- Сильная качка камеры
        local sway = math.sin(CurTime() * 2) * 4 * progress
        local sway2 = math.cos(CurTime() * 1.5) * 3 * progress
        local sway3 = math.sin(CurTime() * 3.5) * 1.5 * progress
        angles.r = angles.r + sway
        angles.p = angles.p + sway2 * 0.5
        angles.y = angles.y + sway3 * 0.2
        
        -- Лёгкое увеличение FOV (эффект дурноты)
        fov = fov + math.sin(CurTime() * 1.8) * 3 * progress
        
        return { origin = pos, angles = angles, fov = fov }
        
    elseif effectType == "blue_meth" then
        -- Замедленная, тянущаяся камера + уменьшение FOV (тоннельное зрение)
        local slowSway = math.sin(CurTime() * 0.8) * 1.5 * progress
        local slowSway2 = math.cos(CurTime() * 0.6) * 1 * progress
        angles.r = angles.r + slowSway
        angles.p = angles.p + slowSway2 * 0.3
        
        -- Тоннельное зрение — сужение FOV
        fov = fov - 15 * progress
        
        return { origin = pos, angles = angles, fov = fov }
        
    elseif effectType == "red_meth" then
        -- Микро-дрожь камеры от ярости
        local shake = math.random() * 1.5 * progress - 0.75 * progress
        local shake2 = math.random() * 1.0 * progress - 0.5 * progress
        angles.r = angles.r + shake * 0.3
        angles.p = angles.p + shake2 * 0.3
        
        -- Широкий FOV (ощущение ярости, адреналина)
        fov = fov + 8 * progress
        
        return { origin = pos, angles = angles, fov = fov }
    end
end)

-- Sound muting for blue meth (УСИЛЕННЫЙ)
hook.Add("EntityEmitSound", "ZGrad_Meth_MuteSound", function(data)
    if not effectActive or effectType ~= "blue_meth" then return end
    if CurTime() > effectEnd then return end
    
    local progress = (effectEnd - CurTime()) / effectDuration
    
    -- Очень сильное приглушение + замедление pitch
    data.Volume = data.Volume * (0.15 + 0.15 * (1 - progress))
    data.Pitch = data.Pitch * (0.7 - 0.1 * progress)
    return true
end)

-- Cooking timer HUD
net.Receive("ZGrad_Meth_CookingTimer", function()
    local entIndex = net.ReadUInt(16)
    local timeLeft = net.ReadFloat()
    local recipeName = net.ReadString()
    local quality = net.ReadUInt(8)
    
    local ent = Entity(entIndex)
    if not IsValid(ent) then return end
    
    ent.ZGrad_CookTimeLeft = timeLeft
    ent.ZGrad_CookRecipe = recipeName
    ent.ZGrad_CookQuality = quality
    ent.ZGrad_CookLastUpdate = CurTime()
end)

print("[Z-Grad RP] Meth system (client) loaded — enhanced effects")

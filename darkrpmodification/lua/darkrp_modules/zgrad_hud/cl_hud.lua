--[[---------------------------------------------------------------------------
Z-Grad RP — Custom HUD (Classic Style with Blue Outline)
---------------------------------------------------------------------------]]

local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["DarkRP_HUD"] = true,
    ["DarkRP_Hungermod"] = false,
    ["DarkRP_EntityDisplay"] = true,
    ["DarkRP_DoorHUD"] = true,
    ["DarkRP_LocalPlayerHUD"] = true,
}

hook.Add("HUDShouldDraw", "ZGrad_HideHUD", function(name)
    if hide[name] then return false end
end)

-- Шрифты
surface.CreateFont("ZGrad_HUD_Large", {
    font = "Roboto",
    size = 24,
    weight = 500,
    antialias = true,
})

surface.CreateFont("ZGrad_HUD_Small", {
    font = "Roboto",
    size = 18,
    weight = 400,
    antialias = true,
})

surface.CreateFont("ZGrad_HUD_Title", {
    font = "DermaLarge",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true,
})

local function DrawBar(x, y, w, h, val, max, color, text)
    draw.RoundedBox(4, x, y, w, h, Color(20, 20, 20, 220)) -- Фон
    
    -- Голубая обводка
    surface.SetDrawColor(Color(0, 180, 255, 150))
    surface.DrawOutlinedRect(x, y, w, h)

    local barW = math.Clamp(val / max, 0, 1) * (w - 2)
    draw.RoundedBox(4, x + 1, y + 1, barW, h - 2, color) -- Полоска
    
    draw.SimpleText(text .. ": " .. val .. "%", "ZGrad_HUD_Small", x + 10, y + h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "ZGrad_DrawHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local hp = ply:Health()
    local armor = ply:Armor()
    local money = ply:getDarkRPVar("money") or 0
    local salary = ply:getDarkRPVar("salary") or 0
    local job = ply:getDarkRPVar("job") or "Безработный"
    
    local scrW, scrH = ScrW(), ScrH()
    local x, y = 20, scrH - 140

    -- Инфо панель (Деньги, Работа)
    local jobColor = (ply.getDarkRPVar and ply:getDarkRPVar("jobColor")) or team.GetColor(ply:Team())
    
    -- Панель с обводкой
    draw.RoundedBox(6, x, y, 300, 60, Color(20, 20, 20, 220))
    surface.SetDrawColor(Color(0, 180, 255, 200))
    surface.DrawOutlinedRect(x, y, 300, 60)

    draw.SimpleText(job, "ZGrad_HUD_Large", x + 10, y + 10, jobColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("$" .. string.Comma(money) .. " (+" .. salary .. ")", "ZGrad_HUD_Small", x + 10, y + 35, Color(100, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Название сервера (справа сверху)
    draw.SimpleText("Z-Grad RP", "ZGrad_HUD_Title", scrW - 20, 20, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Лицензия на оружие
    if ply:getDarkRPVar("HasGunlicense") then
         draw.SimpleText("Лицензия: ЕСТЬ", "ZGrad_HUD_Small", x + 10, y - 20, Color(100, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end

    -- Голод (Hunger Bar)
    local hungerImmuneEnd = ply:getDarkRPVar("hungerImmuneEnd") or 0
    local timeLeft = hungerImmuneEnd - CurTime()
    
    if timeLeft > 0 then
        local mins = math.floor(timeLeft / 60)
        local secs = math.floor(timeLeft % 60)
        local timeStr = string.format("%02d:%02d", mins, secs)
        
        draw.RoundedBox(4, x, y + 70, 300, 20, Color(20, 20, 20, 220))
        surface.SetDrawColor(Color(0, 180, 255, 100))
        surface.DrawOutlinedRect(x, y + 70, 300, 20)
        draw.SimpleText("Иммунитет к голоду: " .. timeStr, "ZGrad_HUD_Small", x + 10, y + 70 + 10, Color(255, 200, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    else
        local energy = ply:getDarkRPVar("energy") or 100
        DrawBar(x, y + 70, 300, 20, energy, 100, Color(255, 140, 0, 200), "Голод")
    end
end)

print("[Z-Grad RP] Classical HUD with Outline Loaded")

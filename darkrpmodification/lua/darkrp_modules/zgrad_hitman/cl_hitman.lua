--[[---------------------------------------------------------------------------
Z-Grad RP — Hitman Module (Client)
---------------------------------------------------------------------------]]

ZGrad_Hitman.ActiveHits = ZGrad_Hitman.ActiveHits or {} -- Создаем шрифт еще больше
surface.CreateFont("ZGrad_Hitman_HUD_Big", {
    font = "Roboto",
    size = 40,
    weight = 800,
})

net.Receive("ZGrad_HitUpdate", function()
    ZGrad_Hitman.ActiveHits = net.ReadTable()
end)

-- Возвращаем старый HUD (в C-меню)
hook.Add("HUDPaint", "ZGrad_HitmanHUD", function()
    if not ZGrad_Hitman.IsHitman(LocalPlayer()) then return end
    
    -- Проверка на открытое C-меню
    if not vgui.CursorVisible() then return end

    local w, h = ScrW(), ScrH()
    local x, y = w - 20, 150 -- СДЕЛАЛИ НИЖЕ (было 20)
    
    local i = 0
    for sid, hit in pairs(ZGrad_Hitman.ActiveHits or {}) do
        -- ИСПОЛЬЗУЕМ КРУПНЫЙ ШРИФТ
        local text = "ЦЕЛЬ: " .. (hit.targetName or "???") .. " | " .. DarkRP.formatMoney(hit.price or 0)
        draw.SimpleTextOutlined(text, "ZGrad_Hitman_HUD_Big", x, y + (i * 45), Color(255, 50, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
        i = i + 1
    end

    if i == 0 then
        draw.SimpleTextOutlined("ЗАКАЗОВ НЕТ", "ZGrad_Hitman_HUD_Big", x, y, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end)

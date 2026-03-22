--[[---------------------------------------------------------------------------
Z-Grad RP — Money Notification (Client)
---------------------------------------------------------------------------]]

local notifications = {}

-- Получаем сообщение от сервера
net.Receive("ZGrad_MoneyNotify", function()
    local amount = net.ReadInt(32)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Звук (тихий и приятный)
    ply:EmitSound("ambient/levels/labs/coinslot1.wav", 60, 150, 0.4) -- Тон повыше чтобы был поприятнее

    -- Если уже есть недавнее уведомление, прибавляем к нему (чтобы не спамить)
    local merged = false
    for _, v in ipairs(notifications) do
        if v.time + 1 > CurTime() then
            v.amount = v.amount + amount
            v.time = CurTime()
            merged = true
            break
        end
    end

    if not merged then
        table.insert(notifications, {
            amount = amount,
            time = CurTime(),
            opacity = 0,
            yOffset = 0
        })
    end
end)

-- Хук отрисовки
--[[hook.Add("HUDPaint", "ZGrad_MoneyNotify_Draw", function()
    if #notifications == 0 then return end

    local scrW, scrH = ScrW(), ScrH()
    local base_x = 30
    local base_y = scrH - 155 -- Чуть выше основной панели HUD (она на -140)

    for i = #notifications, 1, -1 do
        local n = notifications[i]
        local elapsed = CurTime() - n.time
        local duration = 3.0 -- Время жизни

        if elapsed > duration then
            table.remove(notifications, i)
            continue
        end

        -- Анимация появления и затухания
        local alpha = 255
        if elapsed < 0.5 then
            alpha = (elapsed / 0.5) * 255
        elseif elapsed > (duration - 1) then
            alpha = ((duration - elapsed) / 1) * 255
        end

        -- Плавное движение вверх
        n.yOffset = Lerp(FrameTime() * 2, n.yOffset, -50)
        local draw_y = base_y + n.yOffset - ((#notifications - i) * 25)

        -- Отрисовка текста
        local text = "+$" .. string.Comma(n.amount)
        draw.SimpleTextOutlined(text, "ZGrad_HUD_Large", base_x, draw_y, Color(100, 255, 100, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
    end
end)--]]

print("[Z-Grad RP] Money Notification (Client) Loaded")

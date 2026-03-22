--[[---------------------------------------------------------------------------
    Zgrad — Манипринтер (Клиент)
    3D2D HUD: Бумага / Чернила / Энергия / Деньги
    Меню при нажатии E
---------------------------------------------------------------------------]]
include("shared.lua")

-- =============================================
-- 3D2D Отображение над принтером
-- =============================================
function ENT:Draw()
    self:DrawModel()

    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist > 300 then return end

    local pos = self:GetPos() + Vector(0, 0, 42)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local paper    = self:GetPaper()
    local ink      = self:GetInk()
    local hasPower = self:GetHasPower()
    local money    = self:GetMoney()
    local isOn     = self:GetIsOn()

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        -- Фон (Расширяем вниз для улучшений)
        draw.RoundedBox(6, -130, -70, 260, 210, Color(10, 10, 10, 200))
        draw.RoundedBox(6, -128, -68, 256, 206, Color(25, 25, 40, 220))

        -- Заголовок
        local isWorking = isOn and hasPower and paper >= 1 and ink >= 2
        local titleColor = Color(200, 60, 60)
        local titleText = "■ ВЫКЛЮЧЕН"
        if isOn then
            if isWorking then
                titleText = "■ РАБОТАЕТ"
                titleColor = Color(50, 255, 100)
            else
                titleText = "■ ПРОСТАИВАЕТ"
                titleColor = Color(255, 180, 50)
            end
        end
        draw.SimpleTextOutlined("МАНИПРИНТЕР", "DermaDefaultBold", 0, -55, Color(220, 180, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
        draw.SimpleTextOutlined(titleText, "DermaDefault", 0, -35, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        -- Разделитель
        surface.SetDrawColor(80, 80, 100, 180)
        surface.DrawRect(-115, -20, 230, 1)

        -- Ресурсы
        local hasStorage = self:GetHasUpgradeStorage()
        local maxP = hasStorage and 40 or 20
        local maxI = hasStorage and 80 or 40

        local paperColor = paper > (maxP/4) and Color(100, 200, 255) or Color(255, 80, 80)
        draw.SimpleTextOutlined("📄 Бумага: " .. paper .. "/" .. maxP, "DermaDefault", -110, -5, paperColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        local inkColor = ink > (maxI/4) and Color(180, 100, 255) or Color(255, 80, 80)
        draw.SimpleTextOutlined("🖋 Чернила: " .. ink .. "/" .. maxI, "DermaDefault", -110, 20, inkColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        local powerText  = hasPower and "✔ Есть" or "✘ Нет"
        local powerColor = hasPower and Color(50, 255, 100) or Color(255, 80, 80)
        draw.SimpleTextOutlined("⚡ Энергия: " .. powerText, "DermaDefault", -110, 45, powerColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        -- Деньги
        draw.SimpleTextOutlined("💵 Накоплено: $" .. money, "DermaDefaultBold", 0, 75, Color(255, 210, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        -- УЛУЧШЕНИЯ
        surface.SetDrawColor(80, 80, 100, 180)
        surface.DrawRect(-115, 95, 230, 1)
        
        draw.SimpleTextOutlined("УЛУЧШЕНИЯ:", "DermaDefaultBold", 0, 108, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
        
        local upgText = ""
        if self:GetHasUpgradeSpeed() then upgText = upgText .. "[SPEED] " end
        if self:GetHasUpgradeStorage() then upgText = upgText .. "[STORAGE] " end
        if self:GetHasUpgradeBoost() then upgText = upgText .. "[BOOST] " end
        
        if upgText == "" then upgText = "Нет улучшений" end
        draw.SimpleTextOutlined(upgText, "DermaDefault", 0, 125, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

    cam.End3D2D()
end

-- =============================================
-- Net — получаем сигнал открыть меню
-- =============================================
net.Receive("ZGrad_ManiprintMenu", function()
    local ent   = net.ReadEntity()
    local isOn  = net.ReadBool()
    local money = net.ReadInt(32)

    if not IsValid(ent) then return end

    -- Закрываем предыдущее меню если есть
    if IsValid(ZGrad_ManiprintFrame) then ZGrad_ManiprintFrame:Remove() end

    local frame = vgui.Create("DFrame")
    ZGrad_ManiprintFrame = frame
    frame:SetTitle("")
    frame:SetSize(320, 200)
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(15, 15, 25, 245))
        draw.RoundedBox(10, 1, 1, w-2, h-2, Color(30, 30, 50, 240))
        -- Заголовок полоска
        draw.RoundedBoxEx(10, 0, 0, w, 40, Color(40, 40, 80, 255), true, true, false, false)
        draw.SimpleTextOutlined("МАНИПРИНТЕР", "DermaDefaultBold", w/2, 20, Color(220, 180, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
    end

    -- Статус денег
    local moneyLabel = vgui.Create("DLabel", frame)
    moneyLabel:SetPos(0, 48)
    moneyLabel:SetSize(320, 24)
    moneyLabel:SetText("💵 Накоплено: $" .. money)
    moneyLabel:SetFont("DermaDefaultBold")
    moneyLabel:SetContentAlignment(5)
    moneyLabel:SetTextColor(Color(255, 210, 50))

    -- Кнопка ВКЛ/ВЫКЛ
    local toggleBtn = vgui.Create("DButton", frame)
    toggleBtn:SetPos(20, 80)
    toggleBtn:SetSize(280, 45)
    toggleBtn:SetText(isOn and "⏹  ВЫКЛЮЧИТЬ" or "▶  ВКЛЮЧИТЬ")
    toggleBtn:SetFont("DermaDefaultBold")
    toggleBtn:SetTextColor(Color(255, 255, 255))
    toggleBtn.Paint = function(self, w, h)
        local col = isOn and Color(180, 50, 50) or Color(40, 160, 60)
        if self:IsHovered() then
            col = isOn and Color(220, 70, 70) or Color(60, 200, 80)
        end
        draw.RoundedBox(8, 0, 0, w, h, col)
    end
    toggleBtn.DoClick = function()
        net.Start("ZGrad_ManiprintAction")
            net.WriteEntity(ent)
            net.WriteString("toggle")
        net.SendToServer()
        frame:Remove()
    end

    -- Кнопка снять деньги
    local collectBtn = vgui.Create("DButton", frame)
    collectBtn:SetPos(20, 135)
    collectBtn:SetSize(280, 45)
    collectBtn:SetText("💵  СНЯТЬ ДЕНЬГИ ($" .. money .. ")")
    collectBtn:SetFont("DermaDefaultBold")
    collectBtn:SetTextColor(Color(255, 255, 255))
    collectBtn.Paint = function(self, w, h)
        local col = money > 0 and Color(30, 100, 200) or Color(60, 60, 60)
        if self:IsHovered() and money > 0 then
            col = Color(50, 130, 240)
        end
        draw.RoundedBox(8, 0, 0, w, h, col)
    end
    collectBtn.DoClick = function()
        if money <= 0 then return end
        net.Start("ZGrad_ManiprintAction")
            net.WriteEntity(ent)
            net.WriteString("collect")
        net.SendToServer()
        frame:Remove()
    end

    -- Закрытие по Escape
    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then
            self:Remove()
        end
    end

    -- Закрыть через 10 сек автоматически
    timer.Simple(10, function()
        if IsValid(frame) then frame:Remove() end
    end)
end)

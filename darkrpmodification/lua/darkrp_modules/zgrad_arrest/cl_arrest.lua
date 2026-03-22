--[[---------------------------------------------------------------------------
Z-Grad RP — Arrest System (Client)
Меню выбора статьи + HUD таймер заключённого
---------------------------------------------------------------------------]]

-- =============================================
-- ШРИФТЫ
-- =============================================
surface.CreateFont("ZGrad_Arrest_Title", {
    font = "Roboto",
    size = 28,
    weight = 700,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Crime", {
    font = "Roboto",
    size = 20,
    weight = 500,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Time", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Button", {
    font = "Roboto",
    size = 18,
    weight = 600,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Timer_Big", {
    font = "Roboto",
    size = 36,
    weight = 800,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Timer_Small", {
    font = "Roboto",
    size = 20,
    weight = 500,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Hint", {
    font = "Roboto",
    size = 22,
    weight = 600,
    antialias = true,
})

surface.CreateFont("ZGrad_Arrest_Hint_Key", {
    font = "Roboto",
    size = 26,
    weight = 800,
    antialias = true,
})

-- =============================================
-- Цвета
-- =============================================
local COLORS = {
    bg          = Color(15, 15, 20, 245),
    header      = Color(30, 60, 140, 255),
    headerText  = Color(255, 255, 255, 255),
    itemBg      = Color(25, 25, 35, 200),
    itemHover   = Color(40, 70, 160, 200),
    itemText    = Color(220, 220, 230),
    timeText    = Color(255, 180, 50),
    confirm     = Color(40, 140, 40, 255),
    confirmHov  = Color(50, 180, 50, 255),
    cancel      = Color(140, 30, 30, 255),
    cancelHov   = Color(180, 40, 40, 255),
    border      = Color(60, 100, 200, 100),
    timerBg     = Color(10, 10, 15, 220),
    timerBar    = Color(30, 60, 140, 255),
    timerBarBg  = Color(40, 40, 50, 200),
    timerText   = Color(255, 255, 255),
    accent      = Color(80, 130, 255),
}

-- =============================================
-- МЕНЮ ВЫБОРА СТАТЬИ
-- =============================================
local arrestTarget = nil

net.Receive("ZGrad_Arrest_OpenMenu", function()
    arrestTarget = net.ReadEntity()

    if not IsValid(arrestTarget) then return end

    -- Закрываем предыдущее меню если есть
    if IsValid(ZGrad_Arrest.MenuFrame) then
        ZGrad_Arrest.MenuFrame:Remove()
    end

    local scrW, scrH = ScrW(), ScrH()
    local menuW, menuH = 500, 620
    local selectedCrime = nil

    -- ============ Основная рамка ============
    local frame = vgui.Create("DFrame")
    frame:SetSize(menuW, menuH)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        -- Тень
        draw.RoundedBox(10, 2, 2, w, h, Color(0, 0, 0, 100))
        -- Фон
        draw.RoundedBox(8, 0, 0, w, h, COLORS.bg)
        -- Рамка
        surface.SetDrawColor(COLORS.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    ZGrad_Arrest.MenuFrame = frame

    -- ============ Заголовок ============
    local header = vgui.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(60)
    header:DockMargin(0, 0, 0, 0)
    header.Paint = function(self, w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, COLORS.header, true, true, false, false)
        draw.SimpleText("АРЕСТ ПРЕСТУПНИКА", "ZGrad_Arrest_Title", w / 2, 15, COLORS.headerText, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(arrestTarget:Nick(), "ZGrad_Arrest_Crime", w / 2, 38, Color(200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- ============ Список статей ============
    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(10, 10, 10, 10)

    -- Кастомный скроллбар
    local sbar = scrollPanel:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 150))
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.accent)
    end

    -- Кнопки статей
    for i, crime in ipairs(ZGrad_Arrest.Crimes) do
        local btn = vgui.Create("DButton", scrollPanel)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 4)
        btn:SetTall(44)
        btn:SetText("")
        btn.selected = false

        btn.Paint = function(self, w, h)
            local bgCol = COLORS.itemBg
            if self.selected then
                bgCol = COLORS.accent
            elseif self:IsHovered() then
                bgCol = COLORS.itemHover
            end

            draw.RoundedBox(6, 0, 0, w, h, bgCol)

            -- Номер статьи
            local numText = tostring(i) .. "."
            draw.SimpleText(numText, "ZGrad_Arrest_Crime", 12, h / 2 - 1, COLORS.itemText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Название
            draw.SimpleText(crime.name, "ZGrad_Arrest_Crime", 40, h / 2 - 1, COLORS.itemText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Время
            local mins = math.floor(crime.time / 60)
            local secs = crime.time % 60
            local timeStr = string.format("%d:%02d", mins, secs)
            draw.SimpleText(timeStr, "ZGrad_Arrest_Time", w - 12, h / 2, COLORS.timeText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            -- Снимаем выделение со всех
            for _, child in ipairs(scrollPanel:GetCanvas():GetChildren()) do
                if child.selected ~= nil then
                    child.selected = false
                end
            end
            btn.selected = true
            selectedCrime = i
            surface.PlaySound("UI/buttonclick.wav")
        end
    end

    -- ============ Нижняя панель с кнопками ============
    local bottomPanel = vgui.Create("DPanel", frame)
    bottomPanel:Dock(BOTTOM)
    bottomPanel:SetTall(50)
    bottomPanel:DockMargin(10, 0, 10, 10)
    bottomPanel.Paint = function() end

    -- Кнопка "Арестовать"
    local confirmBtn = vgui.Create("DButton", bottomPanel)
    confirmBtn:SetText("")
    confirmBtn:Dock(LEFT)
    confirmBtn:SetWide(menuW / 2 - 25)
    confirmBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and COLORS.confirmHov or COLORS.confirm
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("АРЕСТОВАТЬ", "ZGrad_Arrest_Button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    confirmBtn.DoClick = function()
        if not selectedCrime then
            surface.PlaySound("buttons/button10.wav")
            return
        end

        if not IsValid(arrestTarget) then
            frame:Remove()
            return
        end

        net.Start("ZGrad_Arrest_Confirm")
            net.WriteUInt(selectedCrime, 8)
            net.WriteEntity(arrestTarget)
        net.SendToServer()

        surface.PlaySound("buttons/button9.wav")
        frame:Remove()
    end

    -- Кнопка "Отмена"
    local cancelBtn = vgui.Create("DButton", bottomPanel)
    cancelBtn:SetText("")
    cancelBtn:Dock(RIGHT)
    cancelBtn:SetWide(menuW / 2 - 25)
    cancelBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and COLORS.cancelHov or COLORS.cancel
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("ОТМЕНА", "ZGrad_Arrest_Button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    cancelBtn.DoClick = function()
        surface.PlaySound("UI/buttonrollover.wav")
        frame:Remove()
    end
end)

-- =============================================
-- HUD ТАЙМЕР ДЛЯ ЗАКЛЮЧЁННОГО
-- =============================================
local jailEndTime = 0
local jailTotalDuration = 0
local jailCrimeName = ""
local isInJail = false

net.Receive("ZGrad_Arrest_Timer", function()
    local duration = net.ReadFloat()
    jailCrimeName = net.ReadString()
    jailEndTime = CurTime() + duration
    jailTotalDuration = duration
    isInJail = true
end)

net.Receive("ZGrad_Arrest_TimerEnd", function()
    isInJail = false
    jailEndTime = 0
    jailTotalDuration = 0
    jailCrimeName = ""
end)

-- Рисуем HUD-таймер снизу по центру
local lastNWCheck = 0
hook.Add("HUDPaint", "ZGrad_Arrest_JailTimer", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Авто-подхват если NW говорит что мы в тюрьме, а флаг isInJail еще не стоит
    if CurTime() > lastNWCheck then
        lastNWCheck = CurTime() + 2
        if ply:GetNWBool("ZGrad_IsJailed", false) and not isInJail then
            local endTime = ply:GetNWFloat("ZGrad_JailEnd", 0)
            if endTime > CurTime() then
                jailEndTime = endTime
                jailTotalDuration = ply:GetNWFloat("ZGrad_JailDuration", endTime - CurTime())
                jailCrimeName = ply:GetNWString("ZGrad_JailCrime", "Неизвестно")
                isInJail = true
            end
        end
    end

    if not isInJail then return end

    -- Если NWBool говорит что мы вышли, выключаем HUD (с задержкой 1 сек для надежности)
    if not ply:GetNWBool("ZGrad_IsJailed", false) then
        if not ply.ZGrad_ReleaseWait then
            ply.ZGrad_ReleaseWait = CurTime() + 1.5
        elseif CurTime() > ply.ZGrad_ReleaseWait then
            isInJail = false
            ply.ZGrad_ReleaseWait = nil
        end
        if not isInJail then return end
    else
        ply.ZGrad_ReleaseWait = nil -- Сбрасываем если всё ещё в тюрьме
    end

    local remaining = math.max(0, jailEndTime - CurTime())
    if remaining <= 0 and not ply:GetNWBool("ZGrad_IsJailed", false) then
        isInJail = false
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local panelW, panelH = 400, 90
    local panelX = scrW / 2 - panelW / 2
    local panelY = scrH - panelH - 40

    -- Фон панели
    draw.RoundedBox(10, panelX, panelY, panelW, panelH, COLORS.timerBg)
    surface.SetDrawColor(COLORS.border)
    surface.DrawOutlinedRect(panelX, panelY, panelW, panelH, 1)

    -- Статья
    draw.SimpleText("Статья: " .. (jailCrimeName ~= "" and jailCrimeName or "Не указана"), "ZGrad_Arrest_Timer_Small", scrW / 2, panelY + 14, COLORS.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Время
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    local timeStr = string.format("Осталось: %d:%02d", mins, secs)
    draw.SimpleText(timeStr, "ZGrad_Arrest_Timer_Big", scrW / 2, panelY + 38, COLORS.timerText, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Полоска прогресса
    local barX = panelX + 20
    local barY = panelY + panelH - 16
    local barW = panelW - 40
    local barH = 6

    local progress = math.Clamp(1 - (remaining / math.max(jailTotalDuration, 1)), 0, 1)

    draw.RoundedBox(3, barX, barY, barW, barH, COLORS.timerBarBg)
    draw.RoundedBox(3, barX, barY, barW * progress, barH, COLORS.timerBar)
end)

-- =============================================
-- Восстановление таймера после рестарта клиента
-- =============================================
hook.Add("InitPostEntity", "ZGrad_Arrest_RestoreTimer", function()
    local tryCount = 0
    timer.Create("ZGrad_Arrest_InitSync", 2, 5, function()
        local ply = LocalPlayer()
        if IsValid(ply) then
            if ply:GetNWBool("ZGrad_IsJailed", false) then
                local endTime = ply:GetNWFloat("ZGrad_JailEnd", 0)
                if endTime > CurTime() then
                    jailEndTime = endTime
                    jailTotalDuration = ply:GetNWFloat("ZGrad_JailDuration", endTime - CurTime())
                    jailCrimeName = ply:GetNWString("ZGrad_JailCrime", "")
                    isInJail = true
                end
            end
        end
    end)
end)

-- =============================================
-- Подсказка "Нажмите E чтобы арестовать"
-- =============================================
hook.Add("HUDPaint", "ZGrad_Arrest_HintDraw", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:GetNWBool("ZGrad_CanArrestTarget", false) then return end

    local scrW, scrH = ScrW(), ScrH()
    local hintW, hintH = 340, 50
    local hintX = scrW / 2 - hintW / 2
    local hintY = scrH / 2 + 60

    -- Фон подсказки
    draw.RoundedBox(8, hintX, hintY, hintW, hintH, Color(10, 10, 15, 220))
    surface.SetDrawColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 150)
    surface.DrawOutlinedRect(hintX, hintY, hintW, hintH, 1)

    -- Пульсация для привлечения внимания
    local pulse = math.sin(CurTime() * 4) * 30 + 225
    local hintColor = Color(pulse, pulse, 255)

    -- Рисуем клавишу [E]
    local keyText = "[E]"
    local mainText = " — Арестовать преступника"

    surface.SetFont("ZGrad_Arrest_Hint_Key")
    local keyW = surface.GetTextSize(keyText)
    surface.SetFont("ZGrad_Arrest_Hint")
    local mainW = surface.GetTextSize(mainText)
    local totalW = keyW + mainW
    local startX = scrW / 2 - totalW / 2

    draw.SimpleText(keyText, "ZGrad_Arrest_Hint_Key", startX, hintY + hintH / 2, COLORS.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(mainText, "ZGrad_Arrest_Hint", startX + keyW, hintY + hintH / 2, hintColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end)

print("[Z-Grad RP] Arrest System (Client) Loaded")

--[[---------------------------------------------------------------------------
Z-Grad RP — Система Мэра (Клиент)
Кнопки в С-меню + HUD законов + меню управления
---------------------------------------------------------------------------]]

-- =============================================
-- Шрифты
-- =============================================
surface.CreateFont("ZGrad_Mayor_Title", { font = "Roboto", size = 22, weight = 700, antialias = true })
surface.CreateFont("ZGrad_Mayor_Sub", { font = "Roboto", size = 16, weight = 600, antialias = true })
surface.CreateFont("ZGrad_Mayor_Text", { font = "Roboto", size = 14, weight = 500, antialias = true })
surface.CreateFont("ZGrad_Mayor_Small", { font = "Roboto", size = 13, weight = 400, antialias = true })
surface.CreateFont("ZGrad_Mayor_LawHUD", { font = "Roboto", size = 14, weight = 500, antialias = true })
-- Global Lockdown State
local ZGrad_LockdownActive = false
local ZGrad_LockdownCooldown = 0
local ZGrad_LockdownEndTime = 0

-- =============================================
-- Цвета (стиль F4/Tab)
-- =============================================
local C = {
    bg          = Color(16, 16, 22, 250),
    panel       = Color(22, 22, 30, 255),
    card        = Color(28, 28, 40, 255),
    cardHover   = Color(35, 35, 50, 255),
    accent      = Color(0, 180, 255, 255),
    accentDark  = Color(0, 120, 200, 255),
    green       = Color(0, 160, 80, 255),
    greenHov    = Color(0, 200, 100, 255),
    red         = Color(180, 50, 50, 255),
    redHov      = Color(220, 70, 70, 255),
    orange      = Color(220, 150, 30, 255),
    text        = Color(220, 220, 235, 255),
    textDim     = Color(130, 130, 155, 255),
    separator   = Color(40, 40, 55, 255),
    money       = Color(100, 220, 100, 255),
}

-- =============================================
-- Утилиты
-- =============================================
local function StyledScrollbar(scroll)
    local sb = scroll:GetVBar()
    sb:SetWide(4)
    sb.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(25, 25, 35)) end
    sb.btnUp.Paint = function() end
    sb.btnDown.Paint = function() end
    sb.btnGrip.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, C.accent) end
end

local function MakeButton(parent, text, color, hoverColor, callback)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetTall(38)
    btn:Dock(TOP)
    btn:DockMargin(8, 4, 8, 4)

    local hover = false
    btn.OnCursorEntered = function() hover = true end
    btn.OnCursorExited = function() hover = false end

    btn.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, hover and hoverColor or color)
        draw.SimpleText(text, "ZGrad_Mayor_Sub", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        callback()
    end

    return btn
end

-- =============================================
-- Законы (хранятся локально, обновляются с сервера)
-- =============================================
local ZGrad_ClientLaws = {}

net.Receive("ZGrad_Mayor_LawsUpdate", function()
    local count = net.ReadUInt(8)
    ZGrad_ClientLaws = {}
    for i = 1, count do
        table.insert(ZGrad_ClientLaws, net.ReadString())
    end
end)

-- Запросить законы при входе
hook.Add("InitPostEntity", "ZGrad_Mayor_RequestLaws", function()
    timer.Simple(5, function()
        net.Start("ZGrad_Mayor_RequestLaws")
        net.SendToServer()
    end)
end)

-- Запрос при ручном обновлении файла (горячая перезагрузка)
net.Start("ZGrad_Mayor_RequestLaws")
net.SendToServer()

-- Обновление зарплат (синхронизация с сервером)
net.Receive("ZGrad_Mayor_UpdateSalaries", function()
    local count = net.ReadUInt(8)
    for i = 1, count do
        local teamID = net.ReadUInt(16)
        local salary = net.ReadUInt(16)
        if RPExtraTeams and RPExtraTeams[teamID] then
            RPExtraTeams[teamID].salary = salary
        end
    end
end)

-- =============================================
-- HUD Законов (верх экрана, виден всем в С-меню)
-- =============================================
local ZGrad_LawsPanel = nil

local function ShowLawsPanel()
    if IsValid(ZGrad_LawsPanel) then return end
    if not ZGrad_ClientLaws or #ZGrad_ClientLaws == 0 then return end

    local sw = ScrW()
    local maxW = 350
    local lineH = 20
    local padTop = 12
    local padSide = 16
    local headerH = 32

    local totalH = headerH + padTop + (#ZGrad_ClientLaws * lineH) + 10

    local x = sw / 2 - maxW / 2
    local y = 10

    ZGrad_LawsPanel = vgui.Create("DPanel")
    ZGrad_LawsPanel:SetPos(x, y)
    ZGrad_LawsPanel:SetSize(maxW, totalH)
    -- Панель не должна перехватывать клики
    ZGrad_LawsPanel:SetMouseInputEnabled(false)

    ZGrad_LawsPanel.Paint = function(self, w, h)
        -- Фон
        draw.RoundedBox(10, 0, 0, w, h, Color(16, 16, 22, 240))
        -- Акцент сверху
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        -- Контур
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- Заголовок
        draw.SimpleText("⚖ ЗАКОНЫ ГОРОДА", "ZGrad_Mayor_Sub", w / 2, headerH / 2 + 4, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Разделитель
        surface.SetDrawColor(C.separator)
        surface.DrawRect(10, headerH, w - 20, 1)

        -- Законы
        for i, law in ipairs(ZGrad_ClientLaws) do
            local ly = headerH + padTop + (i - 1) * lineH
            draw.SimpleText(i .. ". " .. law, "ZGrad_Mayor_LawHUD", padSide, ly, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
end

local function HideLawsPanel()
    if IsValid(ZGrad_LawsPanel) then
        ZGrad_LawsPanel:Remove()
        ZGrad_LawsPanel = nil
    end
end

-- Отслеживаем статус кастомного C-меню через Think
hook.Add("Think", "ZGrad_Mayor_LawsTracker", function()
    if IsValid(G_ZGradContextMenu) then
        ShowLawsPanel()
    else
        HideLawsPanel()
    end
end)

-- =============================================
-- Выбор игрока (универсальное окно)
-- =============================================
local function OpenPlayerListMenu(title, action, onSelect)
    net.Start("ZGrad_Mayor_GetPlayers")
        net.WriteString(action)
    net.SendToServer()

    -- Ждём ответ с сервера
    net.Receive("ZGrad_Mayor_GetPlayers", function()
        local respAction = net.ReadString()
        if respAction ~= action then return end

        local count = net.ReadUInt(8)
        local players = {}
        for i = 1, count do
            table.insert(players, {
                ent  = net.ReadEntity(),
                nick = net.ReadString(),
                job  = net.ReadString(),
            })
        end

        -- Создаём окно
        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(380, math.min(100 + count * 50, 500))
        frame:Center()
        frame:MakePopup()
        frame:ShowCloseButton(false)
        frame:SetDraggable(false)

        frame.Paint = function(_, w, h)
            draw.RoundedBox(10, 0, 0, w, h, C.bg)
            draw.RoundedBoxEx(10, 0, 0, w, 44, C.panel, true, true, false, false)
            draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
            draw.SimpleText(title, "ZGrad_Mayor_Title", w / 2, 24, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        -- Кнопка закрытия
        local closeBtn = vgui.Create("DButton", frame)
        closeBtn:SetSize(30, 30)
        closeBtn:SetPos(frame:GetWide() - 38, 7)
        closeBtn:SetText("")
        local cHov = false
        closeBtn.OnCursorEntered = function() cHov = true end
        closeBtn.OnCursorExited = function() cHov = false end
        closeBtn.Paint = function(_, w, h)
            if cHov then draw.RoundedBox(15, 0, 0, w, h, C.red) end
            draw.SimpleText("✕", "ZGrad_Mayor_Sub", w/2, h/2, cHov and Color(255,255,255) or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        closeBtn.DoClick = function() frame:Remove() end

        if count == 0 then
            local lbl = vgui.Create("DLabel", frame)
            lbl:SetPos(0, 60)
            lbl:SetSize(380, 30)
            lbl:SetText("Нет подходящих игроков")
            lbl:SetFont("ZGrad_Mayor_Text")
            lbl:SetTextColor(C.textDim)
            lbl:SetContentAlignment(5)
            return
        end

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:SetPos(0, 50)
        scroll:SetSize(380, frame:GetTall() - 55)
        StyledScrollbar(scroll)

        for _, pData in ipairs(players) do
            local card = vgui.Create("DButton", scroll)
            card:Dock(TOP)
            card:DockMargin(8, 4, 8, 4)
            card:SetTall(42)
            card:SetText("")

            local hov = false
            card.OnCursorEntered = function() hov = true end
            card.OnCursorExited = function() hov = false end

            card.Paint = function(_, w, h)
                draw.RoundedBox(6, 0, 0, w, h, hov and C.cardHover or C.card)
                draw.RoundedBox(3, 2, 4, 4, h - 8, C.accent)
                draw.SimpleText(pData.nick, "ZGrad_Mayor_Sub", 16, 8, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(pData.job, "ZGrad_Mayor_Small", 16, 25, C.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            card.DoClick = function()
                surface.PlaySound("ui/buttonclickrelease.wav")
                frame:Remove()
                onSelect(pData)
            end
        end
    end)
end

-- =============================================
-- Меню "Управление городом"
-- =============================================
local function OpenCityManagement()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(550, 500)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)

    frame.Paint = function(_, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Заголовок
    local header = vgui.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(50)
    header.Paint = function(_, w, h)
        draw.RoundedBoxEx(10, 0, 0, w, h, C.panel, true, true, false, false)
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        draw.SimpleText("🏛 УПРАВЛЕНИЕ ГОРОДОМ", "ZGrad_Mayor_Title", w / 2, h / 2 + 2, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Кнопка закрытия
    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetSize(30, 30)
    closeBtn:Dock(RIGHT)
    closeBtn:DockMargin(0, 8, 8, 8)
    closeBtn:SetText("")
    local cHov = false
    closeBtn.OnCursorEntered = function() cHov = true end
    closeBtn.OnCursorExited = function() cHov = false end
    closeBtn.Paint = function(_, w, h)
        if cHov then draw.RoundedBox(15, 0, 0, w, h, C.red) end
        draw.SimpleText("✕", "ZGrad_Mayor_Sub", w/2, h/2, cHov and Color(255,255,255) or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Remove() end

    -- Вкладки
    local tabBar = vgui.Create("DPanel", frame)
    tabBar:Dock(TOP)
    tabBar:SetTall(40)
    tabBar:DockMargin(0, 0, 0, 0)
    tabBar.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, C.panel)
        surface.SetDrawColor(C.separator)
        surface.DrawRect(0, h - 1, w, 1)
    end

    local contentPanel = vgui.Create("DPanel", frame)
    contentPanel:Dock(FILL)
    contentPanel.Paint = function() end

    local tabs = {}
    local activeTab = nil
    local currentTabName = ""

    local function SwitchTab(name)
        if activeTab then activeTab:SetVisible(false) end
        if tabs[name] then
            tabs[name]:SetVisible(true)
            activeTab = tabs[name]
            currentTabName = name
        end
    end

    -- ===== TAB: УВОЛИТЬ =====
    local firePanel = vgui.Create("DPanel", contentPanel)
    firePanel:Dock(FILL)
    firePanel:DockMargin(5, 5, 5, 5)
    firePanel.Paint = function() end
    firePanel:SetVisible(false)
    tabs["Уволить"] = firePanel

    local fireInfo = vgui.Create("DLabel", firePanel)
    fireInfo:Dock(TOP)
    fireInfo:DockMargin(10, 10, 10, 5)
    fireInfo:SetTall(25)
    fireInfo:SetText("Выберите сотрудника Полиции или ФБР для увольнения:")
    fireInfo:SetFont("ZGrad_Mayor_Text")
    fireInfo:SetTextColor(C.textDim)

    MakeButton(firePanel, "👮 Показать сотрудников", C.accentDark, C.accent, function()
        frame:Remove()
        OpenPlayerListMenu("УВОЛИТЬ СОТРУДНИКА", "fire", function(pData)
            -- Запросить причину
            Derma_StringRequest("Увольнение: " .. pData.nick, "Укажите причину увольнения:", "", function(reason)
                if reason == "" then reason = "Без причины" end
                net.Start("ZGrad_Mayor_Fire")
                    net.WriteEntity(pData.ent)
                    net.WriteString(reason)
                net.SendToServer()
            end)
        end)
    end)

    -- ===== TAB: ЗАРПЛАТЫ =====
    local salaryPanel = vgui.Create("DPanel", contentPanel)
    salaryPanel:Dock(FILL)
    salaryPanel:DockMargin(5, 5, 5, 5)
    salaryPanel.Paint = function() end
    salaryPanel:SetVisible(false)
    tabs["Зарплаты"] = salaryPanel

    -- Запрашиваем данные зарплат
    net.Start("ZGrad_Mayor_GetPlayers")
        net.WriteString("salaries")
    net.SendToServer()

    local salaryEditors = {}
    local salaryScroll = vgui.Create("DScrollPanel", salaryPanel)
    salaryScroll:Dock(FILL)
    salaryScroll:DockMargin(5, 5, 5, 45)
    StyledScrollbar(salaryScroll)

    local totalLabel = vgui.Create("DLabel", salaryPanel)
    totalLabel:Dock(BOTTOM)
    totalLabel:SetTall(22)
    totalLabel:DockMargin(10, 0, 10, 0)
    totalLabel:SetText("Общая сумма: $0 / $500")
    totalLabel:SetFont("ZGrad_Mayor_Text")
    totalLabel:SetTextColor(C.orange)
    totalLabel:SetContentAlignment(5)

    local saveSalBtn = MakeButton(salaryPanel, "💾 Сохранить зарплаты", C.green, C.greenHov, function()
        local data = {}
        local total = 0
        for teamID, editor in pairs(salaryEditors) do
            local val = tonumber(editor:GetValue()) or 0
            table.insert(data, { teamID = teamID, salary = val })
            total = total + val
        end
        if total > 500 then
            Derma_Message("Общая сумма зарплат не может превышать $500!", "Ошибка", "OK")
            return
        end
        net.Start("ZGrad_Mayor_SetSalary")
            net.WriteUInt(#data, 8)
            for _, d in ipairs(data) do
                net.WriteUInt(d.teamID, 16)
                net.WriteUInt(d.salary, 16)
            end
        net.SendToServer()
        frame:Remove()
    end)
    saveSalBtn:Dock(BOTTOM)
    saveSalBtn:DockMargin(8, 4, 8, 8)

    -- Обработчик данных зарплат
    net.Receive("ZGrad_Mayor_GetPlayers", function()
        local respAction = net.ReadString()
        if respAction == "salaries" then
            local cnt = net.ReadUInt(8)
            for i = 1, cnt do
                local teamID = net.ReadUInt(16)
                local name = net.ReadString()
                local salary = net.ReadUInt(16)
                local category = net.ReadString()

                local row = vgui.Create("DPanel", salaryScroll)
                row:Dock(TOP)
                row:DockMargin(5, 3, 5, 3)
                row:SetTall(36)
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, C.card)
                    draw.SimpleText(name, "ZGrad_Mayor_Text", 12, h/2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(category, "ZGrad_Mayor_Small", w - 100, h/2, C.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                local editor = vgui.Create("DNumberWang", row)
                editor:SetPos(row:GetWide() - 90, 4)
                editor:SetSize(70, 28)
                editor:SetMin(0)
                editor:SetMax(500)
                editor:SetValue(salary)
                editor:SetFont("ZGrad_Mayor_Text")
                salaryEditors[teamID] = editor

                row.PerformLayout = function(_, w, h)
                    editor:SetPos(w - 90, 4)
                end

                editor.OnValueChanged = function()
                    local total = 0
                    for _, ed in pairs(salaryEditors) do
                        total = total + (tonumber(ed:GetValue()) or 0)
                    end
                    if IsValid(totalLabel) then
                        totalLabel:SetText("Общая сумма: $" .. total .. " / $500")
                        totalLabel:SetTextColor(total > 500 and C.red or C.money)
                    end
                end
            end

        elseif respAction == "laws" then
            -- Обработка законов для вкладки
            local cnt = net.ReadUInt(8)
            local laws = {}
            for i = 1, cnt do
                table.insert(laws, net.ReadString())
            end
            PopulateLawsTab(laws)
        end
    end)

    -- ===== TAB: ЗАКОНЫ =====
    local lawsPanel = vgui.Create("DPanel", contentPanel)
    lawsPanel:Dock(FILL)
    lawsPanel:DockMargin(5, 5, 5, 5)
    lawsPanel.Paint = function() end
    lawsPanel:SetVisible(false)
    tabs["Законы"] = lawsPanel

    local lawEntries = {}

    local lawScroll = vgui.Create("DScrollPanel", lawsPanel)
    lawScroll:Dock(FILL)
    lawScroll:DockMargin(5, 5, 5, 50)
    StyledScrollbar(lawScroll)

    local function AddLawEntry(text)
        local row = vgui.Create("DPanel", lawScroll)
        row:Dock(TOP)
        row:DockMargin(5, 3, 5, 3)
        row:SetTall(34)
        row.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.card)
        end

        local entry = vgui.Create("DTextEntry", row)
        entry:SetPos(10, 4)
        entry:SetSize(400, 26)
        entry:SetText(text or "")
        entry:SetFont("ZGrad_Mayor_Text")
        entry:SetTextColor(C.text)
        entry:SetPaintBackground(false)

        local delBtn = vgui.Create("DButton", row)
        delBtn:SetSize(26, 26)
        delBtn:SetText("")
        local dHov = false
        delBtn.OnCursorEntered = function() dHov = true end
        delBtn.OnCursorExited = function() dHov = false end
        delBtn.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, dHov and C.redHov or C.red)
            draw.SimpleText("✕", "ZGrad_Mayor_Small", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        delBtn.DoClick = function()
            for k, v in ipairs(lawEntries) do
                if v.row == row then
                    table.remove(lawEntries, k)
                    break
                end
            end
            row:Remove()
            surface.PlaySound("ui/buttonclickrelease.wav")
        end

        row.PerformLayout = function(_, w, h)
            entry:SetSize(w - 55, 26)
            delBtn:SetPos(w - 35, 4)
        end

        table.insert(lawEntries, { row = row, entry = entry })
    end

    -- Кнопки снизу
    local lawBtnPanel = vgui.Create("DPanel", lawsPanel)
    lawBtnPanel:Dock(BOTTOM)
    lawBtnPanel:SetTall(44)
    lawBtnPanel.Paint = function() end

    local addBtn = vgui.Create("DButton", lawBtnPanel)
    addBtn:SetSize(130, 36)
    addBtn:SetPos(8, 4)
    addBtn:SetText("")
    local aHov = false
    addBtn.OnCursorEntered = function() aHov = true end
    addBtn.OnCursorExited = function() aHov = false end
    addBtn.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, aHov and C.accent or C.accentDark)
        draw.SimpleText("+ Добавить закон", "ZGrad_Mayor_Text", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addBtn.DoClick = function()
        AddLawEntry("")
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    local saveBtn = vgui.Create("DButton", lawBtnPanel)
    saveBtn:SetSize(130, 36)
    saveBtn:SetText("")
    local sHov = false
    saveBtn.OnCursorEntered = function() sHov = true end
    saveBtn.OnCursorExited = function() sHov = false end
    saveBtn.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, sHov and C.greenHov or C.green)
        draw.SimpleText("💾 Сохранить", "ZGrad_Mayor_Text", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    saveBtn.DoClick = function()
        local newLaws = {}
        for _, le in ipairs(lawEntries) do
            if IsValid(le.entry) then
                local txt = le.entry:GetValue()
                if txt and txt ~= "" then
                    table.insert(newLaws, txt)
                end
            end
        end
        net.Start("ZGrad_Mayor_SaveLaws")
            net.WriteUInt(#newLaws, 8)
            for _, l in ipairs(newLaws) do
                net.WriteString(l)
            end
        net.SendToServer()
        frame:Remove()
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    local cancelBtn = vgui.Create("DButton", lawBtnPanel)
    cancelBtn:SetSize(100, 36)
    cancelBtn:SetText("")
    local canHov = false
    cancelBtn.OnCursorEntered = function() canHov = true end
    cancelBtn.OnCursorExited = function() canHov = false end
    cancelBtn.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, canHov and C.redHov or C.red)
        draw.SimpleText("Отмена", "ZGrad_Mayor_Text", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    cancelBtn.DoClick = function()
        frame:Remove()
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    lawBtnPanel.PerformLayout = function(_, w, h)
        addBtn:SetPos(8, 4)
        saveBtn:SetPos(w - 248, 4)
        cancelBtn:SetPos(w - 108, 4)
    end

    -- Запрашиваем текущие законы
    function PopulateLawsTab(laws)
        for _, law in ipairs(laws) do
            AddLawEntry(law)
        end
    end

    net.Start("ZGrad_Mayor_GetPlayers")
        net.WriteString("laws")
    net.SendToServer()

    -- ===== TAB: УПРАВЛЕНИЕ =====
    local managePanel = vgui.Create("DPanel", contentPanel)
    managePanel:Dock(FILL)
    managePanel:DockMargin(5, 5, 5, 5)
    managePanel.Paint = function() end
    managePanel:SetVisible(false)
    tabs["Управление"] = managePanel

    local announceLabel = vgui.Create("DLabel", managePanel)
    announceLabel:Dock(TOP)
    announceLabel:DockMargin(10, 10, 10, 5)
    announceLabel:SetTall(25)
    announceLabel:SetText("Сделать объявление:")
    announceLabel:SetFont("ZGrad_Mayor_Text")
    announceLabel:SetTextColor(C.textDim)

    local announceEntry = vgui.Create("DTextEntry", managePanel)
    announceEntry:Dock(TOP)
    announceEntry:DockMargin(10, 0, 10, 10)
    announceEntry:SetTall(30)
    announceEntry:SetFont("ZGrad_Mayor_Text")
    announceEntry:SetTextColor(C.text)
    announceEntry:SetPaintBackground(false)
    announceEntry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, C.card)
        self:DrawTextEntryText(C.text, C.accent, C.text)
    end

    MakeButton(managePanel, "📢 Отправить", C.accentDark, C.accent, function()
        local txt = announceEntry:GetValue()
        if txt and txt ~= "" then
            net.Start("ZGrad_Mayor_DoAnnouncement")
                net.WriteString(txt)
            net.SendToServer()
            announceEntry:SetText("")
        end
    end)

    local lockdownLabel = vgui.Create("DLabel", managePanel)
    lockdownLabel:Dock(TOP)
    lockdownLabel:DockMargin(10, 20, 10, 5)
    lockdownLabel:SetTall(25)
    lockdownLabel:SetText("Комендантский час:")
    lockdownLabel:SetFont("ZGrad_Mayor_Text")
    lockdownLabel:SetTextColor(C.textDim)

    local btnLockdown = MakeButton(managePanel, "🛑 Объявить КЧ", C.red, C.redHov, function()
        if ZGrad_LockdownActive then
            -- Если уже идет, просто выключаем
            net.Start("ZGrad_Mayor_ToggleLockdown")
                net.WriteUInt(0, 8) 
            net.SendToServer()
        else
            -- Если не идет, предлагаем выбор
            Derma_Query("Выберите длительность комендантского часа:", "Объявить КЧ",
                "1 минута", function() 
                    net.Start("ZGrad_Mayor_ToggleLockdown")
                        net.WriteUInt(1, 8)
                    net.SendToServer()
                end,
                "2 минуты", function()
                    net.Start("ZGrad_Mayor_ToggleLockdown")
                        net.WriteUInt(2, 8)
                    net.SendToServer()
                end,
                "3 минуты", function()
                    net.Start("ZGrad_Mayor_ToggleLockdown")
                        net.WriteUInt(3, 8)
                    net.SendToServer()
                end,
                "Отмена"
            )
        end
    end)

    local function UpdateLockdownButton()
        if not IsValid(btnLockdown) then return end
        if ZGrad_LockdownActive then
            btnLockdown.Paint = function(_, w, h)
                draw.RoundedBox(6, 0, 0, w, h, C.orange)
                draw.SimpleText("🔓 Закончить КЧ", "ZGrad_Mayor_Sub", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        else
            btnLockdown.Paint = function(_, w, h)
                local col = C.red
                local txt = "🛑 Объявить КЧ"
                local left = ZGrad_LockdownCooldown - CurTime()
                local hov = btnLockdown:IsHovered()
                if left > 0 then
                    col = Color(100, 100, 100)
                    txt = "⏳ КД КЧ: " .. math.ceil(left) .. " сек."
                elseif hov then
                    col = C.redHov
                end
                draw.RoundedBox(6, 0, 0, w, h, col)
                draw.SimpleText(txt, "ZGrad_Mayor_Sub", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    hook.Add("Think", "ZGrad_Mayor_LockdownBTNthink", function()
        if IsValid(btnLockdown) then UpdateLockdownButton() end
    end)

    net.Start("ZGrad_Mayor_RequestLockdownState")
    net.SendToServer()

    -- ===== КНОПКИ ВКЛАДОК =====
    local tabNames = {"Управление", "Уволить", "Зарплаты", "Законы"}
    local tabIcons = {"⚙", "🔫", "💰", "📜"}
    local tabBtns = {}

    for idx, tName in ipairs(tabNames) do
        local tbtn = vgui.Create("DButton", tabBar)
        tbtn:SetText("")
        tbtn:SetWide(frame:GetWide() / #tabNames)
        tbtn:Dock(LEFT)

        local tHov = false
        tbtn.OnCursorEntered = function() tHov = true end
        tbtn.OnCursorExited = function() tHov = false end

        tbtn.Paint = function(_, w, h)
            local isActive = (currentTabName == tName)
            if isActive then
                draw.RoundedBox(0, 0, 0, w, h, Color(C.accent.r, C.accent.g, C.accent.b, 30))
                surface.SetDrawColor(C.accent)
                surface.DrawRect(0, h - 3, w, 3)
            elseif tHov then
                draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 55, 200))
            end
            local textCol = isActive and C.accent or (tHov and C.text or C.textDim)
            draw.SimpleText(tabIcons[idx] .. " " .. tName, "ZGrad_Mayor_Sub", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        tbtn.DoClick = function()
            SwitchTab(tName)
            surface.PlaySound("ui/buttonclick.wav")
        end

        table.insert(tabBtns, tbtn)
    end

    SwitchTab("Управление")
end

-- =============================================
-- Выдача лицензии
-- =============================================
local function OpenGrantLicense()
    OpenPlayerListMenu("ВЫДАТЬ ЛИЦЕНЗИЮ", "license_grant", function(pData)
        net.Start("ZGrad_Mayor_License")
            net.WriteEntity(pData.ent)
            net.WriteBool(true)
        net.SendToServer()
    end)
end

local function OpenRevokeLicense()
    OpenPlayerListMenu("ЗАБРАТЬ ЛИЦЕНЗИЮ", "license_revoke", function(pData)
        net.Start("ZGrad_Mayor_License")
            net.WriteEntity(pData.ent)
            net.WriteBool(false)
        net.SendToServer()
    end)
end

-- =============================================
-- Экспорт кнопок для С-меню
-- =============================================
ZGrad_MayorButtons = {
    { text = "Выдать лицензию",    icon = "🪪", color = Color(0, 160, 80),  callback = OpenGrantLicense },
    { text = "Забрать лицензию",   icon = "🚫", color = Color(180, 50, 50), callback = OpenRevokeLicense },
    { text = "Управление городом", icon = "🏛",  color = Color(0, 120, 200), callback = OpenCityManagement },
}

-- =============================================
-- HUD Объявлений Мэра
-- =============================================
local AnnounceMsg = ""
local AnnounceAlpha = 0
local AnnounceEndTime = 0

net.Receive("ZGrad_Mayor_Announcement", function()
    AnnounceMsg = net.ReadString()
    AnnounceAlpha = 0
    AnnounceEndTime = CurTime() + 10 -- Показывать 10 секунд
    surface.PlaySound("buttons/blip1.wav")
end)

net.Receive("ZGrad_Mayor_LockdownState", function()
    local newState = net.ReadBool()
    ZGrad_LockdownCooldown = net.ReadFloat()
    ZGrad_LockdownEndTime = net.ReadFloat()

    if newState ~= ZGrad_LockdownActive then
        local soundPath = newState and "ambient/alarms/klaxon1.wav" or "buttons/bell1.wav"
        
        timer.Simple(0.1, function()
            surface.PlaySound(soundPath)
            if IsValid(LocalPlayer()) then
                LocalPlayer():EmitSound(soundPath, 100, 100)
            end
        end)
    end
    ZGrad_LockdownActive = newState
end)

hook.Add("HUDPaint", "ZGrad_Mayor_DrawHUD", function()
    local yPos = 20
    
    -- HUD Комендантского часа
    if ZGrad_LockdownActive then
        local life = ZGrad_LockdownEndTime - CurTime()
        local isInfinite = (ZGrad_LockdownEndTime == 0)

        if life > 0 or isInfinite then
            local w, h = 400, 60
            local x = ScrW() / 2 - w / 2
            
            draw.RoundedBox(10, x, yPos, w, h, Color(16, 16, 22, 240))
            draw.RoundedBoxEx(10, x, yPos, w, 4, Color(200, 50, 50, 255), true, true, false, false)
            surface.SetDrawColor(200, 50, 50, 40)
            surface.DrawOutlinedRect(x, yPos, w, h, 1)
            
            local timeStr = ""
            if isInfinite then
                timeStr = "ДО ЗАВЕРШЕНИЯ ПЕРЕВОРОТА"
            else
                local mins = math.floor(life / 60)
                local secs = math.floor(life % 60)
                timeStr = string.format("ДО ЗАВЕРШЕНИЯ: %02d:%02d", mins, secs)
            end
            
            draw.SimpleText("КОМЕНДАНТСКИЙ ЧАС", "ZGrad_Mayor_Sub", ScrW() / 2, yPos + 15, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(timeStr, isInfinite and "ZGrad_Mayor_Sub" or "ZGrad_Mayor_Title", ScrW() / 2, yPos + 38, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            yPos = yPos + 70
        end
    end

    -- HUD Объявлений
    if AnnounceAlpha > 0 or CurTime() < AnnounceEndTime then
        if CurTime() < AnnounceEndTime then
            AnnounceAlpha = math.Approach(AnnounceAlpha, 255, FrameTime() * 400)
        else
            AnnounceAlpha = math.Approach(AnnounceAlpha, 0, FrameTime() * 200)
        end
        
        if AnnounceAlpha > 0 then
            surface.SetFont("ZGrad_Mayor_Title")
            local tw, th = surface.GetTextSize(AnnounceMsg)
            local w = math.max(tw + 80, 400)
            local h = 60
            local x = ScrW() / 2 - w / 2
            
            draw.RoundedBox(10, x, yPos, w, h, Color(16, 16, 22, AnnounceAlpha * 0.9))
            draw.RoundedBoxEx(10, x, yPos, w, 4, Color(C.accent.r, C.accent.g, C.accent.b, AnnounceAlpha), true, true, false, false)
            surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, math.min(AnnounceAlpha, 40))
            surface.DrawOutlinedRect(x, yPos, w, h, 1)
            
            draw.SimpleText("ОБЪЯВЛЕНИЕ МЭРА", "ZGrad_Mayor_Sub", ScrW() / 2, yPos + 15, Color(C.accent.r, C.accent.g, C.accent.b, AnnounceAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(AnnounceMsg, "ZGrad_Mayor_Title", ScrW() / 2, yPos + 38, Color(255, 255, 255, AnnounceAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)

print("[Z-Grad RP] Mayor System (Client) Loaded")

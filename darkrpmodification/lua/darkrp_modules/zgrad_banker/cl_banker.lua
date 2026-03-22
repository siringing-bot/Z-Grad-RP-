--[[---------------------------------------------------------------------------
Z-Grad RP — Banker System (Client)
Меню банкира + Ответ на кредит
---------------------------------------------------------------------------]]

-- Шрифты и Цвета
surface.CreateFont("ZGrad_Banker_Title", { font = "Roboto", size = 22, weight = 700, antialias = true })
surface.CreateFont("ZGrad_Banker_Sub", { font = "Roboto", size = 16, weight = 600, antialias = true })
surface.CreateFont("ZGrad_Banker_Text", { font = "Roboto", size = 14, weight = 500, antialias = true })

local C = {
    bg          = Color(16, 16, 22, 250),
    panel       = Color(22, 22, 30, 255),
    card        = Color(28, 28, 40, 255),
    accent      = Color(120, 200, 50, 255),
    green       = Color(0, 160, 80, 255),
    greenHov    = Color(0, 200, 100, 255),
    red         = Color(180, 50, 50, 255),
    redHov      = Color(220, 70, 70, 255),
    text        = Color(220, 220, 235, 255),
    textDim     = Color(130, 130, 155, 255),
}

-- =============================================
-- Меню отправки предложения (для банкира)
-- =============================================
local function OpenIssueLoan()
    local ply = LocalPlayer()
    local target = ply:GetEyeTrace().Entity

    if not IsValid(target) or not target:IsPlayer() then
        Derma_Message("Вам нужно смотреть на игрока!", "Ошибка", "OK")
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(350, 320)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(10, 0, 0, w, 44, C.panel, true, true, false, false)
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        draw.SimpleText("Выдача кредита: " .. target:Nick(), "ZGrad_Banker_Sub", w/2, 24, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 38, 7)
    closeBtn:SetText("")
    local cHov = false
    closeBtn.OnCursorEntered = function() cHov = true end
    closeBtn.OnCursorExited = function() cHov = false end
    closeBtn.Paint = function(self, w, h)
        if cHov then draw.RoundedBox(15, 0, 0, w, h, C.red) end
        draw.SimpleText("✕", "ZGrad_Banker_Sub", w/2, h/2, cHov and Color(255,255,255) or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Remove() end

    -- Поля ввода
    local y = 60
    local function AddInputRow(label, defaultVal)
        local lbl = vgui.Create("DLabel", frame)
        lbl:SetPos(20, y)
        lbl:SetSize(120, 30)
        lbl:SetText(label)
        lbl:SetFont("ZGrad_Banker_Text")
        lbl:SetTextColor(C.text)

        local entry = vgui.Create("DNumberWang", frame)
        entry:SetPos(150, y)
        entry:SetSize(170, 30)
        entry:SetMin(1)
        entry:SetMax(100000)
        entry:SetValue(defaultVal)
        entry:SetFont("ZGrad_Banker_Text")

        y = y + 45
        return entry
    end

    local entryAmount = AddInputRow("Сумма ($):", 500)
    local entryPercent = AddInputRow("Процент (%):", 10)
    local entryTime = AddInputRow("Срок (минуты):", 15)

    local lblHint = vgui.Create("DLabel", frame)
    lblHint:SetPos(20, y)
    lblHint:SetSize(310, 40)
    lblHint:SetText("Деньги будут списываться с должника каждые 5 мин.\nНапример: 15 минут = 3 списания.")
    lblHint:SetFont("ZGrad_Banker_Text")
    lblHint:SetTextColor(C.textDim)
    lblHint:SetWrap(true)

    local btnSend = vgui.Create("DButton", frame)
    btnSend:SetSize(310, 40)
    btnSend:SetPos(20, frame:GetTall() - 55)
    btnSend:SetText("")
    local bHov = false
    btnSend.OnCursorEntered = function() bHov = true end
    btnSend.OnCursorExited = function() bHov = false end
    btnSend.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, bHov and C.greenHov or C.green)
        draw.SimpleText("Предложить кредит", "ZGrad_Banker_Sub", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnSend.DoClick = function()
        net.Start("ZGrad_Banker_Offer")
            net.WriteEntity(target)
            net.WriteUInt(tonumber(entryAmount:GetValue()) or 500, 32)
            net.WriteUInt(tonumber(entryPercent:GetValue()) or 10, 16)
            net.WriteUInt(tonumber(entryTime:GetValue()) or 15, 16)
        net.SendToServer()
        frame:Remove()
        surface.PlaySound("ui/buttonclickrelease.wav")
    end
end

-- =============================================
-- Окно решения (Для Игрока)
-- =============================================
net.Receive("ZGrad_Banker_Offer", function()
    local banker = net.ReadEntity()
    local amount = net.ReadUInt(32)
    local percent = net.ReadUInt(16)
    local timeMin = net.ReadUInt(16)

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(400, 320)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(10, 0, 0, w, 44, C.panel, true, true, false, false)
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        draw.SimpleText("Вам предлагают кредит!", "ZGrad_Banker_Title", w/2, 24, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local y = 65
    local function AddTextRow(label, val)
        local lbl = vgui.Create("DLabel", frame)
        lbl:SetPos(30, y)
        lbl:SetSize(160, 30)
        lbl:SetText(label)
        lbl:SetFont("ZGrad_Banker_Sub")
        lbl:SetTextColor(C.textDim)

        local vLbl = vgui.Create("DLabel", frame)
        vLbl:SetPos(180, y)
        vLbl:SetSize(190, 30)
        vLbl:SetText(val)
        vLbl:SetFont("ZGrad_Banker_Sub")
        vLbl:SetTextColor(C.text)

        y = y + 40
    end

    AddTextRow("Банкир:", IsValid(banker) and banker:Nick() or "Неизвестно")
    AddTextRow("Сумма:", "$" .. amount)
    AddTextRow("Процентная ставка:", percent .. "%")
    AddTextRow("Срок:", timeMin .. " минут")

    local total = amount + math.floor(amount * (percent / 100))
    local ticks = math.max(1, math.floor(timeMin / 5))
    local perTick = math.ceil(total / ticks)

    local infoLbl = vgui.Create("DLabel", frame)
    infoLbl:SetPos(30, y)
    infoLbl:SetSize(340, 50)
    infoLbl:SetText("К возврату: $" .. total .. "\nБудет списано: $" .. perTick .. " (раз в 5 минут, " .. ticks .. " раз)")
    infoLbl:SetFont("ZGrad_Banker_Text")
    infoLbl:SetTextColor(C.accent)
    infoLbl:SetWrap(true)

    local btnAccept = vgui.Create("DButton", frame)
    btnAccept:SetSize(160, 40)
    btnAccept:SetPos(30, frame:GetTall() - 55)
    btnAccept:SetText("")
    local aHov = false
    btnAccept.OnCursorEntered = function() aHov = true end
    btnAccept.OnCursorExited = function() aHov = false end
    btnAccept.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, aHov and C.greenHov or C.green)
        draw.SimpleText("✅ Принять", "ZGrad_Banker_Sub", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnAccept.DoClick = function()
        net.Start("ZGrad_Banker_Respond")
            net.WriteEntity(banker)
            net.WriteBool(true)
            net.WriteUInt(amount, 32)
            net.WriteUInt(percent, 16)
            net.WriteUInt(timeMin, 16)
        net.SendToServer()
        frame:Remove()
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    local btnDecline = vgui.Create("DButton", frame)
    btnDecline:SetSize(160, 40)
    btnDecline:SetPos(210, frame:GetTall() - 55)
    btnDecline:SetText("")
    local dHov = false
    btnDecline.OnCursorEntered = function() dHov = true end
    btnDecline.OnCursorExited = function() dHov = false end
    btnDecline.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, dHov and C.redHov or C.red)
        draw.SimpleText("❌ Отклонить", "ZGrad_Banker_Sub", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnDecline.DoClick = function()
        net.Start("ZGrad_Banker_Respond")
            net.WriteEntity(banker)
            net.WriteBool(false)
            net.WriteUInt(0, 32)
            net.WriteUInt(0, 16)
            net.WriteUInt(0, 16)
        net.SendToServer()
        frame:Remove()
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

end)

-- =============================================
-- Меню управления должниками (Список)
-- =============================================
local function OpenDebtorsList(debts)
    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(450, 400)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(10, 0, 0, w, 44, C.panel, true, true, false, false)
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        draw.SimpleText("Список ваших должников", "ZGrad_Banker_Sub", w/2, 24, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 38, 7)
    closeBtn:SetText("")
    local cHov = false
    closeBtn.OnCursorEntered = function() cHov = true end
    closeBtn.OnCursorExited = function() cHov = false end
    closeBtn.Paint = function(self, w, h)
        if cHov then draw.RoundedBox(15, 0, 0, w, h, C.red) end
        draw.SimpleText("✕", "ZGrad_Banker_Sub", w/2, h/2, cHov and Color(255,255,255) or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Remove() end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(15, 10, 15, 15)

    -- Header row
    local header = scroll:Add("DPanel")
    header:Dock(TOP)
    header:SetTall(30)
    header.Paint = function(self, w, h)
        draw.SimpleText("Имя", "ZGrad_Banker_Text", 10, h/2, C.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Долг", "ZGrad_Banker_Text", w/2, h/2, C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Срок (сек)", "ZGrad_Banker_Text", w - 10, h/2, C.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    if #debts == 0 then
        local empty = scroll:Add("DLabel")
        empty:Dock(TOP)
        empty:SetTall(50)
        empty:SetText("У вас пока нет должников.")
        empty:SetFont("ZGrad_Banker_Text")
        empty:SetTextColor(C.textDim)
        empty:SetContentAlignment(5)
    end

    for _, data in ipairs(debts) do
        local row = scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 5, 0, 0)
        row:SetTall(45)
        row.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, C.card)
            draw.SimpleText(data.name, "ZGrad_Banker_Text", 15, h/2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("$" .. data.amount, "ZGrad_Banker_Sub", w/2, h/2, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Countdown simulation on client-side
            local timeLeft = math.max(0, math.floor(data.time - (CurTime() - (data.syncTime or CurTime()))))
            draw.SimpleText(timeLeft .. " с", "ZGrad_Banker_Text", w - 15, h/2, C.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        data.syncTime = CurTime()
    end
end

net.Receive("ZGrad_Banker_GetDebts", function()
    local debts = net.ReadTable()
    OpenDebtorsList(debts)
end)

-- =============================================
-- Экспорт для C-Меню
-- =============================================
ZGrad_BankerButtons = {
    { text = "Выдать кредит", icon = "💵", color = Color(120, 200, 50), callback = OpenIssueLoan },
    { text = "Мои должники", icon = "📜", color = Color(80, 180, 255), callback = function()
        net.Start("ZGrad_Banker_GetDebts")
        net.SendToServer()
        surface.PlaySound("ui/buttonclick.wav")
    end },
}

print("[Z-Grad RP] Banker System (Client) Loaded")

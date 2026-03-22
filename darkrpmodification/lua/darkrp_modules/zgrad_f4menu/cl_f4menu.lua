--[[---------------------------------------------------------------------------
Z-Grad RP — Custom F4 Menu
Тёмный современный стиль с вкладками: Профессии, Магазин, Информация
---------------------------------------------------------------------------]]

print("[Z-Grad RP] F4 Menu file LOADING...")

local F4MENU = nil

-- =============================================
-- ШРИФТЫ
-- =============================================
surface.CreateFont("ZGrad_F4Title", {
    font = "Roboto",
    size = 28,
    weight = 700,
})

surface.CreateFont("ZGrad_F4Tab", {
    font = "Roboto",
    size = 16,
    weight = 600,
})

surface.CreateFont("ZGrad_F4JobTitle", {
    font = "Roboto",
    size = 18,
    weight = 600,
})

surface.CreateFont("ZGrad_F4JobDesc", {
    font = "Roboto",
    size = 13,
    weight = 400,
})

surface.CreateFont("ZGrad_F4Info", {
    font = "Roboto",
    size = 15,
    weight = 400,
})

surface.CreateFont("ZGrad_F4Button", {
    font = "Roboto",
    size = 14,
    weight = 600,
})

surface.CreateFont("ZGrad_F4ShopItem", {
    font = "Roboto",
    size = 14,
    weight = 500,
})

-- =============================================
-- ЦВЕТА
-- =============================================
local C = {
    bg          = Color(16, 16, 22, 250),
    sidebar     = Color(22, 22, 30, 255),
    content     = Color(20, 20, 28, 255),
    tabActive   = Color(0, 160, 255, 255),
    tabInactive = Color(60, 60, 80, 255),
    tabHover    = Color(40, 40, 55, 255),
    accent      = Color(0, 180, 255, 255),
    accentDark  = Color(0, 120, 200, 255),
    text        = Color(220, 220, 235, 255),
    textDim     = Color(130, 130, 155, 255),
    card        = Color(28, 28, 40, 255),
    cardHover   = Color(35, 35, 50, 255),
    btnJoin     = Color(0, 160, 80, 255),
    btnJoinHov  = Color(0, 200, 100, 255),
    money       = Color(100, 220, 100, 255),
    separator   = Color(40, 40, 55, 255),
}

-- =============================================
-- УТИЛИТЫ
-- =============================================
local lastBuyAction = 0
local function CanAction()
    if lastBuyAction > CurTime() then 
        -- surface.PlaySound("common/wpn_denyselect.wav")
        return false 
    end
    lastBuyAction = CurTime() + 0.5
    return true
end

local function DrawGradient(x, y, w, h, fromColor, toColor, horizontal)
    for i = 0, w - 1 do
        local frac = i / w
        local r = Lerp(frac, fromColor.r, toColor.r)
        local g = Lerp(frac, fromColor.g, toColor.g)
        local b = Lerp(frac, fromColor.b, toColor.b)
        local a = Lerp(frac, fromColor.a, toColor.a)
        surface.SetDrawColor(r, g, b, a)
        if horizontal then
            surface.DrawRect(x + i, y, 1, h)
        else
            surface.DrawRect(x, y + i, w, 1)
        end
    end
end

-- =============================================
-- TAB: ПРОФЕССИИ
-- =============================================
local function CreateJobsTab(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)

    -- Стилизация скроллбара
    local sb = scroll:GetVBar()
    sb:SetWide(4)
    sb.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(25, 25, 35))
    end
    sb.btnUp.Paint = function() end
    sb.btnDown.Paint = function() end
    sb.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, C.accent)
    end

    -- Получаем все профессии
    local jobs = {}
    if RPExtraTeams then
        for k, v in pairs(RPExtraTeams) do
            if v and v.name then -- Проверяем что работа валидна
                table.insert(jobs, {id = k, data = v})
            end
        end
        table.sort(jobs, function(a, b)
            local catA = a.data.category or "Other"
            local catB = b.data.category or "Other"
            if catA == catB then
                return (a.data.name or "") < (b.data.name or "")
            end
            return catA < catB
        end)
    end

    if #jobs == 0 then
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(TOP)
        lbl:SetText("Нет доступных профессий или ошибка загрузки.")
        lbl:SetTextColor(Color(255, 100, 100))
        lbl:SetFont("ZGrad_F4Info")
        lbl:SizeToContents()
        return
    end

    local lastCategory = ""

    for _, job in ipairs(jobs) do
        local data = job.data

        -- Разделитель категорий
        local cat = data.category or "Другое"
        if cat ~= lastCategory then
            lastCategory = cat

            local catLabel = vgui.Create("DPanel", scroll)
            catLabel:Dock(TOP)
            catLabel:SetTall(35)
            catLabel:DockMargin(0, 10, 0, 5)
            catLabel.Paint = function(self, w, h)
                draw.SimpleText(cat, "ZGrad_F4Tab", 10, h / 2, C.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(C.separator)
                surface.DrawRect(0, h - 1, w, 1)
            end
        end

        -- Карточка профессии
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:SetTall(80)
        card:DockMargin(0, 2, 0, 2)

        local isHovered = false
        card.OnCursorEntered = function() isHovered = true end
        card.OnCursorExited = function() isHovered = false end

        local jobColor = data.color or Color(100, 100, 100)

        card.Paint = function(self, w, h)
            local bg = isHovered and C.cardHover or C.card
            draw.RoundedBox(6, 0, 0, w, h, bg)

            -- Цветная полоска слева
            draw.RoundedBox(3, 0, 4, 4, h - 8, jobColor)

            -- VIP Check
            if data.vip then
                -- Draw VIP in the center
                draw.SimpleText("V.I.P", "ZGrad_F4Title", w / 2, h / 2, Color(255, 200, 50, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Название
            draw.SimpleText(data.name or "???", "ZGrad_F4JobTitle", 60, 14, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Описание (первая строка)
            local desc = data.description or ""
            local firstLine = string.match(desc, "([^\n]+)") or desc
            if #firstLine > 60 then firstLine = string.sub(firstLine, 1, 58) .. ".." end
            draw.SimpleText(firstLine, "ZGrad_F4JobDesc", 60, 36, C.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Зарплата
            local salary = data.salary or 0
            draw.SimpleText("$" .. salary, "ZGrad_F4JobDesc", 60, 56, C.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Макс игроков
            local maxStr = (data.max == 0) and "∞" or tostring(data.max)
            local currentCount = team.NumPlayers(job.id) or 0
            draw.SimpleText(currentCount .. "/" .. maxStr, "ZGrad_F4JobDesc", 130, 56, C.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        -- Иконка модели
        local modelIcon = vgui.Create("SpawnIcon", card)
        modelIcon:SetPos(12, 10)
        modelIcon:SetSize(40, 60)
        local mdl = data.model
        if istable(mdl) then mdl = mdl[1] end
        modelIcon:SetModel(mdl or "models/player/group01/male_01.mdl")
        modelIcon:SetMouseInputEnabled(false)

        -- Кнопка "Стать"
        local btnJoin = vgui.Create("DButton", card)
        btnJoin:SetSize(90, 32)
        btnJoin:SetPos(card:GetWide() - 110, 24)
        btnJoin:SetText("")

        local btnHover = false
        btnJoin.OnCursorEntered = function() btnHover = true end
        btnJoin.OnCursorExited = function() btnHover = false end

        btnJoin.Paint = function(self, w, h)
            local col = btnHover and C.btnJoinHov or C.btnJoin
            draw.RoundedBox(6, 0, 0, w, h, col)
            draw.SimpleText("Стать", "ZGrad_F4Button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btnJoin.DoClick = function()
            if not CanAction() then return end
            RunConsoleCommand("darkrp", data.command)
            surface.PlaySound("ui/buttonclickrelease.wav")

            if IsValid(F4MENU) then
                F4MENU:Close()
                F4MENU = nil
                ZGRAD_DonateRefreshCallback = nil
            end
        end

        -- Позиция кнопки зависит от ширины карточки
        card.PerformLayout = function(self, w, h)
            btnJoin:SetPos(w - 110, 24)
        end
    end
end

-- =============================================
-- TAB: МАГАЗИН
-- =============================================
local function CreateShopTab(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)

    local sb = scroll:GetVBar()
    sb:SetWide(4)
    sb.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(25, 25, 35)) end
    sb.btnUp.Paint = function() end
    sb.btnDown.Paint = function() end
    sb.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, C.accent) end

    -- Заголовок
    local title = vgui.Create("DPanel", scroll)
    title:Dock(TOP)
    title:SetTall(30)
    title.Paint = function(self, w, h)
        draw.SimpleText("Магазин оружия", "ZGrad_F4Tab", 10, h / 2, C.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.separator)
        surface.DrawRect(0, h - 1, w, 1)
    end

    -- Шипменты (если есть)

    if CustomShipments then
        for _, shipment in pairs(CustomShipments) do
            if shipment.allowed and not table.HasValue(shipment.allowed, LocalPlayer():Team()) then continue end
            local card = vgui.Create("DPanel", scroll)
            card:Dock(TOP)
            card:SetTall(50)
            card:DockMargin(0, 2, 0, 2)

            local hover = false
            card.OnCursorEntered = function() hover = true end
            card.OnCursorExited = function() hover = false end

            card.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, hover and C.cardHover or C.card)

                draw.SimpleText(shipment.name or "???", "ZGrad_F4ShopItem", 60, 12, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                local priceText = "$" .. (shipment.price or 0)
                if shipment.amount and shipment.amount > 1 then
                    priceText = priceText .. " (x" .. shipment.amount .. ")"
                end
                draw.SimpleText(priceText, "ZGrad_F4JobDesc", 60, 30, C.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            -- Иконка модели шипмента
            if shipment.model then
                local icon = vgui.Create("SpawnIcon", card)
                icon:SetPos(8, 5)
                icon:SetSize(40, 40)
                icon:SetModel(shipment.model)
                icon:SetMouseInputEnabled(false)
            end

            -- Кнопка купить
            local btnBuy = vgui.Create("DButton", card)
            btnBuy:SetSize(80, 28)
            btnBuy:SetText("")

            local bHover = false
            btnBuy.OnCursorEntered = function() bHover = true end
            btnBuy.OnCursorExited = function() bHover = false end

            btnBuy.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, bHover and C.accent or C.accentDark)
                draw.SimpleText("Купить", "ZGrad_F4Button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            btnBuy.DoClick = function()
                if not CanAction() then return end
                if shipment.noship then
                    RunConsoleCommand("darkrp", "buy", shipment.name)
                else
                    RunConsoleCommand("darkrp", "buyshipment", shipment.name)
                end
                surface.PlaySound("ui/buttonclickrelease.wav")
            end

            card.PerformLayout = function(self, w, h)
                btnBuy:SetPos(w - 100, 11)
            end
        end
    end

    -- Сущности DarkRP
    local entTitle = vgui.Create("DPanel", scroll)
    entTitle:Dock(TOP)
    entTitle:SetTall(30)
    entTitle:DockMargin(0, 15, 0, 5)
    entTitle.Paint = function(self, w, h)
        draw.SimpleText("Предметы", "ZGrad_F4Tab", 10, h / 2, C.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.separator)
        surface.DrawRect(0, h - 1, w, 1)
    end

    if DarkRPEntities then
        for _, ent in pairs(DarkRPEntities) do
            if ent.allowed and not table.HasValue(ent.allowed, LocalPlayer():Team()) then continue end
            local card = vgui.Create("DPanel", scroll)
            card:Dock(TOP)
            card:SetTall(45)
            card:DockMargin(0, 2, 0, 2)

            local hover = false
            card.OnCursorEntered = function() hover = true end
            card.OnCursorExited = function() hover = false end

            card.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, hover and C.cardHover or C.card)
                draw.SimpleText(ent.name or "???", "ZGrad_F4ShopItem", 15, 8, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("$" .. (ent.price or 0), "ZGrad_F4JobDesc", 15, 25, C.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            local btnBuy = vgui.Create("DButton", card)
            btnBuy:SetSize(80, 28)
            btnBuy:SetText("")

            local bHover = false
            btnBuy.OnCursorEntered = function() bHover = true end
            btnBuy.OnCursorExited = function() bHover = false end

            btnBuy.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, bHover and C.accent or C.accentDark)
                draw.SimpleText("Купить", "ZGrad_F4Button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            btnBuy.DoClick = function()
                if not CanAction() then return end
                RunConsoleCommand("darkrp", ent.cmd)
                surface.PlaySound("ui/buttonclickrelease.wav")
            end

            card.PerformLayout = function(self, w, h)
                btnBuy:SetPos(w - 100, 8)
            end
        end
    end
end

-- =============================================
-- TAB: ИНФОРМАЦИЯ
-- =============================================
local function CreateInfoTab(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(15, 15, 15, 15)

    local sb = scroll:GetVBar()
    sb:SetWide(4)
    sb.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(25, 25, 35)) end
    sb.btnUp.Paint = function() end
    sb.btnDown.Paint = function() end
    sb.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, C.accent) end

    local infoTexts = {
       
    }

    for _, info in ipairs(infoTexts) do
        local label = vgui.Create("DLabel", scroll)
        label:Dock(TOP)
        label:SetTall(20)
        label:SetText(info[1])
        label:SetFont("ZGrad_F4Info")
        label:SetTextColor(info[2])
        label:DockMargin(5, 0, 5, 0)
    end
end

-- =============================================
-- ГЛАВНОЕ МЕНЮ F4
-- =============================================
local function OpenF4Menu()
    if IsValid(F4MENU) then
        F4MENU:Close()
        F4MENU = nil
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local w = math.min(1000, scrW * 0.7)
    local h = math.min(700, scrH * 0.8)

    F4MENU = vgui.Create("DFrame")
    F4MENU:SetSize(w, h)
    F4MENU:Center()
    F4MENU:SetTitle("")
    F4MENU:ShowCloseButton(false)
    F4MENU:SetDraggable(false)
    F4MENU:MakePopup()

    F4MENU.OnKeyCodePressed = function(self, key)
        if key == KEY_F4 then
            self:Close()
            F4MENU = nil
            ZGRAD_DonateRefreshCallback = nil
        end
    end

    F4MENU.Paint = function(self, pw, ph)
        -- Затемнение фона
        draw.RoundedBox(0, -scrW, -scrH, scrW * 3, scrH * 3, Color(0, 0, 0, 120))
        -- Главный фон
        draw.RoundedBox(12, 0, 0, pw, ph, C.bg)
    end

    -- Кнопка закрытия
    local btnClose = vgui.Create("DButton", F4MENU)
    btnClose:SetSize(36, 36)
    btnClose:SetPos(w - 44, 8)
    btnClose:SetText("")
    local closeHover = false
    btnClose.OnCursorEntered = function() closeHover = true end
    btnClose.OnCursorExited = function() closeHover = false end
    btnClose.Paint = function(self, bw, bh)
        if closeHover then
            draw.RoundedBox(18, 0, 0, bw, bh, Color(255, 60, 60, 200))
        end
        draw.SimpleText("✕", "ZGrad_F4Tab", bw / 2, bh / 2, closeHover and Color(255, 255, 255) or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnClose.DoClick = function()
        F4MENU:Close()
        F4MENU = nil
        ZGRAD_DonateRefreshCallback = nil
    end

    -- === САЙДБАР ===
    local sidebar = vgui.Create("DPanel", F4MENU)
    sidebar:SetPos(0, 0)
    sidebar:SetSize(200, h)
    sidebar.Paint = function(self, pw, ph)
        draw.RoundedBoxEx(12, 0, 0, pw, ph, C.sidebar, true, false, true, false)

        -- Логотип
        draw.SimpleText("Z-GRAD", "ZGrad_F4Title", pw / 2, 30, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("ROLEPLAY", "ZGrad_F4Info", pw / 2, 55, C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Разделитель
        surface.SetDrawColor(C.separator)
        surface.DrawRect(20, 75, pw - 40, 1)
    end

    -- === КОНТЕНТ ===
    local contentPanel = vgui.Create("DPanel", F4MENU)
    contentPanel:SetPos(200, 0)
    contentPanel:SetSize(w - 200, h)
    contentPanel.Paint = function(self, pw, ph)
        draw.RoundedBoxEx(12, 0, 0, pw, ph, C.content, false, true, false, true)
    end

    -- Активная вкладка
    local activeTab = nil
    local tabs = {}

    local function SwitchTab(name)
        if activeTab then activeTab:SetVisible(false) end

        if tabs[name] then
            tabs[name]:SetVisible(true)
            activeTab = tabs[name]
        end
    end

    -- Создаём контент вкладок
    local tabData = {
        {name = "Профессии",  icon = "", create = CreateJobsTab},
        {name = "Инфо",       icon = "",  create = CreateInfoTab},
        {name = "Донат",      icon = "", create = ZGRAD_CreateDonateTab},
        {name = "Магазин",    icon = "", create = CreateShopTab},
        {name = "Инвентарь",  icon = "", create = ZGRAD_CreateInventoryTab},
    }

    for _, td in ipairs(tabData) do
        local panel = vgui.Create("DPanel", contentPanel)
        panel:Dock(FILL)
        panel:DockMargin(0, 5, 5, 5)
        panel.Paint = function() end
        panel:SetVisible(false)
        tabs[td.name] = panel
        td.create(panel)
    end

    -- Кнопки вкладок в сайдбаре
    local btnY = 95
    local currentTabName = "Профессии"

    for _, td in ipairs(tabData) do
        local btn = vgui.Create("DButton", sidebar)
        btn:SetPos(10, btnY)
        btn:SetSize(180, 42)
        btn:SetText("")

        local bHover = false
        btn.OnCursorEntered = function() bHover = true end
        btn.OnCursorExited = function() bHover = false end

        btn.Paint = function(self, bw, bh)
            local isActive = (currentTabName == td.name)

            if isActive then
                draw.RoundedBox(6, 0, 0, bw, bh, Color(C.accent.r, C.accent.g, C.accent.b, 30))
                surface.SetDrawColor(C.accent)
                surface.DrawRect(0, 4, 3, bh - 8)
            elseif bHover then
                draw.RoundedBox(6, 0, 0, bw, bh, C.tabHover)
            end

            local textColor = isActive and C.accent or (bHover and C.text or C.textDim)
            local txt = td.icon == "" and td.name or (td.icon .. "  " .. td.name)
            draw.SimpleText(txt, "ZGrad_F4Tab", 20, bh / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            currentTabName = td.name
            SwitchTab(td.name)
            surface.PlaySound("ui/buttonclick.wav")
        end

        btnY = btnY + 48
    end

    -- Информация об игроке внизу сайдбара
    local playerInfo = vgui.Create("DPanel", sidebar)
    playerInfo:SetPos(10, h - 100)
    playerInfo:SetSize(180, 80)
    playerInfo.Paint = function(self, pw, ph)
        surface.SetDrawColor(C.separator)
        surface.DrawRect(10, 0, pw - 20, 1)

        local ply = LocalPlayer()
        draw.SimpleText(ply:Nick(), "ZGrad_F4Info", 45, 12, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local money = "N/A"
        if ply.getDarkRPVar then
            local m = ply:getDarkRPVar("money")
            if m then money = "$" .. m end
        end
        draw.SimpleText(money, "ZGrad_F4Info", 45, 32, C.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Donate Coins
        local dc = ZGRAD_DonateCoins or 0
        draw.SimpleText(dc .. " DC", "ZGrad_F4Info", 45, 52, Color(255, 215, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Аватарка игрока
    local avatar = vgui.Create("AvatarImage", playerInfo)
    avatar:SetPos(5, 14)
    avatar:SetSize(32, 32)
    avatar:SetPlayer(LocalPlayer(), 32)

    -- Открываем первую вкладку
    SwitchTab("Профессии")
end

-- =============================================
-- ХУКИ
-- =============================================

-- Главный перехват F4 через ShowSpare2 (стандартный хук GMod)
hook.Add("ShowSpare2", "ZGrad_OpenF4Menu", function()
    OpenF4Menu()
    return true -- Блокирует стандартное меню
end)

-- Перехват DarkRP F4 (для совместимости)
hook.Add("onDarkRPF4MenuOpen", "ZGrad_ReplaceF4", function()
    OpenF4Menu()
    return false -- Блокирует меню DarkRP
end)

print("[Z-Grad RP] Custom F4 menu loaded")

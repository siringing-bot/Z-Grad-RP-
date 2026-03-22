--[[---------------------------------------------------------------------------
Z-Grad RP — Donate System (Client)
Клиентская часть: UI вкладок Донат и Инвентарь в F4 меню
---------------------------------------------------------------------------]]

print("[Z-Grad RP] Donate System (Client) LOADING...")

-- =============================================
-- ЛОКАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- =============================================
ZGRAD_DonateCoins = ZGRAD_DonateCoins or 0
ZGRAD_DonateInventory = ZGRAD_DonateInventory or {} -- skinID -> equipped(bool)

-- Callback для перестройки вкладки после обновления данных
ZGRAD_DonateRefreshCallback = nil

-- =============================================
-- ШРИФТЫ
-- =============================================
surface.CreateFont("ZGrad_DonateTitle", {
    font = "Roboto",
    size = 22,
    weight = 700,
})

surface.CreateFont("ZGrad_DonateCoinsFont", {
    font = "Roboto",
    size = 20,
    weight = 700,
})

surface.CreateFont("ZGrad_DonateSkinName", {
    font = "Roboto",
    size = 15,
    weight = 600,
})

surface.CreateFont("ZGrad_DonateSkinJob", {
    font = "Roboto",
    size = 12,
    weight = 400,
})

surface.CreateFont("ZGrad_DonateSkinPrice", {
    font = "Roboto",
    size = 14,
    weight = 700,
})

surface.CreateFont("ZGrad_DonateButton", {
    font = "Roboto",
    size = 13,
    weight = 600,
})

surface.CreateFont("ZGrad_DonateCatTab", {
    font = "Roboto",
    size = 13,
    weight = 600,
})

surface.CreateFont("ZGrad_DonatePopupTitle", {
    font = "Roboto",
    size = 18,
    weight = 700,
})

surface.CreateFont("ZGrad_DonatePopupText", {
    font = "Roboto",
    size = 14,
    weight = 500,
})

-- =============================================
-- ЦВЕТА (Z-Grad стиль)
-- =============================================
local DC = {
    bg           = Color(16, 16, 22, 250),
    panel        = Color(22, 22, 30, 255),
    card         = Color(28, 28, 40, 255),
    cardHover    = Color(38, 38, 55, 255),
    accent       = Color(0, 180, 255, 255),
    accentDark   = Color(0, 120, 200, 255),
    gold         = Color(255, 215, 50, 255),
    goldDark     = Color(200, 165, 20, 255),
    text         = Color(220, 220, 235, 255),
    textDim      = Color(130, 130, 155, 255),
    separator    = Color(40, 40, 55, 255),
    green        = Color(0, 180, 80, 255),
    greenHover   = Color(0, 220, 100, 255),
    red          = Color(200, 50, 50, 255),
    redHover     = Color(255, 70, 70, 255),
    overlay      = Color(0, 0, 0, 180),
    catActive    = Color(0, 160, 255, 40),
    catHover     = Color(40, 40, 55, 255),
    equipped     = Color(0, 200, 100, 30),
    owned        = Color(50, 50, 70, 255),
}

-- =============================================
-- СЕТЕВЫЕ ПОЛУЧЕНИЯ
-- =============================================
net.Receive("ZGrad_Donate_SyncCoins", function()
    ZGRAD_DonateCoins = net.ReadInt(32)
end)

net.Receive("ZGrad_Donate_SyncInventory", function()
    ZGRAD_DonateInventory = {}
    local count = net.ReadUInt(16)
    for i = 1, count do
        local skinID = net.ReadString()
        local equipped = net.ReadBool()
        ZGRAD_DonateInventory[skinID] = equipped
    end

    -- Автообновление UI если меню открыто
    if ZGRAD_DonateRefreshCallback then
        ZGRAD_DonateRefreshCallback()
    end
end)

net.Receive("ZGrad_Donate_Notify", function()
    local msg = net.ReadString()
    local isError = net.ReadBool()
    
    chat.AddText(
        Color(0, 180, 255), "[Z-Grad] ",
        isError and Color(255, 80, 80) or Color(100, 255, 100),
        msg
    )
    surface.PlaySound(isError and "common/wpn_denyselect.wav" or "ui/buttonclickrelease.wav")
end)

-- Запросить синхронизацию
local function RequestSync()
    net.Start("ZGrad_Donate_RequestSync")
    net.SendToServer()
end

-- =============================================
-- СТИЛИЗОВАННЫЙ SCROLLBAR
-- =============================================
local function StyleScrollbar(scroll)
    local sb = scroll:GetVBar()
    sb:SetWide(4)
    sb.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(25, 25, 35)) end
    sb.btnUp.Paint = function() end
    sb.btnDown.Paint = function() end
    sb.btnGrip.Paint = function(self, w, h) draw.RoundedBox(2, 0, 0, w, h, DC.accent) end
end

-- =============================================
-- POPUP ПОДТВЕРЖДЕНИЯ / ОШИБКИ
-- =============================================
local function ShowDonatePopup(title, text, onConfirm, showCancel)
    local overlay = vgui.Create("DPanel")
    overlay:SetPos(0, 0)
    overlay:SetSize(ScrW(), ScrH())
    overlay:MakePopup()
    overlay:SetMouseInputEnabled(true)
    overlay.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, DC.overlay)
    end

    local popup = vgui.Create("DPanel", overlay)
    popup:SetSize(400, 200)
    popup:Center()
    popup.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, DC.bg)
        draw.RoundedBox(12, 1, 1, w - 2, h - 2, DC.panel)
        
        -- Заголовок
        draw.SimpleText(title, "ZGrad_DonatePopupTitle", w / 2, 30, DC.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Текст
        draw.SimpleText(text, "ZGrad_DonatePopupText", w / 2, 80, DC.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if onConfirm then
        -- Кнопка "Да"
        local btnYes = vgui.Create("DButton", popup)
        btnYes:SetSize(120, 38)
        btnYes:SetPos(showCancel and 60 or 140, 130)
        btnYes:SetText("")
        local yHover = false
        btnYes.OnCursorEntered = function() yHover = true end
        btnYes.OnCursorExited = function() yHover = false end
        btnYes.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, yHover and DC.greenHover or DC.green)
            draw.SimpleText("Да", "ZGrad_DonateButton", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btnYes.DoClick = function()
            onConfirm()
            overlay:Remove()
        end
    end

    -- Кнопка "Отмена"
    local btnCancel = vgui.Create("DButton", popup)
    btnCancel:SetSize(120, 38)
    btnCancel:SetPos(onConfirm and 220 or 140, 130)
    btnCancel:SetText("")
    local cHover = false
    btnCancel.OnCursorEntered = function() cHover = true end
    btnCancel.OnCursorExited = function() cHover = false end
    btnCancel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, cHover and DC.redHover or DC.red)
        draw.SimpleText("Отмена", "ZGrad_DonateButton", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnCancel.DoClick = function()
        overlay:Remove()
    end
end

-- =============================================
-- КАРТОЧКА СКИНА (3D превью + цена + кнопка)
-- =============================================
local function CreateSkinCard(parent, skinData, mode)
    -- mode: "shop" или "inventory"
    local cardW = 180
    local cardH = 260

    local card = vgui.Create("DPanel", parent)
    card:SetSize(cardW, cardH)
    card.Paint = function() end -- Рисуем вручную ниже

    local isHovered = false
    local hoverAnim = 0
    card.OnCursorEntered = function() isHovered = true end
    card.OnCursorExited = function() isHovered = false end

    -- Проверки владения и экипировки
    local isOwned = ZGRAD_DonateInventory[skinData.id] ~= nil
    local isEquipped = ZGRAD_DonateInventory[skinData.id] == true

    -- Найти отображаемое имя работы
    local jobDisplayName = skinData.job
    for _, cat in ipairs(ZGRAD_DONATE_CATEGORIES) do
        if cat.job == skinData.job then
            jobDisplayName = cat.name
            break
        end
    end

    -- Фон карточки
    card.Paint = function(self, w, h)
        -- Анимация ховера
        hoverAnim = Lerp(FrameTime() * 8, hoverAnim, isHovered and 1 or 0)

        local bgColor = Color(
            Lerp(hoverAnim, DC.card.r, DC.cardHover.r),
            Lerp(hoverAnim, DC.card.g, DC.cardHover.g),
            Lerp(hoverAnim, DC.card.b, DC.cardHover.b),
            255 
        )

        draw.RoundedBox(10, 0, 0, w, h, bgColor)

        -- Полоска сверху (золотая для магазина, зеленая для экипированного)
        if mode == "inventory" and isEquipped then
            draw.RoundedBoxEx(10, 0, 0, w, 3, DC.green, true, true, false, false)
        else
            draw.RoundedBoxEx(10, 0, 0, w, 3, DC.gold, true, true, false, false)
        end

        -- Название скина
        local nameY = 180
        local nameCol = (mode == "shop" and isOwned) and DC.textDim or DC.text
        draw.SimpleText(skinData.name, "ZGrad_DonateSkinName", w / 2, nameY, nameCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Профессия
        draw.SimpleText(jobDisplayName, "ZGrad_DonateSkinJob", w / 2, nameY + 18, DC.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- 3D Модель
    local mdlPanel = vgui.Create("DModelPanel", card)
    mdlPanel:SetPos(10, 10)
    mdlPanel:SetSize(cardW - 20, 155)
    mdlPanel:SetModel(skinData.model)
    mdlPanel:SetFOV(30)
    mdlPanel:SetMouseInputEnabled(false)

    local mn, mx = mdlPanel.Entity:GetRenderBounds()
    local size = 0
    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

    mdlPanel:SetCamPos(Vector(size * 1.6, size * 1.1, size * 0.6))
    mdlPanel:SetLookAt((mn + mx) / 2)

    -- Автоматическое вращение модели
    local rotAngle = math.Rand(0, 360)  -- Случайный старт чтобы все карточки были разные
    mdlPanel.LayoutEntity = function(self, ent)
        rotAngle = rotAngle + FrameTime() * 40
        ent:SetAngles(Angle(0, rotAngle, 0))
    end

    -- Кнопка (Купить / Надеть / Снять)
    if mode == "shop" then
        local priceText = tostring(skinData.price) .. " DC"
        local btnLabel = isOwned and "Куплено" or priceText

        local btn = vgui.Create("DButton", card)
        btn:SetPos(15, cardH - 45)
        btn:SetSize(cardW - 30, 34)
        btn:SetText("")

        local bHover = false
        local btnHoverAnim = 0
        btn.OnCursorEntered = function() bHover = true end
        btn.OnCursorExited = function() bHover = false end

        btn.Paint = function(self, w, h)
            if isOwned then
                draw.RoundedBox(8, 0, 0, w, h, DC.owned)
                draw.SimpleText("✓ Куплено", "ZGrad_DonateButton", w / 2, h / 2, DC.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                btnHoverAnim = Lerp(FrameTime() * 10, btnHoverAnim, bHover and 1 or 0)
                
                local r = Lerp(btnHoverAnim, DC.gold.r, DC.greenHover.r)
                local g = Lerp(btnHoverAnim, DC.gold.g, DC.greenHover.g)
                local b = Lerp(btnHoverAnim, DC.gold.b, DC.greenHover.b)
                draw.RoundedBox(8, 0, 0, w, h, Color(r, g, b))
                
                -- Цена (исчезает при наведении)
                surface.SetAlphaMultiplier(1 - btnHoverAnim)
                draw.SimpleText(priceText, "ZGrad_DonateSkinPrice", w / 2, h / 2, Color(20, 20, 30), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                -- Текст Купить (появляется при наведении)
                surface.SetAlphaMultiplier(btnHoverAnim)
                draw.SimpleText("Купить", "ZGrad_DonateButton", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                surface.SetAlphaMultiplier(1)
            end
        end

        btn.DoClick = function()
            if isOwned then return end

            if ZGRAD_DonateCoins < skinData.price then
                ShowDonatePopup(
                    "Недостаточно средств",
                    "У вас недостаточно Donate Coins!",
                    nil, true
                )
            else
                ShowDonatePopup(
                    "Подтверждение покупки",
                    "Уверены что хотите купить \"" .. skinData.name .. "\" за " .. skinData.price .. " Donate Coins?",
                    function()
                        net.Start("ZGrad_Donate_BuySkin")
                            net.WriteString(skinData.id)
                        net.SendToServer()
                    end,
                    true
                )
            end
        end
    elseif mode == "inventory" then
        local btn = vgui.Create("DButton", card)
        btn:SetPos(15, cardH - 45)
        btn:SetSize(cardW - 30, 34)
        btn:SetText("")

        local bHover = false
        btn.OnCursorEntered = function() bHover = true end
        btn.OnCursorExited = function() bHover = false end

        btn.Paint = function(self, w, h)
            if isEquipped then
                local col = bHover and DC.redHover or DC.red
                draw.RoundedBox(8, 0, 0, w, h, col)
                draw.SimpleText("Снять", "ZGrad_DonateButton", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                local col = bHover and DC.greenHover or DC.green
                draw.RoundedBox(8, 0, 0, w, h, col)
                draw.SimpleText("Надеть", "ZGrad_DonateButton", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        btn.DoClick = function()
            if isEquipped then
                net.Start("ZGrad_Donate_UnequipSkin")
                    net.WriteString(skinData.id)
                net.SendToServer()
            else
                net.Start("ZGrad_Donate_EquipSkin")
                    net.WriteString(skinData.id)
                net.SendToServer()
            end
        end
    end

    return card
end

-- =============================================
-- TAB: ДОНАТ (Магазин скинов)
-- =============================================
function ZGRAD_CreateDonateTab(parent)
    RequestSync()

    local mainPanel = vgui.Create("DPanel", parent)
    mainPanel:Dock(FILL)
    mainPanel.Paint = function() end

    -- Заголовок с балансом
    local header = vgui.Create("DPanel", mainPanel)
    header:Dock(TOP)
    header:SetTall(50)
    header:DockMargin(10, 5, 10, 0)
    header.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, DC.panel)

        draw.SimpleText("Донат Магазин", "ZGrad_DonateTitle", 15, h / 2, DC.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Баланс
        local coinsText = tostring(ZGRAD_DonateCoins) .. " Donate Coins"
        draw.SimpleText(coinsText, "ZGrad_DonateCoinsFont", w - 15, h / 2, DC.gold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Вкладки категорий (горизонтальные)
    local catBar = vgui.Create("DPanel", mainPanel)
    catBar:Dock(TOP)
    catBar:SetTall(40)
    catBar:DockMargin(10, 5, 10, 0)
    catBar.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, DC.panel)
    end

    -- Скролл область для карточек
    local contentScroll = vgui.Create("DScrollPanel", mainPanel)
    contentScroll:Dock(FILL)
    contentScroll:DockMargin(10, 5, 10, 5)
    StyleScrollbar(contentScroll)

    -- Грид для карточек
    local grid = vgui.Create("DIconLayout", contentScroll)
    grid:Dock(FILL)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    grid:DockMargin(5, 5, 5, 5)

    local currentCategory = ZGRAD_DONATE_CATEGORIES[1] and ZGRAD_DONATE_CATEGORIES[1].job or ""

    local function PopulateGrid(jobFilter)
        grid:Clear()
        
        local skins = ZGRAD_GetSkinsForJob(jobFilter)
        for _, skinData in ipairs(skins) do
            local cardPanel = CreateSkinCard(grid, skinData, "shop")
            grid:Add(cardPanel)
        end

        if #skins == 0 then
            local empty = vgui.Create("DPanel", grid)
            empty:SetSize(300, 60)
            grid:Add(empty)
            empty.Paint = function(self, w, h)
                draw.SimpleText("Нет доступных скинов для этой профессии", "ZGrad_DonateSkinName", w / 2, h / 2, DC.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Создать кнопки категорий
    local catScroll = vgui.Create("DHorizontalScroller", catBar)
    catScroll:Dock(FILL)
    catScroll:DockMargin(5, 3, 5, 3)
    catScroll:SetOverlap(-5)

    local catButtons = {}

    for i, cat in ipairs(ZGRAD_DONATE_CATEGORIES) do
        local cbtn = vgui.Create("DButton", catScroll)
        cbtn:SetSize(130, 34)
        cbtn:SetText("")
        catScroll:AddPanel(cbtn)

        local cHover = false
        cbtn.OnCursorEntered = function() cHover = true end
        cbtn.OnCursorExited = function() cHover = false end

        cbtn.Paint = function(self, w, h)
            local isActive = (currentCategory == cat.job)
            
            if isActive then
                draw.RoundedBox(6, 0, 0, w, h, DC.catActive)
                surface.SetDrawColor(DC.accent)
                surface.DrawRect(0, h - 2, w, 2)
            elseif cHover then
                draw.RoundedBox(6, 0, 0, w, h, DC.catHover)
            end

            local textCol = isActive and DC.accent or (cHover and DC.text or DC.textDim)
            local txt = cat.icon == "" and cat.name or (cat.icon .. " " .. cat.name)
            draw.SimpleText(txt, "ZGrad_DonateCatTab", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        cbtn.DoClick = function()
            currentCategory = cat.job
            PopulateGrid(cat.job)
            surface.PlaySound("ui/buttonclick.wav")
        end

        table.insert(catButtons, cbtn)
    end

    -- Начальное заполнение
    PopulateGrid(currentCategory)

    -- Автообновление после покупки (когда приходит обновлённый инвентарь)
    ZGRAD_DonateRefreshCallback = function()
        if IsValid(mainPanel) then
            PopulateGrid(currentCategory)
        end
    end

    mainPanel.OnRemove = function()
        if ZGRAD_DonateRefreshCallback then
            ZGRAD_DonateRefreshCallback = nil
        end
    end
end

-- =============================================
-- TAB: ИНВЕНТАРЬ
-- =============================================
function ZGRAD_CreateInventoryTab(parent)
    RequestSync()

    local mainPanel = vgui.Create("DPanel", parent)
    mainPanel:Dock(FILL)
    mainPanel.Paint = function() end

    -- Заголовок
    local header = vgui.Create("DPanel", mainPanel)
    header:Dock(TOP)
    header:SetTall(50)
    header:DockMargin(10, 5, 10, 0)
    header.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, DC.panel)

        draw.SimpleText("Инвентарь", "ZGrad_DonateTitle", 15, h / 2, DC.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local coinsText = tostring(ZGRAD_DonateCoins) .. " Donate Coins"
        draw.SimpleText(coinsText, "ZGrad_DonateCoinsFont", w - 15, h / 2, DC.gold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Скролл
    local contentScroll = vgui.Create("DScrollPanel", mainPanel)
    contentScroll:Dock(FILL)
    contentScroll:DockMargin(10, 5, 10, 5)
    StyleScrollbar(contentScroll)

    -- Грид
    local grid = vgui.Create("DIconLayout", contentScroll)
    grid:Dock(FILL)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    grid:DockMargin(5, 5, 5, 5)

    -- Функция перестройки инвентаря
    local function RebuildInventory()
        grid:Clear()

        local hasItems = false
        for skinID, equipped in pairs(ZGRAD_DonateInventory) do
            local skinData = ZGRAD_GetSkinByID(skinID)
            if skinData then
                hasItems = true
                local cardPanel = CreateSkinCard(grid, skinData, "inventory")
                grid:Add(cardPanel)
            end
        end

        if not hasItems then
            local empty = vgui.Create("DPanel", grid)
            empty:SetSize(400, 100)
            grid:Add(empty)
            empty.Paint = function(self, w, h)
                draw.SimpleText("Ваш инвентарь пуст", "ZGrad_DonateTitle", w / 2, h / 2 - 10, DC.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Купите скины в магазине Доната!", "ZGrad_DonateSkinJob", w / 2, h / 2 + 15, DC.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Начальное заполнение
    RebuildInventory()

    -- Автообновление после экипировки/снятия
    ZGRAD_DonateRefreshCallback = function()
        if IsValid(mainPanel) then
            RebuildInventory()
        end
    end

    mainPanel.OnRemove = function()
        if ZGRAD_DonateRefreshCallback then
            ZGRAD_DonateRefreshCallback = nil
        end
    end
end

print("[Z-Grad RP] Donate System (Client) loaded")

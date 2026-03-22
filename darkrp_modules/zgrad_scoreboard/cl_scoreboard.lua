--[[---------------------------------------------------------------------------
Z-Grad RP — Custom TAB Scoreboard
Тёмная тема, минималистичный стиль
Колонки: Ник, Профессия, Деньги, Пинг
---------------------------------------------------------------------------]]

local SCOREBOARD = nil

-- Шрифты
surface.CreateFont("ZGrad_ScoreTitle", {
    font = "Roboto",
    size = 32,
    weight = 700,
})

surface.CreateFont("ZGrad_ScoreHeader", {
    font = "Roboto",
    size = 16,
    weight = 600,
})

surface.CreateFont("ZGrad_ScoreRow", {
    font = "Roboto",
    size = 15,
    weight = 400,
})

surface.CreateFont("ZGrad_ScoreOnline", {
    font = "Roboto",
    size = 14,
    weight = 400,
})

-- Цвета
local COLORS = {
    bg         = Color(18, 18, 24, 245),
    header     = Color(25, 25, 35, 255),
    headerLine = Color(0, 180, 255, 255),
    rowEven    = Color(30, 30, 42, 200),
    rowOdd     = Color(35, 35, 48, 200),
    rowHover   = Color(45, 45, 60, 220),
    text       = Color(220, 220, 230, 255),
    textDim    = Color(140, 140, 160, 255),
    accent     = Color(0, 180, 255, 255),
    money      = Color(100, 220, 100, 255),
    ping_good  = Color(100, 220, 100, 255),
    ping_mid   = Color(255, 200, 50, 255),
    ping_bad   = Color(255, 80, 80, 255),
}

local function GetPingColor(ping)
    if ping < 80 then return COLORS.ping_good
    elseif ping < 150 then return COLORS.ping_mid
    else return COLORS.ping_bad end
end

local function FormatMoney(amount)
    local formatted = tostring(amount)
    local k = 1
    while k > 0 do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    end
    return "$" .. formatted
end

local function CreateScoreboard()
    if IsValid(SCOREBOARD) then SCOREBOARD:Remove() end

    local scrW, scrH = ScrW(), ScrH()
    local w = math.min(800, scrW * 0.6)
    local h = math.min(600, scrH * 0.7)

    SCOREBOARD = vgui.Create("DFrame")
    SCOREBOARD:SetSize(w, h)
    SCOREBOARD:Center()
    SCOREBOARD:SetTitle("")
    SCOREBOARD:ShowCloseButton(false)
    SCOREBOARD:SetDraggable(false)
    SCOREBOARD:MakePopup()
    SCOREBOARD:SetKeyboardInputEnabled(false)

    SCOREBOARD.Paint = function(self, pw, ph)
        -- Фон
        draw.RoundedBox(12, 0, 0, pw, ph, COLORS.bg)

        -- Верхняя полоса
        draw.RoundedBoxEx(12, 0, 0, pw, 80, COLORS.header, true, true, false, false)

        -- Акцентная линия
        surface.SetDrawColor(COLORS.headerLine)
        surface.DrawRect(0, 80, pw, 2)

        -- Название сервера
        draw.SimpleText("Z-GRAD RP", "ZGrad_ScoreTitle", pw / 2, 25, COLORS.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Онлайн
        local online = #player.GetAll()
        local maxPlayers = game.MaxPlayers()
        draw.SimpleText("Онлайн: " .. online .. " / " .. maxPlayers, "ZGrad_ScoreOnline", pw / 2, 55, COLORS.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Заголовки колонок
    local headerPanel = vgui.Create("DPanel", SCOREBOARD)
    headerPanel:SetPos(0, 86)
    headerPanel:SetSize(w, 30)
    headerPanel.Paint = function(self, pw, ph)
        draw.RoundedBox(0, 0, 0, pw, ph, Color(22, 22, 32, 255))

        local cols = {
            {text = "Игрок",     x = 60},
            {text = "Профессия", x = pw * 0.45},
            {text = "Деньги",    x = pw * 0.68},
            {text = "Пинг",      x = pw * 0.88},
        }

        for _, col in ipairs(cols) do
            draw.SimpleText(col.text, "ZGrad_ScoreHeader", col.x, ph / 2, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- Список игроков
    local playerList = vgui.Create("DScrollPanel", SCOREBOARD)
    playerList:SetPos(0, 118)
    playerList:SetSize(w, h - 124)

    local scrollBar = playerList:GetVBar()
    scrollBar:SetWide(4)
    scrollBar.Paint = function(self, pw, ph)
        draw.RoundedBox(2, 0, 0, pw, ph, Color(25, 25, 35, 200))
    end
    scrollBar.btnUp.Paint = function() end
    scrollBar.btnDown.Paint = function() end
    scrollBar.btnGrip.Paint = function(self, pw, ph)
        draw.RoundedBox(2, 0, 0, pw, ph, COLORS.accent)
    end

    -- Заполняем игроков
    local players = player.GetAll()
    table.sort(players, function(a, b)
        return a:Team() < b:Team()
    end)

    for i, ply in ipairs(players) do
        local row = vgui.Create("DPanel", playerList)
        row:Dock(TOP)
        row:SetTall(36)
        row:DockMargin(4, 1, 4, 0)

        local isEven = (i % 2 == 0)
        local hovered = false

        row.OnCursorEntered = function() hovered = true end
        row.OnCursorExited = function() hovered = false end

        row.Paint = function(self, pw, ph)
            local bgColor = hovered and COLORS.rowHover or (isEven and COLORS.rowEven or COLORS.rowOdd)
            draw.RoundedBox(4, 0, 0, pw, ph, bgColor)

            -- Цветная полоска команды
            local teamColor = (ply.getDarkRPVar and ply:getDarkRPVar("jobColor")) or team.GetColor(ply:Team()) or Color(100, 100, 100)
            draw.RoundedBox(2, 2, 4, 3, ph - 8, teamColor)

            -- Ник
            local name = ply:Nick()
            if #name > 22 then name = string.sub(name, 1, 20) .. ".." end
            draw.SimpleText(name, "ZGrad_ScoreRow", 56, ph / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Профессия
            local jobName = (ply.getDarkRPVar and ply:getDarkRPVar("job")) or team.GetName(ply:Team()) or "Неизвестно"
            local jobColor = (ply.getDarkRPVar and ply:getDarkRPVar("jobColor")) or team.GetColor(ply:Team()) or COLORS.text
            draw.SimpleText(jobName, "ZGrad_ScoreRow", pw * 0.45, ph / 2, jobColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Деньги (только если DarkRP доступен)
            local money = "N/A"
            if ply.getDarkRPVar then
                local m = ply:getDarkRPVar("money")
                if m then money = FormatMoney(m) end
            end
            draw.SimpleText(money, "ZGrad_ScoreRow", pw * 0.68, ph / 2, COLORS.money, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Пинг
            local ping = ply:Ping()
            draw.SimpleText(ping .. " ms", "ZGrad_ScoreRow", pw * 0.88, ph / 2, GetPingColor(ping), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- Аватар
        local avatar = vgui.Create("AvatarImage", row)
        avatar:SetPos(14, 4)
        avatar:SetSize(28, 28)
        avatar:SetPlayer(ply, 32)

        -- Взаимодействие (Правый клик)
        row.OnMousePressed = function(s, key)
            if key == MOUSE_RIGHT and IsValid(ply) then
                local menu = DermaMenu()
                
                -- Копировать SteamID64
                menu:AddOption("Скопировать SteamID64", function()
                    SetClipboardText(ply:SteamID64())
                    chat.AddText(COLORS.accent, "[Z-Grad] ", COLORS.text, "SteamID64 игрока ", COLORS.accent, ply:Nick(), COLORS.text, " скопирован!")
                end):SetIcon("icon16/tag_blue.png")

                -- Админ-команды (Admin и выше)
                if LocalPlayer():IsAdmin() then
                    menu:AddSpacer()

                    -- Банить
                    menu:AddOption("Забанить", function()
                        Derma_StringRequest("Бан: " .. ply:Nick(), "Введите время бана (в минутах, 0 - навсегда):", "0", function(time)
                            Derma_StringRequest("Бан: " .. ply:Nick(), "Введите причину бана:", "Нарушение правил", function(reason)
                                RunConsoleCommand("ulx", "ban", ply:Nick(), time, reason)
                            end)
                        end)
                    end):SetIcon("icon16/shield_delete.png")

                    -- Кикнуть
                    menu:AddOption("Кикнуть", function()
                        Derma_StringRequest("Кик: " .. ply:Nick(), "Введите причину кика:", "Нарушение правил", function(reason)
                            RunConsoleCommand("ulx", "kick", ply:Nick(), reason)
                        end)
                    end):SetIcon("icon16/door_out.png")

                    -- Мут
                    menu:AddOption("Мут", function()
                        Derma_StringRequest("Мут: " .. ply:Nick(), "Введите время мута (в минутах):", "0", function(time)
                            Derma_StringRequest("Мут: " .. ply:Nick(), "Введите причину мута:", "Нарушение правил", function(reason)
                                RunConsoleCommand("ulx", "mute", ply:Nick(), time, reason)
                            end)
                        end)
                    end):SetIcon("icon16/sound_mute.png")

                    menu:AddSpacer()

                    -- Slay
                    menu:AddOption("Убить (Slay)", function()
                        RunConsoleCommand("ulx", "slay", ply:Nick())
                    end):SetIcon("icon16/lightning.png")

                    -- Заморозить
                    menu:AddOption("Заморозить", function()
                        RunConsoleCommand("ulx", "freeze", ply:Nick())
                    end):SetIcon("icon16/lock.png")

                    menu:AddOption("Разморозить", function()
                        RunConsoleCommand("ulx", "unfreeze", ply:Nick())
                    end):SetIcon("icon16/lock_open.png")

                    menu:AddSpacer()

                    -- Телепортация
                    menu:AddOption("Телепортировать к себе", function()
                        RunConsoleCommand("ulx", "bring", ply:Nick())
                    end):SetIcon("icon16/arrow_refresh.png")

                    menu:AddOption("Телепортироваться к нему", function()
                        RunConsoleCommand("ulx", "goto", ply:Nick())
                    end):SetIcon("icon16/arrow_right.png")
                end
                
                menu:Open()
            end
        end

        -- Сделаем элементы внутри строки прозрачными для клика, чтобы клик ловился всей строкой
        avatar:SetMouseInputEnabled(false)
    end
end

-- Показать скорборд (return true блокирует стандартный скорборд)
hook.Add("ScoreboardShow", "ZGrad_ShowScoreboard", function()
    CreateScoreboard()
    return true
end)

-- Скрыть скорборд
hook.Add("ScoreboardHide", "ZGrad_HideScoreboard", function()
    if IsValid(SCOREBOARD) then
        SCOREBOARD:Remove()
        SCOREBOARD = nil
    end
end)

print("[Z-Grad RP] Custom scoreboard loaded")

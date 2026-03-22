--[[---------------------------------------------------------------------------
Z-Grad RP — Prop Whitelist (CLIENT)
Полная фильтрация Q меню: только разрешенные предметы
---------------------------------------------------------------------------]]

local AllowedProps = {}
local RefreshWhitelistIcons = function() end

-- Настройка для админов (чтобы могли проверить как выглядит у игроков)
-- По умолчанию 0 (админы видят всё). Чтобы скрыть всё как у игроков, напишите в консоль: zgrad_whitelist_admins 1
local cvAdminRestrict = CreateClientConVar("zgrad_whitelist_admins", "0", true, false, "Restrict Q menu for admins too (for testing)")

local function IsRestricted()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    if ply:IsAdmin() or ply:IsSuperAdmin() then
        return cvAdminRestrict:GetBool()
    end
    return true
end

-- Получаем вайтлист с сервера
net.Receive("ZGrad_PropWhitelist", function()
    local count = net.ReadUInt(16)
    AllowedProps = {}
    for i = 1, count do
        local model = net.ReadString()
        AllowedProps[string.lower(model)] = true
    end
    print("[Z-Grad RP] Received prop whitelist: " .. count .. " props")
    RefreshWhitelistIcons()
end)

-- Запрос вайтлиста, если он пуст
local function RequestWhitelist()
    if table.Count(AllowedProps) == 0 then
        -- Проверяем, существует ли строка сообщения на сервере (через pcall или просто дожидаясь)
        -- В GMod нет прямого способа проверить pooling без попытки старта, 
        -- но мы можем обернуть в pcall чтобы не спамить в консоль ошибкой
        pcall(function()
            net.Start("ZGrad_PropWhitelist_Request")
            net.SendToServer()
        end)
    end
end

-- Основная функция очистки вкладок
local function CleanSpawnMenu()
    if not IsRestricted() then return end

    local tabs = spawnmenu.GetCreationTabs()
    if not tabs then return end

    -- Мы должны оставить ТОЛЬКО нашу вкладку
    -- Очищаем таблицу вкладок, чтобы Sandbox не добавил их в UI
    local toRemove = {}
    for k, v in pairs(tabs) do
        if k ~= "Предметы" then
            table.insert(toRemove, k)
        end
    end

    for _, name in ipairs(toRemove) do
        tabs[name] = nil
    end
end

-- Вторичная очистка UI (если вкладки уже успели создаться)
local function HideTabsFromUI()
    if not IsRestricted() then return end
    if not IsValid(g_SpawnMenu) or not IsValid(g_SpawnMenu.CreateMenu) then return end

    -- В некоторых версиях GMod или сборках CreateMenu уже является PropertySheet,
    -- а в некоторых у него есть метод GetPropertySheet().
    local sheet = g_SpawnMenu.CreateMenu
    if sheet.GetPropertySheet then
        sheet = sheet:GetPropertySheet()
    end

    if not IsValid(sheet) or not sheet.Items then return end

    for _, item in pairs(sheet.Items) do
        if item.Tab and item.Name ~= "Предметы" then
            item.Tab:SetVisible(false)
            -- Сдвигаем скрытую вкладку в самый конец чтобы она не мешалась
            item.Tab:SetPos(-1000, -1000)
        end
    end
    
    -- Принудительно переключаем на нашу вкладку, если активна скрытая
    local active = sheet:GetActiveTab()
    if active and not active:IsVisible() then
        for _, item in pairs(sheet.Items) do
            if item.Tab and item.Tab:IsVisible() then
                sheet:SetActiveTab(item.Tab)
                break
            end
        end
    end
    
    sheet:InvalidateLayout(true)
end

-- Хуки для очистки
hook.Add("SpawnMenuPopulate", "ZGrad_SpawnMenuPopulate", function()
    timer.Simple(0, function()
        CleanSpawnMenu()
        HideTabsFromUI()
    end)
end)

hook.Add("OnSpawnMenuOpen", "ZGrad_SpawnMenuOpen", function()
    RequestWhitelist()
    CleanSpawnMenu()
    HideTabsFromUI()
end)

-- Каждую секунду проверяем чтобы ничего лишнего не вылезло (на всякий случай)
timer.Create("ZGrad_SpawnMenuGuard", 1, 0, function()
    if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
        HideTabsFromUI()
    end
end)

-- Блокируем стандартное наполнение контента пропов (на всякий случай)
hook.Add("PopulatePropMenu", "ZGrad_BlockStandardPropMenu", function()
    if IsRestricted() then return true end
end)

-- Создаем нашу вкладку
spawnmenu.AddCreationTab("Предметы", function()
    local panel = vgui.Create("DPanel")
    panel:SetSize(300, 400)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 45, 255))
    end

    local titlePanel = vgui.Create("DPanel", panel)
    titlePanel:SetTall(40)
    titlePanel:Dock(TOP)
    titlePanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 35, 255))
        draw.RoundedBox(0, 0, h-1, w, 1, Color(0, 150, 255, 100))
    end

    local title = vgui.Create("DLabel", titlePanel)
    title:SetText("РАЗРЕШЕННЫЕ ПРЕДМЕТЫ")
    title:SetFont("DermaDefaultBold")
    title:SetTextColor(Color(255, 255, 255))
    title:Dock(FILL)
    title:SetContentAlignment(5)

    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)

    local iconLayout = vgui.Create("DIconLayout", scroll)
    iconLayout:Dock(FILL)
    iconLayout:SetSpaceX(8)
    iconLayout:SetSpaceY(8)

    RefreshWhitelistIcons = function()
        if not IsValid(iconLayout) then return end
        iconLayout:Clear()

        local sorted = {}
        for model, _ in pairs(AllowedProps) do
            table.insert(sorted, model)
        end
        table.sort(sorted)

        for _, model in ipairs(sorted) do
            local icon = vgui.Create("SpawnIcon", iconLayout)
            icon:SetModel(model)
            icon:SetSize(64, 64)
            icon:SetTooltip(model)
            icon.DoClick = function()
                RunConsoleCommand("gm_spawn", model)
                surface.PlaySound("ui/buttonclickrelease.wav")
            end
            icon.DoRightClick = function()
                local menu = DermaMenu()
                menu:AddOption("Скопировать путь", function()
                    SetClipboardText(model)
                end):SetIcon("icon16/page_copy.png")
                menu:Open()
            end
        end
    end

    RefreshWhitelistIcons()
    return panel
end, "icon16/package.png", 1)

-- Команда для принудительного обновления
concommand.Add("zgrad_prop_sync", function()
    net.Start("ZGrad_PropWhitelist_Request")
    net.SendToServer()
    print("[Z-Grad RP] Sync requested...")
end)

print("[Z-Grad RP] Aggressive Prop Whitelist UI loaded")

--[[---------------------------------------------------------------------------
ВТОРАЯ ЧАСТЬ: ИНСТРУМЕНТЫ (TOOLS)
---------------------------------------------------------------------------]]

local AllowedTools = {
    ["adv_duplicator2"] = true,
    ["advdupe2"] = true,
    ["button"] = true,
    ["material"] = true,
    ["colour"] = true,
    ["fading_door"] = true,
    ["keypad_willox"] = true,
    ["keypad"] = true,
    ["zgrad_stacker"] = true,
    ["zgrad_precision"] = true,
    ["camera"] = true,
    ["weld"] = true,
    ["remover"] = true,
    -- ["rope"] = true,
}

local function FilterAllToolNodes()
    if not IsRestricted() then return end
    
    local panels = vgui.GetAll()
    for _, p in pairs(panels) do
        if not IsValid(p) or p.ClassName ~= "DTree_Node" then continue end
        
        local label = p:GetText()
        if label ~= "ВАЙТЛИСТ" and label ~= "0. ВАЙТЛИСТ" then
            local parent = p:GetParent()
            if IsValid(parent) and (parent.ClassName == "DTree" or parent:GetParent().ClassName == "DTree") then
                p:SetVisible(false)
                p:SetTall(0)
                p:Remove()
            end
        end
    end
end

-- Перехват регистрации
local oldAddToolMenuOption = spawnmenu.AddToolMenuOption
function spawnmenu.AddToolMenuOption(tab, cat, item, text, tool, ...)
    if IsRestricted() then
        local tid = string.lower(tool or "")
        if AllowedTools[tid] then
            return oldAddToolMenuOption(tab, "ВАЙТЛИСТ", item, text, tool, ...)
        else
            return -- Блокируем регистрацию
        end
    end
    return oldAddToolMenuOption(tab, cat, item, text, tool, ...)
end

-- Хук открытия
hook.Add("SpawnMenuOpen", "ZGrad_FinalToolFilter", function()
    if not IsRestricted() then return end
    
    -- Чистим реестры
    local toolData = spawnmenu.GetTools()
    if toolData then
        for tID, t in pairs(toolData) do
            local wl = {}
            for cName, tools in pairs(t.Items or {}) do
                for _, tool in pairs(tools) do
                    if type(tool) == "table" and AllowedTools[string.lower(tool.ItemName or "")] then
                        tool.Category = "ВАЙТЛИСТ"
                        table.insert(wl, tool)
                    end
                end
            end
            t.Items = { ["ВАЙТЛИСТ"] = wl }
        end
    end
    
    gamemode.Call("PopulateToolMenu")
    timer.Simple(0, FilterAllToolNodes)
    timer.Simple(0.5, FilterAllToolNodes)
end)

-- Резервный таймер
timer.Create("ZGrad_HeavyToolCleaner", 1, 0, function()
    if g_SpawnMenu and g_SpawnMenu:IsVisible() then
        FilterAllToolNodes()
    end
end)

hook.Add("CanShowTool", "ZGrad_HideTools", function(ply, toolname)
    if not IsRestricted() then return true end
    if not AllowedTools[string.lower(toolname)] then return false end
end)

print("[Z-Grad RP] Tool Whitelist Integrated into cl_propwhitelist.lua")

--[[---------------------------------------------------------------------------
Z-Grad RP — Context Menu (C-Menu)
Quick actions: Money, Selling items, Door management
---------------------------------------------------------------------------]]

surface.CreateFont("ZGrad_ContextMenu_Main", {
    font = "Roboto",
    size = 20,
    weight = 600,
    antialias = true,
})

surface.CreateFont("ZGrad_ContextMenu_Small", {
    font = "Roboto",
    size = 14,
    weight = 500,
    antialias = true,
})

local function CreateStyledButton(parent, text, icon, color, callback)
    local btn = parent:Add("DButton")
    btn:SetSize(180, 45)
    btn:SetText("")
    btn.DoClick = function()
        callback()
        if IsValid(parent) then parent:Remove() end
    end

    local hover_color = Color(color.r + 30, color.g + 30, color.b + 30, color.a)
    
    btn.Paint = function(self, w, h)
        local col = self:IsHovered() and hover_color or color
        draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25, 240))
        
        -- Left accent strip
        draw.RoundedBox(3, 2, 2, 4, h - 4, col)
        
        draw.SimpleText(text, "ZGrad_ContextMenu_Main", 15, h / 2, Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        if icon then
            draw.SimpleText(icon, "ZGrad_ContextMenu_Main", w - 15, h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    btn:Dock(TOP)
    btn:DockMargin(5, 5, 5, 5)
    
    return btn
end

local function OpenContextMenu()
    print("[ZGrad Context] Attempting to open menu...")
    if IsValid(G_ZGradContextMenu) then 
        print("[ZGrad Context] Menu already valid, returning.")
        return 
    end

    local frame = vgui.Create("DFrame")
    G_ZGradContextMenu = frame
    
    frame:SetSize(220, 400) -- Default size, will resize
    frame:SetPos(20, ScrH() / 2 - 200) -- Initial position
    
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    
    -- This allows clicking buttons but prevents character rotation
    frame:SetMouseInputEnabled(true)
    frame:SetKeyboardInputEnabled(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 15, 20, 255))
        
        -- Header accent
        draw.RoundedBoxEx(8, 0, 0, w, 5, Color(80, 130, 255), true, true, false, false)
        
        surface.SetDrawColor(Color(80, 130, 255, 40))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local ply = LocalPlayer()
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity
    local dist = trace.HitPos:DistToSqr(ply:EyePos())

    -- 1. DROP MONEY
    CreateStyledButton(frame, "Выбросить деньги", "", Color(100, 220, 100), function()
        Derma_StringRequest("Выбросить деньги", "Сколько вы хотите выбросить?", "", function(val)
            RunConsoleCommand("darkrp", "dropmoney", val)
        end)
    end)

    -- 2. GIVE MONEY
    CreateStyledButton(frame, "Передать деньги", "", Color(80, 180, 255), function()
        Derma_StringRequest("Передать деньги", "Сколько вы хотите передать игроку?", "", function(val)
            RunConsoleCommand("darkrp", "give", val)
        end)
    end)

    -- 3. SELL ITEM (50%)
    if IsValid(ent) and dist < 40000 then -- ~200 units
        local isOwnedByMe = (ent:GetNW2Entity("owner") == ply) or (ent.Getowning_ent and ent:Getowning_ent() == ply)
        
        if isOwnedByMe then
            local class = ent:GetClass()
            local isSellable = false
            local price = 0
            
            -- Check Entities
            if DarkRPEntities then
                for _, e in pairs(DarkRPEntities) do
                    if e.ent == class then
                        isSellable = true
                        price = e.price or 0
                        break
                    end
                end
            end

            -- Check Shipments
            if not isSellable and CustomShipments then
                for _, s in pairs(CustomShipments) do
                    if s.entity == class then
                        isSellable = true
                        price = s.price or 0
                        break
                    end
                end
            end
            
            if isSellable and price > 0 then
                local sellPrice = math.floor(price * 0.5)
                CreateStyledButton(frame, "Продать предмет", "", Color(255, 200, 50), function()
                    Derma_Query("Продать этот предмет за $" .. sellPrice .. "?", "Продажа", "Да", function()
                        net.Start("ZGrad_ContextMenu_SellItem")
                            net.WriteEntity(ent)
                        net.SendToServer()
                    end, "Нет")
                end)
            end
        end
    end

    -- 4. DOOR MANAGEMENT
    if IsValid(ent) and (ent:isDoor() or ent:IsVehicle()) and dist < 62500 then
        local isOwnedByMe = ent:isKeysOwnedBy(ply)
        
        if isOwnedByMe then
            CreateStyledButton(frame, "Продать дверь", "", Color(255, 100, 100), function()
                RunConsoleCommand("darkrp", "toggleown")
            end)
        else
            CreateStyledButton(frame, "Купить дверь", "", Color(200, 200, 200), function()
                RunConsoleCommand("darkrp", "toggleown")
            end)
        end
    end

    -- 5. UNOWN ALL DOORS
    CreateStyledButton(frame, "Продать все двери", "", Color(220, 60, 60), function()
        Derma_Query("Вы действительно хотите продать все свои двери?", "Продажа дверей", "Да", function()
            RunConsoleCommand("darkrp", "unownalldoors")
        end, "Нет")
    end)

    -- 6. MAYOR BUTTONS
    if ply:Team() == TEAM_MAYOR and ZGrad_MayorButtons then
        local sep = vgui.Create("DPanel", frame)
        sep:Dock(TOP)
        sep:DockMargin(10, 5, 10, 5)
        sep:SetTall(1)
        sep.Paint = function(self, w, h)
            surface.SetDrawColor(Color(80, 130, 255, 100))
            surface.DrawRect(0, 0, w, h)
        end
        
        for _, btnData in ipairs(ZGrad_MayorButtons) do
            CreateStyledButton(frame, btnData.text, btnData.icon, btnData.color, btnData.callback)
        end
    end

    -- 7. BANKER BUTTONS
    if ply:Team() == TEAM_BANKER and ZGrad_BankerButtons then
        local sep = vgui.Create("DPanel", frame)
        sep:Dock(TOP)
        sep:DockMargin(10, 5, 10, 5)
        sep:SetTall(1)
        sep.Paint = function(self, w, h)
            surface.SetDrawColor(Color(100, 255, 100, 100))
            surface.DrawRect(0, 0, w, h)
        end
        
        for _, btnData in ipairs(ZGrad_BankerButtons) do
            CreateStyledButton(frame, btnData.text, btnData.icon, btnData.color, btnData.callback)
        end
    end

    -- 8. TERRORIST BUTTONS
    local tn = string.lower(team.GetName(ply:Team()) or "")
    local isTerror = ply:Team() == (TEAM_TERROR or -1) or ply:Team() == (TEAM_TERRORIST or -1) or string.find(tn, "террор") or string.find(tn, "terror")
    
    if isTerror then
        local sep = vgui.Create("DPanel", frame)
        sep:Dock(TOP)
        sep:DockMargin(10, 5, 10, 5)
        sep:SetTall(1)
        sep.Paint = function(self, w, h)
            surface.SetDrawColor(Color(255, 80, 80, 100))
            surface.DrawRect(0, 0, w, h)
        end
        
        local btnTerror = CreateStyledButton(frame, "Начать теракт", "💣", Color(255, 50, 50), function()
            local cd = GetGlobalFloat("ZGrad_TerrorCD", 0)
            if CurTime() < cd then
                local remain = math.ceil(cd - CurTime())
                DarkRP.notify(string.format("Теракт будет доступен через %d сек.", remain), 1, 4)
                return
            end

            Derma_StringRequest("Начать теракт", "Введите место проведения теракта:", "", function(val)
                if val and val != "" then
                    net.Start("ZGrad_TerrorAct_Start")
                        net.WriteString(val)
                    net.SendToServer()
                end
            end, nil, "Начать", "Отмена")
        end)
        
        -- Override Paint to show dynamic cooldown
        local oldPaint = btnTerror.Paint
        btnTerror.Paint = function(self, w, h)
            local cd = GetGlobalFloat("ZGrad_TerrorCD", 0)
            if CurTime() < cd then
                local remain = math.ceil(cd - CurTime())
                self.CooldownText = "До теракта: " .. remain .. " сек."
                self.IsCooldown = true
            else
                self.CooldownText = "Начать теракт"
                self.IsCooldown = false
            end
            
            -- We just hack the original Paint function by temporarily modifying the upvalue text if we could, 
            -- but since we can't easily change the closure variable, we'll draw it ourselves.
            local color = Color(255, 50, 50)
            local hover_color = Color(color.r + 30, color.g + 30, color.b + 30, color.a)
            local col = self:IsHovered() and hover_color or color
            
            if self.IsCooldown then
                col = Color(150, 150, 150) -- Gray out if on cooldown
            end
            
            draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25, 240))
            draw.RoundedBox(3, 2, 2, 4, h - 4, col)
            draw.SimpleText(self.CooldownText, "ZGrad_ContextMenu_Main", 15, h / 2, self.IsCooldown and Color(150, 150, 150) or Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("", "ZGrad_ContextMenu_Main", w - 15, h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    
    -- 8.5. MAFIA BOSS BUTTONS
    if ply:Team() == (TEAM_MAFIA_BOSS or -1) then
        local sepCoup = vgui.Create("DPanel", frame)
        sepCoup:Dock(TOP)
        sepCoup:DockMargin(10, 5, 10, 5)
        sepCoup:SetTall(1)
        sepCoup.Paint = function(self, w, h)
            surface.SetDrawColor(Color(255, 140, 0, 100))
            surface.DrawRect(0, 0, w, h)
        end
        
        local btnCoup = CreateStyledButton(frame, "Гос. переворот", "👑", Color(255, 140, 0), function()
            local cd = GetGlobalFloat("ZGrad_CoupCD", 0)
            if CurTime() < cd then
                local remain = math.ceil((cd - CurTime()) / 60)
                DarkRP.notify(string.format("Гос. переворот доступен через %d мин.", remain), 1, 4)
                return
            end

            Derma_StringRequest("Гос. переворот", "Введите причину переворота:", "Свержение тирании!", function(val)
                if val and val != "" then
                    net.Start("ZGrad_Coup_Start")
                        net.WriteString(val)
                    net.SendToServer()
                end
            end, nil, "Начать", "Отмена")
        end)
        
        -- Override Paint to show dynamic cooldown
        local oldPaint_Coup = btnCoup.Paint
        btnCoup.Paint = function(self, w, h)
            local cd = GetGlobalFloat("ZGrad_CoupCD", 0)
            if CurTime() < cd then
                local remain = math.ceil(cd - CurTime())
                local mins = math.floor(remain / 60)
                local secs = remain % 60
                self.CooldownText = string.format("Гос. переворот: %02d:%02d", mins, secs)
                self.IsCooldown = true
            else
                self.CooldownText = "Начать гос. переворот"
                self.IsCooldown = false
            end
            
            local color = Color(255, 140, 0)
            local hover_color = Color(color.r + 30, color.g + 30, color.b + 30, color.a)
            local col = self:IsHovered() and hover_color or color
            
            if self.IsCooldown then
                col = Color(150, 150, 150)
            end
            
            draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25, 240))
            draw.RoundedBox(3, 2, 2, 4, h - 4, col)
            draw.SimpleText(self.CooldownText, "ZGrad_ContextMenu_Small", 15, h / 2, self.IsCooldown and Color(150, 150, 150) or Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(self.IsCooldown and "⏳" or "👑", "ZGrad_ContextMenu_Main", w - 15, h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    
    -- 9. CALL ADMIN
    local sepAdmin = vgui.Create("DPanel", frame)
    sepAdmin:Dock(TOP)
    sepAdmin:DockMargin(10, 5, 10, 5)
    sepAdmin:SetTall(1)
    sepAdmin.Paint = function(self, w, h)
        surface.SetDrawColor(Color(255, 100, 100, 100))
        surface.DrawRect(0, 0, w, h)
    end
    
    CreateStyledButton(frame, "Вызвать Админа", "🛡️", Color(255, 80, 80), function()
        if CreateCallAdminWindow then
            CreateCallAdminWindow()
        else
            RunConsoleCommand("say", "///")
        end
    end)

    -- Dynamically adjust height and reposition
    local totalH = 5
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsVisible() and child.SetSize then -- Filter buttons/panels
             totalH = totalH + child:GetTall() + 10
        end
    end
    frame:SetTall(totalH + 5)
    frame:SetPos(20, ScrH() / 2 - frame:GetTall() / 2)
end

-- HOOKS
local zgrad_cursor_enabled = false

-- This hook is often blocked by DarkRP/Sandbox for non-admins
hook.Add("ContextMenuOpen", "!_ZGrad_ContextReplace", function()
    OpenContextMenu()
    return false -- Prevent standard menu
end)

hook.Add("ContextMenuClosed", "!_ZGrad_ContextReplaceClose", function()
    if IsValid(G_ZGradContextMenu) then
        G_ZGradContextMenu:Remove()
    end
end)

-- Allow all players to use context menu at the engine level
hook.Add("AllowContextMenu", "!!!ZGrad_Override", function(ply)
    return true
end)

-- Detect the raw key press (C key and F3)
hook.Add("PlayerButtonDown", "ZGrad_ContextKeyForce", function(ply, button)
    if button == KEY_C then
        if gui.IsGameUIVisible() or gui.IsConsoleVisible() then return end
        OpenContextMenu()
    end

    if button == KEY_F3 then
        if gui.IsGameUIVisible() or gui.IsConsoleVisible() then return end
        
        -- COOLDOWN CHECK
        ply.ZGrad_CursorCD = ply.ZGrad_CursorCD or 0
        if CurTime() < ply.ZGrad_CursorCD then return end
        ply.ZGrad_CursorCD = CurTime() + 1

        zgrad_cursor_enabled = not zgrad_cursor_enabled
        gui.EnableScreenClicker(zgrad_cursor_enabled)

        if zgrad_cursor_enabled then
            surface.PlaySound("ui/buttonrollover.wav")
        else
            surface.PlaySound("ui/buttonclickrelease.wav")
        end
    end
end)

-- Detect key release to close menu (like standard GMod)
hook.Add("PlayerButtonUp", "ZGrad_ContextKeyForceClose", function(ply, button)
    if button == KEY_C then
        if IsValid(G_ZGradContextMenu) then
            G_ZGradContextMenu:Remove()
        end
    end
end)

-- Handle ESC and Binds
hook.Add("PlayerBindPress", "ZGrad_ContextBinds", function(ply, bind, pressed)
    if bind == "cancelselect" and IsValid(G_ZGradContextMenu) then
        G_ZGradContextMenu:Remove()
        return true
    end
    
    -- Catch +menu_context bind
    if bind == "+menu_context" and pressed then
        OpenContextMenu()
        return true
    end

    -- Block default F3 menu if our cursor logic is handled in PlayerButtonDown
    if bind == "gm_showspare1" then
        return true 
    end
end)

concommand.Add("zgrad_cmenu", function()
    OpenContextMenu()
end)

print("[Z-Grad RP] Aggressive Context Menu hooks (V3) LOADED")


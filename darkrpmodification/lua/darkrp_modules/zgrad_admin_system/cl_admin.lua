function CreateCallAdminWindow()
    if IsValid(ZGrad_Admin_CallWindow) then ZGrad_Admin_CallWindow:Remove() end
    
    ZGrad_Admin_CallWindow = vgui.Create("DFrame")
    local frame = ZGrad_Admin_CallWindow
    frame:SetSize(400, 200)
    frame:SetTitle("Жалоба Администрации")
    frame:Center()
    frame:MakePopup()
    
    local textEntry = vgui.Create("DTextEntry", frame)
    textEntry:Dock(FILL)
    textEntry:SetMultiline(true)
    textEntry:DockMargin(10, 10, 10, 10)
    textEntry:SetPlaceholderText("Опишите вашу проблему, и администратор скоро с вами свяжется...")
    
    local sendBtn = vgui.Create("DButton", frame)
    sendBtn:Dock(BOTTOM)
    sendBtn:SetTall(35)
    sendBtn:SetText("Отправить")
    sendBtn:DockMargin(10, 0, 10, 10)
    sendBtn.DoClick = function()
        local txt = textEntry:GetValue()
        if txt == "" then return end
        
        if LocalPlayer():IsAdmin() then
            -- Sending message as an admin-chat message instead of creating a report
            RunConsoleCommand("say", "@ " .. txt)
        else
            net.Start("ZGrad_Admin_CreateReport")
            net.WriteString(txt)
            net.SendToServer()
        end
        frame:Close()
    end
end



ZGrad_Client_Reports = ZGrad_Client_Reports or {}
local AdminMainPanel = nil
local bIsHandlingReport = false
local ActiveReportData = nil

local function BuildAdminPanel()
    if not LocalPlayer():IsAdmin() or (TEAM_ADMIN and LocalPlayer():Team() ~= TEAM_ADMIN) then
        if IsValid(AdminMainPanel) then AdminMainPanel:Remove() end
        return
    end
    
    if not IsValid(AdminMainPanel) then
        AdminMainPanel = vgui.Create("DPanel")
        AdminMainPanel:SetSize(300, 400)
        AdminMainPanel:SetPos(10, ScrH() / 2 - 200)
        AdminMainPanel:SetMouseInputEnabled(true) -- Always enabled, works with F3 cursor
        AdminMainPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 240))
            if not bIsHandlingReport then
                draw.SimpleText("Жалобы (" .. table.Count(ZGrad_Client_Reports) .. ")", "Trebuchet24", w/2, 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    end
end

local function RefreshAdminPanel()
    if not IsValid(AdminMainPanel) then return end
    
    if AdminMainPanel.scrollList then AdminMainPanel.scrollList:Remove() end
    if AdminMainPanel.activeContainer then AdminMainPanel.activeContainer:Remove() end
    
    if bIsHandlingReport and ActiveReportData then
        local container = vgui.Create("DPanel", AdminMainPanel)
        container:Dock(FILL)
        container:DockMargin(10, 40, 10, 10)
        container.Paint = function(self, w, h)
            draw.SimpleText(ActiveReportData.caller_nick, "Trebuchet24", 0, 0, Color(255,200,50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(ActiveReportData.caller_steamid, "DermaDefault", 0, 25, Color(200,200,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        
        local textScroll = vgui.Create("DScrollPanel", container)
        textScroll:SetPos(0, 50)
        textScroll:SetSize(280, 150)
        
        local textLabel = vgui.Create("DLabel", textScroll)
        textLabel:SetText(ActiveReportData.text)
        textLabel:SetFont("DermaDefault")
        textLabel:SetAutoStretchVertical(true)
        textLabel:SetWrap(true)
        textLabel:SetWidth(270)
        
        local btnClose = vgui.Create("DButton", container)
        btnClose:Dock(BOTTOM)
        btnClose:SetTall(30)
        btnClose:SetText("Закрыть жалобу")
        btnClose:DockMargin(0, 5, 0, 0)
        btnClose.DoClick = function()
            net.Start("ZGrad_Admin_ReportAction")
            net.WriteString("close")
            net.WriteString(ActiveReportData.id)
            net.SendToServer()
        end
        
        local btnReturn = vgui.Create("DButton", container)
        btnReturn:Dock(BOTTOM)
        btnReturn:SetTall(30)
        btnReturn:SetText("Вернуть игрока")
        btnReturn:DockMargin(0, 5, 0, 0)
        btnReturn.DoClick = function()
            net.Start("ZGrad_Admin_ReportAction")
            net.WriteString("return")
            net.WriteString(ActiveReportData.id)
            net.SendToServer()
        end
        
        local btnBring = vgui.Create("DButton", container)
        btnBring:Dock(BOTTOM)
        btnBring:SetTall(30)
        btnBring:SetText("Телепортировать игрока")
        btnBring:DockMargin(0, 5, 0, 0)
        btnBring.DoClick = function()
            net.Start("ZGrad_Admin_ReportAction")
            net.WriteString("bring")
            net.WriteString(ActiveReportData.id)
            net.SendToServer()
        end
        
        local btnGoto = vgui.Create("DButton", container)
        btnGoto:Dock(BOTTOM)
        btnGoto:SetTall(30)
        btnGoto:SetText("Телепортироваться к игроку")
        btnGoto:DockMargin(0, 5, 0, 0)
        btnGoto.DoClick = function()
            net.Start("ZGrad_Admin_ReportAction")
            net.WriteString("goto")
            net.WriteString(ActiveReportData.id)
            net.SendToServer()
        end
        
        AdminMainPanel.activeContainer = container
    else
        local scroll = vgui.Create("DScrollPanel", AdminMainPanel)
        scroll:Dock(FILL)
        scroll:DockMargin(5, 40, 5, 5)
        AdminMainPanel.scrollList = scroll
        
        -- Default scrollbar styling
        local sbar = scroll:GetVBar()
        function sbar:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,100)) end
        function sbar.btnUp:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(20,20,20,255)) end
        function sbar.btnDown:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(20,20,20,255)) end
        function sbar.btnGrip:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100,255)) end

        for id, v in pairs(ZGrad_Client_Reports) do
            local pnl = vgui.Create("DPanel", scroll)
            pnl:Dock(TOP)
            pnl:SetTall(60)
            pnl:DockMargin(0, 0, 0, 5)
            pnl.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 255))
                draw.SimpleText(v.caller_nick, "DermaDefaultBold", 5, 5, color_white, TEXT_ALIGN_LEFT)
                local snippet = v.text:sub(1, 40)
                if #v.text > 40 then snippet = snippet .. "..." end
                draw.SimpleText(snippet, "DermaDefault", 5, 20, Color(200,200,200), TEXT_ALIGN_LEFT)
            end
            
            local btnContainer = vgui.Create("DPanel", pnl)
            btnContainer:Dock(BOTTOM)
            btnContainer:SetTall(20)
            btnContainer:SetVisible(false)
            btnContainer.Paint = function() end
            
            local btnAccept = vgui.Create("DButton", btnContainer)
            btnAccept:Dock(LEFT)
            btnAccept:SetWide(140)
            btnAccept:SetText("Принять")
            btnAccept.DoClick = function()
                net.Start("ZGrad_Admin_ReportAction")
                net.WriteString("accept")
                net.WriteString(v.id)
                net.SendToServer()
            end
            
            local btnCancel = vgui.Create("DButton", btnContainer)
            btnCancel:Dock(RIGHT)
            btnCancel:SetWide(140)
            btnCancel:SetText("Отмена")
            
            local clicker = vgui.Create("DButton", pnl)
            clicker:Dock(FILL)
            clicker:SetText("")
            clicker.Paint = function() end
            clicker.DoClick = function()
                pnl:SetTall(85)
                btnContainer:SetVisible(true)
                clicker:SetVisible(false)
            end
            
            btnCancel.DoClick = function()
                pnl:SetTall(60)
                btnContainer:SetVisible(false)
                clicker:SetVisible(true)
            end
        end
    end
end

net.Receive("ZGrad_Admin_SyncReports", function()
    local tbl = net.ReadTable()
    ZGrad_Client_Reports = {}
    for _, v in ipairs(tbl) do
        ZGrad_Client_Reports[v.id] = v
    end
    if not bIsHandlingReport then
        RefreshAdminPanel()
    end
end)

net.Receive("ZGrad_Admin_SyncSpecificReport", function()
    ActiveReportData = net.ReadTable()
    bIsHandlingReport = true
    RefreshAdminPanel()
end)

net.Receive("ZGrad_Admin_CloseReport", function()
    bIsHandlingReport = false
    ActiveReportData = nil
    RefreshAdminPanel()
end)

local function CheckAdminStatus()
    if not IsValid(LocalPlayer()) then return end
    local isAdM = LocalPlayer():IsAdmin() and (TEAM_ADMIN and LocalPlayer():Team() == TEAM_ADMIN)
    if isAdM and not IsValid(AdminMainPanel) then
        net.Start("ZGrad_Admin_RequestSync")
        net.SendToServer()
        BuildAdminPanel()
        RefreshAdminPanel()
    elseif not isAdM and IsValid(AdminMainPanel) then
        AdminMainPanel:Remove()
    end
end
timer.Create("ZGrad_AdminSystem_Check", 2, 0, CheckAdminStatus)

-- Hooks removed since input is handled correctly with F3/Context overrides

hook.Add("HUDPaint", "ZGrad_Admin_OverloadNotify", function()
    if not LocalPlayer():IsAdmin() or (TEAM_ADMIN and LocalPlayer():Team() ~= TEAM_ADMIN) then return end
    if ZGrad_Client_Reports and table.Count(ZGrad_Client_Reports) > 3 then
        draw.SimpleText("ВНИМАНИЕ: Жалоб больше чем 3! Помогите в их разборе.", "Trebuchet24", 20, 20, Color(255, 50, 50, 200 + math.sin(CurTime()*5)*55), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end)

hook.Add("PrePlayerDraw", "ZGrad_Admin_InvisDraw", function(ply)
    if not IsValid(ply) then return end
    if (TEAM_ADMIN and ply:Team() == TEAM_ADMIN) and ply:GetMoveType() == MOVETYPE_NOCLIP then
        return true
    end
end)

local noclipLastPress = 0
hook.Add("PlayerButtonDown", "ZGrad_Admin_NoclipButton", function(ply, button)
    if not IsFirstTimePredicted() then return end
    if button == KEY_V then
        if LocalPlayer():IsAdmin() and (TEAM_ADMIN and LocalPlayer():Team() == TEAM_ADMIN) then
            -- Avoid triggering if typing in chat, console, or any menu
            if vgui.GetKeyboardFocus() then return end
            if gui.IsConsoleVisible() then return end
            if gui.IsGameUIVisible() then return end
            
            -- Cooldown
            if noclipLastPress > CurTime() then return end
            noclipLastPress = CurTime() + 0.3
            
            -- Check if the key is already bound to noclip command. 
            -- If it is, the engine will send its own request, so we don't need to send the net message.
            local bind = input.LookupKeyBinding(button)
            if bind and (string.find(bind, "noclip") or string.find(bind, "noclip")) then 
                return 
            end
            
            net.Start("ZGrad_Admin_ToggleNoclip")
            net.SendToServer()
        end
    end
end)

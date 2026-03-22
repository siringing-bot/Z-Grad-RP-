--[[---------------------------------------------------------------------------
Z-Grad Car Rental - Client
---------------------------------------------------------------------------]]

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
}

local function StyledScrollbar(scroll)
    local sb = scroll:GetVBar()
    sb:SetWide(4)
    sb.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, Color(25, 25, 35)) end
    sb.btnUp.Paint = function() end
    sb.btnDown.Paint = function() end
    sb.btnGrip.Paint = function(_, w, h) draw.RoundedBox(2, 0, 0, w, h, C.accent) end
end

local RentalData = {} -- Sync'd from server

net.Receive("ZGrad_Rental_Sync", function()
    RentalData = net.ReadTable()
end)

local function OpenDurationQuery(class, name, price)
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 180)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(_, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 20)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.SimpleText("ДЛИТЕЛЬНОСТЬ АРЕНДЫ", "ZGrad_Mayor_Sub", w/2, 25, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(name, "ZGrad_Mayor_Text", w/2, 50, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Макс. 20 минут", "ZGrad_Mayor_Small", w/2, 110, C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local entry = vgui.Create("DTextEntry", frame)
    entry:SetSize(80, 30)
    entry:SetPos(110, 70)
    entry:SetNumeric(true)
    entry:SetText("1")
    entry:SetFont("ZGrad_Mayor_Sub")
    entry:SetTextColor(C.text)
    entry:SetPaintBackground(false)
    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, C.panel)
        self:DrawTextEntryText(C.text, C.accent, C.text)
    end

    local btn = vgui.Create("DButton", frame)
    btn:SetSize(120, 35)
    btn:SetPos(90, 130)
    btn:SetText("")
    btn.Paint = function(self, w, h)
        local hov = self:IsHovered()
        draw.RoundedBox(6, 0, 0, w, h, hov and C.greenHov or C.green)
        draw.SimpleText("ПОДТВЕРДИТЬ", "ZGrad_Mayor_Small", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btn.DoClick = function()
        local mins = tonumber(entry:GetValue()) or 0
        if mins > 20 then mins = 20 end
        if mins < 1 then mins = 1 end
        
        net.Start("ZGrad_Rental_Request")
            net.WriteString(class)
            net.WriteUInt(mins, 8)
        net.SendToServer()
        
        frame:Remove()
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(24, 24)
    close:SetPos(268, 8)
    close:SetText("✕")
    close:SetFont("ZGrad_Mayor_Sub")
    close:SetTextColor(C.textDim)
    close.Paint = function() end
    close.DoClick = function() frame:Remove() end
end

local function OpenRentalMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(_, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.bg)
        surface.SetDrawColor(C.accent.r, C.accent.g, C.accent.b, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        draw.RoundedBoxEx(10, 0, 0, w, 50, C.panel, true, true, false, false)
        draw.RoundedBoxEx(10, 0, 0, w, 4, C.accent, true, true, false, false)
        draw.SimpleText("🚗 АРЕНДА ТРАНСПОРТА", "ZGrad_Mayor_Title", 20, 25, C.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 40, 10)
    closeBtn:SetText("")
    local cHov = false
    closeBtn.OnCursorEntered = function() cHov = true end
    closeBtn.OnCursorExited = function() cHov = false end
    closeBtn.Paint = function(_, w, h)
        if cHov then draw.RoundedBox(15, 0, 0, w, h, C.red) end
        draw.SimpleText("✕", "ZGrad_Mayor_Sub", w/2, h/2, cHov and Color(255,255,255) or C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Remove() end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 60, 10, 10)
    StyledScrollbar(scroll)

    local layout = vgui.Create("DIconLayout", scroll)
    layout:Dock(FILL)
    layout:SetSpaceX(10)
    layout:SetSpaceY(10)

    for _, vData in ipairs(ZGrad_CarRental.Vehicles) do
        local p = layout:Add("DPanel")
        p:SetSize(243, 300)
        
        p.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.panel)
            surface.SetDrawColor(C.separator)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            draw.SimpleText(vData.name, "ZGrad_Mayor_Sub", w/2, 170, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText(DarkRP.formatMoney(vData.price) .. " / мин.", "ZGrad_Mayor_Small", w/2, 195, C.green, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local model = vgui.Create("DModelPanel", p)
        model:SetSize(243, 160)
        model:SetPos(0, 0)
        model:SetModel(vData.model)
        
        local mn, mx = model.Entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
        size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
        size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

        model:SetFOV(45)
        model:SetCamPos(Vector(size, size, size))
        model:SetLookAt((mn + mx) * 0.5)
        
        function model:LayoutEntity(ent)
            ent:SetAngles(Angle(0, RealTime() * 30, 0))
        end

        local rentBtn = vgui.Create("DButton", p)
        rentBtn:SetSize(220, 40)
        rentBtn:SetPos(11.5, 245)
        rentBtn:SetText("")
        
        rentBtn.Paint = function(self, w, h)
            local isRented = RentalData[vData.class]
            local hov = self:IsHovered()
            
            if isRented then
                local timeLeft = math.max(0, math.ceil((isRented.endTime - CurTime()) / 60))
                draw.RoundedBox(6, 0, 0, w, h, C.red)
                draw.SimpleText("АРЕНДОВАНА", "ZGrad_Mayor_Small", w/2, h/2 - 7, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Осв. через: " .. timeLeft .. " мин.", "ZGrad_Mayor_Small", w/2, h/2 + 7, Color(255,255,255, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.RoundedBox(6, 0, 0, w, h, hov and C.accent or C.accentDark)
                draw.SimpleText("АРЕНДОВАТЬ", "ZGrad_Mayor_Small", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        rentBtn.DoClick = function()
            local isRented = RentalData[vData.class]
            if isRented then
                local timeLeft = math.max(0, math.ceil((isRented.endTime - CurTime()) / 60))
                LocalPlayer():ChatPrint("[Аренда] Этот транспорт освободится через " .. timeLeft .. " мин.")
                return
            end
            
            OpenDurationQuery(vData.class, vData.name, vData.price)
        end
    end
end

net.Receive("ZGrad_Rental_OpenMenu", OpenRentalMenu)

-- 3D Timer above vehicles
hook.Add("PostDrawTranslucentRenderables", "ZGrad_Rental_3DTag", function()
    for _, ent in ipairs(ents.GetAll()) do
        if not IsValid(ent) or not ent:GetNWBool("ZGrad_IsRental") then continue end
        
        local class = ent:GetNWString("ZGrad_RentalClass")
        if not class or class == "" then continue end

        local info = RentalData[class]
        if not info then continue end
        
        local timeLeft = info.endTime - CurTime()
        if timeLeft < 0 then continue end

        local pos = ent:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        
        local secs = math.ceil(timeLeft)

        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText("АРЕНДОВАННЫЙ ТРАНСПОРТ", "ZGrad_Mayor_Sub", 0, -25, Color(0, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Освободится через: " .. secs .. " сек.", "ZGrad_Mayor_Title", 0, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end)

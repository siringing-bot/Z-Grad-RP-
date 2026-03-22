--[[---------------------------------------------------------------------------
    Zgrad — НПС "Фальшивомонетчик" (Клиент)
    3D2D заголовок и магазин-меню (Стиль Ученого)
---------------------------------------------------------------------------]]
include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        draw.SimpleTextOutlined("Фальшивомонетчик", "DermaLarge", 0, 0, Color(220, 180, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Оборудование для печати", "DermaDefault", 0, 30, Color(200, 200, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end

net.Receive("ZGrad_CounterfeiterShop", function()
    print("[Counterfeiter] Client received Shop message")
    local npc      = net.ReadEntity()
    local count    = net.ReadInt(8)
    local items    = {}
    for i = 1, count do
        items[i] = {
            name  = net.ReadString(),
            ent   = net.ReadString(),
            price = net.ReadInt(32),
            desc  = net.ReadString(),
            model = net.ReadString(),
        }
    end
    local playerMoney = net.ReadInt(32)

    if not IsValid(npc) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(550, 600)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 30, 245))
        draw.RoundedBox(8, 0, 0, w, 30, Color(40, 40, 80, 200))
        draw.SimpleText("🖨 Фальшивомонетчик — Магазин", "DermaDefaultBold", w / 2, 15, Color(220, 200, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Ваш баланс: " .. DarkRP.formatMoney(playerMoney), "DermaDefault", 10, 45, Color(100, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, 60)
    scroll:SetSize(550, 540)
    scroll:DockMargin(5, 5, 5, 5)
    
    for _, item in ipairs(items) do
        local panel = scroll:Add("DPanel")
        panel:Dock(TOP)
        panel:DockMargin(10, 5, 10, 5)
        panel:SetTall(80)
        panel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(40, 40, 60, 200))
        end
        
        -- Icon
        local icon = vgui.Create("SpawnIcon", panel)
        icon:SetSize(70, 70)
        icon:SetPos(5, 5)
        icon:SetModel(item.model)
        icon:SetMouseInputEnabled(false)
        
        -- Name
        local lblName = vgui.Create("DLabel", panel)
        lblName:SetPos(85, 10)
        lblName:SetText(item.name)
        lblName:SetFont("DermaDefaultBold")
        lblName:SetSize(300, 20)
        lblName:SetColor(Color(255, 255, 255))

        -- Desc
        local lblDesc = vgui.Create("DLabel", panel)
        lblDesc:SetPos(85, 30)
        lblDesc:SetText(item.desc)
        lblDesc:SetFont("DermaDefault")
        lblDesc:SetSize(300, 20)
        lblDesc:SetColor(Color(180, 180, 200))
        
        -- Price
        local lblPrice = vgui.Create("DLabel", panel)
        lblPrice:SetPos(85, 50)
        lblPrice:SetText(DarkRP.formatMoney(item.price))
        lblPrice:SetFont("DermaDefaultBold")
        lblPrice:SizeToContents()
        lblPrice:SetColor(Color(100, 255, 100))
        
        -- Buy button
        local btnBuy = vgui.Create("DButton", panel)
        btnBuy:Dock(RIGHT)
        btnBuy:DockMargin(0, 15, 15, 15)
        btnBuy:SetText("Купить")
        btnBuy:SetWide(100)
        btnBuy:SetColor(Color(255, 255, 255))
        btnBuy.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(60, 60, 120) or Color(40, 40, 100)
            draw.RoundedBox(4, 0, 0, w, h, col)
        end
        btnBuy.DoClick = function()
            net.Start("ZGrad_CounterfeiterBuy")
            net.WriteEntity(npc)
            net.WriteString(item.ent)
            net.SendToServer()
            frame:Close()
        end
    end
end)

include("shared.lua")
local ShopItems = ENT.ShopItems

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()

    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        draw.SimpleTextOutlined("Оружейник", "DermaLarge", 0, 0, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Нажмите E", "DermaDefault", 0, 30, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end

net.Receive("ZGrad_WeaponSeller_OpenShop", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(550, 600)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 30, 245))
        draw.RoundedBox(8, 0, 0, w, 30, Color(40, 40, 80, 200))
        draw.SimpleText("🔫 Оружейник — Магазин", "DermaDefaultBold", w / 2, 15, Color(220, 200, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Ваш баланс: " .. DarkRP.formatMoney(LocalPlayer():getDarkRPVar("money") or 0), "DermaDefault", 10, 45, Color(100, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, 60)
    scroll:SetSize(550, 540)
    scroll:DockMargin(5, 5, 5, 5)

    local categories = {
        { id = "Weapons", name = "Оружие" },
        { id = "Ammo", name = "Патроны" },
        { id = "Attachments", name = "Разное" },
    }

    for _, catData in ipairs(categories) do
        local items = ShopItems[catData.id]
        if items and #items > 0 then
            local header = scroll:Add("DLabel")
            header:Dock(TOP)
            header:SetTall(30)
            header:DockMargin(10, 10, 10, 5)
            header:SetFont("DermaDefaultBold")
            header:SetText(catData.name)
            header:SetColor(Color(255, 200, 50))
            header:SetContentAlignment(5)

            for i, item in ipairs(items) do
                local panel = scroll:Add("DPanel")
                panel:Dock(TOP)
                panel:DockMargin(10, 5, 10, 5)
                panel:SetTall(80)
                panel.Paint = function(self, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, Color(40, 40, 60, 200))
                end

                if item.model then
                    local icon = vgui.Create("SpawnIcon", panel)
                    icon:SetSize(70, 70)
                    icon:SetPos(5, 5)
                    icon:SetModel(item.model)
                    icon:SetMouseInputEnabled(false)
                end

                local lblName = vgui.Create("DLabel", panel)
                lblName:SetPos(85, 10)
                lblName:SetText(item.name)
                lblName:SetFont("DermaDefaultBold")
                lblName:SetSize(300, 20)
                lblName:SetColor(Color(255, 255, 255))

                local finalPrice = item.price
                if LocalPlayer():Team() ~= TEAM_GUN then
                    finalPrice = item.price * 3
                end

                local lblPrice = vgui.Create("DLabel", panel)
                lblPrice:SetPos(85, 30)
                lblPrice:SetText(DarkRP.formatMoney(finalPrice))
                lblPrice:SetFont("DermaDefaultBold")
                lblPrice:SizeToContents()
                lblPrice:SetColor(LocalPlayer():Team() ~= TEAM_GUN and Color(255, 100, 100) or Color(100, 255, 100))

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
                    net.Start("ZGrad_WeaponSeller_BuyItem")
                    net.WriteString(catData.id)
                    net.WriteUInt(i, 8)
                    net.SendToServer()
                end
            end
        end
    end
end)

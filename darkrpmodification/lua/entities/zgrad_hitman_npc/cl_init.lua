include("shared.lua")

-- Переменная для хранения текущей цели у киллера
local ActiveTarget = nil
local ActiveCustomer = nil
local ActivePrice = 0

-- Создаем шрифты побольше
surface.CreateFont("ZGrad_Hitman_Big", {
    font = "Roboto",
    size = 35,
    weight = 800,
})

surface.CreateFont("ZGrad_Hitman_Medium", {
    font = "Roboto",
    size = 24,
    weight = 500,
})

-- 1. ОТРИСОВКА НАД ГОЛОВОЙ NPC
function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    -- Проверка дистанции
    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 250000 then -- 500 units
        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
            -- Z-City Style background
            surface.SetDrawColor(20, 20, 25, 230)
            surface.DrawRect(-160, -25, 320, 50)
            surface.SetDrawColor(180, 40, 40, 255)
            surface.DrawRect(-160, -25, 320, 3)
            surface.DrawRect(-160, 22, 320, 3)

            draw.SimpleText("ЗАКАЗ УБИЙСТВА", "ZGrad_Hitman_Big", 0, 0, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Нажмите E", "DermaDefault", 0, 35, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

-- 2. МЕНЮ ЗАКАЗА (ДЛЯ ЗАКАЗЧИКА)
net.Receive("ZGrad_HitOrder", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 550)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25, 245))
        draw.RoundedBoxEx(6, 0, 0, w, 40, Color(160, 40, 40, 255), true, true, false, false)
        draw.SimpleText("☠ ВЫБЕРИТЕ ЦЕЛЬ", "ZGrad_Hitman_Medium", w / 2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(160, 40, 40, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, 50)
    scroll:SetSize(400, 490)
    scroll:DockMargin(5, 5, 5, 5)

    local sbar = scroll:GetVBar()
    function sbar:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,100)) end
    function sbar.btnUp:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(20,20,20,255)) end
    function sbar.btnDown:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(20,20,20,255)) end
    function sbar.btnGrip:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(160,40,40,150)) end

    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() then -- Нельзя заказать самого себя
            local btn = scroll:Add("DButton")
            btn:Dock(TOP)
            btn:SetHeight(50)
            btn:SetText("")
            btn:DockMargin(10, 0, 15, 8)
            
            btn.Paint = function(self, w, h)
                local col = self:IsHovered() and Color(60, 20, 20, 220) or Color(40, 40, 45, 220)
                draw.RoundedBox(4, 0, 0, w, h, col)
                draw.RoundedBox(4, 0, 0, 4, h, Color(160, 40, 40)) -- Left accent stripe
                
                draw.SimpleText(ply:Nick(), "DermaDefaultBold", 15, h/2 - 8, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                local jobStr = ply.getDarkRPVar and team.GetName(ply:Team()) or "Unknown"
                draw.SimpleText(jobStr, "DermaDefault", 15, h/2 + 8, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                draw.SimpleText("ВЫБРАТЬ", "DermaDefaultBold", w - 15, h/2, self:IsHovered() and Color(255, 100, 100) or Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                Derma_StringRequest(
                    "Введите цену",
                    "Введите цену за убийство " .. ply:Nick() .. "\n(Минимальная цена: 2000)",
                    "2000",
                    function(text)
                        local price = tonumber(text)
                        if not price or price < 2000 then
                            chat.AddText(Color(255,0,0), "[NPC] ", Color(255,255,255), "Неверная цена! Минимум 2000.")
                            return
                        end

                        net.Start("ZGrad_HitOrder")
                        net.WriteEntity(ply)
                        net.WriteInt(price, 32)
                        net.SendToServer()
                        
                        frame:Close()
                    end,
                    nil,
                    "Заказать",
                    "Отмена"
                )
            end
        end
    end
end)

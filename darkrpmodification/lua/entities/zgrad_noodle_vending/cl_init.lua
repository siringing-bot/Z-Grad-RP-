include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local mypos = LocalPlayer():GetPos()
    if mypos:DistToSqr(pos) > 250000 then return end 
    
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    local drawPos = pos + Vector(0,0,80)
    
    local price = self:GetNoodlePrice() or 0
    local count = self:GetNoodleCount() or 0
    
    cam.Start3D2D(drawPos, Angle(0, ang.y, 90), 0.1)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(-150, -40, 300, 100)
        
        draw.SimpleTextOutlined("Продажа лапши", "DermaLarge", 0, -20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Цена: " .. DarkRP.formatMoney(price), "Trebuchet24", 0, 15, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Запас: " .. count .. " шт.", "Trebuchet24", 0, 40, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end

net.Receive("ZGrad_VendingMachine_OpenMenu", function(len)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    
    local curPrice = ent:GetNoodlePrice() or 250
    Derma_StringRequest("Автомат с лапшой", "Укажите цену за одину порцию готовой лапши:", curPrice, function(val)
        local price = tonumber(val) or 0
        if price < 0 then return end
        net.Start("ZGrad_VendingMachine_SetPrice")
        net.WriteEntity(ent)
        net.WriteInt(price, 32)
        net.SendToServer()
    end)
end)

net.Receive("ZGrad_VendingMachine_ConfirmPurchase", function(len)
    local ent = net.ReadEntity()
    local price = net.ReadInt(32)
    if not IsValid(ent) then return end
    
    Derma_Query("Вы уверены что хотите купить одну лапшу за " .. DarkRP.formatMoney(price) .. "?", "Покупка", "Да", function()
        net.Start("ZGrad_VendingMachine_DoPurchase")
        net.WriteEntity(ent)
        net.SendToServer()
    end, "Нет")
end)

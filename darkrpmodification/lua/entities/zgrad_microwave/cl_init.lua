include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 20)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    local text = "Микроволновка"
    local color = Color(200, 200, 200)
    
    if self:GetHasFood() then
        if self:GetIsCooking() then
            local timeLeft = math.max(0, math.ceil(self:GetCookEndTime() - CurTime()))
            text = "Готовится: " .. timeLeft .. " сек."
            color = Color(255, 255, 0)
        elseif self:GetIsBurned() then
            text = "Сгоревший продукт!"
            color = Color(255, 50, 50)
        else
            local burnLeft = math.max(0, math.ceil(self:GetBurnEndTime() - CurTime()))
            text = "Сгорит через: " .. burnLeft .. " сек."
            color = Color(50, 255, 50)
        end
    end
    
    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist < 400 then
        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
            draw.SimpleTextOutlined(text, "DermaDefaultBold", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
end


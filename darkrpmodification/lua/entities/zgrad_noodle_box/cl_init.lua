include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 15)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    local state = self:GetFoodState()
    local text = "Сырая лапша"
    local color = Color(200, 200, 200)
    
    if state == 1 then
        text = "Горячая лапша"
        color = Color(50, 255, 50)
    elseif state == 2 then
        text = "Сгоревший продукт"
        color = Color(255, 50, 50)
    end
    
    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist < 300 then
        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
            draw.SimpleTextOutlined(text, "DermaDefaultBold", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
end


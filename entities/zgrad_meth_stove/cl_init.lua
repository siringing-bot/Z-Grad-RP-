include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local isActive = self:GetIsActive()
    
    local pos = self:GetPos() + Vector(0, 0, 55)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.07)
        if isActive then
            draw.SimpleTextOutlined("🔥 Плита работает...", "DermaDefaultBold", 0, 0, Color(255, 100, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        else
            draw.SimpleTextOutlined("Газовая плита", "DermaDefaultBold", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
            draw.SimpleTextOutlined("Поставьте кастрюлю рядом и нажмите E", "DermaDefault", 0, 18, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        end
    cam.End3D2D()
end

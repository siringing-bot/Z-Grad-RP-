include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 10)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local isOn = self:GetIsOn()
    local col = isOn and Color(0, 255, 0) or Color(255, 0, 0)
    local txt = isOn and "ON" or "OFF"

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        draw.SimpleTextOutlined(txt, "DermaDefaultBold", 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
    cam.End3D2D()
end

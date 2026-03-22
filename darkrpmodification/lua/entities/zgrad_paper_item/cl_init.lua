include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist > 200 then return end

    local pos = self:GetPos() + Vector(0, 0, 14)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.06)
        draw.RoundedBox(4, -70, -14, 140, 28, Color(10, 10, 10, 200))
        draw.SimpleTextOutlined("📄 Бумага (" .. self:GetPaperAmount() .. ")", "DermaDefault", 0, 0, Color(220, 220, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
    cam.End3D2D()
end

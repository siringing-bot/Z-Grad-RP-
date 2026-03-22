include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    if self:GetIsOn() then
        -- Эффект свечения или текст?
        local dist = LocalPlayer():GetPos():Distance(self:GetPos())
        if dist < 300 then
            local pos = self:GetPos() + Vector(0, 0, 25)
            local ang = LocalPlayer():EyeAngles()
            ang:RotateAroundAxis(ang:Forward(), 90)
            ang:RotateAroundAxis(ang:Right(), 90)

            cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
                draw.SimpleTextOutlined("📻 В эфире", "DermaDefault", 0, 0, Color(0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
            cam.End3D2D()
        end
    end
end

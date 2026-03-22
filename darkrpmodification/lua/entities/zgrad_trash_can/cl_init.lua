include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    -- Optional: Draw "TRASH" text on top?
    local pos = self:GetPos() + Vector(0, 0, 50)
    local ang = LocalPlayer():EyeAngles()
    
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    -- Show text only if looking at it
    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 200*200 then
        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
            draw.SimpleTextOutlined("Утилизатор тел", "DermaDefaultBold", 0, 0, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
            draw.SimpleTextOutlined("Кинь труп - получи $100", "DermaDefault", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
end

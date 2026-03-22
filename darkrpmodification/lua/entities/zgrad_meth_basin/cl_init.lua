include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local display = self:GetContentsDisplay()
    local isReady = self:GetIsReady()
    
    local pos = self:GetPos() + Vector(0, 0, 18)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        local yOffset = 0
        
        if display ~= "" then
            local lines = string.Explode("\n", display)
            for _, line in ipairs(lines) do
                draw.SimpleTextOutlined(line, "DermaDefault", 0, yOffset, Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
                yOffset = yOffset + 18
            end
        end
        
        if isReady then
            draw.SimpleTextOutlined("ГОТОВО! Нажмите E", "DermaDefaultBold", 0, yOffset + 10, Color(255, 170, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        elseif display == "" then
            draw.SimpleTextOutlined("Тазик для смешивания", "DermaDefault", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        end
    cam.End3D2D()
end

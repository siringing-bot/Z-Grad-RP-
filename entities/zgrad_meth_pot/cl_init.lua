include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local display = self:GetContentsDisplay()
    local isCooking = self:GetIsCooking()
    local isReady = self:GetIsReady()
    local quality = self:GetCookQuality()
    
    local pos = self:GetPos() + Vector(0, 0, 20)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        local yOffset = 0
        
        -- Display contents
        if display ~= "" then
            local lines = string.Explode("\n", display)
            for _, line in ipairs(lines) do
                draw.SimpleTextOutlined(line, "DermaDefault", 0, yOffset, Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
                yOffset = yOffset + 18
            end
        end
        
        -- Cooking status
        if isCooking then
            if isReady then
                draw.SimpleTextOutlined("ГОТОВО! Нажмите E", "DermaDefaultBold", 0, yOffset + 10, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
                
                -- Quality indicator
                local qualColor = Color(0, 255, 0)
                if quality < 50 then qualColor = Color(255, 0, 0)
                elseif quality < 80 then qualColor = Color(255, 255, 0) end
                
                draw.SimpleTextOutlined("Качество: " .. quality .. "%", "DermaDefaultBold", 0, yOffset + 30, qualColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
            else
                -- Timer display
                local timeLeft = 0
                if self.ZGrad_CookTimeLeft and self.ZGrad_CookLastUpdate then
                    timeLeft = math.max(0, self.ZGrad_CookTimeLeft - (CurTime() - self.ZGrad_CookLastUpdate))
                end
                
                local minutes = math.floor(timeLeft / 60)
                local seconds = math.floor(timeLeft % 60)
                local timeStr = string.format("До готовности %d:%02d", minutes, seconds)
                
                draw.SimpleTextOutlined(timeStr, "DermaDefaultBold", 0, yOffset + 10, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
            end
        elseif display == "" then
            draw.SimpleTextOutlined("Кастрюля", "DermaDefault", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        end
    cam.End3D2D()
end

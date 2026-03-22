--[[---------------------------------------------------------------------------
Z-Grad RP — Door HUD (3D2D)
Отображение цены и владельца прямо на дверях
---------------------------------------------------------------------------]]

if SERVER then return end

-- Шрифты для 3D2D
surface.CreateFont("ZGrad_DoorFont", {
    font = "Roboto",
    size = 120,
    weight = 800,
    antialias = true,
})

surface.CreateFont("ZGrad_DoorFontSmall", {
    font = "Roboto",
    size = 70,
    weight = 500,
    antialias = true,
})

local door_classes = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true,
}

-- Цвета из F4/Tab
local C = {
    bg          = Color(16, 16, 22, 230),
    accent      = Color(0, 180, 255, 255),
    text        = Color(220, 220, 235, 255),
    textDim     = Color(130, 130, 155, 255),
    money       = Color(100, 220, 100, 255),
    owner       = Color(0, 200, 100, 255),
}

hook.Add("PostDrawTranslucentRenderables", "ZGrad_DoorHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local plyPos = ply:GetPos()
    local doors = ents.FindInSphere(plyPos, 400)
    
    for _, ent in ipairs(doors) do
        if not IsValid(ent) or not door_classes[ent:GetClass()] then continue end
        if ent.getKeysNonOwnable and ent:getKeysNonOwnable() then continue end

        local isOwned = ent.isKeysOwned and ent:isKeysOwned()
        local text = ""
        local subtext = ""
        local textColor = C.text

        if isOwned then
            local owner = ent.getDoorOwner and ent:getDoorOwner()
            if IsValid(owner) then
                text = owner:Nick()
                textColor = C.owner
                
                local coowners = ent.getKeysAllowedToHouse and ent:getKeysAllowedToHouse()
                if coowners then
                    for co_sid, _ in pairs(coowners) do
                        local co_ply = player.GetBySteamID(co_sid)
                        if IsValid(co_ply) then
                            text = text .. "\n" .. co_ply:Nick()
                        end
                    end
                end
            else
                local doorGroup = ent.getKeysDoorGroup and ent:getKeysDoorGroup()
                if doorGroup then
                    text = doorGroup
                else
                    text = "Куплено"
                end
                textColor = C.accent
            end
        else
            local doorData = ent.getDoorData and ent:getDoorData() or {}
            -- Используем динамическую стоимость
            local cost = (ent.getKeysDoorCost and ent:getKeysDoorCost()) or doorData.price or ZGrad_GetDoorCost(LocalPlayer(), ent)
            text = "Продается"
            subtext = DarkRP.formatMoney(cost)
            textColor = C.money
        end

        local center = ent:WorldSpaceCenter()
        local forward = ent:GetForward()
        local up = ent:GetUp()
        
        local function DrawSide(pos, ang)
            cam.Start3D2D(pos, ang, 0.05)
                -- Background Box
                local tw, th = 850, 450
                draw.RoundedBox(16, -tw/2, -th/2, tw, th, C.bg)
                
                -- Accent border
                surface.SetDrawColor(C.accent)
                surface.DrawOutlinedRect(-tw/2, -th/2, tw, th, 4)
                
                -- Title Line
                surface.SetDrawColor(Color(255, 255, 255, 20))
                surface.DrawRect(-tw/2 + 40, -th/2 + 100, tw - 80, 2)

                if isOwned then
                    draw.SimpleText("ВЛАДЕЛЕЦ", "ZGrad_DoorFontSmall", 0, -160, C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    -- For multi-line text (roommates), we use draw.DrawText but simple for теперь
                    local lines = string.Explode("\n", text)
                    local yAdd = 0
                    for _, line in ipairs(lines) do
                        draw.SimpleText(line, "ZGrad_DoorFont", 0, 50 + yAdd, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        yAdd = yAdd + 130
                    end
                else
                    draw.SimpleText("НЕДВИЖИМОСТЬ", "ZGrad_DoorFontSmall", 0, -160, C.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(text, "ZGrad_DoorFont", 0, -20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(subtext, "ZGrad_DoorFont", 0, 120, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            cam.End3D2D()
        end

        -- Side 1
        local side1_pos = center + forward * 2
        local side1_ang = ent:GetAngles()
        side1_ang:RotateAroundAxis(side1_ang:Up(), 90)
        side1_ang:RotateAroundAxis(side1_ang:Forward(), 90)
        DrawSide(side1_pos, side1_ang)
        
        -- Side 2
        local side2_pos = center - forward * 2
        local side2_ang = ent:GetAngles()
        side2_ang:RotateAroundAxis(side2_ang:Up(), -90)
        side2_ang:RotateAroundAxis(side2_ang:Forward(), 90)
        DrawSide(side2_pos, side2_ang)
    end
end)

print("[Z-Grad RP] Door HUD (3D2D) Loaded")

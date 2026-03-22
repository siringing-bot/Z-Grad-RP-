--[[---------------------------------------------------------------------------
Z-Grad RP — Crates System (Client)
---------------------------------------------------------------------------]]

-- Шрифты
surface.CreateFont("ZGrad_Crates_HUD", {
    font = "Roboto",
    size = 48,
    weight = 700,
    antialias = true,
})

surface.CreateFont("ZGrad_Crates_HUD_Small", {
    font = "Roboto",
    size = 32,
    weight = 500,
    antialias = true,
})

surface.CreateFont("ZGrad_Crates_Menu_Title", {
    font = "Roboto",
    size = 24,
    weight = 700,
    antialias = true,
})

-- =============================================
-- МЕНЮ ИНВЕНТАРЯ ЯЩИКА
-- =============================================
net.Receive("ZGrad_Crates_OpenMenu", function()
    local crate = net.ReadEntity()
    local items = net.ReadTable()
    
    if not IsValid(crate) then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 500)
    frame:Center()
    frame:SetTitle("Инвентарь (" .. (ZGrad_Crates.Types[crate:GetClass()] and ZGrad_Crates.Types[crate:GetClass()].name or "Ящик") .. ")")
    frame:MakePopup()
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    
    for i, item in ipairs(items) do
        local pnl = vgui.Create("DPanel", scroll)
        pnl:Dock(TOP)
        pnl:SetTall(50)
        pnl:DockMargin(5, 5, 5, 0)
        
        local icon = vgui.Create("SpawnIcon", pnl)
        icon:SetPos(5, 5)
        icon:SetSize(40, 40)
        icon:SetModel(item.model)
        
        local name = vgui.Create("DLabel", pnl)
        name:SetText(item.name or "Неизвестно")
        name:SetPos(55, 15)
        name:SetSize(250, 20)
        name:SetColor(Color(0, 0, 0))
        
        local take = vgui.Create("DButton", pnl)
        take:SetText("Взять")
        take:SetPos(310, 10)
        take:SetSize(70, 30)
        take.DoClick = function()
            net.Start("ZGrad_Crates_TakeItem")
                net.WriteEntity(crate)
                net.WriteUInt(i, 8)
            net.SendToServer()
            
            -- Закрываем чтобы обновилось при следующем открытии (либо обновляем на лету)
            frame:Close()
        end
    end
end)

-- =============================================
-- 3D2D HUD
-- =============================================
hook.Add("PostDrawTranslucentRenderables", "ZGrad_Crates_HUD", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    
    local pos = lp:GetPos()
    local crates = ents.FindInSphere(pos, 400)
    
    for _, crate in ipairs(crates) do
        local typeData = ZGrad_Crates.Types[crate:GetClass()]
        if not typeData then continue end
        
        -- Безопасная проверка на закрытость
        local isLocked = ZGrad_Crates.IsLocked(crate)

        local count = crate:GetNWInt("ZGrad_CrateCount", 0)
        local capacity = typeData.capacity
        local percent = math.floor((count / capacity) * 100)
        
        -- Позиция над ящиком
        local ang = lp:EyeAngles()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        
        local drawPos = crate:WorldSpaceCenter() + Vector(0, 0, crate:OBBMaxs().z + 10)
        
        cam.Start3D2D(drawPos, ang, 0.1)
            -- Название (меняется если закрыт)
            local crateName = (isLocked and "Закрытый " or "") .. typeData.name
            draw.SimpleTextOutlined(crateName, "ZGrad_Crates_HUD", 0, -60, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))
            
            -- Статус (Открыт / Закрыт)
            local statusText = isLocked and "ЗАКРЫТ" or "ОТКРЫТ"
            local col = isLocked and Color(255, 100, 100) or Color(100, 255, 100)
            draw.SimpleTextOutlined(statusText, "ZGrad_Crates_HUD_Small", 0, -20, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
            
            -- Вместимость
            local capText = string.format("%d%% (%d/%d)", percent, count, capacity)
            draw.SimpleTextOutlined(capText, "ZGrad_Crates_HUD_Small", 0, 20, Color(200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
end)

-- =============================================
-- Обработка кнопки F (Lock/Unlock)
-- =============================================
-- Мы используем и BindPress и проверку Bind для надежности
hook.Add("PlayerBindPress", "ZGrad_Crates_F_Lock", function(ply, bind, pressed)
    if not pressed then return end
    
    if bind == "impulse 100" or bind == "+flashlight" then
        local tr = ply:GetEyeTrace()
        local ent = tr.Entity
        
        if IsValid(ent) and (ent:GetClass() == "zgrad_crate_small" or ent:GetClass() == "zgrad_crate_large") then
            -- Проверка дистанции (~200 юнитов)
            if ply:GetTargetVector():DistToSqr(ent:GetPos()) < 90000 or ply:GetPos():DistToSqr(ent:GetPos()) < 90000 then
                net.Start("ZGrad_Crates_ToggleLock")
                    net.WriteEntity(ent)
                net.SendToServer()
                return true -- Подавляем фонарик
            end
        end
    end
end)

print("[Z-Grad RP] Crates System (Client) Loaded")

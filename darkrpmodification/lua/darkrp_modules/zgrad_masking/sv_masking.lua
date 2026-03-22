--[[---------------------------------------------------------------------------
Z-Grad RP — Masking Module (Server)
---------------------------------------------------------------------------]]

function ZGrad_Masking.RemoveMask(ply, suppressJobRestore)
    if not IsValid(ply) or not ply.IsMasked then return end

    print("[ZGrad Mask] Removing mask from " .. ply:Nick() .. (suppressJobRestore and " (suppress job restore)" or ""))

    local oldJobName = ply.OriginalJobName
    local oldModel = ply.OriginalModel
    local oldSkin = ply.OriginalSkin
    local oldPlayerColor = ply.OriginalPlayerColor

    ply.IsMasked = false
    ply.OriginalModel = nil
    ply.OriginalJobName = nil
    ply.OriginalSkin = nil
    ply.OriginalPlayerColor = nil

    timer.Remove("ZGrad_MaskApply_" .. ply:EntIndex())
    timer.Remove("ZGrad_MaskTimer" .. ply:SteamID64())
    
    net.Start("ZGrad_MaskRemove")
    net.Send(ply)

    -- Force model and job back after DarkRP has done its thing
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        
        if not suppressJobRestore and oldJobName then
            ply:setDarkRPVar("job", oldJobName)
        end

        if ply.OriginalJobColor then
            ply:setDarkRPVar("jobColor", ply.OriginalJobColor)
            ply.OriginalJobColor = nil
        end

        if oldModel then
            ply:SetModel(oldModel)
            if oldSkin then ply:SetSkin(oldSkin) end
            if oldPlayerColor then ply:SetPlayerColor(oldPlayerColor) end
        end

        ply:SetupHands()
    end)

    DarkRP.notify(ply, 0, 4, "Маскировка снята.")
end

function ZGrad_Masking.ApplyMask(ply, entToRemove)
    if not IsValid(ply) then return end
    if ply.IsMasked then
        DarkRP.notify(ply, 1, 4, "Вы уже в маскировке!")
        return 
    end

    print("[ZGrad Mask] Applying mask to " .. ply:Nick())
    
    ply.OriginalModel = ply:GetModel()
    ply.OriginalJobName = ply:getDarkRPVar("job") or team.GetName(ply:Team())
    ply.OriginalJobColor = ply:getDarkRPVar("jobColor") or team.GetColor(ply:Team())
    ply.OriginalSkin = ply:GetSkin()
    ply.OriginalPlayerColor = ply:GetPlayerColor()
    ply.IsMasked = true

    local randomModel = ZGrad_Masking.CivilianModels[math.random(#ZGrad_Masking.CivilianModels)]
    ply:setDarkRPVar("job", "Гражданский")
    ply:setDarkRPVar("jobColor", Color(20, 150, 20, 255))
    
    -- Force model change
    ply:SetModel(randomModel)
    ply:SetSkin(ply.OriginalSkin)
    ply:SetPlayerColor(ply.OriginalPlayerColor)
    ply:SetupHands()
    
    -- Use a timer to override DarkRP's enforceplayermodel repeatedly
    local timerID = "ZGrad_MaskApply_" .. ply:EntIndex()
    timer.Create(timerID, 1, 0, function() -- Loop indefinitely until removed
        if IsValid(ply) and ply.IsMasked then
            if ply:GetModel() != randomModel then
                ply:SetModel(randomModel)
                ply:SetSkin(ply.OriginalSkin)
                ply:SetPlayerColor(ply.OriginalPlayerColor)
            end
        else
            timer.Remove(timerID)
        end
    end)

    net.Start("ZGrad_MaskApply")
    net.Send(ply)

    timer.Create("ZGrad_MaskTimer" .. ply:SteamID64(), ZGrad_Masking.Duration, 1, function()
        if IsValid(ply) then
            RemoveMask(ply)
        end
    end)

    if IsValid(entToRemove) then entToRemove:Remove() end

    DarkRP.notify(ply, 0, 4, "Маскировка надета на 10 минут.")
end

-- Key bind T to remove mask
hook.Add("PlayerButtonDown", "ZGrad_MaskKey", function(ply, button)
    if button == KEY_T then
        if ply.IsMasked then
            ZGrad_Masking.RemoveMask(ply)
        end
    end
end)

-- Remove mask on death or job change
hook.Add("PlayerDeath", "ZGrad_MaskClearOnDeath", function(ply)
    if ply.IsMasked then
        ZGrad_Masking.RemoveMask(ply)
    end
end)

hook.Add("OnPlayerChangedTeam", "ZGrad_MaskClearOnJob", function(ply)
    if ply.IsMasked then
        ZGrad_Masking.RemoveMask(ply, true) -- Suppress job restore because we are CHANGING to a new job
    else
        -- Force UI clear just in case
        net.Start("ZGrad_MaskRemove")
        net.Send(ply)
    end
end)

-- Receive mask request from entity
net.Receive("ZGrad_MaskApply", function(len, ply)
    local ent = net.ReadEntity()
    
    if not IsValid(ent) or ent:GetClass() != "zgrad_mask_kit" then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > 65000 then return end
    
    if not ZGrad_Utility.IsCriminal(ply) then
        DarkRP.notify(ply, 1, 4, "Только криминальные деятели могут использовать это!")
        return
    end

    ZGrad_Masking.ApplyMask(ply, ent)
end)

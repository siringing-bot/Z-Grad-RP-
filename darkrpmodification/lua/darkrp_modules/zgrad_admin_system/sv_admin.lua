util.AddNetworkString("ZGrad_Admin_CreateReport")
util.AddNetworkString("ZGrad_Admin_SyncReports")
util.AddNetworkString("ZGrad_Admin_ReportAction")
util.AddNetworkString("ZGrad_Admin_SyncSpecificReport")
util.AddNetworkString("ZGrad_Admin_CloseReport")
util.AddNetworkString("ZGrad_Admin_RequestSync")
util.AddNetworkString("ZGrad_Admin_ToggleNoclip")

ZGrad_Reports = ZGrad_Reports or {}

local function GetAdmins()
    local admins = {}
    for _, v in ipairs(player.GetAll()) do
        if v:IsAdmin() and v:Team() == TEAM_ADMIN then table.insert(admins, v) end
    end
    return admins
end

local function SyncReportsTo(ply)
    if not ply:IsAdmin() or ply:Team() ~= TEAM_ADMIN then 
        net.Start("ZGrad_Admin_SyncReports")
        net.WriteTable({})
        net.Send(ply)
        return 
    end
    
    local toSync = {}
    for id, rep in pairs(ZGrad_Reports) do
        if not rep.admin then
            table.insert(toSync, {
                id = rep.id,
                caller_nick = rep.caller_nick,
                text = rep.text
            })
        end
    end
    net.Start("ZGrad_Admin_SyncReports")
    net.WriteTable(toSync)
    net.Send(ply)
end

local function SyncReportsToAdmins()
    for _, admin in ipairs(player.GetAll()) do
        if admin:IsAdmin() and admin:Team() == TEAM_ADMIN then
            SyncReportsTo(admin)
        end
    end
end

net.Receive("ZGrad_Admin_RequestSync", function(len, ply)
    if not ply:IsAdmin() or ply:Team() ~= TEAM_ADMIN then return end
    SyncReportsTo(ply)
end)

net.Receive("ZGrad_Admin_CreateReport", function(len, ply)
    local text = net.ReadString()
    text = string.Left(text, 1000)
    
    -- Check if already has active report
    for k, v in pairs(ZGrad_Reports) do
        if v.caller == ply then
            DarkRP.notify(ply, 1, 4, "У вас уже есть активная жалоба!")
            return
        end
    end
    
    local reportId = os.time() .. "_" .. ply:EntIndex()
    local report = {
        id = reportId,
        caller = ply,
        caller_nick = ply:Nick(),
        caller_steamid = ply:SteamID(),
        text = text,
        admin = nil
    }
    
    ZGrad_Reports[reportId] = report
    DarkRP.notify(ply, 0, 4, "Жалоба успешно отправлена администрации.")
    SyncReportsToAdmins()
end)

net.Receive("ZGrad_Admin_ReportAction", function(len, admin)
    if not admin:IsAdmin() or admin:Team() ~= TEAM_ADMIN then return end
    
    local action = net.ReadString()
    local reportId = net.ReadString()
    
    local report = ZGrad_Reports[reportId]
    if not report then 
        DarkRP.notify(admin, 1, 4, "Данная жалоба уже закрыта или не существует.")
        return 
    end
    
    if action == "accept" then
        if report.admin and report.admin ~= admin then
            DarkRP.notify(admin, 1, 4, "Эту жалобу уже принял другой администратор.")
            return
        end
        report.admin = admin
        
        net.Start("ZGrad_Admin_SyncSpecificReport")
        net.WriteTable({
            id = report.id,
            caller_nick = report.caller_nick,
            caller_steamid = report.caller_steamid,
            text = report.text
        })
        net.Send(admin)
        
        SyncReportsToAdmins() -- Refresh everyone else's list to remove this report
        return
    end

    if not report.admin or report.admin ~= admin then return end
    
    if action == "goto" then
        if not IsValid(report.caller) then DarkRP.notify(admin, 1, 4, "Игрок не найден (возможно, он вышел).") return end
        report.last_teleport = { entity = admin, pos = admin:GetPos(), ang = admin:EyeAngles() }
        admin:SetPos(report.caller:GetPos() + report.caller:GetForward() * 50)
        admin:SetEyeAngles((report.caller:GetPos() - admin:GetPos()):Angle())
        DarkRP.notify(admin, 0, 4, "Вы телепортировались к игроку.")
        
    elseif action == "bring" then
        if not IsValid(report.caller) then DarkRP.notify(admin, 1, 4, "Игрок не найден (возможно, он вышел).") return end
        report.last_teleport = { entity = report.caller, pos = report.caller:GetPos(), ang = report.caller:EyeAngles() }
        report.caller:SetPos(admin:GetPos() + admin:GetForward() * 50)
        report.caller:SetEyeAngles((admin:GetPos() - report.caller:GetPos()):Angle())
        DarkRP.notify(admin, 0, 4, "Вы телепортировали игрока к себе.")
        
    elseif action == "return" then
        if report.last_teleport and IsValid(report.last_teleport.entity) then
            report.last_teleport.entity:SetPos(report.last_teleport.pos)
            report.last_teleport.entity:SetEyeAngles(report.last_teleport.ang)
            report.last_teleport = nil
            DarkRP.notify(admin, 0, 4, "Возврат выполнен успешно.")
        else
            DarkRP.notify(admin, 1, 4, "Нет сохраненной позиции для возврата.")
        end
        
    elseif action == "close" then
        ZGrad_Reports[reportId] = nil
        net.Start("ZGrad_Admin_CloseReport")
        net.Send(admin)
        SyncReportsToAdmins()
        if IsValid(report.caller) then
            DarkRP.notify(report.caller, 0, 4, "Ваша жалоба была закрыта администратором " .. admin:Nick())
        end
    end
end)

hook.Add("OnPlayerChangedTeam", "ZGrad_Admin_Cleanup", function(ply, before, after)
    if before == (TEAM_ADMIN or -1) then
        ply:SetMoveType(MOVETYPE_WALK)
        ply:SetNoDraw(false)
        ply:SetRenderMode(RENDERMODE_NORMAL)
        ply:DrawShadow(true)
        for _, wep in ipairs(ply:GetWeapons()) do
            wep:SetNoDraw(false)
            wep:SetRenderMode(RENDERMODE_NORMAL)
        end
    end
    
    if ply:IsAdmin() then
        if after == TEAM_ADMIN then
            SyncReportsTo(ply)
        else
            -- Release reports that were being handled by this admin
            local released = false
            for id, rep in pairs(ZGrad_Reports) do
                if rep.admin == ply then
                    rep.admin = nil
                    released = true
                end
            end
            if released then
                SyncReportsToAdmins()
            end
            
            -- Clear the client's reports if they left the job
            net.Start("ZGrad_Admin_SyncReports")
            net.WriteTable({})
            net.Send(ply)
        end
    end
end)

-- Noclip & Invis logic
local function SetAdminInvis(ply, bInvis)
    if not IsValid(ply) then return end
    ply:SetNoDraw(bInvis)
    ply:SetRenderMode(bInvis and RENDERMODE_NONE or RENDERMODE_NORMAL)
    ply:DrawShadow(not bInvis)
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            wep:SetNoDraw(bInvis)
            wep:SetRenderMode(bInvis and RENDERMODE_NONE or RENDERMODE_NORMAL)
        end
    end
end

hook.Add("PlayerNoClip", "ZGrad_Admin_Restriction", function(ply, state)
    if not ply:IsAdmin() then return false end
    
    if not TEAM_ADMIN or ply:Team() ~= TEAM_ADMIN then
        if state then DarkRP.notify(ply, 1, 4, "Ноуклип доступен только в профессии Админа!") end
        return false
    end
    
    timer.Simple(0, function()
        if IsValid(ply) then SetAdminInvis(ply, ply:GetMoveType() == MOVETYPE_NOCLIP) end
    end)
    return true
end)

ZGrad_Admin_NoclipCooldown = ZGrad_Admin_NoclipCooldown or {}
net.Receive("ZGrad_Admin_ToggleNoclip", function(len, ply)
    if not ply:IsAdmin() or (TEAM_ADMIN and ply:Team() ~= TEAM_ADMIN) then return end
    
    local curTime = CurTime()
    if (ZGrad_Admin_NoclipCooldown[ply] or 0) > curTime then return end
    ZGrad_Admin_NoclipCooldown[ply] = curTime + 0.3
    
    local newState = (ply:GetMoveType() ~= MOVETYPE_NOCLIP)
    ply:SetMoveType(newState and MOVETYPE_NOCLIP or MOVETYPE_WALK)
    SetAdminInvis(ply, newState)
end)

hook.Add("PlayerSwitchWeapon", "ZGrad_Admin_NoclipInvisWep", function(ply)
    if ply:Team() == TEAM_ADMIN and ply:GetMoveType() == MOVETYPE_NOCLIP then
        timer.Simple(0, function() if IsValid(ply) then SetAdminInvis(ply, true) end end)
    end
end)

hook.Add("WeaponEquip", "ZGrad_Admin_NoclipInvisWepEquip", function(wep, ply)
    if IsValid(ply) and ply:Team() == TEAM_ADMIN and ply:GetMoveType() == MOVETYPE_NOCLIP then
        timer.Simple(0, function() if IsValid(ply) then SetAdminInvis(ply, true) end end)
    end
end)

-- Continuous Enforcement
timer.Create("ZGrad_Admin_InvisEnforce", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == TEAM_ADMIN and ply:GetMoveType() == MOVETYPE_NOCLIP then
            if not ply:GetNoDraw() then
                SetAdminInvis(ply, true)
            end
        end
    end
end)

-- Block !god / /god commands if they exist in other scripts
hook.Add("PlayerSay", "ZGrad_Admin_BlockGod", function(ply, text)
    if not IsValid(ply) then return end
    local low = string.lower(text or "")
    if low == "!god" or low == "/god" then
        return ""
    end
end)



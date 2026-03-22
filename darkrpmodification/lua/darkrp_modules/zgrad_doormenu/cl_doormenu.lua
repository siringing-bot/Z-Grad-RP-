--[[---------------------------------------------------------------------------
Z-Grad RP — Door Menu (F4/Tab Style)
---------------------------------------------------------------------------]]

local C = {
    bg          = Color(16, 16, 22, 250),
    sidebar     = Color(22, 22, 30, 255),
    content     = Color(20, 20, 28, 255),
    accent      = Color(0, 180, 255, 255),
    accentDark  = Color(0, 120, 200, 255),
    text        = Color(220, 220, 235, 255),
    textDim     = Color(130, 130, 155, 255),
    btn         = Color(28, 28, 40, 255),
    btnHover    = Color(35, 35, 50, 255),
    btnAction   = Color(0, 160, 255, 255),
    money       = Color(100, 220, 100, 255),
}

surface.CreateFont("ZGrad_DoorMenu_Title", { font = "Roboto", size = 24, weight = 700 })
surface.CreateFont("ZGrad_DoorMenu_Btn", { font = "Roboto", size = 16, weight = 600 })
surface.CreateFont("ZGrad_DoorMenu_Info", { font = "Roboto", size = 14, weight = 400 })

local function CreateStyledButton(parent, text, y, callback, isAction)
    local btn = vgui.Create("DButton", parent)
    btn:SetSize(parent:GetWide() - 40, 45)
    btn:SetPos(20, y)
    btn:SetText("")
    
    local hover = false
    btn.OnCursorEntered = function() hover = true end
    btn.OnCursorExited = function() hover = false end
    
    btn.Paint = function(self, w, h)
        local baseCol = isAction and C.btnAction or (hover and C.btnHover or C.btn)
        draw.RoundedBox(8, 0, 0, w, h, baseCol)
        
        if hover and not isAction then
            surface.SetDrawColor(C.accent)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        
        draw.SimpleText(text, "ZGrad_DoorMenu_Btn", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    btn.DoClick = function()
        callback()
        if IsValid(parent) then parent:Close() end
        surface.PlaySound("ui/buttonclick.wav")
    end
    
    return btn
end

local ZGradDoorMenuFrame = nil

local function openSimplifiedMenu(ent)
    if IsValid(ZGradDoorMenuFrame) then ZGradDoorMenuFrame:Close() end

    local w, h = 350, 400
    local Frame = vgui.Create("DFrame")
    ZGradDoorMenuFrame = Frame
    Frame:SetSize(w, h)
    Frame:SetTitle("")
    Frame:MakePopup()
    Frame:Center()
    Frame:ShowCloseButton(false)

    Frame.Paint = function(self, pw, ph)
        draw.RoundedBox(12, 0, 0, pw, ph, C.bg)
        draw.RoundedBoxEx(12, 0, 0, pw, 60, C.sidebar, true, true, false, false)
        
        surface.SetDrawColor(C.accent)
        surface.DrawRect(0, 58, pw, 2)
        
        draw.SimpleText("УПРАВЛЕНИЕ ДВЕРЬЮ", "ZGrad_DoorMenu_Title", pw / 2, 30, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local btnClose = vgui.Create("DButton", Frame)
    btnClose:SetSize(32, 32)
    btnClose:SetPos(w - 40, 14)
    btnClose:SetText("✕")
    btnClose:SetFont("ZGrad_DoorMenu_Title")
    btnClose:SetColor(C.textDim)
    btnClose.Paint = function() end
    btnClose.DoClick = function() Frame:Close() end

    local currentY = 80
    local isOwnedByMe = ent:isKeysOwnedBy(LocalPlayer())
    local isOwned = ent:isKeysOwned()

    if not isOwned then
        local costValue = ZGrad_GetDoorCost(LocalPlayer(), ent)
        local cost = DarkRP.formatMoney(costValue)
        CreateStyledButton(Frame, "КУПИТЬ ДВЕРЬ (" .. cost .. ")", currentY, function()
            RunConsoleCommand("darkrp", "toggleown")
        end, true)
        currentY = currentY + 60
    elseif isOwnedByMe then
        CreateStyledButton(Frame, "ПРОДАТЬ НЕДВИЖИМОСТЬ", currentY, function()
            RunConsoleCommand("darkrp", "toggleown")
        end)
        currentY = currentY + 60

        CreateStyledButton(Frame, "ДОБАВИТЬ СОЖИТЕЛЬНИКА", currentY, function()
            local menu = DermaMenu()
            for _, v in ipairs(DarkRP.nickSortedPlayers()) do
                if v ~= LocalPlayer() and not ent:isKeysOwnedBy(v) then
                    menu:AddOption(v:Nick(), function() RunConsoleCommand("darkrp", "ao", v:UserID()) end)
                end
            end
            menu:Open()
        end)
        currentY = currentY + 60

        local coOwners = ent:getKeysCoOwners() or {}
        if table.Count(coOwners) > 0 then
            CreateStyledButton(Frame, "УДАЛИТЬ СОЖИТЕЛЬНИКА", currentY, function()
                local menu = DermaMenu()
                for k, v in pairs(coOwners) do
                    local ply = player.GetBySteamID(k)
                    if IsValid(ply) then
                        menu:AddOption(ply:Nick(), function() RunConsoleCommand("darkrp", "ro", ply:UserID()) end)
                    end
                end
                menu:Open()
            end)
            currentY = currentY + 60
        end
    end

    if LocalPlayer():IsSuperAdmin() then
        CreateStyledButton(Frame, "АДМИН-МЕНЮ (ПОЛНОЕ)", currentY, function()
            if _G.ZGradOldOpenKeysMenu then _G.ZGradOldOpenKeysMenu() end
        end)
        currentY = currentY + 60
    end

    Frame:SetTall(currentY + 20)
    Frame:Center()
end

local function ApplyOverride()
    if not _G.ZGradOldOpenKeysMenu and DarkRP and DarkRP.openKeysMenu then
        _G.ZGradOldOpenKeysMenu = DarkRP.openKeysMenu
    end
    
    function DarkRP.openKeysMenu()
        local trace = LocalPlayer():GetEyeTrace()
        local ent = trace.Entity
        if not IsValid(ent) or not ent:isKeysOwnable() or trace.HitPos:DistToSqr(LocalPlayer():EyePos()) > 40000 then return end
        openSimplifiedMenu(ent)
    end
    
    hook.Add("ShowTeam", "ZGrad_DoorMenu_F2", function()
        DarkRP.openKeysMenu()
        return true
    end)
    
    net.Receive("DarkRP_KeysMenu", function() DarkRP.openKeysMenu() end)
end

hook.Add("InitPostEntity", "ZGrad_OverrideDoorMenu", function() timer.Simple(1, ApplyOverride) end)
if IsValid(LocalPlayer()) then ApplyOverride() end

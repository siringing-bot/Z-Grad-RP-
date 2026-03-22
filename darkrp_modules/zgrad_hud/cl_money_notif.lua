--[[---------------------------------------------------------------------------
Z-Grad RP — Money Notification System
---------------------------------------------------------------------------]]

local moneyNotifs = {}
local font = "ZGrad_HUD_Large"

surface.CreateFont("ZGrad_MoneyNotif", {
    font = "Roboto",
    size = 28,
    weight = 800,
    antialias = true,
    shadow = true
})

local function AddMoneyNotif(amount)
    table.insert(moneyNotifs, {
        amount = amount,
        time = CurTime(),
        alpha = 0, -- Start at 0 for fade in
        y_offset = 0
    })
    
    -- Quiet coin sound
    surface.PlaySound("ambient/levels/labs/coinslot1.wav")
end

-- Hook into DarkRP money changes
hook.Add("DarkRPVarChanged", "ZGrad_MoneyNotif_Track", function(ply, var, old, new)
    if ply ~= LocalPlayer() then return end
    if var ~= "money" then return end
    
    local diff = new - (old or 0)
    if diff ~= 0 then
        AddMoneyNotif(diff)
    end
end)

hook.Add("HUDPaint", "ZGrad_DrawMoneyNotifs", function()
    local scrW, scrH = ScrW(), ScrH()
    local hudX, hudY = 20, scrH - 140
    
    -- Draw notifications above the HUD info panel
    local startY = hudY - 30
    
    for k, v in ipairs(moneyNotifs) do
        local elapsed = CurTime() - v.time
        
        -- Fade in and Slide up
        if elapsed < 0.5 then
            v.alpha = math.Approach(v.alpha, 255, FrameTime() * 1000)
            v.y_offset = math.Approach(v.y_offset, 20, FrameTime() * 100)
        elseif elapsed > 2 then
            -- Fade out after 2 seconds
            v.alpha = math.Approach(v.alpha, 0, FrameTime() * 500)
        end
        
        if v.alpha <= 0 and elapsed > 2 then
            table.remove(moneyNotifs, k)
            continue
        end
        
        local text = (v.amount > 0 and "+" or "") .. "$" .. string.Comma(math.abs(v.amount))
        local col = v.amount > 0 and Color(100, 255, 100, v.alpha) or Color(255, 100, 100, v.alpha)
        
        draw.SimpleText(text, "ZGrad_MoneyNotif", hudX + 10, startY - v.y_offset - (k-1)*30, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
end)

print("[Z-Grad RP] Money Notification System Loaded")

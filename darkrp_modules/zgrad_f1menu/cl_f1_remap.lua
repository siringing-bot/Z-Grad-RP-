-- Remap F1 to open Spawn Menu
-- This simulates functionality of "Q" menu when F1 is pressed.

if CLIENT then
    -- Hook into GM:ShowHelp which is called when F1 is pressed (if default F1 hook is disabled or not blocking)
    hook.Add("ShowHelp", "ZGrad_F1SpawnMenu", function()
        -- Open the Spawn Menu
        RunConsoleCommand("+menu")
        
        -- We need to close it when key is released, but ShowHelp is a single event.
        -- Standard Q menu works by holding the key. 
        -- If user wants "Typical Q Menu" they probably expect toggle or hold.
        -- Triggering +menu without -menu might get it stuck open.
        
        -- Let's try attempting to open the spawnmenu directly if possible
        if g_SpawnMenu then
            g_SpawnMenu:Open()
        end
        
        return true -- Prevent other hooks
    end)
    
    -- Issue: ShowHelp is usually just "Pressed". Q menu needs "Held".
    -- If we want F1 to behave EXACTLY like Q, we might need Input hooks.
    
    hook.Add("PlayerBindPress", "ZGrad_F1ToMenu", function(ply, bind, pressed)
        if bind == "gm_showhelp" then
            -- When F1 (gm_showhelp) is pressed
            if pressed then
                RunConsoleCommand("+menu")
            else
                RunConsoleCommand("-menu")
            end
            return true
        end
    end)
end

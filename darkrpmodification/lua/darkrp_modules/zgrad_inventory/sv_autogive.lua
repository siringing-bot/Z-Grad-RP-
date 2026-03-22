--[[---------------------------------------------------------------------------
Z-Grad RP — Inventory Auto-Give
---------------------------------------------------------------------------]]

if SERVER then
    hook.Add("PlayerSpawn", "ZGrad_Inventory_GiveSWEP", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            
            local weapons = {
                "zgrad_inventory",
                "weapon_hands_sh",
                "keys",
                "weapon_physgun",
                "gmod_tool"
            }

            for _, class in ipairs(weapons) do
                if not ply:HasWeapon(class) then
                    ply:Give(class)
                end
            end
        end)
    end)
end

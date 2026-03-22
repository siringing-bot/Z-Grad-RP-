--[[---------------------------------------------------------------------------
Z-Grad RP — Global Ownership Handler
Ensures all purchased or spawned items are correctly assigned to the player
---------------------------------------------------------------------------]]

-- General helper to set ownership
local function SetOwner(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return end
    
    -- Set NW2Entity for the custom C-Menu and other systems
    ent:SetNW2Entity("owner", ply)
    
    -- Set DarkRP's internal ownership
    if ent.Setowning_ent then
        ent:Setowning_ent(ply)
    end
    
    -- CRITICAL for DarkRP Limits: Always set SID and UID if possible
    ent.SID = ply:UserID()
    if ent.SetUID then ent:SetUID(ply:UniqueID()) end
end

-- 1. When any DarkRP item is spawned (Entities, Shipments, etc.)
hook.Add("onDarkRPItemSpawned", "ZGrad_Ownership_ItemSpawned", function(ply, model, ent, itemTable)
    SetOwner(ent, ply)
    if itemTable then
        ent.DarkRPItem = itemTable
    end
end)

-- 2. Specifically for Custom Entities bought from F4
hook.Add("playerBoughtCustomEntity", "ZGrad_Ownership_CustomEntity", function(ply, entTable, ent, price)
    SetOwner(ent, ply)
    if entTable then
        ent.DarkRPItem = entTable
    end
end)

-- 3. Specifically for Shipments bought from F4
hook.Add("playerBoughtShipment", "ZGrad_Ownership_Shipment", function(ply, entTable, ent, price)
    SetOwner(ent, ply)
    if entTable then
        ent.DarkRPItem = entTable
    end
end)

-- 4. Specifically for Vehicles bought from F4
hook.Add("playerBoughtVehicle", "ZGrad_Ownership_Vehicle", function(ply, entTable, ent, price)
    SetOwner(ent, ply)
    if entTable then
        ent.DarkRPItem = entTable
    end
end)

-- 5. Optional: Handle props if they are allowed (Sandbox menu)
hook.Add("PlayerSpawnedProp", "ZGrad_Ownership_Prop", function(ply, model, ent)
    SetOwner(ent, ply)
end)

hook.Add("PlayerSpawnedSENT", "ZGrad_Ownership_SENT", function(ply, ent)
    SetOwner(ent, ply)
end)

print("[Z-Grad RP] Global Ownership Handler Loaded (Fixed Limits)")

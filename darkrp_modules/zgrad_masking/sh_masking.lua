print("!!! ZGRAD MASKING MODULE DEBUG !!!")
--[[---------------------------------------------------------------------------
Z-Grad RP — Masking Module (Shared)
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("ZGrad_MaskApply")
    util.AddNetworkString("ZGrad_MaskRemove")
end

ZGrad_Masking = ZGrad_Masking or {}
MsgC(Color(255, 100, 0), "[ZGrad Mask] Loading Shared Module...\n")
ZGrad_Masking.Duration = 600 -- 10 minutes
ZGrad_Masking.CivilianModels = {
    "models/player/group01/male_01.mdl",
    "models/player/group01/male_02.mdl",
    "models/player/group01/male_03.mdl",
    "models/player/group01/male_04.mdl",
    "models/player/group01/male_05.mdl",
    "models/player/group01/male_06.mdl",
    "models/player/group01/male_09.mdl",
}

-- Role checks are moved to ZGrad_Utility.IsCriminal for load reliability.

-- Регистрация переменной напрямую для мгновенной готовности
if DarkRP and DarkRP.registerDarkRPVar then
    DarkRP.registerDarkRPVar("jobColor", net.WriteType, net.ReadType)
else
    hook.Add("DarkRPFinishedLoading", "ZGrad_RegisterMaskingVars", function()
        DarkRP.registerDarkRPVar("jobColor", net.WriteType, net.ReadType)
    end)
end

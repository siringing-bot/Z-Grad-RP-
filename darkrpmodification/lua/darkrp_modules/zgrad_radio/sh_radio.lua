--[[---------------------------------------------------------------------------
Z-Grad RP — Radio Shared Logic
---------------------------------------------------------------------------]]

ZGrad_Radio = ZGrad_Radio or {}
ZGrad_Radio.Waves = ZGrad_Radio.Waves or {}

-- Утилита для поиска активной волны сервера
function ZGrad_Radio.GetWaveByServer(server)
    if not IsValid(server) then return nil end
    return ZGrad_Radio.Waves[server:EntIndex()]
end

print("[Z-Grad RP] Radio Shared Module Loaded")

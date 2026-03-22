--[[---------------------------------------------------------------------------
Z-Grad RP — Arrest System (Shared)
Общие данные: список статей, настройки, точки тюрьмы
---------------------------------------------------------------------------]]

ZGrad_Arrest = ZGrad_Arrest or {}

-- Статьи обвинения: {название, время в секундах}
ZGrad_Arrest.Crimes = {
    { name = "Нарушение комендантского часа",          time = 60  },
    { name = "Нелегальное хранение оружия",            time = 120 },
    { name = "Нелегальная торговля",                   time = 90  },
    { name = "Нападение",                              time = 120 },
    { name = "Убийство",                               time = 180 },
    { name = "Варка наркотических средств",            time = 120 },
    { name = "Распространение наркотических средств",  time = 90  },
    { name = "Проникновение со взломом",               time = 90  },
    { name = "Кража",                                  time = 120 },
    { name = "Манипринтеры",                           time = 120 },
    { name = "Терроризм",                              time = 240 },
}

-- Точки тюрьмы (3 позиции) — ЗАМЕНИ на реальные координаты на карте!
ZGrad_Arrest.JailPositions = {
    Vector(3989.707520, -1078.176636, 243.713821),
    Vector(4154.852539, -1078.421021, 240.435059),
    Vector(4334.768555, -1083.033691, 243.708435),
}

-- Команды, которые могут арестовывать
ZGrad_Arrest.AllowedTeams = {
    -- Инициализируются после загрузки job'ов (в sv_arrest.lua)
}

-- Проверка: является ли игрок полицейским / ФБР
function ZGrad_Arrest.CanArrest(ply)
    if not IsValid(ply) then return false end
    local t = ply:Team()
    return t == TEAM_POLICE or t == TEAM_FBI
end

-- Сетевые сообщения
if SERVER then
    util.AddNetworkString("ZGrad_Arrest_OpenMenu")
    util.AddNetworkString("ZGrad_Arrest_Confirm")
    util.AddNetworkString("ZGrad_Arrest_Timer")
    util.AddNetworkString("ZGrad_Arrest_TimerEnd")
end

print("[Z-Grad RP] Arrest System (Shared) Loaded")

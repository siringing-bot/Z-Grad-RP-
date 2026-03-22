--[[---------------------------------------------------------------------------
Z-Grad RP — Donate Skins (Shared Config)
Конфигурация скинов для донат-системы.

КАК ДОБАВИТЬ НОВЫЙ СКИН:
1. Добавьте запись в таблицу ZGRAD_DONATE_SKINS ниже
2. Укажите уникальный id, название, модель, цену и команду профессии

КАК ДОБАВИТЬ НОВУЮ КАТЕГОРИЮ (ПРОФЕССИЮ):
1. Добавьте запись в таблицу ZGRAD_DONATE_CATEGORIES ниже
2. Используйте command профессии как ключ (поле job)
---------------------------------------------------------------------------]]

-- =============================================
-- КАТЕГОРИИ ПРОФЕССИЙ ДЛЯ ДОНАТА
-- =============================================
-- Добавьте сюда профессии, для которых есть донат-скины
-- job = command профессии из jobs.lua
-- name = отображаемое название вкладки
-- icon = иконка (эмоджи) для вкладки
-- color = цвет акцента категории
ZGRAD_DONATE_CATEGORIES = {
 --   {job = "citizen",    name = "Гражданский", icon = "", color = Color(20, 150, 20)},
    {job = "police",     name = "Полиция",     icon = "", color = Color(25, 25, 170)},
    {job = "maniac",     name = "Маньяк",      icon = "", color = Color(120, 0, 0)},
    {job = "mafia",      name = "Мафия",       icon = "", color = Color(128, 128, 128)},
    {job = "killer",     name = "Наёмник",     icon = "", color = Color(75, 0, 130)},
 --   {job = "fbi",        name = "ФБР",         icon = "", color = Color(10, 10, 80)},
    {job = "terrorist",  name = "Террорист",   icon = "", color = Color(255, 0, 0)},
    {job = "medic",      name = "Медик",       icon = "", color = Color(0, 0, 255)},
    {job = "mayor",      name = "Мэр",         icon = "", color = Color(255, 255, 0)},
    {job = "cook",       name = "Повар",       icon = "", color = Color(238, 99, 99)},
    {job = "drugs",      name = "Метоварщик", icon = "", color = Color(0, 150, 200)},
    {job = "radiohost",  name = "Радиоведущий", icon = "", color = Color(255, 105, 180)},
    {job = "mafiaboss",  name = "Босс Мафии", icon = "", color = Color(255, 105, 180)},
    -- ДОБАВЛЯЙТЕ НОВЫЕ КАТЕГОРИИ ЗДЕСЬ:
    -- {job = "cook", name = "Повар", icon = "", color = Color(238, 99, 99)},
}

-- =============================================
-- ДОНАТ СКИНЫ
-- =============================================
-- id       = уникальный идентификатор скина (строка, без пробелов)
-- name     = отображаемое название скина
-- model    = путь к модели игрока
-- price    = цена в Donate Coins
-- job      = command профессии (должен совпадать с job из категории)
ZGRAD_DONATE_SKINS = {
    -- === ПОЛИЦИЯ ===
    {
        id    = "police_hank",
        name  = "Хэнк Андерсон",
        model = "models/kory/dbh/dbh_hank.mdl",
        price = 500,
        job   = "police",
    },
    {
        id    = "police_hank2",
        name  = "Хэнк Шрейдер",
        model = "models/breaking_bad/hank_schrader.mdl",
        price = 500,
        job   = "police",
    },

    -- === МАНЬЯК ===
    {
        id    = "maniac_dexter",
        name  = "Декстер Морган",
        model = "models/dexter_morgan.mdl",
        price = 250,
        job   = "maniac",
    },

    {
        id    = "maniac_jason",
        name  = "Джейсон Вурхиз",
        model = "models/eu_homicide/mkx_jajon.mdl",
        price = 250,
        job   = "maniac",
    },

    {
        id    = "maniac_ghostface",
        name  = "Гост Фейс",
        model = "models/distac/player/ghostface.mdl",
        price = 250,
        job   = "maniac",
    },

    -- === БОСС МАФИИ ===
    {
        id    = "mafiaboss_mafia",
        name  = "Крестный отец",
        model = "models/vito.mdl",
        price = 350,
        job   = "mafiaboss",
    },

    -- === МАФИЯ ===
    {
        id    = "mafia_yakuza",
        name  = "Якудза",
        model = "models/player/voikanaa/kazuma_kiryu.mdl",
        price = 250,
        job   = "mafia",
    },

    {
        id    = "mafia_italian",
        name  = "Итальянская мафия 1",
        model = "models/humans/mafia/male_09.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_italian2",
        name  = "Итальянская мафия 2",
        model = "models/humans/mafia/male_02.mdl",
        price = 50,
        job   = "mafia",
    },
   
    {
        id    = "mafia_italian3",
        name  = "Итальянская мафия 3",
        model = "models/humans/mafia/male_06.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_italian4",
        name  = "Итальянская мафия 4",
        model = "models/humans/mafia/male_08.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_italian5",
        name  = "Итальянская мафия 5",
        model = "models/humans/mafia/male_07.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_italian6",
        name  = "Итальянская мафия 6",
        model = "models/humans/mafia/male_04.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_bloodz",
        name  = "Бладз",
        model = "models/player/bloodz/slow_1.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_bloodz2",
        name  = "Бладз 2",
        model = "models/player/bloodz/slow_2.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_bloodz3",
        name  = "Бладз 3",
        model = "models/player/bloodz/slow_3.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_cripz",
        name  = "Крипз",
        model = "models/player/cripz/slow_1.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_cripz2",
        name  = "Крипз 2",
        model = "models/player/cripz/slow_2.mdl",
        price = 50,
        job   = "mafia",
    },

    {
        id    = "mafia_cripz3",
        name  = "Крипз 3",
        model = "models/player/cripz/slow_3.mdl",
        price = 50,
        job   = "mafia",
    },


    -- === НАЁМНЫЙ УБИЙЦА ===
    {
        id    = "killer_hitman",
        name  = "Хитман",
        model = "models/player/hitman_absolution_47_classic.mdl",
        price = 500,
        job   = "killer",
    },

    {
        id    = "killer_wick",
        name  = "Джон Уик",
        model = "models/player/korka007/wick.mdl",
        price = 500,
        job   = "killer",
    },

    -- === ТЕРРОРИСТ ===
    {
        id    = "terrorist_laden",
        name  = "Усама бен Ладен",
        model = "models/male_laden_citizen.mdl",
        price = 300,
        job   = "terrorist",
    },

    -- === МЕДИК ===
    {
        id    = "plague_doctor_skin",
        name  = "Чумной Доктор",
        model = "models/player/doktor_haus/plague_doctor.mdl",
        price = 350,
        job   = "medic",
    },

    {
        id    = "doctor_house_skin",
        name  = "Доктор Хаус",
        model = "models/bunny/doctor_house/Doctor_House.mdl",
        price = 500,
        job   = "medic",
    },

    -- === Мэр ===
    {
        id    = "trump_skin",
        name  = "Дональд Трамп",
        model = "models/Player/Donald_Trump.mdl",
        price = 500,
        job   = "mayor",
    },

    {
        id    = "stalin_skin",
        name  = "Иосиф Сталин",
        model = "models/player/jackathan/beta/male_06.mdl",
        price = 500,
        job   = "mayor",
    },

    -- === ПОВАР ===
    {
        id    = "senya_skin",
        name  = "Сеня",
        model = "models/kuhnya/senya.mdl",
        price = 250,
        job   = "cook",
    },

    {
        id    = "fedya_skin",
        name  = "Федя",
        model = "models/kuhnya/fedya.mdl",
        price = 250,
        job   = "cook",
    },

    {
        id    = "barinov_skin",
        name  = "Виктор Баринов",
        model = "models/kuhnya/barinov.mdl",
        price = 500,
        job   = "cook",
    },

    -- === МЕТОВАРЩИК ===
    {
        id    = "walter_white_skin",
        name  = "Уолтер Уайт",
        model = "models/player/walterv2.mdl",
        price = 500,
        job   = "drugs",
    },

    {
        id    = "jesse_skin",
        name  = "Джесси Пинкман",
        model = "models/player/jessev2.mdl",
        price = 500,
        job   = "drugs",
    },

    -- === РАДИО ВЕДУЩИЙ ===
    {
        id    = "borat_skin",
        name  = "Борат",
        model = "models/panman/borat_cosplayer_09.mdl",
        price = 250,
        job   = "radiohost",
    },

    -- ДОБАВЛЯЙТЕ НОВЫЕ СКИНЫ ЗДЕСЬ:
    -- {
    --     id    = "unique_id",
    --     name  = "Название Скина",
    --     model = "models/player/model.mdl",
    --     price = 100,
    --     job   = "command_профессии",
    -- },
}

-- =============================================
-- УТИЛИТЫ (не изменять)
-- =============================================

-- Быстрый поиск скина по ID
function ZGRAD_GetSkinByID(skinID)
    for _, skin in ipairs(ZGRAD_DONATE_SKINS) do
        if skin.id == skinID then
            return skin
        end
    end
    return nil
end

-- Получить скины для конкретной профессии
function ZGRAD_GetSkinsForJob(jobCommand)
    local result = {}
    for _, skin in ipairs(ZGRAD_DONATE_SKINS) do
        if skin.job == jobCommand then
            table.insert(result, skin)
        end
    end
    return result
end

-- Получить team ID по command
function ZGRAD_GetTeamByCommand(cmd)
    if not RPExtraTeams then return nil end
    for teamID, data in pairs(RPExtraTeams) do
        if data.command == cmd then
            return teamID
        end
    end
    return nil
end

print("[Z-Grad RP] Donate Skins Config loaded")

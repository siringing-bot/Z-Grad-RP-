--[[---------------------------------------------------------------------------
Z-Grad RP — Кастомные профессии
---------------------------------------------------------------------------]]

print("[Z-Grad RP] Jobs file LOADING...")

-- =============================================
-- ГРАЖДАНСКИЙ
-- =============================================
TEAM_CITIZEN = DarkRP.createJob("Гражданский", {
    color = Color(20, 150, 20, 255),
    model = {
        "models/player/group01/male_01.mdl",
        "models/player/group01/male_02.mdl",
        "models/player/group01/male_03.mdl",
        "models/player/group01/male_04.mdl",
        "models/player/group01/male_05.mdl",
        "models/player/group01/male_06.mdl",
        "models/player/group01/male_07.mdl",
        "models/player/group01/male_08.mdl",
        "models/player/group01/male_09.mdl",
        "models/player/group01/female_01.mdl",
        "models/player/group01/female_02.mdl",
        "models/player/group01/female_03.mdl",
        "models/player/group01/female_04.mdl",
        "models/player/group01/female_06.mdl",
    },
    description = [[Обычный гражданин города Z-Grad.
Найди работу, открой бизнес или просто живи своей жизнью.]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "citizen",
    max = 0,
    salary = 45,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Гражданские",
})

-- =============================================
-- ПАРКУРИСТ
-- =============================================
TEAM_PARKURIST = DarkRP.createJob("Паркурист", {
    vip = true,
    color = Color(255, 255, 0, 255),
    model = {
        "models/kennet/dealer_07.mdl",
    },
    description = "Паркурист города Z-Grad. [VIP БОНУС: Бесконечный бег!]",
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "parkurist",
    max = 3,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Криминал",
    customCheck = function(ply) return CLIENT or ply:IsUserGroup("vip") or ply:IsAdmin() end,
    CustomCheckFailMsg = "Эта профессия только для VIP игроков!",
})

-- =============================================
-- МЕДИК
-- =============================================
TEAM_MEDIC = DarkRP.createJob("Медик", {
    color = Color(0, 0, 255, 255),
    model = {
        "models/player/kerry/medic/medic_02.mdl",
        "models/player/kerry/medic/medic_05.mdl",
        "models/player/kerry/medic/medic_06.mdl",
        "models/player/kerry/medic/medic_07.mdl",
        "models/player/kerry/medic/medic_04.mdl",
        "models/player/kerry/medic/medic_01.mdl",
        "models/player/kerry/medic/medic_03.mdl",
        "models/player/kerry/medic/medic_01_f.mdl",
        "models/player/kerry/medic/medic_02_f.mdl",
        "models/player/kerry/medic/medic_03_f.mdl",
        "models/player/kerry/medic/medic_04_f.mdl",
        "models/player/kerry/medic/medic_05_f.mdl",
        "models/player/kerry/medic/medic_06_f.mdl",
        "models/player/kerry/medic/medic_07_f.mdl",
    },
    description = [[Медик города Z-Grad.
Лечи раненых, спасай жизни и поддерживай здоровье граждан.]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "medic",
    max = 3,
    salary = 45,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Гражданские",
})

-- =============================================
-- БОМЖ
-- =============================================
TEAM_BUM = DarkRP.createJob("Бомж", {
    color = Color(150, 50, 50, 255),
    model = {
        "models/jessev92/player/l4d/m9-hunter.mdl",
    },
    description = [[Бомж города Z-Grad.
Просто живи своей жизнью.]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "bum",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Гражданские",
})

-- =============================================
-- БАНКИР
-- =============================================
TEAM_BANKER = DarkRP.createJob("Банкир", {
    color = Color(127, 255, 0, 255),
    model = {
        "models/player/hostage/hostage_01.mdl",
    },
    description = [[Банкир города Z-Grad.
Работай с деньгами.]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "banker",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Бизнес",
})


-- =============================================
-- АВТО МЕХАНИК
-- =============================================
TEAM_AUTOMEHANIK = DarkRP.createJob("Автомеханик", {
    color = Color(150, 150, 50, 255),
    model = {
        "models/player/odessa.mdl",
    },
    description = [[Автомеханик города Z-Grad.
Ремонтируй машины.]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "automehanik",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Бизнес",
})

-- =============================================
-- ОХРАННИК
-- =============================================
TEAM_SECURITY = DarkRP.createJob("Охранник", {
    color = Color(0, 0, 255, 255),
    model = {
        "models/player/odessa.mdl",
    },
    description = [[Охранник города Z-Grad.
Охраняй частную собственность.]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "security",
    max = 3,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false,
    category = "Бизнес",
})



-- =============================================
-- ПОЛИЦЕЙСКИЙ
-- =============================================
TEAM_POLICE = DarkRP.createJob("Полицейский", {
    color = Color(25, 25, 170, 255),
    model = {
        "models/dannio/usapolice/usapolice.mdl",
        "models/dannio/usapolice/usapolice.mdl",
    },
    description = [[Полицейский города Z-Grad.
Защищай закон и порядок, арестовывай преступников.]],
    weapons = {"arrest_stick", "unarrest_stick", "stunstick", "door_ram", "weaponchecker", "weapon_glock17", "keys"},
    command = "police",
    max = 10,
    salary = 80,
    admin = 0,
    vote = false,
    hasLicense = true,
    candemote = true,
    category = "Правительство",
    PlayerLoadout = function(ply)
        ply:SetArmor(25)
    end,
})

-- =============================================
-- ФБР
-- =============================================
TEAM_FBI = DarkRP.createJob("Агент ФБР", {
    color = Color(10, 10, 80, 255),
    model = {
        "models/player/icpd/fbi_armoured/male_gta_masked.mdl",
    },
    description = [[Агент ФБР. Элитное подразделение.
Расследуй серьёзные преступления, работай под прикрытием.]],
    weapons = {"arrest_stick", "unarrest_stick", "stunstick", "door_ram", "weaponchecker", "weapon_m4a1", "weapon_glock17", "keys"},
    command = "fbi",
    max = 5,
    salary = 100,
    admin = 0,
    vote = false,
    hasLicense = true,
    candemote = true,
    category = "Правительство",
    PlayerLoadout = function(ply)
        ply:SetArmor(50)
    end,
})

-- =============================================
-- МЭР
-- =============================================
TEAM_MAYOR = DarkRP.createJob("Мэр", {
    color = Color(150, 20, 20, 255),
    model = "models/player/breen.mdl",
    description = [[Мэр города Z-Grad.
Устанавливай законы, управляй полицией, объявляй розыск.]],
    weapons = {"keys", "pocket", "weapon_pistol"},
    command = "mayor",
    max = 1,
    salary = 120,
    admin = 0,
    vote = true,
    hasLicense = true,
    candemote = true,
    category = "Правительство",
    mayor = true,
    PlayerDeath = function(ply, weapon, killer)
        ply:teamBan(TEAM_MAYOR, 180) -- Бан на профессию Мэра на 3 минуты
        ply:changeTeam(TEAM_CITIZEN, true)
        if killer:IsPlayer() then
            DarkRP.notifyAll(0, 4, "Мэр был убит!")
        else
            DarkRP.notifyAll(0, 4, "Мэр погиб!")
        end
    end,
})

print("[Z-Grad RP] Jobs loaded successfully!")

-- =============================================
-- ПРОДАВЕЦ ОРУЖИЯ
-- =============================================
TEAM_GUN = DarkRP.createJob("Продавец оружия", {
    color = Color(255, 140, 0, 255),
    model = "models/player/monk.mdl",
    description = [[Продавец оружия.
Продавай оружие другим игрокам, но помни — продажа нелегальным лицам карается законом!]],
    weapons = {"keys", "pocket"},
    command = "gundealer",
    max = 3,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Бизнес",
})

-- =============================================
-- МАНЬЯК
-- =============================================
TEAM_MANIAC = DarkRP.createJob("Маньяк", {
    vip = true,
    color = Color(120, 0, 0, 255),
    model = "models/player/hostage/hostage_04.mdl",
    description = [[Маньяк, скрывающийся в тенях Z-Grad.
Охоться на жертв, но будь осторожен — полиция тебя ищет.]],
    weapons = {"weapon_pocketknife", "keys"},
    command = "maniac",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
    customCheck = function(ply) return CLIENT or ply:IsUserGroup("vip") or ply:IsAdmin() end,
    CustomCheckFailMsg = "Эта профессия только для VIP игроков!",
})

-- =============================================
-- Метоварщик
-- =============================================
TEAM_DRUGS = DarkRP.createJob("Метоварщик", {
    color = Color(0, 150, 200, 255),
    model = {
        "models/player/eli.mdl",
    },
    description = [[Метоварщик Z-Grad.
Вари лучший товар]],
    weapons = {"keys"},
    command = "drugs",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
})

-- =============================================
-- МАФИЯ
-- =============================================
TEAM_MAFIA = DarkRP.createJob("Мафия", {
    color = Color(128, 128, 128, 255),
    model = {
        "models/player/group03/male_01.mdl",
        "models/player/group03/male_02.mdl",
        "models/player/group03/male_03.mdl",
        "models/player/group03/male_04.mdl",
        "models/player/group03/male_05.mdl",
        "models/player/group03/male_06.mdl",
        "models/player/group03/male_07.mdl",
        "models/player/group03/male_08.mdl",
        "models/player/group03/male_09.mdl",
    },
    description = [[Член мафии Z-Grad.
Взламывай двери, грабь, торгуй нелегальным товаром. Работай в группе!]],
    weapons = {"lockpick", "keypad_cracker", "weapon_pistol", "keys"},
    command = "mafia",
    max = 10,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
})

-- =============================================
-- ГЛАВА МАФИИ
-- =============================================
TEAM_MAFIA_BOSS = DarkRP.createJob("Глава мафии", {
    color = Color(80, 80, 80, 255),
    model = {
        "models/player/gman_high.mdl",
    },
    description = [[Глава мафии Z-Grad.
Управляй своей мафией и устраивай Гос перевороты!]],
    weapons = {"lockpick", "keypad_cracker", "weapon_pistol", "keys", "pocket"},
    command = "mafiaboss",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
})

-- =============================================
-- НАЕМНЫЙ УБИЙЦА
-- =============================================
TEAM_KILLER = DarkRP.createJob("Наемный убийца", {
    color = Color(75, 0, 130, 255),
    model = {
        "models/player/leet.mdl",
    },
    description = [[Наемный убийца Z-Grad.
 Работай в группе!]],
    weapons = {"keys"},
    command = "killer",
    max = 3,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
})

-- =============================================
-- ТЕРОРИСТ
-- =============================================
TEAM_TERRORIST = DarkRP.createJob("Террорист", {
    vip = true,
    color = Color(255, 0, 0, 255),
    model = {
        "models/player/phoenix.mdl",
    },
    description = [[Террорист Z-Grad.
 Устрой хаос!]],
    weapons = {"keys"},
    command = "terrorist",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
    customCheck = function(ply) return CLIENT or ply:IsUserGroup("vip") or ply:IsAdmin() end,
    CustomCheckFailMsg = "Эта профессия только для VIP игроков!",
})

-- =============================================
-- РАБОТОРГОВЕЦ
-- =============================================
TEAM_RABOTORGOVEC = DarkRP.createJob("Работорговец", {
    vip = true,
    color = Color(0, 0, 0, 255),
    model = {
        "models/kennet/dealer_07.mdl",
    },
    description = [[Работорговец Z-Grad.
Продавай людей!]],
    weapons = {"keys"},
    command = "rabotorgovets",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Криминал",
    customCheck = function(ply) return CLIENT or ply:IsUserGroup("vip") or ply:IsAdmin() end,
    CustomCheckFailMsg = "Эта профессия только для VIP игроков!",
})



-- =============================================
-- ПОВАР
-- =============================================
TEAM_COOK = DarkRP.createJob("Повар", {
    color = Color(238, 99, 99, 255),
    model = {
        "models/ecott/chefcitizen.mdl",
    },
    description = [[Повар города Z-Grad.
Готовьте вкусную лапшу и продавайте ее людям, чтобы они не умерли от голода!]],
    weapons = {"keys"},
    command = "cook",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Бизнес",
})

-- =============================================
-- РАДИОВЕДУЩИЙ
-- =============================================
TEAM_RADIOHOST = DarkRP.createJob("Радиоведущий", {
    color = Color(255, 105, 180, 255),
    model = {
        "models/player/p2_chell.mdl",
        "models/player/kleiner.mdl",
    },
    description = [[Радиоведущий города Z-Grad.
Создавай свою радиоволну, вещай на весь город и зарабатывай на рекламе или платных подписках!]],
    weapons = {"keys", "pocket", "weapon_physcannon"},
    command = "radiohost",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Бизнес",
})

-- =============================================
-- АДМИН
-- =============================================
TEAM_ADMIN = DarkRP.createJob("Админ", {
    color = Color(255, 255, 255, 255),
    model = {
        "models/player/corpse1.mdl",
    },
    description = [[Админ города Z-Grad.
Администрируйте город!]],
    weapons = {"keys"},
    command = "admin",
    max = 0,
    salary = 0,
    admin = 1,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Администрация",
})

--[[---------------------------------------------------------------------------
Команда по умолчанию и Civil Protection
---------------------------------------------------------------------------]]
GAMEMODE.DefaultTeam = TEAM_CITIZEN

GAMEMODE.CivilProtection = {
    [TEAM_POLICE] = true,
    [TEAM_FBI] = true,
    [TEAM_MAYOR] = true,
}

-- Force set default team on spawn just in case
hook.Add("PlayerInitialSpawn", "ZGrad_ForceDefaultJob", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) and ply:Team() ~= TEAM_CITIZEN then
            ply:changeTeam(TEAM_CITIZEN, true)
            print("[Z-Grad RP] Forced default job for " .. ply:Nick())
        end
    end)
end)

--[[---------------------------------------------------------------------------
Z-Grad RP — Disabled Defaults
Все стандартные профессии, шипменты и сущности отключены.
---------------------------------------------------------------------------]]

DarkRP.disabledDefaults["modules"] = {
    ["afk"]              = true,
    ["chatsounds"]       = false,
    ["events"]           = false,
    ["fpp"]              = false,
    ["f1menu"]           = true,   -- Disable default F1 menu
    ["f4menu"]           = false,  -- Keep enabled so DarkRP handles binding
    ["hitmenu"]          = false,
    ["hud"]              = true,   -- Отключаем стандартный HUD
    ["hungermod"]        = true,   -- Отключен, так как конфликтует с Z-City и убивает от голода
    ["playerscale"]      = false,
    ["sleep"]            = false,
    ["fadmin"]           = true,   -- Disable FAdmin so our custom scoreboard works
    ["animations"]       = false,
    ["chatindicator"]    = false,
}

-- Отключаем ВСЕ стандартные профессии
DarkRP.disabledDefaults["jobs"] = {
    ["chief"]     = true,
    ["citizen"]   = true,
    ["cook"]      = true,
    ["cp"]        = true,
    ["gangster"]  = true,
    ["gundealer"] = true,
    ["hobo"]      = true,
    ["mayor"]     = true,
    ["medic"]     = true,
    ["mobboss"]   = true,
}

-- Отключаем стандартные шипменты
DarkRP.disabledDefaults["shipments"] = {
    ["AK47"]         = true,
    ["Desert eagle"] = true,
    ["Fiveseven"]    = true,
    ["Glock"]        = true,
    ["M4"]           = true,
    ["Mac 10"]       = true,
    ["MP5"]          = true,
    ["P228"]         = true,
    ["Pump shotgun"] = true,
    ["Sniper rifle"] = true,
}

-- Отключаем стандартные сущности
DarkRP.disabledDefaults["entities"] = {
    ["Drug lab"]      = true,
    ["Gun lab"]       = true,
    ["Money printer"] = true,
    ["Microwave"]     = true,
    ["Tip Jar"]       = true,
}

DarkRP.disabledDefaults["vehicles"] = {}

DarkRP.disabledDefaults["food"] = {
    ["Banana"]           = true,
    ["Bunch of bananas"] = true,
    ["Melon"]            = true,
    ["Glass bottle"]     = true,
    ["Pop can"]          = true,
    ["Plastic bottle"]   = true,
    ["Milk"]             = true,
    ["Bottle 1"]         = true,
    ["Bottle 2"]         = true,
    ["Bottle 3"]         = true,
    ["Orange"]           = true,
}

DarkRP.disabledDefaults["doorgroups"] = {
    ["Cops and Mayor only"] = true,
    ["Gundealer only"]      = true,
}

DarkRP.disabledDefaults["ammo"] = {
    ["Pistol ammo"]  = true,
    ["Rifle ammo"]   = true,
    ["Shotgun ammo"] = true,
}

DarkRP.disabledDefaults["agendas"] = {
    ["Gangster's agenda"] = true,
    ["Police agenda"]     = true,
}

DarkRP.disabledDefaults["groupchat"] = {
    [1] = true,
    [2] = true,
    [3] = true,
}

DarkRP.disabledDefaults["hitmen"] = {
    ["mobboss"] = true,
}

DarkRP.disabledDefaults["demotegroups"] = {
    ["Cops"]      = true,
    ["Gangsters"] = true,
}

DarkRP.disabledDefaults["workarounds"] = {
    ["os.date() Windows crash"]                      = false,
    ["SkidCheck"]                                    = false,
    ["Error on edict limit"]                         = false,
    ["Durgz witty sayings"]                          = false,
    ["ULX /me command"]                              = false,
    ["gm_save"]                                      = false,
    ["rp_downtown_v4c_v2 rooftop spawn"]             = false,
    ["White flashbang flashes"]                      = false,
    ["APAnti"]                                       = false,
    ["Wire field generator exploit fix"]             = false,
    ["Door tool class fix"]                          = false,
    ["Constraint crash exploit fix"]                 = false,
    ["Deprecated console commands"]                  = false,
    ["disable CAC"]                                  = false,
}

--[[---------------------------------------------------------------------------
Z-Grad RP — Meth Cooking System (Shared Config)
Loaded on both server and client
---------------------------------------------------------------------------]]

ZGRAD_METH = ZGRAD_METH or {}

ZGRAD_METH.Ingredients = {
    ["red_phosphorus"]  = { name = "Красный фосфор",       grams = 50,  price = 1500, model = "models/props_lab/jar01a.mdl" },
    ["solvent"]         = { name = "Растворитель",          grams = 200, price = 400,  model = "models/props_junk/garbage_plasticbottle001a.mdl" },
    ["distilled_water"] = { name = "Дистиллированная вода", grams = 300, price = 600,  model = "models/props_junk/plasticbucket001a.mdl" },
    ["lithium"]         = { name = "Литий",                 grams = 60,  price = 800,  model = "models/props_junk/garbage_metalcan001a.mdl" },
    ["pseudoephedrine"] = { name = "Псевдоэфедрин",         grams = 80,  price = 1400, model = "models/props_junk/garbage_milkcarton001a.mdl" },
    ["methylamine"]     = { name = "Метиламин",             grams = 80,  price = 1000, model = "models/props_junk/garbage_plasticbottle002a.mdl" },
    ["crimson_x"]       = { name = 'Реагент "Crimson-X"',   grams = 20,  price = 3000, model = "models/props_junk/garbage_bag001a.mdl" },
}

ZGRAD_METH.Recipes = {
    ["meth"] = {
        name = "Метамфетамин",
        container = "pot",
        pricePerGram = 250,
        cookTime = 60,
        outputGrams = 50,
        color = Color(255, 255, 255),
    },
    ["blue_meth"] = {
        name = "Синий Метамфетамин",
        container = "pot",
        pricePerGram = 500,
        cookTime = 120,
        outputGrams = 50,
        color = Color(0, 150, 255),
    },
    ["red_meth"] = {
        name = "Красный Метамфетамин",
        container = "pot",
        pricePerGram = 1000,
        cookTime = 240,
        outputGrams = 50,
        color = Color(255, 50, 50),
    },
    ["fury13"] = {
        name = "Fury-13",
        container = "basin",
        pricePerGram = 100000,
        cookTime = 0,
        outputGrams = 1,
        color = Color(255, 170, 80),
    },
}

print("[Z-Grad RP] Meth shared config loaded")

local addonName, DrinksMacro = ...

local defaults = {
    drink = {
        enabled = true,
        useThreshold = false,
        threshold = 50,
        showRemaining = false,
    },
    food = {
        enabled = false,
        useThreshold = false,
        threshold = 50,
        showRemaining = false,
    },
}

local function applyDefaults(saved, def)
    for k, v in pairs(def) do
        if type(v) == "table" then
            saved[k] = saved[k] or {}
            applyDefaults(saved[k], v)
        elseif saved[k] == nil then
            saved[k] = v
        end
    end
end

local function formatPct(value)
    return string.format("%d%%", value)
end

local function createConfigPanel()
    local db = DrinksMacroDB
    local category, layout = Settings.RegisterVerticalLayoutCategory("DrinkMacro")

    -- Drinks section
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Drinks"))

    local drinkEnabled = Settings.RegisterProxySetting(category, "DrinksMacro_DrinkEnabled",
        Settings.VarType.Boolean, "Drink Water", true,
        function() return db.drink.enabled end,
        function(v) db.drink.enabled = v end)
    Settings.CreateCheckbox(category, drinkEnabled, "Automatically drink water when needed")

    local drinkUseThreshold = Settings.RegisterProxySetting(category, "DrinksMacro_DrinkUseThreshold",
        Settings.VarType.Boolean, "When mana is below", false,
        function() return db.drink.useThreshold end,
        function(v) db.drink.useThreshold = v end)
    Settings.CreateCheckbox(category, drinkUseThreshold, "Only drink when mana falls below the threshold")

    local drinkThreshold = Settings.RegisterProxySetting(category, "DrinksMacro_DrinkThreshold",
        Settings.VarType.Number, "Mana threshold (%)", 50,
        function() return db.drink.threshold end,
        function(v) db.drink.threshold = v end)
    local drinkSliderOptions = Settings.CreateSliderOptions(1, 100, 1)
    if MinimalSliderWithSteppersMixin then
        drinkSliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatPct)
    end
    Settings.CreateSlider(category, drinkThreshold, drinkSliderOptions, "Drink when mana drops below this percentage")

    local drinkShowRemaining = Settings.RegisterProxySetting(category, "DrinksMacro_DrinkShowRemaining",
        Settings.VarType.Boolean, "Display remaining water", false,
        function() return db.drink.showRemaining end,
        function(v) db.drink.showRemaining = v end)
    Settings.CreateCheckbox(category, drinkShowRemaining, "Show how many water charges remain")

    -- Food section
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Food"))

    local foodEnabled = Settings.RegisterProxySetting(category, "DrinksMacro_FoodEnabled",
        Settings.VarType.Boolean, "Eat Food", false,
        function() return db.food.enabled end,
        function(v) db.food.enabled = v end)
    Settings.CreateCheckbox(category, foodEnabled, "Automatically eat food when needed")

    local foodUseThreshold = Settings.RegisterProxySetting(category, "DrinksMacro_FoodUseThreshold",
        Settings.VarType.Boolean, "When health is below", false,
        function() return db.food.useThreshold end,
        function(v) db.food.useThreshold = v end)
    Settings.CreateCheckbox(category, foodUseThreshold, "Only eat when health falls below the threshold")

    local foodThreshold = Settings.RegisterProxySetting(category, "DrinksMacro_FoodThreshold",
        Settings.VarType.Number, "Health threshold (%)", 50,
        function() return db.food.threshold end,
        function(v) db.food.threshold = v end)
    local foodSliderOptions = Settings.CreateSliderOptions(1, 100, 1)
    if MinimalSliderWithSteppersMixin then
        foodSliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatPct)
    end
    Settings.CreateSlider(category, foodThreshold, foodSliderOptions, "Eat when health drops below this percentage")

    local foodShowRemaining = Settings.RegisterProxySetting(category, "DrinksMacro_FoodShowRemaining",
        Settings.VarType.Boolean, "Display remaining food", false,
        function() return db.food.showRemaining end,
        function(v) db.food.showRemaining = v end)
    Settings.CreateCheckbox(category, foodShowRemaining, "Show how many food charges remain")

    Settings.RegisterAddOnCategory(category)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    DrinksMacroDB = DrinksMacroDB or {}
    applyDefaults(DrinksMacroDB, defaults)
    createConfigPanel()
    self:UnregisterEvent("ADDON_LOADED")
end)

local addonName, DrinksMacro = ...

SLASH_DRINKSMACRODEBUG1 = "/dmdbg"
SlashCmdList["DRINKSMACRODEBUG"] = function()
    local getNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local tip = DrinksMacroScanTooltip
    for bagID = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, getNumSlots(bagID) do
            tip:ClearLines()
            tip:SetBagItem(bagID, slot)
            if tip:NumLines() > 0 then
                print(string.format("-- bag=%d slot=%d --", bagID, slot))
                for i = 1, tip:NumLines() do
                    local r = _G["DrinksMacroScanTooltipTextLeft" .. i]
                    if r and r:GetText() then
                        print("  [" .. i .. "] " .. r:GetText())
                    end
                end
            end
        end
    end
end

SLASH_DRINKSMACRO1 = "/dm"
SlashCmdList["DRINKSMACRO"] = function()
    local water, food = DrinksMacro.Scan.FindBestConsumables()
    if water then
        print(string.format("[DM] Water: bag=%d slot=%d conjured=%s manaRate=%.1f/s",
            water.bagID, water.slot, tostring(water.isConjured), water.manaRate))
    else
        print("[DM] Water: none found")
    end
    if food then
        print(string.format("[DM] Food:  bag=%d slot=%d conjured=%s healthRate=%.1f/s",
            food.bagID, food.slot, tostring(food.isConjured), food.healthRate))
    else
        print("[DM] Food:  none found")
    end
end

local function getItemID(bagID, slot)
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bagID, slot)
    end
    return GetContainerItemID(bagID, slot)
end

function DrinksMacro.UpdateMacro()
    local db = DrinksMacroDB
    local water, food, foodRestoresMana = DrinksMacro.Scan.FindBestConsumables()
    local lines = {}

    local hpMax = UnitHealthMax("player")
    local hpPct = hpMax > 0 and (UnitHealth("player") / hpMax * 100) or 100
    local needsFood = db.food.enabled and food ~= nil and (not db.food.useThreshold or hpPct < db.food.threshold)

    if db.drink.enabled and water and not (needsFood and foodRestoresMana) then
        local mana = UnitMana and UnitMana("player") or UnitPower("player", 0)
        local manaMax = UnitManaMax and UnitManaMax("player") or UnitPowerMax("player", 0)
        local pct = manaMax > 0 and (mana / manaMax * 100) or 100
        if not db.drink.useThreshold or pct < db.drink.threshold then
            local itemID = getItemID(water.bagID, water.slot)
            local name = itemID and GetItemInfo(itemID)
            if name then
                lines[#lines + 1] = "/use " .. name
            end
        end
    end

    if needsFood then
        local itemID = getItemID(food.bagID, food.slot)
        local name = itemID and GetItemInfo(itemID)
        if name then
            lines[#lines + 1] = "/use " .. name
        end
    end

    local body = table.concat(lines, "\n")
    local idx = GetMacroIndexByName("DrinksMacro")
    if idx == 0 then
        CreateMacro("DrinksMacro", "INV_MISC_QUESTIONMARK", body, false)
    else
        EditMacro(idx, "DrinksMacro", nil, body)
    end
end

local dmFrame = CreateFrame("Frame")
dmFrame:RegisterEvent("ADDON_LOADED")
dmFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        DrinksMacro.UpdateMacro()
    end
end)

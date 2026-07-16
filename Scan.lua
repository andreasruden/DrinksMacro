local addonName, DrinksMacro = ...
local L = DrinksMacro.L

DrinksMacro.Scan = {}
local Scan = DrinksMacro.Scan

local ScanTooltip = CreateFrame("GameTooltip", "DrinksMacroScanTooltip", nil, "GameTooltipTemplate")
ScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local cache

local function readTooltipLines(bagID, slot)
    ScanTooltip:ClearLines()
    ScanTooltip:SetBagItem(bagID, slot)
    local lines = {}
    for i = 1, ScanTooltip:NumLines() do
        local region = _G["DrinksMacroScanTooltipTextLeft" .. i]
        local text = region and region:GetText()
        if text then
            lines[#lines + 1] = text
        end
    end
    return lines
end

local function parseRate(line, pattern)
    local amount, duration = line:match(pattern)
    if amount and duration then
        duration = tonumber(duration)
        if duration > 0 then
            return tonumber(amount) / duration
        end
    end
end

-- Parses a combined "Restores X health and Y mana over Z sec" line.
-- @return healthRate, manaRate  number|nil, number|nil
local function parseCombinedRate(line, pattern)
    local healthAmount, manaAmount, duration = line:match(pattern)
    if healthAmount and manaAmount and duration then
        duration = tonumber(duration)
        if duration > 0 then
            return tonumber(healthAmount) / duration, tonumber(manaAmount) / duration
        end
    end
end

-- Returns item info table or nil if slot should be ignored.
local function scanSlot(bagID, slot)
    local lines = readTooltipLines(bagID, slot)
    if #lines == 0 then return end

    local isConjured = false
    local hasUse = false
    local manaRate, healthRate

    for _, line in ipairs(lines) do
        if line:find(L.CONJURED_ITEM, 1, true) then
            isConjured = true
        end

        -- Items granting "Well Fed" are food buffs, not consumable restores.
        if line:find(L.WELL_FED, 1, true) then
            return
        end

        if line:find(L.USE_PREFIX, 1, true) then
            hasUse = true
            local comboHealthRate, comboManaRate = parseCombinedRate(line, L.RESTORE_HEALTH_MANA_PATTERN)
            manaRate   = manaRate   or comboManaRate   or parseRate(line, L.RESTORE_MANA_PATTERN)
            healthRate = healthRate or comboHealthRate or parseRate(line, L.RESTORE_HEALTH_PATTERN)
        end
    end

    if not hasUse or (not manaRate and not healthRate) then return end

    return {
        bagID      = bagID,
        slot       = slot,
        isConjured = isConjured,
        manaRate   = manaRate,
        healthRate = healthRate,
    }
end

local function getContainerItemID(bagID, slot)
    local getItemID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
    return getItemID(bagID, slot)
end

-- Checks that the slots recorded in cache still hold the same items.
local function isCacheValid()
    if not cache.isValid then return false end
    if cache.water and getContainerItemID(cache.water.bagID, cache.water.slot) ~= cache.water.itemID then return false end
    if cache.food and getContainerItemID(cache.food.bagID, cache.food.slot) ~= cache.food.itemID then return false end
    return true
end

-- Returns true when candidate should replace current as the best pick.
-- Conjured always wins over non-conjured; ties broken by restore rate.
local function isBetter(candidate, current, rateKey)
    if not current then return true end
    if candidate.isConjured ~= current.isConjured then
        return candidate.isConjured
    end
    return candidate[rateKey] > current[rateKey]
end

--- Scans the backpack and all bags for water and food consumables.
-- @return bestWater      table|nil  { bagID, slot, isConjured, manaRate }
-- @return bestFood       table|nil  { bagID, slot, isConjured, healthRate }
-- @return foodRestoresMana boolean  true if bestFood also restores mana
function Scan.FindBestConsumables()
    if cache then
        if isCacheValid() then
            return cache.bestWater, cache.bestFood, cache.foodRestoresMana
        end
        cache = nil
    end

    local bestWater, bestFood

    local getNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    for bagID = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, getNumSlots(bagID) do
            local item = scanSlot(bagID, slot)
            if item then
                if item.manaRate and isBetter(item, bestWater, "manaRate") then
                    bestWater = item
                end
                if item.healthRate and isBetter(item, bestFood, "healthRate") then
                    bestFood = item
                end
            end
        end
    end

    local foodRestoresMana = bestFood ~= nil and bestFood.manaRate ~= nil

    cache = {
        isValid = bestWater ~= nil or bestFood ~= nil,
        bestWater = bestWater,
        bestFood = bestFood,
        foodRestoresMana = foodRestoresMana,
        water = bestWater and { bagID = bestWater.bagID, slot = bestWater.slot, itemID = getContainerItemID(bestWater.bagID, bestWater.slot) },
        food = bestFood and { bagID = bestFood.bagID, slot = bestFood.slot, itemID = getContainerItemID(bestFood.bagID, bestFood.slot) },
    }

    return bestWater, bestFood, foodRestoresMana
end

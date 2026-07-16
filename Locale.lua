local addonName, DrinksMacro = ...

DrinksMacro.L = {}
local L = DrinksMacro.L

-- Plain strings (used with find(..., 1, true) for literal matching)
L.USE_PREFIX      = "Use:"
L.CONJURED_ITEM   = "Conjured Item"
L.WELL_FED        = "Well Fed"

-- Lua patterns; captures are (amount, duration) in that order
L.RESTORE_MANA_PATTERN   = "Restores? (%d+) mana over (%d+) sec"
L.RESTORE_HEALTH_PATTERN = "Restores? (%d+) health over (%d+) sec"

-- Combined health+mana restore on a single line; captures are (healthAmount, manaAmount, duration)
L.RESTORE_HEALTH_MANA_PATTERN = "Restores? (%d+) health and (%d+) mana over (%d+) sec"

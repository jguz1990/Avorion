local Config = {}

Config.Author = "Hammelpilaw"
Config.ModName = "ExtTurretFactory"
Config.version = {
    major=0, minor=2, patch = 0,
    string = function()
        return  Config.version.major .. '.' ..
                Config.version.minor .. '.' ..
                Config.version.patch
    end
}

Config.Settings = {
	seedsBuyable = true,				-- If true, more seeds can be bought. If false, there are unlimited seeds as in earlier mod versions. Possible values: true, false
	upgradeBasePrice = 1000,		-- Base price per upgraded seed. Possible values: higher then 0
	upgradeAmount = 10,					-- Amount of seeds bought by one upgrade process. Possible values: 1 or higher
	
	--[[ Maximum rarity that can be created at turret factories (npc factories are also affected). Possible values: RarityType Enums, except RarityType.Petty
	RarityType.Common
	RarityType.Uncommon
	RarityType.Rare
	RarityType.Exceptional
	RarityType.Exotic
	RarityType.Legendary
	]]
	maxRarity = RarityType.Exotic,
	
	--[[ Seed calculation for turret factories changed in 0.16.2:
	You have an old galaxy with lot of great turret factories, but in 0.16.x the weapons got very bad? Turn this to "true" to use old calculations.
	Note: If true it will enable the bug, that weapons will change when you transfer a player factory to an alliance.
	Possible values: true, false
	]]
	useOldSeed = false,
}

Config.logLevel = 0
Config.log = function(logLevel, ...) if logLevel <= Config.logLevel then print("["..Config.ModName.." - "..Config.version.string().."]", ...) end end

return Config

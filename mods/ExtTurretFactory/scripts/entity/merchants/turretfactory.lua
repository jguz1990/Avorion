
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/ExtTurretFactory/?.lua"
require ("utility")
require ("faction")
require ("defaultscripts")
require ("randomext")
require ("stationextensions")
require ("galaxy")
require ("randomext")
require ("goods")
require ("tooltipmaker")
require ("faction")
require ("player")
require ("stringutility")
require ("merchantutility")
require ("callable")
SellableInventoryItem = require ("sellableinventoryitem")
Dialog = require("dialogutility")
TurretGenerator = require("turretgenerator")
require("weapontype")


local tax = 0.2
local weaponTypes = {}

local weaponsByComboEntry = {}

local Config = require ("config/ExtTurretFactoryConfig")

-- Custom Seed
local turretFacSeedTextBox
local turretFacSeed = 0
local seedLabel
local upgradeButton
local maxSeedAmount = 0
-- End Custom Seed

-- Search
local turretFacMinDamageTextBox
local turretFacMinDamage = 0
-- End Custom Search


local StatChanges =
{
    ToNextLevel = 0,
    Percentage = 1,
    Flat = 2,
}

function restore(data)
    maxSeedAmount = data.maxSeedAmount
	
	-- Backwards compatibility to a very old version of this mod
	if (not maxSeedAmount or maxSeedAmount == 0) and Entity():getValue("maxSeedAmount") then
		maxSeedAmount = Entity():getValue("maxSeedAmount")
		--Entity():setValue("maxSeedAmount", nil) -- Old data should be removed... Im a little afraid, once we remove it its gone forever.
	end
end

function secure()
    local data = {}
    data.maxSeedAmount = maxSeedAmount
    return data
end

function getBaseIngredients(weaponType)

    if weaponType == WeaponType.ChainGun then
        return {
            {name = "Servo",            amount = 15,    investable = 10,    minimum = 3, rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "Steel Tube",       amount = 6,     investable = 7,     weaponStat = "reach"},
            {name = "Ammunition S",     amount = 5,     investable = 10,    minimum = 1, weaponStat = "damage"},
            {name = "Steel",            amount = 5,     investable = 10,    minimum = 3},
            {name = "Aluminium",        amount = 7,     investable = 5,     minimum = 3},
            {name = "Lead",             amount = 10,    investable = 10,    minimum = 1},
            {name = "Targeting System", amount = 0,     investable = 2,     minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.PointDefenseChainGun then
        return {
            {name = "Servo",            amount = 17,    investable = 8,     minimum = 10, rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "Steel Tube",       amount = 8,     investable = 5,     weaponStat = "reach"},
            {name = "Ammunition S",     amount = 5,     investable = 5,     minimum = 1, weaponStat = "damage"},
            {name = "Steel",            amount = 3,     investable = 7,     minimum = 3},
            {name = "Aluminium",        amount = 7,     investable = 5,     minimum = 3},
            {name = "Lead",             amount = 10,    investable = 10,    minimum = 1},
            {name = "Targeting System", amount = 2,     investable = 0,     minimum = 2, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.Bolter then
        return {
            {name = "Servo",                amount = 15,    investable = 8,     minimum = 5,    rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "High Pressure Tube",   amount = 1,     investable = 3,                     weaponStat = "reach", investFactor = 1.5},
            {name = "Ammunition M",         amount = 5,     investable = 10,    minimum = 1,    weaponStat = "damage", investFactor = 0.25},
            {name = "Explosive Charge",     amount = 2,     investable = 4,     minimum = 1,    weaponStat = "damage", investFactor = 1.5},
            {name = "Steel",                amount = 5,     investable = 10,    minimum = 3,},
            {name = "Aluminium",            amount = 7,     investable = 5,     minimum = 3,},
            {name = "Targeting System",     amount = 0,     investable = 2,     minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},
        }
    elseif weaponType == WeaponType.Laser then
        return {
            {name = "Laser Head",           amount = 2,    investable = 4,  minimum = 1, weaponStat = "damage", investFactor = 2.0, },
            {name = "Laser Compressor",     amount = 2,    investable = 3,              weaponStat = "damage", investFactor = 2.0, },
            {name = "High Capacity Lens",   amount = 2,    investable = 4,              weaponStat = "reach", investFactor = 2.0, },
            {name = "Laser Modulator",      amount = 2,    investable = 4,              turretStat = "energyIncreasePerSecond", investFactor = -0.2, changeType = StatChanges.Percentage },
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Crystal",              amount = 2,    investable = 10, minimum = 1,},
            {name = "Targeting System",     amount = 0,    investable = 2, minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},
        }
    elseif weaponType == WeaponType.PointDefenseLaser then
        return {
            {name = "Servo",                amount = 17,   investable = 8,  minimum = 10, rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "Laser Head",           amount = 2,    investable = 2,  minimum = 1, weaponStat = "damage", investFactor = 2.0, },
            {name = "Laser Compressor",     amount = 2,    investable = 1,              weaponStat = "damage", investFactor = 2.0, },
            {name = "High Capacity Lens",   amount = 2,    investable = 4,              weaponStat = "reach", investFactor = 2.0, },
            {name = "Laser Modulator",      amount = 2,    investable = 4,              turretStat = "energyIncreasePerSecond", investFactor = -0.2, changeType = StatChanges.Percentage },
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Crystal",              amount = 2,    investable = 10, minimum = 1,},
            {name = "Targeting System",     amount = 2,    investable = 0,  minimum = 2, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},
        }

    elseif weaponType == WeaponType.PlasmaGun then
        return {
            {name = "Plasma Cell",          amount = 8,    investable = 4,  minimum = 1,   weaponStat = "damage",   },
            {name = "Energy Tube",          amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", },
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 1,    turretStat = "energyIncreasePerSecond", investFactor = -0.3, changeType = StatChanges.Percentage },
            {name = "Energy Container",     amount = 5,    investable = 6,  minimum = 1,    turretStat = "baseEnergyPerSecond", investFactor = -0.3, changeType = StatChanges.Percentage },
            {name = "Steel",                amount = 4,    investable = 10, minimum = 3,},
            {name = "Crystal",              amount = 2,    investable = 10, minimum = 1,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.Cannon then
        return {
            {name = "Servo",                amount = 15,   investable = 10, minimum = 5,  weaponStat = "fireRate", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Warhead",              amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage",  },
            {name = "High Pressure Tube",   amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", },
            {name = "Explosive Charge",     amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", investFactor = 0.5,},
            {name = "Steel",                amount = 8,    investable = 10, minimum = 3,},
            {name = "Wire",                 amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.RocketLauncher then
        return {
            {name = "Servo",                amount = 15,   investable = 10, minimum = 5,  weaponStat = "fireRate", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Rocket",               amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage",  },
            {name = "High Pressure Tube",   amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", },
            {name = "Fuel",                 amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", investFactor = 0.5,},
            {name = "Targeting Card",       amount = 5,    investable = 5,  minimum = 0,     weaponStat = "seeker", investFactor = 1, changeType = StatChanges.Flat},
            {name = "Steel",                amount = 8,    investable = 10, minimum = 3,},
            {name = "Wire",                 amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},
        }
    elseif weaponType == WeaponType.RailGun then
        return {
            {name = "Servo",                amount = 15,   investable = 10, minimum = 5,   weaponStat = "fireRate", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Electromagnetic Charge",amount = 5,   investable = 6,  minimum = 1,   weaponStat = "damage", investFactor = 0.75,},
            {name = "Electro Magnet",       amount = 8,    investable = 10, minimum = 3,    weaponStat = "reach", investFactor = 0.75,},
            {name = "Gauss Rail",           amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", investFactor = 0.75,},
            {name = "High Pressure Tube",   amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach",  investFactor = 0.75,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Copper",               amount = 2,    investable = 10, minimum = 1,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.RepairBeam then
        return {
            {name = "Nanobot",              amount = 5,    investable = 6,  minimum = 1,      weaponStat = "hullRepair", },
            {name = "Transformator",        amount = 2,    investable = 6,  minimum = 1,    weaponStat = "shieldRepair",  investFactor = 0.75,},
            {name = "Laser Modulator",      amount = 2,    investable = 5,  minimum = 0,    weaponStat = "reach",  investFactor = 0.75, changeType = StatChanges.Percentage},
            {name = "Conductor",            amount = 2,    investable = 6,  minimum = 0,    turretStat = "energyIncreasePerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Gold",                 amount = 3,    investable = 10, minimum = 1,},
            {name = "Steel",                amount = 8,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.MiningLaser then
        return {
            {name = "Laser Compressor",     amount = 5,    investable = 50,  minimum = 1,    weaponStat = "damage",investFactor = 15 },
            {name = "Laser Modulator",      amount = 2,    investable = 15,  minimum = 0,    weaponStat = "stoneRefinedEfficiency", investFactor = 0.5, changeType = StatChanges.Flat },
            {name = "High Capacity Lens",   amount = 2,    investable = 6,  minimum = 0,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.SalvagingLaser then
        return {
            {name = "Laser Compressor",     amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", },
            {name = "Laser Modulator",      amount = 2,    investable = 10,  minimum = 0,    weaponStat = "metalRefinedEfficiency", investFactor = 0.075, changeType = StatChanges.Flat },
            {name = "High Capacity Lens",   amount = 2,    investable = 6,  minimum = 0,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.RawMiningLaser then
        return {
            {name = "Laser Compressor",     amount = 5,    investable = 50,  minimum = 1,    weaponStat = "damage",investFactor = 15 },
            {name = "Laser Modulator",      amount = 2,    investable = 15,  minimum = 0,    weaponStat = "stoneRawEfficiency", investFactor = 0.5, changeType = StatChanges.Flat },
            {name = "High Capacity Lens",   amount = 2,    investable = 6,  minimum = 0,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.RawSalvagingLaser then
        return {
            {name = "Laser Compressor",     amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", },
            {name = "Laser Modulator",      amount = 2,    investable = 10,  minimum = 0,    weaponStat = "metalRawEfficiency", investFactor = 0.075, changeType = StatChanges.Flat },
            {name = "High Capacity Lens",   amount = 2,    investable = 6,  minimum = 0,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.ForceGun then
        return {
            {name = "Force Generator",      amount = 5,    investable = 3,  minimum = 1,    weaponStat = "otherForce", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Energy Inverter",      amount = 2,    investable = 4,  minimum = 1,    weaponStat = "selfForce", investFactor = 1.0, changeType = StatChanges.Percentage },
            {name = "Energy Tube",          amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 10,   investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 7,    investable = 10, minimum = 3,},
            {name = "Zinc",                 amount = 3,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.TeslaGun then
        return {
            {name = "Industrial Tesla Coil",amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", investFactor = 3.0},
            {name = "Electromagnetic Charge",amount = 2,   investable = 4,  minimum = 1,   weaponStat = "reach", investFactor = 0.2, changeType = StatChanges.Percentage },
            {name = "Energy Inverter",      amount = 2,    investable = 4,  minimum = 1,    turretStat = "baseEnergyPerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,    turretStat = "energyIncreasePerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Copper",               amount = 5,    investable = 10, minimum = 3,},
            {name = "Energy Cell",          amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.LightningGun then
        return {
            {name = "Military Tesla Coil",  amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", investFactor = 3.0},
            {name = "High Capacity Lens",   amount = 2,    investable = 4,  minimum = 1,    weaponStat = "reach", investFactor = 0.2, changeType = StatChanges.Percentage },
            {name = "Electromagnetic Charge",amount = 2,   investable = 4,  minimum = 1,   turretStat = "baseEnergyPerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,    turretStat = "energyIncreasePerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Copper",               amount = 5,    investable = 10, minimum = 3,},
            {name = "Energy Cell",          amount = 5,    investable = 10, minimum = 3,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.PulseCannon then
        return {
            {name = "Servo",                amount = 8,    investable = 8,  minimum = 3, rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "Steel Tube",           amount = 6,    investable = 7,  weaponStat = "reach"},
            {name = "Ammunition S",         amount = 5,    investable = 7,  minimum = 1, weaponStat = "damage"},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 4},
            {name = "Copper",               amount = 5,    investable = 10, minimum = 3,},
            {name = "Energy Cell",          amount = 3,    investable = 5,  minimum = 2,},
            {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    elseif weaponType == WeaponType.AntiFighter then
        return {
            {name = "Servo",                amount = 17,    investable = 8,     minimum = 10, rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "High Pressure Tube",   amount = 1,     investable = 3,                     weaponStat = "reach", investFactor = 1.5},
            {name = "Ammunition M",         amount = 5,     investable = 5,     minimum = 1,    weaponStat = "damage", investFactor = 0.25},
            {name = "Explosive Charge",     amount = 2,     investable = 4,     minimum = 1,    weaponStat = "damage", investFactor = 1.5},
            {name = "Steel",                amount = 5,     investable = 10,    minimum = 3,},
            {name = "Aluminium",            amount = 7,     investable = 5,     minimum = 3,},
            {name = "Targeting System",     amount = 2,     investable = 0,     minimum = 2, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat},

        }
    else
        print ("unknown weapon: " .. weaponType .. "!")

        return { {name = "Servo",           amount = 20,    investable = 10, minimum = 3, rarityFactor = 0.75, weaponStat = "damage", investFactor = 0.15, }, }
    end


end





local requirements
local price = 0

-- Menu items
local window
local lines = {}

function initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Turret Factory"%_t

        if onServer() then
            local x, y = Sector():getCoordinates()
            local seed = Server().seed

            math.randomseed(Sector().seed + Sector().numEntities)
            addProductionCenters(station)
            math.randomseed(appTimeMs())
        end
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/turret.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end

    -- remove weapons that aren't dropped in these regions
    local newWeaponTypes = {}
    local probabilities = Balancing_GetWeaponProbability(Sector():getCoordinates())
    for type, probability in pairs(probabilities) do

        for _, t in pairs(WeaponType) do
            if t == type then
                newWeaponTypes[t] = t
            end
        end
    end

    weaponTypes = newWeaponTypes
	
end


function interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, 10000)
end

function initUI()
    local res = getResolution()
    local size = vec2(700, 500)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Turret Factory"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Build Turrets /*window title*/"%_t);

    local container = window:createContainer(Rect(vec2(0, 0), size));

    local vsplit = UIVerticalSplitter(Rect(vec2(0, 0), size), 10, 10, 0.5)
    vsplit:setRightQuadratic()

    local left = vsplit.left
    local right = vsplit.right

    container:createFrame(left);
    container:createFrame(right);

    --- LEFT SIDE
    local lister = UIVerticalLister(left, 10, 10)
    lister.padding = 10 -- add a higher padding as the slider texts might overlap otherwise

    container:createLabel(lister:placeCenter(vec2(lister.inner.width, 15)).lower, "Weapon Type"%_t, 14)
    turretTypeCombo = container:createComboBox(Rect(), "onTurretTypeSelect")
    lister:placeElementCenter(turretTypeCombo)

    container:createLabel(lister:placeCenter(vec2(lister.inner.width, 15)).lower, "Rarity"%_t, 14)
    rarityCombo = container:createComboBox(Rect(), "onRaritySelect")
    lister:placeElementCenter(rarityCombo)

-- Custom Seed
    seedLabel = container:createLabel(vec2(), "", 14);
    seedLabel.size = vec2(0, 0)
    lister.padding = 0
    lister:placeElementCenter(seedLabel)
    lister.padding = 10

    -- make a seed text box with 2 quadratic buttons next to it
    local rect = lister:placeCenter(vec2(vsplit.left.width - 20, 30))
    local split = UIVerticalSplitter(rect, 5, 0, 0.5)
    split:setRightQuadratic();

    container:createButton(split.right, "-", "turretFacSeedDecrease");

    local split = UIVerticalSplitter(split.left, 10, 0, 0.5)
    split:setRightQuadratic();

    container:createButton(split.right, "+", "turretFacSeedIncrease");

    -- make the seed text box
    turretFacSeedTextBox = container:createTextBox(split.left, "turretFacOnSeedChanged");
    turretFacSeedTextBox.text = turretFacSeed

-- End Custom Seed

-- Custom Search
    

    local l = container:createLabel(vec2(), "Min Damage"%_t, 14);
    l.size = vec2(0, 0)
    lister.padding = 0
    lister:placeElementCenter(l)
    lister.padding = 10

    turretFacMinDamageTextBox = container:createTextBox(Rect(), "turretFacOnMinDamageChange")
    turretFacSeedTextBox.text = turretFacMinDamage
    lister:placeElementCenter(turretFacMinDamageTextBox)

    lister:placeElementCenter(container:createButton(Rect(), "Search", "turretFacOnSearch"));
    lister:placeElementCenter(container:createButton(Rect(), "Search For Max", "turretFacOnFindHighestDamage"));
-- End Custom Search
	

	container:createLabel(lister:placeCenter(vec2(lister.inner.width, 15)).lower, "Amount"%_t, 14)
	amountTextbox = container:createTextBox(Rect(), "")
	amountTextbox.text = 1
	lister:placeElementCenter(amountTextbox)
	
	
	local organizer = UIOrganizer(left)
    organizer.margin = 10
    --organizer:placeElementBottomRight(buildButton)
	
	if Config.Settings.seedsBuyable then
		upgradeButton = organizer:placeElementBottomRight(container:createButton(Rect(), "Upgrade"%_t, "turretFacOnUpgradeButtonPressed"))
	end


    --- RIGHT SIDE
    local lister = UIVerticalLister(right, 10, 10)

    local vsplit = UIArbitraryVerticalSplitter(lister:placeCenter(vec2(lister.inner.width, 30)), 10, 5, 320, 390)

    container:createLabel(vsplit:partition(0).lower, "Parts"%_t, 14)
    container:createLabel(vsplit:partition(1).lower, "Req"%_t, 14)
    container:createLabel(vsplit:partition(2).lower, "You"%_t, 14)

    for i = 1, 15 do
        local rect = lister:placeCenter(vec2(lister.inner.width, 30))
        local vsplit = UIArbitraryVerticalSplitter(rect, 10, 7, 20, 250, 280, 310, 320, 390)

        local frame = container:createFrame(rect)

        local i = 0

        local icon = container:createPicture(vsplit:partition(i), ""); i = i + 1
        local materialLabel = container:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local plus = container:createButton(vsplit:partition(i), "+", "onPlus"); i = i + 1
        local minus = container:createButton(vsplit:partition(i), "-", "onMinus"); i = i + 2
        local requiredLabel = container:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local youLabel = container:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1

        icon.isIcon = 1
        minus.textSize = 12
        plus.textSize = 12

        local hide = function(self)
            self.icon:hide()
            self.frame:hide()
            self.material:hide()
            self.plus:hide()
            self.minus:hide()
            self.required:hide()
            self.you:hide()
        end

        local show = function(self)
            self.icon:show()
            self.frame:show()
            self.material:show()
            self.plus:show()
            self.minus:show()
            self.required:show()
            self.you:show()
        end

        local line =  {frame = frame, icon = icon, plus = plus, minus = minus, material = materialLabel, required = requiredLabel, you = youLabel, hide = hide, show = show}
        line:hide()

        table.insert(lines, line)
    end

    buildButton = container:createButton(Rect(), "Build /*Turret Factory Button*/"%_t, "onBuildButtonPressed")
    local organizer = UIOrganizer(right)
    organizer.margin = 10
    organizer:placeElementBottomRight(buildButton)

    priceLabel = container:createLabel(vec2(right.lower.x, right.upper.y) + vec2(12, -75), "Manufacturing Price: Too Much"%_t, 16)

    -- needs a separate counter here, weaponTypes are not strictly numbered from 1 to X
    local c = 0
    for _, type in pairs(weaponTypes) do
        local name = WeaponTypes.nameByType[type]

        turretTypeCombo:addEntry(name)
        weaponsByComboEntry[c] = type
        c = c + 1
    end

	--rarityCombo:addEntry("Common"%_t)
	--rarityCombo:addEntry("Uncommon"%_t)
	--rarityCombo:addEntry("Rare"%_t)
	--rarityCombo:addEntry("Exceptional"%_t)
	
	
	
	rarity = RarityType.Common
	while rarity <= Config.Settings.maxRarity do
		rarityCombo:addEntry(Rarity(rarity).name%_t)
		rarity = rarity + 1
	end

    turretTypeCombo.selectedIndex = 0

    onTurretTypeSelect()
	
	invokeServerFunction("syncClientSeed") -- Custom seed
	
end

function renderUI()

    local weaponType = getUIWeapon()
    local rarity = getUIRarity()
    local material = getMaterial()
    local ingredients = getUIIngredients()

    local turret = makeTurret(weaponType, rarity, material, ingredients)

    local renderer = TooltipRenderer(makeTurretTooltip(turret))
    renderer:draw(vec2(window.upper.x, window.lower.y) + vec2(20, 10))
end

function getUIWeapon()
    return weaponsByComboEntry[turretTypeCombo.selectedIndex]
end

function getUIRarity()
    return Rarity(rarityCombo.selectedIndex)
end

function getUIIngredients()
    return requirements, price
end

function getMaterial()
    local material

    local materialProbabilities = Balancing_GetTechnologyMaterialProbability(Sector():getCoordinates())

    local highest = 0.0
    for i, probability in pairs(materialProbabilities) do
        if probability > highest then
            highest = probability
            material = Material(i)
        end
    end

    return material;
end

function getTurretIngredientsAndTax(weaponType, rarity, material, buyer)
    -- make the turrets generally cheaper, to compensate for randomness and having to bring your own goods
    local turret = makeTurretBase(weaponType, rarity, material)
    local better = makeTurretBase(weaponType,  Rarity(rarity.value + 1), material)

    local item = SellableInventoryItem(turret)
    item.price = item.price * 0.05

    local ingredients = getBaseIngredients(weaponType)

    -- scale required goods with rarity
    for _, ingredient in pairs(ingredients) do
        ingredient.amount = ingredient.amount * (1.0 + rarity.value * (ingredient.rarityFactor or 1.0))
    end

    -- calculate the worth of the required goods
    local goodsPrice = 0
    for _, ingredient in pairs(ingredients) do
        goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
    end

    if item.price < goodsPrice then

        -- turret is cheaper than the goods required to build it
        -- scale down goods
        local factor = item.price / goodsPrice

        for _, ingredient in pairs(ingredients) do
            ingredient.amount = math.max(ingredient.minimum or 0, math.floor(ingredient.amount * factor))
        end

        -- recalculate the worth
        local oldPrice = goodsPrice
        goodsPrice = 0
        for _, ingredient in pairs(ingredients) do
            goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
        end

        -- scale ingredients back up. now, ingredients with minimum 0 won't be taken into account
        -- those are usually very expensive ingredients that might cause all ingredients to be scaled down to 0 or 1
        for _, ingredient in pairs(ingredients) do
            ingredient.amount = math.max(ingredient.minimum or 0, math.floor(ingredient.amount * oldPrice / goodsPrice))
        end

        goodsPrice = 0
        for _, ingredient in pairs(ingredients) do
            goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
        end

        -- and, finally, scale back down if necessary
        if item.price < goodsPrice then
            for _, ingredient in pairs(ingredients) do
                ingredient.amount = math.max(ingredient.minimum or 0, math.floor(ingredient.amount * factor))
            end

            -- recalculate the worth
            goodsPrice = 0
            for _, ingredient in pairs(ingredients) do
                goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
            end
        end
    end

    -- adjust the maximum additional investable goods
    -- get the difference of stats to the next better turret
    for i, ingredient in pairs(ingredients) do

        local object
        local betterObject
        local stat

        if ingredient.weaponStat then
            object = turret:getWeapons()
            betterObject = better:getWeapons()
            stat = ingredient.weaponStat
        end

        if ingredient.turretStat then
            object = turret
            betterObject = better
            stat = ingredient.turretStat
        end

        if object and stat then

            local changeType = ingredient.changeType or StatChanges.ToNextLevel

            local difference
            if changeType == StatChanges.ToNextLevel then
                difference = (betterObject[stat] - object[stat]) * 0.8

                -- difference and invest factor have different sign -> flip sign
                if difference * (ingredient.investFactor or 1) < 0 then
                    difference = -difference * 0.5
                end

                if difference == 0.0 then
                    difference = object[stat] * 0.3
                end

            elseif changeType == StatChanges.Percentage then
                difference = object[stat]
            elseif changeType == StatChanges.Flat then
                difference = ingredient.investFactor
                ingredient.investFactor = 1.0
            end

            -- print ("changeType: " .. changeType)
            -- print ("stat: " .. stat)
            -- print ("difference: " .. difference)

            local sign = 0
            if difference > 0 then sign = 1
            elseif difference < 0 then sign = -1 end

            local statDelta = math.max(math.abs(difference) / ingredient.investable, 0.01)

            local investable = math.floor(math.abs(difference) / statDelta)
            investable = math.min(investable, ingredient.investable)

            local s = 0
            if type(object[stat]) == "boolean" then
                if object[stat] then
                    s = 1
                else
                    s = 0
                end
            else
                s = math.abs(object[stat])
            end

            local removable = math.floor(s / statDelta)
            removable = math.min(removable, math.floor(ingredient.amount * 0.75))

            ingredient.default = ingredient.amount
            ingredient.minimum = ingredient.amount - removable
            ingredient.maximum = ingredient.amount + investable
            ingredient.statDelta = statDelta * (ingredient.investFactor or 1.0) * sign


            -- print ("delta: " .. ingredient.statDelta)
            -- print ("removable: " .. removable)
            -- print ("investable: " .. investable)
            -- print ("minimum: " .. ingredient.minimum)
            -- print ("maximum: " .. ingredient.maximum)
        else
            ingredient.default = ingredient.amount
            ingredient.minimum = ingredient.amount
            ingredient.maximum = ingredient.amount
            ingredient.statDelta = 0
        end

        if ingredient.amount == 0 and ingredient.investable == 0 then
            ingredients[i] = nil
        end
    end

    --
    local finalIngredients = {}
    for i, ingredient in pairs(ingredients) do
        table.insert(finalIngredients, ingredient)
    end

    -- remaining price is the difference between the goods price sum and the actual turret sum
    local remaining = math.floor(math.max(item.price * 0.15, item.price - goodsPrice)) / 0.65
    local taxAmount = round(remaining * tax)

    if Faction().index == buyer.index then
        remaining = remaining - taxAmount
        -- don't pay out for the second time
        taxAmount = 0
    end

    return finalIngredients, remaining, taxAmount
end

function makeTurretBase(weaponType, rarity, material)
    local x, y = Sector():getCoordinates()

    local seed = turretFacGetSeed()
    
    TurretGenerator.initialize(Seed(seed))
    local turret = TurretGenerator.generate(x, y, 0, rarity, weaponType, material)

    -- automatic turrets must get automatic property removed and damage rebuffed
    -- we don't want the base turrets to have independent targeting since that can mess up the rest of the stats calculation, especially for damage
    if turret.automatic then
        turret.automatic = false

        local weapons = {turret:getWeapons()}
        turret:clearWeapons()

        for _, weapon in pairs(weapons) do
            weapon.damage = weapon.damage * 2.0
            if weapon.hullRepair > 0.0 then
                weapon.hullRepair = weapon.hullRepair * 2.0
            end
            if weapon.shieldRepair > 0.0 then
                weapon.shieldRepair = weapon.shieldRepair * 2.0
            end

            turret:addWeapon(weapon)
        end
    end

    return turret
end

function makeTurret(weaponType, rarity, material, ingredients)

    local turret = makeTurretBase(weaponType, rarity, material)
    local weapons = {turret:getWeapons()}

    turret:clearWeapons()

    for _, weapon in pairs(weapons) do
        -- modify weapons
        for _, ingredient in pairs(ingredients) do
            if ingredient.weaponStat then
                -- add one stat for each additional ingredient
                local additions = math.max(ingredient.minimum - ingredient.default, math.min(ingredient.maximum - ingredient.default, ingredient.amount - ingredient.default))

                local value = weapon[ingredient.weaponStat]
                if type(value) == "boolean" then
                    if value then
                        value = 1
                    else
                        value = 0
                    end
                end

                value = value + ingredient.statDelta * additions
                weapon[ingredient.weaponStat] = value
            end
        end

        turret:addWeapon(weapon)
    end

    for _, ingredient in pairs(ingredients) do
        if ingredient.turretStat then
            -- add one stat for each additional ingredient
            local additions = math.max(ingredient.minimum - ingredient.default, math.min(ingredient.maximum - ingredient.default, ingredient.amount - ingredient.default))

            local value = turret[ingredient.turretStat]
            if type(value) == "boolean" then
                if value then
                    value = 1
                else
                    value = 0
                end
            end

            value = value + ingredient.statDelta * additions
            turret[ingredient.turretStat] = value
        end
    end

    -- if the automatic property was set, we must adjust damage of the turret
    if turret.automatic then
        local weapons = {turret:getWeapons()}
        turret:clearWeapons()

        for _, weapon in pairs(weapons) do
            weapon.damage = weapon.damage / 2.0
            if weapon.hullRepair > 0.0 then
                weapon.hullRepair = weapon.hullRepair / 2.0
            end
            if weapon.shieldRepair > 0.0 then
                weapon.shieldRepair = weapon.shieldRepair / 2.0
            end

            turret:addWeapon(weapon)
        end
    end


    return turret;
end

function refreshUI()
    local ingredients = getUIIngredients()
    local rarity = getUIRarity()

    for i, line in pairs(lines) do
        line:hide()
    end

    local ship = Entity(Player().craftIndex)
    if not ship then return end

    for i, ingredient in pairs(ingredients) do
        local line = lines[i]
        line:show()

        local good = goods[ingredient.name]:good()

        local needed = ingredient.amount
        local have = ship:getCargoAmount(good) or 0

        line.icon.picture = good.icon
        line.material.caption = good:displayName(needed)
        line.required.caption = needed
        line.you.caption = have

        line.plus.visible = (ingredient.amount < ingredient.maximum)
        line.minus.visible = (ingredient.amount > ingredient.minimum)

        if have < needed then
            line.you.color = ColorRGB(1, 0, 0)
        else
            line.you.color = ColorRGB(1, 1, 1)
        end
    end

    priceLabel.caption = "Manufacturing Cost: $${money}"%_t % {money = createMonetaryString(price)}
	
	invokeServerFunction("syncClientSeed") -- Custom seed
end

function onPlus(button)
    local ingredients = getUIIngredients()

    local ingredient
    for i, line in pairs(lines) do
        if button.index == line.plus.index then
            ingredient = ingredients[i]
        end
    end

    ingredient.amount = math.min(ingredient.maximum, ingredient.amount + 1)

    refreshUI()
end

function onMinus(button)
    local ingredients = getUIIngredients()

    local ingredient
    for i, line in pairs(lines) do
        if button.index == line.minus.index then
            ingredient = ingredients[i]
        end
    end

    ingredient.amount = math.max(ingredient.minimum, ingredient.amount - 1)

    refreshUI()

end

function onRaritySelect()
    local buyer = Player()
    local playerCraft = buyer.craft
    if playerCraft.factionIndex == buyer.allianceIndex then
        buyer = buyer.alliance
    end

    requirements, price = getTurretIngredientsAndTax(getUIWeapon(), getUIRarity(), getMaterial(), buyer)
    refreshUI()
end

function onTurretTypeSelect()
    local buyer = Player()
    local playerCraft = buyer.craft
    if playerCraft.factionIndex == buyer.allianceIndex then
        buyer = buyer.alliance
    end

    requirements, price = getTurretIngredientsAndTax(getUIWeapon(), getUIRarity(), getMaterial(), buyer)
    refreshUI()
end

function onBuildButtonPressed(button)
    invokeServerFunction("buildTurret", turretFacSeed, getUIWeapon(), getUIRarity(), getMaterial(), getUIIngredients(), amountTextbox.text)
end

function onShowWindow()
    local buyer = Player()
    local playerCraft = buyer.craft
    if playerCraft.factionIndex == buyer.allianceIndex then
        buyer = buyer.alliance
    end

    requirements, price = getTurretIngredientsAndTax(getUIWeapon(), getUIRarity(), getMaterial(), buyer)
    refreshUI()
end

function buildTurret(seed, weaponType, rarity, material, clientIngredients, amount)
	if not tonumber(amount) then
		amount = 1
		Config.log(3, "Could not determine amount, set to 1: " .. amount)
	end
	
	if not validSeed(seed) then
		Config.log(3, "Invalid seed: " .. seed)
		return
	end
	turretFacSeed = seed
    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end
	
	if rarity.value > Config.Settings.maxRarity then
		Config.log(3, "Invalid rarity: " .. rarity.value)
		return
	end

    local station = Entity()

    -- can the weapon be built in this sector?
    local weaponProbabilities = Balancing_GetWeaponProbability(Sector():getCoordinates())
    if not weaponProbabilities[weaponType] then
        sendError(player, "This turret cannot be built here."%_t)
        return
    end

    -- don't take ingredients from clients blindly, they might want to cheat
    local ingredients, price, taxAmount = getTurretIngredientsAndTax(weaponType, rarity, material, buyer)

	for i = 1, amount do
		for i, ingredient in pairs(ingredients) do
			local other = clientIngredients[i]
			if other then
				ingredient.amount = other.amount
			end
		end

		-- make sure all required goods are there
		local missing
		for i, ingredient in pairs(ingredients) do
			local good = goods[ingredient.name]:good()
			local amount = ship:getCargoAmount(good)

			if not amount or amount < ingredient.amount then
				missing = goods[ingredient.name].plural
				break;
			end
		end

		if missing then
			sendError(player, "You need more %s."%_t, missing)
			return
		end

		local canPay, msg, args = buyer:canPay(price)
		if not canPay then
			sendError(player, msg, unpack(args))
			return
		end

		local errors = {}
		errors[EntityType.Station] = "You must be docked to the station to build turrets."%_T
		errors[EntityType.Ship] = "You must be closer to the ship to build turrets."%_T
		if not CheckPlayerDocked(player, station, errors) then
			return
		end

		-- pay
		receiveTransactionTax(station, taxAmount)

		buyer:pay("Paid %1% credits to build a turret."%_T, price)

		for i, ingredient in pairs(ingredients) do
			local g = goods[ingredient.name]:good()
			ship:removeCargo(g, ingredient.amount)
		end

		local turret = makeTurret(weaponType, rarity, material, ingredients)

		buyer:getInventory():add(InventoryTurret(turret))
	end
	
    invokeClientFunction(player, "refreshUI")
end
callable(nil, "buildTurret")

function buildTurretTest(weaponType, rarity, material)
    local ingredients = getTurretIngredientsAndTax(weaponType, rarity, material, Faction(Player(callingPlayer).craft.factionIndex))
    buildTurret(weaponType, rarity, material, ingredients)
end

function getTurretPriceTest(weaponType, rarity, material)
    local _, price, _ = getTurretIngredientsAndTax(weaponType, rarity, material, Faction(Player(callingPlayer).craft.factionIndex))
    return price
end

function getTurretTaxTest(weaponType, rarity, material)
    local _, _, taxAmount = getTurretIngredientsAndTax(weaponType, rarity, material, Faction(Player(callingPlayer).craft.factionIndex))
    return taxAmount
end

function sendError(player, msg, ...)
    local station = Entity()
    player:sendChatMessage(station, 1, msg, ...)
end


-- Custom Seed
function turretFacSeedDecrease()
    local number = tonumber(turretFacSeed) or 0
    turretFacSetSeed(number - 1)
end

function turretFacSeedIncrease()
    local number = tonumber(turretFacSeed) or 0
    turretFacSetSeed(number + 1)
end

function turretFacSetSeed(newSeed)
	local lSeed = tonumber(newSeed) or 0
	if not validSeed(lSeed) then
		lSeed = getValidSeed(lSeed)
	end
	
	turretFacSeed = lSeed
	turretFacSeedTextBox.text = turretFacSeed
	local buyer = Player()
	local playerCraft = buyer.craft
	if playerCraft.factionIndex == buyer.allianceIndex then
		buyer = buyer.alliance
	end


	local ingredients = getUIIngredients()
	requirements, price = getTurretIngredientsAndTax(getUIWeapon(), getUIRarity(), getMaterial(), buyer)
	
	refreshUI()
end

function turretFacGetSeed()
	local station = Entity()
    local x, y = Sector():getCoordinates()
	local seed = tonumber(turretFacSeed)
	
	if not validSeed(seed) then
		seed = 0
	end
	local fullseed = 0
	if Config.Settings.useOldSeed then
		fullseed = (station.index.number + 123 + x + y * 300 * station.factionIndex) + seed
	else
		fullseed = (station.index.number + 123 + x + y * 300) + seed
	end
	
	return fullseed
end

-- avoid cheating
function validSeed(seed)
	if getMaxSeedAmount() == nil or seed == nil or not type(seed) == "number" or not seed == math.floor(seed) then
		return false
	end
	if seed >= 0 and seed <= getMaxSeedAmount() then
		return true
	end
end

function getValidSeed(seed)
	local ret = seed
	if seed < 0 then ret = 0 end
	if seed > getMaxSeedAmount() then ret = getMaxSeedAmount() end
	
	return math.floor(ret)
end

function turretFacOnSeedChanged()
    turretFacSetSeed(turretFacSeedTextBox.text);
end
-- End Custom Seed

-- Start Seed Search

function turretFacOnMinDamageChange()
    turretFacMinDamage = turretFacMinDamageTextBox.text
end

function turretFacOnF()
    local turret = makeTestTurret()
    local foundSeed = false
	local prevSeed = turretFacSeed
	if Config.Settings.seedsBuyable and getMaxSeedAmount() < 20000 then
		turretFacSeed = 0
	end
	local i = 0
    while validSeed(turretFacSeed) and i < 20000 do
        turret = makeTestTurret()
        if turret.dps >= tonumber(turretFacMinDamage) then --        if turret.damage >= tonumber(turretFacMinDamage) then
            turretFacSeedTextBox.text = turretFacSeed
            refreshUI()
            foundSeed = true
            break
        end
        
        turretFacSeed = turretFacSeed + 1
		i = i + 1
    end

	if foundSeed then
		turretFacSetSeed(turretFacSeed)
		refreshUI()
	else
		turretFacSeed = prevSeed
	end
end

function turretFacOnFindHighestDamage()
    local turret = makeTestTurret()

    local maxDamage = 0
    local maxDamageSeed = 0
	if Config.Settings.seedsBuyable and getMaxSeedAmount() < 20000 then
		turretFacSeed = 0
	end
	local i = 0
    while validSeed(turretFacSeed) and i < 20000 do
        turret = makeTestTurret()
        if turret.dps > maxDamage then --        if turret.damage > maxDamage then
            maxDamage = turret.dps--turret.damage
            maxDamageSeed = turretFacSeed
        end
        turretFacSeed = turretFacSeed + 1
		i = i + 1
    end
    turretFacSeed = maxDamageSeed
    turretFacSetSeed(turretFacSeed)
    turretFacMinDamageTextBox.text = math.floor(maxDamage*10)/10
    refreshUI()
end

function makeTestTurret()
    local weaponType = getUIWeapon()
    local rarity = getUIRarity()
    local material = getMaterial()
    local ingredients = getUIIngredients()

    return makeTurret(weaponType, rarity, material, ingredients)
end

-- End Seed Search

function turretFacOnUpgradeButtonPressed()
	-- execute on server
	if onClient() then
		invokeServerFunction("turretFacOnUpgradeButtonPressed")
		return
	end
	
	if not Config.Settings.seedsBuyable then return end -- Should never happen, but lets be sure.
	
	local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.FoundStations)
    if not buyer then return end
	
	local price = getUpgradePrice()
	
	local canPay, msg, args = buyer:canPayMoney(price)
	if not canPay then
		sendError(player, msg, unpack(args))
		return
	end
	
	buyer:pay(price)
	
	maxSeedAmount = getMaxSeedAmount() + Config.Settings.upgradeAmount
	syncClientSeed()
end
callable(nil, "turretFacOnUpgradeButtonPressed")

function getUpgradePrice()
	return (Config.Settings.upgradeBasePrice + (Config.Settings.upgradeBasePrice * 0.1 * getMaxSeedAmount())) * Config.Settings.upgradeAmount
end

function syncClientSeed(maxSeeds)
	if not Config.Settings.seedsBuyable then return end
	if onServer() then
		--local value, abbreviation = getReadableNumber(getUpgradePrice())
		--local value = value
		--local abbreviation = abbreviation
		invokeClientFunction(Player(callingPlayer), "syncClientSeed", getMaxSeedAmount())
		return
	end
	
	maxSeedAmount = maxSeeds
	
	local price, abbreviation = getReadableNumber(getUpgradePrice())
	seedLabel.caption = "Seed"%_t .. " (0 - " .. maxSeedAmount ..")"
	
	upgradeButton.tooltip = "+${seeds} Seeds: ${price} ${abbreviation} Cr"%_t % {seeds = Config.Settings.upgradeAmount, price = price, abbreviation = abbreviation}
end
callable(nil, "syncClientSeed")

function getMaxSeedAmount()
	if not Config.Settings.seedsBuyable then return 999999999999 end -- Unlimited. Not sure how much would be possible... but this should be enaugh :)
	
	-- When executed on client, be sure we have a maxSeedAmount value
	if onClient() and maxSeedAmount == nil then
		invokeServerFunction("syncClientSeed")
	end
	return maxSeedAmount or 0
end


function updateServer()

end


package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getNumBonusTurrets(seed, rarity, permanent)
-- This one will return MilitaryTurrets and CivilianTurrets, because B-TCS will provide both (but usually way more military).
-- Initialization stuff. To put in the first called function.
    math.randomseed(seed)
	baseturrets = {1, 2, 4, 6, 9, 11, 14, 14}

	unfactor = math.max(0, math.random(0, 199) - 100)

	classfactor = math.random(0, 99)
	
	if classfactor >= 90 then -- Chances: 60% of subcapital class, 30% of capital class, 10% of supercapital class.
		nyafactor = 5
		megafactor = math.random(150, 250)
	elseif classfactor >= 60 then
		nyafactor = 2
		megafactor = math.random(0, 200)
	else
		nyafactor = 1
		megafactor = math.random(-100, 200)
	end
	megafactor = math.max(0, megafactor - 100) -- megafactor is bounded from 0 to 100 (150 for SC-class) here
-- Init END	
	-- print("Init'd turret with rarity value " .. rarity.value)
	turretverifiedrarity = 0 -- Please don't crash here again !
	
	if rarity.value then
		if rarity.value < -1 then
			rarity.value = -1
		end
		if rarity.value > 6 then
			rarity.value = 6
		end
		turretverifiedrarity = rarity.value
	end
	
	turretverifiedrarity = turretverifiedrarity + 2
	
	actualturrets = (baseturrets[turretverifiedrarity] + 1) * nyafactor
	
	maxplusturrets = actualturrets + math.ceil(actualturrets * (0.2 + (0.3 * nyafactor))) + 1
	--print("Init'd B-TCS with " .. actualturrets .. "turrets")
	if nyafactor == 5 then
		-- Overkill bonus for Supercapital Class Bulk TCS !
		maxplusturrets = maxplusturrets + (5 * turretverifiedrarity)
	end
	-- The +1 in the following formula is due to the "math.floor", so that math.max amount of turrets is the good amount.
	actualturrets = math.random(actualturrets, maxplusturrets)
	actualturrets = math.floor(actualturrets * (1 + ( megafactor / 200 ))) -- megafactor will cause up to 50% (75% for SC-class) increase.
	-- Military turrets: math.ceil(actualturrets * ((133 - unfactor) / 133)) : unfactor/133 is used because 1/0.75 is 1.33.
	-- Civvie turrets: math.floor(actualturrets * (unfactor / 133)) : flipside of the previous value.
    -- if permanent then
    return {math.ceil(actualturrets * ((133 - unfactor) / 133)), math.floor(actualturrets * (unfactor / 133)), unfactor, nyafactor, megafactor}
    -- end

    -- return {0, 0, 0, 0, 0}
end

function getNumTurrets(seed, rarity, permanent)
	noms = getNumBonusTurrets(seed, rarity, permanent)
	-- B-TCS need to be perma-installed in order for them to function
    -- return math.max(1, rarity.value + 1) + getNumBonusTurrets(seed, rarity, permanent)
    if permanent then
        return noms[1]
    else
        return 0
    end
end

function onInstalled(seed, rarity, permanent)
	noms = getNumBonusTurrets(seed, rarity, permanent)
	local energon = math.ceil((noms[5] / 250) * 100) / 100
	local slowcap = math.max(0, noms[1] - noms[2])
	if permanent then
    addMultiplyableBias(StatsBonuses.ArmedTurrets, noms[1])
    addMultiplyableBias(StatsBonuses.UnarmedTurrets, noms[2])
    addBaseMultiplier(StatsBonuses.GeneratedEnergy, -energon)
	if noms[4] == 2 then
		slowcap = math.min(20, slowcap / 4)
	end
	if noms[4] == 5 then
		slowcap = math.min(50, slowcap / 8)
	end
	addBaseMultiplier(StatsBonuses.Acceleration, slowcap / -100)
	end
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    noms = getNumBonusTurrets(seed, rarity, permanent)

	leadingunfactor = "??" -- I initialize leadingunfactor as a string to allow for a leading zero.
	-- Note: unfactor is carried in noms[3]
	if noms[3] >= 0 and noms[3] <= 9 then
		leadingunfactor = "0" .. noms[3]
	else
		leadingunfactor = noms[3]
	end

	return "Turret Control System B-TCS-" .. noms[1] .. leadingunfactor
	-- It will make a voluntary big number, giving the feeling of power ^_^.
end

function getIcon(seed, rarity)
    return "data/textures/icons/coaxial-gun.png"
end

function getEnergy(seed, rarity, permanent)
    noms = getNumBonusTurrets(seed, rarity, permanent)
	local num = noms[1] * (1 + (noms[3] / 250)) -- Civvie turrets given by B-TCS will be cheap energywise.
	if noms[4] == 1 then
		return num * 1000 * 1000 * 1000 / (1.05 ^ rarity.value) -- Before, 787 *...
	elseif noms[4] == 2 then
		return num * 2500 * 1000 * 1000 / (1.05 ^ rarity.value) -- Before, 1500 *...
	elseif noms[4] == 5 then
		return num * 2500 * 1000 * 1000 / (0.95 ^ rarity.value)
	else
		return num * 3500 * 1000 * 1000 / (1.05 ^ rarity.value) -- Should not happen, but eh... before, 2500 *...
	end
end

function getPrice(seed, rarity)
	noms = getNumBonusTurrets(seed, rarity, permanent)
    local num = noms[1] * (1 + (noms[3] / 125))
    local price = 12000 * num;
    return price * ((1.25 + (noms[4] / 10)) ^ rarity.value)
	-- Should cause a math.max price of around 140 mil for a lucky maxed (409-turret) legendary SC-class.
end

function getTooltipLines(seed, rarity, permanent)
    --{
    --    {ltext = "Armed Turret Slots"%_t, rtext = "+" .. getNumTurrets(seed, rarity, permanent), icon = "data/textures/icons/turret.png", boosted = permanent}
    --},
	noms = getNumBonusTurrets(seed, rarity, permanent)
	--print("Inspecting noms: " .. noms[1] .. ", " .. noms[2] .. ", " .. noms[3] .. ", " .. noms[4] .. ", " .. noms[5])
	energon = math.ceil((noms[5] / 250) * 100)
	slowcap = math.max(0, noms[1] - noms[2]) -- Initialized as number of mill vs civ.
	tcsclassname = "Invalid"
	tcsclassicon = "data/textures/icons/hazard-sign.png"
	if noms[4] == 1 then
		tcsclassname = "Subcapital"
		tcsclassicon = "data/textures/icons/rank-1.png"
		slowcap = 0 -- No acc penalty on subcapital B-TCS.
	end
	if noms[4] == 2 then
		tcsclassname = "Capital"
		tcsclassicon = "data/textures/icons/rank-2.png"
		slowcap = math.min(20, slowcap / 4) -- 1% penalty per four turrets.
	end
	if noms[4] == 5 then
		tcsclassname = "Supercapital"
		tcsclassicon = "data/textures/icons/rank-3.png"
		slowcap = math.min(50, slowcap / 8) -- 1% penalty per eight turrets.
	end
					-- Base text
		texts =
			{
				{ltext = "B-TCS Scale"%_t, rtext = tcsclassname, icon = tcsclassicon},
				{ltext = "Armed Turret Slots"%_t, rtext = "+" .. noms[1], icon = "data/textures/icons/turret.png", boosted = permanent}
			}
	
	if noms[2] ~= 0 then	
		table.insert(texts, {ltext = "Unarmed Turret Slots"%_t, rtext = "+" .. noms[2], icon = "data/textures/icons/turret.png", boosted = permanent})
	end
	if energon ~= 0 then		
		table.insert(texts, {ltext = "Generated Energy"%_t, rtext = "-" .. energon .. "%", icon = "data/textures/icons/electric.png", boosted = permanent})
	end
	if slowcap ~= 0 then		
		table.insert(texts, {ltext = "Acceleration"%_t, rtext = "-" .. slowcap .. "%", icon = "data/textures/icons/acceleration.png", boosted = permanent})
	end
	
	-- if not texts then texts = {{ltext = "B-TCS Scale"%_t, rtext = "Null", icon = "data/textures/icons/hazard-sign.png"}}
	
    if not permanent then
        return texts, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Bulk Turret Control System"%_t, rtext = "", icon = ""},
        {ltext = "Adds a large amount of turret slots,"%_t, rtext = "", icon = ""},
        {ltext = "sometimes at expense of energy generation."%_t, rtext = "", icon = ""},
        {ltext = "Capships will get slow, though~"%_t, rtext = "", icon = ""}
    }
end

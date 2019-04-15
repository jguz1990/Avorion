package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")
require ("stringutility")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)
	local scale = math.random(0, 99)
	scale = math.random(scale, 99)
	scale = 100 - scale -- The reason for this: if I didn't, it would cause more bigscale arrays than smallscale to spawn.
	scale = math.random(1, scale) ^ 2

    local energy = scale * 100 * 1000 * 1000 -- base value, in watts~
    -- add flat percentage based on rarity
    energy = energy + (rarity.value + 1) * 10 -- add 0% (worst rarity) to +60% (best rarity)

    -- add randomized percentage, span is based on rarity
    energy = energy * (100 + (math.random() * ((rarity.value + 1) * 8))) / 100 -- add random value between 0% (worst rarity) and +48% (best rarity)

    local people = scale -- base value, in amount
	-- vary based on rarity
    people = math.max(1, math.ceil(math.random(people * (0.9 - (rarity.value / 10)), people * (1.1 - (rarity.value / 10)))))
	-- 90 to 110%, -10% per rarity. Minimum of 1 enforced after seeing a 0-man one.

    if permanent then
        energy = energy * 1.5
        people = math.ceil(people * 0.75)
    end

    return energy, people
end

function onInstalled(seed, rarity, permanent)
    local energy, people = getBonuses(seed, rarity, permanent)

    addAbsoluteBias(StatsBonuses.GeneratedEnergy, energy)
    addAbsoluteBias(StatsBonuses.Mechanics, -people)
end

function onUninstalled(seed, rarity, permanent)

end

function getName(seed, rarity)
    local energy, people = getBonuses(seed, rarity, permanent)
	text = "Unspecified Dark Matter Reactor"%_t
	microscale = math.floor(math.log(people) / 1.75)
	if microscale == 0 then text = "Tiny Dark Matter Reactor"%_t end
	if microscale == 1 then text = "Small Dark Matter Reactor"%_t end
	if microscale == 2 then text = "Medium Dark Matter Reactor"%_t end
	if microscale == 3 then text = "Large Dark Matter Reactor"%_t end
	if microscale == 4 then text = "Huge Dark Matter Reactor"%_t end
	if microscale == 5 then text = "Epic Dark Matter Reactor"%_t end
    return text
end

function getIcon(seed, rarity)
    return "data/textures/icons/wire.png"
end

function getEnergy(seed, rarity, permanent)
    return 0
end

function getPrice(seed, rarity)
    local energy, people = getBonuses(seed, rarity)
    local price = energy / 500000
    return price * 1.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local energy, people = getBonuses(seed, rarity, permanent)
    local baseEnergy, basePeople = getBonuses(seed, rarity, false)
	-- local unitPrefix = getReadableValue(baseEnergy) -- All the energy !
	local baseActEnergyD = 0
	local baseBaseEnergyD = 0
	local baseActEnergyS = 0
	local baseBaseEnergyS = 0
	-- Why getReadableValue gives out such unreadeable values ! I have to make four variables for just that !
	baseActEnergyD, baseActEnergyS = getReadableValue(energy)
	baseBaseEnergyD, baseBaseEnergyS = getReadableValue(baseEnergy * 0.5)
	
	
    texts = {{ltext = "Generated Energy"%_t, rtext = baseActEnergyD .. " " .. baseActEnergyS .. "W", icon = "data/textures/icons/electric.png", boosted = permanent}}
    bonuses = {{ltext = "Generated Energy"%_t, rtext = baseBaseEnergyD .. " " .. baseBaseEnergyS .. "W", icon = "data/textures/icons/electric.png"}}

    table.insert(texts, {ltext = "Mechanics Needed"%_t, rtext = " " .. people, icon = "data/textures/icons/crew-member.png", boosted = permanent})
    table.insert(bonuses, {ltext = "Mechanics Needed"%_t, rtext = " " .. math.ceil(basePeople * 0.5), icon = "data/textures/icons/crew-member.png"})

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Mechanics work on maintaining a dark"%_t, rtext = "", icon = ""},
        {ltext = "matter reactor to boost the energy"%_t, rtext = "", icon = ""},
        {ltext = "output by a flat ammount."%_t, rtext = "", icon = ""}
    }
end


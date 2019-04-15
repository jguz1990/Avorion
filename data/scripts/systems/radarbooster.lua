package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local radar = 0
    local hiddenRadar = 0

    radar = math.max(0, getInt(rarity.value, rarity.value * 2.0)) + 1
    hiddenRadar = math.max(0, getInt(rarity.value, rarity.value * 1.5)) + 1

    -- probability for both of them being used
    -- when rarity.value >= 4, always both
    -- when rarity.value <= 0 always only one
    local probability = math.max(0, rarity.value * 0.25)
    if math.random() > probability then
        -- only 1 will be used
        if math.random() < 0.5 then
            radar = 0
        else
            hiddenRadar = 0
        end
    end

    if permanent then
        radar = radar * 1.5
        hiddenRadar = hiddenRadar * 2
    end

    return radar, hiddenRadar
end

function onInstalled(seed, rarity, permanent)
    local radar, hiddenRadar = getBonuses(seed, rarity, permanent)

    addMultiplyableBias(StatsBonuses.RadarReach, radar)
    addMultiplyableBias(StatsBonuses.HiddenSectorRadarReach, hiddenRadar)
end

function onUninstalled(seed, rarity, permanent)

end

function getName(seed, rarity)
    return "Radar Upgrade"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/radar-sweep.png"
end

function getEnergy(seed, rarity, permanent)
    local radar, hiddenRadar = getBonuses(seed, rarity)
    return radar * 75 * 1000 * 1000 + hiddenRadar * 150 * 1000 * 1000
end

function getPrice(seed, rarity)
    local radar, hiddenRadar = getBonuses(seed, rarity)
    local price = radar * 3000 + hiddenRadar * 5000
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local radar, hiddenRadar = getBonuses(seed, rarity, permanent)
    local baseRadar, baseHidden = getBonuses(seed, rarity, false)

    if radar ~= 0 then
        table.insert(texts, {ltext = "Radar Range"%_t, rtext = string.format("%+i", radar), icon = "data/textures/icons/radar-sweep.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Radar Range"%_t, rtext = string.format("%+i", baseRadar * 0.5), icon = "data/textures/icons/radar-sweep.png"})
    end

    if hiddenRadar ~= 0 then
        table.insert(texts, {ltext = "Deep Scan Range"%_t, rtext = string.format("%+i", hiddenRadar), icon = "data/textures/icons/radar-sweep.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Deep Scan Range"%_t, rtext = string.format("%+i", baseHidden), icon = "data/textures/icons/radar-sweep.png"})
    end

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local texts = {}
    local radar, hiddenRadar = getBonuses(seed, rarity)

    if hiddenRadar ~= 0 then
        table.insert(texts, {ltext = "Shows sectors with mass /*ctd. in next*/"%_t})
        table.insert(texts, {ltext = "/*ctd.*/as yellow blips on the map"%_t})
    end

    return texts
end


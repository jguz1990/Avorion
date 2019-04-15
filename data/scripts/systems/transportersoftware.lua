package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
PermanentInstallationOnly = true

function getBonuses(seed, rarity, permanent)
    -- rarity -1 is -1 / 2 + 1 * 50 = 0.5 * 100 = 50
    -- rarity 5 is 5 / 2 + 1 * 50 = 3.5 * 100 = 350
    local range = (rarity.value / 2 + 1) * 100

    local fighterCargoPickup = 0
    if rarity.value >= RarityType.Rare then
        fighterCargoPickup = 1
    end

    return range, fighterCargoPickup
end

function onInstalled(seed, rarity, permanent)
    if not permanent then return end

    local range, fighterCargoPickup = getBonuses(seed, rarity, permanent)
    addAbsoluteBias(StatsBonuses.TransporterRange, range)
    addAbsoluteBias(StatsBonuses.FighterCargoPickup, fighterCargoPickup)
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "Transporter Software"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/processor.png"
end

function getEnergy(seed, rarity, permanent)
    return 0
end

function getPrice(seed, rarity)
    local range, fighterCargoPickup = getBonuses(seed, rarity, true)
    return range * 25000
end

function getTooltipLines(seed, rarity, permanent)
    local range, fighterCargoPickup = getBonuses(seed, rarity, permanent)

    local texts =
    {
        {ltext = "Docking Distance"%_t, rtext = "+${distance} km"%_t % {distance = range / 100}, icon = "data/textures/icons/solar-system.png", boosted = permanent}
    }

    if fighterCargoPickup > 0 then
        table.insert(texts, {ltext = "Fighter Cargo Pickup"%_t, icon = "data/textures/icons/fighter.png", boosted = permanent})
    end

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Transporter Software for Transporter Blocks."%_t, rtext = "", icon = ""},
        {ltext = "Transporter Block on your ship required to work."%_t, rtext = "", icon = ""},
    }
end

package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

-- this key is dropped by the AI

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

function onInstalled(seed, rarity, permanent)
    if not permanent then return end

    addAbsoluteBias(StatsBonuses.PilotsPerFighter, -100000)
    addAbsoluteBias(StatsBonuses.MinersPerTurret, -100000)
    addAbsoluteBias(StatsBonuses.MechanicsPerTurret, -100000)
    addAbsoluteBias(StatsBonuses.GunnersPerTurret, -100000)
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "XSTN-K VI"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/key6.png"
end

function getPrice(seed, rarity)
    return 10000
end

function getTooltipLines(seed, rarity, permanent)
    local texts =
    {
        {ltext = "Pilots Required", rtext = "0", icon = CrewProfession(CrewProfessionType.Pilot).icon, boosted = permanent},
        {ltext = "Gunners Required", rtext = "0", icon = CrewProfession(CrewProfessionType.Gunner).icon, boosted = permanent},
        {ltext = "Miners Required", rtext = "0", icon = CrewProfession(CrewProfessionType.Miner).icon, boosted = permanent},
    }

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Replaces Gunners and Pilots with AIs"%_t, rtext = "", icon = ""},
        {ltext = "", rtext = "", icon = ""},
        {ltext = "This system has 6 vertical "%_t, rtext = "", icon = ""},
        {ltext = "scratches on its surface."%_t, rtext = "", icon = ""}
    }
end

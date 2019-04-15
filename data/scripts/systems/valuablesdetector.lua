package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

materialLevel = 0
range = 0
amount = 0
interestingEntities = {}
detections = {}
highlightRange = 0

local entityId

-- this variable gets reset on the client every time the player changes sectors because the script is recreated
local chatMessageDisplayed = false


-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local detections = {"entity/claim.lua"}
    if rarity.value >= RarityType.Common then
        table.insert(detections, "entity/wreckagetoship.lua")
    end

    if rarity.value >= RarityType.Uncommon then
        table.insert(detections, "entity/stash.lua")
        table.insert(detections, "entity/story/exodusbeacon.lua")
    end

    local highlightRange = 0
    if rarity.value >= RarityType.Rare then
        highlightRange = 400 + math.random() * 200
    end

    if rarity.value >= RarityType.Exceptional then
        highlightRange = 900 + math.random() * 200
    end

    if rarity.value >= RarityType.Exotic then
        highlightRange = math.huge
    end

    return detections, highlightRange
end

function onInstalled(seed, rarity, permanent)
end

function onUninstalled(seed, rarity, permanent)
end


if onClient() then

function onInstalled(seed, rarity, permanent)
    if Player() then
        Player():registerCallback("onPreRenderHud", "onPreRenderHud")
        Player():registerCallback("onShipChanged", "detectAndSignal")
    end

    detections, highlightRange = getBonuses(seed, rarity, permanent)
    detectAndSignal()
end

function onUninstalled(seed, rarity, permanent)

end

function onDelete()
    if entityId then
        removeShipProblem("ValuablesDetector", entityId)
    end
end

function detectAndSignal()

    if Player().craftIndex == Entity().index then
        -- check for valuables and send a signal
        interestingEntities = {}
        local entities = {Sector():getEntitiesByComponent(ComponentType.Scripts)}
        for _, entity in pairs(entities) do
            for _, script in pairs(detections) do
                if entity:hasScript(script) then
                    table.insert(interestingEntities, entity)
                    break
                end
            end
        end
    end

    signal()

end

function signal()

    if Player().craftIndex == Entity().index then
        if #interestingEntities > 0 then
            if not chatMessageDisplayed then
                displayChatMessage("Valuable objects detected."%_t, "Object Detector"%_t, 3)
                chatMessageDisplayed = true
            end

            entityId = Entity().id
            addShipProblem("ValuablesDetector", entityId, "Valuable objects detected."%_t, "data/textures/icons/hazard-sign.png", ColorRGB(0, 1, 1))
        end
    end

end

function onSectorChanged()
    detectAndSignal()
end

function onPreRenderHud()

    if not highlightRange or highlightRange == 0 then return end

    local shipPos = Entity().translationf

    -- detect all objects in range
    local renderer = UIRenderer()

    for i, entity in pairs(interestingEntities) do
        if not valid(entity) then
            interestingEntities[i] = nil
        end
    end

    for i, entity in pairs(interestingEntities) do
        local d = distance2(entity.translationf, shipPos)

        if d <= highlightRange * highlightRange then
            renderer:renderEntityTargeter(entity, ColorRGB(1, 1, 1));
            renderer:renderEntityArrow(entity, 30, 10, 250, ColorRGB(1, 1, 1));
        end
    end

    renderer:display()
end
end

function getName(seed, rarity)
    return "C43 Object Detector"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/movement-sensor.png"
end

function getEnergy(seed, rarity, permanent)
    local detections, highlightRange = getBonuses(seed, rarity)
    highlightRange = math.min(highlightRange, 1500)

    return (highlightRange * 0.0005 * 1000 * 1000 * 1000) + (#detections * 15 * 1000 * 1000)
end

function getPrice(seed, rarity)
    local detections, range = getBonuses(seed, rarity)
    range = math.min(range, 1500)

    local price = #detections * 750 + range * 1.5;

    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}

    local _, range = getBonuses(seed, rarity)

    if range > 0 then
        local rangeText = "Sector"%_t
        if range < math.huge then
            rangeText = string.format("%g", round(range / 100, 2))
        end

        table.insert(texts, {ltext = "Highlight Range"%_t, rtext = rangeText, icon = "data/textures/icons/rss.png"})
    end

    table.insert(texts, {ltext = "Detection Range"%_t, rtext = "Sector"%_t, icon = "data/textures/icons/rss.png"})

    return texts
end

function getDescriptionLines(seed, rarity, permanent)
    local texts = {}

    if rarity.value == RarityType.Petty then
        table.insert(texts, {ltext = "Detects claimable asteroids."%_t, amount})
    elseif rarity.value == RarityType.Common then
        table.insert(texts, {ltext = "Detects claimable asteroids and wreckages."%_t, amount})
    elseif rarity.value == RarityType.Uncommon then
        table.insert(texts, {ltext = "Detects claimable asteroids, wreckages and stashes."%_t, amount})
    else
        table.insert(texts, {ltext = "Detects & highlights all interesting objects."%_t, amount})
    end

    table.insert(texts, {ltext = "Displays a notification when"%_t})
    table.insert(texts, {ltext = "interesting items were detected."%_t})

    return texts
end



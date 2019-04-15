
package.path = package.path .. ";data/scripts/lib/?.lua"

require("stringutility")
require("refineutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AISalvage
AISalvage = {}

local minedWreckage = nil
local minedLoot = nil
local collectCounter = 0
local salvagingMaterial = nil
local hasRawLasers = false
local noWreckagesLeft = false
local noCargoSpace = false

local stuckLoot = {}

function AISalvage.getUpdateInterval()
    if noWreckagesLeft or noCargoSpace then return 15 end

    return 1
end

function AISalvage.checkIfAbleToSalvage()
    if onServer() then
        local ship = Entity()
        for _, turret in pairs({ship:getTurrets()}) do
            local weapons = Weapons(turret)

            if weapons.metalRawEfficiency > 0 then hasRawLasers = true end

            if weapons.category == WeaponCategory.Salvaging then
                if salvagingMaterial == nil or weapons.material.value > salvagingMaterial then
                    salvagingMaterial = weapons.material.value
                end
            end
        end

        local hangar = Hangar()
        local squads = {hangar:getSquads()}

        for _, index in pairs(squads) do
            local category = hangar:getSquadMainWeaponCategory(index)
            if category == WeaponCategory.Salvaging or category == WeaponCategory.Armed then
                if salvagingMaterial == nil or hangar:getHighestMaterialInSquadMainCategory(index).value > salvagingMaterial then
                    salvagingMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
                end

                hasRawLasers = hasRawLasers or hangar:getSquadHasRawMinersOrSalvagers(index)
            end
        end

        -- use armed weapons only if no salvaging weapons are available
        if salvagingMaterial == nil then
            for _, turret in pairs({ship:getTurrets()}) do
                local weapons = Weapons(turret)

                if weapons.category == WeaponCategory.Armed then
                    salvagingMaterial = MaterialType.Avorion
                    break
                end
            end
        end

        if not salvagingMaterial then
            local faction = Faction(Entity().factionIndex)
            if faction then
                faction:sendChatMessage("", ChatMessageType.Error, "Your ship needs turrets or combat or salvaging fighters to salvage."%_T)
            end

            ShipAI():setPassive()
            terminate()
        end
    end
end

-- this function will be executed every frame on the server only
function AISalvage.updateServer(timeStep)
    local ship = Entity()

    if salvagingMaterial == nil then
        AISalvage.checkIfAbleToSalvage()

        if salvagingMaterial == nil then
            ShipAI():setPassive()
            terminate()
            return
        end
    end

    if ship.hasPilot or ship:getCrewMembers(CrewProfessionType.Captain) == 0 then
        ShipAI():setPassive()
        terminate()
        return
    end

    -- find a wreckage that can be harvested
    AISalvage.updateSalvaging(timeStep)
end

-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign minedLoot
function AISalvage.findMinedLoot()
    local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()

    minedLoot = nil
    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) < 150 * 150 then
            if stuckLoot[loot.index.string] ~= true then
                minedLoot = loot
                return
            end
        end
    end
end

-- check the sector for a wreckage that can be mined
-- if there is one, assign minedwreckage
function AISalvage.findMinedWreckage()

    local radius = 20
    local ship = Entity()
    local sector = Sector()

    minedWreckage = nil

    local mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
    local nearest = math.huge
    local nearestResources = 0
    local nearestSize = 0

    for _, a in pairs(mineables) do
        if a.type == EntityType.Wreckage then
            local material = a:getLowestMineableMaterial()
            if not material or material.value > salvagingMaterial + 1 then goto continue end

            local resources = 0
            for _, value in pairs({a:getMineableResources()}) do
                resources = resources + value
            end

            if resources < 10 then goto continue end

            local dist2 = distance2(a.translationf, ship.translationf)
            local sphere = a:getBoundingSphere()
            local size = sphere and sphere.radius * 2 or 0

            if resources > nearestResources then
                if dist2 < nearest then
                    -- wreckage has more resources and is closer
                    nearest = dist2
                    nearestResources = resources
                    nearestSize = size
                    minedWreckage = a
                else
                    if math.sqrt(dist2) < math.sqrt(nearest) + 2 * size then
                        -- wreckage has more resources and is only one diameter farther away
                        nearest = dist2
                        nearestResources = resources
                        nearestSize = size
                        minedWreckage = a
                    end
                end
            else
                if math.sqrt(dist2) < math.sqrt(nearest) - nearestSize then
                    -- wreckage is closer
                    nearest = dist2
                    nearestResources = resources
                    nearestSize = size
                    minedWreckage = a
                end
            end

            ::continue::
        end
    end

    if minedWreckage then
        noWreckagesLeft = false
        broadcastInvokeClientFunction("setMinedWreckage", minedWreckage.index)
    else
        if noWreckagesLeft == false then
            noWreckagesLeft = true

            local faction = Faction(Entity().factionIndex)
            if faction then
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)

                faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship in sector %s can't find any more wreckages."%_T, coords)
                faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more wreckages in \\s(%s)!"%_T, coords)
            end

            ShipAI(ship.index):setPassive()
        end
    end

end

function AISalvage.updateSalvaging(timeStep)
    local ship = Entity()

    if hasRawLasers == true then
        if ship.freeCargoSpace < 1 then
            if noCargoSpace == false then
                local faction = Faction(ship.factionIndex)
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship's cargo bay in sector %s is full."%_T, coords) end

                ShipAI():setPassive()

                local ores, totalOres = getOreAmountsOnShip(ship)
                local scraps, totalScraps = getScrapAmountsOnShip(ship)
                if totalOres + totalScraps == 0 then
                    ShipAI():setStatus("Salvaging - No Cargo Space"%_T, {})
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't salvage in \\s(%s), we have no space in our cargo bay!"%_T, coords) end
                    noCargoSpace = true
                else
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't continue salvaging in \\s(%s), we have no more space left in our cargo bay!"%_T, coords) end
                    terminate()
                end
            end

            return
        else
            noCargoSpace = false
        end
    end

    -- highest priority is collecting the resources
    if not valid(minedWreckage) and not valid(minedLoot) then

        -- first, check if there is loot to collect
        AISalvage.findMinedLoot()

        -- then, if there's no loot, check if there is a wreckage to mine
        if not valid(minedLoot) then
            AISalvage.findMinedWreckage()
        end

    end

    local ai = ShipAI()

    if valid(minedLoot) then
        ai:setStatus("Collecting Salvaged Loot /* ship AI status*/"%_T, {})

        -- there is loot to collect, fly there
        collectCounter = collectCounter + timeStep
        if collectCounter > 3 then
            collectCounter = collectCounter - 3

            if ai.isStuck then
                stuckLoot[minedLoot.index.string] = true
                AISalvage.findMinedLoot()
                collectCounter = collectCounter + 2
            end

            if valid(minedLoot) then
                ai:setFly(minedLoot.translationf, 0)
            end
        end

    elseif valid(minedWreckage) then
        ai:setStatus("Salvaging /* ship AI status*/"%_T, {})

        -- if there is a wreckage to collect, harvest it
        if ship.selectedObject == nil
            or ship.selectedObject.index ~= minedWreckage.index
            or ai.state ~= AIState.Harvest then

            ai:setHarvest(minedWreckage)
            stuckLoot = {}
        end
    else
        ai:setStatus("Salvaging - No Wreckages Left /* ship AI status*/"%_T, {})
    end

end

function AISalvage.setMinedWreckage(index)
    minedWreckage = Sector():getEntity(index)
end

---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--
--    if valid(minedWreckage) then
--        drawDebugSphere(minedWreckage:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end

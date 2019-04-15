
package.path = package.path .. ";data/scripts/lib/?.lua"

require("stringutility")
require("refineutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AIMine
AIMine = {}

local minedAsteroid = nil
local minedLoot = nil
local collectCounter = 0
local miningMaterial = nil
local hasRawLasers = false
local noAsteroidsLeft = false
local noCargoSpace = false

local stuckLoot = {}

function AIMine.getUpdateInterval()
    if noAsteroidsLeft or noCargoSpace then return 15 end

    return 1
end

function AIMine.checkIfAbleToMine()
    if onServer() then
        local ship = Entity()
        hasRawLasers = false

        for _, turret in pairs({ship:getTurrets()}) do
            local weapons = Weapons(turret)

            if weapons.stoneRawEfficiency > 0 then hasRawLasers = true end

            if weapons.category == WeaponCategory.Mining then
                if miningMaterial == nil or weapons.material.value > miningMaterial then
                    miningMaterial = weapons.material.value
                end
            end
        end

        local hangar = Hangar()
        local squads = {hangar:getSquads()}

        for _, index in pairs(squads) do
            local category = hangar:getSquadMainWeaponCategory(index)
            if category == WeaponCategory.Mining then
                if miningMaterial == nil or hangar:getHighestMaterialInSquadMainCategory(index).value > miningMaterial then
                    miningMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
                end

                hasRawLasers = hasRawLasers or hangar:getSquadHasRawMinersOrSalvagers(index)
            end
        end

        if not miningMaterial then
            local faction = Faction(Entity().factionIndex)

            if faction then
                faction:sendChatMessage("", ChatMessageType.Error, "Your ship needs mining turrets or fighters to mine."%_T)
            end

--            print("no mining turrets")
            ShipAI():setPassive()
            terminate()
        end
    end
end

-- this function will be executed every frame on the server only
function AIMine.updateServer(timeStep)
    local ship = Entity()

    if miningMaterial == nil then
        AIMine.checkIfAbleToMine()

        if miningMaterial == nil then
            ShipAI():setPassive()
            terminate()
            return
        end
    end

    if ship.hasPilot or ship:getCrewMembers(CrewProfessionType.Captain) == 0 then
--        print("no captain")
        ShipAI():setPassive()
        terminate()
        return
    end

    -- find an asteroid that can be harvested
    AIMine.updateMining(timeStep)
end

-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign minedLoot
function AIMine.findMinedLoot()
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

-- check the sector for an asteroid that can be mined
-- if there is one, assign minedAsteroid
function AIMine.findMinedAsteroid()
    local ship = Entity()
    local sector = Sector()

    minedAsteroid = nil

    local mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
    local nearest = math.huge

    local hasMiningSystem = ship:hasScript("systems/miningsystem.lua")

    for _, a in pairs(mineables) do
        if a.type == EntityType.Asteroid and (a.isObviouslyMineable or hasMiningSystem) then            
            local material = a:getLowestMineableMaterial()
            local resources = a:getMineableResources()

            if resources ~= nil and resources > 0 and material ~= nil then
                -- only try to mine asteroids that are mineable by the available mining lasers
                if material.value <= miningMaterial + 1 then
                    local dist = distance2(a.translationf, ship.translationf)
                    if dist < nearest then
                        nearest = dist
                        minedAsteroid = a
                    end
                end
            end
        end
    end

    if minedAsteroid then
        noAsteroidsLeft = false
        broadcastInvokeClientFunction("setMinedAsteroid", minedAsteroid.index)
    else
        if noAsteroidsLeft == false then
            noAsteroidsLeft = true

            local faction = Faction(Entity().factionIndex)
            if faction then
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)

                faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your mining ship in sector %s can't find any more asteroids."%_T, coords)
                faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more asteroids in \\s(%s)!"%_T, coords)
            end

            ShipAI():setPassive()
        end
    end

end

function AIMine.updateMining(timeStep)
    local ship = Entity()

    if hasRawLasers == true then
        if Entity().freeCargoSpace < 1 then
            if noCargoSpace == false then
                local faction = Faction(ship.factionIndex)
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship's cargo bay in sector %s is full."%_T, coords) end

                ShipAI():setPassive()

                local ores, totalOres = getOreAmountsOnShip(ship)
                local scraps, totalScraps = getScrapAmountsOnShip(ship)
                if totalOres + totalScraps == 0 then
                    ShipAI():setStatus("Mining - No Cargo Space"%_T, {})
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't mine in \\s(%s), we have no space in our cargo bay!"%_T, coords) end
                    noCargoSpace = true
                else
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't continue mining in \\s(%s), we have no more space left in our cargo bay!"%_T, coords) end
                    terminate()
                end
            end

            return
        else
            noCargoSpace = false
        end
    end

    -- highest priority is collecting the resources
    if not valid(minedAsteroid) and not valid(minedLoot) then

        -- first, check if there is loot to collect
        AIMine.findMinedLoot()

        -- then, if there's no loot, check if there is an asteroid to mine
        if not valid(minedLoot) then
            AIMine.findMinedAsteroid()
        end

    end

    local ai = ShipAI()

    if valid(minedLoot) then
        ai:setStatus("Collecting Mined Loot /* ship AI status*/"%_T, {})

        -- there is loot to collect, fly there
        collectCounter = collectCounter + timeStep
        if collectCounter > 3 then
            collectCounter = collectCounter - 3

            if ai.isStuck then
                stuckLoot[minedLoot.index.string] = true
                AIMine.findMinedLoot()
                collectCounter = collectCounter + 2
            end

            if valid(minedLoot) then                
                ai:setFly(minedLoot.translationf, 0)
            end
        end

    elseif valid(minedAsteroid) then
        ai:setStatus("Mining /* ship AI status*/"%_T, {})

        -- if there is an asteroid to collect, harvest it
        if ship.selectedObject == nil
            or ship.selectedObject.index ~= minedAsteroid.index
            or ai.state ~= AIState.Harvest then

            ai:setHarvest(minedAsteroid)
            stuckLoot = {}
        end
    else
--        print("no asteroids")
        ai:setStatus("Mining - No Asteroids Left /* ship AI status*/"%_T, {})
    end

end

function AIMine.setMinedAsteroid(index)
    minedAsteroid = Sector():getEntity(index)
end

---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--
--    if valid(minedAsteroid) then
--        drawDebugSphere(minedAsteroid:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end

if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace SpawnPersecutors
SpawnPersecutors = {}

require("stringutility")
require("persecutorutility")
local AsyncShipGenerator = require ("asyncshipgenerator")
local Placer = require ("placer")

function SpawnPersecutors.getUpdateInterval()
    local time = 300
    if GameSettings().difficulty < Difficulty.Veteran then
        time = time + (Difficulty.Veteran - GameSettings().difficulty) * 60
    end

    return time
end

function SpawnPersecutors.initialize()
--    print ("init: %i %i", Sector():getCoordinates())
end

function SpawnPersecutors.update()

    local persecutedShip = sectorGetPersecutedCraft()
    if not persecutedShip then
        return
    end

    local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(Sector():getCoordinates()))

    local resolveIntersections = function(ships)
        Placer.resolveIntersections(ships)

        for i, ship in pairs(ships) do
            ship:addScript("entity/ai/persecutor.lua")
            if i == 1 then ship:addScript("entity/dialogs/encounters/persecutor.lua") end
        end
    end

    local generator = AsyncShipGenerator(SpawnPersecutors, resolveIntersections)

    local dir = random():getDirection()
    local matrix = MatrixLookUpPosition(-dir, vec3(0,1,0), persecutedShip.translationf + dir * 2000)

    generator:startBatch()
    generator:createPersecutorShip(faction, matrix)
    generator:createPersecutorShip(faction, matrix)
    generator:createDisruptorShip(faction, matrix)
    generator:createDisruptorShip(faction, matrix)
    generator:endBatch()

    local faction = Faction(persecutedShip.factionIndex)
    if faction.isPlayer then
        faction = Player(faction.index)

        local x, y = Sector():getCoordinates()
        local px, py = faction:getSectorCoordinates()
        if x == px and y == py then
            faction = nil
        end

    elseif faction.isAlliance then
        faction = Alliance(faction.index)
    end

    if faction then
        faction:sendChatMessage("", 2, [[A craft is under attack in sector \s(%s:%s)!]]%_T, Sector():getCoordinates())
    end

end

end

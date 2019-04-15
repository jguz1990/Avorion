if not onServer() then return end

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("stringutility")
local AsyncShipGenerator = require ("asyncshipgenerator")
local Placer = require("placer")

local threshold = 60 * 15

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HeadHunter
HeadHunter = {}

function HeadHunter.initialize()
end

function HeadHunter.getUpdateInterval()
    return threshold
end

function HeadHunter.update(timeStep)

    local x, y = Sector():getCoordinates()
    local hx, hy = Faction():getHomeSectorCoordinates()

    local dist = length(vec2(x, y))
    if dist > 550 then return end

    -- no attacks in the home sector
    if x == hx and y == hy then
        threshold = 60 * 3 -- try again after some minutes
        return
    end

    -- find a hopefully evil faction that the player knows already
    local faction = HeadHunter.findNearbyEnemyFaction()

    if faction == nil then
        threshold = 60 * 3 -- try again after some minutes
        return
    end

    -- create the head hunters
    HeadHunter.createEnemies(faction)

    threshold = 60 * 25
end

function HeadHunter.findNearbyEnemyFaction()

    -- find a hopefully evil faction that the player knows already
    local player = Player();

    local x, y = Sector():getCoordinates()


    local locations =
    {
        {x = x, y = y},
        {x = x + math.random(-7, 7), y = y + math.random(-7, 7)},
        {x = x + math.random(-7, 7), y = y + math.random(-7, 7)}
    }

    local faction = nil
    for i, coords in pairs(locations) do

        local f = Galaxy():getNearestFaction(x, y)

        if player:knowsFaction(f.index) then
            local relation = player:getRelations(f.index)

            if relation < -40000 then
                faction = f
                break
            end
        end
    end

    return faction
end

function HeadHunter.createEnemies(faction)

    local onFinished = function(ships)
        for _, ship in pairs(ships) do
            ShipAI(ship):setAggressive()

            if string.match(ship.title, "Persecutor") then
                ship.title = "Head Hunter"%_T
            end
        end

        Placer.resolveIntersections(ships)
    end

    -- create the head hunters
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500


    local generator = AsyncShipGenerator(HeadHunter, onFinished)
    generator:startBatch()

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates())

    generator:createPersecutorShip(faction, MatrixLookUpPosition(dir, up, pos), volume * 4)
    generator:createPersecutorShip(faction, MatrixLookUpPosition(dir, up, pos), volume * 4)
    generator:createBlockerShip(faction, MatrixLookUpPosition(dir, up, pos), volume * 2)

    generator:endBatch()

end

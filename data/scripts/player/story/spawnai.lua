if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("randomext")
local SectorSpecifics = require ("sectorspecifics")
local AI = require("story/ai")

local consecutiveJumps = 0
local noSpawnTimer = 0
local aiPresent = 0

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace SpawnAI
SpawnAI = {}

function SpawnAI.initialize()
    Player():registerCallback("onSectorEntered", "onSectorEntered")
end

function SpawnAI.onSectorEntered(player, x, y)

    if noSpawnTimer > 0 then return end

    local dist = length(vec2(x, y))
    local spawn

    if dist > 280 and dist < 340 then
        local specs = SectorSpecifics()
        local regular, offgrid, blocked, home = specs:determineContent(x, y, Server().seed)

        if not regular and not offgrid and not blocked and not home then
            if math.random() < 0.05 or consecutiveJumps > 8 then
                spawn = true
                -- on spawn reset the jump counter
                consecutiveJumps = 0
            else
                consecutiveJumps = consecutiveJumps + 1
            end
        else
            -- when jumping into the "wrong" sector, reset the jump counter
            consecutiveJumps = 0
        end
    end

    if not spawn then return end

    SpawnAI.spawnEnemies(x, y)
    aiPresent = true
end

-- this is in a separate function so it can be called from outside for testing
function SpawnAI.spawnEnemies(x, y)
    AI.spawn(x, y)
end

function SpawnAI.getUpdateInterval()
    if aiPresent then
        return 0.5
    else
        return 10
    end
end

function SpawnAI.updateServer(timeStep)
    local dropped, present = AI.checkForDrop()
    aiPresent = present

    noSpawnTimer = noSpawnTimer - timeStep
    if dropped then
        noSpawnTimer = 30 * 60
    end
end

end

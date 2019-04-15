if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")
require("galaxy")
require("player")
local ShipGenerator = require ("shipgenerator")
local Xsotan = require("story/xsotan")

local minute = 0
local attackType = 1

function initialize(attackType_in)
    attackType = attackType_in or 1
    deferredCallback(1.0, "update", 1.0)

    if Sector():getValue("neutral_zone") then
        print ("No xsotan attacks in neutral zones.")
        terminate()
        return
    end

    local first = Sector():getEntitiesByFaction(Xsotan.getFaction().index)
    if first then
        terminate()
        return
    end

end

function getUpdateInterval()
    return 60
end

function update(timeStep)

    minute = minute + 1

    if attackType == 0 then

        if minute == 1 then
            Player():sendChatMessage("", 3, "Your sensors picked up a short burst of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("", 3, "More strange subspace signals, they're getting stronger."%_t)
        elseif minute == 5 then
            createEnemies({
                  {size=1, title="Xsotan Scout"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  })

            Player():sendChatMessage("", 2, "A small group of alien ships appeared!"%_t)
            terminate()
        end

    elseif attackType == 1 then

        if minute == 1 then
            Player():sendChatMessage("", 3, "Your sensors picked up short bursts of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("", 3, "The signals are growing stronger."%_t)
        elseif minute == 5 then
            createEnemies({
                  {size=1, title="Xsotan Scout"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  })

            Player():sendChatMessage("", 2, "A group of alien ships warped in!"%_t)
            terminate()
        end

    elseif attackType == 2 then

        if minute == 1 then
            Player():sendChatMessage("", 3, "Your sensors picked up short bursts of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("", 3, "There are lots and lots of subspace signals! Careful!"%_t)
        elseif minute == 5 then

            createEnemies({
                  {size=1, title="Xsotan Scout"%_t},
                  {size=2, title="Xsotan Scout"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=5, title="Big Xsotan Ship"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=2, title="Xsotan Scout"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  })

            Player():sendChatMessage("", 2, "A large group of alien ships appeared!"%_t)
            terminate()
        end

    elseif attackType == 3 then

        if minute == 1 then
            Player():sendChatMessage("", 3, "Your sensors picked up short bursts of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("", 3, "The subspace signals are getting too strong for your scanners. Brace yourself!"%_t)
        elseif minute == 5 then

            createEnemies({
                  {size=1, title="Xsotan Scout"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  {size=2, title="Xsotan Scout"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=5, title="Big Xsotan Ship"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=3, title="Xsotan Ship"%_t},
                  {size=2, title="Xsotan Scout"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  {size=1, title="Xsotan Scout"%_t},
                  })

            Player():sendChatMessage("", 2, "Danger! A large fleet of alien ships appeared!"%_t)
            terminate()
        end

    end

end


function createEnemies(volumes, message)
    local sector = Sector()
    local xsotanFaction = Xsotan.getFaction()

    local first = sector:getEntitiesByFaction(xsotanFaction.index)
    if first then
        terminate()
        return
    end

    local galaxy = Galaxy()


    -- worsen relations to all present players and alliances
    local players = {sector:getPlayers()}
    for _, player in pairs(players) do
        Galaxy():changeFactionRelations(xsotanFaction, player, -200000)
    end

    local factions = {sector:getPresentFactions()}
    for _, factionIndex in pairs(factions) do
        local faction = Faction(factionIndex)
        if faction and not faction.isAIFaction then
            Galaxy():changeFactionRelations(xsotanFaction, faction, -200000)
        end
    end

    -- create the enemies
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500

    for _, p in pairs(volumes) do

        local enemy = Xsotan.createShip(MatrixLookUpPosition(-dir, up, pos), p.size)
        enemy.title = p.title

        local distance = enemy:getBoundingSphere().radius + 20

        pos = pos + right * distance

        enemy.translation = dvec3(pos.x, pos.y, pos.z)

        pos = pos + right * distance + 20

        -- patrol.lua takes care of setting aggressive
    end

    AlertAbsentPlayers(2, "A group of alien ships appeared in sector \\s(%s:%s)!"%_t, sector:getCoordinates())
end



end

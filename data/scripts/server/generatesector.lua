package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";data/scripts/sectors/?.lua"

SectorSpecifics = require ("sectorspecifics")

local specs
local stationsFrom, stationsTo
local shipsFrom, shipsTo
local gates

function initialize(x, y, serverSeed)
    if not specs then
        specs = SectorSpecifics(x, y, serverSeed)
    else
        specs:initialize(x, y, serverSeed)
    end
end

function getScript(script)
    local used = nil

    if script ~= nil then
        -- use the script that was given by the application
        used = require(script)
    else
        -- use the script that was determined earlier
        used = specs.generationTemplate
    end

    return used
end

function generate(player, script)

    local used = getScript(script)
    if used ~= nil then
        if specs.generationSeed == nil then
            local rand = Random(specs.sectorSeed)
            specs.generationSeed = rand:createSeed()
        end

        used.generate(player, specs.generationSeed, specs.coordinates.x, specs.coordinates.y)
    end

end

function getExpectedShips(script)
    local used = getScript(script)
    if used and used.ships then
        return used.ships(specs.coordinates.x, specs.coordinates.y)
    end
end

function getExpectedStations(script)
    local used = getScript(script)
    if used and used.stations then
        return used.stations(specs.coordinates.x, specs.coordinates.y)
    end
end

function getMusic(script)
    local used = getScript(script)
    if used and used.musicTracks then
        return used.musicTracks()
    end
end

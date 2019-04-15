package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("mission")
require("utility")
require("stringutility")
require("callable")
local SectorSpecifics = require("sectorspecifics")
local Dialog = require ("dialogutility")


missionData.brief = "Explore Sector"%_t
missionData.title = "Explore sector (${location.x}:${location.y})"%_t
missionData.description = "The ${giver} asked you to explore sector (${location.x}:${location.y})."%_t

function initialize(giverIndex, x, y, reward)

    if onClient() then
        sync()
        Player():registerCallback("onPreRenderHud", "onPreRenderHud")
        Player():registerCallback("onStartDialog", "startDialog")

    else
        Player():registerCallback("onSectorEntered", "onSectorEntered")

        -- if it's not being initialized from outside, skip initialization
        -- the script will be restored via restore()
        if _restoring or not giverIndex then return end

        missionData.explored = 0
        missionData.enemies = {}
        missionData.interestingPoints = nil
        missionData.finishedExploration = false
        missionData.firstTime = true
        missionData.fulfilled = 0

        -- don't initialize data if there is none
        if not giverIndex then
            terminate()
            return
        end

        local station = Entity(giverIndex)
        missionData.giver = Sector().name .. " " .. station.translatedTitle
        missionData.location = {x = x, y = y}
        missionData.reward = reward
        missionData.justStarted = true
        missionData.factionIndex = station.factionIndex
        local x0, y0 = Sector():getCoordinates()
        missionData.giverCoordinates = {x = x0, y = y0}
    end
end

function onSectorEntered(playerindex, x, y)
    if onServer() then
        if missionData.firstTime then
            if missionData.location.x == x and missionData.location.y == y then

                local player = Player()
                local specs = SectorSpecifics()
                local serverSeed = Server().seed
                specs:initialize(x, y, serverSeed)

                local explorable = {}

                --used if there are pirates
                if specs.generationTemplate.path == "sectors/pirateasteroidfield" or specs.generationTemplate.path == "sectors/piratefight" or specs.generationTemplate.path == "sector/piratestation" then
                    --print("pirates")
                    local ships = {Sector():getEntitiesByType(EntityType.Ship)}
                    for _, ship in pairs(ships) do
                        if not ship.index == player.craftIndex then
                            table.insert(explorable, ship)
                            ship:registerCallback("onDestroyed", "destroyedExplorable")
                        end

                        if #explorable >= 3 then
                            break
                        end
                    end

                --used if there are wreckages
                elseif specs.generationTemplate.path == "sectors/functionalwreckage" or specs.generationTemplate.path == "sectors/stationwreckage" or specs.generationTemplate.path == "sectors/wreckageasteroidfield" or specs.generationTemplate.path == "sectors/wreckagefield" then
                    --print("wreckages")
                    local wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
                    for _, wreckage in pairs(wreckages) do
                        table.insert(explorable, wreckage)
                        wreckage:registerCallback("onDestroyed", "destroyedExplorable")

                        if #explorable >= 2 then
                            break
                        end
                    end

                --used if there are nonagressive factions
                elseif specs.generationTemplate.path == "sectors/smugglerhideout" or specs.generationTemplate.path == "sectors/cultists" or specs.generationTemplate.path == "sectors/resistancecell" then
                    --print("nonagressive faction")
                    local stations = {Sector():getEntitiesByType(EntityType.Station)}
                    for _, station in pairs(stations) do
                        table.insert(explorable, station)
                        station:registerCallback("onDestroyed", "destroyedExplorable")

                        if #explorable >= 2 then
                            break
                        end
                    end

                    local ships = {Sector():getEntitiesByType(EntityType.Ship)}
                    for _, ship in pairs(ships) do
                        if not ship.index == player.craftIndex then
                            table.insert(explorable, ship)
                            ship:registerCallback("onDestroyed", "destroyedExplorable")
                        end

                        if #explorable >= 5 then
                            break
                        end
                    end


                --used if there is a containerfield
                elseif specs.generationTemplate.path == "sectors/containerfield" then
                    --print("containerfield")
                    local containers = {Sector():getEntitiesByType(EntityType.None)}
                    for _, container in pairs(containers) do
                        table.insert(explorable, container)
                        container:registerCallback("onDestroyed", "destroyedExplorable")

                        if #explorable >= 3 then
                            break
                        end
                    end

                end

                --add some asteroids to the objects to explore
                local asteroids = {Sector():getEntitiesByType(EntityType.Asteroid)}
                for _, asteroid in pairs(asteroids) do
                    if #explorable >= math.random(5, 8) then
                        break
                    end

                    asteroid:registerCallback("onDestroyed", "destroyedExplorable")
                    table.insert(explorable, asteroid)
                end


                for i = 1, #explorable do
                    explorable[i]:addScriptOnce("player/missions/exploresector/exploreobject.lua")
                    explorable[i] = explorable[i].id.string
                end

                missionData.interestingPoints = explorable
                missionData.firstTime = false
                sync()
            end
            return
        end
    end
end

function destroyedExplorable()
    if onClient() then
        invokeServerFunction("destroyedExplorable")
    end

    showMissionFailed()
    terminate()
    return
end
callable(nil, "destroyedExplorable")

function onPreRenderHud()
    local renderer = UIRenderer()
    if missionData.interestingPoints == nil then
        return
    end

    local sector = Sector()
    for i = 1, #missionData.interestingPoints do
        local color = ColorRGB(0.2, 0.5, 0.2)
        local entity = sector:getEntity(Uuid(missionData.interestingPoints[i]))
        if entity and entity:hasScript("exploreobject.lua") then
            renderer:renderEntityTargeter(entity, color)
            renderer:renderEntityArrow(entity, 30, 10, 250, color)
        end
    end
    renderer:display()
end

function explored()
    missionData.explored = missionData.explored + 1

    if missionData.interestingPoints and missionData.explored >= #missionData.interestingPoints then
        finishedExploration()
    end
end

function finishedExploration()
    showMissionUpdated("Sector Explored"%_t)
    missionData.description = "You explored the Sector. Bring the information back to the military outpost"%_t
    missionData.location = {x = missionData.giverCoordinates.x, y = missionData.giverCoordinates.y}
    missionData.finishedExploration = true
    sync()
end

function startDialog(entityId)
    if missionData.finishedExploration == true and missionData.fulfilled == 0 then
        local potentialMilitaryOutpost = Sector():getEntity(entityId)
        local isMilitaryOutpost = potentialMilitaryOutpost:hasScript("militaryoutpost.lua")

        if missionData.factionIndex == potentialMilitaryOutpost.factionIndex and isMilitaryOutpost then
            ScriptUI(entityId):addDialogOption("I found some information in the explored sector."%_t, "onDeliver", entityId)
        end
    end
end

function onDeliver(entityId)
    if onClient() then
        invokeServerFunction("onDeliver", entityId)
        return
    end

    if missionData.fulfilled == 1 then
        return
    end

    missionData.timeLimit = 5
    missionData.fulfilled = 1
    onAccomplished(entityId)
    sync()
    --invokeClientFunction(Player(), "onAccomplished", entityId)
end
callable(nil, "onDeliver")

function onAccomplished(entityId)
    if onServer then
        player = Player()
        player:receive("Earned %1% credits for exploring a sector."%_T, missionData.reward)
        player:sendChatMessage(missionData.giver, 0, "Thank you for helping us expand our borders. We transferred the reward to your account."%_t)
        finish()
        return
    end
end

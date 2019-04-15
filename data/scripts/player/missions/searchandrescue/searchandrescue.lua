package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("stringutility")
require ("mission")
require ("galaxy")
require ("callable")
local SectorGenerator = require ("SectorGenerator")
local SectorSpecifics = require ("sectorspecifics")
local Dialog = require ("dialogutility")

if onServer() then

function initialize()
    if _restoring then return end

    missionData.fulfilled = 0
    missionData.allCoordinates = {}
    missionData.firstPart = true
    missionData.started = true

    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 10, 15)

    for _, start in pairs(coords) do
        local finalCoords = specs.getShuffledCoordinates(random(), start.x, start.y, 1, 8)

        for _, tempCoords in pairs(finalCoords) do
            local regular, offgrid, blocked, home = specs:determineContent(tempCoords.x, tempCoords.y, Server().seed)

            if not regular and not offgrid and not blocked and not home then
                table.insert(missionData.allCoordinates, tempCoords)
            end

            if #missionData.allCoordinates >= 5 then break end
        end

        if #missionData.allCoordinates >= 5 then break end
    end

    if #missionData.allCoordinates <= 0 then
        terminate()
        return
    end

    faction = Galaxy():getLocalFaction(x, y) or Galaxy():getNearestFaction(x, y)
    missionData.factionIndex = faction.index

    local x, y = faction:getHomeSectorCoordinates()
    missionData.homeSector = {x = x, y = y}

    local relations = faction:getRelations(faction.index)
    local player = Player()
    if  player:getRelations(missionData.factionIndex) <= -20000 then
        terminate()
        return
    end

    player:registerCallback("onSectorEntered", "onSectorEntered")
    local messages =
    {
        "CHRRK....Mayday, mayd....CHRRRRK....explosion...CHRRK....Need help....CHRRK"%_t,
        "Hello?...Can you....CHRRK...Can you hear us?...CHHRRK....Emergency"%_t,
        "This is.....emergency call.....CHRRRK....life threatening situation....."%_t,
        "CHRRK....Lost.....Navigate....CHRRRK.....immediate help.....someone...CHRRRK"%t,
    }

    player:sendChatMessage("Unknown"%_t, 0, randomEntry(random(), messages))
    player:sendChatMessage("", 3, "You have received an emergency signal by an unknown source."%_t)
end

function updateServer(timeStep)
    updateMission(timeStep)
end

function getUpdateInterval()
    return 1
end

function onSectorEntered(playerIndex, x, y)
    local player = Player()
    if x == missionData.homeSector.x and y == missionData.homeSector.y then
        local stations = {Sector(x, y):getEntitiesByType(EntityType.Station)}
        local headquarters = false

        --check if headquarters of the mission faction is still alive, if not abort mission
        for _, station in pairs(stations) do
            if station:hasScript("headquarters.lua") then
                station:registerCallback("onDestroyed", "destroyedHeadquarters")
                headquarters = true
            end
        end

        if headquarters == false then
            destroyedHeadquarters()
        end

        return
    end

    if x == missionData.allCoordinates[1].x and y == missionData.allCoordinates[1].y then
        if missionData.started == true then
            local messages =
            {
                "Mayday, mayday! We had an explosion. We need help as fast as possible!"%_t,
                "Hello? Can you hear us? Can you hear us? We are having an emergency. Help us please!"%_t,
                "This is an emergency call. We are in a life threatening situation. Please help us!"%_t,
                "We lost our ability to navigate. We need immediate help. Is someone out there?"%_t,
            }

            player:sendChatMessage("Unknown"%_t, 0, randomEntry(random(), messages))
            local generator = SectorGenerator(x, y)
            local faction = Faction(missionData.factionIndex)
            for i = 1, math.random(1, 3) do
                generator:createWreckage(faction)
            end

            local maxVolume = -1
            local biggestWreckage
            local wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
            for _, wreckage in pairs(wreckages) do
                local plan = Plan(wreckage)
                local volume = plan:getStats().volume
                wreckage:addScriptOnce("player/missions/searchandrescue/searchwreckage.lua")
                if volume > maxVolume then
                    biggestWreckage = wreckage
                    biggestWreckageId = biggestWreckage.index
                    maxVolume = volume
                end
            end

            biggestWreckage:removeScript("player/missions/searchandrescue/searchwreckage.lua")
            biggestWreckage:addScriptOnce("player/missions/searchandrescue/findwreckage.lua")
            biggestWreckage:registerCallback("onDestroyed", "destroyedWreckage")

            local x, y = faction:getHomeSectorCoordinates(x, y)
            missionData.factionCoordinates = {x = x, y = y}
            showMissionStarted("Search for information."%_t)
        end

        missionData.started = false
        return
    end

    for i = 2, 5 do
        if x == missionData.allCoordinates[i].x and y == missionData.allCoordinates[i].y then
            local messages =
            {
                "CHRRK....Mayday, mayd....CHRRRRK....explosion...CHRRK....Need help....CHRRK"%_t,
                "Hello?...Can you....CHRRK...Can you hear us?...CHHRRK....Emergency"%_t,
                "This is.....emergency call.....CHRRRK....life threatening situation....."%_t,
                "CHRRK....Lost.....Navigate....CHRRRK.....immediate help.....someone...CHRRRK"%t,
            }

            player:sendChatMessage("Unknown"%_t, 0, randomEntry(random(), messages))
            return
        end
    end
end
end

if onClient() then

function initialize()
    local player = Player()
    player:registerCallback("onStartDialog", "startDialog")
    sync()
end

function getMissionBrief()
    return "Emergency Call"%_t
end

function getMissionDescription()
    if missionData.firstPart == true then
        local randomCoordinates = {}
        for i = 1, #missionData.allCoordinates do
            table.insert (randomCoordinates, math.random(#randomCoordinates), missionData.allCoordinates[i])
        end
        local description = string.format("You received a emergency call from an unknown source. Their position should be one of the following:"%_t)
        for _, coordinates in pairs(randomCoordinates) do
            description = description .. string.format("\n(%i:%i)", coordinates.x, coordinates.y)
        end

        return description
    elseif missionData.factionCoordinates then
        return string.format("You found the debris of the lost ship. Bring the bad news back to their headquarters in their homesector. (%i:%i)."%_t, missionData.factionCoordinates.x, missionData.factionCoordinates.y)
    end

    return ""
end

function startDialog(entityId)
    if missionData.firstPart == false and missionData.fulfilled == 0 then
        local potentialHeadquarters = Entity(entityId)
        local isHeadquarters = potentialHeadquarters:hasScript("headquarters.lua")

        if missionData.factionIndex == potentialHeadquarters.factionIndex and isHeadquarters then
            ScriptUI(entityId):addDialogOption("I have news for you."%_t, "onDeliver", entityId)
        end
    end
end
end

function getMissionLocation()
    if missionData.firstPart == true then
        local locations = {}
        for _, coordinates in pairs(missionData.allCoordinates) do
            table.insert(locations, ivec2(coordinates.x, coordinates.y))
        end

        return unpack(locations)
    elseif missionData.factionCoordinates then
        return missionData.factionCoordinates.x, missionData.factionCoordinates.y
    end
end

function onDeliver(entityId)
    if onClient() then
        ScriptUI(entityId):showDialog(Dialog.empty())

        invokeServerFunction("onDeliver", entityId)
        return
    end

    if missionData.fulfilled == 1 then
        return
    end

    local x, y = Sector():getCoordinates()
    local player = Player(callingPlayer)
    local faction = Faction(missionData.factionIndex)

    player:receive("Received %1% credits for delivering information about the fate of a ship."%_T, 10000 * Balancing_GetSectorRichnessFactor(x, y))
    Galaxy():changeFactionRelations(player, faction, 3000)

    missionData.timeLimit = 5
    missionData.fulfilled = 1

    sync()
    invokeClientFunction(player, "onAccomplished", entityId)
end
callable(nil, "onDeliver")

function onAccomplished(entityId)
    local dialog = {}
    dialog.text = "These are sad news. But we thank you for your help. We transferred some money to your account for your troubles."%_t
    ScriptUI(entityId):showDialog(dialog)
end

function nextPart()
    if onClient() then
        invokeServerFunction("nextPart")
        return
    end

    missionData.firstPart = false
    sync()
end
callable(nil, "nextPart")

function destroyedHeadquarters()
    if onClient() then
        invokeServerFunction("destroyedHeadquarters")
    end

    showMissionFailed("The headquarters are destroyed."%_t)
    terminate()
    return
end
callable(nil, "destroyedHeadquarters")

function destroyedWreckage()
    if onClient() then
        invokeServerFunction("destroyedWreckage")
    end

    showMissionFailed("The flightrecorder was destroyed."%_t)
    terminate()
    return
end
callable(nil, "destroyedWreckage")

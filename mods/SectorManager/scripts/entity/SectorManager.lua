package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
require ("utility")
require ("callable")
local lib = require ("mods/SectorManager/scripts/lib/sectorManagerLib")
local config = require ("mods/SectorManager/config/SectorManagerConfig")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace sectorManager
sectorManager = {}

-- Data
local selX, selY
local keepTheseLoaded = {}
local storageString = "loadedSectorList"

-- UI
local uiInitialized
local scrollframe
local addButton, selectSectorButton
local lines = {}
local lineElementToIndex = {}
local sectorStatusLabel

function sectorManager.initialize()
    local player = Player()
    if onClient() then
        player:registerCallback("onSelectMapCoordinates", "onSelectMapCoordinates")
        invokeServerFunction("getConfig")
    end
end

function sectorManager.receiveConfig(rConfig)
    config = rConfig
end

-- Activated "Add" Button
function sectorManager.onSelectMapCoordinates(x, y)
    selX, selY = x, y
    sectorManager.checkAndActivateAddButton()
end

function sectorManager.getIcon()
    return "mods/SectorManager/textures/icons/connection.png"
end

-- Only allow interaction, when a plyer is on board
function sectorManager.interactionPossible(playerIndex)
    local factionIndex = Entity().factionIndex
    if Entity().index.number == Player(playerIndex).craftIndex.number and (factionIndex == playerIndex or factionIndex == Player(playerIndex).allianceIndex) then
        return true
    end
    return false
end

function sectorManager.initUI()
    local res = getResolution()
    local size = vec2(335, 350)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Sector Manager"
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Manage Sectors"%_t);

    sectorStatusLabel = window:createLabel(vec2(window.size.x - 85, 0), "?/?", 12)
    sectorStatusLabel.width = 80
    sectorStatusLabel:setRightAligned()
    local textLabel = window:createLabel(vec2(5, 0), "Sectors:", 12)
    textLabel.tooltip = "Shows the number of Sectors you want to load and the maximum allowed loaded sectors."
    textLabel:setLeftAligned()

    scrollframe = window:createScrollFrame(Rect(vec2(0, 35), window.size - vec2(0,0)))
    scrollframe.scrollSpeed = 35

    local y = 35
    local buttonSize = vec2(80,25)
    local bPX = vec2(lib.centerUIElementX(scrollframe, buttonSize.x))
    local buttonRect = Rect(bPX.x-10, y+5, bPX.y-10, y+5+buttonSize.y)
    addButton = scrollframe:createButton(buttonRect, "Add", "onAddButtonPressed")
    addButton.active = false
    addButton.tooltip = "Select a sector on the Galaxymap."
    y = y + 35

    buttonSize = vec2(150,25)
    bPX = vec2(lib.centerUIElementX(scrollframe, buttonSize.x))
    buttonRect = Rect(bPX.x-10, y+5, bPX.y-10, y+5+buttonSize.y)
    selectSectorButton = scrollframe:createButton(buttonRect, "Select Sector", "onSelectSectorButtonPressed")

    uiInitialized = true
end
-- Visually update loaded sector
function sectorManager.onShowWindow()
    sectorManager.requestSectorList()
end

function sectorManager.checkAndActivateAddButton()
    if not uiInitialized then return end
    if selX and selY then
        addButton.active = true
        addButton.tooltip = "Adds Sector ("..selX..":"..selY..") to the load list."
    else
        addButton.active = false
        addButton.tooltip = "Select a sector on the Galaxymap."
    end
end

function sectorManager.requestSectorList()
    invokeServerFunction("sendSectorList")
end

function sectorManager.receiveSectorList(sectorList)
    for _,_ in pairs(keepTheseLoaded) do
        sectorManager.removeLastLine()
    end
    keepTheseLoaded = sectorList
    sectorStatusLabel.caption = #keepTheseLoaded.."/"..config.maxSectorPerPlayer
    for _, sector in ipairs(keepTheseLoaded) do
        sectorManager.appendLine(sector.x, sector.y)
    end
    invokeServerFunction("checkLoadedSectors")
end

function sectorManager.receiveActivelyLoadedList(loadList)
    for index,_ in ipairs(lines) do
        if loadList[index] == 1 then
            lines[index].sectorLabel.color = ColorRGB(0.1, 0.7, 0.1)
        else
            lines[index].sectorLabel.color = ColorRGB(1, 1, 1)
        end
    end
end

function sectorManager.appendLine(sectorX, sectorY)
    local index = #lines+1
    local y = index * 35
    local labelsize = vec2(130, 35)
    local buttonSize = vec2(32, 32)
    local bX = {200, 240, 280}

    local labelText = sectorX..":"..sectorY
    local sectorLabel = scrollframe:createLabel(vec2(5,y), labelText, 12)
    sectorLabel.width = labelsize.x
    sectorLabel.height = labelsize.y
    sectorLabel.mouseDownFunction = "sectorLabelPressed"
    sectorLabel.tooltip = "Click to show the sector on the Galaxymap."
    lineElementToIndex[sectorLabel.index] = index


    local upButton = scrollframe:createButton(Rect(bX[1],y+2, bX[1]+buttonSize.x,y+2+buttonSize.y ), "", "upButtonPressed")
    upButton.icon = "mods/SectorManager/textures/icons/arrow-up.png"
    lineElementToIndex[upButton.index] = index

    local downButton = scrollframe:createButton(Rect(bX[2],y+2, bX[2]+buttonSize.x,y+2+buttonSize.y ), "", "downButtonPressed")
    downButton.icon = "mods/SectorManager/textures/icons/arrow-down.png"
    downButton.active = false
    lineElementToIndex[downButton.index] = index

    local deleteLabel = scrollframe:createLabel(vec2(bX[3],y+2), "", 12)
    deleteLabel.mouseDownFunction = "deleteLabelPressed"
    deleteLabel.width = 32
    deleteLabel.height = 32
    deleteLabel.tooltip = "Remove sector from List."
    lineElementToIndex[deleteLabel.index] = index
    local deletePic = scrollframe:createPicture(Rect(bX[3],y+2, bX[3]+buttonSize.x,y+2+buttonSize.y) , "mods/SectorManager/textures/icons/cross-mark.png")
    deletePic.color = ColorRGB(0.705, 0.165, 0.165)
    lineElementToIndex[deletePic.index] = index
    lines[index] = {sectorLabel = sectorLabel, upButton = upButton, downButton = downButton, deleteLabel = deleteLabel, deletePic = deletePic}

    addButton.position = addButton.position + vec2(0,35)
    selectSectorButton.position = selectSectorButton.position + vec2(0,35)

    if lines[index-1] then  -- Make sure that the previous buttons don't allow invalid input
        local prevLine = lines[index-1]
        prevLine.downButton.active = true
        prevLine.deleteLabel.tooltip = nil
        prevLine.deleteLabel.mouseDownFunction = nil
        prevLine.deletePic.color = ColorRGB(0.2, 0.2, 0.2)
    else
        upButton.active = false
    end
end

function sectorManager.removeLastLine()
    local index = #lines
    if index < 1 then print("tried to remove empty line", index) return end
    local l = lines[index]
    lineElementToIndex[l.sectorLabel.index] = nil
    lineElementToIndex[l.upButton.index] = nil
    lineElementToIndex[l.downButton.index] = nil
    lineElementToIndex[l.deleteLabel.index] = nil
    lineElementToIndex[l.deletePic.index] = nil
    l.sectorLabel.visible = false
    l.upButton.visible = false
    l.downButton.visible = false
    l.deleteLabel.visible = false
    l.deletePic.visible = false
    lines[index] = nil

    addButton.position = addButton.position - vec2(0,35)
    selectSectorButton.position = selectSectorButton.position - vec2(0,35)

    if lines[index-1] then  -- Make sure that the previous buttons don't allow invalid input
        local prevLine = lines[index-1]
        prevLine.downButton.active = false
        prevLine.deleteLabel.tooltip = "Remove sector from List."
        prevLine.deleteLabel.mouseDownFunction = "deleteLabelPressed"
        prevLine.deletePic.color = ColorRGB(0.705, 0.165, 0.165)
    end
end

function sectorManager.onAddButtonPressed()
    for _,sector in ipairs(keepTheseLoaded) do
        if sector.x == selX and sector.y == selY then
            displayChatMessage("You already load sector \\s("..selX..":"..selY..") ", "Sector Manager", 0)
            return
        end
    end
    if selX == 0 and selY == 0 then displayChatMessage("Unable to load sector (0:0).", "Sector Manager", 0) return end
    keepTheseLoaded[#keepTheseLoaded+1] = {x = selX, y = selY}
    sectorManager.appendLine(selX, selY)
    invokeServerFunction("setSectorList", keepTheseLoaded)
end

function sectorManager.sectorLabelPressed(label)
    local sector = keepTheseLoaded[lineElementToIndex[label]]
    GalaxyMap():show(sector.x, sector.y)
end

function sectorManager.upButtonPressed(button)
    sectorManager.swapPosition(lineElementToIndex[button.index], lineElementToIndex[button.index]-1)
    invokeServerFunction("setSectorList", keepTheseLoaded)
end

function sectorManager.downButtonPressed(button)
    sectorManager.swapPosition(lineElementToIndex[button.index], lineElementToIndex[button.index]+1)
    invokeServerFunction("setSectorList", keepTheseLoaded)
end

function sectorManager.deleteLabelPressed(label)
    local index = lineElementToIndex[label]
    if index ~= #lines or index ~= #keepTheseLoaded then print("length mismatch", index, #lines, #keepTheseLoaded) return end
    keepTheseLoaded[index] = nil

    sectorManager.removeLastLine()
    invokeServerFunction("setSectorList", keepTheseLoaded)
end

function sectorManager.swapPosition(pos1, pos2)
    if not keepTheseLoaded[pos1] or not keepTheseLoaded[pos2] then print("Well, poor you!") return end
    local sector1, sector2 = keepTheseLoaded[pos1], keepTheseLoaded[pos2]
    keepTheseLoaded[pos1] = sector2
    keepTheseLoaded[pos2] = sector1

    local line1, line2 = lines[pos1], lines[pos2]
    local labelText1 = sector1.x..":"..sector1.y
    local labelText2 = sector2.x..":"..sector2.y
    --enforce Label sizes again, to prevent them from going outside of the scrollframe, after their text changed
    line1.sectorLabel.caption = labelText2
    line2.sectorLabel.caption = labelText1
    line1.sectorLabel.width = 130
    line2.sectorLabel.width = 130
    line1.sectorLabel.height = 35
    line2.sectorLabel.height = 35
end

function sectorManager.onSelectSectorButtonPressed()
    if selX and selY then
        GalaxyMap():show(selX, selY)
    else
        GalaxyMap():show(Sector():getCoordinates())
    end
end
--====================
--===== Server =======
--====================
function sectorManager.getConfig()
    local player = Player(callingPlayer)
    invokeClientFunction(player, "receiveConfig", config)
end
callable(sectorManager, "getConfig")

function sectorManager.checkLoadedSectors()
    local player = Player(callingPlayer)
    if player and player.craftIndex.number == Entity().index.number then
        local loadList = {}
        local galax = Galaxy()
        for i=1,config.maxSectorPerPlayer do
            if keepTheseLoaded[i] then
                local sector = keepTheseLoaded[i]
                if galax:sectorLoaded(sector.x, sector.y) then
                    loadList[i] = 1
                else
                    loadList[i] = 0
                end
            end
        end
        invokeClientFunction(player, "receiveActivelyLoadedList", loadList)
    end
end
callable(sectorManager, "checkLoadedSectors")

function sectorManager.setSectorList(sectorList)
    local player = Player(callingPlayer)
    if not player then print("Who else called?", Alliance() and Alliance().name) return end
    sectorList = sectorList or {}
    keepTheseLoaded = sectorList
    local sectorString = lib.sectorListToString(keepTheseLoaded, player)
    player:setValue(storageString, sectorString)
end
callable(sectorManager, "setSectorList")

function sectorManager.sendSectorList()
    local player = Player(callingPlayer)
    if not player then print("Who else called?", Alliance() and Alliance().name) return end
    keepTheseLoaded = lib.stringToSectorList(player:getValue(storageString))
    invokeClientFunction(player, "receiveSectorList", keepTheseLoaded)
end
callable(sectorManager, "sendSectorList")

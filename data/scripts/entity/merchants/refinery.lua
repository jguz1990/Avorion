package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")
require("callable")
require("faction")
local Dialog = require("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Refinery
Refinery = {}

local runningJobs = {}
local finishedJobs = {}
local window

local oreAmountOnShipLabels = {}
local oreAmountToRefineBoxes = {}
local oreOutputAmountLabels = {}

local scrapAmountOnShipLabels = {}
local scrapAmountToRefineBoxes = {}
local scrapOutputAmountLabels = {}

local addAllButton
local refineButton
local takeButton
local remainingTimeLabel
local timeLeft = 0
local totalTime = 0
local progressBar
local taxLabel

local oreNameByMaterial = {}
oreNameByMaterial[1] = "Iron Ore"
oreNameByMaterial[2] = "Titanium Ore"
oreNameByMaterial[3] = "Naonite Ore"
oreNameByMaterial[4] = "Trinium Ore"
oreNameByMaterial[5] = "Xanion Ore"
oreNameByMaterial[6] = "Ogonite Ore"
oreNameByMaterial[7] = "Avorion Ore"

local scrapNameByMaterial = {}
scrapNameByMaterial[1] = "Scrap Iron"
scrapNameByMaterial[2] = "Scrap Titanium"
scrapNameByMaterial[3] = "Scrap Naonite"
scrapNameByMaterial[4] = "Scrap Trinium"
scrapNameByMaterial[5] = "Scrap Xanion"
scrapNameByMaterial[6] = "Scrap Ogonite"
scrapNameByMaterial[7] = "Scrap Avorion"

function Refinery.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -25000)
end

function Refinery.getUpdateInterval()
    return 1
end

function Refinery.secure()
    return {runningJobs = runningJobs, finishedJobs = finishedJobs}
end

function Refinery.restore(data)
    if not data then return end

    runningJobs = data.runningJobs or {}
    finishedJobs = data.finishedJobs or {}
end

function Refinery.initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Refinery"%_t
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/resources.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    else
        Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    end
end

function Refinery.onRestoredFromDisk(timeSinceLastSimulation)
    Refinery.updateServer(timeSinceLastSimulation)
end

if onClient() then
function Refinery.update(timeStep)
    if remainingTimeLabel then
        if refineButton and refineButton.active == false then
            Refinery.updateRemainingTimeLabel(timeLeft - timeStep, totalTime)
        end
    end
end
end

function Refinery.updateServer(timeStep)
    for faction, job in pairs(runningJobs) do
        job.remainingTime = job.remainingTime - timeStep

        if job.remainingTime <= 0 then
            local finished = {}

            finished.netOreAmounts = job.netOreAmounts
            finished.netScrapAmounts = job.netScrapAmounts
            finished.grossOreAmounts = job.grossOreAmounts
            finished.grossScrapAmounts = job.grossScrapAmounts
            finished.totalTime = job.totalTime
            finished.tax = job.tax

            -- pay tax to station faction
            for material = 1, NumMaterials() do
                local taxAmount = job.grossOreAmounts[material] - job.netOreAmounts[material]
                taxAmount = taxAmount + job.grossScrapAmounts[material] - job.netScrapAmounts[material]
                if taxAmount > 0 then
                    Faction():receiveResource(Format("Received %1% %2% tax from refinery."%_t, taxAmount, Material(material - 1).name), Material(material - 1), taxAmount)
                end
            end

            finishedJobs[faction] = finished
            runningJobs[faction] = nil

            broadcastInvokeClientFunction("onJobFinished", faction)

            local f = Faction(faction)
            if f then
                local sector = Sector()
                f:sendChatMessage(Entity(), ChatMessageType.Normal, "We finished refining your ores. You can pick them up in \\s(%i:%i)."%_t, sector:getCoordinates())
            end
        end
    end
end

function Refinery.addJob(craftIndex, oreAmounts, scrapAmounts, noDockCheck)
    local faction, craft, player = getInteractingFactionByShip(craftIndex, callingPlayer, AlliancePrivilege.SpendItems)
    if not faction then return end

    if runningJobs[faction.index] ~= nil and player then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "You already have a job running."%_t)
        return
    end

    if finishedJobs[faction.index] ~= nil and player then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "You have refined resources that need to be picked up first."%_t)
        return
    end

    local station = Entity()
    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to refine ores."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to refine ores."%_T
    if not noDockCheck then
        if not CheckShipDocked(player, craft, station, errors) then return end
    end

    local oreAdded, oreAmounts = Refinery.removeGoodsToRefine(craft, oreNameByMaterial, oreAmounts)
    local scrapAdded, scrapAmounts = Refinery.removeGoodsToRefine(craft, scrapNameByMaterial, scrapAmounts)
    if oreAdded == false and scrapAdded == false then return end

    local taxFactor = Refinery.getTaxFactor(Faction().index, faction)
    local netOreAmounts = Refinery.applyTax(oreAmounts, taxFactor)
    local netScrapAmounts = Refinery.applyTax(scrapAmounts, taxFactor)

    local time = Refinery.getRefiningTime(oreAmounts, scrapAmounts)
    runningJobs[faction.index] = {grossOreAmounts = oreAmounts, netOreAmounts = netOreAmounts, grossScrapAmounts = scrapAmounts, netScrapAmounts = netScrapAmounts, remainingTime = time, totalTime = time, tax = taxFactor}

    Refinery.updateClientValues(craftIndex)
end
callable(Refinery, "addJob")

function Refinery.removeGoodsToRefine(craft, goodNames, amounts)
    local amountsOnShip = {}
    local goodByIndex = {}
    for i = 1, NumMaterials() do
        amountsOnShip[i] = 0
    end

    for good, amount in pairs(craft:getCargos()) do
        for material, name in pairs(goodNames) do
            if good.name == name and not good.stolen then
                amountsOnShip[material] = amount
                goodByIndex[material] = good
            end
        end
    end

    local resourceAdded = false
    for material, amount in pairs(amounts) do
        amounts[material] = math.min(amountsOnShip[material], amounts[material])

        if amounts[material] > 0 then
            resourceAdded = true
            craft:removeCargo(goodByIndex[material], amounts[material])
        end
    end

    return resourceAdded, amounts
end

function Refinery.getRefiningTime(oreAmounts, scrapAmounts)
    local time = 0

    for material, amount in pairs(oreAmounts) do
        time = time + amount
    end

    for material, amount in pairs(scrapAmounts) do
        time = time + amount
    end

    if time == 0 then return 0 end

    return math.max(1, round(time / 10000))
end

function Refinery.getTaxFactor(stationFactionIndex, customerFaction)
    if stationFactionIndex == customerFaction.index then return 0 end

    return lerp(customerFaction:getRelations(stationFactionIndex), -25000, 100000, 0.1, 0.01)
end

function Refinery.applyTax(amounts, taxFactor)
    local netOreAmounts = {}

    for material, amount in pairs(amounts) do
        local taxAmount = round(amount * taxFactor)
        netOreAmounts[material] = amount - taxAmount
    end

    return netOreAmounts
end

function Refinery.initUI()
    local res = getResolution()
    local size = vec2(800, 575)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Refine Raw Ores"%_t)

    window.caption = "Refinery"%_t
    window.showCloseButton = true
    window.moveable = true

    local splitter1 = UIVerticalSplitter(Rect(window.size), 10, 10, 0.23)
    local splitter2 = UIVerticalSplitter(splitter1.right, 10, 0, 0.5)
    local splitter3 = UIVerticalSplitter(splitter2.left, 10, 0, 0.5)
    local splitter4 = UIVerticalSplitter(splitter2.right, 10, 0, 0.5)

    local lister1 = UIVerticalLister(splitter1.left, 5, 0)
    local lister2 = UIVerticalLister(splitter3.left, 5, 0)
    local lister3 = UIVerticalLister(splitter3.right, 5, 0)
    local lister4 = UIVerticalLister(splitter4.left, 5, 0)
    local lister5 = UIVerticalLister(splitter4.right, 5, 0)

    lister1:nextRect(20)
    local amountRect = lister2:nextRect(20)
    local amountLabel = window:createLabel(Rect(amountRect.lower + vec2(6, 0), amountRect.upper - vec2(6, 0)), "You"%_t, 14)
    amountLabel:setRightAligned()
    lister3:nextRect(20)
    lister4:nextRect(20)
    local outputLabel = window:createLabel(lister5:nextRect(20), "Output"%_t, 14)
    outputLabel:setTopAligned()

    for i = 1, NumMaterials() do
        local materialRect = lister1:nextRect(30)
        local amountOnShipRect = lister2:nextRect(30)
        window:createFrame(Rect(materialRect.lower, amountOnShipRect.upper))

        local materialLabel = window:createLabel(materialRect.lower + vec2(6, 6), "", 14)
        materialLabel.caption = GetLocalizedString(oreNameByMaterial[i])
        materialLabel.color = Material(i - 1).color

        oreAmountOnShipLabels[i] = window:createLabel(Rect(amountOnShipRect.lower + vec2(6, 0), amountOnShipRect.upper - vec2(6, 0)), "0", 14)
        oreAmountOnShipLabels[i]:setRightAligned()

        oreAmountToRefineBoxes[i] = window:createTextBox(lister3:nextRect(30), "onOreAmountEntered")
        oreAmountToRefineBoxes[i].allowedCharacters = "0123456789"
        oreAmountToRefineBoxes[i].text = "0"

        local refinedAmountRect = lister5:nextRect(30)
        window:createFrame(refinedAmountRect)

        oreOutputAmountLabels[i] = window:createLabel(Rect(refinedAmountRect.lower, refinedAmountRect.upper - vec2(6, 0)), "0", 14)
        oreOutputAmountLabels[i]:setRightAligned()
    end

    lister1:nextRect(5)
    lister2:nextRect(5)
    lister3:nextRect(5)
    lister5:nextRect(5)

    for i = 1, NumMaterials() do
        local materialRect = lister1:nextRect(30)
        local amountOnShipRect = lister2:nextRect(30)
        window:createFrame(Rect(materialRect.lower, amountOnShipRect.upper))

        local materialLabel = window:createLabel(materialRect.lower + vec2(6, 6), "", 14)
        materialLabel.caption = GetLocalizedString(scrapNameByMaterial[i])
        materialLabel.color = Material(i - 1).color

        scrapAmountOnShipLabels[i] = window:createLabel(Rect(amountOnShipRect.lower + vec2(6, 0), amountOnShipRect.upper - vec2(6, 0)), "0", 14)
        scrapAmountOnShipLabels[i]:setRightAligned()

        scrapAmountToRefineBoxes[i] = window:createTextBox(lister3:nextRect(30), "onScrapAmountEntered")
        scrapAmountToRefineBoxes[i].allowedCharacters = "0123456789"
        scrapAmountToRefineBoxes[i].text = "0"

        local refinedAmountRect = lister5:nextRect(30)
        window:createFrame(refinedAmountRect)

        scrapOutputAmountLabels[i] = window:createLabel(Rect(refinedAmountRect.lower, refinedAmountRect.upper - vec2(6, 0)), "0", 14)
        scrapOutputAmountLabels[i]:setRightAligned()
    end

    lister4:nextRect(228)
    refineButton = window:createButton(lister4:nextRect(30), "", "onRefinePressed")
    refineButton.icon = "data/textures/icons/play.png"
    refineButton.tooltip = "Start Refining"%_t

    local progressRect = lister4:nextRect(22)
    window:createFrame(progressRect)
    progressBar = window:createProgressBar(progressRect, ColorRGB(0.25, 0.6, 0.9))
    remainingTimeLabel = window:createLabel(progressRect, "00:00", 14)
    remainingTimeLabel:setCenterAligned()

    local taxRect = Rect(lister1:nextRect(30).lower, lister2:nextRect(30).upper)
    local taxSplitter = UIVerticalSplitter(taxRect, 10, 0, 0.5)
    taxSplitter:setLeftQuadratic()
    local helpIcon = window:createPicture(taxSplitter.left, "data/textures/icons/help.png")
    helpIcon.isIcon = true
    helpIcon.tooltip = "Refine ores and scrap metals to extract their resources.\nExtracted resources can be collected after processing.\nThe refinery keeps a small percentage depending on your relations."%_t

    local playerFaction = Player().craft.factionIndex
    local stationFaction = Faction()
    local taxFactor = Refinery.getTaxFactor(playerFaction, stationFaction)
    taxLabel = window:createLabel(taxSplitter.right, string.format("Refinery Tax: %.1f%%"%_t, round(taxFactor * 100)), 14)
    taxLabel:setLeftAligned()

    addAllButton = window:createButton(lister3:nextRect(30), "All"%_t, "onAddAllPressed")
    takeButton = window:createButton(lister5:nextRect(30), "Take"%_t, "onTakeAllPressed")

    -- gets activated when the current values are received from the server
    Refinery.setInputAmountsUIEnabled(false)
    Refinery.setTakeResourcesUIEnabled(false)
end

function Refinery.onShowWindow(optionIndex)
    Refinery.updateClientValues()
end

function Refinery.onJobFinished(factionIndex)
    if Player().craft.factionIndex ~= factionIndex then return end

    if window and window.visible then
        Refinery.updateClientValues()
    end
end

function Refinery.updateRemainingTimeLabel(time, totalTimeIn)
    local time = math.max(0, time)
    totalTime = totalTimeIn

    -- calculate the total time if it isn't set -> preview
    if totalTime == nil then
        local ores = {}
        local scraps = {}

        for i = 1, NumMaterials() do
            ores[i] = tonumber(oreAmountToRefineBoxes[i].text) or 0
            scraps[i] = tonumber(scrapAmountToRefineBoxes[i].text) or 0
        end

        totalTime = Refinery.getRefiningTime(ores, scraps)
        time = totalTime
    end

    progressBar.progress = 1 - time / totalTime
    timeLeft = math.ceil(time)

    if not remainingTimeLabel then return end

    local timeString = ""

    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft - minutes * 60

    if minutes < 10 then timeString = timeString .. "0" end
    timeString = timeString .. minutes

    timeString = timeString .. ":"

    if seconds < 10 then timeString = timeString .. "0" end
    timeString = timeString .. seconds

    remainingTimeLabel.caption = timeString
end

if onClient() then
function Refinery.updateClientValues(job, inputActive, takingActive)
    if job == nil then
        -- request data from the server
        invokeServerFunction("updateClientValues", Player().craftIndex)

    else
        -- receive data from the server
        for i, amount in pairs(job.grossOreAmounts or {}) do
            oreAmountToRefineBoxes[i].text = amount
        end
        for i, amount in pairs(job.netOreAmounts or {}) do
            oreOutputAmountLabels[i].caption = amount
        end

        for i, amount in pairs(job.grossScrapAmounts or {}) do
            scrapAmountToRefineBoxes[i].text = amount
        end
        for i, amount in pairs(job.netScrapAmounts or {}) do
            scrapOutputAmountLabels[i].caption = amount
        end

        Refinery.updateRemainingTimeLabel(job.remainingTime or 0, job.totalTime)

        Refinery.setInputAmountsUIEnabled(inputActive)
        Refinery.setTakeResourcesUIEnabled(takingActive)

        -- update amount of ores on the ship
        Refinery.updateAmountOnShipLabels(oreNameByMaterial, oreAmountOnShipLabels)

        -- update amount of scrap on the ship
        Refinery.updateAmountOnShipLabels(scrapNameByMaterial, scrapAmountOnShipLabels)

        if job.tax then
            taxLabel.caption = string.format("Refinery Tax: %.1f%%"%_t, round(job.tax * 100))
        else
            local playerFaction = Player().craft.factionIndex
            local stationFaction = Faction()
            local taxFactor = Refinery.getTaxFactor(playerFaction, stationFaction)
            taxLabel.caption = string.format("Refinery Tax: %.1f%%"%_t, round(taxFactor * 100))
        end
    end
end
end

if onServer() then
function Refinery.updateClientValues(craftIndex)
    -- send data from server to client
    local faction, craft, player = getInteractingFactionByShip(craftIndex, callingPlayer)

    if not player then return end

    local runningJob = runningJobs[faction.index]
    if runningJob then
        inputActive = false
        takingActive = false
        invokeClientFunction(player, "updateClientValues", runningJob, inputActive, takingActive)
        return
    end

    local finishedJob = finishedJobs[faction.index]
    if finishedJob then
        inputActive = false
        takingActive = true
        invokeClientFunction(player, "updateClientValues", finishedJob, inputActive, takingActive)
        return
    end

    inputActive = true
    takingActive = false
    invokeClientFunction(player, "updateClientValues", {}, inputActive, takingActive)
end
callable(Refinery, "updateClientValues")
end

function Refinery.updateAmountOnShipLabels(goodsTable, labels)
    local amountOnShip = {}
    for material = 1, NumMaterials() do
        amountOnShip[material] = 0
    end

    local craft = Player().craft
    for good, amount in pairs(craft:getCargos()) do
        for material, name in pairs(goodsTable) do
            if good.name == name and not good.stolen then
                amountOnShip[material] = amount
            end
        end
    end

    for material = 1, NumMaterials() do
        labels[material].caption = amountOnShip[material]
    end
end

function Refinery.onAmountEntered(box, boxes, onShipLabels, outputLabels)
    local material
    for i, amountBox in pairs(boxes) do
        if amountBox.index == box.index then
            material = i
            break
        end
    end

    if not material then
        return
    end

    local enteredNumber = tonumber(box.text) or 0
    local newAmount = math.min(tonumber(onShipLabels[material].caption) or 0, enteredNumber)
    box.text = newAmount

    local playerFaction = Player().craft.factionIndex
    local stationFaction = Faction()
    local taxFactor = Refinery.getTaxFactor(playerFaction, stationFaction)

    local netAmount = newAmount - round(newAmount * taxFactor)
    outputLabels[material].caption = netAmount

    Refinery.updateRemainingTimeLabel(0, nil)
end

function Refinery.onOreAmountEntered(box)
    Refinery.onAmountEntered(box, oreAmountToRefineBoxes, oreAmountOnShipLabels, oreOutputAmountLabels)
end

function Refinery.onScrapAmountEntered(box)
    Refinery.onAmountEntered(box, scrapAmountToRefineBoxes, scrapAmountOnShipLabels, scrapOutputAmountLabels)
end

function Refinery.onRefinePressed(button)
    local oreAmounts = {}
    local scrapAmounts = {}

    for i, amountBox in pairs(oreAmountToRefineBoxes) do
        oreAmounts[i] = tonumber(amountBox.text) or 0
    end
    for i, amountBox in pairs(scrapAmountToRefineBoxes) do
        scrapAmounts[i] = tonumber(amountBox.text) or 0
    end

    invokeServerFunction("addJob", Player().craftIndex, oreAmounts, scrapAmounts)
end

function Refinery.onAddAllPressed()
    Refinery.updateAmountOnShipLabels(oreNameByMaterial, oreAmountOnShipLabels)
    Refinery.updateAmountOnShipLabels(scrapNameByMaterial, scrapAmountOnShipLabels)

    local playerFaction = Player().craft.factionIndex
    local stationFaction = Faction()
    local taxFactor = Refinery.getTaxFactor(playerFaction, stationFaction)

    for i = 1, NumMaterials() do
        oreAmountToRefineBoxes[i].text = oreAmountOnShipLabels[i].caption
        scrapAmountToRefineBoxes[i].text = scrapAmountOnShipLabels[i].caption

        -- update output labels
        local newAmount = tonumber(oreAmountOnShipLabels[i].caption) or 0
        local netAmount = newAmount - round(newAmount * taxFactor)
        oreOutputAmountLabels[i].caption = netAmount

        newAmount = tonumber(scrapAmountOnShipLabels[i].caption) or 0
        netAmount = newAmount - round(newAmount * taxFactor)
        scrapOutputAmountLabels[i].caption = netAmount
    end

    Refinery.updateRemainingTimeLabel(0, nil)
end

function Refinery.onTakeAllPressed(craftIndex)
    if onClient() then
        invokeServerFunction("onTakeAllPressed", Player().craftIndex)

        for i = 1, NumMaterials() do
            oreAmountToRefineBoxes[i].text = 0
            scrapAmountToRefineBoxes[i].text = 0

            oreOutputAmountLabels[i].caption = 0
            scrapOutputAmountLabels[i].caption = 0
        end

        return
    end

    local faction, craft, player = getInteractingFactionByShip(craftIndex, callingPlayer, AlliancePrivilege.AddResources)
    if not faction then return end

    local finished = finishedJobs[faction.index]
    if finished == nil then
        if player then
            player:sendChatMessage(Entity(), ChatMessageType.Error, "There is nothing to take."%_t)
        end

        return
    end

    for i = 1, NumMaterials() do
        local amount = finished.netOreAmounts[i] or 0
        amount = amount + finished.netScrapAmounts[i] or 0
        if amount > 0 then
            faction:receiveResource(Format("Received %1% %2% from refinery."%_t, amount, Material(i - 1).name), Material(i - 1), amount)
        end
    end

    finishedJobs[faction.index] = nil

    Refinery.updateClientValues(craftIndex)
end
callable(Refinery, "onTakeAllPressed")

function Refinery.setInputAmountsUIEnabled(bool)
    addAllButton.active = bool
    refineButton.active = bool

    for i = 1, NumMaterials() do
        oreAmountToRefineBoxes[i].editable = bool
        scrapAmountToRefineBoxes[i].editable = bool
    end
end

function Refinery.setTakeResourcesUIEnabled(bool)
    takeButton.active = bool

    for i = 1, NumMaterials() do
        oreOutputAmountLabels[i].active = bool
        scrapOutputAmountLabels[i].active = bool
    end
end

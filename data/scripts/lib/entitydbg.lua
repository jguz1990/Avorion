
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("utility")
require ("faction")
require ("productions")
require ("stationextensions")
require ("callable")
local SectorSpecifics = require ("sectorspecifics")
local SectorGenerator = require ("SectorGenerator")
local ShipUtility = require ("shiputility")
local TurretGenerator = require ("turretgenerator")
local UpgradeGenerator = require ("upgradegenerator")
local PirateGenerator = require ("pirategenerator")
local Rewards = require ("rewards")
local Scientist = require ("story/scientist")
local The4 = require ("story/the4")
local Smuggler = require ("story/smuggler")
local Placer = require ("placer")
local Xsotan = require ("story/xsotan")
local AdventurerGuide = require("story/adventurerguide")
local OperationExodus = require("story/operationexodus")
local AsyncPirateGenerator = require("asyncpirategenerator")
local AsyncShipGenerator = require("asyncshipgenerator")
local FighterGenerator = require("fightergenerator")
local TorpedoGenerator = require("torpedogenerator")
local Scientist = require ("story/scientist")
require("weapontype")

local window
local scriptsWindow
local scriptList
local scripts
local addScriptButton
local removeScriptButton
local templateButtons
local factoryButtons

local WeaponTypes =
{
    {type = WeaponType.ChainGun, name = "Chain Guns"},
    {type = WeaponType.PointDefenseChainGun, name = "PDCs"},
    {type = WeaponType.PointDefenseLaser, name = "PDLs"},
    {type = WeaponType.Laser, name = "Lasers"},
    {type = WeaponType.MiningLaser, name = "Mining Lasers"},
    {type = WeaponType.RawMiningLaser, name = "Raw Mining Lasers"},
    {type = WeaponType.SalvagingLaser, name = "Salvage Lasers"},
    {type = WeaponType.RawSalvagingLaser, name = "Raw Salvage Lasers"},
    {type = WeaponType.PlasmaGun, name = "Plasma Guns"},
    {type = WeaponType.RocketLauncher, name = "Rocket Launchers"},
    {type = WeaponType.Cannon, name = "Cannons"},
    {type = WeaponType.RailGun, name = "Railguns"},
    {type = WeaponType.RepairBeam, name = "Repair Beams"},
    {type = WeaponType.Bolter, name = "Bolters"},
    {type = WeaponType.LightningGun, name = "Lightning Guns"},
    {type = WeaponType.TeslaGun, name = "Tesla Guns"},
    {type = WeaponType.ForceGun, name = "Force Guns"},
    {type = WeaponType.PulseCannon, name = "Pulse Cannons"},
    {type = WeaponType.AntiFighter, name = "Anti-Fighter Cannons"},
}

local numButtons = 0
function ButtonRect(w, h, p)

    local width = w or 280
    local height = h or 35
    local padding = p or 10

    local space = math.floor((window.size.y - 60) / (height + padding))

    local row = math.floor(numButtons % space)
    local col = math.floor(numButtons / space)

    local lower = vec2((width + padding) * col, (height + padding) * row)
    local upper = lower + vec2(width, height)

    numButtons = numButtons + 1

    return Rect(lower, upper)
end

function interactionPossible(player)
    return true, ""
end

function initialize()

end

function onShowWindow()
    scriptsWindow:hide()
    valuesWindow:hide()
end

function onCloseWindow()
    scriptsWindow:hide()
    valuesWindow:hide()
end

function initUI()

    local res = getResolution()
    local size = vec2(1200, 650)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Debug"
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "~dev");

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    local tab = tabbedWindow:createTab("Entity", "data/textures/icons/ship.png", "Ship Commands")
    numButtons = 0
    tab:createButton(ButtonRect(), "GoTo", "onGoToButtonPressed")
    tab:createButton(ButtonRect(), "Entity Scripts", "onEntityScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Entity Values", "onEntityValuesButtonPressed")
    tab:createButton(ButtonRect(), "Faction Values", "onFactionValuesButtonPressed")
    tab:createButton(ButtonRect(), "Spawn Ship", "onCreateShipsButtonPressed")
    tab:createButton(ButtonRect(), "Spawn Ship Copy", "onCreateShipCopyButtonPressed")
    tab:createButton(ButtonRect(), "Spawn Beacon", "onCreateBeaconButtonPressed")
    tab:createButton(ButtonRect(), "Fly", "onFlyButtonPressed")
    tab:createButton(ButtonRect(), "Own", "onOwnButtonPressed")
    tab:createButton(ButtonRect(), "Own Alliance", "onOwnAllianceButtonPressed")
    tab:createButton(ButtonRect(), "Add Crew", "onAddCrewButtonPressed")
    tab:createButton(ButtonRect(), "Add Cargo", "onAddCargoButtonPressed")
    tab:createButton(ButtonRect(), "Add Armed Fighters", "onAddArmedFightersButtonPressed")
    tab:createButton(ButtonRect(), "Add Mining Fighters", "onAddMiningFightersButtonPressed")
    tab:createButton(ButtonRect(), "Add Raw Mining Fighters", "onAddRawMiningFightersButtonPressed")
    tab:createButton(ButtonRect(), "Add Salvaging Fighters", "onAddSalvagingFightersButtonPressed")
    tab:createButton(ButtonRect(), "Add Cargo Shuttles", "onAddCargoShuttlesButtonPressed")
    tab:createButton(ButtonRect(), "Add Torpedoes", "onAddTorpedoesButtonPressed")
    tab:createButton(ButtonRect(), "Clear Cargo", "onClearCargoButtonPressed")
    tab:createButton(ButtonRect(), "Clear Crew", "onClearCrewButtonPressed")
    tab:createButton(ButtonRect(), "Clear Hangar", "onClearHangarButtonPressed")
    tab:createButton(ButtonRect(), "Clear Torpedoes", "onClearTorpedoesButtonPressed")
    tab:createButton(ButtonRect(), "Start Fighter", "onStartFighterButtonPressed")
    tab:createButton(ButtonRect(), "Destroy", "onDestroyButtonPressed")
    tab:createButton(ButtonRect(), "Delete", "onDeleteButtonPressed")
    tab:createButton(ButtonRect(), "Toggle Invincible", "onInvincibleButtonPressed")
    tab:createButton(ButtonRect(), "Set Gate Plan", "onSetGatePlanPressed")
    tab:createButton(ButtonRect(), "Make Freighter", "onSetFreighterPlanPressed")
    tab:createButton(ButtonRect(), "Like", "onLikePressed")
    tab:createButton(ButtonRect(), "Dislike", "onDislikePressed")
    tab:createButton(ButtonRect(), "Damage", "onDamagePressed")
    tab:createButton(ButtonRect(), "Title", "onTitlePressed")
    tab:createButton(ButtonRect(), "Transform Turrets", "onTransformTurretsPressed")
    tab:createButton(ButtonRect(), "Faction Index", "onFactionIndexPressed")

    local tab = tabbedWindow:createTab("", "data/textures/icons/inventory.png", "Player Commands")
    numButtons = 0
    tab:createButton(ButtonRect(), "Player Scripts", "onPlayerScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Player Values", "onPlayerValuesButtonPressed")
    tab:createButton(ButtonRect(), "Disable Events", "onDisableEventsButtonPressed")
    tab:createButton(ButtonRect(), "Clear Inventory", "onClearInventoryButtonPressed")
    tab:createButton(ButtonRect(), "Reset Money", "onResetMoneyButtonPressed")
    tab:createButton(ButtonRect(), "Guns Guns Guns", "onGunsButtonPressed")
    tab:createButton(ButtonRect(), "CoAx Guns Guns Guns", "onCoaxialGunsButtonPressed")
    tab:createButton(ButtonRect(), "Gimme Systems", "onSystemsButtonPressed")
    tab:createButton(ButtonRect(), "Energy Suppressor", "onEnergySuppressorButtonPressed")
    tab:createButton(ButtonRect(), "Quest Reward", "onQuestRewardButtonPressed")


    numButtons = 26
    for _, wp in pairs(WeaponTypes) do
        local button = tab:createButton(ButtonRect(), wp.name, "onGiveWeaponsButtonPressed")
        wp.buttonIndex = button.index
    end



    local tab = tabbedWindow:createTab("Upgrades", "data/textures/icons/circuitry.png", "Upgrades")
    numButtons = 0

    tab:createButton(ButtonRect(), "Clear Inventory", "onClearInventoryButtonPressed")
    tab:createButton(ButtonRect(), "Mission Upgrades", "onKeysButtonPressed")

    systemButtons = {}
    for _, script in pairs(UpgradeGenerator.scripts) do
        local name = script:split("/")[4]:split(".")[1]
        local button = tab:createButton(ButtonRect(), name, "onSystemUpgradeButtonPressed")
        table.insert(systemButtons, {button = button, script = script});
    end

    local tab = tabbedWindow:createTab("Sector", "data/textures/icons/sector.png", "Sector Commands")
    numButtons = 0
    tab:createButton(ButtonRect(), "Sector Scripts", "onSectorScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Sector Values", "onSectorValuesButtonPressed")
    tab:createButton(ButtonRect(), "Server Values", "onServerValuesButtonPressed")
    tab:createButton(ButtonRect(), "Clear Sector", "onClearButtonPressed")
    tab:createButton(ButtonRect(), "Clear Fighters", "onClearFightersButtonPressed")
    tab:createButton(ButtonRect(), "Clear Torpedos", "onClearTorpedosButtonPressed")
    tab:createButton(ButtonRect(), "Infect Asteroids", "onInfectAsteroidsButtonPressed")
    tab:createButton(ButtonRect(), "Align", "onAlignButtonPressed")
    tab:createButton(ButtonRect(), "Condense Entities", "onCondenseSectorButtonPressed")
    tab:createButton(ButtonRect(), "Resolve Intersections", "onResolveIntersectionsButtonPressed")
    tab:createButton(ButtonRect(), "Respawn Asteroids", "onRespawnAsteroidsButtonPressed")
    tab:createButton(ButtonRect(), "Touch all Objects", "onTouchAllObjectsButtonPressed")
    tab:createButton(ButtonRect(), "Touch all Objects [Client]", "onTouchAllObjectsOnClientButtonPressed")

    local tab = tabbedWindow:createTab("Spawn Stations", "data/textures/icons/factory-arm.png", "Spawn Station")
    numButtons = 0
    tab:createButton(ButtonRect(), "Resistance Outpost", "onCreateResistanceOutpostPressed")
    tab:createButton(ButtonRect(), "Smuggler's Market", "onCreateSmugglersMarketPressed")
    tab:createButton(ButtonRect(), "Headquarters", "onCreateHeadQuartersPressed")
    tab:createButton(ButtonRect(), "Research Station", "onCreateResearchStationPressed")
    tab:createButton(ButtonRect(), "Consumer", "onCreateConsumerButtonPressed")
    tab:createButton(ButtonRect(), "Shipyard", "onCreateShipyardButtonPressed")
    tab:createButton(ButtonRect(), "Repair Dock", "onCreateRepairDockButtonPressed")
    tab:createButton(ButtonRect(), "Equipment Dock", "onCreateEquipmentDockButtonPressed")
    tab:createButton(ButtonRect(), "Turret Merchant", "onCreateTurretMerchantButtonPressed")
    tab:createButton(ButtonRect(), "Turret Factory", "onCreateTurretFactoryButtonPressed")
    tab:createButton(ButtonRect(), "Fighter Merchant", "onCreateFighterMerchantButtonPressed")
    tab:createButton(ButtonRect(), "Fighter Factory", "onCreateFighterFactoryButtonPressed")
    tab:createButton(ButtonRect(), "Torpedo Merchant", "onCreateTorpedoMerchantButtonPressed")
    tab:createButton(ButtonRect(), "Trading Post", "onCreateTradingPostButtonPressed")
    tab:createButton(ButtonRect(), "Planetary Trading Post", "onCreatePlanetaryTradingPostButtonPressed")
    tab:createButton(ButtonRect(), "Resource Depot", "onCreateResourceDepotButtonPressed")
    tab:createButton(ButtonRect(), "Scrapyard", "onCreateScrapyardButtonPressed")
    tab:createButton(ButtonRect(), "Military Outpost", "onCreateMilitaryOutpostPressed")

    local tab = tabbedWindow:createTab("Spawn", "data/textures/icons/slow-blob.png", "Spawn")
    numButtons = 0
    tab:createButton(ButtonRect(), "Infected Asteroid", "onCreateInfectedAsteroidPressed")
    tab:createButton(ButtonRect(), "Big Infected Asteroid", "onCreateBigInfectedAsteroidPressed")
    tab:createButton(ButtonRect(), "Claimable Wreckage", "onCreateClaimableWreckagePressed")
    tab:createButton(ButtonRect(), "Claimable Asteroid", "onCreateOwnableAsteroidPressed")
    tab:createButton(ButtonRect(), "Adventurer", "onCreateAdventurerPressed")
    tab:createButton(ButtonRect(), "Travelling Merchant", "onCreateMerchantPressed")
    tab:createButton(ButtonRect(), "Wreckage", "onCreateWreckagePressed")
    tab:createButton(ButtonRect(), "Big Asteroid", "onCreateBigAsteroidButtonPressed")
    tab:createButton(ButtonRect(), "Asteroid Field", "onCreateAsteroidFieldButtonPressed")
    tab:createButton(ButtonRect(), "Empty Asteroid Field", "onCreateEmptyAsteroidFieldButtonPressed")
    tab:createButton(ButtonRect(), "Rich Asteroid Field", "onCreateRichAsteroidFieldButtonPressed")
    tab:createButton(ButtonRect(), "Container Field", "onCreateContainerFieldButtonPressed")
    tab:createButton(ButtonRect(), "Resource Asteroid", "onCreateResourceAsteroidButtonPressed")
    tab:createButton(ButtonRect(), "Pirate", "onCreatePirateButtonPressed")
    tab:createButton(ButtonRect(), "Military Ship", "onSpawnMilitaryShipButtonPressed")
    tab:createButton(ButtonRect(), "Carrier", "onSpawnCarrierButtonPressed")
    tab:createButton(ButtonRect(), "Flagship", "onSpawnFlagshipButtonPressed")
    tab:createButton(ButtonRect(), "Persecutor", "onSpawnPersecutorButtonPressed")
    tab:createButton(ButtonRect(), "Blocker", "onSpawnBlockerButtonPressed")
    tab:createButton(ButtonRect(), "Disruptor", "onSpawnDisruptorButtonPressed")
    tab:createButton(ButtonRect(), "CIWS", "onSpawnCIWSButtonPressed")
    tab:createButton(ButtonRect(), "Torpedoboat", "onSpawnTorpedoBoatButtonPressed")
    tab:createButton(ButtonRect(), "Trader", "onSpawnTraderButtonPressed")
    tab:createButton(ButtonRect(), "Freighter", "onSpawnFreighterButtonPressed")
    tab:createButton(ButtonRect(), "Miner", "onSpawnMinerButtonPressed")
    tab:createButton(ButtonRect(), "Xsotan Squad", "onSpawnXsotanSquadButtonPressed")
    tab:createButton(ButtonRect(), "Xsotan Carrier", "onSpawnXsotanCarrierButtonPressed")
    tab:createButton(ButtonRect(), "Defenders", "onSpawnDefendersButtonPressed")
    tab:createButton(ButtonRect(), "Battle", "onSpawnBattleButtonPressed")
    tab:createButton(ButtonRect(), "Deferred Battle", "onSpawnDeferredBattleButtonPressed")
    tab:createButton(ButtonRect(), "Fleet", "onSpawnFleetButtonPressed")
    tab:createButton(ButtonRect(), "Raiders", "onPersecutorsButtonPressed")
    tab:createButton(ButtonRect(), "Crew Transport", "onCrewTransportButtonPressed")


    local tab = tabbedWindow:createTab("Factory Spawn", "data/textures/icons/cog.png", "Spawn Factory")
    numButtons = 0

    factoryButtons = {}
    for i, production in pairs(productions) do
        local button = tab:createButton(ButtonRect(190, 20, 3), getTranslatedFactoryName(production, ""), "onGenerateFactoryButtonPressed")
        table.insert(factoryButtons, {button = button, production = production});
        button.maxTextSize = 10
    end

    local tab = tabbedWindow:createTab("Generate Sectors", "data/textures/icons/gears.png", "Generator Scripts")
    numButtons = 0

    local specs = SectorSpecifics(0, 0, Seed());
    specs:addTemplates()

    templateButtons = {}
    for i, template in pairs(specs.templates) do
        local parts = template.path:split("/")
        local button = tab:createButton(ButtonRect(), parts[2], "onGenerateTemplateButtonPressed")
        table.insert(templateButtons, {button = button, template = template});
    end

    local tab = tabbedWindow:createTab("Music", "data/textures/icons/g-clef.png", "Music")
    numButtons = 0

    tab:createButton(ButtonRect(), "Stop Music", "onCancelMusicButtonPressed")

    local specs = SectorSpecifics(0, 0, Seed());
    specs:addTemplates()

    musicButtons = {}
    for i, template in pairs(specs.templates) do
        local parts = template.path:split("/")
        local button = tab:createButton(ButtonRect(), parts[2], "onSectorMusicButtonPressed")
        table.insert(musicButtons, {button = button, template = template});
    end

    local tab = tabbedWindow:createTab("Missions", "data/textures/icons/treasure-map.png", "Missions")
    numButtons = 0
    tab:createButton(ButtonRect(), "Distress Call", "onDistressCallButtonPressed")
    tab:createButton(ButtonRect(), "Fake Distress Call", "onFakeDistressCallButtonPressed")
    tab:createButton(ButtonRect(), "Pirate Attack", "onPirateAttackButtonPressed")
    tab:createButton(ButtonRect(), "Trader Attacked by Pirates", "onTraderAttackedByPiratesButtonPressed")
    tab:createButton(ButtonRect(), "Xsotan Attack", "onAlienAttackButtonPressed")
    tab:createButton(ButtonRect(), "Headhunter Attack", "onHeadhunterAttackButtonPressed")
    tab:createButton(ButtonRect(), "Search and Rescue Call", "onSearchAndRescueButtonPressed")
    tab:createButton(ButtonRect(), "Progress Brakers", "onProgressBrakersButtonPressed")
    tab:createButton(ButtonRect(), "Smuggler Retaliation", "onSmugglerRetaliationButtonPressed")
    tab:createButton(ButtonRect(), "Exodus Beacon", "onExodusBeaconButtonPressed")
    tab:createButton(ButtonRect(), "Exodus Corner Points", "onExodusPointsButtonPressed")
    tab:createButton(ButtonRect(), "Exodus Final Beacon", "onExodusFinalBeaconButtonPressed")
    tab:createButton(ButtonRect(), "Research Satellite", "onResearchSatelliteButtonPressed")
    tab:createButton(ButtonRect(), "Boss: Swoks", "onSpawnSwoksButtonPressed")
    tab:createButton(ButtonRect(), "Boss: The AI", "onSpawnTheAIButtonPressed")
    tab:createButton(ButtonRect(), "Boss: Smuggler", "onSpawnSmugglerButtonPressed")
    tab:createButton(ButtonRect(), "Boss: Scientist", "onSpawnScientistButtonPressed")
    tab:createButton(ButtonRect(), "Boss: The 4", "onSpawnThe4ButtonPressed")
    tab:createButton(ButtonRect(), "Boss: Guardian", "onSpawnGuardianButtonPressed")




    local tab = tabbedWindow:createTab("Icons", "data/textures/icons/crate.png", "Cargo Commands")
    numButtons = 0
    local sortedGoods = {}
    for name, good in pairs(goods) do
        table.insert(sortedGoods, good)
    end

    stolenCargoCheckBox = tab:createCheckBox(Rect(vec2(150, 25)), "Stolen", "onStolenChecked")
    local organizer = UIOrganizer(Rect(tabbedWindow.size))

    organizer:placeElementTopRight(stolenCargoCheckBox)

    function goodsByName(a, b) return a.name < b.name end
    table.sort(sortedGoods, goodsByName)

    for _, good in pairs(sortedGoods) do
        local rect = ButtonRect(40, 40)

        rect.upper = rect.lower + vec2(rect.size.y, rect.size.y)

        local button = tab:createButton(rect, "", "onGoodsButtonPressed")
        button.icon = good.icon
        button.tooltip = good.name



--        local p = vec2(rect.upper.x, rect.lower.y + 5)

--        local label = tab:createLabel(p, name, 15)

    end



    local tab = tabbedWindow:createTab("System", "data/textures/icons/treasure-map.png", "System")
    numButtons = 0
    tab:createButton(ButtonRect(), "Crash Script", "onCrashButtonPressed")
    tab:createButton(ButtonRect(), "Client Log", "onPrintClientLogButtonPressed")
    tab:createButton(ButtonRect(), "Server Log", "onPrintServerLogButtonPressed")


    local size = vec2(800, 500)
    scriptsWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    scriptsWindow.visible = false
    scriptsWindow.caption = "Scripts"
    scriptsWindow.showCloseButton = 1
    scriptsWindow.moveable = 1
    scriptsWindow.closeableWithEscape = 1

    local hsplit = UIHorizontalSplitter(Rect(vec2(0, 0), size), 10, 10, 0.5)
    hsplit.bottomSize = 80

    scriptList = scriptsWindow:createListBox(hsplit.top)

    local hsplit = UIHorizontalSplitter(hsplit.bottom, 10, 0, 0.5)
    hsplit.bottomSize = 35

    scriptTextBox = scriptsWindow:createTextBox(hsplit.top, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)

    addScriptButton = scriptsWindow:createButton(vsplit.left, "Add", "")
    removeScriptButton = scriptsWindow:createButton(vsplit.right, "Remove", "")


    -- values window
    local size = vec2(1000, 700)
    valuesWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    valuesWindow.visible = false
    valuesWindow.caption = "Values"
    valuesWindow.showCloseButton = 1
    valuesWindow.moveable = 1
    valuesWindow.closeableWithEscape = 1

    valuesLines = {}

    local horizontal = 2
    local vertical = 19

    local vsplit = UIVerticalMultiSplitter(Rect(size), 5, 0, horizontal - 1)


    local previous = nil
    for x = 1, horizontal do
        local hsplit = UIHorizontalMultiSplitter(vsplit:partition(x - 1), 5, 10, vertical - 1)

        for y = 1, vertical do
            local vsplit = UIVerticalSplitter(hsplit:partition(y - 1), 5, 0, 0.5)

            local vsplit2 = UIVerticalSplitter(vsplit.right, 5, 0, 0.5)
            local vsplit3 = UIVerticalSplitter(vsplit2.right, 5, 0, 0.5)


            local key = valuesWindow:createTextBox(vsplit.left, "")
            local value = valuesWindow:createTextBox(vsplit2.left, "")

            local set = valuesWindow:createButton(vsplit3.left, "set", "onSetValuePressed")
            local delete = valuesWindow:createButton(vsplit3.right, "X", "onDeleteValuePressed")

            key.tabTarget = value

            if previous then previous.tabTarget = key end
            previous = value

            table.insert(valuesLines, {key = key, value = value, set = set, delete = delete})
        end
    end

end

--[[
function updateClient()
    if not docks then
        syncDocks()
    else
        for _, dock in pairs(docks) do
            dock = Entity().position:transformCoord(dock)
            drawDebugSphere(Sphere(dock, 1), ColorRGB(1, 1, 0))
        end
    end

    local ownDocks = {Entity():getDockingPositions()}
    for _, dock in pairs(ownDocks) do
        dock = Entity().position:transformCoord(dock)
        --drawDebugSphere(Sphere(dock, 3), ColorRGB(1, 0, 0))
    end

end
--]]

function syncDocks(docks_in)
    if onClient() then
        if docks_in then
            docks = docks_in
        else
            invokeServerFunction("syncDocks")
        end
    else
        local docks = {Entity():getDockingPositions()}
        invokeClientFunction(Player(callingPlayer), "syncDocks", docks)
    end
end

function onGenerateFactoryButtonPressed(arg)
    if onClient() then
        local button = arg
        for _, p in pairs(factoryButtons) do
            if button.index == p.button.index then
                invokeServerFunction("onGenerateFactoryButtonPressed", p.production)
                break
            end
        end

        return
    end

    local production = arg
    print (production.index)
    print (production.results[1].name)

    if Entity().isStation then
        Entity():removeScript("merchants/factory.lua")
        Entity():addScript("data/scripts/entity/merchants/factory.lua", production.results[1].name)
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", production.results[1].name)

    Placer.resolveIntersections()
end

local function make_set(array)
    array = array or {}
    local set = {}

    for _, element in pairs(array) do
        set[element] = true
    end

    return set
end

function onCancelMusicButtonPressed(arg)
    Music():setAmbientTrackLists({}, {})
end

function onSectorMusicButtonPressed(arg)
    local button = arg
    for _, p in pairs(musicButtons) do
        if button.index == p.button.index then

            local good, neutral, bad = p.template.musicTracks()

            local chosen = good or {}
            local primary = make_set(chosen.primary)
            local secondary = make_set(chosen.secondary)

            -- actually set the tracks for playing
            local ptracks = {}
            local stracks = {}

            for id, _ in pairs(primary) do
                table.insert(ptracks, Tracks[id].path)
            end

            for id, _ in pairs(secondary) do
                table.insert(stracks, Tracks[id].path)
            end

            Music():setAmbientTrackLists(ptracks, stracks)
            Music():setAmbientTrackLists(ptracks, {})
            break
        end
    end
end

function onGenerateTemplateButtonPressed(arg)

    if onClient() then
        local button = arg
        for _, p in pairs(templateButtons) do
            if button.index == p.button.index then
                invokeServerFunction("onGenerateTemplateButtonPressed", p.template.path)
                break
            end
        end

        return
    end

    print("generating sector: " .. arg)

    -- clear sector except for player's entities
    local sector = Sector()
    for _, entity in pairs({sector:getEntities()}) do

        if entity.factionIndex == nil or entity.factionIndex ~= Entity().factionIndex then
            sector:deleteEntity(entity)
        end
    end

    sector:collectGarbage()

    local specs = SectorSpecifics(0, 0, Seed());
    specs:addTemplates()

    local path = arg
    for _, template in pairs(specs.templates) do
        if path == template.path then
            template.generate(Faction(), sector.seed, sector:getCoordinates())
            return
        end
    end

end

function onSmugglerRetaliationButtonPressed()

    if onClient() then
        invokeServerFunction("onSmugglerRetaliationButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:setValue("smuggler_letter", nil)

    player:removeScript("story/smugglerretaliation.lua")
    player:removeScript("story/smugglerdelivery.lua")
    player:removeScript("story/smugglerletter.lua")

    player:addScriptOnce("story/smugglerletter.lua")

end

function onExodusBeaconButtonPressed()

    if onClient() then
        invokeServerFunction("onExodusBeaconButtonPressed")
        return
    end

    OperationExodus.generateBeacon(SectorGenerator(Sector():getCoordinates()))
end

function onExodusPointsButtonPressed()
    if onClient() then
        invokeServerFunction("onExodusPointsButtonPressed")
        return
    end

    local str = "Points: "
    for _, point in pairs(OperationExodus.getCornerPoints()) do
        str = str .. "\\s(${x}, ${y})  " % point
    end

    Player(callingPlayer):sendChatMessage("", 0, str)
end

function onExodusFinalBeaconButtonPressed()
    if onClient() then
        invokeServerFunction("onExodusFinalBeaconButtonPressed")
        return
    end

    local beacon = SectorGenerator(Sector():getCoordinates()):createBeacon(nil, nil, "")
    beacon:removeScript("data/scripts/entity/beacon.lua")
    beacon:addScript("story/exodustalkbeacon.lua")
end

function onResearchSatelliteButtonPressed()
    if onClient() then
        invokeServerFunction("onResearchSatelliteButtonPressed")
        return
    end

    -- if not, create a new one
    Scientist.createSatellite(Matrix())
end

function onDistressCallButtonPressed()
    if onClient() then
        invokeServerFunction("onDistressCallButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:addScript("convoidistresssignal.lua", true)
end

function onFakeDistressCallButtonPressed()
    if onClient() then
        invokeServerFunction("onFakeDistressCallButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:addScript("fakedistresssignal.lua", true)
end

function onPirateAttackButtonPressed()
    if onClient() then
        invokeServerFunction("onPirateAttackButtonPressed")
        return
    end

    Sector():addScript("pirateattack.lua")
end

function onTraderAttackedByPiratesButtonPressed()
    if onClient() then
        invokeServerFunction("onTraderAttackedByPiratesButtonPressed")
        return
    end

    Sector():addScript("traderattackedbypirates.lua")
end

function onAlienAttackButtonPressed()
    if onClient() then
        invokeServerFunction("onAlienAttackButtonPressed")
        return
    end

    Player():addScript("alienattack.lua")
end

function onHeadhunterAttackButtonPressed()
    if onClient() then
        invokeServerFunction("onHeadhunterAttackButtonPressed")
        return
    end

    Player():addScriptOnce("headhunter.lua")

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():createRandomFaction(x, y)

    Player():invokeFunction("headhunter.lua", "createEnemies", faction)

end

function onProgressBrakersButtonPressed()
    if onClient() then
        invokeServerFunction("onProgressBrakersButtonPressed")
        return
    end

    Sector():addScriptOnce("spawnpersecutors.lua")
    Sector():invokeFunction("spawnpersecutors", "update")
end

function onPersecutorsButtonPressed()
    if onClient() then
        invokeServerFunction("onPersecutorsButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator()
    for i = 1, 3 do
        local dir = random():getDirection()
        local matrix = MatrixLookUpPosition(-dir, vec3(0,1,0), Entity().translationf + dir * 2000)

        generator:createRaider(matrix)
    end
end

local transportData

function onCrewTransportButtonPressed()
    if onClient() then
        invokeServerFunction("onCrewTransportButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    local playerShip = player.craft

    if not playerShip then return end

    local generator = AsyncShipGenerator(nil, finalizeCrewTransport)

    local faction = Galaxy():getNearestFaction(Sector():getCoordinates())

    local dir = random():getDirection()
    local position = MatrixLookUpPosition(-dir, random():getDirection(), dir * 3000)
    generator:createFreighterShip(faction, position)

    transportData = {}
    transportData.craft = playerShip.index
    transportData.crew = playerShip.minCrew
end

function finalizeCrewTransport(ship)
    transportData = transportData or {}

    ship:addScriptOnce("crewtransport.lua", transportData.craft or Uuid(), transportData.crew or Crew())

    transportData = nil
end


function onStolenChecked(index, checked)
end

function onAddCrewButtonPressed()
    if onClient() then
        invokeServerFunction("onAddCrewButtonPressed")
        return
    end

    local craft = Entity()

    craft.crew = craft.minCrew
    craft:addCrew(1, CrewMan(CrewProfessionType.Captain))
end

function onGoodsButtonPressed(button, stolen, amount)
    if onClient() then
        local amount = 1
        if Keyboard():keyPressed(KeyboardKey.LControl) then
            amount = 10
        end

        invokeServerFunction("onGoodsButtonPressed", button.tooltip, stolenCargoCheckBox.checked, amount)
        return
    end

    -- we're using the same argument name for both the button and the
    -- good's name, on client it's a button, on server it's a string
    local name = button

    local craft = Entity()
    local good = goods[name]:good()

    good.stolen = stolen

    for i = 1, 10 do
        craft:addCargo(good, amount)
    end
end

function onAddCargoButtonPressed()
    if onClient() then
        invokeServerFunction("onAddCargoButtonPressed")
        return
    end

    local max = #goodsArray
    local goods = {
        goodsArray[random():getInt(1, max)],
        goodsArray[random():getInt(1, max)],
        goodsArray[random():getInt(1, max)],
        goodsArray[random():getInt(1, max)],
    }

    local craft = Entity()

    local add = true
    while add do
        add = false

        for _, g in pairs(goods) do
            local freeBefore = craft.freeCargoSpace
            if freeBefore > g.size then
                craft:addCargo(g:good(), 1)
                add = true
            end
        end
    end

end

function onClearCargoButtonPressed()
    if onClient() then
        invokeServerFunction("onClearCargoButtonPressed")
        return
    end

    local ship = Entity()

    for cargo, amount in pairs(ship:getCargos()) do
        ship:removeCargo(cargo, amount)
    end

end

function onClearCrewButtonPressed()
    if onClient() then
        invokeServerFunction("onClearCrewButtonPressed")
        return
    end

    Entity().crew = Crew()
end

function onClearHangarButtonPressed()
    if onClient() then
        invokeServerFunction("onClearHangarButtonPressed")
        return
    end

    Hangar():clear()
end

function onClearTorpedoesButtonPressed()
    if onClient() then
        invokeServerFunction("onClearTorpedoesButtonPressed")
        return
    end

    TorpedoLauncher():clear()
end

function onStartFighterButtonPressed()
    if onClient() then
        invokeServerFunction("onStartFighterButtonPressed")
        return
    end

    local controller = FighterController()
    local fighter, error = controller:startFighter(0, nil);

    if error ~= 0 then
        print ("error starting fighter: " .. error)
        return
    end

    local station = Sector():getEntitiesByType(EntityType.Station)

    local ai = FighterAI(fighter.id)
    ai.ignoreMothershipOrders = true
    ai:setOrders(FighterOrders.FlyToLocation, station.id)

end

function onDestroyButtonPressed(destroyer)
    if onClient() then
        invokeServerFunction("onDestroyButtonPressed", Player().craft.index)
        return
    end

    local craft = Entity()

    craft:destroy(destroyer)
end

function onSpawnDefendersButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDefendersButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local generator = AsyncShipGenerator()
    for i = -2, 2 do
        local pos = position - right * 500 + dir * i * 100
        generator:createDefender(faction, MatrixLookUpPosition(right, up, pos))
    end

end

local function getPositionInFrontOfPlayer()

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100

    return MatrixLookUpPosition(right, up, pos)
end

function makeDefender(craft)
    craft:addScript("ai/patrol")
end

function onSpawnMilitaryShipButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnMilitaryShipButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createMilitaryShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnTorpedoBoatButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnTorpedoBoatButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createTorpedoShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnCIWSButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnCIWSButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createCIWSShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnDisruptorButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDisruptorButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createDisruptorShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnPersecutorButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnPersecutorButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createPersecutorShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnBlockerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnBlockerButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createBlockerShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnFlagshipButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFlagshipButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createFlagShip(faction, getPositionInFrontOfPlayer())

end

function onSpawnCarrierButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnCarrierButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createCarrier(faction, MatrixLookUpPosition(right, up, pos))

end

function onSpawnTraderButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnTraderButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    local generator = AsyncShipGenerator(nil, makeDefender)
    generator:createTradingShip(faction, MatrixLookUpPosition(right, up, pos))

end

function onSpawnFreighterButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFreighterButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    local generator = AsyncShipGenerator()
    generator:createFreighterShip(faction, MatrixLookUpPosition(right, up, pos))

end

function onSpawnMinerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnMinerButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    local generator = AsyncShipGenerator()
    generator:createMiningShip(faction, MatrixLookUpPosition(right, up, pos))

end

function onSpawnXsotanSquadButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanSquadButtonPressed")
        return
    end

    local galaxy = Galaxy()

    local faction = Xsotan.getFaction()

    local player = Player()
    local others = Galaxy():getNearestFaction(Sector():getCoordinates())
    Galaxy():changeFactionRelations(faction, player, -200000)
    Galaxy():changeFactionRelations(faction, others, -200000)

    -- create the enemies
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500

    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates());
    local volumes = {
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
            }

    for _, p in pairs(volumes) do

        local enemy = Xsotan.createShip(MatrixLookUpPosition(-dir, up, pos), p.size)
        enemy.title = p.title

        local distance = enemy:getBoundingSphere().radius + 20

        pos = pos + right * distance

        enemy.translation = dvec3(pos.x, pos.y, pos.z)

        pos = pos + right * distance + 20

        -- patrol.lua takes care of setting aggressive
    end

end

function onSpawnXsotanCarrierButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanCarrierButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createCarrier(MatrixLookUpPosition(right, up, pos))

end

function onSpawnBattleButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnBattleButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local pirates = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local onGenerated = function(ships)
        for _, ship in pairs(ships) do
            ship:removeScript("entity/antismuggle.lua")
        end

        Placer.resolveIntersections(ships)
    end

    local generator = AsyncShipGenerator(nil, onGenerated)
    generator:startBatch()

    for i = -5, 5 do
        local pos = position + dir * 1500 + right * i * 100
        local ship
        if i >= -1 and i <= 1 then
            generator:createCarrier(pirates, MatrixLookUpPosition(-right, up, pos))
        else
            generator:createDefender(pirates, MatrixLookUpPosition(-right, up, pos))
        end
    end

    for i = -4, 4 do
        local pos = position + dir * 500 + right * i * 100
        local ship
        if i >= -1 and i <= 1 then
            generator:createCarrier(faction, MatrixLookUpPosition(-right, up, pos))
        else
            generator:createDefender(faction, MatrixLookUpPosition(-right, up, pos))
        end
    end

    generator:endBatch()
end

function onSpawnDeferredBattleButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDeferredBattleButtonPressed")
        return
    end

    deferredCallback(15.0, "onSpawnBattleButtonPressed")
end


function onSpawnFleetButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFleetButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local pirates = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
    local faction = Faction()

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local onFinished = function(ship)
        local waypoints = {}
        for j = 0, 8 do
            local pos = position + random():getVector(-400, 400)
            table.insert(waypoints, pos)
        end

    end

    local generator = AsyncShipGenerator(nil, onFinished)
    for i = -3, 3 do
        local pos = position - right * 500 + dir * i * 100
        generator:createDefender(faction, MatrixLookUpPosition(right, up, pos))
    end

end

function prepareCleanUp()
    local safe =
    {
        cleanUp = cleanUp,
        initialize = initialize,
        interactionPossible = interactionPossible,
        onShowWindow = onShowWindow,
        onCloseWindow = onCloseWindow,
        initUI = initUI,
        update = update,
        updateServer = updateServer,
        updateClient = updateClient,
    }

    return safe
end

function cleanUp(safe)
    cleanUp = safe.cleanUp
    initialize = safe.initialize
    interactionPossible = safe.interactionPossible
    onShowWindow = safe.onShowWindow
    onCloseWindow = safe.onCloseWindow
    initUI = safe.initUI

    update = nil
    updateServer = nil
    updateClient = nil
    getUpdateInterval = nil
    secure = nil
    restore = nil
end

function onResolveIntersectionsButtonPressed()
    if onClient() then
        invokeServerFunction("onResolveIntersectionsButtonPressed")
        return
    end

    Placer.resolveIntersections()
end

function onCondenseSectorButtonPressed()
    if onClient() then
        invokeServerFunction("onCondenseSectorButtonPressed")
        Entity().position = Matrix()
        return
    end

    for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.Plan)}) do
        entity.position = Matrix()
    end

    Placer.resolveIntersections()
end

function onRespawnAsteroidsButtonPressed()
    if onClient() then
        invokeServerFunction("onRespawnAsteroidsButtonPressed")
        return
    end

    Sector():removeScript("respawnresourceasteroids.lua")
    Sector():addScriptOnce("respawnresourceasteroids.lua")
end

function onTouchAllObjectsButtonPressed()
    if onClient() then
        invokeServerFunction("onTouchAllObjectsButtonPressed")
        return
    end

    for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.Physics)}) do
        local physics = Physics(entity.id)
        physics:applyImpulse(entity.translation, vec3(0, 1, 0), 10000)
    end

end

function onTouchAllObjectsOnClientButtonPressed()

    for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.Physics)}) do
        local physics = Physics(entity.id)
        physics:applyImpulse(entity.translation, vec3(0, 1, 0), 10000)
    end

end

function onSpawnSwoksButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSwoksButtonPressed")
        return
    end

    local safe = prepareCleanUp()

    dofile("data/scripts/player/story/spawnswoks.lua")
    SpawnSwoks.spawnEnemies(Player(), Sector():getCoordinates())

    safe.cleanUp(safe)
end

function onSpawnTheAIButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnTheAIButtonPressed")
        return
    end

    local safe = prepareCleanUp()

    dofile("data/scripts/player/story/spawnai.lua")
    SpawnAI.spawnEnemies(Player(), Sector():getCoordinates())

    safe.cleanUp(safe)

end

function onSpawnSmugglerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSmugglerButtonPressed")
        return
    end

    Smuggler.spawn()
end

function onSpawnScientistButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnScientistButtonPressed")
        return
    end

    Scientist.spawn()
end

function onSpawnGuardianButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnGuardianButtonPressed")
        return
    end

    Xsotan.createGuardian()
    Placer.resolveIntersections()
end

function onSearchAndRescueButtonPressed()
    if onClient() then
        invokeServerFunction("onSearchAndRescueButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:addScript("missions/searchandrescue/searchandrescue.lua", true)

end

function onSpawnThe4ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnThe4ButtonPressed")
        return
    end

    The4.spawn(Sector():getCoordinates())
end

function onAlignButtonPressed()
    if onClient() then
        invokeServerFunction("onAlignButtonPressed")
        return
    end

    Placer.placeNextToEachOther(vec3(0, 0, 0), vec3(1, 0, 0), vec3(0, 1, 0), Sector():getEntitiesByComponent(ComponentType.Plan))
    Placer.resolveIntersections()
end

function onEntityScriptsButtonPressed()
    scriptList:clear()
    scripts = {}
    scriptsWindow:show()


    addScriptButton.onPressedFunction = "addEntityScript"
    removeScriptButton.onPressedFunction = "removeEntityScript"

    invokeServerFunction("sendEntityScripts", Player().index)
end

function addEntityScript(name)
    if onClient() then
        invokeServerFunction("addEntityScript", scriptTextBox.text)
        invokeServerFunction("sendEntityScripts", Player().index)
        return
    end

    print("add script " .. name )

    Entity():addScript(name)

end

function removeEntityScript(script)

    if onClient() then

        local entry = tonumber(scripts[scriptList.selected])
        if entry ~= nil then
            invokeServerFunction("removeEntityScript", entry)
            invokeServerFunction("sendEntityScripts", Player().index)
        end

        return
    end

    print("remove script " .. script)

    Entity():removeScript(tonumber(script))

    print("remove script done ")
end

function sendEntityScripts(playerIndex)
    invokeClientFunction(Player(playerIndex), "receiveScripts", Entity():getScripts())
end



function onSectorScriptsButtonPressed()
    scriptList:clear()
    scripts = {}
    scriptsWindow:show()

    addScriptButton.onPressedFunction = "addSectorScript"
    removeScriptButton.onPressedFunction = "removeSectorScript"

    invokeServerFunction("sendSectorScripts", Player().index)
end

function addSectorScript(name)

    if onClient() then
        invokeServerFunction("addSectorScript", scriptTextBox.text)
        invokeServerFunction("sendSectorScripts", Player().index)
        return
    end

    print("add sector script " .. name )

    Sector():addScript(name)

end

function removeSectorScript(script)

    if onClient() then

        local entry = tonumber(scripts[scriptList.selected])
        if entry ~= nil then
            invokeServerFunction("removeSectorScript", entry)
            invokeServerFunction("sendSectorScripts", Player().index)
        end

        return
    end

    print("remove script " .. script )

    Sector():removeScript(tonumber(script))

end

function sendSectorScripts(playerIndex)
    invokeClientFunction(Player(playerIndex), "receiveScripts", Sector():getScripts())
end


function onPlayerScriptsButtonPressed()
    scriptList:clear()
    scripts = {}
    scriptsWindow:show()

    addScriptButton.onPressedFunction = "addPlayerScript"
    removeScriptButton.onPressedFunction = "removePlayerScript"

    invokeServerFunction("sendPlayerScripts")
end

function addPlayerScript(name)

    if onClient() then
        invokeServerFunction("addPlayerScript", scriptTextBox.text)
        invokeServerFunction("sendPlayerScripts")
        return
    end

    print("adding player script " .. name )

    Player(callingPlayer):addScript(name)

end

function removePlayerScript(script)

    if onClient() then

        local entry = tonumber(scripts[scriptList.selected])
        if entry ~= nil then
            invokeServerFunction("removePlayerScript", entry)
            invokeServerFunction("sendPlayerScripts")
        end

        return
    end

    print("removing player script " .. script )

    Player(callingPlayer):removeScript(tonumber(script))

end

function sendPlayerScripts()
    invokeClientFunction(Player(callingPlayer), "receiveScripts", Player(callingPlayer):getScripts())
end





function receiveScripts(scripts_in)

    scriptList:clear()
    scripts = {}

    local c = 0
    for i, name in pairs(scripts_in) do
        scriptList:addEntry(string.format("[%i] %s", i, name))

        scripts[c] = i
        c = c + 1
    end
end

function syncValues(valueType_in, values_in)
    if onClient() then
        if not values_in then
            invokeServerFunction("syncValues", valueType_in)
        else
            valueType = valueType_in
            values = values_in

            fillValues()
        end
    else
        local values

        if valueType_in == 0 then
            values = Entity():getValues()
        elseif valueType_in == 1 then
            values = Sector():getValues()
        elseif valueType_in == 2 then
            values = Faction():getValues()
        elseif valueType_in == 3 then
            values = Player(callingPlayer):getValues()
        elseif valueType_in == 4 then
            values = Server():getValues()
        end

        invokeClientFunction(Player(callingPlayer), "syncValues", valueType_in, values)
    end
end

function setValue(tp, key, value)

    if tp == 0 then
        values = Entity():setValue(key, value)
    elseif tp == 1 then
        values = Sector():setValue(key, value)
    elseif tp == 2 then
        values = Faction():setValue(key, value)
    elseif tp == 3 then
        values = Player(callingPlayer):setValue(key, value)
    elseif tp == 4 then
        values = Server():setValue(key, value)
    end

    syncValues(tp)
end

function onEntityValuesButtonPressed()
    syncValues(0)
    valuesWindow:show()
end

function onSectorValuesButtonPressed()
    syncValues(1)
    valuesWindow:show()
end

function onFactionValuesButtonPressed()
    syncValues(2)
    valuesWindow:show()
end

function onPlayerValuesButtonPressed()
    syncValues(3)
    valuesWindow:show()
end

function onServerValuesButtonPressed()
    syncValues(4)
    valuesWindow:show()
end

function fillValues()
    for _, line in pairs(valuesLines) do
        line.key.text = ""
        line.value.text = ""
    end

    local sorted = {}

    for k, v in pairs(values) do
        table.insert(sorted, {k=k, v=v})
    end

    function comp(a, b) return a.k < b.k end
    table.sort(sorted, comp)


    local c = 1
    for _, p in pairs(sorted) do
        local line = valuesLines[c]

        line.key.text = p.k
        line.value.text = tostring(p.v)

        c = c + 1
    end

end

function onSetValuePressed(button)
    for _, line in pairs(valuesLines) do
        if line.set.index == button.index then
            local str = line.value.text
            local number = tonumber(str)

            if number then
                invokeServerFunction("setValue", valueType, line.key.text, number)
            elseif str == "true" then
                invokeServerFunction("setValue", valueType, line.key.text, true)
            elseif str == "false" then
                invokeServerFunction("setValue", valueType, line.key.text, false)
            else
                invokeServerFunction("setValue", valueType, line.key.text, str)
            end
        end
    end
end

function onDeleteValuePressed(button)
    for _, line in pairs(valuesLines) do
        if line.delete.index == button.index then
            invokeServerFunction("setValue", valueType, line.key.text, nil)
        end
    end
end


function onGiveWeaponsButtonPressed(arg)
    if onClient() then
        local button = arg
        for _, wp in pairs(WeaponTypes) do
            if wp.buttonIndex == button.index then
                invokeServerFunction("onGiveWeaponsButtonPressed", wp.type)
                break
            end
        end
        return
    end

    local player = Faction()
    local x, y = Sector():getCoordinates()
    local dps, tech = Balancing_GetSectorWeaponDPS(x, y)
    local weaponType = arg

    rarityCounter = (rarityCounter or 0) + 1
    if rarityCounter > 5 then rarityCounter = -1 end

    local turret = TurretGenerator.generate(x, y, 0, Rarity(rarityCounter), weaponType)
    for j = 1, 20 do
        player:getInventory():add(InventoryTurret(turret))
    end
end

function onQuestRewardButtonPressed(arg)
    if onClient() then
        invokeServerFunction("onQuestRewardButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    local faction = Galaxy():getNearestFaction(Sector():getCoordinates())

    Rewards.standard(player, faction, nil, 12345, 500, true, true)
end

function onKeysButtonPressed(arg)
    if onClient() then
        invokeServerFunction("onKeysButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey1.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey2.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey3.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey4.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey5.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey6.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey7.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey8.lua", Rarity(RarityType.Legendary), Seed(0)))

    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/smugglerblocker.lua", Rarity(RarityType.Exotic), Seed(0)))

    for i = 0, 3 do
        player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/enginebooster.lua", Rarity(RarityType.Legendary), Seed(0)))
    end

end

function onDisableEventsButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onDisableEventsButtonPressed")
        return
    end

    Player(callingPlayer):removeScript("eventscheduler.lua")
    Player(callingPlayer):removeScript("pirateattackstarter.lua")
    Player(callingPlayer):removeScript("headhunter.lua")
    Player(callingPlayer):removeScript("alienattack.lua")

    Sector():removeScript("eventscheduler.lua")
    Sector():removeScript("pirateattack.lua")
end

function onCrashButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onCrashButtonPressed")

        local player = nil
        player:removeScript("eventscheduler.lua")
        return
    end

    local player = nil
    player:removeScript("eventscheduler.lua")
end

function onPrintClientLogButtonPressed(arg)
    print("Client Log: ")
    print(tostring(DebugInfo():getEndingLog()))
end

function onPrintServerLogButtonPressed(arg)
    if onClient() then
        invokeServerFunction("onPrintServerLogButtonPressed", Player().index)
        return
    end

    print(DebugInfo():getEndingLog())
end

function onFlyButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onFlyButtonPressed", Player().index)
        return
    end

    local player = Player(arg)
    player.craft = Entity()
end

function onOwnButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onOwnButtonPressed", Player().index)
        return
    end

    Entity().factionIndex = arg
end

function onOwnAllianceButtonPressed(arg)

    if onClient() then
        local allianceIndex = Player().allianceIndex

        if allianceIndex then
            invokeServerFunction("onOwnAllianceButtonPressed", allianceIndex)
        end

        return
    end

    Entity().factionIndex = arg
end

function onCreateShipsButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateShipsButtonPressed")
        return
    end

    local faction = Faction()
    local this = Entity()

    local position = this.position
    local p = this.right * (this:getBoundingBox().size.x + 50.0)
    position.pos = position.pos + vec3(p.x, p.y, p.z)

    local finished = function(ship) ship:addScript("data/scripts/entity/stationfounder.lua") end
    local generator = AsyncShipGenerator(nil, finished)

    generator:createMilitaryShip(faction, position)

end

function onCreateShipCopyButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateShipCopyButtonPressed")
        return
    end

    local faction = Faction()
    local this = Entity()

    local position = this.position
    local p = this.right * (this:getBoundingBox().size.x + 50.0)
    position.pos = position.pos + vec3(p.x, p.y, p.z)

    Sector():copyEntity(this, position)

end

function onCreateBeaconButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateBeaconButtonPressed")
        return
    end

    local faction = Faction()
    local this = Entity()

    local position = this.position
    local p = this.right * (this:getBoundingBox().size.x + 50.0)
    position.pos = position.pos + vec3(p.x, p.y, p.z)

    SectorGenerator(Sector():getCoordinates()):createBeacon(position, nil, "This is the ${text}", {text = "Beacon Text"})

end

function onGunsButtonPressed()
    if onClient() then
        invokeServerFunction("onGunsButtonPressed")
        return
    end

    local player = Faction()

    local weaponTypes = {}
    weaponTypes[WeaponType.ChainGun] = 1
    weaponTypes[WeaponType.PointDefenseChainGun] = 1
    weaponTypes[WeaponType.Laser] = 1
    weaponTypes[WeaponType.MiningLaser] = 1
    weaponTypes[WeaponType.RawMiningLaser] = 1
    weaponTypes[WeaponType.SalvagingLaser] = 1
    weaponTypes[WeaponType.RawSalvagingLaser] = 1
    weaponTypes[WeaponType.PlasmaGun] = 1
    weaponTypes[WeaponType.RocketLauncher] = 1
    weaponTypes[WeaponType.Cannon] = 1
    weaponTypes[WeaponType.RailGun] = 1
    weaponTypes[WeaponType.RepairBeam] = 1
    weaponTypes[WeaponType.Bolter] = 1
    weaponTypes[WeaponType.LightningGun] = 1
    weaponTypes[WeaponType.TeslaGun] = 1
    weaponTypes[WeaponType.ForceGun] = 1
    weaponTypes[WeaponType.PulseCannon] = 1
    weaponTypes[WeaponType.AntiFighter] = 1
    weaponTypes[WeaponType.PointDefenseLaser] = 1

    local rarities = {}
    rarities[RarityType.Petty] = 1
    rarities[RarityType.Common] = 1
    rarities[RarityType.Uncommon] = 1
    rarities[RarityType.Rare] = 1
    rarities[RarityType.Exceptional] = 1
    rarities[RarityType.Exotic] = 1
    rarities[RarityType.Legendary] = 1


    local materials = {}
    materials[0] = 1
    materials[1] = 1
    materials[2] = 1
    materials[3] = 1
    materials[4] = 1
    materials[5] = 1
    materials[6] = 1

    local dps, tech = Balancing_GetSectorWeaponDPS(Sector():getCoordinates())

    local x, y = Sector():getCoordinates()

    for i = 1, 15 do

        local rarity = selectByWeight(random(), rarities)
        local material = selectByWeight(random(), materials)
        local weaponType = selectByWeight(random(), weaponTypes)

        local turret = TurretGenerator.generate(x, y, 0, Rarity(rarity), weaponType, Material(material))

        for j = 1, 20 do
            player:getInventory():add(InventoryTurret(turret))
        end
    end

end

function onCoaxialGunsButtonPressed()
    if onClient() then
        invokeServerFunction("onCoaxialGunsButtonPressed")
        return
    end

    local player = Faction()

    local weaponTypes = {}
    weaponTypes[WeaponType.ChainGun] = 1
    weaponTypes[WeaponType.PointDefenseChainGun] = 1
    weaponTypes[WeaponType.Laser] = 1
    weaponTypes[WeaponType.MiningLaser] = 1
    weaponTypes[WeaponType.RawMiningLaser] = 1
    weaponTypes[WeaponType.SalvagingLaser] = 1
    weaponTypes[WeaponType.RawSalvagingLaser] = 1
    weaponTypes[WeaponType.PlasmaGun] = 1
    weaponTypes[WeaponType.RocketLauncher] = 1
    weaponTypes[WeaponType.Cannon] = 1
    weaponTypes[WeaponType.RailGun] = 1
    weaponTypes[WeaponType.RepairBeam] = 1
    weaponTypes[WeaponType.Bolter] = 1
    weaponTypes[WeaponType.LightningGun] = 1
    weaponTypes[WeaponType.TeslaGun] = 1
    weaponTypes[WeaponType.ForceGun] = 1
    weaponTypes[WeaponType.PulseCannon] = 1
    weaponTypes[WeaponType.AntiFighter] = 1
    weaponTypes[WeaponType.PointDefenseLaser] = 1

    local rarities = {}
    rarities[RarityType.Petty] = 1
    rarities[RarityType.Common] = 1
    rarities[RarityType.Uncommon] = 1
    rarities[RarityType.Rare] = 1
    rarities[RarityType.Exceptional] = 1
    rarities[RarityType.Exotic] = 1
    rarities[RarityType.Legendary] = 1


    local materials = {}
    materials[0] = 1
    materials[1] = 1
    materials[2] = 1
    materials[3] = 1
    materials[4] = 1
    materials[5] = 1
    materials[6] = 1

    local dps, tech = Balancing_GetSectorWeaponDPS(Sector():getCoordinates())

    local x, y = Sector():getCoordinates()

    for i = 1, 15 do

        local rarity = selectByWeight(random(), rarities)
        local material = selectByWeight(random(), materials)
        local weaponType = selectByWeight(random(), weaponTypes)

        local turret = TurretGenerator.generate(x, y, 0, Rarity(rarity), weaponType, Material(material))
        turret.coaxial = true

        for j = 1, 5 do
            player:getInventory():add(InventoryTurret(turret))
        end
    end

end

function onSystemsButtonPressed()
    if onClient() then
        invokeServerFunction("onSystemsButtonPressed")
        return
    end

    UpgradeGenerator.initialize()

    for i = 1, 15 do
        Faction():getInventory():add(UpgradeGenerator.generateSystem())
    end
end

function onSystemUpgradeButtonPressed(arg)
    if onClient() then
        local button = arg
        for _, p in pairs(systemButtons) do
            if button.index == p.button.index then
                invokeServerFunction("onSystemUpgradeButtonPressed", p.script)
                break
            end
        end
        return
    end

    rarityCounter = (rarityCounter or 0) + 1
    if rarityCounter > 5 then rarityCounter = -1 end

    Faction():getInventory():add(SystemUpgradeTemplate(arg, Rarity(rarityCounter), random():createSeed()))
end

function onEnergySuppressorButtonPressed()
    if onClient() then
        invokeServerFunction("onEnergySuppressorButtonPressed")
        return
    end

    local item = UsableInventoryItem("energysuppressor.lua", Rarity(RarityType.Exceptional))
    Faction():getInventory():add(item)
    Faction():getInventory():add(item)
    Faction():getInventory():add(item)
    Faction():getInventory():add(item)
end

function onClearInventoryButtonPressed()
    if onClient() then
        invokeServerFunction("onClearInventoryButtonPressed")
        return
    end

    Faction():getInventory():clear()

end

function onCreateWreckagePressed()
    if onClient() then
        invokeServerFunction("onCreateWreckagePressed")
        return
    end

    SectorGenerator(Sector():getCoordinates()):createWreckage(Galaxy():getNearestFaction(Sector():getCoordinates()))
end

function onCreateInfectedAsteroidPressed()
    if onClient() then
        invokeServerFunction("onCreateInfectedAsteroidPressed")
        return
    end

    local ship = Entity()
    local asteroid = SectorGenerator(0, 0):createSmallAsteroid(ship.translationf + ship.look * (ship.size.z * 0.5 + 20), 7, true, Material(MaterialType.Iron))
    Xsotan.infect(asteroid)

    Placer.resolveIntersections()
end

function onCreateBigInfectedAsteroidPressed()
    if onClient() then
        invokeServerFunction("onCreateBigInfectedAsteroidPressed")
        return
    end

    local ship = Entity()
    Xsotan.createBigInfectedAsteroid(ship.translationf + ship.look * (ship.size.z * 0.5 + 50))

    Placer.resolveIntersections()
end

function onCreateOwnableAsteroidPressed()
    if onClient() then
        invokeServerFunction("onCreateOwnableAsteroidPressed")
        return
    end

    SectorGenerator(0, 0):createClaimableAsteroid()
    Placer.resolveIntersections()
end

function onCreateClaimableWreckagePressed()
    if onClient() then
        invokeServerFunction("onCreateClaimableWreckagePressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local wreckage = generator:createWreckage(faction, nil, 0)

    -- find largest wreckage
    wreckage.title = "Abandoned Ship"%_t
    wreckage:addScript("wreckagetoship.lua")

    Placer.resolveIntersections()
end

function onCreateAdventurerPressed()
    if onClient() then
        invokeServerFunction("onCreateAdventurerPressed")
        return
    end

    AdventurerGuide.spawn1(Player(callingPlayer))
end

function onCreateMerchantPressed()
    if onClient() then
        invokeServerFunction("onCreateMerchantPressed")
        return
        end

        Player(callingPlayer):addScript("spawntravellingmerchant.lua")
        end

function onGoToButtonPressed()

    local ship = Player().craft
    local target = ship.selectedObject

    ship.position = target.position

    Velocity(ship.index).velocity = dvec3(0, 0, 0)
    ship.desiredVelocity = 0

    if target.type == EntityType.Station then
        local pos, dir = target:getDockingPositions()

        pos = target.position:transformCoord(pos)
        dir = target.position:transformNormal(dir)

        pos = pos + dir * (ship:getBoundingSphere().radius + 10)

        local up = target.position.up

        ship.position = MatrixLookUpPosition(-dir, up, pos)
    end

end

function onCreateContainerFieldButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateContainerFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    generator:createContainerField()

    Placer.resolveIntersections()
end

function onCreateResourceAsteroidButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateResourceAsteroidButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    generator:createSmallAsteroid(vec3(0, 0, 0), 1.0, true, generator:getAsteroidType())

    Placer.resolveIntersections()
end

function onCreatePirateButtonPressed()

    if onClient() then
        invokeServerFunction("onCreatePirateButtonPressed")
        return
    end

    local generator = AsyncPirateGenerator();
    generator:createPirate()
end

function onCreateTurretFactoryButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTurretFactoryButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createTurretFactory(faction)
    station:addScript("data/scripts/entity/merchants/turretmerchant.lua")
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateFighterMerchantButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateFighterMerchantButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/fightermerchant.lua")
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateFighterFactoryButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateFighterFactoryButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createFighterFactory(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateTorpedoMerchantButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTorpedoMerchantButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/torpedomerchant.lua")
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateTradingPostButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTradingPostButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/tradingpost.lua")
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreatePlanetaryTradingPostButtonPressed()

    if onClient() then
        invokeServerFunction("onCreatePlanetaryTradingPostButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()
    local generator = SectorGenerator(x, y)

    local faction = Galaxy():createRandomFaction(x, y)
    local station = generator:createStation(faction)
    local specs = SectorSpecifics(x, y, Server().seed)
    local planets = {specs:generatePlanets()}
    station:addScript("data/scripts/entity/merchants/planetarytradingpost.lua", planets)
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateSmugglersMarketPressed()

    if onClient() then
        invokeServerFunction("onCreateSmugglersMarketPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/smugglersmarket.lua")
--    station:addScript("merchants/tradingpost")
    station.position = Matrix()
    station.title = "Smuggler's Market"

    Placer.resolveIntersections()

end

function onCreateResistanceOutpostPressed()

    if onClient() then
        invokeServerFunction("onCreateResistanceOutpostPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "merchants/resistanceoutpost.lua")

    Placer.resolveIntersections()
end

function onCreateHeadQuartersPressed()

    if onClient() then
        invokeServerFunction("onCreateHeadQuartersPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/headquarters.lua")
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateResearchStationPressed()

    if onClient() then
        invokeServerFunction("onCreateResearchStationPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createResearchStation(faction)
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateShipyardButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateShipyardButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createShipyard(faction)
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateConsumerButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateConsumerButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())

    local station
    local consumerType = math.random(1, 3)
    if consumerType == 1 then
        station = generator:createStation(faction, "data/scripts/entity/merchants/casino.lua");
    elseif consumerType == 2 then
        station = generator:createStation(faction, "data/scripts/entity/merchants/biotope.lua");
    elseif consumerType == 3 then
        station = generator:createStation(faction, "data/scripts/entity/merchants/habitat.lua");
    end

    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateRepairDockButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateRepairDockButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createRepairDock(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateEquipmentDockButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateEquipmentDockButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createEquipmentDock(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateTurretMerchantButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTurretMerchantButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/turretmerchant.lua")
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateResourceDepotButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateResourceDepotButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/resourcetrader.lua")
    station.position = Matrix()

    Placer.resolveIntersections()
end


function onResetMoneyButtonPressed()
    if onClient() then
        invokeServerFunction("onResetMoneyButtonPressed")
        return
    end

    local player = Player() or Alliance()
    if not player then return end

    if player ~= nil then
        local money = 5000000

        if player.money == money * 100 then
            money = 0

            player.money = money * 100
            player:setResources(money, money, money, money, money, money, money, money, money, money, money) -- too much, don't care

        elseif player.money == 0 then
            local x, y = Sector():getCoordinates()

            player.money = Balancing_GetSectorRichnessFactor(x, y) * 200000

            local probabilities = Balancing_GetMaterialProbability(x, y)

            for i, p in pairs(probabilities) do
                probabilities[i] = p * Balancing_GetSectorRichnessFactor(x, y) * 5000
            end

            local num = 0
            for i = NumMaterials() - 1, 0, -1 do
                probabilities[i] = probabilities[i] + num
                num = num + probabilities[i] / 2;
            end


            player:setResources(unpack(probabilities))
        else
            player.money = money * 100
            player:setResources(money, money, money, money, money, money, money, money, money, money, money) -- too much, don't care
        end

    end

end

function onSetGatePlanPressed()
    if onClient() then
        invokeServerFunction("onSetGatePlanPressed")
        return
    end

    local plan = PlanGenerator.makeGatePlan()

    local entity = Entity()

    entity:setMovePlan(plan)
end

function onSetFreighterPlanPressed()
    if onClient() then
        invokeServerFunction("onSetFreighterPlanPressed")
        return
    end

    local plan = PlanGenerator.makeFreighterPlan(Faction())

    Entity():setMovePlan(plan)
end

function onLikePressed()
    if onClient() then
        invokeServerFunction("onLikePressed")
        return
    end

    local faction, ship, player = getInteractingFaction(callingPlayer)
    Galaxy():changeFactionRelations(faction, Faction(), 5000)
end

function onDislikePressed()
    if onClient() then
        invokeServerFunction("onDislikePressed")
        return
    end

    local faction, ship, player = getInteractingFaction(callingPlayer)
    Galaxy():changeFactionRelations(faction, Faction(), -5000)

end

function onTitlePressed()

    local str = "args: "
    for k, v in pairs(Entity():getTitleArguments()) do
        str = str .. " k: " .. k .. ", v: " .. v
    end

    print (str)
    print (Entity().title)

    if onClient() then
        invokeServerFunction("onTitlePressed")
        return
    end
end

function onTransformTurretsPressed()
    if onClient() then
        invokeServerFunction("onTransformTurretsPressed")
        return
    end

    local fighter = FighterGenerator.generateArmed(Sector():getCoordinates())

    local base = TurretDesignPart()
    base:setPlan(fighter.plan)

    local body = TurretDesignPart()
    body:setPlan(fighter.plan)

    local barrel = TurretDesignPart()
    barrel:setPlan(fighter.plan)

    local design = TurretDesign()
    design:setMoveBase(base)
    design:setMoveBody(body)
    design:setMoveBarrels(barrel)

    for _, block in pairs(Plan():getBlocksByType(BlockType.TurretBase)) do
        TurretBases():setDesign(block, design)
    end
end

function onFactionIndexPressed()
    print ("${factionIndex}" % Entity())
end

function addFighterSquad(weaponType)
    local ship = Entity()
    local hangar = Hangar(ship.index)
    if hangar == nil then return end

    local x, y = Sector():getCoordinates()

    hangar:addSquad("Script Squad")

    local squads = {hangar:getSquads()}
    local squad = squads[#squads]

    -- fill all present squads
    local fighter = FighterGenerator.generate(x, y, nil, nil, weaponType)
    hangar:setBlueprint(squad, fighter)

    for i = hangar:getSquadFighters(squad), hangar:getSquadMaxFighters(squad) - 1 do
        if hangar.freeSpace < fighter.volume then return end

        hangar:addFighter(squad, fighter)
    end

end

function onAddArmedFightersButtonPressed()
    if onClient() then
        invokeServerFunction("onAddArmedFightersButtonPressed")
        return
    end

    addFighterSquad(WeaponType.RailGun)
end

function onAddMiningFightersButtonPressed()
    if onClient() then
        invokeServerFunction("onAddMiningFightersButtonPressed")
        return
    end

    addFighterSquad(WeaponType.MiningLaser)
end

function onAddRawMiningFightersButtonPressed()
    if onClient() then
        invokeServerFunction("onAddRawMiningFightersButtonPressed")
        return
    end

    addFighterSquad(WeaponType.RawMiningLaser)
end

function onAddSalvagingFightersButtonPressed()
    if onClient() then
        invokeServerFunction("onAddSalvagingFightersButtonPressed")
        return
    end

    addFighterSquad(WeaponType.SalvagingLaser)
end

function onAddCargoShuttlesButtonPressed()
    if onClient() then
        invokeServerFunction("onAddCargoShuttlesButtonPressed")
        return
    end

    local ship = Entity()
    local hangar = Hangar(ship.index)
    if hangar == nil then return end

    local x, y = Sector():getCoordinates()

    for i = 1, 10 do
        hangar:addSquad("Script Squad")
    end

    local squads = {hangar:getSquads()}

    -- fill all present squads
    for _, squad in pairs(squads) do
        local fighter = FighterGenerator.generateCargoShuttle(x, y)
        fighter.diameter = 1

        for i = hangar:getSquadFighters(squad), hangar:getSquadMaxFighters(squad) - 1 do
            if hangar.freeSpace < fighter.volume then return end

            hangar:addFighter(squad, fighter)
        end
    end

end

function onAddTorpedoesButtonPressed()
    if onClient() then
        invokeServerFunction("onAddTorpedoesButtonPressed")
        return
    end

    local ship = Entity()
    local launcher = TorpedoLauncher(ship.index)
    if launcher == nil then return end

    local x, y = Sector():getCoordinates()

    local shafts = {launcher:getShafts()}

    -- fill all present squads
    for _, shaft in pairs(shafts) do
        local torpedo = TorpedoGenerator.generate(x, y)

        for i = 1, 10 do
            launcher:addTorpedo(torpedo, shaft)
        end
    end

    for j = 1, 10 do
        local torpedo = TorpedoGenerator.generate(x, y)

        for i = 1, 5 do
            launcher:addTorpedo(torpedo)
        end
    end
end

function onDamagePressed()
    if onClient() then
        invokeServerFunction("onDamagePressed")
        return
    end

    local ship = Entity()
    if ship.shieldDurability and ship.shieldDurability > 0 then
        local damage = ship.shieldMaxDurability * 0.2
        ship:damageShield(damage, ship.translationf, Player(callingPlayer).craftIndex)
    else
        local damage = (ship.maxDurability or 0) * 0.2
        ship:inflictDamage(damage, 0, vec3(), Player(callingPlayer).craftIndex)
    end

end

function onInvincibleButtonPressed()
    if onClient() then
        invokeServerFunction("onInvincibleButtonPressed")
        return
    end

    local entity = Entity()

    local name = string.format("%s %s", entity.title or "", entity.name or "")

    if entity.invincible then
        entity.invincible = false
        Player(callingPlayer):sendChatMessage("", 0, name .. " is no longer invincible")
    else
        entity.invincible = true
        Player(callingPlayer):sendChatMessage("", 0, name .. " is now invincible")
    end
end

function onDeleteButtonPressed()
    if onClient() then
        invokeServerFunction("onDeleteButtonPressed")
        return
    end

    Sector():deleteEntityJumped(Entity())
end

function onCreateBigAsteroidButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateBigAsteroidButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createBigAsteroid()

    Placer.resolveIntersections()
end

function onCreateAsteroidFieldButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateAsteroidFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createAsteroidField()

    Placer.resolveIntersections()
end

function onCreateEmptyAsteroidFieldButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateEmptyAsteroidFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createEmptyAsteroidField()

    Placer.resolveIntersections()
end

function onCreateRichAsteroidFieldButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateRichAsteroidFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createAsteroidField(0.8)

    Placer.resolveIntersections()
end

function onCreateManufacturerButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateManufacturerButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Rubber")

    Placer.resolveIntersections()
end

function onCreateFarmButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateFarmButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Wheat")

    Placer.resolveIntersections()
end

function onCreateCollectorButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateCollectorButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Water")

    Placer.resolveIntersections()
end

function onCreateScrapyardButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateScrapyardButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/scrapyard.lua", "Water")

    Placer.resolveIntersections()
end

function onCreateMilitaryOutpostPressed()

    if onClient() then
        invokeServerFunction("onCreateMilitaryOutpostPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createMilitaryBase(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateSolarPlantButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateSolarPlantButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Energy Cell")

    Placer.resolveIntersections()
end

function onCreateMineButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateMineButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Silicium")

    Placer.resolveIntersections()
end

function onClearButtonPressed()
    if onClient() then
        invokeServerFunction("onClearButtonPressed")
        return
    end

    -- portion that is executed on server
    local sector = Sector()
    local self = Entity()

    for _, entity in pairs({sector:getEntities()}) do
        if entity.factionIndex == nil or (entity.factionIndex ~= callingPlayer and entity.factionIndex ~= self.factionIndex) then
            sector:deleteEntity(entity)
        end
    end

end

function onClearFightersButtonPressed()
    if onClient() then
        invokeServerFunction("onClearFightersButtonPressed")
        return
    end

    -- portion that is executed on server
    local sector = Sector()
    local self = Entity()

    for _, entity in pairs({sector:getEntities()}) do
        if entity.type == EntityType.Fighter then
            sector:deleteEntity(entity)
        end
    end

end

function onClearTorpedosButtonPressed()
    if onClient() then
        invokeServerFunction("onClearTorpedosButtonPressed")
        return
    end

    -- portion that is executed on server
    local sector = Sector()
    local self = Entity()

    for _, entity in pairs({sector:getEntities()}) do
        if entity.type == EntityType.Torpedo then
            sector:deleteEntity(entity)
        end
    end

end


function onInfectAsteroidsButtonPressed()
    if onClient() then
        invokeServerFunction("onInfectAsteroidsButtonPressed")
        return
    end

    Xsotan.infectAsteroids()
end

function clearStations()
    local sector = Sector()
    for _, entity in pairs({sector:getEntitiesByType(EntityType.Station)}) do
        sector:deleteEntity(entity)
    end
end




callable(nil, "addEntityScript")
callable(nil, "addPlayerScript")
callable(nil, "addSectorScript")
callable(nil, "onAddCargoButtonPressed")
callable(nil, "onAddCargoShuttlesButtonPressed")
callable(nil, "onAddCrewButtonPressed")
callable(nil, "onAddArmedFightersButtonPressed")
callable(nil, "onAddMiningFightersButtonPressed")
callable(nil, "onAddRawMiningFightersButtonPressed")
callable(nil, "onAddSalvagingFightersButtonPressed")
callable(nil, "onAddTorpedoesButtonPressed")
callable(nil, "onAlienAttackButtonPressed")
callable(nil, "onAlignButtonPressed")
callable(nil, "onClearButtonPressed")
callable(nil, "onClearCargoButtonPressed")
callable(nil, "onClearCrewButtonPressed")
callable(nil, "onClearFightersButtonPressed")
callable(nil, "onClearHangarButtonPressed")
callable(nil, "onClearInventoryButtonPressed")
callable(nil, "onClearTorpedoesButtonPressed")
callable(nil, "onClearTorpedosButtonPressed")
callable(nil, "onCoaxialGunsButtonPressed")
callable(nil, "onCondenseSectorButtonPressed")
callable(nil, "onCreateAdventurerPressed")
callable(nil, "onCreateAsteroidFieldButtonPressed")
callable(nil, "onCreateBeaconButtonPressed")
callable(nil, "onCreateBigAsteroidButtonPressed")
callable(nil, "onCreateBigInfectedAsteroidPressed")
callable(nil, "onCreateClaimableWreckagePressed")
callable(nil, "onCreateCollectorButtonPressed")
callable(nil, "onCreateConsumerButtonPressed")
callable(nil, "onCreateContainerFieldButtonPressed")
callable(nil, "onCreateEmptyAsteroidFieldButtonPressed")
callable(nil, "onCreateEquipmentDockButtonPressed")
callable(nil, "onCreateFarmButtonPressed")
callable(nil, "onCreateFighterFactoryButtonPressed")
callable(nil, "onCreateFighterMerchantButtonPressed")
callable(nil, "onCreateHeadQuartersPressed")
callable(nil, "onCreateInfectedAsteroidPressed")
callable(nil, "onCreateManufacturerButtonPressed")
callable(nil, "onCreateMerchantPressed")
callable(nil, "onCreateMilitaryOutpostPressed")
callable(nil, "onCreateMineButtonPressed")
callable(nil, "onCreateOwnableAsteroidPressed")
callable(nil, "onCreatePirateButtonPressed")
callable(nil, "onCreatePlanetaryTradingPostButtonPressed")
callable(nil, "onCreateRepairDockButtonPressed")
callable(nil, "onCreateResearchStationPressed")
callable(nil, "onCreateResistanceOutpostPressed")
callable(nil, "onCreateResourceAsteroidButtonPressed")
callable(nil, "onCreateResourceDepotButtonPressed")
callable(nil, "onCreateRichAsteroidFieldButtonPressed")
callable(nil, "onCreateScrapyardButtonPressed")
callable(nil, "onCreateShipsButtonPressed")
callable(nil, "onCreateShipCopyButtonPressed")
callable(nil, "onCreateShipyardButtonPressed")
callable(nil, "onCreateSmugglersMarketPressed")
callable(nil, "onCreateSolarPlantButtonPressed")
callable(nil, "onCreateTorpedoMerchantButtonPressed")
callable(nil, "onCreateTradingPostButtonPressed")
callable(nil, "onCreateTurretFactoryButtonPressed")
callable(nil, "onCreateTurretMerchantButtonPressed")
callable(nil, "onCreateWreckagePressed")
callable(nil, "onCrewTransportButtonPressed")
callable(nil, "onDamagePressed")
callable(nil, "onDeleteButtonPressed")
callable(nil, "onDestroyButtonPressed")
callable(nil, "onCrashButtonPressed")
callable(nil, "onDisableEventsButtonPressed")
callable(nil, "onDislikePressed")
callable(nil, "onDistressCallButtonPressed")
callable(nil, "onExodusBeaconButtonPressed")
callable(nil, "onExodusFinalBeaconButtonPressed")
callable(nil, "onExodusPointsButtonPressed")
callable(nil, "onFakeDistressCallButtonPressed")
callable(nil, "onFlyButtonPressed")
callable(nil, "onGenerateFactoryButtonPressed")
callable(nil, "onGenerateTemplateButtonPressed")
callable(nil, "onGoodsButtonPressed")
callable(nil, "onGunsButtonPressed")
callable(nil, "onHeadhunterAttackButtonPressed")
callable(nil, "onInfectAsteroidsButtonPressed")
callable(nil, "onInvincibleButtonPressed")
callable(nil, "onKeysButtonPressed")
callable(nil, "onLikePressed")
callable(nil, "onMiningLasersButtonPressed")
callable(nil, "onOwnAllianceButtonPressed")
callable(nil, "onOwnButtonPressed")
callable(nil, "onPersecutorsButtonPressed")
callable(nil, "onPirateAttackButtonPressed")
callable(nil, "onPrintServerLogButtonPressed")
callable(nil, "onProgressBrakersButtonPressed")
callable(nil, "onGiveWeaponsButtonPressed")
callable(nil, "onQuestRewardButtonPressed")
callable(nil, "onResearchSatelliteButtonPressed")
callable(nil, "onResetMoneyButtonPressed")
callable(nil, "onResolveIntersectionsButtonPressed")
callable(nil, "onRespawnAsteroidsButtonPressed")
callable(nil, "onSearchAndRescueButtonPressed")
callable(nil, "onSetFreighterPlanPressed")
callable(nil, "onSetGatePlanPressed")
callable(nil, "onSmugglerRetaliationButtonPressed")
callable(nil, "onSpawnBattleButtonPressed")
callable(nil, "onSpawnBlockerButtonPressed")
callable(nil, "onSpawnCIWSButtonPressed")
callable(nil, "onSpawnCarrierButtonPressed")
callable(nil, "onSpawnDefendersButtonPressed")
callable(nil, "onSpawnDeferredBattleButtonPressed")
callable(nil, "onSpawnDisruptorButtonPressed")
callable(nil, "onSpawnFlagshipButtonPressed")
callable(nil, "onSpawnFleetButtonPressed")
callable(nil, "onSpawnFreighterButtonPressed")
callable(nil, "onSpawnGuardianButtonPressed")
callable(nil, "onSpawnMilitaryShipButtonPressed")
callable(nil, "onSpawnMinerButtonPressed")
callable(nil, "onSpawnPersecutorButtonPressed")
callable(nil, "onSpawnScientistButtonPressed")
callable(nil, "onSpawnSmugglerButtonPressed")
callable(nil, "onSpawnSwoksButtonPressed")
callable(nil, "onSpawnThe4ButtonPressed")
callable(nil, "onSpawnTheAIButtonPressed")
callable(nil, "onSpawnTorpedoBoatButtonPressed")
callable(nil, "onSpawnTraderButtonPressed")
callable(nil, "onSpawnXsotanCarrierButtonPressed")
callable(nil, "onSpawnXsotanSquadButtonPressed")
callable(nil, "onStartFighterButtonPressed")
callable(nil, "onSystemUpgradeButtonPressed")
callable(nil, "onSystemsButtonPressed")
callable(nil, "onTitlePressed")
callable(nil, "onTouchAllObjectsButtonPressed")
callable(nil, "onTraderAttackedByPiratesButtonPressed")
callable(nil, "onTransformTurretsPressed")
callable(nil, "removeEntityScript")
callable(nil, "removePlayerScript")
callable(nil, "removeSectorScript")
callable(nil, "sendEntityScripts")
callable(nil, "sendPlayerScripts")
callable(nil, "sendSectorScripts")
callable(nil, "setValue")
callable(nil, "syncDocks")
callable(nil, "syncValues")
callable(nil, "onEnergySuppressorButtonPressed")

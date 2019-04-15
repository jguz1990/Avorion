package.path = package.path .. ";data/scripts/lib/?.lua"
require ("defaultscripts")
require ("stringutility")
require ("utility")
require ("callable")
ShipFounding = require ("shipfounding")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ShipFounder
ShipFounder = {}

local nameTextBox = nil
local allianceCheckBox = nil
local feeLabel = nil
local materialsLabel = nil
local window = nil
local warningLabel = nil

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function ShipFounder.interactionPossible(playerIndex, option)
    local self = Entity()
    local player = Player(playerIndex)

    if self.factionIndex ~= player.index then return false end

    local craft = player.craft
    if craft == nil then return false end

    if self.index == craft.index then
        return true
    end

    return false, "Fly the craft to found a ship."%_t
end

function ShipFounder.getIcon()
    return "data/textures/icons/flying-flag.png"
end

-- create all required UI elements for the client side
function ShipFounder.initUI()

    local res = getResolution()
    local size = vec2(400, 300)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    window.caption = "Founding Ship"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Found Ship"%_t);

    local hsplit = UIHorizontalSplitter(Rect(size), 10, 10, 0.5)
    hsplit.bottomSize = 40

    -- button at the bottom
    local button = window:createButton(hsplit.bottom, "OK"%_t, "onFoundButtonPress");
    button.textSize = 14

    -- name & type
    local hsplit2 = UIHorizontalSplitter(hsplit.top, 10, 0, 0.6)
    local lister = UIVerticalLister(hsplit2.top, 10, 0)

    local label = window:createLabel(Rect(), "Enter the name of the ship:"%_t, 14);
    label.centered = true
    label.wordBreak = true

    lister:placeElementTop(label)

    nameTextBox = window:createTextBox(Rect(), "")
    nameTextBox.maxCharacters = 35
    nameTextBox:forbidInvalidFilenameChars()
    lister:placeElementTop(nameTextBox)

    local rect = lister.rect
    local vsplit = UIVerticalSplitter(lister.rect, 10, 10, 0.85)

    warningPicture = window:createPicture(vsplit.right, "data/textures/icons/hazard-sign.png")
    warningPicture.isIcon = true
    warningPicture.color = ColorRGB(1, 0, 0)
    warningPicture.tooltip = "WARNING: Having Many ships in many different sectors can cause lags, FPS drops and overall bad game performance.\nThis is highly dependent on your system."%_t

    allianceCheckBox = window:createCheckBox(Rect(), "Alliance Ship"%_t, "onAllianceCheckBoxChecked")
    allianceCheckBox.active = false
    allianceCheckBox.captionLeft = false
    lister:placeElementTop(allianceCheckBox)

    -- costs
    local lister = UIVerticalLister(hsplit2.bottom, 10, 0)
    local rect = lister:nextRect(20)
    local label = window:createLabel(rect, "Founding Fee (?)"%_t, 14);
    label:setLeftAligned()
    label.tooltip = "Every ship costs a founding fee. The more ships you own, the higher the fee."%_t

    feeLabel = window:createLabel(rect, "", 14);
    feeLabel:setRightAligned()

    local rect = lister:nextRect(16)
    local label = window:createLabel(rect, "Materials:"%_t, 14);
    label:setLeftAligned()

    materialsLabel = window:createLabel(rect, "", 14);
    materialsLabel:setRightAligned()

    window:createLine(hsplit2.top.bottomLeft, hsplit2.top.bottomRight)
end

function ShipFounder.onFoundButtonPress()
    name = nameTextBox.text
    invokeServerFunction("found", name, allianceCheckBox.checked)
end


function ShipFounder.foundShip(faction, player, name)

    local settings = GameSettings()
    if settings.maximumPlayerShips > 0 and faction.numShips >= settings.maximumPlayerShips then
        player:sendChatMessage("", 1, "Maximum ship limit per faction (%s) of this server reached!"%_t, settings.maximumPlayerShips)
        return
    end

    if faction:ownsShip(name) then
        player:sendChatMessage("", 1, "You already have a ship called '%s'."%_t, name)
        return
    end

    local money, resources = ShipFounding.getNextShipCosts(faction)

    local ok, msg, args = faction:canPay(money, unpack(resources))
    if not ok then
        player:sendChatMessage("", 1, msg, unpack(args))
        return
    end

    local args = {money = money}
    local material = Material()
    for i, amount in pairs(resources) do
        if amount > 0 then
            material = Material(i-1)
            args.amount = amount
            args.material = material.name
            break
        end
    end

    if money > 0 then
        faction:pay("Paid ${money} credits, ${amount} ${material} to found a ship."%_T % args, money, unpack(resources))
    else
        faction:pay("Paid ${money} credits, ${amount} ${material} to found a ship."%_T % args, money, unpack(resources))
    end

    local self = Entity()

    local plan = BlockPlan()
    plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, material.blockColor, material, Matrix(), BlockType.Hull)

    local ship = Sector():createShip(faction, name, plan, self.position);

    -- add base scripts
    AddDefaultShipScripts(ship)
    ship:addScriptOnce("insurance.lua")

    player.craft = ship

    return ship
end

function ShipFounder.onAllianceCheckBoxChecked()
    ShipFounder.refreshUI()
end

function ShipFounder.refreshUI()
    local money, resources
    local ships = 0

    local alliance = Player().alliance
    if allianceCheckBox.checked and alliance then
        money, resources, ships = ShipFounding.getNextShipCosts(alliance)
    else
        money, resources, ships = ShipFounding.getNextShipCosts(Player())
    end

    feeLabel.caption = createMonetaryString(money) .. " Cr"

    local amount = 500
    local material = Material(MaterialType.Naonite)

    for i, am in pairs(resources) do
        if am > 0 then
            amount = am
            material = Material(i-1)
            break
        end
    end

    materialsLabel.caption = "${amount} ${material}"%_t % {amount = amount, material = material.name}
    materialsLabel.color = material.color

    window.caption = "Founding Ship #${number}"%_t % {number = ships + 1}

    if ships + 1 >= 25 then
        warningPicture:show()
    else
        warningPicture:hide()
    end

end

function ShipFounder.onShowWindow()

    local alliance = Alliance()

    if alliance then
        allianceCheckBox.active = true
    else
        allianceCheckBox.checked = false
        allianceCheckBox.active = false
    end

    ShipFounder.refreshUI()
end

function ShipFounder.found(name, forAlliance)

    if anynils(name, forAlliance) then return end

    if Faction().index ~= callingPlayer then return end
    local player = Player(callingPlayer)

    if forAlliance then
        local alliance = player.alliance

        if not alliance then
            player:sendChatMessage("", 1, "You're not in an alliance."%_t)
            return
        end

        if not alliance:hasPrivilege(callingPlayer, AlliancePrivilege.FoundShips) then
            player:sendChatMessage("", 1, "You don't have permissions to found ships for your alliance."%_t)
            return
        end

        local ship = ShipFounder.foundShip(alliance, player, name)

        if ship then
            ship:addScriptOnce("entity/claimalliance.lua")
        end
    else
        ShipFounder.foundShip(player, player, name)
    end

end
callable(ShipFounder, "found")


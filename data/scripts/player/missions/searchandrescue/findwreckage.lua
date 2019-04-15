package.path = package.path .. ";data/scripts/lib/?.lua"

require("defaultscripts")
require("stringutility")
require("callable")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex)

    local player = Player(playerIndex)
    local self = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(self)

    if dist < 200 then
        return true
    end

    return false, "You're not close enough to search the object."%_t
end

function initUI()
    ScriptUI():registerInteraction("Search"%_t, "onInteract")
end

function onInteract(entityIndex)
    local ui = ScriptUI(entityIndex)
    if ui then
        ui:showDialog(makeDialog())
    end
end

function makeDialog()
    local d0_YouFoundSomeInf = {}

    d0_YouFoundSomeInf.text = "You found some information about the ship. You should bring it back their homesector."%_t
    d0_YouFoundSomeInf.answers = {
        {answer = "OK"%_t, onSelect = "nextPart"}
    }

    return d0_YouFoundSomeInf
end

function nextPart()
    if onClient() then
        invokeServerFunction("nextPart")
        return
    end
    Player(callingPlayer):invokeFunction("searchandrescue.lua", "nextPart")
    terminate()
    return
end
callable(nil, "nextPart")

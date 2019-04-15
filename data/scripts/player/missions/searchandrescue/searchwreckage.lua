package.path = package.path .. ";data/scripts/lib/?.lua"

require("defaultscripts")
require("stringutility")

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

function onInteract()
    ScriptUI():showDialog(makeDialog())
end

function makeDialog()
    local d0_NothingFoundHer = {}

    d0_NothingFoundHer.text = "Nothing found here."%_t
    d0_NothingFoundHer.answers = {
        {answer = "OK"%_t, onSelect = "finishScript"}
    }

    return d0_NothingFoundHer
end

function finishScript()
    terminate()
    return
end

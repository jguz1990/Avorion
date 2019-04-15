package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("stringutility")
require ("goods")
local DockAI = require ("entity/ai/dock")

local TradeUT = {}
local self = TradeUT

self.data = {}

function getUpdateInterval()
    return 1
end

function secure()
    return self.data
end

function restore(data)
    self.data = data
end

function TradeUT.onDockingOver(ship, msg)
    self.data.partner = nil
    DockAI.reset()
end

function TradeUT.updateDocking(timeStep, transaction)
    local station = nil
    if self.data.partner then
        station = Sector():getEntity(self.data.partner.id)
    end

    -- station must have been destroyed, reset
    if not station then
        self.data.partner = nil
        return
    else
        self.lastPartner = station.id.string
    end

    DockAI.updateDockingUndocking(timeStep, station, 10, transaction, TradeUT.onDockingOver)

    -- if all of this works, we can reset errors
    TradeUT.resetError()
end

function TradeUT.updateErrorHandling(timeStep)
    if not self.currentError then return end

    local maximum = 10 * 60

    self.notificationTimer = (self.notificationTimer or maximum) + timeStep
    self.lastError = self.lastError or ""

    local newError = self.lastError ~= self.currentError.text

    if self.notificationTimer > maximum or newError then
        self.notificationTimer = 0
        self.lastError = self.currentError.text

        if self.currentError.critical or not newError then
            -- notify whenever an error has been there for a while
            -- or when a critical error happens for the first time
            Faction():sendChatMessage("", ChatMessageType.Error, self.currentError.text, unpack(self.currentError.args))
        end
    end

    DockAI.reset()
end

function TradeUT.setSoftError(msg, ...)
    self.currentError = {text = msg, critical = false, args = {...}}
end

function TradeUT.setCriticalError(msg, ...)
    self.currentError = {text = msg, critical = true, args = {...}}
end

function TradeUT.resetError()
    self.currentError = nil
end

function getLastPartner()
    return self.lastPartner
end

function getLastError()
    return self.lastError
end

return TradeUT

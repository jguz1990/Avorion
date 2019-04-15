package.path = package.path .. ";data/scripts/lib/?.lua"
require ("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Icon
Icon = {}

local icon = ""

function Icon.initialize(value)
    Icon.set(value)

    if onClient() then
        Icon.sync()
    end
end

function Icon.sync(data)
    if onClient() then
        if data then
            Icon.set(data)
        else
            invokeServerFunction("sync")
        end
    elseif callingPlayer then
        invokeClientFunction(Player(callingPlayer), "sync", icon)
    end
end
callable(Icon, "sync")

function Icon.set(value)
    icon = value or ""

    if onClient() then
        EntityIcon().icon = icon
    else
        broadcastInvokeClientFunction("sync", icon)
    end
end

function Icon.secure()
    return {icon = icon}
end

function Icon.restore(data)
    icon = data.icon
end

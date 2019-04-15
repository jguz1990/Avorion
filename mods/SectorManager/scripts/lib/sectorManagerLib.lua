local lib = {}
-- parent: UIElement
-- size: Int
function lib.centerUIElementX(parent, size)
    return parent.size.x/2 - size, parent.size.x/2 + size
end

function lib.sectorListToString(sectorList)
    local str = ""
    for _,sector in ipairs(sectorList) do
        if type(sector.x) == "number" and type(sector.y) == "number" then
            str = str .. sector.x .. ":".. sector.y .. ","
        end
    end
    str = str:sub(1, -2)    -- remove last ','
    return str
end

function lib.stringToSectorList(str)
    str = str or ""
    local list = {}
    for s in string.gmatch(str, '([^,]+)') do
        local t = string.find(s, "([:])")
        list[#list+1] = {x = tonumber(string.sub(s, 1,t-1)), y = tonumber(string.sub(s, t+1))}
    end
    return list
end

return lib

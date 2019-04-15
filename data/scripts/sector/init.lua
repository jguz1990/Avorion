
if not onServer() then return end

local sector = Sector()

sector:addScriptOnce("sector/relationchanges.lua")
sector:addScriptOnce("sector/spawnpersecutors.lua")

if onServer() then

function initialize()

end

function getUpdateInterval()
  return 1
end

function updateServer(timestep)
    print("I'm alive", Sector():getCoordinates())
end

end

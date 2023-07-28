local Globals = {}

--- This is the real time delta, adding up to 48/s
Globals.multiplier = 0
Globals.deltaMinutesPerDay = 0
--- This is the multiplier adjusted for the day length.
--- Note that this is NOT centered around 1 hour days, but 30 minute days. This means that the default is half the multiplier.
Globals.delta = 0
Globals.statsDecreaseMultiplier = 1
Globals.gameWorldSecondsSinceLastUpdate = 0
Globals.FPSMultiplier = 0
Globals.lastTimeOfDay = 0
Globals.timeOfDay = 0

-- EvenPaused because it fires before player stat calculations, OnTick fires after
-- unfortunately, GameTime updates after this, so we're technically always a frame behind, but it doesn't really matter
Events.OnTickEvenPaused.Add(function()
    Globals.multiplier = Globals.gameTime:getMultiplier()
    Globals.delta = Globals.multiplier * Globals.deltaMinutesPerDay
    Globals.statsDecreaseMultiplier = Globals.sandboxOptions:getStatsDecreaseMultiplier()
    Globals.gameWorldSecondsSinceLastUpdate = Globals.gameTime:getGameWorldSecondsSinceLastUpdate()
    Globals.FPSMultiplier = Globals.gameTime.FPSMultiplier -- this might seem unnecessary, but java field accesses are disguised method calls
    
    Globals.lastTimeOfDay = Globals.timeOfDay
    Globals.timeOfDay = Globals.gameTime:getTimeOfDay()
end)


Events.OnGameStart.Add(function()
    Globals.sandboxOptions = getSandboxOptions()
end)

Events.OnGameTimeLoaded.Add(function()
    Globals.gameTime = getGameTime()
    Globals.deltaMinutesPerDay = Globals.gameTime:getDeltaMinutesPerDay()
end)

return Globals
local Globals = {}

Globals.multiplier = 0
Globals.deltaMinutesPerDay = 0
Globals.delta = 0
Globals.statsDecreaseMultiplier = 1

-- EvenPaused because it fires before player stat calculations, OnTick fires after
-- unfortunately, GameTime updates after this, so we're technically always a frame behind, but it doesn't really matter
Events.OnTickEvenPaused.Add(function()
    Globals.multiplier = Globals.gameTime:getMultiplier()
    Globals.deltaMinutesPerDay = Globals.gameTime:getDeltaMinutesPerDay()
    Globals.delta = Globals.multiplier * Globals.deltaMinutesPerDay
    Globals.statsDecreaseMultiplier = Globals.sandboxOptions:getStatsDecreaseMultiplier()
end)


Events.OnGameStart.Add(function()
    Globals.sandboxOptions = getSandboxOptions()
end)

Events.OnGameTimeLoaded.Add(function()
    Globals.gameTime = getGameTime()
end)

return Globals
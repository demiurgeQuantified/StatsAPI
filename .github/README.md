# StatsAPI
[Visit on the Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2997722072)

A Lua reimplementation of Project Zomboid's stat calculations, finally allowing modders to modify them easily.
While its feature set is currently small, the goal of this project is to evolve with the needs of modders, so feel free
to open feature requests on the [issues page](https://github.com/demiurgeQuantified/StatsAPI/issues).
## API
The API allows for traits that affect certain stat calculations.
The below example is how the Vanilla traits would look if they were implemented using the API.
```lua
local StatsAPI = require "StatsAPI/StatsAPI"

StatsAPI.addTraitHungerModifier("HeartyAppitite", 1.5)
StatsAPI.addTraitHungerModifier("LightEater", 0.75)

StatsAPI.addTraitThirstModifier("HighThirst", 2)
StatsAPI.addTraitThirstModifier("LowThirst", 0.5)

StatsAPI.addTraitFatigueModifier("NeedsLessSleep", 0.7, 0.75)
StatsAPI.addTraitFatigueModifier("NeedsMoreSleep", 1.3, 1.18)

StatsAPI.addTraitSleepModifier("NightOwl", 1.4)
StatsAPI.addTraitSleepModifier("Insomniac", 0.5)
```
Make sure to include the API as a dependency in your `mod.info`:
```
require=StatsAPI
```
You should also add the [Workshop item](https://steamcommunity.com/sharedfiles/filedetails/?id=2997722072) as a steam dependency. You can do this from the workshop page after uploading.
# StatsAPI
[Visit on the Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2997722072)

A Lua reimplementation of Project Zomboid's stat calculations and moodles, finally allowing modders to modify them easily.
The goal of this project is to evolve with the needs of modders, so feel free
to open feature requests on the [issues page](https://github.com/demiurgeQuantified/StatsAPI/issues).
## API
The API allows for traits that affect certain stat calculations.
Examples for how to use some parts of the API can be seen in the [vanilla](../Contents/mods/StatsAPI/media/lua/client/StatsAPI/vanilla/)
folder.

Make sure to include the API as a dependency in your `mod.info`:
```
require=StatsAPI
```
You should also add the [Workshop item](https://steamcommunity.com/sharedfiles/filedetails/?id=2997722072) as a steam dependency. You can do this from the workshop page after uploading.
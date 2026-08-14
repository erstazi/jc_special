local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

dofile(modpath .. "/daybutton.lua")
dofile(modpath .. "/welcomeplayers.lua")
dofile(modpath .. "/snowball.lua")

if core.get_modpath("homedecor") then
  dofile(modpath .. "/homedecor_overrides.lua")
  core.log("action", "[jc_special] homedecor overrides should have ran")
else
  core.log("action", "[jc_special] homedecor not loaded?")
end

dofile(modpath .. "/animalworld_cleanup.lua")
dofile(modpath .. "/misc_overrides.lua")
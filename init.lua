core.log("action", "[jc_special] INIT STARTED")

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

core.log("action", "[jc_special] modpath = " .. tostring(modpath))

dofile(modpath .. "/daybutton.lua")
dofile(modpath .. "/welcomeplayers.lua")
dofile(modpath .. "/snowball.lua")

core.log("action", "[jc_special] reached homedecor check")

-- if core.get_modpath("homedecor") then
  core.log("action", "[jc_special] homedecor FOUND")
  dofile(modpath .. "/homedecor_overrides.lua")
  core.log("action", "[jc_special] homedecor overrides should have ran")
-- else
  -- core.log("action", "[jc_special] homedecor NOT FOUND")
-- end

dofile(modpath .. "/animalworld_cleanup.lua")
dofile(modpath .. "/misc_overrides.lua")
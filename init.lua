local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

dofile(modpath .. "/daybutton.lua")
dofile(modpath .. "/welcomeplayers.lua")
dofile(modpath .. "/snowball.lua")

if core.get_modpath("homedecor") then
    dofile(modpath .. "/homedecor_overrides.lua")
end

dofile(modpath .. "/misc_overrides.lua")
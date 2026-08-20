local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

jc_special = {}

dofile(modpath .. "/daybutton.lua")
dofile(modpath .. "/welcomeplayers.lua")
dofile(modpath .. "/infotext.lua")
dofile(modpath .. "/cans.lua")
dofile(modpath .. "/snowball.lua")
dofile(modpath .. "/homedecor_overrides.lua")
dofile(modpath .. "/unified_inventory_overrides.lua")
dofile(modpath .. "/animalworld_cleanup.lua")
dofile(modpath .. "/misc_overrides.lua")
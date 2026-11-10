-- minimap.lua

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

function map.update_hud_flags(player)
  local minimap_enabled = player:get_inventory():contains_item("main", "map:mapping_kit")

  player:hud_set_flags({
    minimap = minimap_enabled,
    minimap_radar = minimap_enabled
  })
end

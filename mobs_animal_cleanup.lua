-- mobs_animal_cleanup.lua
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local function cleanupOldEntities(name)
  core.register_entity(":" .. name, {
    initial_properties = {
      physical = false,
      pointable = false,
      visual = "sprite",
      textures = {"blank.png"},
    },

    on_activate = function(self)
      core.log("action", "[" .. modpath .. " cleanup] Removing " .. name)
      self.object:remove()
    end,
  })
end


if core.get_modpath("mobs_animal") then
  local all_colours = {
    "black",
    "blue",
    "brown",
    "cyan",
    "dark_green",
    "dark_grey",
    "green",
    "grey",
    "magenta",
    "orange",
    "pink",
    "red",
    "violet",
    "white",
    "yellow",
  }

  for _, colour in ipairs(all_colours) do
    cleanupOldEntities("mobs_animal:sheep_" .. colour)
  end

  cleanupOldEntities("mobs_animal:kitten")
  cleanupOldEntities("mobs_animal:cow")
end

if core.get_modpath("mobs") and core.get_modpath("animalia") then
  core.register_alias("mobs:mutton_cooked", "animalia:mutton_cooked")
  core.register_alias("mobs:mutton_raw", "animalia:mutton_raw")
end
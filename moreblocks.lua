-- moreblocks.lua
local modname = core.get_current_modname()
local S = core.get_translator(modname)
local modpath = core.get_modpath(modname)

core.register_on_mods_loaded(function()
  if not core.get_modpath("moreblocks") then
    core.log("warning", "[" .. modname .. "] moreblocks mod not found")
    return
  end

  local nodes = {
    "default:dirt_with_grass",
    "default:dirt_with_rainforest_litter",
    "default:dirt_with_snow",
    "default:dirt_with_dry_grass",
    "default:dry_dirt",
    "default:dirt_with_coniferous_litter",
    "ethereal:dry_dirt",
    "ethereal:bamboo_dirt",
    "ethereal:jungle_dirt",
    "ethereal:grove_dirt",
    "ethereal:prairie_dirt",
    "ethereal:cold_dirt",
    "ethereal:crystal_dirt",
    "ethereal:mushroom_dirt",
    "ethereal:fiery_dirt",
    "ethereal:gray_dirt",
    "ethereal:magical_dirt",
  }

  for _, node_name in ipairs(nodes) do
    local def = core.registered_nodes[node_name]

    if def then
      local _, subname = node_name:match("^([^:]+):(.+)$")
      local groups = {}

      for name, value in pairs(def.groups or {}) do
        groups[name] = value
      end

      stairsplus:register_all("moreblocks", subname, node_name, {
        description = def.description,
        groups = groups,
        tiles = def.tiles,
        sunlight_propagates = def.sunlight_propagates,
        light_source = def.light_source,
        sounds = def.sounds,
      })
    end
  end
end)
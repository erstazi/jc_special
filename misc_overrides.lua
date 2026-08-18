-- misc_overrides.lua
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

core.register_on_mods_loaded(function()
  if carts then
    carts.speed_max = 10
    core.log("action", "[jc_special] Minecart speed set to " .. carts.speed_max)
  else
    core.log("warning", "[jc_special] carts mod not found")
  end
end)

local function get_mods_formspec()
  local mods = core.get_modnames()
  table.sort(mods)

  return
    "formspec_version[4]" ..
    "size[12,10]" ..
    "label[0.4,0.3; " .. core.formspec_escape( S("Loaded Mods") ) .. " (" .. #mods .. ")]" ..
    "textarea[0.4,0.8;11.2,8;;;" ..
    core.formspec_escape(table.concat(mods, ", ")) ..
    "]" ..
    "button_exit[4,9;4,0.8;close;" .. core.formspec_escape( S("Close") ) .. "]"
end

core.register_chatcommand("mods", {
  description = S("Show loaded mods"),
  func = function(name)
    core.show_formspec(name, "jc_special:mods", get_mods_formspec())
    return true
  end,
})


core.register_chatcommand("where", {
  params = "<player>",
  description = S("Shows the coordinates of a player."),
  privs = { server = true },

  func = function(name, param)
    local green = core.get_color_escape_sequence("#1eff00")
    local gold  = core.get_color_escape_sequence("#ffdf00")
    local white = core.get_color_escape_sequence("#ffffff")

    if param == "" then
      return false, gold .. S("Usage: /where <player>")
    end

    local player = core.get_player_by_name(param)
    if not player then
      return false, white .. S("Player @1 is not online.", param )
    end

    local pos = vector.round(player:get_pos())

    -- return true, string.format("%s is at %d,%d,%d", param, pos.x, pos.y, pos.z)
    -- return true, string.format("%s%s%s is at %s%d,%d,%d", green, param, white, gold, pos.x, pos.y, pos.z )
    return true, S("@1 is at @2",
        core.colorize("#55FF55", param),
        core.colorize("#FFD700", string.format("%d,%d,%d", pos.x, pos.y, pos.z))
      )
  end,
})

local old_shutdown = core.registered_chatcommands["shutdown"]
if old_shutdown then
  core.override_chatcommand("shutdown", {
    func = function(name, param)
      core.chat_send_player(name, S("The /shutdown command has been disabled on this server.") )
      core.log("action", "[SHUTDOWN BLOCKED] " .. name .. " attempted /shutdown")
      return true
    end
  })
end

if core.get_modpath("ethereal") then
  core.override_item("ethereal:jungle_dirt", {
    light_source = 4,
  })
end

if core.get_modpath("animalia") and core.get_modpath("creatura") then
  local ambient_spawn_chance_override = 18000
  creatura.register_abm_spawn("animalia:bat", {
    chance = ambient_spawn_chance_override,
    interval = 30,
    min_light = 0,
    max_light = 5,
    min_height = -31000,
    max_height = -30,
    min_group = 3,
    max_group = 5,
    spawn_cap = 6,
    nodes = {"default:stone"}
  })
end

if core.get_modpath("animalia") and core.get_modpath("creatura") then
  core.register_chatcommand("batcount", {
    description = S("Count Animalia bats"),
    privs = {server = true},
    func = function(name)
      local count = 0

      for _, object in ipairs(core.get_objects_inside_radius(
        core.get_player_by_name(name):get_pos(),
        31000
      )) do
        local ent = object:get_luaentity()
        if ent and ent.name == "animalia:bat" then
          count = count + 1
        end
      end

      return true, S("There are @1 Animalia bats nearby.", count)
    end,
  })

  core.register_chatcommand("batkill", {
    description = S("Remove all loaded Animalia bats"),
    privs = {server = true},
    func = function(name)
      local player = core.get_player_by_name(name)
      if not player then
        return false, S("Player not found.")
      end

      local count = 0

      for _, object in ipairs(core.get_objects_inside_radius(
        player:get_pos(),
        31000
      )) do
        local ent = object:get_luaentity()

        if ent and ent.name == "animalia:bat" then
          object:remove()
          count = count + 1
        end
      end

      return true, S("Removed @1 Animalia bats.", count)
    end,
  })
end


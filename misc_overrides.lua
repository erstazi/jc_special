-- misc_overrides.lua

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
    "label[0.4,0.3;Loaded Mods (" .. #mods .. ")]" ..
    "textarea[0.4,0.8;11.2,8;;;" ..
    core.formspec_escape(table.concat(mods, ", ")) ..
    "]" ..
    "button_exit[4,9;4,0.8;close;Close]"
end

core.register_chatcommand("mods", {
  description = "Show loaded mods",
  func = function(name)
    core.show_formspec(name, "jc_special:mods", get_mods_formspec())
    return true
  end,
})


core.register_chatcommand("where", {
  params = "<player>",
  description = "Shows the coordinates of a player.",
  privs = { server = true },

  func = function(name, param)
    local green = core.get_color_escape_sequence("#1eff00")
    local gold  = core.get_color_escape_sequence("#ffdf00")
    local white = core.get_color_escape_sequence("#ffffff")

    if param == "" then
      return false, gold .. "Usage: " .. white .. " /where " .. green .. "<player>"
    end

    local player = core.get_player_by_name(param)
    if not player then
      return false, white .. "Player " .. green .. param .. white .. " is not online."
    end

    local pos = vector.round(player:get_pos())

    -- return true, string.format("%s is at %d,%d,%d", param, pos.x, pos.y, pos.z)
    return true, string.format("%s%s%s is at %s%d,%d,%d", green, param, white, gold, pos.x, pos.y, pos.z )
  end,
})

local old_shutdown = core.registered_chatcommands["shutdown"]
if old_shutdown then
  core.override_chatcommand("shutdown", {
    func = function(name, param)
      core.chat_send_player(name, "The /shutdown command has been disabled on this server.")
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
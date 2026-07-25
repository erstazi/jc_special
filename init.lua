local S = core.get_translator(core.get_current_modname())

local day_button_pressed_sounds = {
  'day_button_pressed',
}

local function press_day_button(pos, node, puncher)
  -- Already pressed?
  if node.name == "jc_special:day_button_pressed" then
    return
  end
  -- Press the button in
  core.swap_node(pos, {name = "jc_special:day_button_pressed", param2 = node.param2, })

  -- Pop back out after half a second
  core.after(0.5, function(pos)
    local n = core.get_node(pos)
    if n.name == "jc_special:day_button_pressed" then
      core.swap_node(pos, {
        name = "jc_special:day_button",
        param2 = n.param2,
      })
      core.get_meta(pos):set_string("infotext", "Press to skip the night.")
    end
  end, vector.new(pos))

  local tod = core.get_timeofday()
  if tod < 0.291667 or tod > 0.791667 then
    core.set_timeofday(0.291667)
    core.sound_play(day_button_pressed_sounds[1], {
      pos = pos,
      gain = 1.0,
      max_hear_distance = 16,
    })
    core.chat_send_all(puncher:get_player_name() .. " skipped the night.")
  else
    core.sound_play("default_click", {
      pos = pos,
      gain = 0.7,
      max_hear_distance = 16,
    })
  end
end

core.register_node("jc_special:day_button", {
  description = S("Day Button"),
  tiles = {
    "jc_special_day_button.png",
  },
  light_source = 6,
  groups = {
    cracky = 2,
    not_in_creative_inventory = 1,
  },
  sounds = default.node_sound_stone_defaults(),
  on_punch = press_day_button,
  after_place_node = function(pos)
    core.get_meta(pos):set_string("infotext", "Press to skip the night.")
  end,
})

core.register_node("jc_special:day_button_pressed", {
  description = S("Day Button"),
  tiles = {
    "jc_special_day_button_pressed.png",
  },
  drop = "jc_special:day_button",
  light_source = 8,
  groups = {
    cracky = 2,
    not_in_creative_inventory = 1,
  },
  sounds = default.node_sound_stone_defaults(),
})

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

local greet_enabled = false
local join_queue = {}

core.register_chatcommand("greet", {
  params = "on | off",
  description = "Enable or disable join greeter",
  privs = {server = true},
  func = function(name, param)
    if name ~= "erstazi" then
      return false, "Not allowed."
    end

    if param == "on" then
      greet_enabled = true
      return true, "Join greeter enabled"
    elseif param == "off" then
      greet_enabled = false
      return true, "Join greeter disabled"
    else
      return false, "Use: /greet on | off"
    end
  end
})

local new_players = {}

core.register_on_newplayer(function(player)
  local new_name = player:get_player_name()
  new_players[new_name] = true

  -- Notify staff
  core.after(2, function()
    for _, p in ipairs(core.get_connected_players()) do
      local staff_name = p:get_player_name()
      if core.check_player_privs(staff_name, {ban = true}) then
        core.chat_send_player(staff_name,
          core.colorize("#00FF00", "*** NEW PLAYER: " .. new_name .. " has joined the server for the first time. Information about apartments already sent to new player."))
      end
    end
  end)

  core.after(2, function()
    local p = core.get_player_by_name(new_name)
    if not p then
      new_players[new_name] = nil
      return
    end

    core.chat_send_player(new_name, core.colorize("#00FF88", "======================================================="))
    core.chat_send_player(new_name, core.colorize("#FFFF00", "Welcome to the Just-Craft server, " .. new_name .. "!"))
    core.chat_send_player(new_name, "")
    core.chat_send_player(new_name, core.colorize("#88FF88", "Type: ") .. core.colorize("#FFFF00", "/apt") .. core.colorize("#88FF88", " to get your free apartment!") )
    core.chat_send_player(new_name, core.colorize("#00FF88", "======================================================="))

    core.sound_play("welcome_stranger", {
      to_player = new_name,
      gain = 1.0,
    })
    new_players[new_name] = nil
  end)
end)

core.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  core.after(1, function()
    if not core.get_player_by_name(name) then
      return
    end

    core.sound_play("welcome", {
      gain = 1.0,
      exclude_player = name,
    })

    if not new_players[name] then
      core.sound_play("glockenspiel", {
        to_player = name,
        gain = 1.0,
      })
    end
  end)
end)

local welcome_sounds = {
  welcome = true,
  glockenspiel = true,
  welcome_stranger = true,
}

core.register_chatcommand("welcome_sound", {
  params = "[welcome|glockenspiel|welcome_stranger]",
  description = "Play a welcome sound for all connected players.",
  privs = {ban = true},

  func = function(name, param)
    param = (param or ""):trim()

    if param == "" then
      return true,
        "Available sounds: welcome, glockenspiel, welcome_stranger\n" ..
        "Usage: /welcome_sound <sound>"
    end

    if not welcome_sounds[param] then
      return false,
        "No sounds found with that name.\n" ..
        "Available: welcome, glockenspiel, welcome_stranger"
    end

    core.sound_play(param, {
      gain = 1.0,
    })

    core.log("action", name .. " played welcome sound: " .. param)

    return true,
      "Playing '" .. param .. "' for all connected players."
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

-- core.register_on_joinplayer(function(player)
  -- local name = player:get_player_name()

  -- if not greet_enabled then
    -- return
  -- end

  -- if name == "erstazi" then
    -- return
  -- end

  -- table.insert(join_queue, {
    -- target = "erstazi",
    -- guest = name,
    -- t = os.time()
  -- })
-- end)

-- core.register_globalstep(function(dtime)
  -- if not greet_enabled then
    -- return
  -- end

  -- for i = #join_queue, 1, -1 do
    -- local entry = join_queue[i]

    -- if os.time() - entry.t >= 3 then
      -- local target = core.get_player_by_name(entry.target)

      -- if target then
        -- core.chat_send_player(entry.target, "hi " .. entry.guest)
      -- end

      -- table.remove(join_queue, i)
    -- end
  -- end
-- end)
local S = core.get_translator(core.get_current_modname())

local day_button_pressed_sounds = {
  'day_button_pressed',
}

-- core.register_node("jc_special:day_button", {
  -- description = S("Day Button"),
  -- tiles = {
    -- "default_wood.png^default_mese_crystal.png",
  -- },
  -- groups = {
    -- choppy = 2,
    -- oddly_breakable_by_hand = 2,
    -- not_in_creative_inventory = 1,
  -- },
  -- sounds = default.node_sound_wood_defaults(),

  -- on_punch = function(pos, node, puncher)
    -- local tod = core.get_timeofday()

    -- if tod < 0.291667 or tod > 0.791667 then
      -- core.set_timeofday(0.291667)

      -- core.sound_play("default_place_node_hard", {
        -- pos = pos,
        -- gain = 1.0,
        -- max_hear_distance = 16,
      -- })

      -- core.chat_send_all(puncher:get_player_name() .. " skipped the night.")
    -- end
  -- end,
  -- after_place_node = function(pos, placer)
    -- local meta = minetest.get_meta(pos);
    -- meta:set_string("infotext",  "OOO I AM SO SCARED!!! MAKE IT DAY");
  -- end,
-- })

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

minetest.register_chatcommand("greet", {
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

-- minetest.register_on_joinplayer(function(player)
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

-- minetest.register_globalstep(function(dtime)
  -- if not greet_enabled then
    -- return
  -- end

  -- for i = #join_queue, 1, -1 do
    -- local entry = join_queue[i]

    -- if os.time() - entry.t >= 3 then
      -- local target = minetest.get_player_by_name(entry.target)

      -- if target then
        -- minetest.chat_send_player(entry.target, "hi " .. entry.guest)
      -- end

      -- table.remove(join_queue, i)
    -- end
  -- end
-- end)
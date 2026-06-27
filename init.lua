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
local S = core.get_translator(core.get_current_modname())

core.register_node("jc_special:day_button", {
  description = S("Day Button"),
  tiles = {
    "default_wood.png^default_mese_crystal.png",
  },
  groups = {
    choppy = 2,
    oddly_breakable_by_hand = 2,
    not_in_creative_inventory = 1,
  },
  sounds = default.node_sound_wood_defaults(),

  on_punch = function(pos, node, puncher)
    local tod = core.get_timeofday()

    -- Only allow at night (approximately 7 PM to 7 AM)
    if tod < 0.291667 or tod > 0.791667 then
      core.set_timeofday(0.291667) -- 07:00

      core.sound_play("default_place_node_hard", {
        pos = pos,
        gain = 1.0,
        max_hear_distance = 16,
      })

      core.chat_send_all(puncher:get_player_name() .. " skipped the night.")
    end
  end,
  after_place_node = function(pos, placer)
    local meta = minetest.get_meta(pos);
    meta:set_string("infotext",  "OOO I AM SO SCARED!!! MAKE IT DAY");
  end,
})

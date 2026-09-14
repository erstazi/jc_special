-- stadium_seats.lua

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local cushion_alt_players = {
  crisdan = true,
  erstazi = true,
  MrPhil = true,
  iisu = true,
  talamh = true,
  istie = true,
}

local cushion_cycles = {}

local function stadium_seat_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker:is_player() then
    return itemstack
  end

  local was_attached = clicker:get_attach()

  local result = lrfurn.sit(pos, node, clicker, itemstack, pointed_thing, 1)

  local is_attached = clicker:get_attach()
  local name = clicker:get_player_name()

  if not core.settings:get_bool("jc_special_stadium_seat_sounds", true) then
    return result
  end

  if not was_attached and is_attached then
    if cushion_alt_players[name] then
      cushion_cycles[name] = (cushion_cycles[name] or 0) + 1

      if cushion_cycles[name] % 3 == 1 then
        core.sound_play("chair_cushion_down_alt", {
          pos = pos,
          gain = 1.0,
          max_hear_distance = 20,
        })
      else
        core.sound_play("chair_cushion_down", {
          pos = pos,
          gain = 0.2,
          max_hear_distance = 20,
        })
      end
    else
      core.sound_play("chair_cushion_down", {
        pos = pos,
        gain = 0.2,
        max_hear_distance = 20,
      })
    end
  elseif was_attached and not is_attached then
    core.sound_play("chair_cushion_up", {
      pos = pos,
      gain = 0.2,
      max_hear_distance = 20,
    })
  end

  return result
end

local colors_table_stadium_seat_general = {
  {"white",      S("General Stadium Seat (White)") },
  {"grey",       S("General Stadium Seat (Grey)") },
  {"dark_grey",  S("General Stadium Seat (Dark Grey)") },
  {"black",      S("General Stadium Seat (Black)") },
  {"violet",     S("General Stadium Seat (Violet)") },
  {"blue",       S("General Stadium Seat (Blue)") },
  {"cyan",       S("General Stadium Seat (Cyan)") },
  {"dark_green", S("General Stadium Seat (Dark Green)") },
  {"green",      S("General Stadium Seat (Green)") },
  {"yellow",     S("General Stadium Seat (Yellow)") },
  {"brown",      S("General Stadium Seat (Brown)") },
  {"orange",     S("General Stadium Seat (Orange)") },
  {"red",        S("General Stadium Seat (Red)") },
  {"magenta",    S("General Stadium Seat (Magenta)") },
  {"pink",       S("General Stadium Seat (Pink)") },
}

for _, color_item in ipairs(colors_table_stadium_seat_general) do
  local color = color_item[1]
  local description_name = color_item[2]

  core.register_node("jc_special:stadium_seat_general_" .. color, {
    description = description_name,
    drawtype = "mesh",
    mesh = "stadium_seat.obj",
    tiles = {
      "jc_special_seat_leg_black.png",
      "wool_white.png",
      "wool_" .. color .. ".png",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    groups = {
    choppy = 2,
    oddly_breakable_by_hand = 2,
    furniture = 1,
    },
    collision_box = {
      type = "fixed",
      fixed = {-0.34, -0.52, -0.40, 0.34, 0.52, 0.40},
    },
    selection_box = {
      type = "fixed",
      fixed = {-0.34, -0.52, -0.40, 0.34, 0.52, 0.40},
    },
    on_rightclick = stadium_seat_rightclick,
    on_destruct = lrfurn.on_seat_destruct,
  })
end

local colors_table_dugout_seat = {
  {"white",      S("Dugout Seat (White)") },
  {"grey",       S("Dugout Seat (Grey)") },
  {"dark_grey",  S("Dugout Seat (Dark Grey)") },
  {"black",      S("Dugout Seat (Black)") },
  {"violet",     S("Dugout Seat (Violet)") },
  {"blue",       S("Dugout Seat (Blue)") },
  {"cyan",       S("Dugout Seat (Cyan)") },
  {"dark_green", S("Dugout Seat (Dark Green)") },
  {"green",      S("Dugout Seat (Green)") },
  {"yellow",     S("Dugout Seat (Yellow)") },
  {"brown",      S("Dugout Seat (Brown)") },
  {"orange",     S("Dugout Seat (Orange)") },
  {"red",        S("Dugout Seat (Red)") },
  {"magenta",    S("Dugout Seat (Magenta)") },
  {"pink",       S("Dugout Seat (Pink)") },
}

for _, color_item in ipairs(colors_table_dugout_seat) do
  local color = color_item[1]
  local description_name = color_item[2]

  core.register_node("jc_special:dugout_seat_" .. color, {
    description = description_name,
    drawtype = "mesh",
    mesh = "dugout_seat.obj",
    tiles = {
      "jc_special_seat_leg_black.png",
      "wool_" .. color .. ".png",
      "wool_" .. color .. ".png",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    groups = {choppy = 2, oddly_breakable_by_hand = 2, furniture = 1},
    collision_box = {
      type = "fixed",
      fixed = {-0.32, -0.55, -0.36, 0.32, 0.55, 0.36},
    },
    selection_box = {
      type = "fixed",
      fixed = {-0.32, -0.55, -0.36, 0.32, 0.55, 0.36},
    },
    on_rightclick = stadium_seat_rightclick,
    on_destruct = lrfurn.on_seat_destruct,
  })
end
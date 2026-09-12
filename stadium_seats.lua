-- stadium_seats.lua

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

for _, dye in ipairs(dye.dyes) do
  local color = dye[1]
  local color_name = dye[2]

  core.register_node("jc_special:stadium_seat_general_" .. color, {
    description = S("General Stadium Seat (@1)", color_name),
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
    add_properties = {
      seat_data = {
        pos = vector.new(0, -0.05, 0),
        rot = vector.new(0, 0, 0),
        model = multidecor.sitting.standard_model,
        anims = {"sit1", "sit2"},
      },
    },
    on_construct = multidecor.sitting.on_construct,
    on_destruct = multidecor.sitting.on_destruct,
    on_rightclick = multidecor.sitting.on_rightclick,
  })
end

for _, dye in ipairs(dye.dyes) do
  local color = dye[1]
  local color_name = dye[2]

  core.register_node("jc_special:dugout_seat_" .. color, {
    description = S("Dugout Seat (@1)", color_name),
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
    add_properties = {
      seat_data = {
        pos = vector.new(0, -0.14, 0),
        rot = vector.new(0, 0, 0),
        model = multidecor.sitting.standard_model,
        anims = {"sit1", "sit2"},
      },
    },
    on_construct = multidecor.sitting.on_construct,
    on_destruct = multidecor.sitting.on_destruct,
    on_rightclick = multidecor.sitting.on_rightclick,
  })
end
-- mobs/rhino.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- RHINO
----------------------------------------------------------------

monsterDefinitions.rhino = {
  name = "mobs_monster:rhino",
  type = "monster",
  description = "Rhino",
  alias = "mobs:rhino",
  nametag = false,
  nametag_color = "#808080",

  damage = 2,
  rainbow_damage = 7,

  hp_min = 22,
  hp_max = 22,
  armor = 60,
  visual_size = {x = 1, y = 1},
  -- collisionbox = {
    -- -0.4, -0.01, -0.4,
     -- 0.4,  1.9,   0.4,
  -- },
  collisionbox = {
    -0.3, -1, -0.3,
     0.3,  0.8,  0.3,
  },
  texture = "mobs_rhino.png",
  -- mesh = "mobs_sand_monster.x",
  mesh = "character.b3d",

  egg_texture = "mobs_rhino.png",

  stepheight = 1.6,
  walk_velocity = 1.2,
  run_velocity = 2,
  jump_height = 4,
  view_range = 12,
  lava_damage = 8,
  light_damage = 1,
  lifetimer = 300,

  attack_type = "shoot",
  passive = false,
  attack_players = true,
  attack_npcs = true,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = false,

  animation = {
    speed_normal = 25,
    speed_run = 45,

    stand_start = 0,
    stand_end = 39,

    walk_start = 41,
    walk_end = 72,

    run_start = 74,
    run_end = 105,

    punch_start = 74,
    punch_end = 105,
  },

  drops = {
    { name = "animalia:feather", chance = 4, min = 1, max = 5, },
    { name = "default:steel_ingot", chance = 1, min = 10, max = 10, },
  },

  mob_properties = {
    arrow = "jc_special:rhino_bullet",
    shoot_interval = 0.5,
    shoot_offset = 1,

    sounds = {
      attack = "mobs_bullet",
    },
  },
}
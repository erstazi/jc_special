-- mobs/zombie.lua
--
-- Zombies adapted from the standalone "zombies" mod for jc_special.
-- The three variants use the shared Monster registration framework.
--
-- Original texture attribution and license are preserved in
-- licenses/zombies-license.txt.

local zombie_textures = {
  {"zombie01.png"},
  {"zombie02.png"},
  {"zombie03.png"},
  {"zombie04.png"},
}

local zombie_drops = {
  {name = "bonemeal:bone", chance = 1, min = 3, max = 25},
  {name = "default:dirt", chance = 2, min = 3, max = 5},
  {name = "default:apple", chance = 4, min = 2, max = 5},
  {name = "default:clay_lump", chance = 10, min = 1, max = 4},
  {name = "bonemeal:bone_block", chance = 15, min = 1, max = 5},
  {name = "bones:bones", chance = 2, min = 1, max = 1},
}

-- Keep the original spawn locations and settings.
local zombie_spawn = {
  nodes = {
    "cityscape:road_broken",
    "cityscape:sidewalk_broken",
    "default:gravel",
    "steles:desert_stone_stele",
    "steles:sandstone_stele",
    "steles:stone_stele",
  },
  max_light = 7,
  min_light = 0,
  chance = 70,
  active_object_count = 3,
  max_height = 170,
  day_toggle = false,
}

local zombie_sounds = {
  attack = {
    "zombies_attack_01",
    "zombies_attack_02",
    "zombies_attack_03",
  },
}

local zombie_random_sounds = {
  enabled = true,
  sounds = {
    "zombies_sound_01",
    "zombies_sound_02",
    "zombies_sound_03",
    "zombies_sound_04",
    "zombies_sound_05",
    "zombies_sound_06",
  },
  gain = 0.5,
  interval_min = 3,
  interval_max = 10,
}

----------------------------------------------------------------
-- ONE-ARMED ZOMBIE
----------------------------------------------------------------
monsterDefinitions.zombie_1arm = {
  name = "jc_special:zombie_1arm",
  aliases = {"zombies:1arm"},
  description = "One-Armed Zombie",

  type = "monster",
  passive = false,
  attack_type = "dogfight",
  damage = 2,
  hp_min = 3,
  hp_max = 15,
  armor = 80,
  reach = 2,
  nametag = false,

  collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
  mesh = "zombie_one-arm.b3d",
  textures = zombie_textures,
  texture = "zombie01.png",
  egg_texture = "zombie01.png",

  makes_footstep_sound = true,
  walk_velocity = 2,
  run_velocity = 4,
  view_range = 15,
  lava_damage = 5,

  animation = {
    speed_normal = 10,
    speed_run = 10,
    punch_speed = 20,
    walk_start = 0,
    walk_end = 20,
    run_start = 0,
    run_end = 20,
    punch_start = 21,
    punch_end = 51,
  },

  sounds = zombie_sounds,
  random_sounds = zombie_random_sounds,
  drops = zombie_drops,
  spawn = zombie_spawn,

  mob_properties = {
    pathfinding = true,
    jump = true,
    blood_texture = "default_wood.png",
    light_damage = 4,
    light_damage_min = 11,
    light_damage_max = 15,
    fall_damage = 2,
  },
}

----------------------------------------------------------------
-- CRAWLER ZOMBIE
----------------------------------------------------------------
monsterDefinitions.zombie_crawler = {
  name = "jc_special:zombie_crawler",
  aliases = {"zombies:crawler"},
  description = "Crawler Zombie",

  type = "monster",
  passive = false,
  attack_type = "dogfight",
  damage = 1,
  hp_min = 1,
  hp_max = 10,
  armor = 80,
  reach = 2,
  nametag = false,

  collisionbox = {-0.5, -0.5, -0.4, 0.5, 0.2, 0.4},
  mesh = "zombie_crawler.b3d",
  textures = zombie_textures,
  texture = "zombie01.png",
  egg_texture = "zombie01.png",

  makes_footstep_sound = true,
  walk_velocity = 0.5,
  run_velocity = 1,
  view_range = 15,
  lava_damage = 5,

  animation = {
    speed_normal = 10,
    speed_run = 10,
    punch_speed = 60,
    walk_start = 0,
    walk_end = 40,
    run_start = 0,
    run_end = 40,
    punch_start = 41,
    punch_end = 71,
  },

  sounds = zombie_sounds,
  random_sounds = zombie_random_sounds,
  drops = zombie_drops,
  spawn = zombie_spawn,

  mob_properties = {
    pathfinding = true,
    jump = true,
    blood_texture = "default_wood.png",
    light_damage = 4,
    light_damage_min = 11,
    light_damage_max = 15,
    fall_damage = 2,
  },
}

----------------------------------------------------------------
-- NORMAL ZOMBIE
----------------------------------------------------------------
monsterDefinitions.zombie_normal = {
  name = "jc_special:zombie_normal",
  aliases = {"zombies:normal"},
  description = "Normal Zombie",

  type = "monster",
  passive = false,
  attack_type = "dogfight",
  damage = 1,
  hp_min = 1,
  hp_max = 10,
  armor = 80,
  reach = 2,
  nametag = false,

  collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
  mesh = "zombie_normal.b3d",
  textures = zombie_textures,
  texture = "zombie01.png",
  egg_texture = "zombie01.png",

  makes_footstep_sound = true,
  walk_velocity = 2,
  run_velocity = 4,
  view_range = 15,
  lava_damage = 5,

  animation = {
    speed_normal = 20,
    speed_run = 20,
    punch_speed = 20,
    stand_start = 0,
    stand_end = 40,
    walk_start = 41,
    walk_end = 101,
    run_start = 41,
    run_end = 101,
    punch_start = 102,
    punch_end = 142,
  },

  sounds = zombie_sounds,
  random_sounds = zombie_random_sounds,
  drops = zombie_drops,
  spawn = zombie_spawn,

  mob_properties = {
    pathfinding = true,
    jump = true,
    blood_texture = "default_wood.png",
    light_damage = 4,
    light_damage_min = 11,
    light_damage_max = 15,
    fall_damage = 2,
  },
}

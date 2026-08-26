if not core.get_modpath("mobs") then
  core.log("warning", "[jc_special] mobs_redo not found, Trooper not registered.")
  return
end

local S = core.get_translator(core.get_current_modname())

-- mobs_monster_trooper.lua
-- Trooper mob originally from carbone_mobs.
-- Reimplemented for mobs_redo through jc_special.
local trooper_names = {
  "Trooper",
  "Bob",
  "Steve",
  "Gary",
  "Frank",
  "Private",
  "Sgt. Jenkins",
  "Dave",
  "Clint",
  "Chuck",
  "Fred",
  "Johnson",
  "Peter Johnson",
  "Wilson",
  "Smith",
  "Will Smith",
  "Nobody",
  "Definitely Not A Trooper",
  "Private Parts",
  "General Kenobi",
  "Captain Obvious",
  "Major Payne",
  "Corporal Punishment",
  "Sergeant Pepper",
  "Private Ryan",
  "General Failure",
  "Captain Crunch",
  "Major Tom",
  "Lieutenant Dan",
  "Colonel Mustard",
  "Admiral Ackbar",
  "Private Benjamin",
  "Sgt. Rock",
  "Officer Friendly",
  "The Other Bob",
  "Bob #2",
  "Definitely Bob",
  "Probably Steve",
  "Probably Sam",
  "Not The Real Steve",
  "Not The Real Sam",
  "The Real Sam",
  "Some Guy",
  "That One Guy",
  "Lennie Small",
  "Who Hired Me?",
}

local function trooper_group_attack(self, hitter)
  if not hitter or not hitter:is_player() then
    return
  end

  local pos = self.object:get_pos()
  if not pos then
    return
  end

  local radius = 20

  self.attack = hitter
  self.state = "attack"
  self.timer = 0

  -- Alert all nearby Troopers.
  for _, object in ipairs(core.get_objects_inside_radius(pos, radius)) do
    local entity = object:get_luaentity()

    if entity
    and entity.name == "mobs_monster:trooper"
    and object ~= self.object then

      entity.attack = hitter
      entity.state = "attack"
      entity.timer = 0
    end
  end
end

mobs:register_mob("mobs_monster:trooper", {
  type = "monster",
  passive = true,
  attack_type = "dogfight",
  pathfinding = false,
  reach = 2,
  damage = 10,
  hp_min = 20,
  hp_max = 20,
  armor = 100,
  collisionbox = {-0.3, -1, -0.3, 0.3, 0.8, 0.3},
  visual = "mesh",
  mesh = "character.b3d",
  textures = {{"character.png"}},
  makes_footstep_sound = true,
  stepheight = 1.6,
  walk_velocity = 1,
  run_velocity = 4,
  jump_height = 4,
  view_range = 8,
  lava_damage = 8,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = true,

  animation = {
    speed_normal = 15,
    speed_run = 30,
    stand_start = 0, stand_end = 40,
    walk_start = 168, walk_end = 187,
    run_start = 168, run_end = 187,
    punch_start = 189, punch_end = 198
  },

  on_spawn = function(self)
    local name = trooper_names[math.random(#trooper_names)]
    self.trooper_name = name
    self.nametag = core.colorize("#FFFF00", name)
    return true
  end,

  do_punch = function(self, hitter)
    trooper_group_attack(self, hitter)
  end,

  do_custom = function(self, dtime)
    -- Forget dead player
    if self.attack and self.attack:is_player() and self.attack:get_hp() <= 0 then
      self.attack = nil
      self.state = "walk"
      self.timer = 0
    end

    return true
  end,

  drops = {
    {name = "mobs_monster:trooper", chance = 3, min = 1, max = 1}
  }
})

mobs:register_egg(
  "mobs_monster:trooper",
  S("Trooper"),
  "player.png",
  1
)

mobs:alias_mob("mobs:trooper", "mobs_monster:trooper")

if not mobs.custom_spawn_monster then
  mobs:spawn({
    name = "mobs_monster:trooper",
    nodes = {"moreblocks:checker_stone_tile"},
    min_light = 0,
    max_light = 15,
    chance = 5000,
    min_height = -2,
    max_height = 30
  })

end

core.register_on_dieplayer(function(player, reason)
  if not reason or not reason.object then
    return
  end

  local killer = reason.object
  local killer_entity = killer:get_luaentity()

  if not killer_entity then
    return
  end

  if killer_entity.name ~= "mobs_monster:trooper" then
    return
  end

  local player_name = player:get_player_name()
  local trooper_name = killer_entity.trooper_name or S("Trooper")
  local death_pos = player:get_pos()

  -- Play "oof" for everyone within 30 blocks of the death.
  if death_pos then
    core.sound_play("oof", {
      pos = death_pos,
      gain = 1.0,
      max_hear_distance = 30,
    })
  end

  -- Server-wide death message.
  core.chat_send_all(core.colorize("#FF7979", S("@1 was eliminated by @2!", player_name, trooper_name) ) )
end)

core.log("action", "[jc_special] Trooper registered with mobs_redo")
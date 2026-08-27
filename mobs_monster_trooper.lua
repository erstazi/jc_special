if not core.get_modpath("mobs") then
  core.log("warning", "[jc_special] mobs_redo not found, Trooper not registered.")
  return
end

local S = core.get_translator(core.get_current_modname())

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
local TROOPER_NORMAL_DAMAGE = 10
local TROOPER_RAINBOW_DAMAGE = 7

-- mobs_monster_trooper.lua
-- Trooper mob originally from carbone_mobs.
-- Reimplemented for mobs_redo through jc_special.
local trooper_names = {
  "Trooper",
  "Bob",
  "Bob's Lawyer",
  "Steve",
  "Gary",
  "Frank",
  "Frank's Accountant",
  "Frank's Cousin",
  "Definitely Not Frank",
  "Bob Ross",
  "Your Worst Enemy",
  "The Guy Who Punches Trees",
  "The Guy Who Never Punches Trees",
  "Dave",
  "Clint",
  "Chuck",
  "Fred",
  "Johnson",
  "Peter Johnson",
  "Wilson",
  "Smith",
  "Will Smith",
  "Michael Jackson",
  "Nobody",
  "Definitely Not A Trooper",
  "Private Parts",
  "Captain Obvious",
  "Sergeant Pepper",
  "Private Ryan",
  "Major Tom",
  "Lieutenant Dan",
  "Admiral Ackbar",
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
  "Definitely Human",
  "Probably Human",
  "Not A Robot",
  "Not A Villager",
  "Not A Mob",
  "The Last Guy",
  "The First Guy",
  "The Middle Guy",
  "The Backup Guy",
  "MrBackDoorMan",
  "Oprah",
  "DrPhil",
  "Totally Not MrPhil",
  "iisu's inner thoughts",
  "talamh's Dirt Man",
  "Istie Bistie",
  "Captain Nemo",
  "Scruffy",
  "not tilt",
  "Gumbo",
  "The Other Guy",
  "The Other Other Guy",
  "Guy From Somewhere",
  "Guy From Over There",
  "Guy From Around Here",
  "Guy I Found",
  "Guy I Met Once",
  "Guy Nobody Remembers",
  "Guy Who Was Here Yesterday",
  "Guy Who Just Showed Up",
  "Guy Who Should Not Be Here",
  "Your Wife's Boyfriend",
  "Your Wife's Other Boyfriend",
  "Your Wife's Other Other Boyfriend",
  "Your Wife's Lawyer",
  "Your Wife's Accountant",
  "Your Wife's Neighbor",
}

----------------------------------------------------------------
-- RAINBOW ARMOR / SHIELD DETECTION
----------------------------------------------------------------
local rainbow_armor_items = {
  ["rainbow_ore:rainbow_ore_helmet"] = true,
  ["rainbow_ore:rainbow_ore_chestplate"] = true,
  ["rainbow_ore:rainbow_ore_leggings"] = true,
  ["rainbow_ore:rainbow_ore_boots"] = true,
}

local function player_has_rainbow_armor(player)
  if not player or not player:is_player() then
    return false
  end

  if not armor or not armor.get_valid_player then
    core.log("warning",
      "[CASTLE GUARD] 3d_armor API not available")
    return false
  end

  local _, armor_inv = armor:get_valid_player(player, "3d_armor")

  if not armor_inv then
    core.log("warning",
      "[CASTLE GUARD] 3d_armor inventory not found for " ..
      player:get_player_name())
    return false
  end

  for i = 1, 6 do
    local stack = armor_inv:get_stack("armor", i)

    if not stack:is_empty() and rainbow_armor_items[stack:get_name()] then
      return true
    end
  end

  return false
end

local function trooper_group_attack(self, hitter)
  if not hitter
    or not hitter.is_player
    or not hitter:is_player() then
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
  damage = TROOPER_NORMAL_DAMAGE,
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
    if self.attack
      and self.attack.is_player
      and self.attack:is_player()
      and self.attack:get_hp() <= 0 then
      self.attack = nil
      self.state = "walk"
      self.timer = 0
    end

    return true
  end,

  --------------------------------------------------------------
  -- CUSTOM ATTACK
  --------------------------------------------------------------
  custom_attack = function(self, to_attack)
    local target = self.attack

    if not target or not target:is_player() then
      return false
    end

    local damage = TROOPER_NORMAL_DAMAGE

    if player_has_rainbow_armor(target) then
      damage = TROOPER_RAINBOW_DAMAGE
    end

    local hp = target:get_hp()

    target:set_hp(
      math.max(0, hp - damage),
      {
        type = "punch",
        from = self.object,
        direct = true,
      }
    )

    return false
  end,

  drops = {
    { name = "mobs_monster:trooper", chance = 5, min = 1, max = 1 },
    { name = "default:pick_steel", chance = 3, min = 1, max = 1 },
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
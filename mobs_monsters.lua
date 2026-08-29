----------------------------------------------------------------
-- JC_SPECIAL - MOBS_REDO MONSTERS
--
-- Unified mobs_redo monster registration.
--
-- Monsters are defined in the "monsterDefinitions" table below.
-- Common monster functionality is handled by Monster.
--
-- Currently:
--   - Castle Guard
--   - Trooper
--
----------------------------------------------------------------

if not core.get_modpath("mobs") then
  core.log("warning", "[jc_special] mobs_redo not found, monsters not registered.")
  return
end

local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- SHARED SETTINGS
----------------------------------------------------------------

local PLAYER_NAME_COLOR = "#FFFF00"

----------------------------------------------------------------
-- RAINBOW ARMOR
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
    return false
  end

  local _, armor_inv = armor:get_valid_player(player, "3d_armor")

  if not armor_inv then
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

----------------------------------------------------------------
-- MONSTER REGISTRY
----------------------------------------------------------------

local registered_monsters = {}

----------------------------------------------------------------
-- LAST ATTACKERS
--
-- Indexed by player name.
--
-- This is shared by every monster instead of having one table
-- per monster.
----------------------------------------------------------------

local last_attackers = {}

----------------------------------------------------------------
-- MONSTER SOUND SETTINGS
----------------------------------------------------------------

core.register_chatcommand("jc_special_sounds_monsters", {
  params = "<on|off>",
  description = S("Enable or disable monster sounds."),

  func = function(name, param)
    local player = core.get_player_by_name(name)

    if not player then
      return false, S("Player not found.")
    end

    local meta = player:get_meta()

    param = param:lower()

    if param == "off" then
      meta:set_string("jc_special_sounds_monsters", "off")
      monster_sounds_storage:set_string("disabled:" .. name, "off")
      core.log("action", "[JC_SPECIAL MONSTER SOUNDS] " .. name .. " turned _OFF_ monster sounds")
      return true, S("Monster sounds disabled.")
    elseif param == "on" then
      meta:set_string("jc_special_sounds_monsters", "on")
      monster_sounds_storage:set_string( "disabled:" .. name, "" )
      core.log("action", "[JC_SPECIAL MONSTER SOUNDS] " .. name .. " turned ON monster sounds" )
      return true, S("Monster sounds enabled.")
    end

    return false, S("Usage: /jc_special_sounds_monsters <on|off>")
  end,
})

----------------------------------------------------------------
-- LIST PLAYERS WITH MONSTER SOUNDS DISABLED
----------------------------------------------------------------
core.register_chatcommand("list_jc_special_sounds_monsters", {
  params = "",
  description = S("List players who have monster sounds disabled."),
  privs = {
    server = true,
  },

  func = function(name, param)
    local disabled_players = {}

    local keys = monster_sounds_storage:get_keys()

    for _, key in ipairs(keys) do
      if key:sub(1, 9) == "disabled:" then
        local player_name = key:sub(10)

        if monster_sounds_storage:get_string(key) == "off" then
          table.insert(disabled_players, player_name)
        end
      end
    end

    table.sort(disabled_players)

    if #disabled_players == 0 then
      return true, S("No players have monster sounds disabled.")
    end

    core.chat_send_player(name, core.colorize(PLAYER_NAME_COLOR, S("Players with monster sounds disabled (@1):", #disabled_players ) ) )

    for _, player_name in ipairs(disabled_players) do
      core.chat_send_player(name, "  " .. core.colorize("#FEC0C0", player_name) )
    end

    return true
  end,
})

----------------------------------------------------------------
-- MONSTER HELPER METHODS
----------------------------------------------------------------
local Monster = {}

----------------------------------------------------------------
-- RANDOM SOUND
----------------------------------------------------------------
function Monster:play_random_sound(self, sounds, gain)
  if not sounds or #sounds == 0 then
    return
  end

  local pos = self.object:get_pos()

  if not pos then
    return
  end

  local sound = sounds[math.random(#sounds)]

  for _, player in ipairs(core.get_connected_players()) do
    local player_pos = player:get_pos()

    if player_pos then
      local dx = player_pos.x - pos.x
      local dy = player_pos.y - pos.y
      local dz = player_pos.z - pos.z

      local distance = math.sqrt(
        dx * dx
          + dy * dy
          + dz * dz
        )

      if distance <= 20 then
        local meta = player:get_meta()

        local monster_sounds = meta:get_string("jc_special_sounds_monsters")

        -- Monster sounds are ON by default.
        if monster_sounds ~= "off" then
          core.sound_play(sound, {
            to_player = player:get_player_name(),
            pos = pos,
            gain = gain or 1.0,
            max_hear_distance = 20,
          })
        end
      end
    end
  end
end

----------------------------------------------------------------
-- FIND A VISIBLE PLAYER
----------------------------------------------------------------
function Monster:find_visible_player(self, radius)
  local pos = self.object:get_pos()

  if not pos then
    return nil
  end

  for _, player in ipairs(core.get_connected_players()) do
    local player_pos = player:get_pos()

    if player_pos then
      local dx = player_pos.x - pos.x
      local dy = player_pos.y - pos.y
      local dz = player_pos.z - pos.z

      local distance = math.sqrt(
        dx * dx
          + dy * dy
          + dz * dz
        )

      if distance <= radius then
        local visible = core.line_of_sight(pos, player_pos, 1 )

        if visible then
          return player
        end
      end
    end
  end

  return nil
end

----------------------------------------------------------------
-- GROUP ATTACK
----------------------------------------------------------------
--
-- Any monster registered through this system can participate
-- in group attacks.
----------------------------------------------------------------
function Monster:group_attack(self, hitter)
  if not hitter or not hitter.is_player or not hitter:is_player() then
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

  for _, object in ipairs( core.get_objects_inside_radius(pos, radius) ) do
    local entity = object:get_luaentity()

    if entity and entity.name and registered_monsters[entity.name] and object ~= self.object then
      entity.attack = hitter
      entity.state = "attack"
      entity.timer = 0
    end
  end
end

----------------------------------------------------------------
-- PICK PATROL TARGET
----------------------------------------------------------------
function Monster:pick_patrol_target(self, def)
  local patrol = def.patrol

  if not patrol
    or not patrol.enabled then
    return
  end

  if not self.jc_monster_home then
    return
  end

  local angle = math.random() * math.pi * 2
  local distance = math.random() * patrol.radius

  self.jc_monster_patrol_target = {
    x = self.jc_monster_home.x + math.cos(angle) * distance,
    y = self.jc_monster_home.y,
    z = self.jc_monster_home.z + math.sin(angle) * distance,
  }
end

----------------------------------------------------------------
-- PATROL
----------------------------------------------------------------
function Monster:patrol(self, dtime, def)
  local patrol = def.patrol

  if not patrol
    or not patrol.enabled then
    return
  end

  if not self.jc_monster_home then
    return
  end

  -- Don't patrol while attacking something.
  if self.attack then
    return
  end

  local pos = self.object:get_pos()

  if not pos then
    return
  end

  local home = self.jc_monster_home

  local dx = pos.x - home.x
  local dz = pos.z - home.z

  local distance_from_home = math.sqrt(
    dx * dx
      + dz * dz
    )

  --------------------------------------------------------------
  -- Outside patrol radius.
  -- Return directly toward home.
  --------------------------------------------------------------
  if distance_from_home > patrol.radius + 1 then
    local distance = math.sqrt(
      dx * dx
        + dz * dz
      )

    if distance > 0 then
      local velocity = 1

      local move_x = -dx / distance
      local move_z = -dz / distance

      self.object:set_velocity({
        x = move_x * velocity,
        y = self.object:get_velocity().y,
        z = move_z * velocity,
      })

      ------------------------------------------------------------
      -- Face movement direction normally.
      -- Face opposite movement direction when backwards=true.
      ------------------------------------------------------------
      local yaw = math.atan2(move_x, move_z)

      if def.backwards then
        yaw = yaw + math.pi
      end

      self.object:set_yaw(yaw)
    end

    return
  end

  --------------------------------------------------------------
  -- Pick a patrol destination if we don't have one.
  --------------------------------------------------------------
  if not self.jc_monster_patrol_target then
    Monster:pick_patrol_target(self, def)
    return
  end

  local target = self.jc_monster_patrol_target

  local tx = target.x - pos.x
  local tz = target.z - pos.z

  local target_distance = math.sqrt(
    tx * tx
      + tz * tz
    )

  --------------------------------------------------------------
  -- Reached patrol destination.
  --------------------------------------------------------------
  local reached_distance =
    patrol.reached_distance or 1.0

  if target_distance <= reached_distance then
    self.object:set_velocity({
      x = 0,
      y = self.object:get_velocity().y,
      z = 0,
    })

    self.jc_monster_patrol_wait =
      (self.jc_monster_patrol_wait or 0) - dtime

    if self.jc_monster_patrol_wait <= 0 then
      self.jc_monster_patrol_wait = math.random(2, 5)

      Monster:pick_patrol_target(self, def)
    end

    return
  end

  --------------------------------------------------------------
  -- Walk toward patrol destination.
  --------------------------------------------------------------
  local velocity = self.object:get_velocity()

  local move_x = tx / target_distance
  local move_z = tz / target_distance

  local speed = def.walk_velocity or 1

  self.object:set_velocity({
    x = move_x * speed,
    y = velocity.y,
    z = move_z * speed,
  })

  --------------------------------------------------------------
  -- Face movement direction.
  --
  -- Normal:
  --   face the direction of travel.
  --
  -- backwards = true:
  --   face 180 degrees opposite the direction of travel.
  --
  -- This produces the moonwalk effect:
  -- the mob's body faces backward while its actual
  -- movement remains toward the patrol destination.
  --------------------------------------------------------------
  local yaw = math.atan2(move_x, move_z)

  if def.backwards then
    yaw = yaw + math.pi
  end

  self.object:set_yaw(yaw)
end

----------------------------------------------------------------
-- COMMON SPAWN
----------------------------------------------------------------
function Monster:on_spawn(self, def)
  local name

  if def.names and #def.names > 0 then
    name = def.names[math.random(#def.names)]
  else
    name = def.description
  end

  self.jc_monster_name = name

  self.nametag = core.colorize(def.nametag_color or "#FFFFFF", name)

  --------------------------------------------------------------
  -- Patrol home
  --------------------------------------------------------------
  if def.patrol and def.patrol.enabled then
    local pos = self.object:get_pos()

    if pos then
      self.jc_monster_home = {
        x = pos.x,
        y = pos.y,
        z = pos.z,
      }
    end

    self.jc_monster_patrol_target = nil

    self.jc_monster_patrol_wait = math.random(2, 5)
  end

  --------------------------------------------------------------
  -- Detection timers
  --------------------------------------------------------------
  if def.detection and def.detection.enabled then

    self.jc_monster_seeing_cooldown = 0

    local min = def.detection.idle_sound_min or 25

    local max = def.detection.idle_sound_max or 125

    self.jc_monster_idle_cooldown = math.random(min, max)
  end

  --------------------------------------------------------------
  -- Random monster sound timer
  --------------------------------------------------------------
  if def.random_sounds and def.random_sounds.enabled then

    local min = def.random_sounds.interval_min or 3
    local max = def.random_sounds.interval_max or 8

    self.jc_monster_random_sound_timer = math.random(min, max)
  end

  --------------------------------------------------------------
  -- Monster-specific spawn callback
  --------------------------------------------------------------
  if def.on_spawn then
    def.on_spawn(self, def)
  end

  return true
end

----------------------------------------------------------------
-- COMMON CUSTOM ATTACK
----------------------------------------------------------------
function Monster:custom_attack(self, to_attack, def)
  local target = self.attack

  if not target or not target:is_player() then
    return false
  end

  local damage = def.damage

  if player_has_rainbow_armor(target) then
    damage = def.rainbow_damage or damage
  end

  local player_name = target:get_player_name()

  -- Remember which monster delivered the attack.
  last_attackers[player_name] = self.object

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
end

----------------------------------------------------------------
-- COMMON CUSTOM LOGIC
----------------------------------------------------------------
function Monster:do_custom(self, dtime, def)
  --------------------------------------------------------------
  -- Forget dead player.
  --------------------------------------------------------------
  if self.attack and self.attack.is_player and self.attack:is_player() and self.attack:get_hp() <= 0 then
    self.attack = nil
    self.state = "walk"
    self.timer = 0

    self.jc_monster_patrol_target = nil

    if def.on_forget_attack then
      def.on_forget_attack(self, def)
    end

    return true
  end

  --------------------------------------------------------------
  -- Monster-specific custom logic.
  --
  -- This is called before the common patrol/detection logic.
  --------------------------------------------------------------
  if def.do_custom then
    local result = def.do_custom( self, dtime, def )

    if result == false then
      return false
    end
  end

  --------------------------------------------------------------
  -- Random monster sounds
  --------------------------------------------------------------
  if def.random_sounds and def.random_sounds.enabled and def.random_sounds.sounds then

    self.jc_monster_random_sound_timer =
      math.max(
        0,
        (self.jc_monster_random_sound_timer or 0)
          - dtime
      )

    if self.jc_monster_random_sound_timer <= 0 then
      Monster:play_random_sound( self, def.random_sounds.sounds, def.random_sounds.gain or 1.0 )

      local min = def.random_sounds.interval_min or 3
      local max = def.random_sounds.interval_max or 8

      self.jc_monster_random_sound_timer = math.random(min, max)
    end
  end

  --------------------------------------------------------------
  -- If currently attacking, don't do idle behavior.
  --------------------------------------------------------------
  if self.attack then
    return true
  end

  --------------------------------------------------------------
  -- Detection
  --------------------------------------------------------------
  local detection = def.detection
  if detection and detection.enabled then

    -- Countdown sound cooldowns
    self.jc_monster_seeing_cooldown =
      math.max(0, (self.jc_monster_seeing_cooldown or 0) - dtime)

    self.jc_monster_idle_cooldown =
      math.max(0, (self.jc_monster_idle_cooldown or 0) - dtime)

    -- Only do the expensive player search every 0.4 seconds
    self.jc_monster_detect_timer =
      (self.jc_monster_detect_timer or 0) - dtime

    if self.jc_monster_detect_timer <= 0 then
      self.jc_monster_detect_timer = 0.4   -- check 2.5 times per second

      local player = Monster:find_visible_player(self, detection.radius)

      if player then
        if self.jc_monster_seeing_cooldown <= 0 then
          if def.sounds and def.sounds.seeing_player then
            Monster:play_random_sound(
              self,
              def.sounds.seeing_player,
              def.sounds.seeing_gain or 0.2
            )
          end
          self.jc_monster_seeing_cooldown = detection.seeing_sound_cooldown or 25
        end
      else
        -- No player nearby
        if self.jc_monster_idle_cooldown <= 0 then
          if def.sounds and def.sounds.no_players_around then
            Monster:play_random_sound(
              self,
              def.sounds.no_players_around,
              def.sounds.idle_gain or 0.05
            )
          end
          self.jc_monster_idle_cooldown = math.random(
            detection.idle_sound_min or 25,
            detection.idle_sound_max or 125
          )
        end
      end
    end
  end

  --------------------------------------------------------------
  -- Patrol
  --------------------------------------------------------------
  if def.patrol and def.patrol.enabled then
    Monster:patrol( self, dtime, def )
  end

  return true
end

----------------------------------------------------------------
-- BUILD COMMON MOBS_REDO DEFINITION
----------------------------------------------------------------
function Monster:build_definition(def)
  local mob_def = {
    type = def.type or "monster",
    passive = def.passive ~= false,
    attack_type = def.attack_type or "dogfight",
    pathfinding = false,
    reach = def.reach or 2,
    damage = def.damage,
    hp_min = def.hp_min or 20,
    hp_max = def.hp_max or 20,
    armor = def.armor or 100,
    collisionbox = def.collisionbox
      or {
        -0.3, -1, -0.3,
         0.3,  0.8,  0.3,
      },
    visual = "mesh",
    mesh = def.mesh or "character.b3d",
    textures = {
      {def.texture},
    },
    makes_footstep_sound = def.makes_footstep_sound ~= false,
    stepheight = def.stepheight or 1.6,
    walk_velocity = def.walk_velocity or 1,
    run_velocity = def.run_velocity or 4,
    jump_height = def.jump_height or 4,
    view_range = def.view_range or 8,
    lava_damage = def.lava_damage or 8,
    attack_npcs = def.attack_npcs or false,
    attack_animals = def.attack_animals or false,
    attack_monsters = def.attack_monsters ~= false,
    animation = def.animation or {
      speed_normal = 15,
      speed_run = 30,

      stand_start = 0,
      stand_end = 40,

      walk_start = 168,
      walk_end = 187,

      run_start = 168,
      run_end = 187,

      punch_start = 189,
      punch_end = 198,
    },

    --------------------------------------------------------------
    -- SPAWN
    --------------------------------------------------------------
    on_spawn = function(self)
      return Monster:on_spawn(self, def)
    end,

    --------------------------------------------------------------
    -- HIT BY PLAYER
    --------------------------------------------------------------
    do_punch = function(self, hitter)
      if hitter and hitter.is_player and hitter:is_player() then
        if def.sounds and def.sounds.hit then
          Monster:play_random_sound( self, def.sounds.hit, def.sounds.hit_gain or 1.0 )
        end

        Monster:group_attack( self, hitter )
      end

      if def.do_punch then
        return def.do_punch( self, hitter, def )
      end
    end,

    on_step = function(self, dtime)
      if def.backwards and self.state == "walk" then

        local velocity = self.object:get_velocity()

        if velocity then
          local dx = velocity.x
          local dz = velocity.z

          local speed = math.sqrt(dx * dx + dz * dz)

          if speed > 0.05 then
            self.object:set_yaw(
              math.atan2(dx, dz) + math.pi
            )
          end
        end
      end
    end,

    --------------------------------------------------------------
    -- CUSTOM ATTACK
    --------------------------------------------------------------
    custom_attack = function(self, to_attack)
      return Monster:custom_attack(self, to_attack, def )
    end,

    --------------------------------------------------------------
    -- CUSTOM LOGIC
    --------------------------------------------------------------
    do_custom = function(self, dtime)
      return Monster:do_custom( self, dtime, def )
    end,

    --------------------------------------------------------------
    -- DROPS
    --------------------------------------------------------------
    drops = def.drops or {},
  }

  --------------------------------------------------------------
  -- Optional lifetimer.
  --------------------------------------------------------------
  if def.lifetimer then
    mob_def.lifetimer = def.lifetimer
  end

  --------------------------------------------------------------
  -- Optional custom mobs_redo properties.
  --------------------------------------------------------------
  if def.mob_properties then
    for key, value in pairs(def.mob_properties) do
      mob_def[key] = value
    end
  end

  return mob_def
end

----------------------------------------------------------------
-- REGISTER SPAWN
----------------------------------------------------------------
function Monster:register_spawn(def)
  if not def.spawn then
    return
  end

  if mobs.custom_spawn_monster then
    return
  end

  mobs:spawn({
    name = def.name,

    nodes = def.spawn.nodes,

    min_light = def.spawn.min_light,
    max_light = def.spawn.max_light,

    chance = def.spawn.chance,

    min_height = def.spawn.min_height,
    max_height = def.spawn.max_height,
  })
end

----------------------------------------------------------------
-- REGISTER EGG
----------------------------------------------------------------
function Monster:register_egg(def)
  mobs:register_egg(
    def.name,
    S(def.description),
    def.egg_texture or def.texture,
    1
  )
end

----------------------------------------------------------------
-- REGISTER ALIAS
----------------------------------------------------------------
function Monster:register_alias(def)
  mobs:alias_mob(
    def.alias or ("mobs:" .. def.name:match("^[^:]+:(.+)$") ),
    def.name
  )
end

----------------------------------------------------------------
-- REGISTER MONSTER
----------------------------------------------------------------
function Monster:register(def)
  if not def.name then
    core.log("error", "[jc_special] Monster definition missing name." )
    return
  end

  if registered_monsters[def.name] then
    core.log("warning", "[jc_special] Monster already registered: " .. def.name )
    return
  end

  registered_monsters[def.name] = def

  local mob_def = self:build_definition(def)

  mobs:register_mob( def.name, mob_def )

  self:register_egg(def)

  self:register_alias(def)

  self:register_spawn(def)

  core.log("action", "[jc_special] " .. def.description .. " registered with mobs_redo")
end

----------------------------------------------------------------
-- MONSTER DEFINITIONS
----------------------------------------------------------------
-- THIS IS WHERE JC_SPECIAL MONSTERS GO.
--
-- Add new monster definitions to "monsterDefinitions".
--
-- The factory above should normally not need to be modified
-- when adding another monster.
----------------------------------------------------------------
local monsterDefinitions = {
  ----------------------------------------------------------------
  -- CASTLE GUARD
  ----------------------------------------------------------------
  castle_guard = {
    name = "mobs_monster:castle_guard",
    type = "monster",
    description = "Castle Guard",
    alias = "mobs:castle_guard",
    nametag_color = "#ACF5A7",
    damage = 15,
    rainbow_damage = 10,
    hp_min = 20,
    hp_max = 20,
    armor = 100,
    collisionbox = {
      -0.3, -1, -0.3,
       0.3,  0.8,  0.3,
    },
    texture = "character.111.png",
    mesh = "character.b3d",
    egg_texture = "castle_guard.png",
    stepheight = 1.6,
    walk_velocity = 1,
    run_velocity = 4,
    jump_height = 2,
    view_range = 8,
    lava_damage = 8,
    lifetimer = 20000,
    animation = {
      speed_normal = 15, speed_run = 30,
      stand_start = 0, stand_end = 40,
      walk_start = 168, walk_end = 187,
      run_start = 168, run_end = 187,
      punch_start = 189, punch_end = 198
    },

    ----------------------------------------------------------------
    -- RANDOM CASTLE GUARD NAMES
    ----------------------------------------------------------------
    names = {
      "Sir Aldric",
      "Sir Cedric",
      "Sir Godfrey",
      "Sir Reginald",
      "Sir Geoffrey",
      "Sir Roland",
      "Sir Percival",
      "Sir Tristan",
      "Sir Baldwin",
      "Sir Reynard",
      "Sir Oswald",
      "Sir Eustace",
      "Sir Alaric",
      "Sir Bertram",
      "Sir Edmund",
      "Sir Richard",
      "Sir William",
      "Sir Henry",
      "Sir Walter",
      "Sir Gilbert",
      "Sir Hugh",
      "Sir Lionel",
      "Sir Harold",
      "Sir Roderick",
      "The Knights Who Say Ni!",

      "Guard Aldwin",
      "Guard Edwin",
      "Guard Leofric",
      "Guard Wulfric",
      "Guard Cuthbert",
      "Guard Oswin",
      "Guard Godwin",
      "Guard Hereward",
      "Guard Aethelred",
      "Guard Dunstan",
      "Guard Cedwin",
      "Guard Wilfred",
      "Guard Anselm",
      "Guard Berengar",
      "Guard Rainald",
      "Guard Theobald",
      "Guard Lambert",
      "Guard Conrad",
      "Guard Everard",
      "Guard Alwin",

      "The Knights Who Say Ni!",
      "Captain of the Guard",
      "Master of the Gate",
      "Keeper of the Gate",
      "Warden of the Castle",
      "Warden of the Wall",
      "Keeper of the Drawbridge",
      "Guardian of the Keep",
      "Watchman of the North Tower",
      "Watchman of the South Tower",
      "Sentinel of the Gate",

      "The Knights Who Say Ni!",
      "Old Guard Harold",
      "Sir Grumbles",
      "Sir Sleeps-at-the-Gate",
      "Sir Stands-Around",
      "Sir No-Boots",
      "Sir Forgets-His-Helmet",
      "Guard Who Heard Nothing",
      "Guard Who Saw Nothing",
      "The Gatekeeper",
      "The Last Watchman",
    },

    ----------------------------------------------------------------
    -- PATROL
    ----------------------------------------------------------------
    patrol = {
      enabled = true,
      radius = 5,
      reached_distance = 1.0,
    },

    ----------------------------------------------------------------
    -- PLAYER DETECTION
    ----------------------------------------------------------------
    detection = {
      enabled = true,
      radius = 20,
      seeing_sound_cooldown = 25,
      idle_sound_min = 25,
      idle_sound_max = 125,
    },

    ----------------------------------------------------------------
    -- CASTLE GUARD SOUNDS
    ----------------------------------------------------------------
    sounds = {
      hit = {
        "castle_guard_sounds_hit_01",
        "castle_guard_sounds_hit_02",
        "castle_guard_sounds_hit_03",
        "castle_guard_sounds_hit_04",
      },
      hit_gain = 1.0,

      seeing_player = {
        "castle_guard_sounds_seeing_player_01",
        "castle_guard_sounds_seeing_player_02",
        "castle_guard_sounds_seeing_player_03",
        "castle_guard_sounds_seeing_player_04",
        "castle_guard_sounds_hit_04",
      },
      seeing_gain = 0.2,

      no_players_around = {
        "castle_guard_sounds_no_players_around_01",
        "castle_guard_sounds_no_players_around_02",
        "castle_guard_sounds_no_players_around_03",
        "castle_guard_sounds_no_players_around_04",
        "castle_guard_sounds_no_players_around_05",
      },
      idle_gain = 0.05,
    },

    ----------------------------------------------------------------
    -- DROPS
    ----------------------------------------------------------------
    drops = {
      { name = "default:sword_steel", chance = 4, min = 1, max = 1, },
      { name = "shields:shield_steel", chance = 15, min = 1, max = 1, },
      { name = "3d_armor:helmet_steel", chance = 8, min = 1, max = 1, },
      { name = "3d_armor:chestplate_steel", chance = 8, min = 1, max = 1, },
      { name = "3d_armor:leggings_steel", chance = 8, min = 1, max = 1, },
      { name = "3d_armor:boots_steel", chance = 8, min = 1, max = 1, },

    },
  },

  ----------------------------------------------------------------
  -- TROOPER
  ----------------------------------------------------------------
  trooper = {
    name = "mobs_monster:trooper",
    type = "monster",
    description = "Trooper",
    alias = "mobs:trooper",
    nametag_color = "#FFFF00",
    damage = 10,
    rainbow_damage = 7,
    hp_min = 20,
    hp_max = 20,
    armor = 100,
    collisionbox = {
      -0.3, -1, -0.3,
       0.3,  0.8,  0.3,
    },
    texture = "character.png",
    mesh = "character.b3d",
    egg_texture = "player.png",
    stepheight = 1.6,
    walk_velocity = 1,
    run_velocity = 4,
    jump_height = 4,
    view_range = 8,
    lava_damage = 8,
    animation = {
      speed_normal = 15, speed_run = 30,
      stand_start = 0, stand_end = 40,
      walk_start = 168, walk_end = 187,
      run_start = 168, run_end = 187,
      punch_start = 189, punch_end = 198
    },

    ----------------------------------------------------------------
    -- RANDOM TROOPER NAMES
    ----------------------------------------------------------------
    names = {
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
      -- "Michael Jackson",
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
    },

    ----------------------------------------------------------------
    -- TROOPER SPAWN
    ----------------------------------------------------------------
    spawn = {
      nodes = { "moreblocks:checker_stone_tile", },
      min_light = 0,
      max_light = 15,
      chance = 5000,
      min_height = -2,
      max_height = 30,
    },

    ----------------------------------------------------------------
    -- DROPS
    ----------------------------------------------------------------
    drops = {
      { name = "mobs_monster:trooper", chance = 5, min = 1, max = 1, },
      { name = "default:pick_steel", chance = 3, min = 1, max = 1, },
    },
  },

  ----------------------------------------------------------------
  -- MICHAEL JACKSON
  ----------------------------------------------------------------
  michael_jackson = {
    name = "mobs_monster:michael_jackson",
    type = "npc",
    description = "Michael Jackson",
    alias = "mobs:michael_jackson",
    nametag_color = "#FFFFFF",

    passive = true,
    attack_players = false,
    attack_npcs = false,
    attack_animals = false,
    attack_monsters = false,

    damage = 0, -- was 10
    rainbow_damage = 0, -- was 7

    hp_min = 20,
    hp_max = 20,
    armor = 100,

    collisionbox = {
      -0.3, -1, -0.3,
       0.3,  0.8,  0.3,
    },

    texture = "michael_jackson.png",
    mesh = "character.b3d",
    egg_texture = "michael_jackson.png",

    stepheight = 1.6,
    walk_velocity = 0,
    run_velocity = 0,
    jump_height = 4,
    view_range = 8,
    lava_damage = 8,

    -- Prevent mobs_redo from doing normal walk behavior
    walk_chance = 0,
    stand_chance = 0,

    animation = {
      speed_normal = 15,
      speed_run = 15,
      stand_start = 0, stand_end = 40,
      walk_start = 168, walk_end = 187,
      run_start = 168, run_end = 187,
      punch_start = 189, punch_end = 198,
    },

    names = {
      "Michael Jackson",
    },

    random_sounds = {
      enabled = true,
      interval_min = 0.4,
      interval_max = 1.8,
      gain = 1.0,
      sounds = {
        "michael_jackson_sound_001",
        "michael_jackson_sound_002",
        "michael_jackson_sound_003",
        "michael_jackson_sound_004",
        "michael_jackson_sound_005",
        "michael_jackson_sound_006",
        "michael_jackson_sound_007",
        "michael_jackson_sound_008",
        "michael_jackson_sound_009",
        "michael_jackson_sound_010",
        "michael_jackson_sound_011",
        "michael_jackson_sound_012",
      },
    },

    ----------------------------------------------------------------
    -- CUSTOM PUNCH MOVEMENT
    ----------------------------------------------------------------
    do_punch = function(self, hitter, def)
      if hitter and hitter:is_player() then
        Monster:play_random_sound(self, {"michael_jackson_sound_011"}, 1.0)
      end

      -- Force him back to peaceful moonwalking
      self.attack = nil
      self.state = "stand"
      self.timer = 0

      return true
    end,

    ----------------------------------------------------------------
    -- CUSTOM MOONWALK MOVEMENT
    ----------------------------------------------------------------
    do_custom = function(self, dtime, def)
      -- Don't do our own movement while attacking
      if self.attack then
        return true
      end

      local pos = self.object:get_pos()
      if not pos then return true end

      -- Change direction every few seconds
      self.mj_timer = (self.mj_timer or 0) - dtime
      if not self.mj_dir or self.mj_timer <= 0 then
        local angle = math.random() * math.pi * 2
        self.mj_dir = {
          x = math.cos(angle),
          z = math.sin(angle)
        }
        self.mj_timer = math.random(4, 8)
      end

      local speed = 1.0

      -- Move in the chosen direction
      local vel = self.object:get_velocity() or {y = 0}
      self.object:set_velocity({
        x = self.mj_dir.x * speed,
        y = vel.y,
        z = self.mj_dir.z * speed
      })

      -- Always face the exact opposite direction
      local move_yaw = math.atan2(self.mj_dir.x, self.mj_dir.z)
      local face_yaw = move_yaw + math.pi          -- 180 degrees opposite

      self.object:set_yaw(face_yaw)

      -- Force it again next tick so mobs_redo can't override it
      core.after(0, function()
        if self.object and self.object:get_luaentity() then
          self.object:set_yaw(face_yaw)
        end
      end)

      -- Keep walk animation
      self:set_animation("walk")

      return true
    end,
    drops = {
      { name = "mobs_monster:michael_jackson", chance = 5, min = 1, max = 1 },
    },
  },
}

----------------------------------------------------------------
-- REGISTER ALL MONSTERS
----------------------------------------------------------------
for _, def in pairs(monsterDefinitions) do
  Monster:register(def)
end

----------------------------------------------------------------
-- REGISTER ON PLAYER DEATH
----------------------------------------------------------------
core.register_on_dieplayer(function(player, reason)
  local player_name = player:get_player_name()

  local meta = player:get_meta()

  local monster_sounds = meta:get_string("jc_special_sounds_monsters")

  --------------------------------------------------------------
  -- Try to get the killer from the normal death reason first.
  --------------------------------------------------------------
  local killer = nil

  if reason and reason.object then
    killer = reason.object
  end

  --------------------------------------------------------------
  -- Our custom attacks use set_hp(), so fall back to the
  -- monster recorded in custom_attack().
  --------------------------------------------------------------
  if not killer then
    killer = last_attackers[player_name]
  end

  -- Remove the stored attacker now that the player has died.
  last_attackers[player_name] = nil

  if not killer then
    return
  end

  local killer_entity = killer:get_luaentity()

  if not killer_entity then
    return
  end

  local def = registered_monsters[killer_entity.name]

  if not def then
    return
  end

  local monster_name = killer_entity.jc_monster_name or S(def.description)

  local death_pos = player:get_pos()

  --------------------------------------------------------------
  -- OOF SOUND
  --------------------------------------------------------------
  if death_pos and monster_sounds ~= "off" then
    core.sound_play("oof", {
      pos = death_pos,
      gain = 1.0,
      max_hear_distance = 30,
    })
  end

  --------------------------------------------------------------
  -- DEATH MESSAGE
  --------------------------------------------------------------
  core.chat_send_all( S("@1 was eliminated by @2!", core.colorize(PLAYER_NAME_COLOR, player_name ), core.colorize( def.nametag_color or "#FFFFFF", monster_name ) ) )
end)

----------------------------------------------------------------
-- DONE
----------------------------------------------------------------
core.log("action", "[jc_special] Unified mobs_redo monster system loaded.")

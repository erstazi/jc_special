if not core.get_modpath("mobs") then
  core.log("warning", "[jc_special] mobs_redo not found, Castle Guards not registered.")
  return
end

local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- CASTLE GUARD SOUNDS
----------------------------------------------------------------
--[[
### 1. Sounds played when the guard is hit by a player.
- Halt!
- Stay where you are!
- You there! Stop at once!
- Oi, mate! Ya got a loicense for that?
]]
local castle_guard_sounds_hit = {
  'castle_guard_sounds_hit_01',
  'castle_guard_sounds_hit_02',
  'castle_guard_sounds_hit_03',
  'castle_guard_sounds_hit_04',
}

--[[
### 2. Sounds played when the guard sees a player.
- Identify yourself!
- State your business!
- Who goes there?
- Come out where I can see you!
]]
local castle_guard_sounds_seeing_player = {
  'castle_guard_sounds_seeing_player_01',
  'castle_guard_sounds_seeing_player_02',
  'castle_guard_sounds_seeing_player_03',
  'castle_guard_sounds_seeing_player_04',
  'castle_guard_sounds_hit_04',
}

--[[
### 3. Sounds played when no player is nearby.
- Did you hear that?
- Quiet… listen.
- Something’s not right.
- I don’t like this silence.
- All quiet so far…
]]
local castle_guard_sounds_no_players_around = {
  'castle_guard_sounds_no_players_around_01',
  'castle_guard_sounds_no_players_around_02',
  'castle_guard_sounds_no_players_around_03',
  'castle_guard_sounds_no_players_around_04',
  'castle_guard_sounds_no_players_around_05',
}

----------------------------------------------------------------
-- CASTLE GUARD NAMES
----------------------------------------------------------------
local castle_guard_names = {
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
}

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
local PATROL_RADIUS = 5
local PLAYER_DETECTION_RADIUS = 20

-- How often the guard is allowed to announce that it sees a player.
local SEEING_SOUND_COOLDOWN = 25

-- Minimum time between idle comments.
local IDLE_SOUND_MIN = 25

-- Maximum time between idle comments.
local IDLE_SOUND_MAX = 125

-- How close to the patrol destination before picking another one.
local PATROL_REACHED_DISTANCE = 1.0

-- Normal damage that castle guard does against player without rainbow
local CASTLE_GUARD_NORMAL_DAMAGE = 15

-- Normal damage that castle guard does against player with rainbow
local CASTLE_GUARD_RAINBOW_DAMAGE = 10

----------------------------------------------------------------
-- RAINBOW ARMOR DETECTION
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
-- RANDOM SOUND HELPER
----------------------------------------------------------------
local function castle_guard_play_random_sound(self, sounds, gain)
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
        dx * dx +
        dy * dy +
        dz * dz
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
      monster_sounds_storage:set_string("disabled:" .. name, "")

      core.log("action", "[JC_SPECIAL MONSTER SOUNDS] " .. name .. " turned ON monster sounds")
      return true, S("Monster sounds enabled.")
    end

    return false, S("Usage: /jc_special_sounds_monsters <on|off>")
  end,
})


----------------------------------------------------------------
-- LIST PLAYERS WITH MONSTER SOUND DISABLED
----------------------------------------------------------------
core.register_chatcommand("list_jc_special_sounds_monsters", {
  params = "",
  description = S("List players who have monster sounds disabled."),
  privs = { server = true },

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

    core.chat_send_player(name, core.colorize("#FFFF00", S("Players with monster sounds disabled (@1):", #disabled_players) ) )

    for _, player_name in ipairs(disabled_players) do
      core.chat_send_player(name, "  " .. core.colorize("#FF7979", player_name) )
    end

    return true
  end
})

----------------------------------------------------------------
-- FIND A PLAYER THE GUARD CAN SEE
----------------------------------------------------------------
local function castle_guard_find_visible_player(self)
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
        dx * dx +
        dy * dy +
        dz * dz
      )

      if distance <= PLAYER_DETECTION_RADIUS then

        -- Check line of sight.
        local visible = core.line_of_sight(
          pos,
          player_pos,
          1
        )

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
local function castle_guard_group_attack(self, hitter)
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

  -- Alert all nearby Castle Guards.
  for _, object in ipairs(core.get_objects_inside_radius(pos, radius)) do
    local entity = object:get_luaentity()
    if entity and entity.name == "mobs_monster:castle_guard" and object ~= self.object then
      entity.attack = hitter
      entity.state = "attack"
      entity.timer = 0
    end
  end
end

----------------------------------------------------------------
-- PICK A NEW PATROL POSITION
----------------------------------------------------------------
local function castle_guard_pick_patrol_target(self)
  if not self.castle_guard_home then
    return
  end

  local home = self.castle_guard_home

  local angle = math.random() * math.pi * 2
  local distance = math.random() * PATROL_RADIUS

  self.castle_guard_patrol_target = {
    x = home.x + math.cos(angle) * distance,
    y = home.y,
    z = home.z + math.sin(angle) * distance
  }
end

----------------------------------------------------------------
-- PATROL
----------------------------------------------------------------
local function castle_guard_patrol(self, dtime)
  if not self.castle_guard_home then
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

  --------------------------------------------------------------
  -- Make sure the guard hasn't wandered too far from home.
  --------------------------------------------------------------

  local home = self.castle_guard_home

  local dx = pos.x - home.x
  local dz = pos.z - home.z

  local distance_from_home = math.sqrt(
    dx * dx +
    dz * dz
  )

  if distance_from_home > PATROL_RADIUS + 1 then
    -- Head directly back toward the castle guard's home.
    local distance = math.sqrt(dx * dx + dz * dz)

    if distance > 0 then
      local velocity = 1
      self.object:set_velocity({
        x = -dx / distance * velocity,
        y = self.object:get_velocity().y,
        z = -dz / distance * velocity
      })

      self.object:set_yaw(
        math.atan2(-dx, -dz)
      )
    end

    return
  end

  --------------------------------------------------------------
  -- Pick a patrol destination if we don't have one.
  --------------------------------------------------------------
  if not self.castle_guard_patrol_target then
    castle_guard_pick_patrol_target(self)
    return
  end

  local target = self.castle_guard_patrol_target
  local tx = target.x - pos.x
  local tz = target.z - pos.z
  local target_distance = math.sqrt(
    tx * tx +
    tz * tz
  )

  --------------------------------------------------------------
  -- Reached patrol destination.
  --------------------------------------------------------------
  if target_distance <= PATROL_REACHED_DISTANCE then
    self.object:set_velocity({
      x = 0,
      y = self.object:get_velocity().y,
      z = 0
    })

    self.castle_guard_patrol_wait =
      (self.castle_guard_patrol_wait or 0) - dtime

    if self.castle_guard_patrol_wait <= 0 then
      self.castle_guard_patrol_wait = math.random(2, 5)
      castle_guard_pick_patrol_target(self)
    end

    return
  end

  --------------------------------------------------------------
  -- Walk toward patrol destination.
  --------------------------------------------------------------
  local velocity = self.object:get_velocity()

  self.object:set_velocity({
    x = tx / target_distance * 1,
    y = velocity.y,
    z = tz / target_distance * 1
  })

  self.object:set_yaw(
    math.atan2(tx, tz)
  )
end


----------------------------------------------------------------
-- REGISTER CASTLE GUARD
----------------------------------------------------------------

mobs:register_mob("mobs_monster:castle_guard", {
  type = "monster",
  passive = true,
  attack_type = "dogfight",
  pathfinding = false,
  reach = 2,
  damage = CASTLE_GUARD_NORMAL_DAMAGE,
  hp_min = 20,
  hp_max = 20,
  armor = 100,
  collisionbox = {
    -0.3, -1, -0.3,
     0.3,  0.8,  0.3
  },
  visual = "mesh",
  mesh = "character.b3d",
  textures = {
    {"character.111.png"}
  },
  makes_footstep_sound = true,
  stepheight = 1.6,
  walk_velocity = 1,
  run_velocity = 4,
  -- jump_height = 4,
  jump_height = 2,
  view_range = 8,
  lava_damage = 8,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = true,
  -- Prevent the normal 3-minute mobs_redo lifetime
  -- from removing the Castle Guard.
  lifetimer = 20000,
  animation = {
    speed_normal = 15,
    speed_run = 30,

    stand_start = 0,
    stand_end = 40,

    walk_start = 168,
    walk_end = 187,

    run_start = 168,
    run_end = 187,

    punch_start = 189,
    punch_end = 198
  },

  --------------------------------------------------------------
  -- SPAWN
  --------------------------------------------------------------
  on_spawn = function(self)
    local name = castle_guard_names[ math.random(#castle_guard_names) ]

    self.castle_guard_name = name
    self.nametag = core.colorize("#ACF5A7", name)

    -- Remember where this particular guard spawned.
    local pos = self.object:get_pos()

    if pos then
      self.castle_guard_home = {
        x = pos.x,
        y = pos.y,
        z = pos.z
      }
    end

    self.castle_guard_patrol_target = nil
    self.castle_guard_patrol_wait = math.random(2, 5)
    self.castle_guard_seeing_cooldown = 0
    self.castle_guard_idle_cooldown = math.random(IDLE_SOUND_MIN, IDLE_SOUND_MAX)
    return true
  end,


  --------------------------------------------------------------
  -- HIT BY PLAYER
  --------------------------------------------------------------
  do_punch = function(self, hitter)
    if hitter and hitter.is_player and hitter:is_player() then
      castle_guard_play_random_sound(
        self,
        castle_guard_sounds_hit,
        1.0
      )
      castle_guard_group_attack(self, hitter)
    end
  end,

  --[[
  ----------------------------------------------------------------
  -- CUSTOM ATTACK
  ----------------------------------------------------------------
  custom_attack = function(self, to_attack)
    local target = self.attack

    if not target or not target:is_player() then
      return false
    end

    local damage = CASTLE_GUARD_NORMAL_DAMAGE

    if player_has_rainbow_armor(target) then
      damage = CASTLE_GUARD_RAINBOW_DAMAGE
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
  ]]

  --------------------------------------------------------------
  -- CUSTOM LOGIC
  --------------------------------------------------------------
  do_custom = function(self, dtime)
    ------------------------------------------------------------
    -- Countdown sound timers.
    ------------------------------------------------------------
    self.castle_guard_seeing_cooldown = math.max(0, (self.castle_guard_seeing_cooldown or 0) - dtime )
    self.castle_guard_idle_cooldown = math.max(0, (self.castle_guard_idle_cooldown or 0) - dtime )

    ------------------------------------------------------------
    -- Forget a dead player.
    ------------------------------------------------------------
    if self.attack and self.attack:is_player() and self.attack:get_hp() <= 0 then
      self.attack = nil
      self.state = "walk"
      self.timer = 0
      self.castle_guard_patrol_target = nil
      return true
    end

    ------------------------------------------------------------
    -- If currently attacking, don't do patrol or idle sounds.
    ------------------------------------------------------------
    if self.attack then
      return true
    end

    ------------------------------------------------------------
    -- Look for a player within 10 meters.
    ------------------------------------------------------------
    local player = castle_guard_find_visible_player(self)

    ------------------------------------------------------------
    -- PLAYER DETECTED
    ------------------------------------------------------------
    if player then
      -- Only announce periodically.
      if self.castle_guard_seeing_cooldown <= 0 then
        castle_guard_play_random_sound( self, castle_guard_sounds_seeing_player, 0.2 )
        self.castle_guard_seeing_cooldown = SEEING_SOUND_COOLDOWN
      end

      return true
    end

    ------------------------------------------------------------
    -- NO PLAYER NEARBY
    ------------------------------------------------------------
    if self.castle_guard_idle_cooldown <= 0 then
      castle_guard_play_random_sound( self, castle_guard_sounds_no_players_around, 0.05 )
      self.castle_guard_idle_cooldown = math.random(IDLE_SOUND_MIN, IDLE_SOUND_MAX)
    end

    ------------------------------------------------------------
    -- PATROL
    ------------------------------------------------------------
    castle_guard_patrol( self, dtime )

    return true
  end,


  --------------------------------------------------------------
  -- DROPS
  --------------------------------------------------------------
  drops = {
    { name = "default:sword_steel", chance = 4, min = 1, max = 1 },
    { name = "shields:shield_steel", chance = 15, min = 1, max = 1 },
    { name = "3d_armor:helmet_steel", chance = 8, min = 1, max = 1 },
    { name = "3d_armor:chestplate_steel", chance = 8, min = 1, max = 1 },
    { name = "3d_armor:leggings_steel", chance = 8, min = 1, max = 1 },
    { name = "3d_armor:boots_steel", chance = 8, min = 1, max = 1 }
  }
})

----------------------------------------------------------------
-- EGG
----------------------------------------------------------------
mobs:register_egg(
  "mobs_monster:castle_guard",
  S("Castle Guard"),
  "castle_guard.png",
  1
)

----------------------------------------------------------------
-- ALIAS
----------------------------------------------------------------
mobs:alias_mob("mobs:castle_guard", "mobs_monster:castle_guard")

----------------------------------------------------------------
-- PLAYER DEATH MESSAGE / OOF SOUND
----------------------------------------------------------------
core.register_on_dieplayer(function(player, reason)
  if not reason or not reason.object then
    return
  end

  local killer = reason.object
  local killer_entity = killer:get_luaentity()

  if not killer_entity then
    return
  end

  if killer_entity.name ~= "mobs_monster:castle_guard" then
    return
  end

  local player_name = player:get_player_name()
  local castle_guard_name = killer_entity.castle_guard_name or S("Castle Guard")
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
  core.chat_send_all(core.colorize("#FF7979", S("@1 was eliminated by @2!", player_name, castle_guard_name) ) )
end)

core.log("action", "[jc_special] Castle Guard registered with mobs_redo" )

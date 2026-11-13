-- mobs/michael_jackson.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- MICHAEL JACKSON
----------------------------------------------------------------

monsterDefinitions.michael_jackson = {
  name = "mobs_monster:michael_jackson",
  type = "npc",
  description = "Michael Jackson",
  alias = "mobs:michael_jackson",
  nametag = true,
  nametag_color = "#FFFFFF",

  passive = true,
  attack_players = false,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = false,

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
    speed_normal = 6,
    speed_run = 6,

    stand_start = 0,
    stand_end = 40,
    stand_speed = 15,


    walk_start = 168,
    walk_end = 187,
    walk_speed = 5,

    run_start = 168,
    run_end = 187,
    run_speed = 5,

    punch_start = 189,
    punch_end = 198,
    punch_speed = 15,
  },

  names = {
    "Michael Jackson",
  },

  random_sounds = {
    enabled = true,
    interval_min = 0.4,
    interval_max = 1.8,
    gain = 0.6,
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

    ----------------------------------------------------------
    -- ARM RAISING (left then right)
    ----------------------------------------------------------
    --[[
    TOO MUCH LIKE A PENIS COMING OUT
    self.mj_arm_timer = (self.mj_arm_timer or 0) - dtime
    if self.mj_arm_timer <= 0 then
      self.mj_arm_side = not self.mj_arm_side
      local bone = self.mj_arm_side and "Arm_Left" or "Arm_Right"
      self.object:set_bone_position(bone, {x = 0, y = 0, z = 0}, {x = -90, y = 0, z = 0})
      core.after(0.7, function()
        if self.object and self.object:get_luaentity() then
          self.object:set_bone_position(bone, {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        end
      end)
      self.mj_arm_timer = 1.6
    end
    ]]

    return true
  end,
  drops = {
    { name = "mobs_monster:michael_jackson", chance = 5, min = 1, max = 1 },
  },
}
-- mobs/elmo_large.lua

local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- ELMO LARGE
----------------------------------------------------------------

monsterDefinitions.elmo_large = {
  name = "mobs_monster:elmo_large",
  type = "monster",
  description = "Giant Elmo",
  alias = "mobs:elmo_large",
  nametag = true,
  nametag_color = "#FF0000",

  passive = false,
  attack_type = "dogfight",
  attack_players = true,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = true,

  damage = 14,
  rainbow_damage = 10,
  reach = 3.0,

  hp_min = 40,
  hp_max = 40,
  armor = 100,

  visual_size = { x = 2.0, y = 2.0 },

  collisionbox = {
    -0.6, -2.0, -0.6,
     0.6,  1.6,  0.6,
  },

  texture = "elmo.png",
  mesh = "character.b3d",
  egg_texture = "elmo_inv.png",
  is_egg = false,

  stepheight = 3.0,
  walk_velocity = 1.2,
  run_velocity = 2.4,
  jump_height = 3,
  view_range = 30,

  lava_damage = 8,

  animation = {
    speed_normal = 15, speed_run = 20,
    stand_start = 0, stand_end = 40,
    walk_start = 168, walk_end = 187,
    run_start = 168, run_end = 187,
    punch_start = 189, punch_end = 198,
  },

  detection = {
    enabled = true,
    radius = 30,
    see_through_nodes = true,
    seeing_sound_cooldown = 4,
    idle_sound_min = 4,
    idle_sound_max = 6,
  },

  sounds = {
    hit = {
      "elmo_hit_01",
      "elmo_hit_02",
    },
    hit_gain = 1.0,

    seeing_player = {
      "elmo_seeing_player_01",
      "elmo_seeing_player_02",
      "elmo_no_players_around_01",
      "elmo_no_players_around_02",
      "elmo_no_players_around_03",
      "elmo_no_players_around_04",
      "elmo_no_players_around_05",
      "elmo_no_players_around_06",
      "elmo_no_players_around_07",
      "elmo_no_players_around_08",
      "elmo_no_players_around_09",
    },
    seeing_gain = 0.4,
    seeing_max_hear_distance = 30,

    no_players_around = {
      "elmo_no_players_around_01",
      "elmo_no_players_around_02",
      "elmo_no_players_around_03",
      "elmo_no_players_around_04",
      "elmo_no_players_around_05",
      "elmo_no_players_around_06",
      "elmo_no_players_around_07",
      "elmo_no_players_around_08",
      "elmo_no_players_around_09",
    },
    idle_gain = 0.2,
    idle_max_hear_distance = 60,
  },

  ------------------------------------------------------------
  -- Face + chase; no stalk phase
  ------------------------------------------------------------
  do_custom = function(self, dtime, def)
    local pos = self.object:get_pos()

    if not pos then
      return true
    end

    local velocity = self.object:get_velocity() or {y = 0}
    local detection = def.detection
    local radius = (detection and detection.radius) or 30

    ------------------------------------------------------------
    -- FIND CLOSEST PLAYER
    ------------------------------------------------------------
    local closest_player = nil
    local closest_distance = def.view_range or 20

    for _, player in ipairs(core.get_connected_players()) do
      local player_pos = player:get_pos()

      if player_pos then
        local distance = vector.distance(pos, player_pos)

        if distance <= closest_distance then
          closest_distance = distance
          closest_player = player
        end
      end
    end

    ------------------------------------------------------------
    -- CHASE AND ATTACK
    ------------------------------------------------------------
    if closest_player then
      local player_pos = closest_player:get_pos()

      if player_pos then
        local dx = player_pos.x - pos.x
        local dz = player_pos.z - pos.z
        local distance = math.sqrt(dx * dx + dz * dz)

        self.object:set_yaw(math.atan2(-dx, dz))

        if distance > (def.reach or 3.0) then
          local speed = def.run_velocity or 2.4

          self.object:set_velocity({
            x = dx / distance * speed,
            y = velocity.y,
            z = dz / distance * speed,
          })

          self:set_animation("run")
        else
          self.object:set_velocity({
            x = 0,
            y = velocity.y,
            z = 0,
          })

          self:set_animation("punch")

          ------------------------------------------------------
          -- DAMAGE PLAYER
          ------------------------------------------------------
          self.jc_attack_timer =
            (self.jc_attack_timer or 0) - dtime

          if self.jc_attack_timer <= 0 then
            self.jc_attack_timer = 1.0

            closest_player:punch(self.object, 1.0, {
              full_punch_interval = 1.0,
              damage_groups = {
                fleshy = def.damage or 14,
              },
            }, nil)
          end
        end
      end

      ----------------------------------------------------------
      -- SEEING-PLAYER SOUNDS
      ----------------------------------------------------------
      self.jc_monster_seeing_cooldown = math.max(
        0,
        (self.jc_monster_seeing_cooldown or 0) - dtime
      )

      self.jc_monster_detect_timer =
        (self.jc_monster_detect_timer or 0) - dtime

      if self.jc_monster_detect_timer <= 0 then
        self.jc_monster_detect_timer = 0.4

        if self.jc_monster_seeing_cooldown <= 0 then
          if def.sounds and def.sounds.seeing_player then
            Monster:play_random_sound(
              self,
              def.sounds.seeing_player,
              def.sounds.seeing_gain or 0.4,
              def.sounds.seeing_max_hear_distance or 40
            )
          end

          self.jc_monster_seeing_cooldown =
            detection and detection.seeing_sound_cooldown or 4
        end
      end

      self.jc_monster_idle_timer = nil

    else
      ----------------------------------------------------------
      -- NO PLAYER NEARBY: STOP AND PLAY IDLE SOUNDS
      ----------------------------------------------------------
      elmo_patrol(self, dtime, def.walk_velocity or 0.8)

      self.jc_attack_timer = nil
      self.jc_monster_detect_timer = nil
      self.jc_monster_seeing_cooldown = nil

      self.jc_monster_idle_timer =
        (self.jc_monster_idle_timer
          or math.random(
            detection and detection.idle_sound_min or 5,
            detection and detection.idle_sound_max or 12
          )) - dtime

      if self.jc_monster_idle_timer <= 0 then
        self.jc_monster_idle_timer = math.random(
          detection and detection.idle_sound_min or 5,
          detection and detection.idle_sound_max or 12
        )

        if def.sounds and def.sounds.no_players_around then
          Monster:play_random_sound(
            self,
            def.sounds.no_players_around,
            def.sounds.idle_gain or 0.1,
            def.sounds.idle_max_hear_distance or 50
          )
        end
      end
    end

    -- Custom AI handles movement, attacking, and sounds.
    return true
  end,
  ----------------------------------------------------------------
  -- DROPS
  ----------------------------------------------------------------
  drops = {
    { name = "animalia:feather", chance = 3, min = 3, max = 15, },
    { name = "mobs_monster:elmo", chance = 6, min = 1, max = 1, },
    { name = "dye:red", chance = 2, min = 5, max = 15, },
    { name = "wool:red", chance = 3, min = 15, max = 99, },
  },

}
-- mobs/unggoy_large.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- UNGGOY LARGE (200%)
----------------------------------------------------------------

monsterDefinitions.unggoy_large = {
  name = "mobs_monster:unggoy_large",
  type = "monster",
  description = "Dakong Unggoy",
  alias = "mobs:unggoy_large",
  nametag = true,
  nametag_color = "#FFFFFF",
  passive = false,
  damage = 12,
  rainbow_damage = 8,
  hp_min = 40,
  hp_max = 40,
  armor = 100,

  visual_size = {x = 2.0, y = 2.0},

  collisionbox = {
    -0.8, -0.02, -0.8,
     0.8,  3.0,   0.8,
  },

  texture = "defense_unggoy.png",
  mesh = "defense_unggoy.b3d",
  egg_texture = "defense_unggoy.png",
  stepheight = 2,
  walk_velocity = 4,
  run_velocity = 4,
  jump_height = 3,
  view_range = 24,
  lava_damage = 8,
  lifetimer = 300,
  attack_type = "dogfight",
  attack_players = true,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = true,
  reach = 3.0,

  detection = {
    enabled = true,
    radius = 20,
    see_through_nodes = false,
    seeing_sound_cooldown = 8,
    idle_sound_min = 12,
    idle_sound_max = 35,
  },
  sounds = {
    hit = {
      "unggoy_hit_01",
      "unggoy_hit_02",
    },
    hit_gain = 0.6,

    seeing_player = {
      "unggoy_alert_01",
      "unggoy_alert_02",
      "unggoy_alert_03",
      "unggoy_alert_04",
    },
    seeing_gain = 0.9,
    seeing_max_hear_distance = 24,

    no_players_around = {
      "unggoy_idle_01",
      "unggoy_idle_02",
      "unggoy_idle_03",
      "unggoy_idle_04",
      "unggoy_idle_05",
      "unggoy_idle_06",
      "unggoy_idle_07",
      "unggoy_idle_08",
    },
    idle_gain = 0.35,
    idle_max_hear_distance = 54,
  },

  animation = {
    speed_normal = 30,
    speed_run = 40,
    stand_start = 0,
    stand_end = 39,
    walk_start = 75,
    walk_end = 99,
    run_start = 75,
    run_end = 99,
    punch_start = 65,
    punch_end = 72,
  },
  do_custom = function(self, dtime, def)
    ------------------------------------------------------------
    -- Face attack target
    ------------------------------------------------------------
    local target = self.attack
    if target and target.get_pos then
      local target_pos = target:get_pos()
      local pos = self.object:get_pos()
      if target_pos and pos then
        local dx = target_pos.x - pos.x
        local dz = target_pos.z - pos.z
        if math.abs(dx) > 0.01 or math.abs(dz) > 0.01 then
          local yaw = math.atan2(-dx, dz)
          self.object:set_yaw(yaw)
          core.after(0, function()
            if self.object and self.object:get_luaentity() then
              self.object:set_yaw(yaw)
            end
          end)
        end
      end

      -- Alert once when we first acquire this target
      if self.jc_alert_target ~= target then
        self.jc_alert_target = target
        if def.sounds and def.sounds.seeing_player then
          Monster:play_random_sound(
            self,
            def.sounds.seeing_player,
            def.sounds.seeing_gain or 0.9,
            def.sounds.seeing_max_hear_distance or 24
          )
        end
        self.jc_monster_seeing_cooldown = def.detection
          and def.detection.seeing_sound_cooldown or 8
      end
    else
      self.jc_alert_target = nil
    end

    ------------------------------------------------------------
    -- Detection / idle (distance-limited, not "any player online")
    ------------------------------------------------------------
    local detection = def.detection
    local pos = self.object:get_pos()
    if not pos then
      return true
    end

    local radius = (detection and detection.radius) or 20

    local closest_player = nil
    local closest_distance = math.huge
    for _, player in ipairs(core.get_connected_players()) do
      local player_pos = player:get_pos()
      if player_pos then
        local distance = vector.distance(pos, player_pos)
        if distance < closest_distance then
          closest_distance = distance
          closest_player = player
        end
      end
    end

    local player_in_range = closest_player and closest_distance <= radius

    if detection and detection.enabled then
      self.jc_monster_seeing_cooldown = math.max(0, (self.jc_monster_seeing_cooldown or 0) - dtime)

      self.jc_monster_detect_timer = (self.jc_monster_detect_timer or 0) - dtime

      if self.jc_monster_detect_timer <= 0 then
        self.jc_monster_detect_timer = 0.4

        local player = Monster:find_visible_player( self, radius, detection.see_through_nodes )

        -- Repeat alert while visible, on cooldown (not only on first attack)
        if player and self.jc_monster_seeing_cooldown <= 0 then
          if def.sounds and def.sounds.seeing_player then
            Monster:play_random_sound(
              self,
              def.sounds.seeing_player,
              def.sounds.seeing_gain or 0.9,
              def.sounds.seeing_max_hear_distance or 24
            )
          end
          self.jc_monster_seeing_cooldown =
            detection.seeing_sound_cooldown or 8
        end
      end
    end

    ------------------------------------------------------------
    -- Idle only if no player within radius
    ------------------------------------------------------------
    if not player_in_range then
      self.jc_monster_idle_timer =
        (self.jc_monster_idle_timer
          or math.random(
            detection and detection.idle_sound_min or 12,
            detection and detection.idle_sound_max or 35
          )) - dtime

      if self.jc_monster_idle_timer <= 0 then
        self.jc_monster_idle_timer = math.random(
          detection and detection.idle_sound_min or 12,
          detection and detection.idle_sound_max or 35
        )
        if def.sounds and def.sounds.no_players_around then
          Monster:play_random_sound(
            self,
            def.sounds.no_players_around,
            def.sounds.idle_gain or 0.5,
            def.sounds.idle_max_hear_distance or 24
          )
        end
      end
    else
      self.jc_monster_idle_timer = nil
    end

    return true
  end,
  spawn = {
    nodes = {
      "ethereal:fiery_dirt",
      "ethereal:dry_dirt",
      "default:desert_sand",
      "default:dirt_with_dry_grass",
      "default:dry_dirt_with_dry_grass",
    },
    min_light = 0,
    max_light = 15,
    chance = 18000,
    min_height = -12,
    max_height = 100,
  },
  on_spawn = function(self, def)
    if math.random() < 0.1 then
      self.jump_height = self.jump_height + math.random() * 2
    end
  end,
  drops = {
    { name = "animalia:feather", chance = 3, min = 3, max = 10, },
    { name = "mobs:meat_raw", chance = 1, min = 2, max = 8 },
    { name = "ethereal:banana", chance = 2, min = 1, max = 3 },
    { name = "ethereal:mushroom_pore", chance = 3, min = 1, max = 2 },
    { name = "ethereal:fire_dust", chance = 4, min = 1, max = 2 },
    { name = "ethereal:crystal_ingot", chance = 15, min = 1, max = 1 },
    { name = "default:steel_ingot", chance = 5, min = 1, max = 3 },
    { name = "default:gold_ingot", chance = 12, min = 1, max = 1 },
    { name = "mobs:lava_orb", chance = 10, min = 1, max = 3 },
  },
}

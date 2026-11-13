-- mobs/handsome_squidward.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- HANDSOME SQUIDWARD
----------------------------------------------------------------

monsterDefinitions.handsome_squidward = {
  name = "mobs_monster:handsome_squidward",
  type = "npc",
  description = "Handsome Squidward",
  alias = "mobs:handsome_squidward",
  nametag = true,
  nametag_color = "#87CEEB",

  passive = true,
  attack_type = nil,
  attack_players = false,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = false,

  damage = 0,
  reach = 0,

  hp_min = 20,
  hp_max = 20,
  armor = 100,

  visual_size = { x = 1.0, y = 1.0 },

  collisionbox = {
    -0.3, -1.0, -0.3,
     0.3,  0.8,  0.3,
  },

  texture = "handsome_squidward.png",
  mesh = "character.b3d",
  egg_texture = "handsome_squidward_inv.png",
  is_egg = false,

  stepheight = 1.1,
  walk_velocity = 0.7,
  run_velocity = 1.2,
  jump_height = 1,
  view_range = 12,

  lava_damage = 5,
  water_damage = 0,
  light_damage = 0,

  animation = {
    speed_normal = 15,
    speed_run = 20,
    stand_start = 0,   stand_end = 79,
    walk_start = 168,  walk_end = 187,
    run_start = 168,   run_end = 187,
  },

  ------------------------------------------------------------
  -- Patrol: just walk back and forth looking handsome
  ------------------------------------------------------------
  patrol = {
    enabled = true,
    first_distance = 8,
    stand_time = 4,
    reached_distance = 0.9,
    look_at_players = true,
    detection_radius = 10,
  },

  detection = {
    enabled = true,
    radius = 10,
    see_through_nodes = true,
    seeing_sound_cooldown = 12,
    idle_sound_min = 8,
    idle_sound_max = 20,
  },

  sounds = {
    hit = {
      "handsome_squidward_hit_01",
    },
    hit_gain = 1.0,

    seeing_player = {
      "handsome_squidward_idle_01",
      "handsome_squidward_idle_02",
      "handsome_squidward_idle_03",
      "handsome_squidward_idle_04",
    },
    seeing_gain = 0.55,
    seeing_max_hear_distance = 28,

    walk = {
      "handsome_squidward_walk_01",
    },
    walk_gain = 0.55,
    walk_max_hear_distance = 40,

    no_players_around = {
      "handsome_squidward_idle_01",
      "handsome_squidward_idle_02",
      "handsome_squidward_idle_03",
      "handsome_squidward_idle_04",
    },
    idle_gain = 0.35,
    idle_max_hear_distance = 40,
  },

  do_custom = function(self, dtime, def)
    local pos = self.object:get_pos()
    if not pos then
      return false
    end

    ------------------------------------------------------------
    -- Walking footstep sound (only while actually moving)
    ------------------------------------------------------------
    local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
    local horizontal_speed = math.sqrt(vel.x * vel.x + vel.z * vel.z)

    local is_walking =
      horizontal_speed > 0.15
      and self.jc_patrol_phase
      and (self.jc_patrol_phase == "walk_to_end"
        or self.jc_patrol_phase == "walk_to_start")

    if is_walking then
      self.jc_walk_sound_timer = (self.jc_walk_sound_timer or 0) - dtime

      if self.jc_walk_sound_timer <= 0 then
        self.jc_walk_sound_timer = 0.65

        if def.sounds and def.sounds.walk then
          Monster:play_random_sound(
            self,
            def.sounds.walk,
            def.sounds.walk_gain or 0.55,
            def.sounds.walk_max_hear_distance or 40
          )
        end
      end
    else
      self.jc_walk_sound_timer = nil
    end

    ------------------------------------------------------------
    -- Player detection (shared by seeing + idle)
    ------------------------------------------------------------
    local detection = def.detection or {}
    local radius = detection.radius or 10
    local see_through = detection.see_through_nodes or false

    local player = Monster:find_visible_player(self, radius, see_through)
    local player_nearby = player ~= nil

    ------------------------------------------------------------
    -- Seeing-player sounds
    ------------------------------------------------------------
    if detection.enabled and player_nearby then
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
              def.sounds.seeing_gain or 0.55,
              def.sounds.seeing_max_hear_distance or 28
            )
          end

          self.jc_monster_seeing_cooldown =
            detection.seeing_sound_cooldown or 12
        end
      end

      -- Don't play idle while a player is around
      self.jc_monster_idle_timer = nil
    else
      ------------------------------------------------------------
      -- Idle sounds when no player is nearby
      ------------------------------------------------------------
      self.jc_monster_detect_timer = nil
      self.jc_monster_seeing_cooldown = nil

      self.jc_monster_idle_timer =
        (self.jc_monster_idle_timer
          or math.random(
            detection.idle_sound_min or 8,
            detection.idle_sound_max or 20
          )) - dtime

      if self.jc_monster_idle_timer <= 0 then
        self.jc_monster_idle_timer = math.random(
          detection.idle_sound_min or 8,
          detection.idle_sound_max or 20
        )

        if def.sounds and def.sounds.no_players_around then
          Monster:play_random_sound(
            self,
            def.sounds.no_players_around,
            def.sounds.idle_gain or 0.35,
            def.sounds.idle_max_hear_distance or 40
          )
        end
      end
    end

    ------------------------------------------------------------
    -- Shared patrol
    ------------------------------------------------------------
    Monster:patrol(self, dtime, def)

    return false
  end,

  on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, direction)

    if self.sounds and self.sounds.hit then
      -- the normal hit path already plays it, but this guarantees it
    end
    self.passive = true
    self.attack = nil
    self.state = "stand"
  end,

  ----------------------------------------------------------------
  -- DROPS
  ----------------------------------------------------------------
  drops = {
    { name = "ethereal:fish_starfish", chance = 10, min = 1, max = 1, },
    { name = "ethereal:fish_squid", chance = 1, min = 2, max = 15, },
    { name = "default:gold_ingot", chance = 1, min = 1, max = 3, },
    { name = "default:mese_crystal", chance = 5, min = 1, max = 1, },
    { name = "jc_party:party_horn", chance = 5, min = 1, max = 1, },
    { name = "jc_party:didgeridoo", chance = 5, min = 1, max = 1, },
  },
}
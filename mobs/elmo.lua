-- mobs/elmo.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- ELMO
----------------------------------------------------------------

monsterDefinitions.elmo = {
  name = "mobs_monster:elmo",
  type = "npc",
  description = "Elmo",
  alias = "mobs:elmo",
  nametag = true,
  nametag_color = "#FF0000",

  passive = true,
  attack_type = "dogfight",
  attack_players = true,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = true,

  damage = 10,
  rainbow_damage = 7,
  reach = 1.5,


  hp_min = 20,
  hp_max = 20,
  armor = 100,

  visual_size = {
    x = 0.5,
    y = 0.4,
    z = 0.5,
  },

  collisionbox = {
    -0.15, -0.4, -0.15,
     0.15,  0.32, 0.15,
  },

  texture = "elmo.png",
  mesh = "character.b3d",
  egg_texture = "elmo_inv.png",
  is_egg = false,

  stepheight = 3.0,
  walk_velocity = 0.8,
  run_velocity = 1.2,
  jump_height = 3,
  view_range = 16,

  lava_damage = 8,

  animation = {
    speed_normal = 15, speed_run = 15,
    stand_start = 0, stand_end = 40,
    walk_start = 168, walk_end = 187,
    run_start = 168, run_end = 187,
    punch_start = 189, punch_end = 198
  },

  ----------------------------------------------------------------
  -- PLAYER DETECTION
  ----------------------------------------------------------------
  detection = {
    enabled = true,
    radius = 30,
    see_through_nodes = true,
    seeing_sound_cooldown = 4,
    idle_sound_min = 4,
    idle_sound_max = 6,
  },

  ----------------------------------------------------------------
  -- ELMO SOUNDS
  ----------------------------------------------------------------
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

  ----------------------------------------------------------------
  -- ELMO ON PUNCH BEHAVIOR
  ----------------------------------------------------------------
  do_punch = function(self, hitter, def)
    if not hitter or not hitter:is_player() then
      return true
    end

    self.passive = false
    self.attack = hitter
    self.state = "attack"
    self.timer = 0
    self.jc_elmo_hostile = true

    if def.can_group_attack ~= false then
      Monster:group_attack(self, hitter)
    end

    return true
  end,
  ----------------------------------------------------------------
  -- ELMO STALKING BEHAVIOR
  ----------------------------------------------------------------
  do_custom = function(self, dtime, def)
    ------------------------------------------------------------
    -- Hostile: let mobs_redo dogfight / custom_attack run
    ------------------------------------------------------------
    if self.jc_elmo_hostile or self.attack then
      self.jc_elmo_hostile = true
      self.passive = false

      local target = self.attack
      if target and target.get_pos then
        local target_pos = target:get_pos()
        local pos = self.object:get_pos()
        if target_pos and pos then
          local dx = target_pos.x - pos.x
          local dz = target_pos.z - pos.z
          if math.abs(dx) > 0.01 or math.abs(dz) > 0.01 then
            self.object:set_yaw(math.atan2(-dx, dz))
          end
        end
      else
        self.jc_elmo_hostile = nil
        self.passive = true
        self.state = "stand"
      end

      return true
    end


    local pos = self.object:get_pos()

    if not pos then
      return false
    end

    local velocity = self.object:get_velocity() or {y = 0}
    local detection = def.detection
    local radius = (detection and detection.radius) or 16

    ------------------------------------------------------------
    -- PLAYER DETECTION
    ------------------------------------------------------------
    local player = Monster:find_visible_player(
      self,
      16,
      false
    )

    ------------------------------------------------------------
    -- ELMO STALKING BEHAVIOR
    ------------------------------------------------------------
    if player then
      local player_pos = player:get_pos()

      if player_pos then
        local dx = player_pos.x - pos.x
        local dz = player_pos.z - pos.z

        local distance = math.sqrt(dx * dx + dz * dz)

        -- Get uncomfortably close, but don't touch the player.
        -- local personal_space = 1.1
        local personal_space = 0.8

        self.object:set_yaw(math.atan2(-dx, dz))

        if distance > personal_space then
          local speed = 0.8

          self.object:set_velocity({
            x = dx / distance * speed,
            y = velocity.y,
            z = dz / distance * speed,
          })

          self:set_animation("walk")
        else
          -- Stand directly in front of the player.
          self.object:set_velocity({
            x = 0,
            y = velocity.y,
            z = 0,
          })

          self:set_animation("stand")
        end
      end
    else
      -- No visible player nearby. Patrol the area.
      elmo_patrol(self, dtime, def.walk_velocity or 0.8)
    end

    ------------------------------------------------------------
    -- DETECTION / SEEING-PLAYER SOUNDS
    ------------------------------------------------------------
    local closest_distance = math.huge

    for _, connected_player in ipairs(core.get_connected_players()) do
      local player_pos = connected_player:get_pos()

      if player_pos then
        local distance = vector.distance(pos, player_pos)

        if distance < closest_distance then
          closest_distance = distance
        end
      end
    end

    local player_in_range = closest_distance <= radius

    if detection and detection.enabled then
      self.jc_monster_seeing_cooldown = math.max(
        0,
        (self.jc_monster_seeing_cooldown or 0) - dtime
      )

      self.jc_monster_detect_timer =
        (self.jc_monster_detect_timer or 0) - dtime

      if self.jc_monster_detect_timer <= 0 then
        self.jc_monster_detect_timer = 0.4

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
    -- IDLE SOUNDS WHEN NO PLAYER IS NEARBY
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

    -- Elmo controls his own movement.
    return false
  end,
  mob_properties = {
    on_die = function(self, pos)
      if not pos then
        return
      end

      core.sound_play("elmo_death_01", {
        pos = pos,
        gain = 1.0,
        max_hear_distance = 40,
      }, true)

      -- Slight offset so it doesn’t clip the corpse
      local spawn_pos = {
        x = pos.x,
        y = pos.y + 2.5,
        z = pos.z,
      }

      local obj = core.add_entity(spawn_pos, "mobs_monster:elmo_large")
      if not obj then
        return
      end

      -- Magical sparkle burst when Giant Elmo appears
      core.add_particlespawner({
        amount = 60,
        time = 0.5,
        minpos = {
          x = spawn_pos.x - 0.8,
          y = spawn_pos.y,
          z = spawn_pos.z - 0.8,
        },
        maxpos = {
          x = spawn_pos.x + 0.8,
          y = spawn_pos.y + 2.5,
          z = spawn_pos.z + 0.8,
        },
        minvel = { x = -1.5, y = 0.5, z = -1.5 },
        maxvel = { x = 1.5, y = 3.0, z = 1.5 },
        minacc = { x = 0, y = -2, z = 0 },
        maxacc = { x = 0, y = -4, z = 0 },
        minexptime = 0.5,
        maxexptime = 1.5,
        minsize = 1,
        maxsize = 3,
        texture = "spark.png",
        glow = 14,
      })

      local ent = obj:get_luaentity()
      if not ent then
        return
      end

      -- Immediately angry at whoever was fighting the small one
      local target = self.attack
      if target and target:is_player() then
        ent.attack = target
        ent.state = "attack"
        ent.timer = 0
        ent.passive = false
      end
    end,
  },

}
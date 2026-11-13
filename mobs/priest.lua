-- mobs/priest.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- PRIEST
----------------------------------------------------------------

monsterDefinitions.priest = {
  name = "mobs_monster:priest",
  type = "npc",
  description = "Padre",
  alias = "mobs:priest",
  nametag = true,
  nametag_color = "#76D7F3",

  passive = true,
  attack_players = false,
  attack_npcs = false,
  attack_animals = false,
  attack_monsters = false,
  can_group_attack = false,

  damage = 0,
  rainbow_damage = 0,

  hp_min = 50,
  hp_max = 50,
  armor = 100,

  collisionbox = {
    -0.3, -1, -0.3,
     0.3,  0.8,  0.3,
  },

  texture = "priest.png",
  mesh = "character.b3d",
  egg_texture = "priest_egg.png",
  is_egg = false,

  stepheight = 1.6,
  walk_velocity = 0,
  run_velocity = 0,
  jump_height = 0,
  view_range = 0,
  lava_damage = 8,
  lifetimer = 300,

  -- Prevent mobs_redo from doing normal walk behavior
  walk_chance = 0,
  stand_chance = 0,

  animation = {
    speed_normal = 15,
    speed_run = 15,

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


  ----------------------------------------------------------------
  -- PLAYER DETECTION
  ----------------------------------------------------------------
  detection = {
    enabled = true,
    radius = 20,
    see_through_nodes = true,
    seeing_sound_cooldown = 7,
    idle_sound_min = 25,
    idle_sound_max = 125,
  },

  ----------------------------------------------------------------
  -- PRIEST SOUNDS
  ----------------------------------------------------------------
  sounds = {
    hit = {
      "priest_sounds_hit_01",
      "priest_sounds_hit_02",
      "priest_sounds_hit_03",
    },
    hit_gain = 1.0,

    seeing_player = {
      "priest_sounds_seeing_player_01", -- Bienvenidos todos a Jast Craft. *****
      "priest_sounds_seeing_player_02", -- Que la paz de Jast Craft esté con ustedes. *****
      -- "priest_sounds_seeing_player_03", -- NOT USED: Tomen asiento y descansen un poco.
      "priest_sounds_seeing_player_04", -- Que encuentren descanso y alegría en este lugar.
      "priest_sounds_seeing_player_05", -- Bienaventurados los jugadores noobs.
      "priest_sounds_seeing_player_06", -- No desprecies al jugador nuevo; todos fuimos novatos alguna vez.
      "priest_sounds_seeing_player_07", -- Que los nuevos jugadores encuentren madera antes de que anochezca.
      "priest_sounds_seeing_player_08", -- Que tu pico nunca se rompa lejos de casa.
      "priest_sounds_seeing_player_09", -- Que encuentres diamantes cuando menos los esperes.
      -- "priest_sounds_seeing_player_10", -- NOT USED: Y que nunca caves directamente hacia abajo.
      "priest_sounds_seeing_player_11", -- Que Jast Craft bendiga tus construcciones. *****
      "priest_sounds_seeing_player_12", -- Que tus caminos sean seguros y tus cofres estén llenos.
      "priest_sounds_seeing_player_13", -- Ve en paz, hijo mío, y no olvides tu armadura.
      "priest_sounds_seeing_player_14", -- No temas a los monstruos. Ellos te temen a ti... probablemente.
      "priest_sounds_seeing_player_15", -- Hijo mío, aléjate de la lava.
      "priest_sounds_seeing_player_16", -- Ama a tu prójimo, pero no le des acceso a tu cofre.
      "priest_sounds_seeing_player_17", -- No pierdas la fe... ni las coordenadas de tu casa.
      "priest_sounds_seeing_player_18", -- El servidor proveerá. Pero trae tu propia comida.
    },
    seeing_gain = 0.7,
    seeing_max_hear_distance = 30,

    no_players_around = {
      "priest_sounds_seeing_player_02",
      "priest_sounds_seeing_player_05",
      "priest_sounds_seeing_player_11",
      "priest_sounds_seeing_player_16",
      "priest_sounds_seeing_player_17",
      "priest_sounds_seeing_player_18",
    },
    idle_gain = 0.3,
    idle_max_hear_distance = 40,
  },

  names = {
    "Padre Miguel",
    "Padre Rafael",
    "Padre Antonio",
    "Padre Mateo",
    "Padre Santiago",
    "Padre Crisdan",
    "Padre Jesús",
    "Padre Jorge",
    "Padre Carlos",
    "Padre Juan",
    "Padre José",
    "Padre Luis",
    "Padre Roberto",
    "Padre Daniel",
  },

  ----------------------------------------------------------------
  -- PUNCH DOES NOTHING TO PRIEST EXCEPT THOSE WITH SERVER PRIV
  ----------------------------------------------------------------
  do_punch = function(self, hitter, def)
    if not hitter or not hitter:is_player() then
      return false
    end

    local player_name = hitter:get_player_name()

    if core.check_player_privs(player_name, {server = true}) then
      return nil
    end

    core.sound_play("player_damage", {
      object = self.object,
      max_hear_distance = 18,
      gain = 1.0,
    })

    Monster:disorient_player(hitter)

    return false
  end,

  ----------------------------------------------------------------
  -- STAY COMPLETELY STILL
  ----------------------------------------------------------------
  do_custom = function(self, dtime, def)
    -- Only despawn if not tamed
    if not self.tamed then
      self.lifetimer = (self.lifetimer or 300) - dtime

      if self.lifetimer <= 0 then
        local pos = self.object:get_pos()
        if pos then
          local players_nearby = false
          for _, player in ipairs(core.get_connected_players()) do
            local ppos = player:get_pos()
            if ppos and vector.distance(pos, ppos) < 20 then
              players_nearby = true
              break
            end
          end

          if not players_nearby then
            local name = self.jc_monster_name or self.name or "unknown"

            -- smoke effect + remove
            core.add_particlespawner({
              amount = 15,
              time = 0.1,
              minpos = pos,
              maxpos = pos,
              minvel = {x = -1, y = 0, z = -1},
              maxvel = {x = 1, y = 2, z = 1},
              minacc = {x = 0, y = -4, z = 0},
              maxacc = {x = 0, y = -8, z = 0},
              minexptime = 0.5,
              maxexptime = 1.5,
              minsize = 2,
              maxsize = 4,
              texture = "mobs_tnt_smoke.png",
            })
            self.object:remove()
            return true
          else
            self.lifetimer = 60
          end
        end
      end
    end

    local pos = self.object:get_pos()

    if not pos then
      return false
    end

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

    if closest_player then
      local player_pos = closest_player:get_pos()

      if player_pos then
        local dx = player_pos.x - pos.x
        local dz = player_pos.z - pos.z

        if math.abs(dx) > 0.01 or math.abs(dz) > 0.01 then
          self.object:set_yaw(math.atan2(-dx, dz))
        end
      end
    end

    local velocity = self.object:get_velocity()

    if velocity then
      self.object:set_velocity({
        x = 0,
        y = velocity.y,
        z = 0,
      })
    end

    self:set_animation("stand")

    --------------------------------------------------------------
    -- PLAYER DETECTION / SEEING SOUND
    --------------------------------------------------------------
    local detection = def.detection

    if detection and detection.enabled then
      self.jc_monster_seeing_cooldown = math.max(0, (self.jc_monster_seeing_cooldown or 0) - dtime)

      self.jc_monster_detect_timer = (self.jc_monster_detect_timer or 0) - dtime

      if self.jc_monster_detect_timer <= 0 then
        self.jc_monster_detect_timer = 0.4

        local player = Monster:find_visible_player(self, detection.radius, detection.see_through_nodes)

        if player and self.jc_monster_seeing_cooldown <= 0 then
          if def.sounds and def.sounds.seeing_player then
            Monster:play_random_sound(
              self,
              def.sounds.seeing_player,
              def.sounds.seeing_gain or 0.2,
              def.sounds.seeing_max_hear_distance or 20
            )
            -- core.log("action", os.date("%Y-%m-%d %H:%M:%S")
              -- .. " [JC_SPECIAL] "
              -- .. (self.jc_monster_name or self.name or "unknown")
              -- .. " sees "
              -- .. player:get_player_name()
              -- .. " - playing seeing sound"
              -- .. " - cooldown: "
              -- .. tostring(detection.seeing_sound_cooldown or 25))
          end

          self.jc_monster_seeing_cooldown = detection.seeing_sound_cooldown or 25
        end
      end
    end

    --------------------------------------------------------------
    -- NO PLAYERS AROUND / IDLE SOUND
    --------------------------------------------------------------
    if not closest_player then
      self.jc_monster_idle_timer = (self.jc_monster_idle_timer or math.random(25, 125)) - dtime

      if self.jc_monster_idle_timer <= 0 then
        self.jc_monster_idle_timer = math.random(detection and detection.idle_sound_min or 25, detection and detection.idle_sound_max or 125 )

        if def.sounds and def.sounds.no_players_around then
          Monster:play_random_sound(
            self,
            def.sounds.no_players_around,
            def.sounds.idle_gain or 0.5,
            def.sounds.idle_max_hear_distance or 20
          )
        end
      end
    else
      self.jc_monster_idle_timer = nil
    end

    return false
  end,


  drops = {},
}
-- mobs/castle_guard.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- CASTLE GUARD
----------------------------------------------------------------

monsterDefinitions.castle_guard = {
  name = "mobs_monster:castle_guard",
  type = "npc",
  description = "Castle Guard",
  alias = "mobs:castle_guard",
  nametag = true,
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
  lifetimer = 300, -- it was 20000
  attack_monsters = true,
  can_group_attack = true,
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
  -- patrol = {
    -- enabled = true,
    -- radius = 5,
    -- reached_distance = 1.0,
  -- },
  patrol = {
    enabled = true,

    radius = 5,

    stand_time = 5,

    first_distance = 5,

    reached_distance = 0.8,

    avoid_jumps = true,

    look_at_players = true,

    detection_radius = 20,
  },

  ----------------------------------------------------------------
  -- PLAYER DETECTION
  ----------------------------------------------------------------
  detection = {
    enabled = true,
    radius = 20,
    see_through_nodes = false,
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
  -- CUSTOM CASTLE GUARD HANDLING FOR DEATH
  ----------------------------------------------------------------
  do_custom = function(self, dtime, def)
    -- Only despawn if not tamed
    if not self.tamed then
      self.lifetimer = (self.lifetimer or 300) - dtime

      -- self.jc_log_timer = (self.jc_log_timer or 0) - dtime
      -- if self.jc_log_timer <= 0 then
        -- self.jc_log_timer = 30
        -- local name = self.jc_monster_name or self.name or "unknown"
        -- core.log("action", string.format( "[JC Castle Guard Despawn] '%s' timer = %.1f seconds remaining", name, self.lifetimer ))
      -- end

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
            -- core.log("action", string.format("[JC Castle Guard Despawn] '%s' EXPIRED and removed at %s", name, core.pos_to_string(pos) ))

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
            -- local name = self.jc_monster_name or self.name or "unknown"
            -- core.log("action", string.format("[JC Castle Guard Despawn] '%s' player nearby, timer reset to 60s", name ))
          end
        end
      end
    end

    return true  -- continue normal behavior
  end,
  ----------------------------------------------------------------
  -- DROPS
  ----------------------------------------------------------------
  drops = {
    { name = "animalia:feather", chance = 4, min = 1, max = 5, },
    { name = "default:sword_steel", chance = 4, min = 1, max = 1, },
    { name = "shields:shield_steel", chance = 15, min = 1, max = 1, },
    { name = "3d_armor:helmet_steel", chance = 8, min = 1, max = 1, },
    { name = "3d_armor:chestplate_steel", chance = 8, min = 1, max = 1, },
    { name = "3d_armor:leggings_steel", chance = 8, min = 1, max = 1, },
    { name = "3d_armor:boots_steel", chance = 8, min = 1, max = 1, },

  },
}

----------------------------------------------------------------
-- JC_SPECIAL - MOBS_REDO MONSTERS
--
-- Unified mobs_redo monster registration.
--
-- Monsters are defined in the "monsterDefinitions" table below.
-- Common monster functionality is handled by Monster.
--
-- Monster definitions are maintained in individual files under mobs/.
--
----------------------------------------------------------------

if not core.get_modpath("mobs") then
  core.log("warning", "[jc_special] mobs_redo not found, monsters not registered.")
  return
end

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- LETTING THE PYTHON LOCALE PO CREATOR SEE THE DANG NAMES
----------------------------------------------------------------
local temp_trooper_name_for_translation = S("Trooper")
local temp_castle_gaurd_name_for_translation = S("Castle Guard")
-- local temp_priest_name_for_translation = S("Priest")
-- mobs_monster:priest 0 15 1 20 3

----------------------------------------------------------------
-- SHARED SETTINGS
----------------------------------------------------------------

PLAYER_NAME_COLOR = "#FFFF00"

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

registered_monsters = {}

----------------------------------------------------------------
-- LAST ATTACKERS
--
-- Indexed by player name.
--
-- This is shared by every monster instead of having one table
-- per monster.
----------------------------------------------------------------

last_attackers = {}

----------------------------------------------------------------
-- MONSTER HELPER METHODS
----------------------------------------------------------------
Monster = {}

----------------------------------------------------------------
-- RANDOM SOUND
----------------------------------------------------------------
function Monster:play_random_sound(self, sounds, gain, max_hear_distance)
  if not sounds or #sounds == 0 then
    return
  end

  local pos = self.object:get_pos()

  if not pos then
    return
  end

  max_hear_distance = max_hear_distance or 20

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

      if distance <= max_hear_distance then
        local meta = player:get_meta()

        local monster_sounds = meta:get_string("jc_special_sounds_monsters")

        -- Monster sounds are ON by default.
        if monster_sounds ~= "off" then
          core.sound_play(sound, {
            to_player = player:get_player_name(),
            pos = pos,
            gain = gain or 1.0,
            max_hear_distance = max_hear_distance,
          })
        end
      end
    end
  end
end

----------------------------------------------------------------
-- FIND A VISIBLE PLAYER
----------------------------------------------------------------
function Monster:find_visible_player(self, radius, see_through_nodes)
  local pos = self.object:get_pos()
  if not pos then
    return nil
  end

  for _, object in ipairs(core.get_objects_inside_radius(pos, radius)) do
    if object:is_player() then
      local player_pos = object:get_pos()

      if player_pos then
        if see_through_nodes or core.line_of_sight(pos, player_pos, 1) then
          return object
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
  -- New: respect the per-monster setting
  local def = registered_monsters[self.name]
  if def and def.can_group_attack == false then
    return
  end

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
-- CHECK PATROL PATH
--
-- Checks the ground along the patrol route.
--
-- Returns false if the guard would encounter a node that
-- requires jumping or otherwise cannot walk normally.
----------------------------------------------------------------
function Monster:patrol_path_is_clear(self, start_pos, target_pos)
  local dx = target_pos.x - start_pos.x
  local dz = target_pos.z - start_pos.z

  local distance = math.sqrt( dx * dx + dz * dz )

  if distance <= 0 then
    return true
  end

  local steps = math.ceil(distance)

  for i = 1, steps do

    local fraction = i / steps

    local x = start_pos.x + dx * fraction
    local z = start_pos.z + dz * fraction

    local ground_y = math.floor(start_pos.y + 0.5)

    local ground_pos = {
      x = math.floor(x + 0.5),
      y = ground_y,
      z = math.floor(z + 0.5),
    }

    local node_below = core.get_node({
      x = ground_pos.x,
      y = ground_pos.y - 1,
      z = ground_pos.z,
    })

    local node_feet = core.get_node({
      x = ground_pos.x,
      y = ground_pos.y,
      z = ground_pos.z,
    })

    local node_head = core.get_node({
      x = ground_pos.x,
      y = ground_pos.y + 1,
      z = ground_pos.z,
    })

    local below_def = core.registered_nodes[node_below.name]
    local feet_def = core.registered_nodes[node_feet.name]
    local head_def = core.registered_nodes[node_head.name]

    ------------------------------------------------------------
    -- Need solid ground.
    ------------------------------------------------------------
    if not below_def
      or below_def.walkable ~= true then
      return false
    end

    ------------------------------------------------------------
    -- Feet and head must be clear.
    ------------------------------------------------------------
    if feet_def and feet_def.walkable then
      return false
    end

    if head_def and head_def.walkable then
      return false
    end
  end

  return true
end

----------------------------------------------------------------
-- PATROL
----------------------------------------------------------------

function Monster:patrolOLD(self, dtime, def)
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
-- PATROL (ATTEMPT AT NEW)
----------------------------------------------------------------
function Monster:patrol(self, dtime, def)
  local patrol = def.patrol

  if not patrol
    or not patrol.enabled then
    return
  end

  local pos = self.object:get_pos()

  if not pos then
    return
  end

  --------------------------------------------------------------
  -- INITIALIZE PATROL
  --------------------------------------------------------------
  if not self.jc_patrol_initialized then
    self.jc_patrol_initialized = true

    ------------------------------------------------------------
    -- Remember the exact starting position.
    ------------------------------------------------------------
    self.jc_patrol_start = {
      x = pos.x,
      y = pos.y,
      z = pos.z,
    }

    ------------------------------------------------------------
    -- Remember the direction the monster was originally facing.
    ------------------------------------------------------------
    self.jc_patrol_yaw = self.object:get_yaw()

    ------------------------------------------------------------
    -- Build the two patrol endpoints.
    ------------------------------------------------------------
    local distance = patrol.first_distance or patrol.radius or 5

    local dx = -math.sin(self.jc_patrol_yaw)
    local dz = math.cos(self.jc_patrol_yaw)

    self.jc_patrol_end = {
      x = self.jc_patrol_start.x + dx * distance,
      y = self.jc_patrol_start.y,
      z = self.jc_patrol_start.z + dz * distance,
    }

    ------------------------------------------------------------
    -- Start by standing.
    ------------------------------------------------------------
    self.jc_patrol_phase = "stand_start"

    self.jc_patrol_timer =
      patrol.stand_time or 5

    self.jc_patrol_target = nil

    self.object:set_velocity({
      x = 0,
      y = self.object:get_velocity().y,
      z = 0,
    })

    self.object:set_yaw(self.jc_patrol_yaw)

    self:set_animation("stand")

    return
  end

  --------------------------------------------------------------
  -- LOOK AT PLAYERS
  --
  -- This temporarily overrides patrol movement.
  --
  -- IMPORTANT:
  -- We do NOT change the patrol phase or target here.
  -- When the player disappears, the guard simply continues
  -- exactly where it left off.
  --------------------------------------------------------------
  if patrol.look_at_players then
    local detection = def.detection or {}

    local see_through_nodes = detection.see_through_nodes or false

    local player = Monster:find_visible_player( self, patrol.detection_radius or 20, see_through_nodes )

    if player then

      ----------------------------------------------------------
      -- Stop horizontal movement.
      ----------------------------------------------------------
      self.object:set_velocity({
        x = 0,
        y = self.object:get_velocity().y,
        z = 0,
      })

      ----------------------------------------------------------
      -- Look at player.
      ----------------------------------------------------------
      local player_pos = player:get_pos()

      if player_pos then

        local dx = player_pos.x - pos.x
        local dz = player_pos.z - pos.z

        if math.abs(dx) > 0.01
          or math.abs(dz) > 0.01 then

          local yaw = math.atan2(-dx, dz)

          self.object:set_yaw(yaw)
        end
      end

      self:set_animation("stand")

      ----------------------------------------------------------
      -- Do NOT advance the patrol timer while watching.
      ----------------------------------------------------------
      return
    end
  end

  --------------------------------------------------------------
  -- STAND AT START
  --------------------------------------------------------------
  if self.jc_patrol_phase == "stand_start" then

    self.object:set_velocity({
      x = 0,
      y = self.object:get_velocity().y,
      z = 0,
    })

    self.object:set_yaw(self.jc_patrol_yaw)

    self:set_animation("stand")

    self.jc_patrol_timer =
      self.jc_patrol_timer - dtime

    if self.jc_patrol_timer <= 0 then

      ----------------------------------------------------------
      -- Walk toward the far endpoint.
      ----------------------------------------------------------
      self.jc_patrol_target = self.jc_patrol_end
      self.jc_patrol_phase = "walk_to_end"

    end

    return
  end

  --------------------------------------------------------------
  -- WALK TO END
  --------------------------------------------------------------
  if self.jc_patrol_phase == "walk_to_end" then

    local target = self.jc_patrol_end

    local tx = target.x - pos.x
    local tz = target.z - pos.z

    local distance = math.sqrt( tx * tx + tz * tz )

    ------------------------------------------------------------
    -- Reached endpoint.
    ------------------------------------------------------------
    if distance <= (patrol.reached_distance or 0.8) then

      self.object:set_velocity({
        x = 0,
        y = self.object:get_velocity().y,
        z = 0,
      })

      self.object:set_yaw(self.jc_patrol_yaw)

      self:set_animation("stand")

      self.jc_patrol_phase = "stand_end"

      self.jc_patrol_timer =
        patrol.stand_time or 5

      return
    end

    ------------------------------------------------------------
    -- Walk toward endpoint.
    ------------------------------------------------------------
    local move_x = tx / distance
    local move_z = tz / distance

    local velocity = self.object:get_velocity()

    local speed = def.walk_velocity or 1

    self.object:set_velocity({
      x = move_x * speed,
      y = velocity.y,
      z = move_z * speed,
    })

    ------------------------------------------------------------
    -- Face movement direction.
    ------------------------------------------------------------
    local yaw = math.atan2(-move_x, move_z)

    if def.backwards then
      yaw = yaw + math.pi
    end

    self.object:set_yaw(yaw)

    self:set_animation("walk")

    return
  end

  --------------------------------------------------------------
  -- STAND AT END
  --------------------------------------------------------------
  if self.jc_patrol_phase == "stand_end" then

    self.object:set_velocity({
      x = 0,
      y = self.object:get_velocity().y,
      z = 0,
    })

    self:set_animation("stand")

    self.jc_patrol_timer =
      self.jc_patrol_timer - dtime

    if self.jc_patrol_timer <= 0 then

      ----------------------------------------------------------
      -- Walk back to the original spawn position.
      ----------------------------------------------------------
      self.jc_patrol_target = self.jc_patrol_start
      self.jc_patrol_phase = "walk_to_start"

    end

    return
  end

  --------------------------------------------------------------
  -- WALK BACK TO START
  --------------------------------------------------------------
  if self.jc_patrol_phase == "walk_to_start" then

    local target = self.jc_patrol_start

    local tx = target.x - pos.x
    local tz = target.z - pos.z

    local distance = math.sqrt( tx * tx + tz * tz )

    ------------------------------------------------------------
    -- Reached starting point.
    ------------------------------------------------------------
    if distance <= (patrol.reached_distance or 0.8) then

      self.object:set_velocity({
        x = 0,
        y = self.object:get_velocity().y,
        z = 0,
      })

      self.object:set_yaw(self.jc_patrol_yaw)

      self:set_animation("stand")

      self.jc_patrol_phase = "stand_start"

      self.jc_patrol_timer =
        patrol.stand_time or 5

      return
    end

    ------------------------------------------------------------
    -- Walk toward starting point.
    ------------------------------------------------------------
    local move_x = tx / distance
    local move_z = tz / distance

    local velocity = self.object:get_velocity()

    local speed = def.walk_velocity or 1

    self.object:set_velocity({
      x = move_x * speed,
      y = velocity.y,
      z = move_z * speed,
    })

    ------------------------------------------------------------
    -- Face movement direction.
    ------------------------------------------------------------
    local yaw = math.atan2(-move_x, move_z)

    if def.backwards then
      yaw = yaw + math.pi
    end

    self.object:set_yaw(yaw)

    self:set_animation("walk")

    return
  end
end

----------------------------------------------------------------
-- COMMON SPAWN
----------------------------------------------------------------
function Monster:on_spawn(self, def)
  local name

  ----------------------------------------------------------------
  -- Keep an existing name.
  --
  -- mobs_redo restores self.jc_monster_name when a captured mob
  -- is spawned again, so don't generate a new name in that case.
  ----------------------------------------------------------------
  if self.jc_monster_name then
    name = self.jc_monster_name
  elseif def.names and #def.names > 0 then
    name = def.names[math.random(#def.names)]
    self.jc_monster_name = name
  else
    name = def.description
    self.jc_monster_name = name
  end

  ----------------------------------------------------------------
  -- Set nametag
  ----------------------------------------------------------------
  if def.nametag ~= false then
    self.nametag = core.colorize(def.nametag_color or "#FFFFFF", name )
  else
    self.nametag = ""
  end

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

  if def.sounds and def.sounds.attack then
    Monster:play_random_sound(
      self,
      def.sounds.attack,
      def.sounds.attack_gain or 1.0,
      def.sounds.attack_max_hear_distance or 24
    )
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
-- Priest Disorient Player
----------------------------------------------------------------
local priest_disorientation = {}

function Monster:disorient_player(player)
  local player_name = player:get_player_name()
  local existing = priest_disorientation[player_name]

  if existing then
    existing.generation = existing.generation + 1
    existing.expires = core.get_us_time() + 30000000
  else
    existing = {
      generation = 1,
      expires = core.get_us_time() + 30000000,
    }

    priest_disorientation[player_name] = existing

    existing.hud_id = player:hud_add({
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      offset = {x = 0, y = 0},
      text = "priest_blue_overlay.png^[opacity:200",
      alignment = {x = 0, y = 0},
      scale = {x = -100, y = -100},
    })
  end

  local generation = existing.generation

  -- Refresh the full-strength overlay
  player:hud_change(
    existing.hud_id,
    "text",
    "priest_blue_overlay.png^[opacity:200"
  )

  -- Apply a temporary movement slowdown while disoriented
  local physics = player:get_physics_override()
  player:set_physics_override({ speed = physics.speed * 0.2 })

  core.after(30, function()
    local effect = priest_disorientation[player_name]

    if not effect or effect.generation ~= generation or not player:is_player() then
      return
    end

    player:set_physics_override({ speed = 1.0 })
    player:hud_remove(effect.hud_id)
    priest_disorientation[player_name] = nil
  end)

  local fade_steps = {
    {delay = 5, opacity = 175},
    {delay = 10, opacity = 150},
    {delay = 15, opacity = 120},
    {delay = 20, opacity = 85},
    {delay = 25, opacity = 45},
    {delay = 30, opacity = 0},
  }

  for _, step in ipairs(fade_steps) do
    core.after(step.delay, function()
      local effect = priest_disorientation[player_name]

      if not effect or effect.generation ~= generation or not player:is_player() then
        return
      end

      if step.opacity == 0 then
        player:hud_remove(effect.hud_id)
        priest_disorientation[player_name] = nil
        return
      end

      player:hud_change(
        effect.hud_id,
        "text",
        "priest_blue_overlay.png^[opacity:" .. step.opacity
      )
    end)
  end
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

      local player = Monster:find_visible_player(self, detection.radius, detection.see_through_nodes or false)

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

    ------------------------------------------------------------
    -- Our patrol system owns movement while the monster is
    -- not attacking.
    --
    -- Returning false tells mobs_redo not to continue with
    -- its normal movement/idle processing and overwrite the
    -- velocity we just set.
    ------------------------------------------------------------
    return false
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
    visual_size = def.visual_size or {x = 1, y = 1},
    collisionbox = def.collisionbox
      or {
        -0.3, -1, -0.3,
         0.3,  0.8,  0.3,
      },
    visual = "mesh",
    mesh = def.mesh or "character.b3d",
    textures = def.textures or {
      {def.texture},
    },
    follow = def.follow or {},
    makes_footstep_sound = def.makes_footstep_sound ~= false,
    stepheight = def.stepheight or 1.6,
    walk_velocity = def.walk_velocity or 1,
    run_velocity = def.run_velocity or 4,
    jump_height = def.jump_height or 4,
    view_range = def.view_range or 8,
    lava_damage = def.lava_damage or 8,

    attack_players = def.attack_players ~= false,
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
    -- ON RIGHT CLICK
    --------------------------------------------------------------
    on_rightclick = function(self, clicker)
      if def.on_rightclick then
        return def.on_rightclick(self, clicker, def)
      end
    end,
    --------------------------------------------------------------
    -- HIT BY PLAYER
    --------------------------------------------------------------
    do_punch = function(self, hitter)
      if hitter and hitter.is_player and hitter:is_player() then
        if def.sounds and def.sounds.hit then
          Monster:play_random_sound( self, def.sounds.hit, def.sounds.hit_gain or 1.0 )
        end

        -- Only call group attack if allowed
        if def.can_group_attack ~= false then
          Monster:group_attack(self, hitter)
        end
      end

      if def.do_punch then
        return def.do_punch( self, hitter, def )
      end
    end,

    on_die = function(self, pos)
      if def.on_die then
        def.on_die(self, pos, def)
      end
    end,

    on_step = function(self, dtime)
      --------------------------------------------------------------
      -- Face attack target.
      --
      -- def.yaw_offset: extra rotation for meshes that don't face +Z
      --   (e.g. unggoy: math.pi / 2  or  -math.pi / 2)
      --------------------------------------------------------------
      if self.attack and self.attack.get_pos then
        local target_pos = self.attack:get_pos()
        local pos = self.object:get_pos()

        if pos and target_pos then
          local dx = target_pos.x - pos.x
          local dz = target_pos.z - pos.z

          if math.abs(dx) > 0.01 or math.abs(dz) > 0.01 then
            local yaw = math.atan2(-dx, dz) + (def.yaw_offset or 0)
            self.object:set_yaw(yaw)
          end
        end
      end

      --------------------------------------------------------------
      -- Backwards walking.
      --------------------------------------------------------------
      if def.backwards and self.state == "walk" then
        local velocity = self.object:get_velocity()

        if velocity then
          local dx = velocity.x
          local dz = velocity.z
          local speed = math.sqrt(dx * dx + dz * dz)

          if speed > 0.05 then
            local yaw = math.atan2(dx, dz) + math.pi + (def.yaw_offset or 0)
            self.object:set_yaw(yaw)
          end
        end
      end

      --------------------------------------------------------------
      -- Custom on_step.
      --------------------------------------------------------------
      if def.on_step then
        def.on_step(self, dtime)
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
    -- ON DIE LOGIC
    --------------------------------------------------------------
    on_die = function(self, pos)
      if def.on_die then
        def.on_die(self, pos, def)
      end
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

    active_object_count = def.spawn.active_object_count,
    min_height = def.spawn.min_height,
    max_height = def.spawn.max_height,
    day_toggle = def.spawn.day_toggle,
  })
end

----------------------------------------------------------------
-- REGISTER EGG
----------------------------------------------------------------
function Monster:register_egg(def)
  --[[
  mobs:register_egg(
    mob,
    desc,
    background,
    addegg,
    no_creative,
    can_spawn_protect
  )
  ]]
  mobs:register_egg(
    def.name,
    S(def.description),
    def.egg_texture or def.texture,
    def.is_egg == false and 0 or 1
  )
end

----------------------------------------------------------------
-- REGISTER ALIAS
----------------------------------------------------------------
function Monster:register_alias(def)
  local aliases = def.aliases or {def.alias}

  if not def.aliases and not def.alias then
    aliases = {"mobs:" .. def.name:match("^[^:]+:(.+)$")}
  end

  for _, alias in ipairs(aliases) do
    if alias and alias ~= "" then
      mobs:alias_mob(alias, def.name)
    end
  end
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
-- ELMO PATROL
----------------------------------------------------------------
function elmo_patrol(self, dtime, speed)
  local pos = self.object:get_pos()

  if not pos then
    return
  end

  self.jc_patrol_timer = (self.jc_patrol_timer or 0) - dtime

  local target = self.jc_patrol_target

  if not target or self.jc_patrol_timer <= 0 then
    local angle = math.random() * math.pi * 2
    local distance = math.random(4, 10)

    target = {
      x = pos.x + math.cos(angle) * distance,
      y = pos.y,
      z = pos.z + math.sin(angle) * distance,
    }

    self.jc_patrol_target = target
    self.jc_patrol_timer = math.random(5, 12)
  end

  local dx = target.x - pos.x
  local dz = target.z - pos.z
  local distance = math.sqrt(dx * dx + dz * dz)

  if distance < 1.0 then
    self.jc_patrol_target = nil
    self.object:set_velocity({
      x = 0,
      y = (self.object:get_velocity() or {y = 0}).y,
      z = 0,
    })
    self:set_animation("stand")
    return
  end

  self.object:set_yaw(math.atan2(-dx, dz))

  local velocity = self.object:get_velocity() or {y = 0}

  self.object:set_velocity({
    x = dx / distance * speed,
    y = velocity.y,
    z = dz / distance * speed,
  })

  self:set_animation("walk")
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
monsterDefinitions = {}

dofile(modpath .. "/mobs/castle_guard.lua")
dofile(modpath .. "/mobs/trooper.lua")
dofile(modpath .. "/mobs/priest.lua")
dofile(modpath .. "/mobs/rhino.lua")
dofile(modpath .. "/mobs/michael_jackson.lua")
dofile(modpath .. "/mobs/unggoy_large.lua")
dofile(modpath .. "/mobs/unggoy.lua")
dofile(modpath .. "/mobs/elmo_large.lua")
dofile(modpath .. "/mobs/elmo.lua")
dofile(modpath .. "/mobs/handsome_squidward.lua")
dofile(modpath .. "/mobs/zombie.lua")

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
  core.log("action", string.format("[MOB KILLED PLAYER] %s was eliminated by %s (%s) at %s", player_name, monster_name, def.description, core.pos_to_string(death_pos, 0) ) )
  core.chat_send_all( S("@1 was eliminated by @2!", core.colorize(PLAYER_NAME_COLOR, player_name ), core.colorize( def.nametag_color or "#FFFFFF", monster_name ) ) )
end)


--------------------------------------------------------
-- SPECIAL MOB ENTITIES
--------------------------------------------------------
mobs:register_arrow("jc_special:rhino_bullet", {
  visual = "sprite",
  visual_size = {x = 0.75, y = 0.75},
  textures = {"mobs_rhino_bullet.png"},
  velocity = 15,

  hit_player = function(self, player)
    local s = self.object:get_pos()
    local p = player:get_pos()

    local vec = {
      x = s.x - p.x,
      y = s.y - p.y,
      z = s.z - p.z,
    }

    player:punch(self.object, 1.0, {
      full_punch_interval = 1.0,
      damage_groups = {
        fleshy = 10,
      },
    }, vec)
  end,

  hit_node = function(self, pos)
  end,
})

--------------------------------------------------------
-- /spawnmob command
--------------------------------------------------------
core.register_chatcommand("spawnmob", {
  params = "<mob> [<x>,<y>,<z>|<player>]",
  description = "Spawn a mob near the player, at a position, or at another player's position",
  privs = {server = true},
  func = function(name, param)
    local mob, location = param:match("^(%S+)%s+(.+)$")

    if not mob then
      mob = param:match("^(%S+)$")
    end

    if not mob or mob == "" then
      return false, "Usage: /spawnmob <mob> [<x>,<y>,<z>|<player>]"
    end

    local player = core.get_player_by_name(name)

    if not player then
      return false, "Player not found."
    end

    local pos
    local target_player

    if location then
      location = location:match("^%s*(.-)%s*$")

      -- Check for a player name first.
      target_player = core.get_player_by_name(location)

      if target_player then
        pos = target_player:get_pos()
      else
        -- Otherwise, try x,y,z coordinates.
        local x, y, z = location:match("^%s*(-?[%d.]+)%s*,%s*(-?[%d.]+)%s*,%s*(-?[%d.]+)%s*$")

        if not x then
          return false, "Location must be x,y,z coordinates or an online player's username."
        end

        pos = {
          x = tonumber(x),
          y = tonumber(y),
          z = tonumber(z),
        }
      end
    else
      local player_pos = player:get_pos()

      for distance = 2, 10 do
        local found = false

        for dx = -distance, distance do
          for dz = -distance, distance do
            if math.abs(dx) == distance or math.abs(dz) == distance then
              local test_pos = {
                x = math.floor(player_pos.x + dx + 0.5),
                y = math.floor(player_pos.y + 0.5),
                z = math.floor(player_pos.z + dz + 0.5),
              }

              local node_below = core.get_node_or_nil({
                x = test_pos.x,
                y = test_pos.y - 1,
                z = test_pos.z,
              })

              local node_at = core.get_node_or_nil(test_pos)
              local node_above = core.get_node_or_nil({
                x = test_pos.x,
                y = test_pos.y + 1,
                z = test_pos.z,
              })

              if node_below and node_at and node_above then
                local below_def = core.registered_nodes[node_below.name]
                local at_def = core.registered_nodes[node_at.name]
                local above_def = core.registered_nodes[node_above.name]

                if below_def and at_def and above_def
                    and below_def.walkable
                    and not at_def.walkable
                    and not above_def.walkable then
                  pos = test_pos
                  found = true
                  break
                end
              end
            end
          end

          if found then
            break
          end
        end

        if pos then
          break
        end
      end

      if not pos then
        return false, "Could not find a free place to spawn the mob."
      end
    end

    if not core.registered_entities[mob] then
      return false, "Unknown entity: " .. mob
    end

    local object = core.add_entity(pos, mob)

    if not object then
      return false, "Failed to spawn " .. mob
    end

    if target_player then
      return true, "Spawned " .. mob .. " at " .. location .. "'s position: " .. core.pos_to_string(pos, 0)
    end

    return true, "Spawned " .. mob .. " at " .. core.pos_to_string(pos)
  end,
})

----------------------------------------------------------------
-- DONE
----------------------------------------------------------------
core.log("action", "[jc_special] Unified mobs_redo monster system loaded.")

-- mobs/trooper.lua
local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

----------------------------------------------------------------
-- TROOPER
----------------------------------------------------------------

monsterDefinitions.trooper = {
  name = "mobs_monster:trooper",
  type = "npc",
  description = "Trooper",
  alias = "mobs:trooper",
  nametag = true,
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
  follow = {"flowers:mushroom_red"},
  stepheight = 1.6,
  walk_velocity = 1,
  run_velocity = 4,
  jump_height = 4,
  view_range = 8,
  lava_damage = 8,
  lifetimer = 300,
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
    "Will Smith",
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
    "MrsPhil",
    "MrPill",
    "Totally Not MrPhil",
    "iisu's inner thoughts",
    "iisu's intrusive thoughts",
    "iisu's search history",
    "iisu's good twin",
    "iisn't",
    "iisuless",
    "iisue",
    "iissue",
    "iisu's alt account",
    "not iisu",
    "iisus christ",
    "iisus iscariot",
    "talamh's Dirt Man",
    "talamh's Dirt Dealer",
    "totally not talamh",
    "talamh's Dirt Smuggler",
    "talamh's undercover account",
    "talamh's Dirt Witness",
    "talamh's Dirty Alibi",
    "talamh's dirty secret",
    "talamh's Dirt Accountant",
    "Definitely Not Dirt",
    "Probably Dirt",
    "Legally Considered Dirt",
    "Istie Bistie",
    "Istie Bistie Spider",
    "Istie the Biscuit",
    "isn'tie",
    "eastie",
    "westie",
    "Feisty Istie",
    "The Real istie",
    "Not Your Average Istie",
    "istieologist",
    "PRIDE",
    "Swallow Your PRIDE",
    "PRIDEFUL",
    "PRIDELESS",
    "SPONGEBOB",
    "errorstazi",
    "The Real Stasi",
    "I Was Told There'd Be Cake",
    "Captain Nemo",
    "Nemo Not The Fish",
    "Captain Memo",
    "Captain Neko",
    "jesus crisdan",
    "crisdan #2",
    "crisdan #3",
    "crisdan #9",
    "crisdan #67",
    "crisdan #81",
    "Ooo Me So Trooper",
    "Plan B",
    "Plan C",
    "Plan Z",
    "YOLO",
    "Scruffy",
    "not tilt",
    "tlit",
    "tiIt",
    "just a little tilt",
    "not tilt (maybe just a little)",
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
  -- spawn = {
    -- nodes = { "moreblocks:checker_stone_tile", },
    -- min_light = 0,
    -- max_light = 15,
    -- chance = 7000,
    -- min_height = -2,
    -- max_height = 30,
  -- },

  ----------------------------------------------------------------
  -- CUSTOM TROOPER HANDLING FOR DEATH
  ----------------------------------------------------------------
  do_custom = function(self, dtime, def)
    -- Only despawn if not tamed
    if not self.tamed then
      self.lifetimer = (self.lifetimer or 300) - dtime

      -- self.jc_log_timer = (self.jc_log_timer or 0) - dtime
      -- if self.jc_log_timer <= 0 then
        -- self.jc_log_timer = 30
        -- local name = self.jc_monster_name or self.name or "unknown"
        -- core.log("action", string.format( "[JC Trooper Despawn] '%s' timer = %.1f seconds remaining", name, self.lifetimer ))
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
            -- core.log("action", string.format("[JC Trooper Despawn] '%s' EXPIRED and removed at %s", name, core.pos_to_string(pos) ))

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
            -- core.log("action", string.format("[JC Trooper Despawn] '%s' player nearby, timer reset to 60s", name ))
          end
        end
      end
    end

    return true  -- continue normal behavior
  end,
    ----------------------------------------------------------------
  -- TROOPER TAMING
  ----------------------------------------------------------------
  --[[
  on_rightclick = function(self, clicker)
    if not clicker or not clicker:is_player() then
      return
    end

    local player_name = clicker:get_player_name()

    --------------------------------------------------------------
    -- 1. Feed / Tame
    --------------------------------------------------------------
    if mobs:feed_tame(self, clicker, 4, true, true) then
      if self.tamed and self.jc_monster_name then
        self.owner = player_name
        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({nametag = self.nametag})
        end
      end
      return
    end

    --------------------------------------------------------------
    -- 2. Protect (only allowed if already tamed)
    --------------------------------------------------------------
    if not self.tamed then
      -- Optional message so the player understands
      core.chat_send_player(player_name, S("This Trooper must be tamed before you can protect it."))
      return
    end

    if mobs:protect(self, clicker) then
      return
    end

    --------------------------------------------------------------
    -- 3. Capture (only allowed if already tamed)
    --------------------------------------------------------------
    if self.tamed then
      self.owner = player_name

      if self.jc_monster_name then
        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")
      end

      if mobs:capture_mob(self, clicker, 30, 50, 80, false, nil) then
        return
      end
    end
  end,

  on_rightclick = function(self, clicker)
    if not clicker or not clicker:is_player() then
      return
    end

    local player_name = clicker:get_player_name()

    --------------------------------------------------------------
    -- 1. Feed / Tame
    --------------------------------------------------------------
    if mobs:feed_tame(self, clicker, 4, true, true) then
      if self.tamed and self.jc_monster_name then
        self.owner = player_name

        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({ nametag = self.nametag })
        end
      end

      return
    end

    --------------------------------------------------------------
    -- 2. Must be tamed
    --------------------------------------------------------------
    if not self.tamed then
      core.chat_send_player(player_name, S("This Trooper must be tamed before you can protect it.") )
      return
    end

    --------------------------------------------------------------
    -- 3. Ownership check
    --
    -- The owner can use their Trooper normally.
    -- Players with the ban privilege can take ownership.
    --------------------------------------------------------------
    local has_ban_priv = core.check_player_privs(player_name, { ban = true })
    if self.owner and self.owner ~= "" and self.owner ~= player_name and not has_ban_priv then
      core.chat_send_player(player_name, S("This Trooper belongs to @1.", self.owner) )
      return
    end

    --------------------------------------------------------------
    -- 4. Staff with ban privilege can take ownership
    --------------------------------------------------------------
    if has_ban_priv and self.owner ~= player_name then
      local old_owner = self.owner

      self.owner = player_name

      if self.jc_monster_name then
        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({
            nametag = self.nametag
          })
        end
      end

      core.log("action", "[jc_special] " .. player_name .. " took ownership of Trooper from " .. tostring(old_owner) )
    end

    --------------------------------------------------------------
    -- 5. Protect
    --------------------------------------------------------------
    if mobs:protect(self, clicker) then
      return
    end

    --------------------------------------------------------------
    -- 6. Capture
    --------------------------------------------------------------
    if self.tamed then

      -- Owner is already verified above.
      self.owner = player_name

      if self.jc_monster_name then
        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({ nametag = self.nametag })
        end
      end

      if mobs:capture_mob(self, clicker, 30, 50, 80, false, nil) then
        return
      end
    end
  end,
  ]]

  on_rightclick = function(self, clicker)
    if not clicker or not clicker:is_player() then
      return
    end

    local player_name = clicker:get_player_name()

    --------------------------------------------------------------
    -- 1. Ownership check BEFORE feeding/taming
    --
    -- The owner can feed their Trooper normally.
    -- Players with the ban privilege can bypass ownership.
    --------------------------------------------------------------
    local has_ban_priv = core.check_player_privs(player_name, { ban = true })

    if self.tamed and self.owner and self.owner ~= "" and self.owner ~= player_name and not has_ban_priv then
      core.chat_send_player(player_name, S("This Trooper belongs to @1.", self.owner))
      return
    end

    --------------------------------------------------------------
    -- 2. Feed / Tame
    --------------------------------------------------------------
    if mobs:feed_tame(self, clicker, 4, true, true) then
      if self.tamed and self.jc_monster_name then
        self.owner = player_name

        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({ nametag = self.nametag })
        end
      end

      return
    end

    --------------------------------------------------------------
    -- 3. Must be tamed
    --------------------------------------------------------------
    if not self.tamed then
      core.chat_send_player( player_name, S("This Trooper must be tamed before you can protect it.") )
      return
    end

    --------------------------------------------------------------
    -- 4. Staff with ban privilege can take ownership
    --------------------------------------------------------------
    if has_ban_priv and self.owner ~= player_name then
      local old_owner = self.owner

      self.owner = player_name

      if self.jc_monster_name then
        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({ nametag = self.nametag })
        end
      end

      core.log("action", "[jc_special] " .. player_name .. " took ownership of Trooper from " .. tostring(old_owner) )
    end

    --------------------------------------------------------------
    -- 5. Protect
    --------------------------------------------------------------
    if mobs:protect(self, clicker) then
      return
    end

    --------------------------------------------------------------
    -- 6. Capture
    --------------------------------------------------------------
    if self.tamed then

      -- Owner is already verified above.
      self.owner = player_name

      if self.jc_monster_name then
        self.nametag = core.colorize("#FFFF00", self.jc_monster_name) .. core.colorize("#AAAAAA", " (" .. player_name .. ")")

        if self.update_tag then
          self:update_tag()
        else
          self.object:set_properties({ nametag = self.nametag })
        end
      end

      if mobs:capture_mob(self, clicker, 30, 50, 80, false, nil) then
        return
      end
    end
  end,

  ----------------------------------------------------------------
  -- DROPS
  ----------------------------------------------------------------
  drops = {
    { name = "animalia:feather", chance = 3, min = 1, max = 5, },
    { name = "mobs_monster:trooper", chance = 5, min = 1, max = 1, },
    { name = "default:pick_steel", chance = 3, min = 1, max = 1, },
  },
}

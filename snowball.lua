-- Throwable default:snow
core.register_entity("jc_special:thrown_snow", {
  initial_properties = {
    physical = false,
    collide_with_objects = true,
    collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
    visual = "sprite",
    textures = {"default_snowball.png"},
    visual_size = {x = 0.4, y = 0.4},
    pointable = false,
    static_save = false,
  },
  get_staticdata = function(self)
    return ""
  end,

  last_pos = nil,
  timer = 0,
  thrower = nil,

  on_step = function(self, dtime)
    self.timer = self.timer + dtime

    local pos = self.object:get_pos()
    if not pos then
      return
    end

    local old_pos = self.last_pos

    if not old_pos then
      self.last_pos = vector.copy(pos)
      return
    end

    self.last_pos = vector.copy(pos)


    -- Hit a solid node
    local ray = core.raycast(old_pos, pos, false, false)

    for pointed_thing in ray do
      if pointed_thing.type == "node" then
        core.sound_play("default_snow_footstep", {
          pos = pos,
          gain = 0.5,
        })

        core.add_particlespawner({
          amount = 8,
          time = 0.1,
          minpos = pos,
          maxpos = pos,
          minvel = {x = -1, y = -1, z = -1},
          maxvel = {x =  1, y =  1, z =  1},
          texture = "default_snowball.png",
        })

        self.object:remove()
        return
      end
    end

    -- Hit a player or mob
    for _, obj in ipairs(core.get_objects_inside_radius(pos, 1)) do
      if obj ~= self.object and obj:get_pos() then
        local ent = obj:get_luaentity()

        if not (obj:is_player() and obj:get_player_name() == self.thrower) then
          if obj:is_player() or (ent and ent.name and ent.name ~= "jc_special:thrown_snow") then
            local puncher = nil

            if self.thrower then
              puncher = core.get_player_by_name(self.thrower)
            end

            obj:punch(puncher or self.object, 1.0, {
              full_punch_interval = 1,
              damage_groups = {fleshy = 1},
            })

            core.sound_play("default_snow_footstep", {
              pos = pos,
              gain = 0.5,
            })

            core.add_particlespawner({
              amount = 8,
              time = 0.1,
              minpos = pos,
              maxpos = pos,
              minvel = {x=-1, y=-1, z=-1},
              maxvel = {x=1, y=1, z=1},
              texture = "default_snowball.png",
            })

            self.object:remove()
            return
          end
        end
      end
    end

    -- Remove after 3 seconds
    if self.timer > 3 then
      self.object:remove()
    end
  end,
})

core.override_item("default:snow", {
  on_use = function(itemstack, user, pointed_thing)
    local pos = user:get_pos()
    pos.y = pos.y + 1.5

    local dir = user:get_look_dir()

    local obj = core.add_entity(pos, "jc_special:thrown_snow")
    if obj then
      local ent = obj:get_luaentity()
      ent.thrower = user:get_player_name()

      obj:set_velocity(vector.multiply(dir, 20))
      obj:set_acceleration({x = 0, y = -9.8, z = 0})
      obj:set_yaw(user:get_look_horizontal())
    end


    if not core.is_creative_enabled(user:get_player_name()) then
      itemstack:take_item()
    end

    return itemstack
  end,
})
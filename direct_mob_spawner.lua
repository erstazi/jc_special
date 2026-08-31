-- direct_mob_spawner.lua

local S = core.get_translator(core.get_current_modname())

--[[
Old one:
mobs_animal:pumba 10 15 1 10 1
]]
local spawner_default = "mobs_animal:bunny 0 15 1 10 2"

core.register_node("jc_special:direct_mob_spawner", {
  tiles = {"mob_spawner.png"},
  drawtype = "glasslike",
  paramtype = "light",
  walkable = true,
  description = S("Direct Mob Spawner"),
  groups = {cracky = 1},

  on_construct = function(pos)
    local meta = core.get_meta(pos)

    local head = S("(mob name) (min light) (max light) (amount) (player distance) (Y offset)" )

    meta:set_string(
      "formspec",
      "formspec_version[6]"
      -- ""
      .. "size[10,5.5]"
      .. "label[0.15,0.5;" .. core.formspec_escape(head) .. "]"
      .. "field[1,2.3;8.5,0.8;text;" .. S("Command:") .. ";${command}]"
    )

    meta:set_string("infotext", S("Direct Mob Spawner Not Active (enter settings)") )

    meta:set_string("command", spawner_default)
  end,

  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if clicker and core.is_protected(pos, clicker:get_player_name()) then
      return
    end
  end,

  on_receive_fields = function(pos, formname, fields, sender)
    if not fields.key_enter_field then
      return
    end

    local text = fields.text

    if not text or text == "" then
      return
    end

    local meta = core.get_meta(pos)
    local comm = text:split(" ")
    local name = sender:get_player_name()

    if core.is_protected(pos, name) then
      core.record_protection_violation(pos, name)
      return
    end

    local mob = comm[1]
    local mlig = tonumber(comm[2])
    local xlig = tonumber(comm[3])
    local num = tonumber(comm[4])
    local pla = tonumber(comm[5])
    local yof = tonumber(comm[6]) or 0

    if mob
    and mob ~= ""
    and mobs.spawning_mobs[mob]
    and num
    and num >= 0
    and num <= 10
    and mlig
    and mlig >= 0
    and mlig <= 15
    and xlig
    and xlig >= 0
    and xlig <= 15
    and pla
    and pla >= 0
    and pla <= 20
    and yof
    and yof > -10
    and yof < 10 then

      meta:set_string("command", text)
      meta:set_string(
        "infotext",
        S("Direct Mob Spawner Active (@1)", mob)
      )

      -- Close the formspec after successfully saving.
      core.close_formspec(name, "jc_special:direct_mob_spawner")

    else
      core.chat_send_player(
        name,
        S("Direct Mob Spawner settings failed!")
      )

      core.chat_send_player(
        name,
        S(
          "Syntax: “name min_light[0-15] max_light[0-15] "
          .. "max_mobs[0 to disable] player_distance[1-20] "
          .. "y_offset[-9 to 9]”"
        )
      )
    end
  end,
})


local max_per_block = tonumber(core.settings:get("max_objects_per_block") or 99 )


core.register_abm({
  label = "Direct mob spawner node",
  nodenames = {"jc_special:direct_mob_spawner"},
  interval = 10,
  chance = 4,
  catch_up = false,

  action = function(pos, node, active_object_count, active_object_count_wider)

    -- Return if there are too many entities already.
    if active_object_count_wider >= max_per_block then
      return
    end

    local meta = core.get_meta(pos)
    local comm = meta:get_string("command"):split(" ")

    local mob = comm[1]
    local mlig = tonumber(comm[2])
    local xlig = tonumber(comm[3])
    local num = tonumber(comm[4])
    local pla = tonumber(comm[5]) or 0
    local yof = tonumber(comm[6]) or 0

    -- Amount of 0 disables spawning.
    if num == 0 then
      return
    end

    -- Make sure the mob exists.
    if not mobs.spawning_mobs[mob] then
      return
    end

    local entity_def = core.registered_entities[mob]

    if not entity_def then
      return
    end

    --------------------------------------------------------
    -- Count existing mobs.
    --
    -- This keeps the same 9-node radius behavior as the
    -- normal mobs_redo spawner for determining how many
    -- mobs already exist.
    --------------------------------------------------------

    local objs = core.get_objects_inside_radius(pos, 9)
    local count = 0

    for _, obj in ipairs(objs) do
      local ent = obj:get_luaentity()

      if ent and ent.name == mob then
        count = count + 1
      end
    end

    if count >= num then
      return
    end

    --------------------------------------------------------
    -- Player detection.
    --------------------------------------------------------

    if pla > 0 then
      local objsp = core.get_objects_inside_radius(pos, pla)
      local in_range = false

      for _, obj in ipairs(objsp) do
        if obj:is_player() then
          in_range = true
          break
        end
      end

      if not in_range then
        return
      end
    end

    --------------------------------------------------------
    -- Determine what the mob can spawn inside.
    --------------------------------------------------------

    local reg = entity_def.fly_in

    if not reg or type(reg) == "string" then
      reg = {reg or "air"}
    end

    --------------------------------------------------------
    -- DIRECT SPAWN POSITION
    --
    -- No X/Z radius.
    -- The mob spawns directly at the spawner's X/Z,
    -- with only the configured Y offset.
    --------------------------------------------------------

    local spawn_pos = {
      x = pos.x,
      y = pos.y + yof,
      z = pos.z,
    }

    local node = core.get_node(spawn_pos)

    --------------------------------------------------------
    -- Make sure the exact target node is suitable.
    --------------------------------------------------------

    local valid_node = false

    for _, name in ipairs(reg) do
      if node.name == name then
        valid_node = true
        break
      end
    end

    if not valid_node then
      return
    end

    --------------------------------------------------------
    -- Check light at the exact spawn position.
    --------------------------------------------------------

    local light = core.get_node_light(spawn_pos) or 0

    if light < mlig or light > xlig then
      return
    end

    --------------------------------------------------------
    -- Spawn.
    --------------------------------------------------------

    core.add_entity(spawn_pos, mob)
  end,
})
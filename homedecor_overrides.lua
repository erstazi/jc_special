-- homedecor_overrides.lua
local function update_clock(pos)
  local tod = core.get_timeofday()

  local hours = math.floor(tod * 24)
  local minutes = math.floor((tod * 1440) % 60)

  core.get_meta(pos):set_string(
    "infotext",
    string.format("Grandfather Clock\n%02d:%02d", hours, minutes)
  )
end

local def = core.registered_nodes["homedecor:grandfather_clock"]

if def then
  core.override_item("homedecor:grandfather_clock", {
    on_construct = function(pos)
      if def.on_construct then
        def.on_construct(pos)
      end

      update_clock(pos)
      core.get_node_timer(pos):start(10)
    end,

    on_timer = function(pos, elapsed)
      update_clock(pos)

      if def.on_timer then
        return def.on_timer(pos, elapsed)
      end

      return true
    end,
  })
end


local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local function set_can_wear(itemstack, level, max_level)
  local wear

  if level == 0 then
    wear = 0
  else
    wear = 65536 - math.floor(level / max_level * 65535)

    if wear > 65535 then
      wear = 65535
    end

    if wear < 1 then
      wear = 1
    end
  end

  itemstack:set_wear(wear)
end


local function get_can_level(itemstack)
  local metadata = itemstack:get_metadata()

  if metadata == "" then
    return 0
  end

  return tonumber(metadata) or 0
end


function jc_special.register_can(data)
  core.register_tool(data.name, {
    description = data.description,
    inventory_image = data.inventory_image,
    stack_max = 1,

    wear_represents = "content_level",
    liquids_pointable = true,

    groups = {
      jc_special_can = 1,
    },

    on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then
        return itemstack
      end

      local node = core.get_node(pointed_thing.under)

      if node.name ~= data.source then
        return itemstack
      end

      local charge = get_can_level(itemstack)

      if charge >= data.capacity then
        return itemstack
      end

      local player_name = user:get_player_name()

      if core.is_protected(pointed_thing.under, player_name) then
        core.log(
          "action",
          player_name ..
          " tried to take " .. data.description ..
          " at protected position " ..
          core.pos_to_string(pointed_thing.under)
        )

        return itemstack
      end

      core.remove_node(pointed_thing.under)

      charge = charge + 1

      itemstack:set_metadata(tostring(charge))
      set_can_wear(itemstack, charge, data.capacity)

      return itemstack
    end,

    on_place = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then
        return itemstack
      end

      local pos = pointed_thing.under
      local node = core.get_node(pos)
      local def = core.registered_nodes[node.name] or {}

      -- Let the pointed node handle its own right-click.
      if def.on_rightclick
          and user
          and not user:get_player_control().sneak then
        return def.on_rightclick(
          pos,
          node,
          user,
          itemstack,
          pointed_thing
        )
      end

      -- If the pointed node isn't buildable_to,
      -- try placing the liquid above it.
      if not def.buildable_to then
        pos = pointed_thing.above
        node = core.get_node(pos)
        def = core.registered_nodes[node.name] or {}

        if not def.buildable_to then
          return itemstack
        end
      end

      local charge = get_can_level(itemstack)

      if charge <= 0 then
        return itemstack
      end

      local player_name = user:get_player_name()

      if core.is_protected(pos, player_name) then
        core.log(
          "action",
          player_name ..
          " tried to place " .. data.description ..
          " at protected position " ..
          core.pos_to_string(pos)
        )

        return itemstack
      end

      core.set_node(pos, {
        name = data.source
      })

      charge = charge - 1

      itemstack:set_metadata(tostring(charge))
      set_can_wear(itemstack, charge, data.capacity)

      return itemstack
    end,

    on_refill = function(itemstack)
      itemstack:set_metadata(tostring(data.capacity))
      set_can_wear(itemstack, data.capacity, data.capacity)

      return itemstack
    end,
  })
end

jc_special.register_can({
  name = "jc_special:water_can",
  description = "Water Can",
  inventory_image = "jc_special_water_can.png",
  capacity = 15,
  source = "default:water_source",
})

jc_special.register_can({
  name = "jc_special:water_jumbo_can",
  description = "Jumbo Water Can",
  inventory_image = "jc_special_water_can_jumbo.png",
  capacity = 35,
  source = "default:water_source",
})

jc_special.register_can({
  name = "jc_special:freshwater_can",
  description = "Freshwater Can",
  inventory_image = "jc_special_freshwater_can.png",
  capacity = 15,
  source = "default:river_water_source",
})

jc_special.register_can({
  name = "jc_special:lava_can",
  description = "Lava Can",
  inventory_image = "jc_special_lava_can.png",
  capacity = 10,
  source = "default:lava_source",
})

core.register_craft({
  output = "jc_special:water_can",
  recipe = {
    {"default:steel_ingot", "default:tin_ingot",   "default:steel_ingot"},
    {"default:steel_ingot", "",                    "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:water_jumbo_can",
  recipe = {
    {"default:steel_ingot", "multidecor:wolfram_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "",                        "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot",     "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:freshwater_can",
  recipe = {
    {"default:steel_ingot", "moreores:silver_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "",                        "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot",     "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:lava_can",
  recipe = {
    {"default:steel_ingot", "multidecor:zinc_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "",                    "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
  },
})

if core.get_modpath("homedecor_exterior")
    and core.registered_nodes["homedecor:well"] then

  local well_cans = {
    ["jc_special:water_can"] = 15,
    ["jc_special:water_jumbo_can"] = 35,
  }

  for can_name, capacity in pairs(well_cans) do
    local old_on_use = core.registered_items[can_name].on_use

    core.override_item(can_name, {
      on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node"
            and core.get_node(pointed_thing.under).name == "homedecor:well" then

          local charge = get_can_level(itemstack)

          if charge >= capacity then
            return itemstack
          end

          charge = charge + 1

          itemstack:set_metadata(tostring(charge))
          set_can_wear(itemstack, charge, capacity)

          return itemstack
        end

        if old_on_use then
          return old_on_use(itemstack, user, pointed_thing)
        end

        return itemstack
      end,
    })
  end
end

-- Wine barrel compatibility
if core.get_modpath("wine") then
  local wine_cans = {
    ["jc_special:water_can"] = 15,
    ["jc_special:water_jumbo_can"] = 35,
    ["jc_special:freshwater_can"] = 15,
  }

  local barrel = core.registered_nodes["wine:wine_barrel"]

  if barrel then
    local old_allow_put = barrel.allow_metadata_inventory_put
    local old_inventory_put = barrel.on_metadata_inventory_put

    core.override_item("wine:wine_barrel", {
      allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "src_b" and wine_cans[stack:get_name()] then
          local level = tonumber(stack:get_metadata()) or 0
          local water = core.get_meta(pos):get_int("water")

          if level <= 0 or water >= 100 then
            return 0
          end

          return 1
        end

        if old_allow_put then
          return old_allow_put(pos, listname, index, stack, player)
        end

        return 0
      end,

      on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "src_b" and wine_cans[stack:get_name()] then
          local meta = core.get_meta(pos)
          local inv = meta:get_inventory()
          local can = inv:get_stack("src_b", 1)

          local level = tonumber(can:get_metadata()) or 0

          if level > 0 then
            local water = meta:get_int("water")

            -- One can charge = one bucket = 20 Wine water.
            -- A full barrel holds 5 buckets = 100 water.
            local needed = 100 - water
            local charges_used = math.min(level, math.ceil(needed / 20))

            local water_added = charges_used * 20

            if water_added > needed then
              water_added = needed
            end

            water = water + water_added
            level = level - charges_used

            can:set_metadata(tostring(level))

            -- Update can wear.
            local capacity = wine_cans[can:get_name()]

            if level == 0 then
              can:set_wear(0)
            else
              local wear = 65536 - math.floor(
                level / capacity * 65535
              )

              if wear > 65535 then
                wear = 65535
              elseif wear < 1 then
                wear = 1
              end

              can:set_wear(wear)
            end

            inv:set_stack("src_b", 1, can)
            meta:set_int("water", water)

            return
          end
        end

        if old_inventory_put then
          old_inventory_put(pos, listname, index, stack, player)
        end
      end,
    })
  end
end
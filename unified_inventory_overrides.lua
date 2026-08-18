local S = core.get_translator(core.get_current_modname())

if core.get_modpath("unified_inventory") then
  core.register_tool(":unified_inventory:bag_wooden", {
    description = S("MrPhil's Wooden Bag"),
    inventory_image = "jc_special_bags_wooden.png",
    groups = {bagslots = 24},
  })


  core.register_craft({
    output = "unified_inventory:bag_wooden",
    recipe = {
      {"", "", ""},
      {"group:wood", "unified_inventory:bag_medium", "group:wood"},
      {"group:wood", "unified_inventory:bag_medium", "group:wood"},
    },
  })
end


-- geode_armor.lua
local S = core.get_translator("jc_special")
if core.get_modpath("3d_armor") then
  armor:register_armor("jc_special:geode_helmet", {
    description = "Geode Helmet",
    inventory_image = "jc_special_geode_helmet_inv.png",
    texture = "jc_special_geode_helmet.png",
    preview = "jc_special_geode_helmet_preview.png",
    groups = {armor_head=16, armor_heal=12, armor_use=55},
    armor_groups = {fleshy=16},
    damage_groups = {cracky=2, snappy=2, level=2},
  })

  armor:register_armor("jc_special:geode_chestplate", {
    description = "Geode Chestplate",
    inventory_image = "jc_special_geode_chestplate_inv.png",
    texture = "jc_special_geode_chestplate.png",
    preview = "jc_special_geode_chestplate_preview.png",
    groups = {armor_torso=20, armor_heal=12, armor_use=55},
    armor_groups = {fleshy=20},
    damage_groups = {cracky=2, snappy=2, level=2},
  })

  armor:register_armor("jc_special:geode_leggings", {
    description = "Geode Leggings",
    inventory_image = "jc_special_geode_leggings_inv.png",
    texture = "jc_special_geode_leggings.png",
    preview = "jc_special_geode_leggings_preview.png",
    groups = {armor_legs=20, armor_heal=12, armor_use=55},
    armor_groups = {fleshy=20},
    damage_groups = {cracky=2, snappy=2, level=2},
  })

  armor:register_armor("jc_special:geode_boots", {
    description = "Geode Boots",
    inventory_image = "jc_special_geode_boots_inv.png",
    texture = "jc_special_geode_boots.png",
    preview = "jc_special_geode_boots_preview.png",
    groups = {armor_feet=16, armor_heal=12, armor_use=50},
    armor_groups = {fleshy=16},
    damage_groups = {cracky=2, snappy=2, level=2},
  })

  armor:register_armor("jc_special:geode_shield", {
    description = S("Geode Shield"),
    inventory_image = "jc_special_geode_shield_inv.png",
    texture = "jc_special_geode_shield.png",
    preview = "jc_special_geode_shield_preview.png",
    groups = {armor_shield=1, armor_heal=12, armor_use=55},
    armor_groups = {fleshy=14},
    damage_groups = {cracky=2, snappy=2, level=2},
    reciprocate_damage = true,
  })
end

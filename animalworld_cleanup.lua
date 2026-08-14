-- animalworld_cleanup.lua

local function cleanupOldEntities(name)
  minetest.register_entity(":" .. name, {
    initial_properties = {
      physical = false,
      pointable = false,
      visual = "sprite",
      textures = {"blank.png"},
    },

    on_activate = function(self)
      minetest.log("action", "[cleanup] Removing " .. name)
      self.object:remove()
    end,
  })
end

local mobs = {
  "animalworld:beluga",
  "animalworld:blackbird",
  "animalworld:divingbeetle",
  "animalworld:frog",
  "animalworld:hare",
  "animalworld:locust",
  "animalworld:moose",
  "animalworld:owl",
  "animalworld:rat",
  "animalworld:reindeer",
  "animalworld:spider",
  "animalworld:stingray",
  "animalworld:tiger",
  "animalworld:volverine",
}

for _, name in ipairs(mobs) do
  cleanupOldEntities(name)
end

minetest.register_craftitem(":animalworld:rabbit_raw", {
  description = "",
  inventory_image = "blank.png",
})
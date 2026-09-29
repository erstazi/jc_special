-- farming_overrides.lua

core.register_on_mods_loaded(function()
  if not core.get_modpath("farming") then
    return
  end

  for _, name in ipairs({
    "farming:rhubarb_1",
    "farming:rhubarb_2",
    "farming:rhubarb_3",
  }) do
    local def = core.registered_nodes[name]

    if def then
      def.maxlight = 15
    end
  end

  local plant = farming.registered_plants["farming:rhubarb"]

  if plant then
    plant.maxlight = 15
  end
end)
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

--------------------------------------------------------
-- INFOTEXT WAND
--------------------------------------------------------

local infotext_edit = {}

core.register_tool("jc_special:infotext_wand", {
  description = "Infotext Wand",
  inventory_image = "default_stick.png^[colorize:#00ffff:100",
  range = 10,

  -- Right-click: edit infotext
  on_place = function(itemstack, user, pointed_thing)
    if not user then
      return itemstack
    end

    local player_name = user:get_player_name()

    if not core.check_player_privs(player_name, {server = true}) then
      core.chat_send_player(
        player_name,
        S("You need server privileges to use this.")
      )
      return itemstack
    end

    if pointed_thing.type ~= "node" then
      return itemstack
    end

    local pos = pointed_thing.under
    local node = core.get_node(pos)
    local meta = core.get_meta(pos)

    infotext_edit[player_name] = {
      pos = vector.copy(pos),
      node = node.name
    }

    local current = meta:get_string("infotext")

    local formspec =
      "formspec_version[4]" ..
      "size[10,5]" ..

      "label[0.5,0.4;" ..
      core.formspec_escape(
        S("Edit Infotext: @1", node.name)
      ) ..
      "]" ..

      "textarea[0.5,1.0;9,2.5;infotext;" ..
      core.formspec_escape(S("Infotext")) .. ";" ..
      core.formspec_escape(current) ..
      "]" ..

      "button[2.5,4.0;2.0,0.8;save;" ..
      core.formspec_escape(S("SAVE")) ..
      "]" ..

      "button[5.0,4.0;2.0,0.8;cancel;" ..
      core.formspec_escape(S("CANCEL")) ..
      "]"

    core.show_formspec(
      player_name,
      "jc_special:infotext_edit",
      formspec
    )

    return itemstack
  end,

  -- Left-click: reset infotext
  -- Left-click: reset or clear infotext
  on_use = function(itemstack, user, pointed_thing)
    if not user then
      return itemstack
    end

    local player_name = user:get_player_name()

    if not core.check_player_privs(player_name, {server = true}) then
      core.chat_send_player(
        player_name,
        S("You need server privileges to use this.")
      )
      return itemstack
    end

    if pointed_thing.type ~= "node" then
      return itemstack
    end

    local pos = pointed_thing.under
    local node = core.get_node(pos)
    local meta = core.get_meta(pos)
    local def = core.registered_nodes[node.name]

    -- Sneak + left-click: always clear infotext
    if user:get_player_control().sneak then
      meta:set_string("infotext", "")

      core.log(
        "action",
        "[jc_special] Cleared infotext from " ..
        node.name .. " at " ..
        core.pos_to_string(pos) ..
        ". Current infotext: [" ..
        meta:get_string("infotext") ..
        "]"
      )

      core.chat_send_player(
        player_name,
        S("Infotext cleared.")
      )

      return itemstack
    end

    -- Normal left-click: restore default infotext
    if def and def.infotext and def.infotext ~= "" then
      meta:set_string("infotext", def.infotext)

      core.chat_send_player(
        player_name,
        S("Infotext reset to default.")
      )
    else
      meta:set_string("infotext", "")

      core.chat_send_player(
        player_name,
        S("Infotext cleared; this node has no default infotext.")
      )
    end

    return itemstack
  end,
})

--------------------------------------------------------
-- INFOTEXT WAND FORMSPEC
--------------------------------------------------------

core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "jc_special:infotext_edit" then
    return
  end

  local player_name = player:get_player_name()
  local edit = infotext_edit[player_name]

  if not edit then
    return
  end

  if fields.cancel then
    infotext_edit[player_name] = nil
    core.close_formspec(player_name, formname)
    return
  end

  if fields.save then
    local pos = edit.pos

    local node = core.get_node(pos)

    -- Make sure the node hasn't changed while the formspec was open.
    if node.name ~= edit.node then
      core.chat_send_player(
        player_name,
        S("The node has changed. Infotext was not modified.")
      )

      infotext_edit[player_name] = nil
      return
    end

    local meta = core.get_meta(pos)

    meta:set_string(
      "infotext",
      fields.infotext or ""
    )

    core.chat_send_player(
      player_name,
      S("Infotext updated.")
    )

    infotext_edit[player_name] = nil
    core.close_formspec(player_name, formname)
  end
end)
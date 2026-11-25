
-- mailbox.lua
local S = core.get_translator("jc_special")
local modpath = core.get_modpath("jc_special")
local storage = core.get_mod_storage()
local ESC = core.formspec_escape

local mailboxes = core.deserialize(storage:get_string("mailbox_registry")) or {}

local dropbox_sessions = {}
local starter_items = {}
local maildrop_sessions = {}

-- ============================================================
-- MAILBOX NODE TYPES
-- ============================================================

local mailbox_node_names = {
  ["jc_special:mailbox"] = true,
  ["jc_special:mailbox_modern"] = true,
}

local function is_mailbox_node(name)
  return mailbox_node_names[name] == true
end

-- ============================================================
-- STARTER ITEMS
-- Read initial_stuff from minetest.conf
-- ============================================================

local initial_stuff = core.settings:get("initial_stuff") or ""

for itemstring in initial_stuff:gmatch("[^,]+") do
  local stack = ItemStack(itemstring)

  if not stack:is_empty() then
    starter_items[stack:get_name()] = true
  end
end

local function is_starter_item(stack)
  return starter_items[stack:get_name()] == true
end

local function item_word(count)
  return count == 1 and S("item") or S("items")
end

-- ============================================================
-- MAILBOX REGISTRY
-- ============================================================

local function save_mailboxes()
  storage:set_string("mailbox_registry", core.serialize(mailboxes))
end

local function mailbox_id(pos)
  return core.pos_to_string(pos)
end

local function register_mailbox(pos, owner, name, settings)
  local id = mailbox_id(pos)

  mailboxes[id] = {
    pos = pos,
    owner = owner,
    name = name,
    allow_starter_items = settings.allow_starter_items,
    public = settings.public,
    notifications = settings.notifications,
  }

  save_mailboxes()
end

local function unregister_mailbox(pos)
  mailboxes[mailbox_id(pos)] = nil
  save_mailboxes()
end

local function get_mailbox(pos)
  return mailboxes[mailbox_id(pos)]
end

local function get_settings(meta)
  return {
    allow_starter_items = meta:get_int("allow_starter_items") == 1,
    public = meta:get_int("public") == 1,
    notifications = meta:get_int("notifications") == 1,
  }
end

local function update_mailbox(pos, name, settings)
  local mailbox = get_mailbox(pos)

  if not mailbox then
    return false
  end

  mailbox.name = name
  mailbox.allow_starter_items = settings.allow_starter_items
  mailbox.public = settings.public
  mailbox.notifications = settings.notifications

  save_mailboxes()
  return true
end

-- ============================================================
-- MAILBOX INFOTEXT
-- ============================================================

local function update_mailbox_infotext(pos)
  local meta = core.get_meta(pos)
  local owner = meta:get_string("owner")
  local name = meta:get_string("mailbox_name")
  local coords = core.pos_to_string(pos)

  meta:set_string("infotext", S("@1 (Owner: @2) @3", name, owner, coords))
end

-- ============================================================
-- MAILBOX FORMSPEC
-- ============================================================

local function mailbox_formspec(pos)
  local meta = core.get_meta(pos)
  local spos = pos.x .. "," .. pos.y .. "," .. pos.z
  local display_coords = ESC(core.pos_to_string(pos))

  local name = ESC(meta:get_string("mailbox_name"))
  local settings = get_settings(meta)

  return
    "formspec_version[4]" ..
    "size[10.5,15.0]" ..

    "label[0.4,0.25;" .. S("Coordinates: @1", display_coords) .. "]" ..

    "field[0.4,1.0;7.0,0.8;mailbox_name;" .. S("Mailbox Name") .. ";" .. name .. "]" ..
    "button[7.6,1.0;2.2,0.8;save;" .. S("Save Settings") .. "]" ..

    "checkbox[0.4,2.1;allow_starter_items;" .. S("Allow Starter Items") .. ";" .. tostring(settings.allow_starter_items) .. "]" ..
    "checkbox[3.8,2.1;public;" .. S("Public?") .. ";" .. tostring(settings.public) .. "]" ..
    "checkbox[6.4,2.1;notifications;" .. S("Enable Notifications") .. ";" .. tostring(settings.notifications) .. "]" ..

    "label[0.4,3.0;" .. S("Mailbox Contents") .. "]" ..
    "listcolors[#80808080;#c0c0c0;#000000;#686868;#ffffff]" ..
    "list[nodemeta:" .. spos .. ";main;0.4,3.4;8,4;]" ..

    "button[3,8.3;4,0.8;getitems;" .. ESC(S("Get Mailbox Items")) .. "]" ..

    "label[0.4,9.5;" .. S("Your Inventory") .. "]" ..
    "list[current_player;main;0.4,9.9;8,1;]" ..
    "list[current_player;main;0.4,11.1;8,3;8]" ..

    "listring[nodemeta:" .. spos .. ";main]" ..
    "listring[current_player;main]"
end

-- ============================================================
-- DIRECT MAIL DELIVERY
-- ============================================================

local function maildrop_inventory_name(player_name)
  return "jc_special_maildrop_" .. player_name
end

local function get_maildrop_inventory(player)
  local player_name = player:get_player_name()
  local inv_name = maildrop_inventory_name(player_name)

  local inv = core.get_inventory({
    type = "detached",
    name = inv_name,
  })

  if not inv then
    inv = core.create_detached_inventory(inv_name, {
      allow_put = function(inv, listname, index, stack, putter)
        if putter and putter:get_player_name() == player_name and listname == "mail" then
          return stack:get_count()
        end
        return 0
      end,

      allow_take = function(inv, listname, index, stack, taker)
        if taker and taker:get_player_name() == player_name and listname == "mail" then
          return stack:get_count()
        end
        return 0
      end,
    }, player_name)

    inv:set_size("mail", 1)
  end

  return inv
end

local function return_maildrop_items(player)
  local player_name = player:get_player_name()
  local inv = core.get_inventory({
    type = "detached",
    name = maildrop_inventory_name(player_name),
  })

  if not inv or inv:is_empty("mail") then
    return
  end

  local leftover = player:get_inventory():add_item("main", inv:get_stack("mail", 1))

  if not leftover:is_empty() then
    core.add_item(player:get_pos(), leftover)
  end

  inv:set_stack("mail", 1, ItemStack(""))
end

local function maildrop_formspec(player, session)
  local player_name = player:get_player_name()
  local inv_name = maildrop_inventory_name(player_name)
  local meta = core.get_meta(session.pos)

  local owner = ESC(session.owner)
  local name = ESC(meta:get_string("mailbox_name"))
  local coords = ESC(core.pos_to_string(session.pos))

  return
    "formspec_version[4]" ..
    "size[10.5,10.5]" ..

    "label[0.5,0.3;" .. S("Mailbox Owner: @1", owner) .. "]" ..
    "label[0.5,0.7;" .. S("Mailbox Name: @1", name) .. "]" ..
    "label[0.5,1.1;" .. S("Coordinates: @1", coords) .. "]" ..

    "label[0.5,1.8;" .. S("Place an item in the slot to deliver it.") .. "]" ..
    "list[detached:" .. inv_name .. ";mail;4.75,2.3;1,1;]" ..
    "button[3.75,3.8;3,0.8;deliver;" .. S("Deliver Mail") .. "]" ..

    "label[0.5,5.0;" .. S("Your Inventory") .. "]" ..
    "list[current_player;main;0.5,5.4;8,1;]" ..
    "list[current_player;main;0.5,6.6;8,3;8]" ..

    "listring[detached:" .. inv_name .. ";mail]" ..
    "listring[current_player;main]"
end

local function show_maildrop(player, pos)
  local player_name = player:get_player_name()
  local mailbox = get_mailbox(pos)

  if not mailbox or not mailbox.public then
    core.chat_send_player(player_name, S("This mailbox is not accepting public mail."))
    return
  end

  local inv = get_maildrop_inventory(player)

  if not inv:is_empty("mail") then
    local leftover = player:get_inventory():add_item("main", inv:get_stack("mail", 1))
    if not leftover:is_empty() then
      core.add_item(player:get_pos(), leftover)
    end
    inv:set_stack("mail", 1, ItemStack(""))
  end

  maildrop_sessions[player_name] = {
    pos = pos,
    owner = mailbox.owner,
  }

  core.show_formspec(player_name, "jc_special:maildrop", maildrop_formspec(player, maildrop_sessions[player_name]))
end

local function notification_key(owner)
  return "notifications:" .. owner
end

local function queue_notification(owner, message)
  local player = core.get_player_by_name(owner)

  if player then
    core.chat_send_player(owner, message)

    core.sound_play("incoming_mailbox", {
      to_player = owner,
      gain = 0.6,
    })

    return
  end

  local key = notification_key(owner)
  local notifications = core.deserialize(storage:get_string(key)) or {}

  notifications[#notifications + 1] = message
  storage:set_string(key, core.serialize(notifications))
end

local function deliver_maildrop(player)
  local player_name = player:get_player_name()
  local session = maildrop_sessions[player_name]

  if not session then
    return false, S("Mailbox session expired.")
  end

  local pos = session.pos

  core.load_area(pos, pos)

  local node = core.get_node_or_nil(pos)

  if not node or not is_mailbox_node(node.name) then
    return false, S("This mailbox no longer exists.")
  end

  local meta = core.get_meta(pos)

  if meta:get_string("owner") ~= session.owner or meta:get_int("public") ~= 1 then
    return false, S("This mailbox is no longer accepting public mail.")
  end

  local source_inv = core.get_inventory({
    type = "detached",
    name = maildrop_inventory_name(player_name),
  })

  if not source_inv or source_inv:is_empty("mail") then
    return false, S("Please place an item in the delivery slot.")
  end

  local stack = source_inv:get_stack("mail", 1)
  local item_count = stack:get_count()

  if meta:get_int("allow_starter_items") ~= 1 and is_starter_item(stack) then
    return false, S("This mailbox does not accept starter items: @1", stack:get_name())
  end

  local destination_inv = meta:get_inventory()
  local backup = destination_inv:get_list("main")
  local leftover = destination_inv:add_item("main", stack)

  if not leftover:is_empty() then
    destination_inv:set_list("main", backup)
    return false, S("The mailbox does not have enough room.")
  end

  source_inv:set_stack("mail", 1, ItemStack(""))

  local mailbox_name = meta:get_string("mailbox_name")
  local coords = core.colorize("#FFFF00", core.pos_to_string(pos))
  local colored_count = core.colorize("#FFFF00", tostring(item_count))

  if meta:get_int("notifications") == 1 then
    queue_notification(session.owner, S(
      "[Mailbox] @1 delivered @2 @3 to your mailbox '@4' at @5.",
      core.colorize("#00FF00", player_name),
      colored_count,
      item_word(item_count),
      mailbox_name,
      coords
    ))
  end

  core.chat_send_player(player_name, S(
    "Successfully delivered @1 @2 to mailbox '@3' owned by @4 at @5.",
    colored_count,
    item_word(item_count),
    mailbox_name,
    core.colorize("#00FF00", session.owner),
    coords
  ))

  core.sound_play("default_item_smoke", {to_player = player_name, gain = 0.6})

  return true
end

-- ============================================================
-- MAILBOX NODE REGISTRATION
-- Both mailbox designs share the same behavior and inventory.
-- ============================================================

local function register_mailbox_node(name, description, default_mailbox_name, tiles, node_box)
  core.register_node(name, {
    description = S(description),

    drawtype = "nodebox",
    node_box = node_box,

    tiles = tiles,

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {
      mailbox = 1,
      cracky = 2,
      oddly_breakable_by_hand = 2,
    },

    is_ground_content = false,
    sounds = default.node_sound_metal_defaults(),

    on_construct = function(pos)
      local meta = core.get_meta(pos)
      local inv = meta:get_inventory()

      inv:set_size("main", 8 * 4)

      meta:set_string("mailbox_name", S(default_mailbox_name))
      meta:set_int("allow_starter_items", 0)
      meta:set_int("public", 1)
      meta:set_int("notifications", 1)
    end,

    after_place_node = function(pos, placer)
      local owner = placer:get_player_name()
      local meta = core.get_meta(pos)

      meta:set_string("owner", owner)

      register_mailbox(pos, owner, meta:get_string("mailbox_name"), get_settings(meta))
      update_mailbox_infotext(pos)
    end,

    on_rightclick = function(pos, node, clicker)
      local meta = core.get_meta(pos)
      local owner = meta:get_string("owner")
      local player = clicker:get_player_name()

      if player == owner then
        core.show_formspec(player, "jc_special:mailbox:" .. core.pos_to_string(pos), mailbox_formspec(pos))
      else
        show_maildrop(clicker, pos)
      end
    end,

    can_dig = function(pos, player)
      local meta = core.get_meta(pos)
      local inv = meta:get_inventory()

      return player:get_player_name() == meta:get_string("owner") and inv:is_empty("main")
    end,

    on_destruct = function(pos)
      unregister_mailbox(pos)
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      local meta = core.get_meta(pos)

      if listname == "main" and player:get_player_name() == meta:get_string("owner") then
        return stack:get_count()
      end

      return 0
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
      local meta = core.get_meta(pos)

      if listname == "main" and player:get_player_name() == meta:get_string("owner") then
        return stack:get_count()
      end

      return 0
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
      local meta = core.get_meta(pos)

      if player:get_player_name() == meta:get_string("owner") then
        return count
      end

      return 0
    end,

    on_blast = function()
    end,
  })
end

-- Original mailbox.
register_mailbox_node(
  "jc_special:mailbox",
  "Mailbox",
  "Mailbox",
  {
    "jc_mailbox_top.png",
    "jc_mailbox_bottom.png",
    "jc_mailbox_east.png",
    "jc_mailbox_west.png",
    "jc_mailbox_back.png",
    "jc_mailbox_front.png",
  },
  {
    type = "fixed",
    fixed = {
      {-4/12, -6/12, -6/12, 4/12, 0/12, 6/12},
      {-3/12, 0/12, -6/12, 3/12, 2/12, 6/12},
      {3/12, 0/12, -6/12, 4/12, 5/12, -2/12},
      {3/12, 3/12, -2/12, 4/12, 5/12, 0/12},
    },
  }
)

-- Modern box-shaped mailbox.
register_mailbox_node(
  "jc_special:mailbox_modern",
  "Modern Mailbox",
  "Modern Mailbox",
  {
    "jc_mailbox2_mailbox_top.png",
    "jc_mailbox2_mailbox_bottom.png",
    "jc_mailbox2_mailbox_side.png",
    "jc_mailbox2_mailbox_side.png",
    "jc_mailbox2_mailbox.png",
    "jc_mailbox2_mailbox.png",
  },
  {
    type = "fixed",
    fixed = {
      {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
  }
)

core.register_craft({
  output = "jc_special:mailbox",
  recipe = {
    {"", "default:steel_ingot", ""},
    {"default:steel_ingot", "", "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:mailbox_modern",
  recipe = {
    {"dye:red", "default:steel_ingot", "dye:red"},
    {"default:steel_ingot", "", "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
  },
})

-- ============================================================
-- OFFLINE NOTIFICATION QUEUE
-- ============================================================

core.register_on_joinplayer(function(player)
  local owner = player:get_player_name()
  local key = notification_key(owner)
  local notifications = core.deserialize(storage:get_string(key)) or {}

  if #notifications == 0 then
    return
  end

  -- Clear before sending to avoid duplicate notifications.
  storage:set_string(key, "")

  for _, message in ipairs(notifications) do
    core.chat_send_player(owner, message)
  end

  core.sound_play("incoming_mailbox", {
    to_player = owner,
    gain = 0.6,
  })
end)

-- ============================================================
-- DROPBOX INVENTORY
-- Each player gets their own temporary sending inventory.
-- ============================================================

local function dropbox_inventory_name(player_name)
  return "jc_special_dropbox_" .. player_name
end

local function get_dropbox_inventory(player)
  local player_name = type(player) == "string" and player or (player and player.get_player_name and player:get_player_name() or "")
  local inv_name = dropbox_inventory_name(player_name)

  local inv = core.get_inventory({
    type = "detached",
    name = inv_name,
  })

  if not inv then
    inv = core.create_detached_inventory(inv_name, {
      allow_put = function(inv, listname, index, stack, player)
        if player:get_player_name() == player_name and listname == "send" then
          return stack:get_count()
        end
        return 0
      end,

      allow_take = function(inv, listname, index, stack, player)
        if player:get_player_name() == player_name and listname == "send" then
          return stack:get_count()
        end
        return 0
      end,

      allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
        if player:get_player_name() == player_name and from_list == "send" and to_list == "send" then
          return count
        end
        return 0
      end,
    }, player_name)

    inv:set_size("send", 8)
  end

  return inv
end

-- ============================================================
-- PUBLIC MAILBOX LIST
-- ============================================================

local function get_public_mailboxes()
  local result = {}

  for id, mailbox in pairs(mailboxes) do
    if mailbox.public then
      result[#result + 1] = {
        id = id,
        owner = mailbox.owner,
        name = mailbox.name,
        pos = mailbox.pos,
      }
    end
  end

  table.sort(result, function(a, b)
    if a.owner == b.owner then
      return a.name < b.name
    end
    return a.owner < b.owner
  end)

  return result
end

-- ============================================================================
-- DROPBOX ANIMATION
-- The B3D contains 53 keyed frames at 60 FPS.
-- The root bone has been fixed in the model so only the door moves:
-- 1-10 opens, 10 is the open pose, 37-46 closes, 46 is closed.
-- https://blockbenchworkshop.com/model/polyjo/blue-low-poly-mail-box
-- ============================================================================

local dropbox_entity_name = "jc_special:dropbox_visual"

local function same_position(a, b)
  return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

local function get_dropbox_visual(pos)
  for _, object in ipairs(core.get_objects_inside_radius(pos, 0.75)) do
    local entity = object:get_luaentity()

    if entity and entity.name == dropbox_entity_name and same_position(entity.node_pos, pos) then
      return object
    end
  end
end

local function ensure_dropbox_visual(pos, node)
  node = node or core.get_node_or_nil(pos)

  if not node or node.name ~= "jc_special:dropbox" then
    return
  end

  local object = get_dropbox_visual(pos)

  if not object then
    object = core.add_entity(pos, dropbox_entity_name, core.serialize(pos))
  end

  if object then
    -- Keep the entity's logical node position unchanged.
    -- Move only its visual origin down to floor level.
    object:set_pos({
      x = pos.x,
      y = pos.y - 0.5,
      z = pos.z,
    })

    local direction = core.facedir_to_dir(node.param2 or 0)
    -- object:set_yaw(core.dir_to_yaw(direction) + math.pi / 2)
    object:set_yaw(core.dir_to_yaw(direction) + math.pi)
    object:set_animation({x = 46, y = 46}, 60, 0, false)
  end
end

local function set_dropbox_animation(pos, start_frame, end_frame)
  local object = get_dropbox_visual(pos)

  if not object then
    ensure_dropbox_visual(pos)
    object = get_dropbox_visual(pos)
  end

  if object then
    object:set_animation({
      x = start_frame,
      y = end_frame,
    }, 60, 0, false)
  end
end

local function animate_dropbox_open(pos)
  set_dropbox_animation(pos, 1, 10)

  core.sound_play("dropbox_open", {
    pos = pos,
    gain = 0.7,
    max_hear_distance = 12,
  })
end

local function animate_dropbox_close(pos)
  set_dropbox_animation(pos, 37, 46)

  core.sound_play("dropbox_close", {
    pos = pos,
    gain = 0.7,
    max_hear_distance = 12,
  })
end

local function remove_dropbox_visual(pos)
  local object = get_dropbox_visual(pos)

  if object then
    object:remove()
  end
end

core.register_entity(dropbox_entity_name, {
  initial_properties = {
    physical = false,
    collide_with_objects = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    selectionbox = {0, 0, 0, 0, 0, 0},
    pointable = false,
    visual = "mesh",
    mesh = "jc_dropbox_animated_textured.b3d",
    textures = {"jc_dropbox.png"},
    -- visual_size = {x = 10, y = 10, z = 10},
    visual_size = {x = 11, y = 12, z = 11},
    static_save = false,
  },

  on_activate = function(self, staticdata)
    self.node_pos = core.deserialize(staticdata)

    if self.node_pos then
      self.object:set_pos({
        x = self.node_pos.x,
        y = self.node_pos.y - 0.5,
        z = self.node_pos.z,
      })

      self.object:set_animation({x = 46, y = 46}, 60, 0, false)
    end
  end,
})

local function dropbox_has_other_open_session(pos, except_player)
  for player_name, session in pairs(dropbox_sessions) do
    if player_name ~= except_player and same_position(session.pos, pos) then
      return true
    end
  end

  return false
end

local function close_dropbox_session(player)
  local player_name = player:get_player_name()
  local session = dropbox_sessions[player_name]

  dropbox_sessions[player_name] = nil

  if session and session.pos and not dropbox_has_other_open_session(session.pos, player_name) then
    animate_dropbox_close(session.pos)
  end
end

-- ============================================================
-- DROPBOX FORMSPEC
-- ============================================================

local function dropbox_formspec(player, pos)
  local player_name = player:get_player_name()
  local inv_name = dropbox_inventory_name(player_name)
  local recipients = get_public_mailboxes()
  local options = {S("Please select a recipient")}

  for _, mailbox in ipairs(recipients) do
    local coords = mailbox.pos and core.pos_to_string(mailbox.pos) or mailbox.id
    options[#options + 1] = ESC(mailbox.owner .. " - " .. mailbox.name .. " " .. coords .. "")
  end

  local formspec =
    "formspec_version[4]" ..
    "size[13,11]" ..
    "label[0.5,0.3;" .. S("Select a recipient") .. "]"

  if #recipients > 0 then
    formspec = formspec .. "dropdown[0.5,0.6;12,0.8;recipient;" .. table.concat(options, ",") .. ";1;true]"
  else
    formspec = formspec .. "label[0.5,0.8;" .. S("No public mailboxes available") .. "]"
  end

  local x_for_lists = 2

  formspec = formspec ..
    "label[" .. x_for_lists .. ",1.8;" .. S("Items to send") .. "]" ..
    "list[detached:" .. inv_name .. ";send;" .. x_for_lists .. ",2.2;8,1;]" ..
    "button[5.0,3.4;3,0.8;send;" .. S("Send Items") .. "]" ..
    "label[" .. x_for_lists .. ",4.7;" .. S("Your Inventory") .. "]" ..
    "list[current_player;main;" .. x_for_lists .. ",5.2;8,4;]" ..
    "listring[detached:" .. inv_name .. ";send]" ..
    "listring[current_player;main]"

  dropbox_sessions[player_name] = {
    recipients = recipients,
    pos = {x = pos.x, y = pos.y, z = pos.z},
  }

  return formspec
end

local function show_dropbox(player, pos, animate)
  local player_name = player:get_player_name()
  local previous_session = dropbox_sessions[player_name]

  if not pos and previous_session then
    pos = previous_session.pos
  end

  if not pos then
    return
  end

  if previous_session and previous_session.pos and not same_position(previous_session.pos, pos) then
    close_dropbox_session(player)
  end

  if animate ~= false then
    animate_dropbox_open(pos)
  end

  get_dropbox_inventory(player)
  core.show_formspec(player_name, "jc_special:dropbox", dropbox_formspec(player, pos))
end

-- ============================================================
-- RETURN UNSENT ITEMS TO PLAYER
-- ============================================================

local function return_dropbox_items(player)
  local player_name = player:get_player_name()

  local inv = core.get_inventory({
    type = "detached",
    name = dropbox_inventory_name(player_name),
  })

  if not inv then
    return
  end

  local player_inv = player:get_inventory()

  for i = 1, inv:get_size("send") do
    local stack = inv:get_stack("send", i)

    if not stack:is_empty() then
      local leftover = player_inv:add_item("main", stack)

      if not leftover:is_empty() then
        core.add_item(player:get_pos(), leftover)
      end

      inv:set_stack("send", i, ItemStack(""))
    end
  end
end

-- ============================================================
-- SEND MAIL
-- ============================================================

local function send_mail(player, mailbox)
  local player_name = player:get_player_name()

  if not mailbox or not mailbox.public then
    return false, S("That mailbox is no longer available.")
  end

  if mailbox.owner == "" then
    return false, S("Invalid mailbox owner.")
  end

  local pos = mailbox.pos

  -- Load the destination area before accessing the mailbox.
  core.load_area(pos, pos)

  local node = core.get_node_or_nil(pos)

  if not node then
    return false, S("The destination mailbox could not be loaded.")
  end

  if not is_mailbox_node(node.name) then
    unregister_mailbox(pos)
    return false, S("The destination mailbox no longer exists.")
  end

  local meta = core.get_meta(pos)

  if meta:get_string("owner") ~= mailbox.owner then
    unregister_mailbox(pos)
    return false, S("The mailbox owner has changed.")
  end

  local settings = get_settings(meta)
  local destination_inv = meta:get_inventory()

  local source_inv = core.get_inventory({
    type = "detached",
    name = dropbox_inventory_name(player_name),
  })

  if not source_inv or source_inv:is_empty("send") then
    return false, S("You have no items to send.")
  end

  -- Validate every item before changing either inventory.
  local item_count = 0

  for i = 1, source_inv:get_size("send") do
    local stack = source_inv:get_stack("send", i)

    if not stack:is_empty() then
      if not settings.allow_starter_items and is_starter_item(stack) then
        return false, S("This mailbox does not accept starter items: @1", stack:get_name())
      end

      item_count = item_count + stack:get_count()
    end
  end

  if item_count == 0 then
    return false, S("You have no items to send.")
  end

  -- Back up the destination inventory.
  local backup = destination_inv:get_list("main")

  -- Attempt the entire transfer.
  for i = 1, source_inv:get_size("send") do
    local stack = source_inv:get_stack("send", i)

    if not stack:is_empty() then
      local leftover = destination_inv:add_item("main", stack)

      if not leftover:is_empty() then
        -- Restore the destination if anything failed.
        destination_inv:set_list("main", backup)
        return false, S("The recipient mailbox does not have enough room.")
      end
    end
  end

  -- Delivery succeeded. Clear the sending inventory.
  for i = 1, source_inv:get_size("send") do
    source_inv:set_stack("send", i, ItemStack(""))
  end

  local mailbox_name = meta:get_string("mailbox_name")
  local coords = core.colorize("#FFFF00", core.pos_to_string(pos))
  local colored_count = core.colorize("#FFFF00", tostring(item_count))

  if settings.notifications then
    local message = S(
      "[Mailbox] @1 sent @2 @3 to your mailbox '@4' at @5.",
      core.colorize("#00FF00", player_name),
      colored_count,
      item_word(item_count),
      mailbox_name,
      coords
    )

    queue_notification(mailbox.owner, message)
  end

  core.sound_play("default_item_smoke", {to_player = player_name, gain = 0.6})

  core.chat_send_player(player_name, S(
    "Successfully delivered @1 @2 to mailbox '@3' owned by @4 at @5.",
    colored_count,
    item_word(item_count),
    mailbox_name,
    core.colorize("#00FF00", mailbox.owner),
    coords
  ))

  return true
end

-- ============================================================
-- DROPBOX NODE
-- ============================================================

core.register_node("jc_special:dropbox", {
  description = S("Dropbox"),

  -- The visible B3D model is supplied by the animated entity above.
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {},
  },

  inventory_image = "jc_special_dropbox_inv.png",
  wield_image = "jc_special_dropbox_inv.png",

  paramtype = "light",
  paramtype2 = "4dir",

  groups = {
    cracky = 2,
    oddly_breakable_by_hand = 2,
  },

  is_ground_content = false,
  sounds = default.node_sound_metal_defaults(),

  collision_box = {
    type = "fixed",
    fixed = {
      {-0.35, -0.5, -0.35, 0.35, 0.8, 0.35},
    },
  },

  selection_box = {
    type = "fixed",
    fixed = {
      {-0.35, -0.5, -0.35, 0.35, 0.8, 0.35},
    },
  },

  on_construct = function(pos)
    ensure_dropbox_visual(pos)
  end,

  after_place_node = function(pos, placer, itemstack, pointed_thing)
    ensure_dropbox_visual(pos)
  end,

  on_rotate = function(pos, node, user, mode, new_param2)
    core.swap_node(pos, {
      name = node.name,
      param2 = new_param2,
    })

    ensure_dropbox_visual(pos)

    return true
  end,

  on_rightclick = function(pos, node, clicker)
    show_dropbox(clicker, pos, true)
  end,

  on_destruct = function(pos)
    remove_dropbox_visual(pos)
  end,

  on_blast = function()
  end,
})

core.register_lbm({
  label = "Restore Dropbox visuals",
  name = "jc_special:restore_dropbox_visuals",
  nodenames = {"jc_special:dropbox"},
  run_at_every_load = true,
  action = function(pos, node)
    ensure_dropbox_visual(pos, node)
  end,
})

core.register_craft({
  output = "jc_special:dropbox",
  recipe = {
    {"default:steelblock", "dye:blue", "default:steelblock"},
    {"dye:blue", "jc_special:mailbox", "dye:blue"},
    {"default:steelblock", "dye:blue", "default:steelblock"},
  },
})

-- ============================================================
-- FORMSPEC CALLBACKS
-- ============================================================

local function checkbox_value(value, current)
  if value == "true" then
    return 1
  elseif value == "false" then
    return 0
  end

  return current
end

core.register_on_player_receive_fields(function(player, formname, fields)
  local player_name = player:get_player_name()

  -- ----------------------------------------------------------
  -- MAILBOX SETTINGS
  -- ----------------------------------------------------------

  if formname == "jc_special:maildrop" then
    if fields.quit then
      return_maildrop_items(player)
      maildrop_sessions[player_name] = nil
      return
    end

    if fields.deliver then
      local success, message = deliver_maildrop(player)

      if not success then
        core.chat_send_player(player_name, message)
      end

      if maildrop_sessions[player_name] then
        core.show_formspec(player_name, formname, maildrop_formspec(player, maildrop_sessions[player_name]))
      end
    end

    return
  end

  local posstr = formname:match("^jc_special:mailbox:(.+)$")

  if posstr then
    local pos = core.string_to_pos(posstr)

    if not pos then
      return
    end

    local node = core.get_node_or_nil(pos)

    if not node or not is_mailbox_node(node.name) then
      return
    end

    local meta = core.get_meta(pos)

    if meta:get_string("owner") ~= player_name then
      return
    end

    -- Save checkbox changes immediately.
    local checkbox_changed = false

    if fields.allow_starter_items ~= nil then
      meta:set_int("allow_starter_items", fields.allow_starter_items == "true" and 1 or 0)
      checkbox_changed = true
    end

    if fields.public ~= nil then
      meta:set_int("public", fields.public == "true" and 1 or 0)
      checkbox_changed = true
    end

    if fields.notifications ~= nil then
      meta:set_int("notifications", fields.notifications == "true" and 1 or 0)
      checkbox_changed = true
    end

    if checkbox_changed then
      update_mailbox(pos, meta:get_string("mailbox_name"), get_settings(meta))
    end

    if not fields.save and not fields.getitems then
      return
    end

    if fields.getitems then
      local mailbox_inv = meta:get_inventory()
      local player_inv = player:get_inventory()
      local total_moved = 0

      for i = 1, mailbox_inv:get_size("main") do
        local stack = mailbox_inv:get_stack("main", i)

        if not stack:is_empty() then
          local original_count = stack:get_count()
          local leftover = player_inv:add_item("main", stack)

          local moved = original_count - leftover:get_count()
          total_moved = total_moved + moved

          mailbox_inv:set_stack("main", i, leftover)
        end
      end

      core.chat_send_player(player_name, S(
        "Retrieved @1 @2 from your mailbox at @3.",
        core.colorize("#FFFF00", tostring(total_moved)),
        item_word(total_moved),
        core.colorize("#FFFF00", core.pos_to_string(pos))
      ))

      core.show_formspec(player_name, formname, mailbox_formspec(pos))
      return
    end

    local name = fields.mailbox_name or ""
    name = name:match("^%s*(.-)%s*$")
    name = string.sub(name, 1, 40)

    if name == "" then
      name = node.name == "jc_special:mailbox_modern" and S("Modern Mailbox") or S("Mailbox")
    end

    meta:set_string("mailbox_name", name)

    update_mailbox(pos, name, get_settings(meta))
    update_mailbox_infotext(pos)

    core.show_formspec(player_name, formname, mailbox_formspec(pos))
    return
  end

  -- ----------------------------------------------------------
  -- DROPBOX
  -- ----------------------------------------------------------

  if formname ~= "jc_special:dropbox" then
    return
  end

  if fields.quit then
    return_dropbox_items(player)
    close_dropbox_session(player)
    return
  end

  if not fields.send then
    return
  end

  local session = dropbox_sessions[player_name]

  if not session then
    return
  end

  local selected = tonumber(fields.recipient)

  if not selected or selected == 1 or not session.recipients[selected - 1] then
    core.chat_send_player(player_name, S("Please select a recipient."))
    show_dropbox(player, nil, false)
    return
  end

  local selected_mailbox = session.recipients[selected - 1]
  local mailbox = mailboxes[selected_mailbox.id]

  if not mailbox or not mailbox.public then
    core.chat_send_player(player_name, S("That mailbox is no longer available."))
    show_dropbox(player, nil, false)
    return
  end

  local success, message = send_mail(player, mailbox)

  if not success then
    core.chat_send_player(player_name, message)
  end

  show_dropbox(player, nil, false)
end)

-- Return any unsent items when a player disconnects.
core.register_on_leaveplayer(function(player)
  return_dropbox_items(player)
  return_maildrop_items(player)

  close_dropbox_session(player)
  maildrop_sessions[player:get_player_name()] = nil
end)

core.register_on_joinplayer(function(player)
  get_dropbox_inventory(player)
end)

-- ============================================================
-- COMPATIBILITY — force-replace homedecor:inbox
-- register_alias alone is ignored when the target item already exists.
-- ============================================================

core.register_on_mods_loaded(function()
  if core.registered_nodes["homedecor:inbox"] or core.registered_aliases["homedecor:inbox"] then
    if core.register_alias_force then
      core.register_alias_force("homedecor:inbox", "jc_special:mailbox")
    else
      -- Older engines: clear the old registration path as best we can, then alias.
      core.register_alias("homedecor:inbox", "jc_special:mailbox")
    end
    core.log("action", "[jc_special] Aliased homedecor:inbox -> jc_special:mailbox")
  end
end)

-- Also register early so itemstrings resolve during craft/give before mods_loaded.
if core.register_alias_force then
  core.register_alias_force("homedecor:inbox", "jc_special:mailbox")
else
  core.register_alias("homedecor:inbox", "jc_special:mailbox")
end

core.log("action", "[jc_special] Mailbox and Dropbox system loaded.")

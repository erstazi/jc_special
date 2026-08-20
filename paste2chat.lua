-- paste2chat.lua

local S = core.get_translator(core.get_current_modname())

--------------------------------------------------------
-- PASTE TO CHAT
--------------------------------------------------------

local paste_formspec = "jc_special:paste_chat"

core.register_chatcommand("paste", {
  description = S("Open a text box to paste a message into chat."),
  func = function(name)
    local formspec =
      "formspec_version[4]" ..
      "size[10,6]" ..
      "label[0.5,0.4;" .. core.formspec_escape(S("Paste Message")) .. "]" ..
      "textarea[0.5,1.0;9,3.5;message;" .. core.formspec_escape( S("Enter your chat message here (maximum 500 characters):") ) .. ";]" ..
      "button[2.5,5.0;2.0,0.8;send;" .. core.formspec_escape(S("SEND")) .. "]" ..
      "button[5.0,5.0;2.0,0.8;cancel;" .. core.formspec_escape(S("CANCEL")) .. "]"

    core.show_formspec(
      name,
      paste_formspec,
      formspec
    )

    return true
  end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= paste_formspec then
    return
  end

  local name = player:get_player_name()

  if fields.cancel then
    core.close_formspec(name, formname)
    return
  end

  if not fields.send then
    return
  end

  local message = fields.message or ""

  ------------------------------------------------------
  -- Limit to 500 characters
  ------------------------------------------------------

  if #message > 500 then
    core.chat_send_player( name, S("Your message is limited to 500 characters.") )
    return
  end

  ------------------------------------------------------
  -- Remove leading/trailing whitespace
  ------------------------------------------------------

  message = message:gsub("^%s+", ""):gsub("%s+$", "")

  if message == "" then
    core.chat_send_player( name, S("The message cannot be empty.") )
    return
  end

  core.close_formspec(name, formname)

  ------------------------------------------------------
  -- Use ranks chat handling if available
  ------------------------------------------------------

  if ranks and ranks.chat_send then
    local handled = ranks.chat_send(name, message)

    if handled then
      return
    end
  end

  ------------------------------------------------------
  -- Normal fallback chat formatting
  ------------------------------------------------------

  core.chat_send_all( "<" .. name .. "> " .. message )
end)
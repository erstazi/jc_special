--[[
========================================================================
  player_lookup.lua
  Player Lookup
  /lookup <player>

  Shows the player's:
    - IP address
    - Language
    - Location

  Requires server privilege.
  Location is obtained asynchronously from ip-api.com.

========================================================================
]]

local http = core.request_http_api()

-- ========================================================================
-- Language names
-- ========================================================================

local language_names = {
  -- English
  [""] = "English",
  en = "English",
  en_US = "English (United States)",
  en_GB = "English (United Kingdom)",
  en_AU = "English (Australia)",
  en_CA = "English (Canada)",
  en_IE = "English (Ireland)",
  en_NZ = "English (New Zealand)",
  en_ZA = "English (South Africa)",

  -- Spanish
  es = "Spanish",
  es_ES = "Spanish (Spain)",
  es_MX = "Spanish (Mexico)",
  es_AR = "Spanish (Argentina)",
  es_CL = "Spanish (Chile)",
  es_CO = "Spanish (Colombia)",

  -- Portuguese
  pt = "Portuguese",
  pt_PT = "Portuguese (Portugal)",
  pt_BR = "Portuguese (Brazil)",

  -- French
  fr = "French",
  fr_FR = "French (France)",
  fr_CA = "French (Canada)",

  -- German
  de = "German",
  de_DE = "German (Germany)",
  de_AT = "German (Austria)",
  de_CH = "German (Switzerland)",

  -- East Asian
  zh = "Chinese",
  zh_CN = "Chinese (Simplified)",
  zh_TW = "Chinese (Traditional)",
  zh_HK = "Chinese (Hong Kong)",
  ja = "Japanese",
  ko = "Korean",

  -- Slavic
  ru = "Russian",
  uk = "Ukrainian",
  pl = "Polish",
  cs = "Czech",
  sk = "Slovak",
  bg = "Bulgarian",
  sr = "Serbian",
  hr = "Croatian",
  sl = "Slovenian",

  -- Dutch / Scandinavian
  nl = "Dutch",
  nl_NL = "Dutch (Netherlands)",
  sv = "Swedish",
  da = "Danish",
  no = "Norwegian",
  nb = "Norwegian Bokmål",
  nn = "Norwegian Nynorsk",
  fi = "Finnish",
  is = "Icelandic",

  -- Italian / Romanian / Greek
  it = "Italian",
  ro = "Romanian",
  el = "Greek",

  -- Turkish / Hungarian
  tr = "Turkish",
  hu = "Hungarian",

  -- Hebrew / Arabic
  he = "Hebrew",
  ar = "Arabic",

  -- Indian languages
  hi = "Hindi",
  bn = "Bengali",
  ta = "Tamil",
  te = "Telugu",
  mr = "Marathi",

  -- Southeast Asian languages
  vi = "Vietnamese",
  th = "Thai",
  id = "Indonesian",
  ms = "Malay",

  -- Other
  ca = "Catalan",
  eu = "Basque",
  gl = "Galician",
  et = "Estonian",
  lv = "Latvian",
  lt = "Lithuanian",
  fa = "Persian",
  ur = "Urdu",
}

-- ========================================================================
-- /lookup <player>
-- ========================================================================
core.register_chatcommand("lookup", {
  params = "<player>",
  description = "Look up a player's information",
  privs = { server = true, },
  func = function(name, param)
    param = param:trim()
    if param == "" then
      return false, "Usage: /lookup <player>"
    end

    -- ------------------------------------------------------------
    -- Find the player
    -- ------------------------------------------------------------
    local player = core.get_player_by_name(param)
    if not player then
      return false, "Player '" .. param .. "' is not online."
    end

    local player_name = player:get_player_name()

    -- ------------------------------------------------------------
    -- Get player information from Luanti
    -- ------------------------------------------------------------
    local info = core.get_player_information(player_name)
    if not info then
      return false, "Unable to get information for " .. player_name .. "."
    end

    local ip = info.address or "Unknown"

    -- Empty/nil language should be treated as English because some reason Luanti doesn't show `en` for English players
    local lang_code = info.lang_code or ""
    local language = language_names[lang_code]

    if not language then
      -- Unknown language code: show the code rather than
      -- incorrectly claiming the player is English.
      language = lang_code

      if language == "" then
        language = "English"
      end
    end

    -- ------------------------------------------------------------
    -- Send the information we already have
    -- ------------------------------------------------------------
    core.chat_send_player( name, core.colorize( "yellow", "Player: " .. player_name ) )
    core.chat_send_player( name, "IP: " .. ip )
    core.chat_send_player( name, "Language: " .. language .. " (" .. (lang_code ~= "" and lang_code or "en") .. ")" )

    -- ------------------------------------------------------------
    -- HTTP API unavailable
    -- ------------------------------------------------------------
    if not http then
      core.chat_send_player(name, core.colorize( "#FF7C7C", "Location lookup unavailable. " .. "HTTP access is not enabled for this mod." ) )
      return true
    end

    -- ------------------------------------------------------------
    -- Asynchronous location lookup
    -- ------------------------------------------------------------
    local url = "http://ip-api.com/json/" .. ip .. "?fields=status,city,regionName,country"

    http.fetch({
      url = url,
      timeout = 5,
    }, function(result)
      -- ----------------------------------------------------------
      -- HTTP request failed
      -- ----------------------------------------------------------
      if not result.succeeded then
        core.chat_send_player( name, core.colorize( "#FF7C7C", "Location lookup failed." ) )
        return
      end

      -- ----------------------------------------------------------
      -- Parse JSON
      -- ----------------------------------------------------------
      local data = core.parse_json(result.data)
      if not data then
        core.chat_send_player( name, core.colorize( "#FF7C7C", "Location lookup returned invalid data." ) )
        return
      end

      -- ----------------------------------------------------------
      -- API reported failure
      -- ----------------------------------------------------------
      if data.status ~= "success" then
        core.chat_send_player( name, core.colorize( "#FF7C7C", "Unable to determine location for " .. player_name .. "." ) )
        return
      end

      -- ----------------------------------------------------------
      -- Build location
      -- ----------------------------------------------------------
      local city = data.city or "Unknown"
      local region = data.regionName or "Unknown"
      local country = data.country or "Unknown"
      local location = city .. ", " .. region .. ", " .. country

      -- ----------------------------------------------------------
      -- Send location
      -- ----------------------------------------------------------
      core.chat_send_player(name, "Location: " .. location )
    end)

    return true
  end,
})
-- sneakjump.lua

local sneakjump_exempt_players = {
  ["test"] = true,
  ["Bierbrouwer"] = true,
}

local function enable_sneakjump(player)
  if not player or not player:is_player() then
    return
  end

  if sneakjump_exempt_players[player:get_player_name()] then
    return
  end

  player:set_physics_override({
    sneak_glitch = true,
    new_move = false,
  })
end

core.register_on_joinplayer(enable_sneakjump)
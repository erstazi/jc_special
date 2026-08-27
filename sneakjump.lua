-- sneakjump.lua

local function enable_sneakjump(player)
    player:set_physics_override({
        sneak_glitch = true,
        new_move = false,
    })
end

core.register_on_joinplayer(enable_sneakjump)
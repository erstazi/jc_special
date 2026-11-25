local S = core.get_translator(core.get_current_modname())

core.register_chatcommand("dice", {
  params = S("[2-1000]"),
  description = S("Roll a dice"),

  func = function(name, param)
    -- Chance format: 1/3, 1/5, etc.
    local chance_den = param:match("^1%s*/%s*(%d+)$")

    if chance_den then
      chance_den = tonumber(chance_den)
      if chance_den < 2 or chance_den > 1000 then
        return false, S("Usage: /dice [2-1000]")
      end
      local result = math.random(1, chance_den)
      -- Player jesus spun the wheel, and won with a 50% chance!
      if result == 1 then
        core.chat_send_all( S("Player @1 won the 1/@2 chance!", name, chance_den) )
      else
        core.chat_send_all( S("Player @1 lost the 1/@2 chance.", name, chance_den) )
      end
      return true
    end

    -- Normal dice roll.
    local max = tonumber(param)

    -- If no number is specified, use 6.
    if not max then
      max = 7
    end

    -- It only allows between 2 and 1000.
    if max < 2 or max > 1000 then
      return false, S("Usage: /dice [2-1000]")
    end

    max = math.floor(max)

    -- Random number between 1 and max.
    local result = math.random(1, max)
    core.chat_send_all( S("Player @1 rolled the dice, and got @2 out of @3!", name, result, max) )
    return true
  end
})

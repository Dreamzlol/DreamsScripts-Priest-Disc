local Unlocker, awful, rotation = ...
local disc = rotation.priest.disc
local player = awful.player

if player.class2 ~= "PRIEST" then
    return
end

function rotation.apl_pvp()
    if player.mounted then
        return
    end
    if player.buff("Drink") then
        return
    end
    if player.casting == "Mind Control" or player.channel == "Mind Control" then
        return
    end

    awful.fullGroup.sort(function(x, y) return x.hp < y.hp end)

    disc.holy_nova("stealth")
    disc.shadow_word_death("tremor")
    disc.auto_attack("totems")
    disc.shadow_word_death("polymorph")
    disc.shadow_word_death("seduction")
    disc.fear_ward()
    disc.dispel_magic("focus")
    disc.mass_dispel("combat")
    disc.mass_dispel("immune")
    disc.psychic_scream("lowhp")
    disc.psychic_scream("mutiple")
    disc.psychic_scream("focus")
    disc.desperate_prayer()
    disc.pain_suppression()
    disc.power_word_shield()
    disc.penance()
    disc.prayer_of_mending()
    disc.renew()
    disc.holy_nova("moving")
    disc.inner_fire()
    disc.shackle_undead("lich")
    disc.shackle_undead("gargoyle")
    disc.dispel_magic("defensive")
    disc.dispel_magic("offensive")

    if awful.burst then
        disc.power_infusion("burst")
        disc.shadow_word_death("burst")
        disc.holy_fire("burst")
        disc.mind_blast("burst")
        disc.penance("burst")
        disc.shadowfiend()
        disc.devouring_plague("burst")
    end

    disc.abolish_disease()
    disc.binding_heal()
    disc.flash_heal()
    disc.holy_nova("snakes")
    disc.shadow_word_death("burst")
    disc.devouring_plague()
    disc.shadowfiend()
    disc.holy_fire()
    disc.mind_blast()
    disc.shadow_word_pain()
    disc.power_word_fortitude()
    disc.smite()
end

return rotation.apl_pvp

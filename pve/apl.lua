local Unlocker, awful, rotation = ...
local disc = rotation.priest.disc
local player = awful.player

if player.class2 ~= "PRIEST" then
    return
end

function rotation.apl_pve()
    if player.mounted or player.dead or player.buff("Drink") then
        return
    end

    if not rotation.settings.use_ooc then
        if not player.combat then
            return
        end
    end

    disc.inner_fire()
    disc.fear_ward()
    disc.mass_dispel()
    disc.power_infusion()
    disc.hymn_of_hope()
    disc.shadowfiend()
    disc.pain_supression()
    disc.desperate_prayer()
    disc.power_word_shield("tank")
    disc.penance("tank")
    disc.prayer_of_mending("tank")
    disc.power_word_shield()
    disc.penance()
    disc.dispel_magic()
    disc.cure_disease()
    disc.flash_heal()
    disc.binding_heal()
    disc.renew("tank")
    disc.power_word_shield("pre")
end

return rotation.apl_pve

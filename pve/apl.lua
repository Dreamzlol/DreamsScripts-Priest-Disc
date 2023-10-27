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
    disc.WasCastingCheck()
    disc.pve_inner_fire()
    disc.pve_fear_ward()
    disc.pve_mass_dispel()
    disc.pve_power_infusion()
    disc.pve_hymn_of_hope()
    disc.pve_shadowfiend()
    disc.pve_pain_supression()
    disc.pve_desperate_prayer()
    disc.pve_power_word_shield("tank")
    disc.pve_shadow_word_death("web wrap") -- Dungeon Logic
    disc.pve_mind_blast("web wrap") -- Dungeon Logic
    disc.pve_holy_fire("web wrap") -- Dungeon Logic
    disc.pve_penance("tank")
    disc.pve_prayer_of_mending("tank")
    disc.pve_power_word_shield()
    disc.pve_penance()
    disc.pve_dispel_magic()
    disc.pve_cure_disease()
    disc.pve_flash_heal()
    disc.pve_binding_heal()
    disc.pve_renew("tank")
    disc.pve_power_word_shield("pre")
    disc.pve_holy_fire() -- Dungeon Logic
    disc.pve_mind_blast() -- Dungeon Logic
    disc.pve_smite() -- Dungeon Logic
end

local Unlocker, awful, rotation = ...
local disc = rotation.priest.disc
local Spell = awful.Spell
local player, target, focus = awful.player, awful.target, awful.focus

awful.Populate({
    pve_penance           = Spell(53007, { beneficial = true }),
    pve_power_word_shield = Spell(48066, { beneficial = true, ignoreUsable = true }),
    pve_prayer_of_mending = Spell(48113, { beneficial = true }),
    pve_inner_fire        = Spell(48168, { beneficial = true }),
    pve_flash_heal        = Spell(48071, { beneficial = true }),
    pve_renew             = Spell(48068, { beneficial = true }),
    pve_pain_supression   = Spell(33206, { beneficial = true }),
    pve_binding_heal      = Spell(48120, { beneficial = true }),
    pve_desperate_prayer  = Spell(48173, { beneficial = true }),
    pve_power_infusion    = Spell(10060, { beneficial = true }),
    pve_cure_disease      = Spell(528, { beneficial = true }),
    pve_dispel_magic      = Spell(988, { beneficial = true }),
    pve_shadowfiend       = Spell(34433),
    pve_hymn_of_hope      = Spell(64901),
    pve_fear_ward         = Spell(6346, { ignoreCasting = true }),
    pve_mass_dispel       = Spell(32375, { ignoreFacing = true, radius = 15 }),
    pve_smite             = Spell(48123, { damage = "magic" }),
    pve_mind_blast        = Spell(48127, { damage = "magic" }),
    pve_holy_fire         = Spell(48135, { damage = "magic" }),
    pve_shadow_word_death = Spell(48158, { ignoreFacing = true, ignoreCasting = true, ignoreChanneling = true }),
}, disc, getfenv(1))

local spell_stop_casting = awful.unlock("SpellStopCasting")

local function unit_filter(obj)
    return obj.los and not obj.dead
end

local wasCasting = {}
function disc.WasCastingCheck()
    local time = awful.time
    if player.casting then
        wasCasting[player.castingid] = time
    end
    for spell, when in pairs(wasCasting) do
        if time - when > 0.100 + awful.buffer then
            wasCasting[spell] = nil
        end
    end
end

local tank_buffs = {
    ["Flask of Stoneblood"] = true,
    ["Shield Wall"] = true,
    ["Shield Block"] = true,
    ["Holy Shield"] = true,
    ["Righteous Fury"] = true,
    ["Bear Form"] = true,
    ["Savage Defense"] = true,
    ["Frenzied Regeneration"] = true,
    ["Frost Presence"] = true
}

local function is_tank(unit)
    if unit.role == "tank" or unit.aggro or unit.threat == 3 then
        return true
    end

    if not unit.buffs then
        return
    end
    for i, buff in ipairs(unit.buffs) do
        local name = unpack(buff)
        if tank_buffs[name] then
            return true
        end
    end
end

local function is_boss(unit)
    return unit.exists and unit.level == -1 or (unit.level == 82 and player.buff("Luck of the Draw"))
end

local mass_dispel_debuff = {
    ["Freeze"] = true,
    ["Terrifying Screech"] = true
}

local function has_dispel_debuff(unit)
    if unit.debuffs then
        for i, debuff in ipairs(unit.debuffs) do
            local name = unpack(debuff)
            if mass_dispel_debuff[name] then
                return true
            end
        end
    end
    return false
end

local mass_dispel_radius = 15
local md_filter = function(obj, estimated_distance_to_cast_position)
    if has_dispel_debuff(obj) and obj.friendly then
        if estimated_distance_to_cast_position <= mass_dispel_radius then
            return true
        elseif estimated_distance_to_cast_position <= mass_dispel_radius * 2 then
            return "avoid"
        end
    end
end

pve_mass_dispel:Callback(function(spell)
    local friend = awful.fullGroup.within(30).filter(unit_filter).lowest
    if has_dispel_debuff(friend) then
        if spell:SmartAoE(friend, {
                filter = md_filter,
                movePredTime = awful.buffer,
                minHit = 3,
                maxHit = 25,
                sort = function(x, y)
                    return x.hit > y.hit
                end
            }) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

local on_cast = {
    ["Terrifying Screech"] = true
}

pve_fear_ward:Callback(function(spell)
    if player.buff("Fear Ward") then
        return
    end
    local enemy = awful.enemies.within(40).filter(unit_filter).lowest
    if on_cast[enemy.casting] then
        spell_stop_casting()
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

local debuff_disease = {
    ["Disease"] = true
}

pve_cure_disease:Callback(function(spell)
    if not rotation.settings.use_cure_disease then
        return
    end
    awful.fullGroup.within(40).filter(unit_filter).loop(function(friend)
        if not friend then
            return
        end

        for i = 1, #friend.debuffs do
            local _, _, _, type = unpack(friend['debuff' .. i])
            if debuff_disease[type] then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end
    end)
end)

local debuff_magic = {
    ["Magic"] = true
}

local debuff_name = {
    ["Frostbolt"] = true,
    ["Frostbolt Volley"] = true,
    ["Cone of Cold"] = true
}

pve_dispel_magic:Callback(function(spell)
    if not rotation.settings.use_dispel_magic then
        return
    end
    awful.fullGroup.within(40).filter(unit_filter).loop(function(friend)
        if not friend then
            return
        end

        for i = 1, #friend.debuffs do
            local name, _, _, type = unpack(friend['debuff' .. i])
            if debuff_magic[type] and not debuff_name[name] then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end
    end)
end)

pve_penance:Callback(function(spell)
    if not rotation.settings.use_penance then
        return
    end
    if target.cast == "Ground Tremor" or target.cast == "Flame Jets" then
        return
    end
    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not friend.debuff("Weakened Soul") then
        return
    end
    if player.moving then
        return
    end
    if friend.hp < rotation.settings.penance_hp then
        if spell:Cast(friend) then
            awful.controlMovement(1.5)
            awful.alert(spell.name .. " (Controlling Movement)", spell.id)
            return
        end
    end
end)

pve_penance:Callback("tank", function(spell)
    if not rotation.settings.use_penance_tank then
        return
    end
    if target.cast == "Ground Tremor" or target.cast == "Flame Jets" then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not is_tank(friend) then
        return
    end
    if player.moving then
        return
    end
    if friend.hp < rotation.settings.penance_tank_hp then
        if spell:Cast(friend) then
            awful.controlMovement(1.5)
            awful.alert(spell.name .. " (Controlling Movement)", spell.id)
            return
        end
    end
end)

pve_pain_supression:Callback(function(spell)
    if not rotation.settings.use_pain_supression_tank then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not is_tank(friend) then
        return
    end
    if friend.hp < rotation.settings.pain_supression_hp then
        if spell:Cast(friend) then
            awful.alert(spell.name .. " (Tank)", spell.id)
            return
        end
    end
end)

pve_power_word_shield:Callback("tank", function(spell)
    if not rotation.settings.use_power_word_shield_tank then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not is_tank(friend) then
        return
    end
    if not friend.buff("Power Word: Shield") and not friend.debuff("Weakened Soul") then
        if friend.hp < rotation.settings.power_word_shield_tank_safe_hp then
            if spell:Cast(friend) then
                awful.alert(spell.name .. " (Tank)", spell.id)
                return
            end
        end
    end
end)

pve_power_word_shield:Callback(function(spell)
    if not rotation.settings.use_power_word_shield then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if is_tank(friend) then
        return
    end
    if friend and not friend.buff("Power Word: Shield") and not friend.debuff("Weakened Soul") then
        if friend.hp < rotation.settings.power_word_shield_safe_hp then
            if spell:Cast(friend) then
                awful.alert(spell.name .. "(Safe)", spell.id)
                return
            end
        end
    end
end)

pve_power_word_shield:Callback("pre", function(spell)
    if not rotation.settings.use_power_word_shield_pre_shield then
        return
    end

    awful.fullGroup.within(40).filter(unit_filter).loop(function(friend)
        if not friend then
            return
        end
        if is_tank(friend) then
            return
        end
        if not friend.buff("Power Word: Shield") and not friend.debuff("Weakened Soul") then
            if spell:Cast(friend) then
                awful.alert(spell.name .. " (Pre Shield)", spell.id)
                return
            end
        end
    end)
end)

pve_inner_fire:Callback(function(spell)
    if not rotation.settings.use_inner_fire then
        return
    end
    if player.buff("Inner Fire") then
        return
    end
    if spell:Cast(player) then
        awful.alert(spell.name, spell.id)
        return
    end
end)

pve_flash_heal:Callback(function(spell)
    if not rotation.settings.use_flash_heal then
        return
    end
    if wasCasting[spell.id] then return end
    if target.cast == "Ground Tremor" or target.cast == "Flame Jets" then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not friend.debuff("Weakened Soul") then
        return
    end
    if not pve_penance.cooldown == 0 then
        return
    end
    if friend.hp < rotation.settings.flash_heal_hp then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_shadowfiend:Callback(function(spell)
    if not rotation.settings.use_shadowfiend then
        return
    end
    if player.debuff("Aura of Despair") then
        return
    end
    if not is_boss(target) then
        return
    end
    if player.manaPct < rotation.settings.shadowfiend_mp then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_renew:Callback("tank", function(spell)
    if not rotation.settings.use_renew_tank then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not is_tank(friend) then
        return
    end
    if friend.buff("Renew") then
        return
    end
    if spell:Cast(friend) then
        awful.alert(spell.name .. " (Tank)", spell.id)
        return
    end
end)

pve_smite:Callback(function(spell)
    if not rotation.settings.use_damage_gamma then
        return
    end
    if not player.buff("Confessor's Wrath") then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    local enemy = awful.enemies.within(30).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not enemy then
        return
    end
    if enemy.dead then
        return
    end
    if not enemy.combat then
        return
    end
    if friend.hp > 80 and player.manaPct > 40 then
        if spell:Cast(enemy) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_mind_blast:Callback(function(spell)
    if not rotation.settings.use_damage_gamma then
        return
    end
    if not player.buff("Confessor's Wrath") then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    local enemy = awful.enemies.within(30).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not enemy then
        return
    end
    if enemy.dead then
        return
    end
    if not enemy.combat then
        return
    end
    if friend.hp > 80 and player.manaPct > 40 then
        if spell:Cast(enemy) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_mind_blast:Callback("web wrap", function(spell)
    if player.debuff("Web Wrap") then
        return
    end
    awful.units.loop(function(obj)
        if not obj then
            return
        end
        if obj.name == "Web Wrap" then
            if spell:Cast(obj) then
                awful.alert(spell.name .. " (Web Wrap)", spell.id)
                return
            end
        end
    end)
end)

pve_holy_fire:Callback(function(spell)
    if not rotation.settings.use_damage_gamma then
        return
    end
    if not player.buff("Confessor's Wrath") then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    local enemy = awful.enemies.within(30).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not enemy then
        return
    end
    if enemy.dead then
        return
    end
    if not enemy.combat then
        return
    end
    if friend.hp > 80 and player.manaPct > 40 then
        if spell:Cast(enemy) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_holy_fire:Callback("web wrap", function(spell)
    if player.debuff("Web Wrap") then
        return
    end
    awful.units.loop(function(obj)
        if not obj then
            return
        end
        if obj.name == "Web Wrap" then
            if spell:Cast(obj) then
                awful.alert(spell.name .. " (Web Wrap)", spell.id)
                return
            end
        end
    end)
end)

pve_shadow_word_death:Callback("web wrap", function(spell)
    if player.debuff("Web Wrap") then
        return
    end
    awful.units.loop(function(obj)
        if not obj then
            return
        end
        if obj.name == "Web Wrap" then
            if spell:Cast(obj) then
                awful.alert(spell.name .. " (Web Wrap)", spell.id)
                return
            end
        end
    end)
end)

pve_prayer_of_mending:Callback("tank", function(spell)
    if not rotation.settings.use_prayer_of_mending_tank then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if not is_tank(friend) then
        return
    end
    if friend.buff("Prayer of Mending") then
        return
    end
    if spell:Cast(friend) then
        awful.alert(spell.name .. " (Tank)", spell.id)
        return
    end
end)

pve_binding_heal:Callback(function(spell)
    if not rotation.settings.use_binding_heal then
        return
    end

    local friend = awful.friends.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    if friend.hp < rotation.settings.binding_heal_hp and player.hp < rotation.settings.binding_heal_hp then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_desperate_prayer:Callback(function(spell)
    if not rotation.settings.use_desperate_prayer then
        return
    end
    if player.hp < rotation.settings.desperate_prayer_hp then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_power_infusion:Callback(function(spell)
    if not focus then
        return
    end
    if not focus.combat then
        return
    end
    if focus.distance > spell.range then
        return
    end

    -- Execute Phase
    if rotation.settings.power_infusion_conditions["Execute Phase"] then
        if focus.buff("Bloodlust") or focus.buff("Heroism") then
            return
        end
        if is_boss(target) and not target.dead and target.hp < 20 then
            if spell:Cast(focus) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end

    -- after Bloodlust
    if rotation.settings.power_infusion_conditions["After Bloodlust"] then
        if (focus.buff("Bloodlust") and focus.buffRemains("Bloodlust") <= 0.5) or (focus.buff("Heroism") and focus.buffRemains("Heroism") <= 0.5) then
            if spell:Cast(focus) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end

    -- Pull
    if rotation.settings.power_infusion_conditions["At Boss Pull"] then
        if focus.buff("Bloodlust") or focus.buff("Heroism") then
            return
        end
        if is_boss(target) and not target.dead and target.hp >= 80 then
            if spell:Cast(focus) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end

    -- On CD
    if rotation.settings.power_infusion_conditions["On CD"] then
        if focus.buff("Bloodlust") or focus.buff("Heroism") then
            return
        end
        if spell:Cast(focus) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

pve_hymn_of_hope:Callback(function(spell)
    if not is_boss(target) then
        return
    end
    if player.used(34433, 5) then
        if spell:Cast() then
            awful.controlMovement(5)
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

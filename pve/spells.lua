local Unlocker, awful, rotation = ...
local disc = rotation.priest.disc
local Spell = awful.Spell
local player, target = awful.player, awful.target

awful.Populate({
    penance           = Spell(53007, { beneficial = true }),
    power_word_shield = Spell(48066, { beneficial = true, ignoreUsable = true }),
    prayer_of_mending = Spell(48113, { beneficial = true }),
    inner_fire        = Spell(48168, { beneficial = true }),
    flash_heal        = Spell(48071, { beneficial = true }),
    renew             = Spell(48068, { beneficial = true }),
    pain_supression   = Spell(33206, { beneficial = true }),
    binding_heal      = Spell(48120, { beneficial = true }),
    desperate_prayer  = Spell(48173, { beneficial = true }),
    power_infusion    = Spell(10060, { beneficial = true }),
    cure_disease      = Spell(528, { beneficial = true }),
    dispel_magic      = Spell(988, { beneficial = true }),
    shadowfiend       = Spell(34433),
    hymn_of_hope      = Spell(64901),
    fear_ward         = Spell(6346, { ignoreCasting = true }),
    mass_dispel       = Spell(32375, { ignoreFacing = true, radius = 15 }),
}, disc, getfenv(1))

local spell_stop_casting = awful.unlock("SpellStopCasting")

local function unit_filter(obj)
    return obj.los and not obj.dead
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
    return unit.exists and unit.level == -1
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

mass_dispel:Callback(function(spell)
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

fear_ward:Callback(function(spell)
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

cure_disease:Callback(function(spell)
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

dispel_magic:Callback(function(spell)
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

penance:Callback(function(spell)
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


penance:Callback("tank", function(spell)
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


pain_supression:Callback(function(spell)
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

power_word_shield:Callback("tank", function(spell)
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
    if friend.buff("Power Word: Shield") then
        return
    end
    if friend.debuff("Weakened Soul") then
        return
    end
    if friend.hp < rotation.settings.power_word_shield_tank_safe_hp then
        if spell:Cast(friend) then
            awful.alert(spell.name .. " (Tank)", spell.id)
            return
        end
    end
end)

power_word_shield:Callback(function(spell)
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
    if friend.buff("Power Word: Shield") then
        return
    end
    if friend.debuff("Weakened Soul") then
        return
    end
    if friend.hp < rotation.settings.power_word_shield_safe_hp then
        if spell:Cast(friend) then
            awful.alert(spell.name .. "(Safe)", spell.id)
            return
        end
    end
end)

power_word_shield:Callback("pre", function(spell)
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
        if friend.buff("Power Word: Shield") then
            return
        end
        if friend.debuff("Weakened Soul") then
            return
        end
        if spell:Cast(friend) then
            awful.alert(spell.name .. " (Pre Shield)", spell.id)
            return
        end
    end)
end)

inner_fire:Callback(function(spell)
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

flash_heal:Callback(function(spell)
    if not rotation.settings.use_flash_heal then
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
    if not penance.cooldown == 0 then
        return
    end
    if friend.hp < rotation.settings.flash_heal_hp then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)


shadowfiend:Callback(function(spell)
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

renew:Callback("tank", function(spell)
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

prayer_of_mending:Callback("tank", function(spell)
    if not rotation.settings.use_prayer_of_mending_tank then
        return
    end

    local friend = awful.fullGroup.within(40).filter(unit_filter).lowest
    if not friend then
        return
    end
    --if not is_tank(friend) then
    --    return
    --end
    print("Debug: PvE")
    if friend.buff("Prayer of Mending") then
        return
    end
    if spell:Cast(friend) then
        awful.alert(spell.name .. " (Tank)", spell.id)
        return
    end
end)

binding_heal:Callback(function(spell)
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

desperate_prayer:Callback(function(spell)
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

power_infusion:Callback(function(spell)
    awful.fullGroup.within(40).filter(unit_filter).loop(function(friend)
        if not friend then
            return
        end
        if friend.distance > spell.range then
            return
        end

        -- Execute Phase
        if friend.name == rotation.settings.power_infusion and rotation.settings.power_infusion_conditions.execute then
            if friend.buff("Bloodlust") or friend.buff("Heroism") then
                return
            end
            if is_boss(target) and not target.dead and target.hp < 20 then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end

        -- after Bloodlust
        if friend.name == rotation.settings.power_infusion and rotation.settings.power_infusion_conditions.bloodlust then
            if (friend.buff("Bloodlust") and friend.buffRemains("Bloodlust") <= 0.5) or (friend.buff("Heroism") and friend.buffRemains("Heroism") <= 0.5) then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end

        -- Pull
        if friend.name == rotation.settings.power_infusion and rotation.settings.power_infusion_conditions.pull then
            if friend.buff("Bloodlust") or friend.buff("Heroism") then
                return
            end
            if is_boss(target) and not target.dead and target.hp >= 80 then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end

        -- On CD
        if friend.name == rotation.settings.power_infusion and rotation.settings.power_infusion_conditions.on_cd then
            if friend.buff("Bloodlust") or friend.buff("Heroism") then
                return
            end
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

hymn_of_hope:Callback(function(spell)
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

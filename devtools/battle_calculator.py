import random

hmmwv_tow = {
    'display_name': 'HMMWV with TOW AT Missiles',
    'unit_strength': 3,
    'base_defense': 3,
    'armor': 0,
    'attack_bonus': 0,
    'experience': 'regular',
    'main_weapon': {
        'attack_strength': 3,
        'armor_piercing': 4,
        'explosive': 0,
    }
}

taliban_tank = {
    'display_name': 'Soviet Early Cold War Era MBT',
    'unit_strength': 6,
    'base_defense': 4,
    'armor': 5,
    'attack_bonus': 0,
    'experience': 'regular',
    'main_weapon': {
        'attack_strength': 5,
        'armor_piercing': 4,
        'explosive': 2,
    },
    'modifier': {
        'mod1': {
            'name': 'In a really bad state',
            'attack_bonus': -2,
            'base_defense': -1
        }
    }
}

m2a3_bradley = {
    'display_name': 'M2/A3 Bradley - IFV',
    'unit_strength': 4,
    'base_defense': 10,
    'armor': 2,
    'attack_bonus': 0,
    'experience': 'regular',
    'main_weapon': {
        'attack_strength': 4,
        'armor_piercing': 3,
        'explosive': 2
    },
    'modifier': {
        'mod1': {
            'name': 'Doesn\'t want to be here',
            'attack_bonus': -2,
            'base_defense': -2
        },
        'mod2': {
            'name': 'TUSK II',
            'attack_bonus': 2,
            'base_defense': 3
        }
    },
}

us_infantry_rifles = {
    'display_name': 'US Army Infantry',
    'unit_strength': 8,
    'base_defense': 2,
    'armor': 0,
    'attack_bonus': 1,
    'experience': 'regular',
    'main_weapon': {
        'attack_strength': 2,
        'armor_piercing': 0,
        'explosive': 0
    }
}

us_infrantry_at_javelin = {
    'display_name': 'US Navy Marines - Antiarmor Team',
    'unit_strength': 4,
    'base_defense': 1,
    'armor': 0,
    'attack_bonus': 0,
    'experience': 'regular',
    'main_weapon': {
        'attack_strength': 5,
        'armor_piercing': 5,
        'explosive': 0
    }
}

us_infantry_marines_rifles = {
    'display_name': 'US Army Infantry',
    'unit_strength': 5,
    'base_defense': 4,
    'armor': 0,
    'attack_bonus': 4,
    'experience': 'elite',
    'main_weapon': {
        'attack_strength': 2,
        'armor_piercing': 0,
        'explosive': 1
    }
}

taliban_rifles = {
    'display_name': 'Taliban Village Militia',
    'unit_strength': 5,
    'base_defense': 0,
    'armor': 0,
    'attack_bonus': 0,
    'experience': 'untrained',
    'main_weapon': {
        'attack_strength': 2,
        'armor_piercing': 0,
        'explosive': 0
    },
    'modifier': {
        'mod1': {
            'name': 'Bad morale',
            'base_defense': -2
        }
    }
}

taliban_heavy_weapons = {
    'display_name': 'Taliban Heavy Weapons Squad',
    'unit_strength': 4,
    'base_defense': 1,
    'armor': 0,
    'attack_bonus': 0,
    'experience': 'untrained',
    'main_weapon': {
        'attack_strength': 2,
        'armor_piercing': 2,
        'explosive': 1
    },
    'modifier': {
        'mod1': {
            'name': 'Good knowledge of terrain',
            'attack_bonus': 1,
            'base_defense': 2
        }
    }
}

# Experience is a bit weird atm:
# Each unit has an attribute "experience", which is a floating point value.
# Here are defined ranges. The experience is checked, and depending on in which range it is, 
# a different multipler is chosen. That multiplier is then used, and the higher it gets, 
# the more it cancels out the randomness of certain things, like who shoots first, chance of 
# hitting, getting hit etc. to portrait the high level of skill. 
# However, randomness is never completely cancelled out.
experience_levels = {
    'untrained': [0, 0.35, 0],
    'regular': [0.35, 0.65, 0.15],
    'veteran': [0.65, 0.90, 0.35],
    'elite': [0.90, 1, 0.5]
}

DAMAGE_VARIANCE = 0.2
GRAZE_CHANCE = 0.2
GRAZE_MULTIPLIER = 0.3

def apply_modifiers(unit):
    if 'modifier' in unit and len(unit['modifier']) > 0:
        for modifier_name in unit['modifier']:
            modifier = unit['modifier'][modifier_name]
            for attribute in modifier:
                if attribute != 'name':
                    if attribute in unit:
                        unit[attribute] += modifier[attribute]

def get_experience_multiplier(unit):
    if unit['experience'] in experience_levels:
        exp_min, exp_max, multiplier = experience_levels[unit['experience']]
        if unit.get('experience_value', exp_min) >= exp_min and unit.get('experience_value', exp_min) < exp_max:
            return multiplier
        return multiplier
    return 0

print('=================================')
# hmmwv_tow
# taliban_tank
# m2a3_bradley
# us_infantry_rifles
# us_infantry_marines_rifles
# us_infrantry_at_javelin
# taliban_rifles
# taliban_heavy_weapons
defending_unit = m2a3_bradley
print('Defending unit is',defending_unit['experience'],defending_unit['display_name'])
attacking_unit = taliban_heavy_weapons
print('Attacking unit is',attacking_unit['experience'],attacking_unit['display_name'])

# Apply modifiers before calculating effective stats (mirrors in-game update())
apply_modifiers(defending_unit)
apply_modifiers(attacking_unit)

# Attack Example calculations
#### Setting base values
defender_base_defense = defending_unit['base_defense'] + defending_unit.get('temp_defense_bonus', 0)
defender_effective_strength = defending_unit['unit_strength'] + (defending_unit['unit_strength'] * (defender_base_defense/10))
print('Defending unit has strength of',defending_unit['unit_strength'],', effective strength of',defender_effective_strength,'(',defending_unit['unit_strength'],'+',defending_unit['unit_strength'] * (defender_base_defense/10),')')
attacker_effective_attack = attacking_unit['main_weapon']['attack_strength'] + attacking_unit['main_weapon']['attack_strength'] * (attacking_unit['unit_strength']/10)
print('Attacking unit has effective attack of',attacker_effective_attack,'(',attacking_unit['main_weapon']['attack_strength'],'+',attacking_unit['main_weapon']['attack_strength'] * (attacking_unit['unit_strength']/10),')')

## Attack bonus
total_attack_bonus = attacking_unit.get('attack_bonus', 0) + attacking_unit.get('temp_attack_bonus', 0)
if total_attack_bonus != 0:
    attacker_effective_attack += total_attack_bonus
    print('Attacker has attack modifier of',total_attack_bonus,'resulting in effective attack value change to:',attacker_effective_attack)

## Armor Piercing ammo & armor effects
if defending_unit['armor'] > 0:
    print('Defender has armor value of',defending_unit['armor'])
    if attacking_unit['main_weapon']['armor_piercing'] <= 0:
        attacker_effective_attack = attacker_effective_attack * 0.1
        print('Thus, the attacker is ineffective, will only deal ',attacker_effective_attack,' damage.')
    elif attacking_unit['main_weapon']['armor_piercing'] >= 0:
        at_factor = defending_unit['armor'] / attacking_unit['main_weapon']['armor_piercing']
        attacker_effective_attack = attacker_effective_attack + at_factor
        print('But attackers weapons are armor piercing, dealing additional damage of ',at_factor,' totalling ',attacker_effective_attack,' attack value.')

## High Explosive ammo
if defending_unit['armor'] <= 0 and attacking_unit['main_weapon']['explosive'] > 0:
    attacker_effective_attack = attacker_effective_attack * (attacking_unit['main_weapon']['explosive'] * 0.5)
    he_factor = ((attacker_effective_attack * (attacking_unit['main_weapon']['explosive'])) - attacker_effective_attack) / 0.75
    attacker_effective_attack -= defending_unit['base_defense']
    print('Defender is soft target and attacker has HE weapons, attack will deal additional damage of ',he_factor,' totalling ',attacker_effective_attack,' attack value.')

#### Finally, battling it out
print('Attacker attempts attack with',attacker_effective_attack,'effective attack, while defender has',defender_effective_strength,'effective strength.')

# Determine if hit or miss, based on experience of unit
rand = random.random()
if rand >= (0.45 - get_experience_multiplier(attacking_unit)):
    print('Attacker scores a hit.')
    hit = True
else:
    print('Attacker misses and the attack nds.')
    hit = False

if hit:
    if attacker_effective_attack > 0:
        variance = random.uniform(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
        graze = GRAZE_MULTIPLIER if random.random() <= GRAZE_CHANCE else 1.0
        attacker_effective_attack = float(f\"{(attacker_effective_attack * variance * graze):.1f}\")
        new_defender_strength = float(f"{(defender_effective_strength - attacker_effective_attack):.1f}")
        print('Defending unit strength is calculated by',defender_effective_strength,'-',attacker_effective_attack,'rounded, which is',new_defender_strength)
        if new_defender_strength < defender_effective_strength:
            if new_defender_strength <= 0:
                print('Defending unit is destroyed!')
            else:
                print('Defending unit survived attack with',new_defender_strength,'strength.')
        else:
            print('Attack did not manage to get trough to defenders base strength.')
else:
    print('Defending unit survived attack with',defending_unit['unit_strength'],'strength.')

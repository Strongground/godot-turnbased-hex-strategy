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

# Experience:
#   0.25  0.5   0.75
# [     |     |     ]
# Untrained
# Regular
# Elite

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
        'name': 'In a really bad state',
        'attack_bonus': -2,
        'base_defense': -1
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
    }
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
        'name': 'Bad morale',
        'attack_bonus': -1,
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
        'name': 'Good knowledge of terrain',
        'attack_bonus': 1,
        'base_defense': 2
    }
}

experience_levels = {
    'untrained': 0.25,
    'regular': 0.5,
    'elite': 0.75
}

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

# Attack Example calculations
#### Setting base values
defending_unit['effective_strength'] = defending_unit['unit_strength'] + (defending_unit['unit_strength'] * (defending_unit['base_defense']/10))
print('Defending unit has strength of',defending_unit['unit_strength'],', effective strength of',defending_unit['effective_strength'],'(',defending_unit['unit_strength'],'+',defending_unit['unit_strength'] * (defending_unit['base_defense']/10),')')
attacking_unit['effective_attack'] = attacking_unit['main_weapon']['attack_strength'] + attacking_unit['main_weapon']['attack_strength'] * (attacking_unit['unit_strength']/10)
print('Attacking unit has effective attack of',attacking_unit['effective_attack'],'(',attacking_unit['main_weapon']['attack_strength'],'+',attacking_unit['main_weapon']['attack_strength'] * (attacking_unit['unit_strength']/10),')')

#### Factoring in Modifiers
if 'modifier' in defending_unit and len(defending_unit['modifier']) > 0:
    print('Defender has modifier: "',defending_unit['modifier']['name'],'" resulting in:',)
    for index in range(1,len(defending_unit['modifier'])):
        print(list(defending_unit['modifier'])[index],':',defending_unit['modifier'] [ list(defending_unit['modifier']) [index] ] )
        defending_unit[list(defending_unit['modifier'])[index]] += defending_unit['modifier'][list(defending_unit['modifier'])[index]]

## Attack bonus
if attacking_unit['attack_bonus'] != 0:
    attacking_unit['effective_attack'] += attacking_unit['attack_bonus']
    print('Attacker has attack modifier of',attacking_unit['attack_bonus'],'resulting in effective attack value change to:',attacking_unit['effective_attack'])

## Armor Piercing ammo & armor effects
if defending_unit['armor'] > 0:
    print('Defender has armor value of',defending_unit['armor'])
    if attacking_unit['main_weapon']['armor_piercing'] <= 0:
        attacking_unit['effective_attack'] = attacking_unit['effective_attack'] * 0.1
        print('Attack is ineffective, will only deal ',attacking_unit['effective_attack'],'damage.')
    elif attacking_unit['main_weapon']['armor_piercing'] >= 0:
        print('Attackers weapons are armor piercing, making the attack extra effective:')
        at_factor = defending_unit['armor'] / attacking_unit['main_weapon']['armor_piercing']
        print('Attack will deal additional damage of',at_factor)
        attacking_unit['effective_attack'] = attacking_unit['effective_attack'] + at_factor

## High Explosive ammo
if defending_unit['armor'] <= 0 and attacking_unit['main_weapon']['explosive'] > 0:
    print('Defender is soft target and attacker has HE weapons.')
    attacking_unit['effective_attack'] = attacking_unit['effective_attack'] * (attacking_unit['main_weapon']['explosive'] * 0.5)
    he_factor = (attacking_unit['effective_attack'] * (attacking_unit['main_weapon']['explosive'] * 0.5)) - attacking_unit['effective_attack']
    print('Attack will deal additional damage of',he_factor)
    attacking_unit['effective_attack'] -= defending_unit['base_defense']

#### Good or bad luck
value_proximity = attacking_unit['effective_attack'] - defending_unit['effective_strength']
max_luck = random.randint(1,3)
luck = round(abs(1/(value_proximity*((max_luck-0.9)/(max_luck*1.8))+1/max_luck)), 2)
print('Luck:',luck)

#### Finally, battling it out
print('Attacker attempts attack with',attacking_unit['effective_attack'],'effective attack, while defender has',defending_unit['effective_strength'],'effective strength.')

# The events show from the perspective of the defender, so "good" means "good for the defender"
random_events = {
    'good': [
        'A sudden gust of stormy wind alters the course of a projectile, altering its angle ever so slightly, leading to a dramatically reduced impact on the target and next to no damage.',
        'The projectile was a dud. It impacts without any effect, besides a few startled soldiers.',
        'A critter flowing into ones eyes is always unpleasant, much more if one is trying to fire at the same time. The shots go way too high, even leaving the battlefield.',
        'A unexpectedly soft spot on the ground leads to a sudden drop of the defending unit, which in turn leads to a missed hit on part of the attacker.'
        'At the end of the day, all soldiers are humans, with a conscience. A few moments of hesitation, a missed shot.',
    ],
    'bad': [
        'Trick shot! While not planned, the shot manages to penetrate perfectly, hitting vital parts of the defending unit.',
        'Having suffered heavy losses, the defending units cohesion is lost and the remaining wounded soldiers give up or flee.',
        'A sudden gust of stormy wind alters the course of a projectile, altering its angle ever so slightly, leading to a dramatically increased effect on the target.',
        'The long extra hours of training have paid off! Every free hour that comrades spent sleeping, gambling or drinking, this lone soldier has used for training. Now the result is a perfect kill shot.'
    ]
}

# Determine if hit or miss, based on experience of unit
if random.random() <= experience_levels[attacking_unit['experience']]:
    print('It\'s a hit!')
    hit = True
else:
    print('Attacking unit misses!')
    hit = False

# Random events influenced by chance
if hit and luck > 0.75:
    if random.random() > 0.5:
        attack_bonus = round(attacking_unit['effective_attack'] * luck,2)
        print(random_events['bad'][random.randint(0, len(random_events['bad'])-1)],'// Attack increased by',attack_bonus,'adding up to effective attack of',attacking_unit['effective_attack'] + attack_bonus)
        attacking_unit['effective_attack'] += attack_bonus
    else:
        print(random_events['good'][random.randint(0, len(random_events['good'])-1)], '// Attack decreased by',round((attacking_unit['effective_attack'] * luck) / attacking_unit['effective_attack'],2))
        attacking_unit['effective_attack'] -= round((attacking_unit['effective_attack'] * luck) / attacking_unit['effective_attack'],2)

if hit and attacking_unit['effective_attack'] > 0:
    defending_unit['unit_strength'] = round(defending_unit['effective_strength'] - attacking_unit['effective_attack'],2)
    if defending_unit['unit_strength'] <= 0:
        print('Boom! Defending unit destroyed!')
    else:
        print('Defending unit survived attack with',defending_unit['unit_strength'],'strength.')
else:
    print('Defending unit survived attack with',defending_unit['unit_strength'],'strength.')

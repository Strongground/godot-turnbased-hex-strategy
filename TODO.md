# TODO and ideas for the project
# Separated into sections for better organization
## General TODOs
- [ ] Implement generic attributes for the existing "entity" class (which parents all units), that can be used for many different things.
    - "Can_Hold_Garrison:Boolean" can be used for buildings, trenches, etc. that can hold a unit inside of them.
    - "Garrison_Modifier:String" the ID of the modifier applied to the units that is garrisoned inside this entity. Garrison differs from cover in that it takes one turn to garrison and that turn is used by the action. Same for ungarrison.
    - "Is_Obstacle:Boolean" determines if other units can move through/over this entity. Can be dynamically switched to have destructable bridges e.g.
    - "Obstacle_Ignores_Terrain:Boolean" If true, this entity will allow units to move through it regardless of terrain. This can be used for things like trenches that allow movement through them even if the terrain is normally impassable.
    - "Is_Destructible:Boolean" determines if this entity can be destroyed by attacks. This can be used for things like buildings that can be destroyed to create new paths, or for destructible cover.
    - "Is_Cover:Boolean" determines if this entity provides cover for units inside of it. This can be used for things like buildings, trenches, etc. that provide cover.
    - "Cover_Modifier:String" the ID of the modifier applied to the units that are in cover inside this entity. This can be used to apply different modifiers for different types of cover, e.g. a building might provide better cover than a trench.
    - "Static:Boolean" This effectively only hides the display of movement points. They still need to be set to 0 for the entity to be immobile.


- [ ] Add a "Gaia" player for entities that are not controlled by any player. This can be used for things like neutral buildings, destructible cover, etc. that are not owned by any player but still need to be represented in the game.
- [ ] UI for selected units or units affected by an action.
    - Modifers should always be visible at a unit, even if only by a tiny marker. Details can be shown in a tooltip or a unit detail window.
    - Selected unit that is about to start an action should have clear visual indicators of movement range, attack range etc.
    - The UI (also the current part showing stats) must be made smaller, less obtrusive, and most importantly: scale with zoom level.  
- [ ] State machine for units - if already implemented - should be extended. Possible states/actions for units should be:
    - Idle
    - Moving
    - Attacking
    - Garrisoning
    - Ungarrisoning
    - Garrisoned
    - Dying
    - Dead
    - Being supplied
    - Supplying
- [ ] Find out how this state machine stuff helps me. :P

- [ ] Experience system is currently static. If a unit is given a certain level, it will keep that level forever. Make it dynamic?
    - Maybe units can gain experience by attacking and being attacked, and lose experience by being repaired or supplied? This would make the game more dynamic and give players more incentive to keep their units alive and in good condition.
    - Maybe allow the scenario creator to control if units can gain experience or not? This would allow for more static scenarios where the player is supposed to use specific units with specific levels, and more dynamic scenarios where the player can level up their units as they play.
    - Also plan for a way to have units gain experience during a scenario but are only able to be levelled up between scenarios in a campaign - like classic PanzerGeneral with core army.

- [ ] Eye Candy: Add particle system for each unit that displays little smoke puffs when they move on certain tiles (where configureable?).
- [ ] Eye Candy: Add a moving cloud shadow effect to the map. This can be done by having a cloud texture that moves across the map, and using a shader to darken the tiles that are under the clouds. This would add some visual interest to the map and make it feel more dynamic.
- [ ] Eye Candy: Add simple weather system that can display sunny, cloudy, rainy and snowy weather. Could be enhanced by shaders in the future. Also may affect gameplay by giving modifiers.
- [ ] Eye Candy: Evaluate particle systems for all the effects instead of spritesheet animations - since they are hard to find in good quality and for free. This would also allow to have things like lingering smoke chimneys for destroyed units etc.
- [ ] Add a entity with attributes "Is_Cover"=true "Cover_Modifier"=1.5 and "Static"=true with a random crater image variation shown for each spawn, after an explosive attack misses or hits a non-cover entity. Add "craters" attribute to weapons.yaml.

- [ ] Prepare for a campaign system. This is a long-term goal. 
    - Scenarios can be linked together in a campaign, and the player's progress through the campaign can be tracked.
    - Make "Player_Has_Core_Army" a possible attribute for a campaign, which allows the player to keep their units and their experience between scenarios.
    - Allow for campaigns to have branching paths, where the player's choices in one scenario can affect which scenario they play next.
    - A scenario must have a briefing screen before it starts, and a debriefing screen after it ends. These screens can be used to provide story and context for the scenario, as well as to show the player's performance and rewards.
    - Briefings must be encoded in a simple way at first, allowing for a picture and text. Maybe allow a soundfile to be played for spoken briefings.

- [ ] Implement a simple save/load system for the game. This can be used to save the player's progress in a campaign, as well as to save the state of a scenario in case the player wants to quit and come back later.

- [ ] Implement a simple AI for the enemy units. This can be used to provide a challenge for the player in single-player scenarios. The AI can be as simple or as complex as desired, but it should at least be able to move and attack with its units.
    - For a simple AI, units can just move towards the nearest player unit and attack if they are in range. For a more complex AI, units can have different behaviors based on their type and the situation, e.g. a tank might try to flank the player's units, while an artillery unit might try to stay back and provide support.
    - The scenario designer should be able to optionally control the AI behavior of enemy units in a scenario. 
    - Maybe also plan for a simple scripting system for scenarios, so that certain events like reinforcements, retreats etc. can be triggered by player actions.
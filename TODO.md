# ToDo & Documentation
## Themes
Since a theme is at its core designed to represent a specific time in human history or a specific theatre of conflict, it is appropriate to think of a theme as an "era". 

Technically speaking, a theme is a folder containing multiple files, with a structure that is imposed by convention.

## Theme Manager
The theme manager is supposed to provide a Class of getters that provide the information inside a `YAML` file, which by design is structured to be easily edited and read by a game designer, for the classes in the game - like "unit" - to consume.

### Theme format
A theme consists of some basic information like "name" and maybe a short "description" or a picture to show in some future implementation of an ingame "theme manager GUI".

But, maybe most important, is the reference to the YAML-files, that contain all theme specific data.

Following is a draft of the contained files inside a themes folder and their contents:

* `config.yaml`
    * name
    * description
    * picture
    * icon
    * units file name
    * weapons file name
    * factions file name
    * modifiers file name
* `units.yaml`
    * example unit 1
        * unit_id
        * display_name
        * description
        * unit_faction
        * graphical_schemes
        * base_defense
        * armored
        * can_traverse
        * movement_points
        * main_weapon
        * main_ammo
    * example unit 2
        * ...
* `weapons.yaml`
    * weapon_id
    * display_name
    * description
    * armor_piercing
    * exclusive_against
    * effect/s (Array?)
    * sound/s (Array?)
    * area_of_effect
* `factions.yaml`
    * faction_id
    * display_name
    * description
* `modifiers.yaml`
    * mod_id
    * display_name
    * description
    * modifiers
        * stat, modifier
        * stat 2, modifier 2
        * ...

### TODO and open questions
* Are maps, campaigns and missions somehow bound to a theme?
    * Maybe only via dependencies (Campaign X, Mission Y depends on Theme Z, you need it to play them)

## Game core mechanics
### Turnbased behaviour
Implement some kind of 'game' class (refactor currently `map.gd` class?) that controls turns and players and so on. Basic idea: The game class keeps track of number of turns and Array of players. A player is a simple object that is bound to a faction and has an ID.

For the first few turns of the game (where 'few' is 'number of players') an Array is populated with the IDs of players. This is used to determine the order of players turns.

The effect of actions is immediatly visible in game. An attack on another unit instantly yields the result. If an attacked unit is destroyed, it will no longer be available for commands for the owning player in his turn. Movement to another tile is irreversible.

#### Fill player rotation
Before each turn, there is a check if `players.count() == player_rotation.count()`. If no, the following happens:

During first turn, the player at `players[turn_counter]` is set to `active=true` and allowed to interact with units on the map where he is `unit.unit_owner`. `player.id` is added to `player_rotation` at index `turn_counter`. After the player ends the turn, the player is set to `active=false`, `turn_counter` is incremented and the player at `players[turn_counter]` is set to `active=true`, the loop continues.

#### Player rotation full
If the check is no longer true because all players have been added to the `player_rotation` Array, the following happens:

In an infinite loop (`while true`), enter a `while player.active` loop `for player in players[player_rotation]` where he can interact with units on the map with `unit.unit_owner == player.id`.
Each pass from one player to the next increments the `turn_counter`.


## Line Of Sight / Fog Of War
Oh boy this is a whole other story.
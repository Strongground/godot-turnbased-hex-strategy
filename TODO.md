# ToDo & Documentation

## ToDo

[x] Implement turnbased game loop as described further below
[x] Fix that a unit can only be moved once (bug?)
[x] Figure out how to use tool scripts to load all units from the theme when a mission is opened and update units in editor according to its attributes
[ ] Implement some kind of UI lock state, where any action that is uninterruptible should lock any input from player until completion.
Camera movement should be independent of this (or maybe just automatic camera movement?)
[ ] Implement range finder method from red blob games blog to determine firing range, movement range etc. of entities.
[ ] Add animations to the attack-mechanic.
[ ] Make attacks reduce movement points and ammo of attacker.
[ ] Implement effect on attacked unit
[ ] Show useful information in GUI at all times.
[ ] Fix or re-implement useful popup to show information (About units, tiles, ...)
[ ] Implement attributes and logic to allow units to supply other units with ammo and fuel.
[ ] Implement static units that can be walked onto (trenches, bridges) and that can have modifiers affect units inside/on them

## Themes
Since a theme is at its core designed to represent a specific time in human history or a specific theatre of conflict, it is appropriate to think of a theme as an "era". 

Technically speaking, a theme is a folder containing multiple files, with a structure that is imposed by convention.

## Theme Manager
The theme manager is supposed to provide a Class of getters that provide the information inside a `XML` which is created out of a `YAML` file - which by design is structured to be easily edited and read, e.g. by a level designer - for the classes in the game, like "unit", to consume.

### Theme format
A theme consists of some basic information like "name" and maybe a short "description", "author" or a picture to show in some future implementation of an ingame "theme manager GUI".

But, maybe most important, is the reference to the YAML-files, that contain all theme specific data.

Following is a draft of the contained files inside a themes folder and their contents:

* `config.yaml`
    * name
    * description
    * picture
    * icon
    * data_files
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
        * unit_sprites
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
    * attack_strength
    * armor_piercing
    * attacks_units
    * area_of_effect
    * range
    * effect
        * spritesheet_1
        * (spritesheet_2)
        * ...
    * sound
        * sound_1
        * (sound 2)
        * ...
* `factions.yaml`
    * faction_id
    * display_name
    * description
* `modifiers.yaml`
    * mod_id
    * display_name
    * description
    * duration
    * modifiers
        * stat_1, modifier_1
        * (stat_2, modifier_2)
        * ...
* `graphics/`
    * `units/`
        `unit_id1-0.png` // Corresponds to unit with same id described in `units.yaml`, has only one direction
        `unit_id2-0.png` // This unit has only full 6 directions support
        `unit_id2-1.png`
        `unit_id2-2.png`
        `unit_id2-3.png`
        `unit_id2-4.png`
        `unit_id2-5.png`

### TODO and open questions
* Are maps, campaigns and missions somehow bound to a theme?
    * Maybe only via dependencies (Campaign X, Mission Y depends on Theme Z, you need it to play them)

## Game core mechanics
### Turnbased behaviour
[x] Implement some kind of 'game' class (refactor current `map.gd` class?) that controls turns and players and so on. Basic idea: The game class keeps track of number of turns and Array of players. A player is a simple object that is bound to a faction and has an ID. Units in the game are "owned" by a player who exlusively can fully interact with them (e.g. issue move orders, attack orders etc.)

In the first turn of the game, an Array is populated with the IDs of players. This is used to determine the order of players turns.

The effect of actions is immedietly visible in game. An attack on another unit instantly yields the result. If an attacked unit is destroyed, it will no longer be available for commands for the owning player in his turn. However a unit with higher "initiative" value than the attacker will be able to shoot first, when attacked. Movement to another tile is irreversible.

##### Ideas for the game loop
UI has a button "end turn", which sends a signal to trigger a method `end_turn()`. 
This method then does the turn processing - set current player inactive, set next player active and so on.
This method is called `advance_turn()`. It can also be called if a turn change is desirable outside the regular "User ends turn"-pattern.

The input-handler compares ID of `active_player` with the clicked units `unit_owner` attribute before acting on the supposed action of the player, e.g. moving, attack etc.

## Line Of Sight / Fog Of War
An Array of visibility information must be kept somewhere. For each tile on the map, there must be a value for each player
if the tile and its contents are visible. This central array is then updated according to unit movement.
Maybe save this information in global "tile_list" for each tile so it is easily accessible.

## Workflow of scenario editing
a) User creates a new scene for the scenario.
b) It must contain a node instance of map-class, allowing for attribtues like 'map image', 'description', 'name' etc. to be set.
c) A toolscript _once_ creates associated nodes in hierarchy under the map node (tilemap, camera-boundary, etc.), which are then customized by the User (sizing and positioning of the camera-boundary node, painting of the tilemap, etc.)
d) The map node has a attribute 'theme', which is filled with the name of the theme to be used. (Make this easier somehow? Detect all themes and offer selection?)
e) A tool script will then trigger the parsing of the theme's files and populate lists of the contained entities (e.g. units).
f) Entities are placed
    i) For unit-entities, one of the theme-contained unit-types can be selected via `unit_id`-attribute from a dropdown containing all available `unit_id`s from the theme. 
    ii) A tool script is triggered by the selection and updates the entity (appearance, orientation etc.)
g) The map node has a attribute 'player_number'.
    i) This number serves as iterator count for a tool script to create attributes for each supposed player.
    ii) Attributes created for each player are 'name', 'faction' (gotten from theme), etc.
h) Map node attributes like 'name', 'author', 'image' etc. are used in a future implementation of a theme-change-UI.

## Workflow of selecting themes / scenarios depending on them ingame (far off)
*Specifics of the UI will not be discussed as this is still ages away.*
The User can select a scenario. A scenario (a.k.a map) has a dependency for a specific theme.
So actually a theme is never loaded in the main menu, only in a scenario. And thus can't be selected.
But maybe installed/deinstalled? Central repo?


(how trigger any method on attribute change inside editor? This was answered somewhere already...)
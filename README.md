# Turn Based Hexagonal Strategy Game
###### Title may change later

![Screenshot showing very early stage of the game, yet already somewhat playable](https://github.com/Strongground/godot-turnbased-hex-strategy/blob/master/screen.jpg)

## Made with Godot
This is my first attempt at a compelete Godot game and also the fulfillment of one of my dreams - a hex-based turn-based strategy game/engine that is versatile enough to represent any setting/period with ease.

### Ancestors
I drew a big heap of inspiration from classics like 'Nectaris', 'Battle Isle', 'Historyline' and last but not least the lovely 'Panzer General' series.

### What will it be like?
I have a vision which, in many aspects, resembles 'Panzer General II' (called 'Panzer General 3D' in Germany for bizarre marketing reasons, but it's still PGII!). 

So you will have a underlying map graphic, a hexagonal overlay where terrain will be marked. This means a hexagonal tile can be of a terrain type ('road', 'hills', 'village') and can possibly have other traits, like being a tile that can be owned by a faction or allow the placement of reinforcements and so on.

There can be x factions per session (so not only 1v1), who each can have x units on the map and may have different goals, types of units, abilities. 

Then of course there are units, static ones, moveable, sea, ground and flying ones. Every given unit is owned by one faction. They can attack each other, based on the type of the units (infantry won't be able to attack a battleship, artillery units can't attack bombers etc.). 

Each unit can have various stats that represent physical and immaterial conditions of the unit like ammunition, fuel, manpower, experience, morale etc. These influence and/or determine various actions like combat outcome, movement speed, etc.

There may also be temporary stats, so a unit attacked from three sides may gain a 'encircled' trait, which could lower morale and fighting capabilities. But then again, maybe it also strengthens fighting power because the encircled unit has some combat experience already and feels it fights for their life? Random things like that also play a role.

I also want to incorporate random things that always bugged me in some games. Here is a incomplete ad-hoc list of some:
- Creating Fortifications  
At least for some units (think worker units in Civilization creating fortifications). So if you have a couple infantry units sitting idle and await the enemy attack, why not let them dig trenches? You could always let units "entrench" in some games, but the entrenchments where seemingly abandoned as soon as the unit moved again. Also imagine a roman legion moving into an area (game time-scale of several weeks per turn given) and create a proper roman outpost with towers (giving better sight) and bridges to cross rivers. Maybe even creating roads. How cool would that be?
- Civilians  
Okay, individuals would not be visible at the scale of most wargames. But civilian ships? Treks of refugees or neutral third party entities like NGO/aid organizations? Also given the area of effect-nature of modern weapons, this would add a new dimension of 'follow rules of engagement and avoid civilian casualties' to a game.
- Diverse goals  
In most games, even the more modern ones, it almost always boils down to 'Race to that victory marker in under 12 turns to be glorious winner'. Of course this will be a important thing to do in many missions, but I think holding control of regions of the map with flexible conditions like 'percentage of own units bigger than enemy units' or other more diverse goals could add so much spice to the game. So I will try to implement these.
- Destruction of Terrain  
The destructive force of artillery or prolonged battle to any area can be witnessed by watching historical photographs from World War One, west front.

### So, why another PanzerGeneral clone?
While projects like 'OpenGeneral' do exist, and modern niche games like 'Panzer Corps' are really well done and fun to play, I want this to be MY game.

I want to set the rules, I want it to be what I imagine is fun. So adding a Cold War era? No problem. Shifting the game towards 500 B.C roman army campaign? Easy: swap maps and add new units, animations, sounds and maybe a couple special rules.

So maybe this will really appeal to nobody except me, but that's worth it. :)

### Learning
Also this project, like all my projects, has the main goal of advancing my skills in various areas, be it sound design, project management, OOP etc. So even if it never reaches playability, I still will have learned a lot so far.

### Contribute
Even if it may not sound like it, I welcome any help you want to give me. Eager to playtest and give me feedback? Well, if there is a runnable branch, feel free to check it out and tell me how it went!
I welcome any comments about balance, style, game mechanics etc.

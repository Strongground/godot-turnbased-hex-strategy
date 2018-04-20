extends Node2D

# player class
# This serves as anchor for the actual player, handling a subset of units
# on a given map. A player is always associated with one faction. 

# Basic members
var active = false
var faction = null
var is_human = true
var id = 0

func _ready():
    pass

func is_active():
    return self.active

func set_active(active):
    self.active = active
extends Node
# Define global definitions of often used statics

# Return Dict of all colors with named indexes
# @return Dictionary
static func getColors():
    var colors = {
        'red':   [204,0,0],
		'white': [255,255,255],
		'black': [0,0,0]
    }
    return colors

# Get Array with RGB values by common color name (i.e. 'white' returns [255,255,255])
# @return Array
static func getColor(color_name):
	var colors = getColors()
	if colors.has(color_name):
		return colors[color_name]
	else:
		# if color not in dict, return pink as easy-to-notice fallback
		return [255,192,203]

# Return true if color exists in color dictionary. Convienience method to avoid messy implementations to avoid NPEs all over.
# @return Boolean
static func hasColor(color_name):
	var colors = getColors()
	for color in colors:
		if color_name == color:
			return true
	return false
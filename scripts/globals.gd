extends Node
# Define global definitions of often used statics

# Return Dict of all colors with named indexes
# @return Dictionary
static func getColors():
    var colors = {
        'red':    [204,0,0],
		'white':  [255,255,255],
		'black':  [0,0,0],
		'yellow': [0,255,255],
		'green':  [0,255,0],
		'blue':	  [0,0,255]
    }
    return colors

# Return array with RGB values by common color name (i.e. 'white' returns [255,255,255])
# @return Array
static func getColorArray(color_name):
	var colors = getColors()
	if colors.has(color_name):
		return colors[color_name]
	else:
		# if color not in dict, return pink as easy-to-notice fallback
		return [255,192,203]

# Return Color() by common color name (i.e. 'red' returns Color(204,0,0,1))
# Allows to specifiy opacity. If ommitted or invalid, '1' is assumed
# @return Color
static func getColor(color_name, opacity=1):
	if opacity > 1 || opacity < 0:
		opacity = 1
	var colors = getColors()
	if colors.has(color_name):
		var retrieved_color = colors[color_name]
		retrieved_color.append(opacity)
		return Color(retrieved_color[0], retrieved_color[1], retrieved_color[2], retrieved_color[3])
	else:
		# if color not in dict, return pink as easy-to-notice fallback
		return Color(255,192,203,1)
extends Node

func _get_palette(name):
	var THE_COLORS = []
	
	var image: Image
	image = load("res://palettes/%s.png" % name).get_image()
	
	for x in image.get_width():
		for y in image.get_height():
			var color = image.get_pixel(x, y)
			if (not THE_COLORS.has(color)): THE_COLORS.append(color)
	
	THE_COLORS.sort_custom(func(a, b): return (a.get_luminance() < b.get_luminance()))
	
	return THE_COLORS

func _color_dist_hsv(col1: Color, col2: Color):
	var h_dist = abs(col1.h - col2.h)
	var s_dist = abs(col1.s - col2.s)
	var v_dist = abs(col1.v - col2.v)
	
	return (float(h_dist + s_dist + v_dist) / 3.0)

func _color_dist_rgb(col1: Color, col2: Color):
	var r_dist = abs(col1.r - col2.r)
	var g_dist = abs(col1.g - col2.g)
	var b_dist = abs(col1.b - col2.b)
	
	return (float(r_dist + g_dist + b_dist) / 3.0)

func _color_dist_total(col1: Color, col2: Color):
	var rgb_dist = _color_dist_rgb(col1, col2)
	var hsv_dist = _color_dist_hsv(col1, col2)
	
	return (float(rgb_dist + hsv_dist) / 2.0)

func palettify(image: Image, palette = "blu"):
	if (palette is String):
		palette = _get_palette(palette)
	var min_lum = 1.0
	var max_lum = 0.0
	
	# Phase 2
	for x in image.get_width():
		for y in image.get_height():
			var pixel = image.get_pixel(x, y)
			var this_lum = pixel.get_luminance()
			
			if (this_lum < min_lum):
				min_lum = this_lum
			
			if (this_lum > max_lum):
				max_lum = this_lum
	
	# Phase 1
	for x in image.get_width():
		for y in image.get_height():
			var pixel = image.get_pixel(x, y)
			var this_lum = pixel.get_luminance()
			var mapped_lum = remap(this_lum, min_lum, max_lum, 0.0, 1.0)
			
			var ind = round(mapped_lum / (1.0/float(palette.size() - 1)))
			if (ind == NAN): ind = 0
			var new_color = palette[ind]
			
			#var new_color: Color
			#var low_dist = INF
			#for entry in blubot_palette:
				#var this_dist = _color_dist_total(entry, pixel)
				#if (this_dist < low_dist):
					#low_dist = this_dist
					#new_color = entry
			
			new_color.a = pixel.a
			
			image.set_pixel(x, y, new_color)
	
	return image

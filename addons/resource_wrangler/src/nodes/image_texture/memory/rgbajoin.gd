@tool
@icon("../icons/channel_join_nodeicon.cleaned_icon.svg")
class_name rwtexJoinRGBA
extends rwMemoryImageTexture

## Join RGBA channels
##
## Incoming images will have their colors interpreted as a
## luminance (ranging from 0.0 to 1.0).
## [br][br]
## Note, the image size output is determined like this:[br]
## R → G → B → A (as connected.)

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Join Channels", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}

## Source texture to reconstruct as Red
@export var R : Resource

## Source texture to reconstruct as Green
@export var G : Resource

## Source texture to reconstruct as Blue
@export var B : Resource

## Source texture to reconstruct as Alpha
@export var A : Resource

func create_image()->Image:
	var in_r:Image
	var in_g:Image
	var in_b:Image
	var in_a:Image
	var sizer:Image
	if A:
		in_a = await get_image__from_input_port_resource(A)
		if in_a : sizer = in_a
	if B:
		in_b = await get_image__from_input_port_resource(B)
		if in_b : sizer = in_b
	if G:
		in_g = await get_image__from_input_port_resource(G)
		if in_g: sizer = in_g
	if R:
		in_r = await get_image__from_input_port_resource(R)
		if in_r : sizer = in_r

	if in_r or in_g or in_b or in_a:
		var col:Color
		var _lum:float
		var mutate : Image = sizer
		mutate.convert(Image.FORMAT_RGBA8)
		var _red_size = size(sizer)
		for y in range(_red_size.y):
			for x in range(_red_size.x):
				col = Color(0,0,0,1)
				if in_r:
					_lum = in_r.get_pixel(x,y).get_luminance()
					col = Color(_lum,col.g, col.b, col.a)
				if in_g:
					_lum = in_g.get_pixel(x,y).get_luminance()
					col = Color(col.r,_lum, col.b, col.a)
				if in_b:
					_lum = in_b.get_pixel(x,y).get_luminance()
					col = Color(col.r, col.g, _lum, col.a)
				if in_a:
					_lum = in_a.get_pixel(x,y).get_luminance()
					col = Color(col.r, col.g, col.b, _lum)

				mutate.set_pixel(x,y,col)

		return mutate
	return null

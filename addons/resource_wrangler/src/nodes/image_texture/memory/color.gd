@tool
@icon("../icons/color_nodeicon.cleaned_icon.svg")
class_name rwtexColor
extends rwMemoryImageTexture

## Color
##
## A 1x1 coloured pixel. (Useful for imitating float values.)

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Color",
	&"category" : &"Image Nodes"
	}

var out : Image = Image.create(1,1,false,Image.FORMAT_RGBA8)

## The color.
@export var color : Color
@export_range(1,4096) var width : int = 1:
	set(w):
		width = w
		out.resize(width,height)
@export_range(1,4096) var height : int = 1:
	set(h):
		height = h
		out.resize(width,height)

func create_image()->Image:
	out.fill(color)
	self.set_image(out)
	return out

## Always returns color, no matter the x,y.
func get_pixel(x,y)->Color:
	return color

## Always returns color, no matter the v2.
func get_pixelv(v2:Vector2i)->Color:
	return color

@tool
@icon("../icons/bcs_nodeicon.cleaned_icon.svg")
class_name rwtexBCS
extends rwMemoryImageTexture

## Brightness, Contrast, Saturation
##
## Control the Brightness, Contrast and Saturation of the input. You can also invert the image.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"BCS", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}

## The texture to effect.
@export var texture : Resource

## Controls the brightness.
@export var brightness:float = 1.0

## Controls the contrast.
@export var contrast:float = 1.0

## Controls the saturation.
@export var saturation:float = 1.0

## Quick way to "invert" by flipping the sign on contrast.
@export var invert:bool

func create_image()->Image:
	if texture:
		#print("BCS ", self)
		var out_img:Image = await get_image__from_input_port_resource(texture)
		if out_img:
			# make a copy if the export property *before* changing it - coz that causes
			# changed signals to happen and all hell breaks loose.
			var _c = contrast
			if invert: _c *= -1
			out_img.adjust_bcs(brightness, _c, saturation)
			return out_img
	return null

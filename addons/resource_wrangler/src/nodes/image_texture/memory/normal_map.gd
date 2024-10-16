@tool
@icon("../icons/normalmap_nodeicon.cleaned_icon.svg")
class_name rwtexNormalMap
extends rwMemoryImageTexture

## Bump to Normal Map [rwMemoryImageTexture]
##
## Converts a bump map to a normal map. A bump map provides a height offset per-pixel, while a normal map provides a normal direction per pixel.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Normal Map", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}




## The bump/height source texture.
@export var texture : Resource

## How much to scale the effect by.
@export var bump_scale:float

func create_image()->Image:
	if texture:
		var out_img:Image = await get_image__from_input_port_resource(texture)
		if out_img:
			out_img.bump_map_to_normal_map(bump_scale)
			return out_img
	return null

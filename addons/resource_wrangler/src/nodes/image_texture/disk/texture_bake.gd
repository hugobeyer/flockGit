@tool
@icon("../icons/texsave_nodeicon.cleaned_icon.svg")
class_name rwtexBake
extends rwImageTexture

## Saves ("Bakes") the TextureImage
##
## A [rwImageTexture] that accepts a Texture (of some kind) and [b]saves it
## as a binary resource file[/b]. It can also generate mipmaps, in two ways.


## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Bake Texture", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	&"save_as_res_file" : true # will use .res (.tres is the default)
	}

## The texture coming in.
@export var texture : Resource

## Toggle the normal map arg.
@export var make_mipmaps:bool = false

## Toggle the normal map arg.
@export var make_normalized_mipmaps:bool = false

func create_image()->Image:
	if texture:
		var out_img:Image = await _rwImgTexture.get_image__from_input_port_resource(texture)
		if out_img:
			#print("  Save Texture has an out_img to work on")
			if make_mipmaps:
				out_img.generate_mipmaps(make_normalized_mipmaps)
			return out_img
	return null

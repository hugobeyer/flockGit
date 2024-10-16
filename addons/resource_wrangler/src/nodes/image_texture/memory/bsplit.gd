@tool
@icon("../icons/channel_split_nodeicon.cleaned_icon.svg")
class_name rwtexSplitBlue
extends rwMemoryImageTexture

## Blue channel out
##
## Splits the blue channel out.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Blue Split", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}

## The ImageTexture affected.
@export var texture : Resource

func create_image()->Image:
	if texture:
		var out_img:Image = await get_image__from_input_port_resource(texture)
		if out_img:
			return extract_channel(out_img, &"B")
	return null

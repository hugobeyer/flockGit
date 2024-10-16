@tool
@icon("../icons/channel_split_nodeicon.cleaned_icon.svg")
class_name rwtexSplitGreen
extends rwMemoryImageTexture

## Green channel out
##
## Splits the green channel out.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Green Split",
	&"category" : &"Image Nodes"
	}

## The ImageTexture affected.
@export var texture : Resource

func create_image()->Image:
	if texture:
		var out_img:Image = await get_image__from_input_port_resource(texture)
		if out_img:
			return extract_channel(out_img, &"G")
	return null

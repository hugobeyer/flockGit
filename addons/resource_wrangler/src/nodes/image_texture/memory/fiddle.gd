@tool
@icon("../icons/fiddle_nodeicon.cleaned_icon.svg")
class_name rwtexFiddle
extends rwMemoryImageTexture

## Fiddle with Images
##
## Invert, flip and more.
##
## @tutorial:file://test_link_do_not_try_doc.html


## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Fiddle", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}




## The ImageTexture affected.
@export var texture : Resource
## Invert the image.
@export var invert : bool
## Rotates 90 degrees up to four times.
@export_range(0,4) var rotate_90 : int
## Flip X
@export var flip_x : bool
## Flip Y
@export var flip_y : bool
## Convert a normal map to XY [method Image.normal_map_to_xy]
@export var normal_to_xy : bool
## Fix odd alpha edges [method Image.fix_alpha_edges]
@export var fix_alpha_edges : bool
## Go see [method Image.premultiply_alpha]
@export var premultiply_alpha : bool
## Shrink down to the nearest factor of 2 [method Image.shrink_x2]
@export var shrink_x2 : bool

var _rot90
func create_image()->Image:
	if texture:
		#print("Fiddle ",self)
		#print("Fiddle.texture= ",self.texture)
		var out_img:Image = await get_image__from_input_port_resource(texture)
		#print("Fiddle back with:", out_img)
		if out_img:
			if invert:
				out_img.adjust_bcs(1, -1, 1)

			if normal_to_xy:
				out_img.normal_map_to_xy()

			if premultiply_alpha:
				out_img.premultiply_alpha()

			if fix_alpha_edges:
				out_img.fix_alpha_edges()

			if shrink_x2:
				out_img.shrink_x2()

			if rotate_90 > 0:
				for rot in range(0,rotate_90):
					out_img.rotate_90(CLOCKWISE)

			if flip_x:
				out_img.flip_x()

			if flip_y:
				out_img.flip_y()

		#var _th = EditorInterface.get_editor_theme()
		#print(_th.get_icon_type_list())
		#var _icon = _th.get_icon(&"rwtexFiddle", &"rwtexFiddle")
		#print(_icon)
		##print("Fiddle returning img of size:", size(out_img))
		#out_img = _icon.get_image()
		return out_img
	return null

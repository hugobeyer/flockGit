@tool
@icon("../icons/shadermaterialcapture_nodeicon.cleaned_icon.svg")
class_name rwtexShaderMaterialCapture
extends rwMemoryImageTexture

## ShaderMaterial Capture
##
## If you connect a [ShaderMaterial] it will fill a rectangle who's size you
## control.
## [br]
## The output is an [ImageTexture] that you can further develop.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Capture 2D Shader", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}

@export_range(1, 4096) var width:int = 32
@export_range(1, 4096) var height:int = 32

## The shader material to (attempt) to capture
@export var material : Material


func create_image()->Image:
	if material:
		# We will use RenderingServer because it lets us make a
		# viewport without needing to use nodes and add_child to the tree
		# which I don't really have access to here.
		var _canvas = RenderingServer.canvas_create()
		var _canvas_item:RID = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(_canvas_item, _canvas)

		var _vp_rid = RenderingServer.viewport_create()
		RenderingServer.viewport_set_size(_vp_rid,width,height)
		RenderingServer.viewport_set_update_mode(_vp_rid, RenderingServer.VIEWPORT_UPDATE_ALWAYS)
		RenderingServer.viewport_attach_canvas(_vp_rid, _canvas)
		RenderingServer.viewport_set_transparent_background(_vp_rid,true)
		RenderingServer.viewport_set_disable_3d(_vp_rid, false)
		RenderingServer.viewport_set_disable_2d(_vp_rid, false)
		RenderingServer.viewport_set_active(_vp_rid, true) # Thanks @efi@chitter.xyz  !!!

		## only needed the material.get_rid() in the end. No shader need be made here.
		RenderingServer.canvas_item_set_material(_canvas_item,material.get_rid())
		## the rect is magenta to show when the material failed in some way.
		## unless the shader is magenta :)
		RenderingServer.canvas_item_add_rect(_canvas_item, Rect2i(0,0,width,height),Color.MAGENTA)

		await RenderingServer.frame_post_draw

		var _tex_rid = RenderingServer.viewport_get_texture(_vp_rid)
		var _img:Image = RenderingServer.texture_2d_get(_tex_rid)

		# clean up all create_* rids
		RenderingServer.free_rid(_canvas_item)
		RenderingServer.free_rid(_canvas)
		RenderingServer.free_rid(_vp_rid)

		return _img

	return null

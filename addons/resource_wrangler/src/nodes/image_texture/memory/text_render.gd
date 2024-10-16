@tool
@icon("../icons/textrender_nodeicon.cleaned_icon.svg")
class_name rwtexTextRender
extends rwMemoryImageTexture

## Text Render Node
##
## Will render the string using the supplied [param text_settings].
## If none are provided, defaults are used.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Text Render",
	&"category" : &"Image Nodes"
	}

## The text settings resource.
@export var text_settings : rwtexTextSettings

func create_image()->Image:
	#print("  TextRender")
	if not text_settings: return null
	var _ls : rwtexTextSettings = text_settings

	if _ls.text:
		var _lines = _ls.text.count("\n") + 1
		var _string_size:Vector2 = _ls.font.get_multiline_string_size(
			_ls.text,
			0, #alignment: HorizontalAlignment = 0,
			-1, #width: float = -1,
			_ls.font_size, #font_size: int = 16,
			_lines, #max_lines: int = -1
		)
			#3, #brk_flags: BitField[TextServer.LineBreakFlag] = 3,
			#3, #justification_flags: BitField[TextServer.JustificationFlag] = 3,
			#0, #direction: TextServer.Direction = 0,
			#0, #orientation: TextServer.Orientation = 0
		#)
		if _string_size < Vector2.ONE: _string_size = Vector2.ONE

		# We will use RenderingServer because it lets us make a
		# viewport without needing to use nodes and add_child to the tree
		# which I don't really have access to here.
		var _canvas = RenderingServer.canvas_create()
		var _canvas_item = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(_canvas_item, _canvas)

		var _vp_rid = RenderingServer.viewport_create()
		RenderingServer.viewport_set_size(_vp_rid,_string_size.x,_string_size.y)
		RenderingServer.viewport_set_update_mode(_vp_rid, RenderingServer.VIEWPORT_UPDATE_ALWAYS)
		RenderingServer.viewport_attach_canvas(_vp_rid, _canvas)
		RenderingServer.viewport_set_transparent_background(_vp_rid,true)
		RenderingServer.viewport_set_active(_vp_rid, true) # Thanks @efi@chitter.xyz  !!!

		var _ascent = _ls.font.get_ascent(_ls.font_size)
		_ascent += _ls.adjust_up_down

		if not _ls.no_fill:
			_ls.font.draw_multiline_string(
				_canvas_item,
				Vector2(0, _ascent),
				_ls.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				_ls.font_size,
				_lines,
				_ls.font_color
			)
		if _ls.outline_size > 0.0:
			_ls.font.draw_multiline_string_outline(
				_canvas_item,
				Vector2(0, _ascent),
				_ls.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				_ls.font_size,
				_lines,
				_ls.outline_size,
				_ls.outline_color
			)
		#print(" BEFORE RenderingServer.frame_post_draw")
		await RenderingServer.frame_post_draw
		#print(" AFTER RenderingServer.frame_post_draw")

		var _tex_rid = RenderingServer.viewport_get_texture(_vp_rid)
		var _img:Image = RenderingServer.texture_2d_get(_tex_rid)
		# clean up all create_* rids
		RenderingServer.free_rid(_canvas_item)
		RenderingServer.free_rid(_canvas)
		RenderingServer.free_rid(_vp_rid)

		#print("  font size reported as:", _ls.font_size)
		#print("  _img size reported as:", size(_img))

		return _img
	return null

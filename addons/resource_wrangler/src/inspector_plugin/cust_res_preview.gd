extends EditorInspectorPlugin

## Custom Resource (Images only) Preview
##
## Found a lot of info here:
## https://github.com/godotengine/godot/blob/f8a2a9193662b2e8c1d04d65e647399dee94f31e/editor/plugins/texture_editor_plugin.cpp#L125


#const NSrw = preload("../../ns.gd")


func _can_handle(object) -> bool:
	return object is Resource

func _parse_begin(object: Object) -> void:
	if object is Image or object is Texture: return
	if object:
		# Only looking for an image. Other kinds of nodes like meshes won't
		# get a preview for now.
		var _img = object.get(&"image")
		if _img:
			# Have to instance this every time else crash.
			var _scene = NSrw.InsPscene.instantiate()
			var _tex = ImageTexture.create_from_image(_img)
			var _check:TextureRect = _scene.get_child(0)
			var _tr:TextureRect = _scene.get_child(1)
			var _lab:Label = _scene.get_child(2)

			_check.stretch_mode = TextureRect.STRETCH_TILE
			_check.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			_check.custom_minimum_size = Vector2(0,256) * \
				EditorInterface.get_editor_scale()
			var _th = EditorInterface.get_editor_theme()
			_check.texture = _th.get_icon(&"Checkerboard", &"EditorIcons")

			_tr.custom_minimum_size = Vector2(0,256) * \
				EditorInterface.get_editor_scale()
			_tr.texture = _tex

			_lab.add_theme_color_override(&"font_color", Color.WHITE)
			_lab.add_theme_font_size_override(&"font_size",
					14 * EditorInterface.get_editor_scale())

			# I can't get the string of the format. Tried:
			#  Image.Format.keys()[0]] and _tex.get_format()
			_lab.text = "%sx%s" % [_tex.get_width(), _tex.get_height()]
			add_custom_control(_scene)

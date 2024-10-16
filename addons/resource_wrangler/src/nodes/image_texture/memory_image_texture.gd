@tool
class_name rwMemoryImageTexture
extends Resource

## Memory Image Texture [Resource]
##
## Forms a base for other non-storage image resource nodes.
## It's not an ImageTexture, it [b]won't save the image[/b], but
## it's pretending to be one.
## [br]
## Images are calculated each time the nodes are loaded or changed.


## Emit with [param msg] and [param style] to display feedback to the user.
signal feedback(msg, style)

## Emit to force the last connected noodle to disconnect.
signal force_disconnect

enum {NOTHING = 0, CONVERT = 1, CLEAR_MIPMAPS = 2}

var bad:Image = preload("../../../assets/resource_no_image.small.svg").get_image()
var image : Image

## Resource Wranger looks for this property in order to draw a preview.
var preview_this: Image = bad:
	get:
		if self.image:
			var _previmg:Image
			_previmg = self.image.duplicate()
			return _previmg
		return bad

## Coroutine.
## Override to do the work.
func create_image()->Image: return null

## coroutine
## Calls create_image if no .image is cached.
func process():
	var final_img:Image = await create_image()
	set_image(final_img)
	return true

## coroutine
## Only called in here, not from rwnode.
## Reaches for the .image cached. Else calls process (a coroutine) which
## draws the image. That process reaches for input resources and walks
## down the tree until there is an image or something built-in like
## a texture2D which emits changed. Then it bubbles back up.
func get_image()->Image:
	var _img:Image = self.image
	if not self.image:
		await process()
		_img = self.image
	return _img


## I'm pretending to be an ImageTexture, hence:
func set_image(_image:Image):
	self.image = _image


## Coroutine
## Gets the image from the resource port and returns a duplicate.
## Mipmaps are cleared, to keep the memory use low.[br]
## NOTE: This func is used when self must pull images from the
## various Resource export vars in it.
## iow it has nothing to do with rwnode - it's all about getting my
## data and using it to make an image and thence the preview.
func get_image__from_input_port_resource(working_resource:Resource, viewport_rid=null) -> Image:
	var _img : Image = null

	# we have override_base_port_types to control what comes into this 'node'
	# so, I won't repeat all that logic

	if working_resource is rwMemoryImageTexture:
		_img = await working_resource.get_image()

	elif working_resource is NoiseTexture2D or working_resource is Noise:
		if working_resource is Noise:
			var _noisetex : NoiseTexture2D = NoiseTexture2D.new()
			_noisetex.noise = working_resource
			await _noisetex.changed
			_img =_noisetex.get_image()

		elif working_resource is NoiseTexture2D:
			var _texture:NoiseTexture2D = working_resource.duplicate()
			await _texture.changed
			_img = _texture.get_image()

	elif working_resource is ImageTexture:
		if not working_resource.get_image():
			await working_resource.changed
		_img = working_resource.get_image()

	## Texture2D covers GradientTextures too
	elif working_resource is Texture2D:
		if not working_resource.get(&"gradient"):
			_img = null
		else:
			if not working_resource.get_image():
				await working_resource.changed
			_img = working_resource.get_image()

	elif working_resource is Image:
		_img = working_resource
		if not _img:
			await working_resource.changed
		_img = working_resource.get_image()

	else:
		feedback.emit("%s is not supported." % working_resource, &"NORMAL")
		force_disconnect.emit()
		return null

	if _img == null:
		return null

	_img = _img.duplicate()
	_img.clear_mipmaps()
	return _img


## Make param1 the same size as param2
func crop_from_to(mutate:Image, ro:Image, nodename:StringName)->bool:
	var _sro = size(ro)
	mutate.crop(_sro.x, _sro.y)
	# I swear this happens now and again. No idea why.
	# I eventually plonked this catch in here:
	var sz1 = size(mutate)
	var sz2 = size(ro)
	if sz1 != sz2:
		#print("mutate size:", sz1, " vs ro size:",sz2)
		feedback.emit(
			"Cthulhu Error: Sizes weird after crop in %s node." % nodename,
			&"ERROR")
		return false
	return true

## Quicker way to get an image size
func size(img:Image)->Vector2i:
	return Vector2i(img.get_width(), img.get_height())



func extract_channel(out_img:Image, chan:StringName)->Image:
	var out_col
	var lum:float
	var mutate : Image = out_img.duplicate()
	mutate.convert(Image.FORMAT_L8)
	var out_size = size(out_img)
	for y in range(out_size.y):
		for x in range(out_size.x):
			out_col = out_img.get_pixel(x,y)
			out_col = out_col.srgb_to_linear()
			match chan:
				&"R" :
					lum = Color(out_col.r, out_col.r, out_col.r, 1).get_luminance()
					out_col = Color(lum,0,0)
				&"G" :
					lum = Color(out_col.g, out_col.g, out_col.g, 1).get_luminance()
					out_col = Color(0, lum, 0)
				&"B" :
					lum = Color(out_col.b, out_col.b, out_col.b, 1).get_luminance()
					out_col = Color(0, 0, lum)
				&"A" :
					lum = 1.0 - Color(out_col.a, out_col.a, out_col.a, 0).get_luminance()
					out_col = Color(lum, lum, lum)
			mutate.set_pixel(x,y,out_col)
	return mutate






# Old system for port type override
#func _init() -> void:
	#override_base_port_types = {&"texture":[&"ImageTexture", &"Texture2D", &"rwMemoryImageTexture"]}




### rgba8 is so common, this is handy
#func ensure_rgba8(img:Image):
	#if img.get_format() != Image.FORMAT_RGBA8:
		#img.convert(Image.FORMAT_RGBA8)


#
#func sizes_not_equal(img1,img2,txt)->bool:
	#var sz1 = size(img1)
	#var sz2 = size(img2)
	#if sz1 != sz2:
		#print("img1 size:", sz1, " vs img2 size:",sz2)
		#feedback.emit("Cthulhu Error: %s" % txt, &"ERROR")
		#return true
	#return false

#
### Unused right now...
#func alpha_fill_point_five(
	#out:Image,
	#texture:Texture2D):
	#alpha_fill(out, null, texture, null, false, true)
#
#
### Process an image into black and white
### Well.. alpha 1 or 0 - because that's what some Image
### funcs require.
#func make_mask(out:Image):
	#out.convert(Image.FORMAT_L8)
	#ensure_rgba8(out)
	#var out_col
	#var _out_sz := size(out)
	#print("make mask:", _out_sz)
	#return
#
	#for y in range(_out_sz.y):
		#for x in range(_out_sz.x):
			#out_col = out.get_pixel(x,y)
			#var a = out_col.get_luminance()
			#out_col.a = snappedf(a,1.)
			#out.set_pixel(x, y, out_col)
#
#
#



#
#func advanced_convert_to_image(viewport_rid)->Image:
		#await RenderingServer.frame_post_draw
		#var _tex_rid = RenderingServer.viewport_get_texture(viewport_rid)
		#var _img:Image = RenderingServer.texture_2d_get(_tex_rid)
		#_img.clear_mipmaps()
		##await _img.changed #infinite wait
		#return _img


#
#func convert__and_clearmips(_img:Image,
		#flags := CONVERT | CLEAR_MIPMAPS,
		#format := Image.FORMAT_RGBA8) -> Image:
	#if not _img: return null
	#_img = _img.duplicate()
	#if bool(flags & CONVERT): _img.convert(format)
	#if bool(flags & CLEAR_MIPMAPS): _img.clear_mipmaps()
	#return _img

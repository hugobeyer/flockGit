@tool
@icon("../icons/blend_nodeicon.cleaned_icon.svg")
class_name rwtexBlend
extends rwMemoryImageTexture

## Blend
##
## This is the blend_rect function of the Image class. Honestly, this function is very weird. Check the docs: [method Image.blend_rect_mask]
## [br]
## [param source] The priority image; size overrides others.
## Must have an alpha channel where anything 0.0 will block.[br]
## [param background] Blender onto source. Alpha not used.[br]
## [param mask] Must have alpha channel where 0.0 will block.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Blend", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}

##The priority image; size overrides others. Must have an alpha channel where anything 0.0 will block.
@export var source : Resource

## Blender onto source. Alpha not used.[br]
@export var background : Resource


## Must have alpha channel where 0.0 will block.
@export var mask : Resource


func create_image()->Image:
	if background and source:
		#print("blend await src_img")
		var src_img:Image = await get_image__from_input_port_resource(source)
		#print("blend await bg_img")
		var bg_img:Image = await get_image__from_input_port_resource(background)
		#print("blend done waiting")

		if src_img and bg_img:
			src_img.convert(Image.FORMAT_RGBA8)
			# Make sure things are the same size

			if not crop_from_to(bg_img, src_img, &"Blend"): return null

			if mask:
				var mask_img:Image = await get_image__from_input_port_resource(mask)
				# Make sure things are the same size
				if not crop_from_to(mask_img, src_img, &"Blend"): return null

				var _bg_size := size(bg_img)
				var _src_size := size(src_img)
				#print("size src:", _src_size, " size bg:", _bg_size)
				bg_img.blend_rect_mask(src_img, mask_img, Rect2i(Vector2i.ZERO, _src_size), Vector2i.ZERO)
			else:
				# blend_rect(src: Image, src_rect: Rect2i, dst: Vector2i)
				# Alpha-blends src_rect from src image to this image at coordinates dst, clipped accordingly to both
				# image bounds. This image and src image must have the same format. src_rect with non-positive size is
				# treated as empty.
				var _bg_size := size(bg_img)
				var _src_size := size(src_img)
				#print("size src:", _src_size, " size bg:", _bg_size)
				#src_img.blend_rect(bg_img, Rect2i(Vector2i.ZERO, _bg_size), Vector2i.ZERO)
				bg_img.blend_rect(src_img, Rect2i(Vector2i.ZERO, _src_size), Vector2i.ZERO)
			return bg_img
	return null

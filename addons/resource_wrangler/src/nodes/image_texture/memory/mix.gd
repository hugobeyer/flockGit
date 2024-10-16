@tool
@icon("../icons/mix_nodeicon.cleaned_icon.svg")
class_name rwtexMix
extends rwMemoryImageTexture

## Mix
##
## Allows blending between two Textures by a 'factor', similar to Blender's system.
## [br][br]
## The ouput can connect to any [Texture2D].
## [br][br]
## Keep in mind that texture1's size is imposed on the other two by cropping.
## This means texture2 and fac may not be the size you think they are.
## [br]
## (Fac's colours are interpreted as a value range from 0 to 1)

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Mix",
	&"category" : &"Image Nodes"
	}


## The texture which black reveals
@export var texture1 : Resource

## The texture which white reveals.
@export var texture2 : Resource

## The mixture factor between texture1 and texture2.
@export var fac : Resource

func create_image()->Image:
	if texture1 and texture2:
		var out_img:Image = await get_image__from_input_port_resource(texture1)
		var mix_img:Image = await get_image__from_input_port_resource(texture2)
		if out_img and mix_img:
			out_img.convert(Image.FORMAT_RGBA8)
			mix_img.convert(Image.FORMAT_RGBA8)
			if out_img and mix_img:
				var out_size := size(out_img)
				if not crop_from_to(mix_img, out_img, &"Mix"): return null
				var fac_img:Image
				if fac:
					fac_img = await get_image__from_input_port_resource(fac)
					if not crop_from_to(fac_img, out_img, &"Mix"): return null
				var fac_col
				var out_col
				var mix_col
				for y in range(out_size.y):
					for x in range(out_size.x):
						out_col = out_img.get_pixel(x,y)
						mix_col = mix_img.get_pixel(x,y)
						# when a = 0.0 we see only texture1
						# when a = 1.0 we see only texture2
						# if fac is null, set a to 0.5
						if fac:
							if fac is NoiseTexture2D:
								fac_col = fac_img.get_pixel(x,y)
								out_col.a = fac_col.r
							else:
								fac_col = fac_img.get_pixel(x,y)
								out_col.a = 1.0 - fac_col.get_luminance()
						else:
							out_col.a = 0.5
						out_col = mix_col.blend(out_col)
						out_img.set_pixel(x, y, out_col)
				return out_img

	return null

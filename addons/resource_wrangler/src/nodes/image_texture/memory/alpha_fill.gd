@tool
@icon("../icons/alphafill_nodeicon.cleaned_icon.svg")
class_name rwtexAlphaFill
extends rwMemoryImageTexture

## Fill the Alpha Channel
##
## Use this when an alpha channel is required.
## [br]
## Makes an alpha channel from [param fac], else from [param texture].

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Alpha Fill", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}




## If no [param fac], the alpha will be filled with the luminance of the rgb
## or, if it's a noise texture, the red channel.
@export var texture : Resource

## Will be used for the alpha fill if present.
## By default the alpha will be filled with the luminance of the rgb
## or, if it's a noise texture, the red channel.
@export var fac:Resource

##Will invert the alpha calculation.
@export var invert:bool=false

func create_image()->Image:
	if texture:
		#print("Alpha Fill:", self)
		var out_img:Image = await get_image__from_input_port_resource(texture)#, NOTHING)
		if out_img:
			out_img.convert(Image.FORMAT_RGBA8)
			var _out_sz := size(out_img)

			var fac_img:Image
			if fac:
				fac_img = await get_image__from_input_port_resource(fac)
				if fac_img:
					if not crop_from_to(fac_img, out_img, &"AlphaFill"):
						return null

			if fac_img:
				_alpha_fill(out_img, fac_img, texture, fac, invert)
			return out_img
	return null


## Get some kind of data into the alpha channel.
## I use this in a few other palces
func _alpha_fill(out:Image, facimg:Image,
		texture:Resource, fac:Resource,
		invert:=false,
		point_five:=false):
	var fac_col
	var out_col
	var _out_sz := size(out)
	for y in range(_out_sz.y):
		for x in range(_out_sz.x):
			out_col = out.get_pixel(x,y)
			if fac:
				if fac is NoiseTexture2D:
					fac_col = facimg.get_pixel(x,y)
					out_col.a = fac_col.r
				else:
					fac_col = facimg.get_pixel(x,y)
					out_col.a = fac_col.get_luminance()
			else:
				if point_five:
					out_col.a = 0.5
				else:
					if texture is NoiseTexture2D:
						out_col.a = out_col.r
					else:
						out_col.a = out_col.get_luminance()

			if invert:
				out_col.a = 1.0 - out_col.a
			#if out_col.a > 0.:
			#print(x,y,out_col)
			out.set_pixel(x, y, out_col)

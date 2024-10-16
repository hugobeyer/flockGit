@tool
class_name rwImageTexture
extends ImageTexture

## Image Texture [ImageTexture]
##
## This node will persist the image in [param image] to your disk.
## [br]
## All memory texture nodes [rwMemoryImageTexture] should terminate in
## one of these nodes so that they are saved.

var _rwImgTexture = rwMemoryImageTexture.new()

## Resource Wranger looks for this property in order to draw a preview.
var preview_this: Image = _rwImgTexture.bad:
	get:
		if self.image:
			var _previmg:Image
			_previmg = self.image.duplicate()
			return _previmg
		return _rwImgTexture.bad

## Override to do the work. Coroutine.
func create_image()->Image: return null

## Called from ResourceWrangler when this node must supply image data.
## Have to repeat this code here because I am not actually related to the
## rwMemoryImageTexture class. (I'm trying to imitate it.)
## Coroutine.
func process():
	var final_img:Image = await create_image()
	if final_img:
		self.set_image(final_img)
	return

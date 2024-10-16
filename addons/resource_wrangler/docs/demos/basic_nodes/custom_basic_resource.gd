@tool
@icon("../../../assets/resource_wrangler_icon_32x32.small.svg") #<-- relative paths to some icon!
class_name CustomResource
extends Resource

@export_group("Plug one resource in")
@export var stuff:Resource # used by default as preview icon
@export var somethingelse:Resource

## to demo the preview override
var preview_this:Resource: # choose some other preview resource
	get: # DOES NOT RUN UNLESS SCRIPT IS @tool :(
		return somethingelse

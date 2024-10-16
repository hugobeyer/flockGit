@tool
@icon("../icons/textsettings_nodeicon.cleaned_icon.svg")
class_name rwtexTextSettings
extends LabelSettings

## Text Settings
##
## A reusable resource for various text settings that can be used by
## the Render Text node [rwtexTextRender].
## [br]
## Will create a default Font if [param font] is null.

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Text Settings", # What appears on the node itself
	&"category" : &"Image Nodes", # Optional
	}

## The string to render.
@export_multiline var text:String

## Whether to fill the text or not.
@export var no_fill:bool = false

## Adjust the text up and down.
@export var adjust_up_down:float = 0.0

#TODO other params
#alignment: HorizontalAlignment = 0,
#justification_flags: BitField[TextServer.JustificationFlag]
#0, #direction: TextServer.Direction = 0,
#0, #orientation: TextServer.Orientation = 0

var _default_font : Font = SystemFont.new()

func _get(property: StringName) -> Variant:
	if property == &"font":
		if not font: return _default_font
		return font
	return null

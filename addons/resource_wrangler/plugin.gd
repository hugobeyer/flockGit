@tool
class_name NSrw # NS == NameSpace
extends EditorPlugin

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

## Credits
#Thanks to these ultra-cool peeps who helped me along the way:
#1. https://mastodon.gamedev.place/@jdbaudi
#2. https://mastodon.gamedev.place/@exoticorn
#3. https://mastodon.gamedev.place/@efi@chitter.xyz

# Dedicated to the memory of my mum Marie (d 2022). We were best friends for
# life and lived the last twenty of her's in the Fynbos of the Cape in South Africa.
# And to my old dad Howard (d 1998) who showed me BASIC and bought me my
# Spectravideo 318 home computer.
# I miss you guys. — Donn Ingle.
#  Cherish your people. Life ends.


## All the assets the entire plugin will use.

# This one has some oddness, leaving as preloads for noo.
const rwBoardDatabase := preload("src/main/board_data.gd")
const rwBoardDatabaseIcon = preload("assets/resource_wrangler_icon_32x32.small.svg")

const InsP := preload("src/inspector_plugin/cust_res_preview.gd")
const InsPscene:PackedScene = preload("src/inspector_plugin/cust_res_preview.tscn")

const DataSlotScene:PackedScene = preload("src/nodes/slot.tscn")
#const DataSlotScript := preload("src/nodes/slot.gd")

const BASE_NODE_SCENE:PackedScene = preload("src/nodes/rw_node.tscn")
const ChooserThingScene:PackedScene = preload("src/nodes/choosers/chooser_node.tscn")

const MainViewScene:PackedScene = preload("src/main/main_view.tscn")
const MainView := preload("src/main/main_view.gd")

const array_porticon := preload("assets/array_port_icon_cleaned.svg")
const selected_style := preload("assets/graphnode_selected_style.stylebox")
const frame_style := preload("assets/graphnode_style.stylebox")
const title_normal := preload("assets/title_bar_style.tres")
#const title_rolled_up := preload("assets/title_bar_rolledup_style.tres")
const graph_bgstyle := preload("assets/graph_bg_style.tres")

const clone_string := "⭕ Duplicate as Clone"


# leaving in case I have to come back to this.
#const CUSTOM_RESOURCE_DB = {
	#"rwtexFiddle": {
		#basename="Resource",
		#icon = preload("assets/resource_wrangler_icon_16x16.small.svg")
		#}
#}


var main_view: NSrw.MainView
var rwbutton : Button
var cust_res_preview

# Block resource classnames here that crash Godot when they
# are instantiated, or they are specified as not creatable by new()
var blocked_resource_classes:=[
	"Image",
	"AudioStreamMP3"
] # Add them as you find them


func _enter_tree() -> void:
	#print(NSrw.get_property_list())
	if Engine.is_editor_hint():
		print("
=================== RESOURCE WRANGLER TIPS ======================
If you have just installed this plugin, restart your project.
=================================================================
		")

		## Was hoping this would provide an icon for the tres files, but nope...
		#add_custom_type("Board","Resource", NSrw.rwBoardDatabase, NSrw.rwBoardDatabaseIcon)

		## Nice, a preview for my custom resources
		cust_res_preview = NSrw.InsP.new()
		add_inspector_plugin(cust_res_preview)

		main_view = NSrw.MainViewScene.instantiate()

		## get_editor_interface().get_editor_main_screen().add_child(main_view)
		rwbutton = add_control_to_bottom_panel(main_view, "Resource Wrangler")
		if main_view:
			main_view.setup(self, get_undo_redo())
		else:
			push_error("""


*** RESOURCE WRANGLER
			SANITY ERROR ***
  For some arcane reason,
  the plugin will not plug.
  Restart Godot..
  Make offerings to your
  Eldritch gods.
****** /|\\(;,;)/|\\ ******


""")




func _exit_tree() -> void:
	if is_instance_valid(main_view):
		remove_inspector_plugin(cust_res_preview)
		remove_control_from_bottom_panel(main_view)
		main_view.queue_free()


func _has_main_screen() -> bool:
	return false


func _get_plugin_name() -> String:
	return "Resource Wrangler"


func _apply_changes() -> void:
	if is_instance_valid(main_view):
		main_view.apply_changes()


func _handles(object: Object) -> bool:
	return object is rwBoardDatabase #rwBoardDatabaseResource


## _handles() enables this func. So we can dclick a board.tres file
## and have it open in this plugin.
func _edit(object: Object) -> void:
	if object is not rwBoardDatabase: return

	# Have to do this cast, or:
	# SCRIPT ERROR: Invalid access to property or key 'resource_path' on a base object of type 'null instance'.
	object = object as Resource

	if is_instance_valid(main_view):

		# If the board was made outside RW UI:
		if object.board_created_outside_rw:
			# Notes:
			# If I JUST made a new board outside the ui:
			# print confirms all these props blank at this point.
			# print("object.object.resource_path:", object.resource_path)
			# print("object.object.resource_name:", object.resource_name)
			# print("object.object.resource_id:", object.id)
			# object.get_property_list().filter(func(e): print(e) )
			# BUT I see the resource file in the FS.
			# Conclusion:
			# flag that we made this board WITHIN rw ui and bail and hope.
			object.board_created_outside_rw = false
			return

		make_bottom_panel_item_visible(main_view) # YAY!!!
		main_view._open_board(object.resource_path)



# not used when the plugin is in the bottom panel area. Ah well.
#func _get_plugin_icon() -> Texture2D:
#	return create_main_icon()


#func create_main_icon(scale: float = 1.0) -> Texture2D:
#	var size: Vector2 = Vector2(16, 16) * get_editor_interface().get_editor_scale() * scale
#	#var base_color: Color = get_editor_interface().get_editor_main_screen().get_theme_color("base_color", "Editor")
#	#var theme: String = "light" if base_color.v > 0.5 else "dark"
#	var base_icon = load("res://addons/resource_wrangler/assets/resource_wrangler_icon_large_cleaned.svg") as Texture2D
#	var image: Image = base_icon.get_image()
#	image.resize(size.x, size.y, Image.INTERPOLATE_TRILINEAR)
#	return ImageTexture.create_from_image(image)

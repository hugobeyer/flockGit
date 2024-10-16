@tool
class_name dbatGeneralUtils
extends RefCounted

##region licence
# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
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
##endregion

static func mk_file_dialog(filters, mode):
	var fd:FileDialog = FileDialog.new()
	fd.filters = filters
	fd.file_mode = mode
	fd.mode_overrides_title = true
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.mode = Window.MODE_WINDOWED
	fd.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	fd.size = Vector2(512,512)
	return fd


static func refresh_filesystem(paf=""):
	if paf: EditorInterface.get_resource_filesystem().update_file(paf)
	EditorInterface.get_resource_filesystem().scan()


static func show_editor_icons():
	var godot_theme = EditorInterface.get_editor_theme()
	var list = Array(godot_theme.get_icon_list(&"EditorIcons"))
	list.sort()
	print("list:", list)
	print()


## Note to future self:
## I had this:
## if "preview_this" in resource:
##  ... and it was ALWAYS TRUE, even if preview_this was NOT in res,
##  ... which was some bs!!
## ∴ This func
## Nov 2023: I had reported this bug and it was fixed in 4.2 RC1
## TODO But was it fixed for all resources?
static func is_in(an_object:Object, seek:StringName)->bool:
	var props = an_object.get_property_list()
	for prop in props:
		#print(prop)
		if prop.name == seek:
			return true
	return false


static func smallhash(classname:String)->int:
	return abs(classname.hash() % 512) # hopefully not more than 512 resource types!

static func varhash(s:String,v:int)->int:
	return abs(s.hash() % v)


static var _used_ids:Array[String]
static func record_used_id(id):
	if id not in _used_ids:
		_used_ids.append(id)
		#print("recorded id:", id)
	#else:
		#print("already know id:", id)
	#print("  list:", _used_ids)
static func reclaim_used_id(id):
	_used_ids.erase(id) # no error if not in there
	#print("reclaim id:", id)
	#print("  list:", _used_ids)
## This func alteration ensures an id at least different from the last one
## generated.
static func get_random_id()->String:
	var id:String = _rid()
	if not _used_ids.is_empty():
		while id in _used_ids:
			id = _rid()
	_used_ids.append(id)
	#print("ret id:", id)
	#print("  list:", _used_ids)
	return id
static func _rid()->String:
	randomize()
	seed(Time.get_unix_time_from_system())
	return str(randi() % 1000000).sha1_text().substr(0, 10)


static func show_settings(_main_view):
	#Thanks to https://mastodon.gamedev.place/@jdbaudi
	var base = EditorInterface.get_base_control()
	# Find the Project Settings Editor
	var settings = base.find_child('*ProjectSettingsEditor*', true, false)
	if not settings:
		print('ProjectSettingsEditor not found (?)')
		return

	# Grab the tab container from the sectioned editor
	var tab_container = settings.find_child('*TabContainer*', true, false)
	if not tab_container is TabContainer:
		print('Could not find the tab container')
		return

	# Set the current tab to General
	tab_container.current_tab = 0

	# Find the Sectioned Editor inside it
	var sectioned_inspector = tab_container.find_child('*SectionedInspector*', true, false)
	if not sectioned_inspector:
		print('SectionedInspector not found (?)')
		return

	# Find the Tree inside it
	var tree = sectioned_inspector.find_child("Tree", true, false) as Tree
	if not tree:
		print('Could not find Tree')
		return

	# Find the entry in the tree
	var found_item = null
	var item = tree.get_root()

	while item:
		item = item.get_next_visible()
		if not item:
			_main_view.feedback("You have to open Project Settings manually at least once.", &"WARNING")
			break
		if item.get_text(0) == "Resource Wrangler":
			found_item = item
			break

	# Select the found item
	if found_item:
		tree.set_selected(found_item, 0)
		tree.ensure_cursor_is_visible()

		# Finally popup the Project Settings Editor
		settings.size = Vector2(512,512)
		settings.popup()

static func get_lowercase_suffix(s:String) -> String:
	#s="aABCabcABC"
	#casecmp_to
	#Performs a case-sensitive comparison to another string.
	#Returns -1 if less than, 1 if greater than, or 0 if equal.

	# if all lower, there's no suffix
	var S := s.to_lower()
	var cmp = s.casecmp_to(S)
	if cmp == 0: return s

	# if all upper, same
	S = s.to_upper()
	cmp = s.casecmp_to(S)
	if cmp == 0: return s

	# Now to find lower case suffix
	var i:=0
	while true:
		var _c = s.substr(i,1)
		var _C = S.substr(i,1)
		cmp = _c.casecmp_to(_C)
		if cmp == 0:
			break
		i += 1
	var sub = s.substr(0,i)
	return sub


### Tries to clean up the automade folder.
### Massive re-write Aug 14, 2023
#func _on_prune_automades_pressed():# -> void:
	#var db_owns:Array
#
	## Get a list of all the resources known to to all the boards
	#for board in boards.values():
		#if "map_id_to_rwnode" in (board as Dictionary).keys():
			#for thing in board.map_id_to_rwnode:
				#if "dbat_data" in thing:
					#if "files" in thing.dbat_data:
						#db_owns.append(thing.dbat_data.files[0])
#
	#if db_owns.is_empty():
		#return # can't do anything
#
	#var path:String=rwSettings.automade_path + "/resources"
	#var makepaf := "%s/%s" % [path,"%s"]
	#var all_autos:Array
#
	#var dir = DirAccess.open(path)
	#if dir:
		#dir.list_dir_begin()
		#var file_name
		#file_name = dir.get_next()
#
		## Build a list of <Resources> that are in the automades dir
		#while file_name != "":
			#if not dir.current_is_dir():
				#var paf = makepaf % [file_name]
				##print("automade:",paf)
				#all_autos.append(paf)
			#file_name = dir.get_next()
#
	#if all_autos.is_empty():
		#return #no automades anyway...
#
	#var unowned:Array
	## Reasoning: if the automade is not in the db, then
	## it must be unowned by the db
	#for automade_paf in all_autos:
		#if not automade_paf in db_owns:
			#unowned.append(automade_paf)
#
	#if unowned.is_empty():
		#return # Nothing is unowned - so, all good
#
	## Ok! Move the buggers out!
	## If the resource has dependencies, it goes into a sub
	## folder has_deps
	## If not, has_no_deps
	## It's left to the user to sort those out.
	#var have_deps_path:String="%s/have_deps" % [path]
	#var have_no_deps_path:String="%s/have_no_deps" % [path]
	#for paf in unowned:
		## This barfs a lot on any error
		#var deps = ResourceLoader.get_dependencies(paf)
		#var to_paf:String
		#if deps.is_empty():
			#to_paf = "%s/%s" % [have_no_deps_path, paf.get_file()]
			#dir.make_dir(have_no_deps_path)
			#dir.rename(paf, to_paf)
		#else:
			#to_paf = "%s/%s" % [have_deps_path, paf.get_file()]
			#dir.make_dir(have_deps_path)
			#dir.rename(paf, to_paf)
#
	#_save_board()
	##EditorInterface.get_resource_filesystem().scan()
	#return
#

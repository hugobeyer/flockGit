@tool
class_name rwSettings extends Object

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

enum {NOP,DIR}

const ADDON_KEY = &"resource_wrangler"

#const NSrw = preload("../../ns.gd")

## resource_wrangler/automade_path
static var automade_path:
	get:
		var ret : String = get_setting(&"automade_path").rstrip("/")
		return ret

static var boards_path:
	get:
		var ret : String = get_setting(&"boards_path").rstrip("/")
		return ret


static func setup():
	# Desperately flail around trying to make keys and stuff
	_make_setting(&"automade_path", &"res://automade_resources", DIR)
	_make_setting(&"extended_functionality", false)
	_make_setting(&"recent_boards",[])

	_make_setting(&"minimap_enabled", false)
	_internal(&"minimap_enabled")
	_make_setting(&"minimap_size", Vector2(200, 150))
	_internal(&"minimap_size")
	_make_setting(&"snapping_enabled", true)
	_internal(&"snapping_enabled")
	_make_setting(&"snapping_distance", 20)
	_internal(&"snapping_distance")

	# Remove deprecated keys
	_rm("database_path_and_filename")
	_rm("last_board_database_paf")
	_rm("current_board_id")
	_rm("extended functionality")
	_rm("foo")
	_rm("categories")
	_rm("no_instance")
	_rm("boards_path") # rm Jan 4, 2024

	ProjectSettings.save()
	ensure_dirs()


static func _rm(key):
	var pkey := "%s/%s" % [ADDON_KEY,key]
	if ProjectSettings.has_setting(pkey):
		ProjectSettings.set_setting(pkey, null) #null removes a key
		ProjectSettings.save()


static func _internal(key):
	var pkey := "%s/%s" % [ADDON_KEY,key]
	ProjectSettings.set_as_internal(pkey, true)
	ProjectSettings.save()


static func _make_setting(key: String, init_value, typ:int=0)->void:
	if init_value == null:
		assert(false, "Trying to remove a key in _make_setting")
	var pkey := "%s/%s" % [ADDON_KEY,key]
	if not ProjectSettings.has_setting(pkey):
		ProjectSettings.set_setting(pkey, init_value)
		ProjectSettings.set_initial_value(pkey, init_value)
		match typ:
			DIR:
				ProjectSettings.add_property_info({
					name = pkey,
					type = TYPE_STRING,
			 		hint = PROPERTY_HINT_DIR
					})
	ProjectSettings.set_as_basic(pkey, true)


static func get_setting(key:String, default=null)->Variant:
	var pkey := "%s/%s" % [ADDON_KEY,key]
	#print(pkey, " ", ProjectSettings.get_setting(pkey, default))
	return ProjectSettings.get_setting(pkey, default)


static func save_setting(key, value):
	var pkey := "%s/%s" % [ADDON_KEY,key]
	ProjectSettings.set_setting(pkey,value)
	ProjectSettings.save()


static func ensure_dirs():
	var err:=[]
	var d = automade_path
	err.append( DirAccess.make_dir_absolute(d) )
	err.append( DirAccess.make_dir_absolute(d + "/classes") )
	err.append( DirAccess.make_dir_absolute(d + "/resources") )
	#d = boards_path
	#err.append( DirAccess.make_dir_absolute(d) )
	var crash:=false
	for e in err:
		if e != ERR_ALREADY_EXISTS:
			push_error(e)
			crash = true
	if crash: assert(false, "DirAcces errors. If Godot has crashed, force-close and try again.")


static func get_most_recent_board()->NSrw.rwBoardDatabase:
	return get_recent_board_by_index(0)


static func get_recent_board_by_index(index:int)->NSrw.rwBoardDatabase:
	var board_paf:String = ""
	var test_load = null
	var recent_boards = get_setting(&"recent_boards")
	if index in range(0, recent_boards.size()):
		board_paf = recent_boards[index]
	if board_paf:
		test_load = NSrw.rwBoardDatabase.load(board_paf)
	if test_load == null:
		recent_boards.remove_at(index)
		save_setting(&"recent_boards", recent_boards)
		return null
	return test_load


static func verify_recent_boards()-> void:
	var test_load = null
	var tmp = []
	var recent_boards = get_setting(&"recent_boards")
	for board_paf in recent_boards:
		if FileAccess.file_exists(board_paf):
			tmp.append(board_paf)
	recent_boards.clear()
	recent_boards = tmp.duplicate()
	save_setting(&"recent_boards", recent_boards)


static func add_to_recent_boards(paf):
	var recent_boards : Array = get_setting(&"recent_boards")
	rm_from_recent_boards(paf)
	recent_boards.push_front(paf)
	if recent_boards.size() > 10:
		recent_boards.resize(10)
	save_setting(&"recent_boards", recent_boards)


static func rm_from_recent_boards(paf):
	#print("rm:", paf)
	var recent_boards:Array = get_setting(&"recent_boards")
	#print("recent boards before:")
	#recent_boards.filter( func(e): print(e); return e )
	recent_boards.erase(paf)
	#print("after:")
	#recent_boards.filter(func(e): print(e); return e)
	save_setting(&"recent_boards", recent_boards)

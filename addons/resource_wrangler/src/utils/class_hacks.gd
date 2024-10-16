@tool
class_name dbatClassHacks
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

## Various desperate functions to handle GDscript's weird class name crap.
## As of Godot 4.3 there is now `obj.get_script().get_global_name()` which will
## return the class_name. Yay. However, the code in here already works, so
## I am loathe to mess with it. So, leaving it be for the nonce.
##
## Also ways to get icons and such. General mayhem.

const NO_CLASS_NAME := "NO_CLASS_NAME" #TODO can I make this a StringName type?
const _regexes := {
	"@icon" : "@icon.*\\(\"(.*)\"\\)",
	"class_name" : "class_name.(.*)"
	#"noinstance" : "#.*\\ *(noinstance)",
	#"extends" : "extends.(.*)",
	}


## Get an icon for a resource class, by hook or by crook.
## If one is not found in input class name, seek for one
## in the ancestors. Default "Object" icon is returned if none.
static func get_icon_for(res_class_name, editor_plugin)->Texture2D:
	var icon:Texture2D
	var iconpaf:=""
	var a = ProjectSettings.get_global_class_list()
	var _d:Dictionary
	var cn:String = res_class_name
	while true:
		var arr = a.filter(func(d): return StringName(cn) == d["class"])
		if arr.is_empty():
			break
		_d = arr[0]
		iconpaf = _d.get(&"icon","")
		if iconpaf:
			break
		cn = _d.get(&"base", "")
		if not cn:
			assert(false, "Weird bug in get_icon_for")

	var godot_theme = EditorInterface.get_editor_theme()
	if not is_class_custom(cn):
		var iconname := ""
		if godot_theme.has_icon(cn, &"EditorIcons"):
			iconname = cn
		else:
			iconname = &"Object"
		icon = godot_theme.get_icon(iconname, &"EditorIcons")
		return icon

	var sz32 := Vector2i(32,32)
	var image:Image
	if iconpaf.is_empty():
		## Try to get the Object icon from a cache, else make it and resize it.
		icon = godot_theme.get_icon(&"Object", &"EditorIcons")
	else:
		icon = load(iconpaf) # this prevents the Warning message
	return icon


## In my parlance, "paf" means "path and filename"
static func lookup_script_paf_by_classname(classname:String)->String:
	var a = ProjectSettings.get_global_class_list()
	var find = a.filter(func(d): return StringName(classname) == d["class"])
	var ret : String = ""
	if not find.is_empty():
		ret = find[0]["path"]
	return ret


## If all you have is a script path and you want the class_name
## Custom resource scripts that DO NOT have a class_name statement
## get a blank classname, which causes trouble upstream.
static func _lookup_class_name_by_script(paf:String)->String:
	var a = ProjectSettings.get_global_class_list()
	var find = a.filter(func(d): return paf in d["path"])
	var ret : String = NO_CLASS_NAME
	if not find.is_empty():
		ret = find[0]["class"]
	else:
		push_warning("_lookup_class_name_by_script for %s has no class entry. Looking in source." % paf)
		# okay, it's not registered, but Godot has issues,
		# so, let's go look for a class_name string in the source code
		var src = FileAccess.open(paf,FileAccess.READ).get_as_text()
		if src:
			var regex = RegEx.new()
			regex.compile(_regexes["class_name"])
			var result = regex.search(src)
			if result:
				ret = result.get_string(1)
	return ret


## If all you have is a path to a *resource* - even a gd file -
## and you want the class_name...
static func get_class_name_by_paf(trespaf:String)->String:
	var res := load(trespaf)
	if not res:
		push_error("%s path does not point to a resource file. Check orphans perhaps?" \
				% [trespaf])
		return NO_CLASS_NAME
	return _lookup_class_name_by_script(trespaf)


## Given a Resource, attempt to get the class name
static func get_classname_from_a_resource(res:Resource)->String:
	var resclassname:String = NO_CLASS_NAME
	if res.script: # TODO this .script access seems to be undocumented...
		var res_script : String = res.script.get_path()
		# Note: If the script has no class_name keyword then the
		# res_script is not matched in the lookup test below:
		resclassname = _lookup_class_name_by_script(res_script)
		# Therefore it comes back as empty. So we make sure to id it:
		if resclassname == NO_CLASS_NAME:
			push_warning("Please make sure your script has a class_name:%s" % res_script)
		return resclassname
	# If there's no script, try the get_class func
	if res.get_class():
		resclassname = res.get_class()
	return resclassname


## Given a classname string, find the immediate 'parent' class
## of a built-in or custom script.
## class_name 'classname' extends B
## B is the 'parent'
static func get_parent_class(classname)->String:
	if not classname:
		return NO_CLASS_NAME
	var _ret:String=""
	if is_class_custom(classname):
		var a := ProjectSettings.get_global_class_list()
		# Seems to work for @tool and non tool ! ! !
		# {"class": &"ClassA", "language": &"GDScript", "path": "..classA.gd",
		# "base": &"Node", "icon": "..if one"}
		a = a.filter(func(i): return i.class == classname)
		if not a.is_empty():
			_ret = a[0].base
	else:
		_ret = ClassDB.get_parent_class(classname)
	if _ret == "":
		return NO_CLASS_NAME
	return _ret


## Get ancestors (things that have extended the classname)
## e.g Noise gives ["Noise", &"Resource", &"RefCounted", &"Object"]
static func get_ancestors(classname)->Array[StringName]:
	if not classname:
		return [NO_CLASS_NAME]
	var a := ProjectSettings.get_global_class_list()
	var b = a.map(func(d): return {"class":d.class, "base":d.base})
	var c = {}
	for d in b:
		c[d.class] = d.base
	var curr = classname
	var base
	var stack:Array[StringName]
	while true:
		if c.get(curr,false):
			base = c[curr]
		else:
			base = ClassDB.get_parent_class(curr)
		if base.is_empty():
			stack.append(NO_CLASS_NAME)
			break
		stack.append(base)
		curr = base
		if base == "Object": break
	return stack


## Is the given classname a custom class?
static func is_class_custom(classname)->bool:
	return not ClassDB.class_exists(classname)


## Can we actually instantiate the given classname?
## If it's a custom class:[br]
## I want to check the class for something that flags it as ok to instance.
## Either I force the classname to contain some substring or I have to
## open the script file and grep the source. I could instance it and look
## for some property like _no_instance or something, but that seems radical.
## because inits and stuff will run and who-knows what else?[br]
## UPDATE: May 2024 Moved to a key in rw_metadata func
## Use key noinstance = true/false
static func can_we_instantiate(classname)->bool:
	if classname == NO_CLASS_NAME: return false
	if is_class_custom(classname):
		var _n = get_metadata(classname, &"noinstance")
		return not _n
	return ClassDB.can_instantiate(classname)


# This returns a Resource (or null)
static func get_class_from_stringname(classname:StringName) -> Resource:
	var a = ProjectSettings.get_global_class_list()
	a = a.filter(func(d): return d.class == classname)
	if a:
		# it's possible for old scripts to be in `a` but not on
		# disk. Go figure...
		if FileAccess.file_exists(a[0].path):
			var i = load(a[0].path)
			return i
	return null


static func get_metadata(classname:StringName, key):
	var _val = null
	var inst = get_class_from_stringname(classname)
	if inst and inst.has_method(&"rw_metadata"):
		_val = inst.rw_metadata().get(key, null)
	#REMOVED const dict May 2024 for a static func instead
	#if inst and &"_rwMetadata" in inst:
		#_val = inst._rwMetadata.get(key, null)
	return _val





#region OLD STUFF

# LESSONS
# ====

#var a = ProjectSettings.get_global_class_list() # Gets CUSTOM classes
#for d in a: print(d)
"""
{ "class": &"ARes", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/ares.gd", "base": &"Resource", "icon": "res://addons/resource_wrangler/assets/resource_wrangler_icon_large.svg" }
{ "class": &"ChooserBase", "language": &"GDScript", "path": "res://addons/resource_wrangler/src/nodes/choosers/chooser_thing_base.gd", "base": &"GraphNode", "icon": "" }
{ "class": &"ClassA", "language": &"GDScript", "path": "res://tests/extends/classA.gd", "base": &"Node", "icon": "" }
{ "class": &"ClassB", "language": &"GDScript", "path": "res://tests/extends/classB.gd", "base": &"ClassA", "icon": "" }
{ "class": &"ClassC", "language": &"GDScript", "path": "res://tests/extends/classC.gd", "base": &"ClassB", "icon": "" }
{ "class": &"CustomResource", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/custom_basic_resource.gd", "base": &"Resource", "icon": "" }
{ "class": &"ExtendedResourceNode", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/extended_nodes/extended_node.gd", "base": &"rwExtendedResourceBase", "icon": "" }
{ "class": &"MyTestDB", "language": &"GDScript", "path": "res://tests/resource_uid/mytestdb.gd", "base": &"Resource", "icon": "" }
{ "class": &"SampleOne", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/grouped_nodes/sample1.gd", "base": &"Resource", "icon": "" }
{ "class": &"SampleThree", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/grouped_nodes/sample3.gd", "base": &"Resource", "icon": "" }
{ "class": &"SampleTwo", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/grouped_nodes/sample2.gd", "base": &"Resource", "icon": "" }
{ "class": &"customNameExample", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/custom_name_example.gd", "base": &"Resource", "icon": "" }
{ "class": &"dbatClassHacks", "language": &"GDScript", "path": "res://addons/resource_wrangler/src/utils/classes.gd", "base": &"RefCounted", "icon": "" }
{ "class": &"dbatGeneralUtils", "language": &"GDScript", "path": "res://addons/resource_wrangler/src/utils/general.gd", "base": &"RefCounted", "icon": "" }
{ "class": &"resCust4", "language": &"GDScript", "path": "res://automade_resources/classes/cust4.gd", "base": &"resCustom3", "icon": "" }
{ "class": &"resCustom2", "language": &"GDScript", "path": "res://automade_resources/classes/custom2.gd", "base": &"CustomResource", "icon": "" }
{ "class": &"resCustom3", "language": &"GDScript", "path": "res://automade_resources/classes/custom3.gd", "base": &"resCustom2", "icon": "" }
{ "class": &"resCustomB", "language": &"GDScript", "path": "res://automade_resources/classes/customB.gd", "base": &"CustomResource", "icon": "" }
{ "class": &"resPooped", "language": &"GDScript", "path": "res://automade_resources/classes/pooped.gd", "base": &"resTrd", "icon": "" }
{ "class": &"resRuhoh", "language": &"GDScript", "path": "res://automade_resources/classes/ruhoh.gd", "base": &"resUhoh", "icon": "" }
{ "class": &"resScooby", "language": &"GDScript", "path": "res://automade_resources/classes/Scooby.gd", "base": &"resRuhoh", "icon": "" }
{ "class": &"resTrd", "language": &"GDScript", "path": "res://automade_resources/classes/trd.gd", "base": &"CustomResource", "icon": "" }
{ "class": &"resUhoh", "language": &"GDScript", "path": "res://automade_resources/classes/uhoh.gd", "base": &"PlaneMesh", "icon": "" }
{ "class": &"rwExtendedResourceBase", "language": &"GDScript", "path": "res://addons/resource_wrangler/src/nodes/extended/resource_base.gd", "base": &"Resource", "icon": "" }
{ "class": &"willNotAppearInWrangler", "language": &"GDScript", "path": "res://addons/resource_wrangler/docs/samples/basic_nodes/custom_no_instance_resource.gd", "base": &"Resource", "icon": "" }

"""


	#var huh = ClassDB.get_class_list() # gets string names of all built-in classes
	#var a := ProjectSettings.get_global_class_list() # all custom classes in dicts
	#.map(#func(d): return str(d.class))

# LESSONS LEARNED about ClassDB.is_parent_class:
#var classname = "Node2D"
#var potential_parent_name = "Object" #true
#print("ClassDB.is_parent_class(",classname,",", potential_parent_name, ")",
 #ClassDB.is_parent_class(classname, potential_parent_name)  )
#
## LESSON: ClassDB.is_parent_class tests *any* parent of the first arg
#
##@tool
##class_name ClassA
##extends Node
#classname = "ClassA"
#potential_parent_name = "Node" #false
#print("ClassDB.is_parent_class(",classname,",", potential_parent_name, ")",
 #ClassDB.is_parent_class(classname, potential_parent_name)  )
#
## LESSON: DOES NOT WORK FOR CUSTOM CLASSES
#
#classname = "ClassB"
#potential_parent_name = "ClassA" #false
#print("ClassDB.is_parent_class(",classname,",", potential_parent_name, ")",
 #ClassDB.is_parent_class(classname, potential_parent_name)  )

# Keep for in-case
#static func get_parent_class(classname)->String:
	#var parent_class_or_script_path:String = NO_CLASS_NAME
	#if not classname:
		#return parent_class_or_script_path
	#if is_class_custom(classname):
		#var a := ProjectSettings.get_global_class_list()
		#a = a.filter(
			#func(i): return i.class == classname )
		#if not a.is_empty():
			#var paf = a.back().path
			#var src = FileAccess.open(paf,FileAccess.READ)
			#if src:
				#var regex = RegEx.new()
				#regex.compile(_regexes["extends"])
				#var result = regex.search(src.get_as_text())
				#if result:
					#parent_class_or_script_path = result.get_string(1)
	#else:
		#parent_class_or_script_path = ClassDB.get_parent_class(classname)
	#return parent_class_or_script_path



## Reach down into the source code of a resource and
## pluck-out any reference to the @icon
## Nov 2023 : Not being used anymore
#static func get_script_icon_paf(res:Resource)->String:
	#if not res: return ""
	#var s:Script
	## sometimes I call this with a basic load of a resource
	## which means res is already a GDScript:
	#if res is GDScript:
		#s = res
	#else:
		## else we need to do more work to find the actual script
		#var scrpt = res.get_script()
		#if not scrpt: return ""
		#s = load(scrpt.get_path())
	### Should not be needed anymore:
	#push_warning("Going into source to find an icon in %s" % s.resource_path)
	#var src:String = s.source_code
	#var regex = RegEx.new()
	#regex.compile(_regexes["@icon"])
	#var result = regex.search(src)
	#if result:
		#return result.get_string(1)
	#return ""

## Given a BUILTIN classname like "mesh", this will return a string of
## a class name one up from Resource.
## Nov 2023: Currently not being used.
#static func get_base_class_name_of_builtin_resources(classname)->String:
	#var parent_class_or_script_path = ClassDB.get_parent_class(classname)
	#if parent_class_or_script_path=="Resource":
		#return classname
	#if parent_class_or_script_path=="":
		#return "Resource"
	#return get_base_class_name_of_builtin_resources(parent_class_or_script_path)


##
#static func is_resource_custom(res)->bool:
	#return is_class_custom(get_classname_from_a_resource(res))


#endregion

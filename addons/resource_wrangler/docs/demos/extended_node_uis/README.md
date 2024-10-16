Extended Nodes
==
See "extended_node.gd" for the example.

If you want to 'glue' extra controls onto a node, you can use this process:

Code at the top
--

```
@tool #make sure this is used
class_name ExtendedResourceNode # Your name here
extends DbatResourceBase #and then extend this class
```

TIP: If you get weird errors like Resource has no method "show_node_gui" then restart the project. Godot is iffy like that.

Your Exports
--
As you please:

```
@export_group("Meshes")
@export var my_meshes:Array[Mesh]
```

Supply a Scene and Override show_node
--

```
## This is a scene that is your gui
const SCENE_PRELOAD = preload("sample_extended_ui.tscn")

## Now implement this func:
## Calls parent which handles adding the gui
## Then does the necc to show the data in the gui
## _nop just means no operation, i.e. ignore it; leave as-is
func show_node_gui(graphnode:GraphNode, data: Dictionary, _nop) -> void:
```

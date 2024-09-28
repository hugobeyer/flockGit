@tool
extends EditorInspectorPlugin

var shader_manager: ShaderManager

func _can_handle(object):
    return object is ShaderInteraction

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
    if name == "parameter_name":
        var dropdown = ShaderParamDropdown.new()
        dropdown.shader_manager = shader_manager
        add_property_editor(name, dropdown)
        return true
    return false

class ShaderParamDropdown extends EditorProperty:
    var dropdown = OptionButton.new()
    var shader_manager: ShaderManager
    var updating = false

    func _init():
        add_child(dropdown)
        add_focusable(dropdown)
        dropdown.connect("item_selected", Callable(self, "_on_dropdown_selected"))

    func _ready():
        update_dropdown()

    func update_property():
        var new_value = get_edited_object()[get_edited_property()]
        updating = true
        dropdown.select(dropdown.get_item_index(dropdown.find_item_by_text(new_value)))
        updating = false

    func _on_dropdown_selected(index):
        if updating:
            return
        var selected = dropdown.get_item_text(index)
        emit_changed(get_edited_property(), selected)

    func update_dropdown():
        dropdown.clear()
        if shader_manager:
            for param in shader_manager.shader_params:
                dropdown.add_item(param)
        update_property()

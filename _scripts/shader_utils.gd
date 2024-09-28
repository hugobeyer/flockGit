extends Node

func update_shader_preserving_instance_params(material: ShaderMaterial, new_shader: Shader):
    # Store current instance parameter values
    var instance_params = {}
    for param in material.get_shader_parameter_list():
        if material.get_shader_parameter(param) != null:
            instance_params[param] = material.get_shader_parameter(param)
    
    # Update the shader
    material.shader = new_shader
    
    # Reapply stored instance parameter values
    for param in instance_params:
        if material.get_shader_parameter(param) != null:
            material.set_shader_parameter(param, instance_params[param])

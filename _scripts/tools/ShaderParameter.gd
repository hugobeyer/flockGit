extends Node3D  # or whatever your player node type is

func _process(delta):
    var player_pos = global_position
    print("player position: ", player_pos)
    RenderingServer.global_shader_parameter_set("player_position", player_pos)

extends MeshInstance3D

@export var damage_flash_duration: float = 0.1  # How long the player flashes green when damaged
var original_albedo_color: Color  # Store the original color
var damage_timer: Timer  # Timer to reset the color
var material: StandardMaterial3D  # The player's material

func _ready():
	# Get the material and store the original albedo color
	material = get_active_material(0) as StandardMaterial3D
	original_albedo_color = material.albedo_color
	
	# Initialize a timer to reset the albedo color after damage
	damage_timer = Timer.new()
	damage_timer.one_shot = true
	add_child(damage_timer)

	# Properly connect the timer's timeout signal using Callable
	damage_timer.connect("timeout", Callable(self, "_on_damage_timeout"))

func flash_green():
	# Change the albedo color to green when damaged
	material.albedo_color = Color(1, 0, 0)

	# Start the timer to reset the color after a brief moment
	damage_timer.start(damage_flash_duration)

func _on_damage_timeout():
	# Revert the albedo color to the original
	material.albedo_color = original_albedo_color

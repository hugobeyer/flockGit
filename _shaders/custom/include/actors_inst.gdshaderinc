instance uniform vec4 color_top : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform vec4 color_bottom : source_color = vec4(0.120, 0.55, 0.120, 1.0);
instance uniform float gradient_offset : hint_range(-1.0, 1.0) = 0.0;
instance uniform float gradient_smoothness : hint_range(0.0, 1.0) = 0.5;
instance uniform float gradient_rotation_x : hint_range(-3.14159, 3.14159) = 0.0;
instance uniform float gradient_rotation_y : hint_range(-3.14159, 3.14159) = 0.0;
instance uniform float gradient_rotation_z : hint_range(-3.14159, 3.14159) = 0.0;

instance uniform bool use_vertex_colors = false;
instance uniform float vertex_color_mix : hint_range(0.0, 1.0) = 1.0;
instance uniform int blend_mode : hint_range(0, 3) = 0;
instance uniform float alpha : hint_range(0.0, 1.0) = 1.0;

instance uniform vec3 specular_color : source_color = vec3(1.0, 1.0, 1.0);
instance uniform vec3 fresnel_color : source_color = vec3(1.0, 1.0, 1.0);
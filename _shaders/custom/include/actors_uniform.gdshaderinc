uniform float diffuse_softness : hint_range(0.0, 1.0) = 0.3;
uniform float diffuse_bias : hint_range(-1.0, 1.0) = 0.0;
uniform float diffuse_contrast : hint_range(0.0, 2.0) = 1.0;
uniform int diffuse_steps : hint_range(1, 10) = 1;
uniform float diffuse_step_softness : hint_range(0.0, 1.0) = 0.1;
uniform float diffuse_wrap : hint_range(0.0, 2.0) = 0.0;
uniform float diffuse_offset : hint_range(-1.0, 1.0) = 0.0;

uniform float specular_intensity : hint_range(0.0, 1.0) = 1;
uniform float specular_size : hint_range(0.0, 1.0) = 0.125;
uniform float specular_smoothness : hint_range(0.0, 1.0) = 0.25;
uniform float specular_offset : hint_range(-1.0, 1.0) = 0.0;

uniform float fresnel_power : hint_range(0.0, 10.0) = 2;
uniform float fresnel_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float fresnel_contrast : hint_range(0.0, 2.0) = 2.0;
uniform float fresnel_offset : hint_range(0.0, 10.0) = 2;

shader_type spatial;

#include "res://shaders/custom/include/actors_inst.gdshaderinc"
#include "res://shaders/custom/include/actors_uniform.gdshaderinc"
#include "res://shaders/custom/include/fresnel.gdshaderinc"

varying vec3 vertex_pos;
varying vec4 vertex_color;

mat3 euler_rotation(vec3 angles) {
    vec3 c = cos(angles);
    vec3 s = sin(angles);
    
    mat3 rotX = mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, c.x, -s.x),
        vec3(0.0, s.x, c.x)
    );
    
    mat3 rotY = mat3(
        vec3(c.y, 0.0, s.y),
        vec3(0.0, 1.0, 0.0),
        vec3(-s.y, 0.0, c.y)
    );
    
    mat3 rotZ = mat3(
        vec3(c.z, -s.z, 0.0),
        vec3(s.z, c.z, 0.0),
        vec3(0.0, 0.0, 1.0)
    );
    
    return rotZ * rotY * rotX;
}

vec3 apply_rotation(mat3 rotation, vec3 point) {
    return vec3(
        dot(rotation[0], point),
        dot(rotation[1], point),
        dot(rotation[2], point)
    );
}

float apply_contrast(float value, float contrast) {
    return clamp(((value - 0.5) * contrast) + 0.5, 0.0, 1.0);
}

float apply_soft_steps(float value, int steps, float softness) {
    if (steps <= 1) return value;
    
    float stepped = floor(value * float(steps)) / float(steps - 1);
    float next_step = ceil(value * float(steps)) / float(steps - 1);
    float t = smoothstep(0.0, softness, fract(value * float(steps)));
    return mix(stepped, next_step, t);
}

vec3 soft_clamp(vec3 x, float a) {
    return 1.0 - exp(-a * x);
}

void vertex() {
    vertex_pos = VERTEX;
    vertex_color = COLOR;
}

void fragment() {
    mat3 rotation = euler_rotation(vec3(gradient_rotation_x, gradient_rotation_y, gradient_rotation_z));
    vec3 rotated_pos = apply_rotation(rotation, vertex_pos);
    float t = smoothstep(-gradient_smoothness, gradient_smoothness, rotated_pos.y + gradient_offset);
    vec4 gradient_color = mix(color_bottom, color_top, clamp(t, 0.0, 1.0));
    
    if (use_vertex_colors) {
        if (blend_mode == 0) { // Normal blend
            gradient_color = mix(gradient_color, vertex_color, vertex_color_mix);
        } else if (blend_mode == 1) { // Additive blend
            gradient_color.rgb += vertex_color.rgb * vertex_color_mix;
        } else if (blend_mode == 2) { // Multiply blend
            gradient_color.rgb *= mix(vec3(1.0), vertex_color.rgb, vertex_color_mix);
        } else if (blend_mode == 3) { // Screen blend
            gradient_color.rgb = 1.0 - (1.0 - gradient_color.rgb) * (1.0 - vertex_color.rgb * vertex_color_mix);
        }
    }
    
    ALBEDO = gradient_color.rgb;
    ALPHA = gradient_color.a * alpha;
}

void light() {
    // Diffuse lighting
    float ndotl = dot(NORMAL, LIGHT);
    float wrapped_ndotl = (ndotl + diffuse_wrap) / (1.0 + diffuse_wrap);
    float diffuse = wrapped_ndotl + diffuse_bias;
    diffuse = smoothstep(-diffuse_softness, 1.0, diffuse + diffuse_offset);
    diffuse = apply_contrast(diffuse, diffuse_contrast);
    diffuse = apply_soft_steps(diffuse, diffuse_steps, diffuse_step_softness);
    diffuse = clamp(diffuse, 0.0, 1.0);
    
    // Specular lighting
    vec3 half_dir = normalize(VIEW + LIGHT);
    float ndoth = dot(NORMAL, half_dir);
    float spec = pow(max(ndoth + specular_offset, 0.0), mix(1.0, 128.0, specular_size));
    spec = smoothstep(-specular_smoothness, 1.0, spec);
    spec *= specular_intensity;
    
    // Fresnel
    float fresnel = calculate_fresnel(NORMAL, VIEW, fresnel_power, fresnel_contrast);
    
    // Apply lighting components
    vec3 diffuse_light = ALBEDO * diffuse;
    vec3 specular_light = specular_color * spec;
    vec3 combined_light = diffuse_light + specular_light;
    
    // Apply fresnel
    combined_light = apply_fresnel(combined_light, fresnel_color, fresnel, fresnel_intensity);
    
    // Apply soft clamping
    combined_light = soft_clamp(combined_light, 0.6);
    
    // Apply light color and attenuation
    vec3 final_light = combined_light * LIGHT_COLOR * ATTENUATION;
    
    DIFFUSE_LIGHT += final_light;
}
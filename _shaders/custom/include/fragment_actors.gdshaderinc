void fragment() {
    mat3 rotation = euler_rotation(vec3(gradient_rotation_x, gradient_rotation_y, gradient_rotation_z));
    vec3 rotated_pos = apply_rotation(rotation, VERTEX);
    float t = smoothstep(-gradient_smoothness, gradient_smoothness, rotated_pos.y + gradient_offset);
    vec4 gradient_color = mix(color_bottom, color_top, clamp(t, 0.0, 1.0));
    
    if (use_vertex_colors) {
        vec4 vertex_color = vec4(COLOR.rgb, 1.0);
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
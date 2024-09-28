float calculate_fresnel(vec3 normal, vec3 view, float power, float contrast) {
    float fresnel = pow(1.0 - abs(dot(normal, view)), power);
    return apply_contrast(fresnel, contrast);
}

vec3 apply_fresnel(vec3 base_color, vec3 fresnel_color, float fresnel_value, float intensity) {
    return mix(base_color, fresnel_color, fresnel_value * intensity);
}

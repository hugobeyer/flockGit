shader_type spatial;

instance uniform float shield_percentage : hint_range(0.0, 1.0) = 1.0;
instance uniform float hit_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // Basic shield color
    vec3 shield_color = vec3(0.0, 0.25, 2.0);

    // Adjust alpha based on shield percentage
    float alpha = shield_percentage * 0.5 + 0.1;

    // Add hit effect
    vec3 hit_color = vec3(1.0, 1.0, 1.0);
    shield_color = mix(shield_color, hit_color, hit_progress);

    ALBEDO = shield_color;
    ALPHA = alpha;
    EMISSION = shield_color * 0.5;
}
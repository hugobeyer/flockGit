shader_type spatial;

uniform float lifetime : hint_range(0, 1) = 0.0;  // Lifetime uniform to control the transition
uniform vec4 start_color = vec4(1.0, 1.0, 1.0, 1.0);  // Start color for the gradient (white)
uniform vec4 end_color = vec4(1.0, 0.0, 0.0, 1.0);  // End color for the gradient (red)

void fragment() {
    // Interpolate between start and end colors based on lifetime
    vec4 final_color = mix(start_color, end_color, lifetime);

    // Output final unlit color
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
}

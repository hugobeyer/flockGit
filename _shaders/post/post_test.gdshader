shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 blur = vec4(0.0);
    
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * 0.005;
            blur += texture(TEXTURE, UV + offset);
        }
    }
    
    blur /= 25.0;
    COLOR = mix(color, blur, glow_strength);
}

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
//uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 texel_size = vec2(1.0) / vec2(textureSize(screen_texture, 0));
    vec2 uv = FRAGCOORD.xy * texel_size;

    // Sample the screen texture
    vec3 color = texture(screen_texture, uv).rgb;

    // Debug: Output the sampled texture color
    // Uncomment the following line to check if the texture is being sampled correctly
    COLOR = vec4(color, 1.0);
    // return;
//
    //float kernel_x[9];
    //kernel_x[0] = -1.0; kernel_x[1] = -2.0; kernel_x[2] = -1.0;
    //kernel_x[3] =  0.0; kernel_x[4] =  0.0; kernel_x[5] =  0.0;
    //kernel_x[6] =  1.0; kernel_x[7] =  2.0; kernel_x[8] =  1.0;
//
    //float kernel_y[9];
    //kernel_y[0] = -1.0; kernel_y[1] =  0.0; kernel_y[2] =  1.0;
    //kernel_y[3] = -2.0; kernel_y[4] =  0.0; kernel_y[5] =  2.0;
    //kernel_y[6] = -1.0; kernel_y[7] =  0.0; kernel_y[8] =  1.0;
//
    //vec3 sample[9];
    //sample[0] = texture(screen_texture, uv + texel_size * vec2(-1.0, -1.0)).rgb;
    //sample[1] = texture(screen_texture, uv + texel_size * vec2( 0.0, -1.0)).rgb;
    //sample[2] = texture(screen_texture, uv + texel_size * vec2( 1.0, -1.0)).rgb;
    //sample[3] = texture(screen_texture, uv + texel_size * vec2(-1.0,  0.0)).rgb;
    //sample[4] = texture(screen_texture, uv + texel_size * vec2( 0.0,  0.0)).rgb;
    //sample[5] = texture(screen_texture, uv + texel_size * vec2( 1.0,  0.0)).rgb;
    //sample[6] = texture(screen_texture, uv + texel_size * vec2(-1.0,  1.0)).rgb;
    //sample[7] = texture(screen_texture, uv + texel_size * vec2( 0.0,  1.0)).rgb;
    //sample[8] = texture(screen_texture, uv + texel_size * vec2( 1.0,  1.0)).rgb;
//
    //vec3 gx = vec3(0.0);
    //vec3 gy = vec3(0.0);
//
    //for (int i = 0; i < 9; i++) {
        //gx += sample[i] * kernel_x[i];
        //gy += sample[i] * kernel_y[i];
    //}
//
    //float edge_intensity = length(gx) + length(gy);
    //edge_intensity = edge_intensity > edge_threshold ? 1.0 : 0.0;
//
    //COLOR = vec4(vec3(edge_intensity), 1.0);
}
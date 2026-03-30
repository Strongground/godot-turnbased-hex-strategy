shader_type canvas_item;

uniform float noise_scale: hint_range(0.01, 10) = 0.05;
uniform float scroll_speed: hint_range(0.0, 50.0) = 15.0;
uniform float shadow_darkness: hint_range(0.0, 1.0) = 0.5;
uniform float cloud_softness: hint_range(0.0, 1.0) = 0.6;
uniform float cloud_threshold: hint_range(0.0, 1.0) = 0.5;

vec2 fade(vec2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlin(vec2 P) {
    vec2 Pi = floor(P);
    vec2 Pf = fract(P);
    vec2 u = fade(Pf);
    
    float n00 = fract(sin(dot(Pi + vec2(0.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
    float n10 = fract(sin(dot(Pi + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
    float n01 = fract(sin(dot(Pi + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    float n11 = fract(sin(dot(Pi + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    
    float nx0 = mix(n00, n10, u.x);
    float nx1 = mix(n01, n11, u.x);
    return mix(nx0, nx1, u.y);
}

float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float max_value = 0.0;
    
    for(int i = 0; i < 4; i++) {
        value += amplitude * perlin(uv * frequency);
        max_value += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value / max_value;
}

void fragment() {
    vec2 uv = UV;
    uv.x += TIME * scroll_speed * 0.05;
    uv.y += sin(TIME * scroll_speed * 0.01) * 0.1;
    
    float noise_val = fbm(uv * noise_scale);
    noise_val = pow(noise_val, cloud_softness);
    
    // Only create shadow where noise exceeds threshold
    // Below threshold = fully transparent (alpha = 0)
    // Above threshold = gradually darker up to shadow_darkness
    float shadow_alpha = smoothstep(cloud_threshold - 0.1, cloud_threshold + 0.1, noise_val) * shadow_darkness;
    
    COLOR = vec4(0.0, 0.0, 0.0, shadow_alpha);
}
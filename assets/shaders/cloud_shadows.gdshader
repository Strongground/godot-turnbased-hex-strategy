shader_type canvas_item;

uniform float noise_scale: hint_range(0.01, 10) = 0.05;
uniform float scroll_speed: hint_range(0.0, 50.0) = 15.0;
uniform float shadow_darkness: hint_range(0.0, 1.0) = 0.5;
uniform float cloud_softness: hint_range(0.0, 1.0) = 0.6;
uniform float cloud_threshold: hint_range(0.0, 1.0) = 0.5;

vec2 fade(vec2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

vec2 hash2(vec2 p) {
    // Keep the coordinate range bounded to avoid precision artifacts over long TIME runs.
    p = mod(p, 512.0);
    p = vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    );
    return normalize(fract(sin(p) * 43758.5453123) * 2.0 - 1.0);
}

float perlin(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = fade(f);

    vec2 g00 = hash2(i + vec2(0.0, 0.0));
    vec2 g10 = hash2(i + vec2(1.0, 0.0));
    vec2 g01 = hash2(i + vec2(0.0, 1.0));
    vec2 g11 = hash2(i + vec2(1.0, 1.0));

    float n00 = dot(g00, f - vec2(0.0, 0.0));
    float n10 = dot(g10, f - vec2(1.0, 0.0));
    float n01 = dot(g01, f - vec2(0.0, 1.0));
    float n11 = dot(g11, f - vec2(1.0, 1.0));

    float nx0 = mix(n00, n10, u.x);
    float nx1 = mix(n01, n11, u.x);
    // Map from approximately [-1, 1] to [0, 1].
    return mix(nx0, nx1, u.y) * 0.5 + 0.5;
}

float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float max_value = 0.0;
    
    for (int i = 0; i < 6; i++) {
        value += amplitude * perlin(uv * frequency);
        max_value += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value / max_value;
}

void fragment() {
    vec2 scroll_uv = UV;
    scroll_uv.x += TIME * scroll_speed * 0.05;
    scroll_uv.y += sin(TIME * scroll_speed * 0.01) * 0.1;

    vec2 base_uv = scroll_uv * noise_scale;

    // Domain warp breaks remaining grid alignment from the lattice structure.
    vec2 warp = vec2(
        perlin(base_uv * 0.75 + vec2(37.1, 17.7)),
        perlin(base_uv * 0.75 + vec2(11.3, 53.9))
    );
    base_uv += (warp - 0.5) * 1.35;

    float noise_val = fbm(base_uv);
    noise_val = pow(clamp(noise_val, 0.0, 1.0), cloud_softness);
    
    // Only create shadow where noise exceeds threshold
    // Below threshold = fully transparent (alpha = 0)
    // Above threshold = gradually darker up to shadow_darkness
    float shadow_alpha = smoothstep(cloud_threshold - 0.1, cloud_threshold + 0.1, noise_val) * shadow_darkness;
    
    COLOR = vec4(0.0, 0.0, 0.0, shadow_alpha);
}
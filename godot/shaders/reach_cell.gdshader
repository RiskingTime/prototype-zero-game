shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec4 ap_color : source_color;

// UV distance to the closest side gives a continuous rim around all four edges.
// Draw the fill and both bands on one depth-tested plane to avoid z-fighting.
void fragment() {
    vec2 sides = min(UV, 1.0 - UV);
    float edge = min(sides.x, sides.y);
    vec4 rim = vec4(0.035, 0.035, 0.035, 0.85);
    vec4 band = vec4(mix(ap_color.rgb, vec3(1.0), 0.27), 1.0);
    vec4 fill = vec4(ap_color.rgb, 0.35);
    float aa = max(fwidth(edge), 0.001);
    vec4 ink = mix(rim, band, smoothstep(0.03 - aa * 0.5, 0.03 + aa * 0.5, edge));
    ink = mix(ink, fill, smoothstep(0.09 - aa * 0.5, 0.09 + aa * 0.5, edge));
    ALBEDO = ink.rgb;
    ALPHA = ink.a;
}

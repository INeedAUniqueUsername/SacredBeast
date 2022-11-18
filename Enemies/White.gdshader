shader_type spatial;

uniform float whitening;

void fragment() {
    vec4 texture_color = texture(, UV);
    COLOR = vec4(mix(texture_color.rgb, vec3(1,1,1), whitening), texture_color.a);
}
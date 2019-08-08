shader_type spatial;
render_mode blend_mix, depth_draw_never, depth_test_disable, unshaded;

uniform vec4 color = vec4(1.0,1.0,1.0,1.0);
uniform sampler2D behind_tex : hint_albedo;
uniform float fade = 1;
uniform float offset = 0;
uniform float limit = 0;

void vertex() {
	POINT_SIZE = 4.0;
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    vec4 pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	
	float real_depth = 1.0 / pos.w;
	float depth_difference = real_depth + VERTEX.z;
	
	float difference_fade = clamp(depth_difference / fade + 1.0 + offset, 0.0, 1.0) + limit;
	float proximity_fade = clamp(-VERTEX.z * 4.0 - 0.2, 0.0, 1.0);
	
	ALPHA = (difference_fade * proximity_fade) * COLOR.a * color.a;
	ALBEDO = COLOR.rgb * color.rgb;
	
	if (depth_difference < 0.0)
		ALBEDO.rgb *= texture(behind_tex,FRAGCOORD.xy / vec2(textureSize(behind_tex, 0)) * vec2(1,-1)).rgb;
}
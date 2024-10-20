shader_type spatial;
render_mode blend_mix,cull_back,depth_draw_opaque,skip_vertex_transform; //for the sake of performance avoid enabling transparency on all your terrain.
uniform sampler2D texture_albedo : hint_albedo; //hint_albedo is important, it performs a color space conversion
uniform vec4 albedo : hint_color;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform float distance_fade_min;
uniform float distance_fade_max;
uniform vec3 player_position;
uniform vec4 distance_color : hint_color;
varying vec4 worldPos;

void vertex() {
	worldPos = WORLD_MATRIX * vec4(VERTEX, 1.0); //required when using skip_vertex_transform
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	VERTEX = (INV_CAMERA_MATRIX * worldPos).xyz; //required when using skip_vertex_transform
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,UV);
	//float percent = distance(normalize(player_position),normalize(VERTEX));
	float dist = distance(vec3(player_position.x,0.0,player_position.z),vec3(worldPos.x,0.0,worldPos.z));// length(worldPos)-length(player_position);
	float distanceBlend = clamp( smoothstep(distance_fade_min, distance_fade_max, dist), 0.0,1.0);
	ALBEDO = mix(albedo.rgb*albedo_tex.rgb, distance_color.rgb, distanceBlend);
}

uniform float color_saturation = 1.00;

void light() {
	vec3 base_col = ALBEDO;
	float grey_col = (base_col.r + base_col.g + base_col.b) / 3.0; //Has a softer appearance than the other greyscale formula.
	//float grey_col = dot(base_col.rgb, vec3(0.2125, 0.7154, 0.0721));
	
	float color_distant_light = min(1.00, ATTENUATION.r * color_saturation); //color_saturation decides how much of the light gradient should be saturated //The "min(1.00," prevents the saturated color from becoming over-saturated.
	base_col = mix( vec3(grey_col), base_col, color_distant_light );
	
	//How much Blue to apply is dependent on the value of grey_col.
	//First value in the mix() for each RGB all added together must be 3.0
	//Second value in the mix() is like Contrast. Lower value = flat and soft. Higher value = shiny and sharp/harsh.
//	base_col.r *= mix(0.45, 2.0, grey_col);
//	base_col.g *= mix(0.45, 2.0, grey_col);
//	base_col.b *= mix(2.10, 2.0, grey_col);
	base_col.r *= mix(1.00, 1.0, grey_col);
	base_col.g *= mix(1.00, 1.0, grey_col);
	base_col.b *= mix(1.00, 1.0, grey_col);
	
	DIFFUSE_LIGHT += ATTENUATION * base_col;
}
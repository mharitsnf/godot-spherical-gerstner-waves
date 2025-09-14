shader_type spatial;

group_uniforms GridSettings;
uniform float y_offset = 100.;
uniform float y_exponent = 4.;
uniform float radius = 1003.4;
uniform mat3 basis;

group_uniforms WaveSettings;
uniform float wave_normal_amount;
uniform float amplitude_scale;
uniform float frequency_scale;
uniform float time_scale;
uniform float steepness_e0;
uniform float steepness_e1;
uniform float cpu_time;
uniform sampler2D wave_tex;

group_uniforms VisualSettings;
uniform vec3 uv_offset;
uniform sampler2D normal_tex;
uniform vec4 main_color : source_color;
uniform vec4 back_light : source_color;
uniform float rim;

void spherical_gerstner(
	vec4 wave_data, vec3 wave_dir, vec3 pos_os_norm,
	inout float sin_part, inout vec3 cos_part,
	inout float sin_part_normal, inout vec3 cos_part_normal, inout vec3 tangent,
	float amp_scale, float s_e0, float s_e1, float freq_scale, float t, float r, float time
) {
	vec3 wave_dir_norm = normalize(wave_dir);

	float amplitude = amp_scale * wave_data.x;
	float steepness = wave_data.y * smoothstep(1. - abs(dot(pos_os_norm, wave_dir_norm)), s_e0, s_e1);
	float frequency = wave_data.z * freq_scale;
	float fi = wave_data.w * t;

	vec3 di = cross(pos_os_norm, cross(pos_os_norm - wave_dir_norm, pos_os_norm));
	float li = acos(dot(pos_os_norm, wave_dir_norm)) * r;

	sin_part += amplitude * sin(frequency * li + fi * time);
	cos_part += steepness * amplitude * cos(frequency * li + fi * time) * di;

	sin_part_normal += steepness * amplitude * frequency * sin(frequency * li + fi * time);
	cos_part_normal += di * amplitude * frequency * cos(frequency * li + fi * time);

	vec3 di_cross = cross(di, pos_os_norm);
	tangent += di_cross / length(di_cross);
}

void vertex() {
	vec3 init_vertex = VERTEX;
	init_vertex.y = (1. - pow(abs(init_vertex.x), y_exponent)) * (1. - pow(abs(init_vertex.z), y_exponent));
	vec3 rotated_vertex = basis * init_vertex;
	vec3 rotated_offset = basis * vec3(0., y_offset, 0.);
	vec3 grid = normalize(rotated_offset + rotated_vertex) * radius;

	vec3 position_os = grid;
	vec3 position_os_norm = normalize(position_os);

	float sin_part = 0.;
	vec3 cos_part = vec3(0.);

	float sin_part_normal = 0.;
	vec3 cos_part_normal = vec3(0.);

	vec3 tangent = vec3(0.);

	int wave_data_amount = textureSize(wave_tex, 0).y;
	for (int i = 0; i < wave_data_amount; i++) {
		vec4 data = texelFetch(wave_tex, ivec2(0, i), 0);
		vec3 dir = texelFetch(wave_tex, ivec2(1, i), 0).rgb;
		spherical_gerstner(
			data, dir, position_os_norm,
			sin_part, cos_part, sin_part_normal, cos_part_normal, tangent,
			amplitude_scale, steepness_e0, steepness_e1, frequency_scale, time_scale,
			radius, TIME
		);
	}

	tangent = normalize(tangent);

	vec3 surface_level = position_os_norm * radius;
	vec3 wave_movement = position_os_norm * sin_part + cos_part;
	vec3 wave_pos = surface_level + wave_movement;

	vec3 wave_normal = position_os_norm - position_os_norm * sin_part_normal - cos_part_normal;
	wave_normal = mix(position_os_norm, wave_normal, wave_normal_amount);
	wave_normal = normalize(wave_normal);

	VERTEX = wave_pos;
	NORMAL = wave_normal;
}

void fragment() {
	ALBEDO = main_color.rgb;
}


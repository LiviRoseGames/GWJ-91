shader_type canvas_item;

uniform sampler2D paper_texture;

uniform float grain_strength = 0.25;
uniform float grain_scale = 40.0;

float random(vec2 uv){
	return fract(sin(dot(uv ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {

	vec4 tex = texture(TEXTURE, UV);

	//Noise generating~
	float noise = random(UV * grain_scale);

	//Applying~
	tex.rgb += (noise - 0.5) * grain_strength;

	vec4 paper = texture(paper_texture, UV * 5.0);
	tex.rgb *= paper.rgb;

	COLOR = tex * COLOR;
}
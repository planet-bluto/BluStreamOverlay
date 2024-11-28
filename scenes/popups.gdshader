shader_type canvas_item;

uniform vec4 swatch_base: source_color = vec4(1,1,1,1);
uniform vec4 swatch_shade: source_color = vec4(0.5,0.5,0.5,1);

void fragment() {
	float alpha = COLOR.a;
	
	if (COLOR.rgb == vec3(1,0,0)) {
		COLOR = swatch_base;
	}
	if (COLOR.rgb == vec3(1,0,1)) {
		COLOR = swatch_shade;
	}
	
	COLOR.a = alpha;
}
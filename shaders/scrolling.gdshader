shader_type canvas_item;

uniform float scroll_speed = 1.0;
uniform vec4 border_color: source_color = vec4(1, 1, 1, 1);

void fragment() {
	float add = (TIME * scroll_speed);
	//float add = 0.0;
	vec2 PRE_UV = vec2(UV.x + add, UV.y);
	COLOR = texture(TEXTURE, PRE_UV) * border_color;
}
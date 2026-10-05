shader_type spatial;
uniform vec4 col_a : source_color = vec4(0.75, 0.75, 0.78, 1.0);
uniform vec4 col_b : source_color = vec4(0.25, 0.25, 0.28, 1.0);
uniform float squares = 20.0;
void fragment() {
  vec2 g = UV * squares;
  float c = mod(floor(g.x) + floor(g.y), 2.0);
  ALBEDO = mix(col_a.rgb, col_b.rgb, c);
}
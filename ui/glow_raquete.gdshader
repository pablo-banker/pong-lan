shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 cor : source_color = vec4(
	0.357, 0.616, 1.0, 1.0
);

uniform float intensidade : hint_range(0.0, 2.0) = 0.6;
uniform float alcance : hint_range(1.0, 20.0) = 10.0;

void fragment() {
	vec2 tamanho = vec2(80.0, 170.0);
	vec2 metade_raquete = vec2(10.0, 55.0);

	vec2 posicao = (UV - vec2(0.5)) * tamanho;
	vec2 distancia_borda = abs(posicao) - metade_raquete;

	float distancia = length(
		max(distancia_borda, vec2(0.0))
	);

	float brilho = exp(-distancia / alcance);

	// Faz o brilho desaparecer antes do limite do ColorRect.
	float acabamento = 1.0 - smoothstep(
		20.0,
		30.0,
		distancia
	);

	COLOR = vec4(
		cor.rgb,
		brilho * acabamento * intensidade * cor.a
	);
}
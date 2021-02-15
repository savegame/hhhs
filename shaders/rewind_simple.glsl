float strengthX = 0.006;
float strengthY = 20.0;
float strengthY2 = 3.2;
float segments = 50.0;

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	uniform float wave;
	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec2 texcoordwavy = texcoord;
		texcoordwavy.x = texcoordwavy.x+strengthX*sin(wave+(floor(texcoordwavy.y*segments)/segments)*strengthY)*sin(wave+texcoordwavy.y*strengthY2);
		vec4 texcolor = Texel(tex, texcoordwavy);
		if (texcolor.a == 0.0) { discard; }
		return vec4(texcolor)*color;
	}
#endif
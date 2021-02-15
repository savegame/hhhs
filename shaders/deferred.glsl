uniform Image MainTex;
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrixInverse; //Inverse to calculate normals

varying vec3 normal; //Vertex Normal
varying vec4 vertPos; //vertex position (for point lights)
varying vec4 project;

#ifdef VERTEX
	attribute vec4 VertexNormal;
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		normal = normalize(vec3(vec4(modelMatrixInverse*VertexNormal))); //interpolate normal
		vertPos = vec4(modelMatrix * vertex_position);
		return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
	}
#endif

#ifdef PIXEL
	void effect() {
		//IGNORE ALPHA
		vec4 texcolor = Texel(MainTex, VaryingTexCoord.xy);
		if (texcolor.a == 0.0) { discard; };

		love_Canvases[0] = VaryingColor * texcolor;
		love_Canvases[1] = vec4(vertPos.x,vertPos.y,vertPos.z, 1.0);
		love_Canvases[2] = vec4(normal, 1.0);
	}
#endif
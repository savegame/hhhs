//Alesan99
//Renders Sprite in 3D space that always faces Camera
//http://www.opengl-tutorial.org/intermediate-tutorials/billboards-particles/billboards/
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform vec3 modelScale;

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		mat4 modelMatrix2 = modelMatrix;
		modelMatrix2[1][1] = -modelMatrix2[1][1];
		mat4 modelView = viewMatrix * modelMatrix2;
		//(Comment out the middle ones for cylindrical billboarding)
		// Column 0:
		modelView[0][0] = modelScale[0];
		modelView[0][1] = 0.0;
		modelView[0][2] = 0.0;

		// Column 1:
		//modelView[1][0] = 0.0;
		//modelView[1][1] = modelScale[1];
		//modelView[1][1] = -modelView[1][1];
		//modelView[1][2] = 0.0;

		// Column 2:
		modelView[2][0] = 0.0;
		modelView[2][1] = 0.0;
		modelView[2][2] = modelScale[2];
		return projectionMatrix *  modelView * vec4(vertex_position.x,vertex_position.y,0.0,vertex_position.w);
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec4 texcolor = Texel(tex, texcoord);
		if (texcolor.a == 0.0) { discard; }
		return vec4(texcolor)*color;
	}
#endif
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

varying float depth;

uniform bool animated = false;

#ifdef VERTEX
	attribute vec4 VertexWeight;
	attribute vec4 VertexBone;
	uniform mat4 u_pose[16]; //100 bones crashes web version, only set to whats absolutely necessary
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		if (animated == true) {
			mat4 skeleton = u_pose[int(VertexBone.x*255.0)] * VertexWeight.x +
				u_pose[int(VertexBone.y*255.0)] * VertexWeight.y +
				u_pose[int(VertexBone.z*255.0)] * VertexWeight.z +
				u_pose[int(VertexBone.w*255.0)] * VertexWeight.w;
			vertex_position = skeleton * vertex_position;
		};
		return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec4 texcolor = Texel(tex, texcoord);
		if (texcolor.a == 0.0) { discard; }
		return vec4(0.0,0.0,0.0,1.0);
	}
#endif
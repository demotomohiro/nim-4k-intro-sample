#version 420
out gl_PerVertex {vec4 gl_Position;};

void main()
{
	if(gl_VertexID == 0)
	{
		gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
	}else if(gl_VertexID == 1)
	{
		gl_Position = vec4(0.0, 1.0, 0.0, 1.0);
	}else
	{
		gl_Position = vec4(1.0, 0.0, 0.0, 1.0);
	}
}

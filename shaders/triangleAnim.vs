#version 420

uniform float time;

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
		gl_Position = vec4(fract(time), 0.0, 0.0, 1.0);
	}
}

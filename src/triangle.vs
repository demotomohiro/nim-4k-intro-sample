#version 420

uniform float sampleCount;

void main()
{
  float t = sampleCount/44100.0;

	if(gl_VertexID == 0)
	{
		gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
	}else if(gl_VertexID == 1)
	{
		gl_Position = vec4(0.0, 1.0, 0.0, 1.0);
	}else
	{
		gl_Position = vec4(t*0.25, 0.0, 0.0, 1.0);
	}
}

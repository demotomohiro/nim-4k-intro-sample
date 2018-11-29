#version 420

uniform float sampleCount;

out vec4 color;

void main()
{
  float t = sampleCount/44100.0;
	color = vec4(sin(t*12.0)*0.5 + 0.5, 0.0, 0.0, 0.0);
}

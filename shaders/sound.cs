#version 450

layout(local_size_x = $soundCSLocalSize) in;
layout(binding = 0) buffer layoutName {
  vec2 samples[];
};

#define PI	3.1415926

void main(){
  uint id = gl_GlobalInvocationID.x;
  if(id >= $soundNumSamples)
    return;

  float t = float(id)/$soundSampleRate;
  float v = sin(2.0 * PI * t * 400.0)*0.25;
  samples[id] = (vec2(v) + vec2(1.0)) * 0.5;
}

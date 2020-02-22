/*
 * Minimum C program.
 * Nim program can be as small as this program?
 * Run minimum_build.bat on VS2015 x86 Native Tools command prompt to build this code.
 */

#include <windows.h>
#include <Mmsystem.h>
#include <Mmreg.h>
#include <GL/gl.h>
#include <GL/glext.h>
#include <GL/wglext.h>

#define WIDTH 640
#define HEIGHT 480

PFNGLCREATESHADERPROC glCreateShader;
PFNGLSHADERSOURCEPROC glShaderSource;
PFNGLCOMPILESHADERPROC glCompileShader;
PFNGLCREATEPROGRAMPROC glCreateProgram;
PFNGLLINKPROGRAMPROC glLinkProgram;
PFNGLATTACHSHADERPROC glAttachShader;
PFNGLUSEPROGRAMPROC glUseProgram;
PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT;
PFNGLCREATEBUFFERSPROC glCreateBuffers;
PFNGLNAMEDBUFFERDATAPROC glNamedBufferData;
PFNGLBINDBUFFERBASEPROC glBindBufferBase;
PFNGLDISPATCHCOMPUTEPROC glDispatchCompute;
PFNGLMEMORYBARRIERPROC glMemoryBarrier;
PFNGLGETNAMEDBUFFERSUBDATAPROC glGetNamedBufferSubData;
PFNGLUNIFORM1FPROC glUniform1f;

__forceinline void loadExtensions() {
  glCreateShader = (PFNGLCREATESHADERPROC)wglGetProcAddress("glCreateShader");
  glShaderSource = (PFNGLSHADERSOURCEPROC)wglGetProcAddress("glShaderSource");
  glCompileShader = (PFNGLCOMPILESHADERPROC)wglGetProcAddress("glCompileShader");
  glCreateProgram = (PFNGLCREATEPROGRAMPROC)wglGetProcAddress("glCreateProgram");
  glLinkProgram = (PFNGLLINKPROGRAMPROC)wglGetProcAddress("glLinkProgram");
  glAttachShader = (PFNGLATTACHSHADERPROC)wglGetProcAddress("glAttachShader");
  glUseProgram = (PFNGLUSEPROGRAMPROC)wglGetProcAddress("glUseProgram");
  wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC)wglGetProcAddress("wglSwapIntervalEXT");
  glCreateBuffers = (PFNGLCREATEBUFFERSPROC)wglGetProcAddress("glCreateBuffers");
  glNamedBufferData = (PFNGLNAMEDBUFFERDATAPROC)wglGetProcAddress("glNamedBufferData");
  glBindBufferBase = (PFNGLBINDBUFFERBASEPROC)wglGetProcAddress("glBindBufferBase");
  glDispatchCompute = (PFNGLDISPATCHCOMPUTEPROC)wglGetProcAddress("glDispatchCompute");
  glMemoryBarrier = (PFNGLMEMORYBARRIERPROC)wglGetProcAddress("glMemoryBarrier");
  glGetNamedBufferSubData = (PFNGLGETNAMEDBUFFERSUBDATAPROC)wglGetProcAddress("glGetNamedBufferSubData");
  glUniform1f = (PFNGLUNIFORM1FPROC)wglGetProcAddress("glUniform1f");
}

static PIXELFORMATDESCRIPTOR pfd =
{
	sizeof(PIXELFORMATDESCRIPTOR),
	1,									          //OpenGL version
	PFD_DRAW_TO_WINDOW |
	PFD_SUPPORT_OPENGL |
	PFD_DOUBLEBUFFER,
	PFD_TYPE_RGBA,
	24,									//Color bits
	0, 0,
	0, 0,
	0, 0,
	0, 0,
	0,
	0, 0, 0, 0,
	24,									//Z buffer
	0,
	0,
	PFD_MAIN_PLANE,
	0,
	0, 0, 0
};

HWND hWnd;

__forceinline HDC initScreen() {
	hWnd =	CreateWindowA("STATIC", 0,
		WS_POPUP|WS_VISIBLE, 0, 0,
		WIDTH, HEIGHT, NULL, NULL, NULL, NULL);

	HDC hdc = GetDC(hWnd);

	SetPixelFormat(hdc, ChoosePixelFormat(hdc, &pfd), &pfd);
	wglMakeCurrent(hdc, wglCreateContext(hdc));

  loadExtensions();

  ShowCursor(FALSE);

  return hdc;
}

__forceinline GLuint createShader(const char* source, GLenum shaderType) {
  GLenum result = glCreateShader(shaderType);
  glShaderSource(result, 1, (const GLchar**)&source, NULL);
  glCompileShader(result);
  
  return result;
}

void linkProgramObj(GLuint progObj) {
  glLinkProgram(progObj);
}

#define SHADER_TIME_LOC 1

#include "../shaders/triangleAnim.vs.h"
#include "../shaders/triangle.fs.h"

GLuint triangleProgObj;

__forceinline void initScene() {
  GLuint vso = createShader(triangleAnim_vs, GL_VERTEX_SHADER);
  GLuint fso = createShader(triangle_fs, GL_FRAGMENT_SHADER);
  GLuint progObj = glCreateProgram();
  glAttachShader(progObj, vso);
  glAttachShader(progObj, fso);
  linkProgramObj(progObj);
  //glUseProgram(progObj);
  triangleProgObj = progObj;
}

#define SOUND_SAMPLE_RATE		44100
#define SOUND_LENGTH_IN_SECOND	60
#define SOUND_NUM_CHANNELS		2
#define SOUND_NUM_SAMPLES		(SOUND_SAMPLE_RATE*SOUND_LENGTH_IN_SECOND)

typedef float sample_type;

sample_type	samples[SOUND_NUM_SAMPLES * SOUND_NUM_CHANNELS];

WAVEFORMATEX wave_format =
{
	WAVE_FORMAT_IEEE_FLOAT,
	SOUND_NUM_CHANNELS,							//nChannels
	SOUND_SAMPLE_RATE,							//nSamplesPerSec,
	SOUND_SAMPLE_RATE*sizeof(sample_type)*
	SOUND_NUM_CHANNELS,							//nAvgBytesPerSec
	sizeof(sample_type)*SOUND_NUM_CHANNELS,		//nBlockAlign
	sizeof(sample_type)*8,						//wBitsPerSample
	0
};

WAVEHDR wave_hdr =
{
	(LPSTR)samples,
	sizeof(samples),
	0,
	0,
	0,
	0,
	0,
	0
};

#define SOUND_CS_LOCAL_SIZE 32

#include "../shaders/sound.cs.h"

HWAVEOUT h_wave_out;

__forceinline void initSound() {
  GLuint cso = createShader(sound_cs, GL_COMPUTE_SHADER);
  GLuint progObj = glCreateProgram();
  glAttachShader(progObj, cso);
  linkProgramObj(progObj);

  GLuint ssbo;
  glCreateBuffers(1, &ssbo);
  glNamedBufferData(ssbo, sizeof(samples), NULL, GL_DYNAMIC_READ);
  glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, ssbo);

  glUseProgram(progObj);
  glDispatchCompute(
    (GLuint)((SOUND_NUM_SAMPLES	+ SOUND_CS_LOCAL_SIZE - 1) / SOUND_CS_LOCAL_SIZE), 1, 1);

  glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT);
  glGetNamedBufferSubData(ssbo, 0, sizeof(samples), samples);

	waveOutOpen(&h_wave_out, WAVE_MAPPER, &wave_format, (DWORD_PTR)hWnd, 0, CALLBACK_WINDOW);
	waveOutPrepareHeader(h_wave_out, &wave_hdr, sizeof(wave_hdr));
	waveOutWrite(h_wave_out, &wave_hdr, sizeof(wave_hdr));
}

__forceinline float getSoundPosition() {
	MMRESULT r;

	MMTIME mmtime =
	{
		TIME_SAMPLES,
		0
	};

	r = waveOutGetPosition(h_wave_out, &mmtime, sizeof(mmtime));

	return (float)(mmtime.u.sample) / (float)SOUND_SAMPLE_RATE;
}

void WinMainCRTStartup(void) {
  HDC hdc = initScreen();
  initScene();
  initSound();

  wglSwapIntervalEXT(1);

	MSG msg;
loop:
	PeekMessage(&msg, 0, 0, 0, PM_REMOVE);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glUseProgram(triangleProgObj);
  float pos = getSoundPosition();
  glUniform1f(SHADER_TIME_LOC, pos);
  glDrawArrays(GL_TRIANGLES, 0, 3);
	SwapBuffers(hdc);
	if(GetAsyncKeyState(VK_ESCAPE) || msg.message == MM_WOM_DONE)
		ExitProcess(0);
	goto loop;
}

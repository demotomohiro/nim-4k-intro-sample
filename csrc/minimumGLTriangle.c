/*
 * Minimum C program.
 * Nim program can be as small as this program?
 * Run minimum_build.bat on VS2015 x86 Native Tools command prompt to build this code.
 */

#include <windows.h>
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

__forceinline void loadExtensions() {
  glCreateShader = (PFNGLCREATESHADERPROC)wglGetProcAddress("glCreateShader");
  glShaderSource = (PFNGLSHADERSOURCEPROC)wglGetProcAddress("glShaderSource");
  glCompileShader = (PFNGLCOMPILESHADERPROC)wglGetProcAddress("glCompileShader");
  glCreateProgram = (PFNGLCREATEPROGRAMPROC)wglGetProcAddress("glCreateProgram");
  glLinkProgram = (PFNGLLINKPROGRAMPROC)wglGetProcAddress("glLinkProgram");
  glAttachShader = (PFNGLATTACHSHADERPROC)wglGetProcAddress("glAttachShader");
  glUseProgram = (PFNGLUSEPROGRAMPROC)wglGetProcAddress("glUseProgram");
  wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC)wglGetProcAddress("wglSwapIntervalEXT");
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

__forceinline HDC initScreen() {
	HWND hWnd =	CreateWindowA("STATIC", 0,
		WS_POPUP|WS_VISIBLE, 0, 0,
		WIDTH, HEIGHT, NULL, NULL, NULL,NULL);

	HDC hdc = GetDC(hWnd);

	SetPixelFormat(hdc, ChoosePixelFormat(hdc, &pfd), &pfd);
	wglMakeCurrent(hdc, wglCreateContext(hdc));

  loadExtensions();

  return hdc;
}

__forceinline GLuint createShader(const char* source, GLenum shaderType) {
  GLenum result = glCreateShader(shaderType);
  glShaderSource(result, 1, (const GLchar**)&source, NULL);
  glCompileShader(result);
  
  return result;
}

__forceinline void linkProgramObj(GLuint progObj) {
  glLinkProgram(progObj);
}

#include "../shaders/triangle.vs.h"
#include "../shaders/triangle.fs.h"

__forceinline void initScene() {
  GLuint vso = createShader(triangle_vs, GL_VERTEX_SHADER);
  GLuint fso = createShader(triangle_fs, GL_FRAGMENT_SHADER);
  GLuint progObj = glCreateProgram();
  glAttachShader(progObj, vso);
  glAttachShader(progObj, fso);
  linkProgramObj(progObj);
  glUseProgram(progObj);
}

void WinMainCRTStartup(void) {
  HDC hdc = initScreen();
  initScene();

  wglSwapIntervalEXT(1);

	MSG msg;
loop:
	PeekMessage(&msg, 0, 0, 0, PM_REMOVE);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glDrawArrays(GL_TRIANGLES, 0, 3);
	SwapBuffers(hdc);
	if(GetAsyncKeyState(VK_ESCAPE))
		ExitProcess(0);
	goto loop;
}

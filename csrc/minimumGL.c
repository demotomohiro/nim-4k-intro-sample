/*
 * Minimum C program.
 * Nim program can be as small as this program?
 * Run minimum_build.bat on VS2015 x86 Native Tools command prompt to build this code.
 */

#include <windows.h>
#include <GL/gl.h>
#include <GL/wglext.h>

#define WIDTH 640
#define HEIGHT 480

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

void initScreen() {
	HWND hWnd =	CreateWindowA("STATIC", 0,
		WS_POPUP|WS_VISIBLE, 0, 0,
		WIDTH, HEIGHT, NULL, NULL, NULL, NULL);

	HDC hdc = GetDC(hWnd);

	SetPixelFormat(hdc, ChoosePixelFormat(hdc, &pfd), &pfd);

	wglMakeCurrent(hdc, wglCreateContext(hdc));
}

void WinMainCRTStartup(void) {
  initScreen();
	MessageBoxA(0, glGetString(GL_VERSION), "minimumGL", 0);
  //Process keep alive if ExitProcess API was not called.
  ExitProcess(0);
}

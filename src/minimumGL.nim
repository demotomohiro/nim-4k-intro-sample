import winlean4k, openGL4k2

const
  ScreenWidth   = 640
  ScreenHeight  = 480

let
  pfd           = PIXELFORMATDESCRIPTOR(
    nSize:          sizeof(PIXELFORMATDESCRIPTOR).uint16,
    nVersion:       1'u16,
    dwFlags:        PFD_DRAW_TO_WINDOW or
                    PFD_SUPPORT_OPENGL or
                    PFD_DOUBLEBUFFER,
    iPixelType:     PFD_TYPE_RGBA,
    cColorBits:     24,
    cRedBits:       0, cRedShift:   0,
    cGreenBits:     0, cGreenShift: 0,
    cBlueBits:      0, cBlueShift:  0,
    cAlphaBits:     0, cAlphaShift: 0,
    cAccumBits:     0,
    cAccumRedBits:  0,
    cAccumGreenBits:0,
    cAccumBlueBits: 0,
    cAccumAlphaBits:0,
    cDepthBits:     24,
    cStencilBits:   0,
    cAuxBuffers:    0,
    iLayerType:     PFD_MAIN_PLANE,
    bReserved:      0,
    dwLayerMask:    0,
    dwVisibleMask:  0,
    dwDamageMask:   0)

proc initScreen() {.inline.} =
  let hWnd = CreateWindowA(
    "STATIC".cstring, nil,
    WS_POPUP or WS_VISIBLE, 0, 0,
    ScreenWidth, ScreenHeight, nil, nil, nil, nil)
  let hdc = GetDC(hWnd)

  discard SetPixelFormat(hdc, ChoosePixelFormat(hdc, unsafeAddr pfd), unsafeAddr pfd)
  discard wglMakeCurrent(hdc, wglCreateContext(hdc))

proc WinMainCRTStartup() {.exportc.} =
  initScreen()
  let version = glGetString(GL_VERSION)
  discard MessageBoxA(nil, cast[cstring](version), cstring"minimumGL", 0)
  # Process keep alive if ExitProcess API was not called.
  ExitProcess(0)

when not defined(danger):
  WinMainCRTStartup()

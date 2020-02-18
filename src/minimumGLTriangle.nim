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

proc initScreen(): auto =
  let hWnd = CreateWindowA(
    "STATIC".cstring, nil,
    WS_POPUP or WS_VISIBLE, 0, 0,
    ScreenWidth, ScreenHeight, nil, nil, nil, nil)
  let hdc = GetDC(hWnd)

  discard SetPixelFormat(hdc, ChoosePixelFormat(hdc, unsafeAddr pfd), unsafeAddr pfd)
  discard wglMakeCurrent(hdc, wglCreateContext(hdc))
  loadExtensions()

  ShowCursor(0)

  return hdc

proc createShader(source:cstring, shaderType: GLEnum): GLuint =
  result = glCreateShader(shaderType)
  assert result != 0
  glShaderSource(result, 1, cast[cstringArray](unsafeAddr source), nil)
  glCompileShader(result)
  when not defined(danger):
    var logLen: GLint
    glGetShaderiv(result, GL_INFO_LOG_LENGTH, addr logLen)
    if logLen != 0:
      var log = newseq[int8](logLen)
      glGetShaderInfoLog(result, logLen, nil, cast[cstring](addr log[0]))
      echo "Message from OpenGL shader compiler:"
      echo cast[cstring](addr log[0])

    var compileStatus: GLint
    glGetShaderiv(result, GL_COMPILE_STATUS, addr compileStatus)
    if compileStatus != cast[GLint](GL_TRUE):
      quit "Failed to compile shader"

proc linkProgramObj(progObj: GLuint) =
  glLinkProgram(progObj)

  when not defined(danger):
    var logLen: GLint
    glGetProgramiv(progObj, GL_INFO_LOG_LENGTH, addr logLen)
    if logLen != 0:
      var log = newseq[int8](logLen)
      glGetProgramInfoLog(progObj, logLen, nil, cast[cstring](addr log[0]))
      echo "Message from OpenGL shader compiler:"
      echo cast[cstring](addr log[0])

    var success: GLint
    glGetProgramiv(progObj, GL_LINK_STATUS, addr success)
    if success != cast[GLint](GL_TRUE):
      quit "Failed to link shader"

const triangleVSSrc = staticRead("../shaders/triangle.vs").cstring
const triangleFSSrc = staticRead("../shaders/triangle.fs").cstring

proc initScene() =
  let vso = createShader(triangleVSSrc, GL_VERTEX_SHADER)
  let fso = createShader(triangleFSSrc, GL_FRAGMENT_SHADER)
  let progObj = glCreateProgram()
  glAttachShader(progObj, vso)
  glAttachShader(progObj, fso)
  progObj.linkProgramObj()
  glUseProgram(progObj)

proc WinMainCRTStartup() {.exportc.} =
  let hdc = initScreen()
  initScene()

  discard wglSwapIntervalEXT(1)

  var msg{.noinit.}: MSG

  while true:
    discard PeekMessageA(addr msg, nil, 0, 0, PM_REMOVE)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    discard SwapBuffers(hdc)
    if GetAsyncKeyState(VK_ESCAPE) != 0:
      ExitProcess(0)

  # Process keep alive if ExitProcess API was not called.
  ExitProcess(0)

when not defined(danger):
  WinMainCRTStartup()

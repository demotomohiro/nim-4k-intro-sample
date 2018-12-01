import oldwinapi/[windows, mmsystem]
include openGL4k
include strutils_tmp

wrapErrorChecking:
  proc wglSwapIntervalEXT(interval: GLint): WINBOOL

const
  ScreenWidth {.intdefine.}  = 640
  ScreenHeight {.intdefine.} = 480
  pfd           = PIXELFORMATDESCRIPTOR(
    nSize:          sizeof(PIXELFORMATDESCRIPTOR).int16,
    nVersion:       1'i16,
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

when not defined(release):
  const
    attribList = [
      WGL_CONTEXT_MAJOR_VERSION_ARB,   4,
      WGL_CONTEXT_MINOR_VERSION_ARB,   5,
      WGL_CONTEXT_FLAGS_ARB,           WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB or WGL_CONTEXT_DEBUG_BIT_ARB,
      WGL_CONTEXT_PROFILE_MASK_ARB,    WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
      0]

  proc debugGLCallback(
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.} = 
    echo "Message from glDebugMessageCallback:"
    echo message
    assert severity != GL_DEBUG_SEVERITY_HIGH

var hWnd: HWND
proc initScreen(): auto =
  hWnd = CreateWindowA(
    "STATIC".cstring, nil,
    WS_POPUP or WS_VISIBLE, 0, 0,
    ScreenWidth, ScreenHeight, 0, 0, 0, nil)
  let hdc = GetDC(hWnd)

  var varPfd = pfd

  discard SetPixelFormat(hdc, ChoosePixelFormat(hdc, addr varPfd), addr varPfd)
  discard wglMakeCurrent(hdc, wglCreateContext(hdc));

  when not defined(release):
    #Create Debug context
    type
      PFNwglCreateContextAttribsARB = proc (hDC: HDC, hShareContext: HGLRC, attribList: ptr int32): HGLRC {.stdcall.}
    let wglCreateContextAttribsARB = cast[PFNwglCreateContextAttribsARB](wglGetProcAddress("wglCreateContextAttribsARB"))

    if wglCreateContextAttribsARB == nil:
      quit "wglCreateContextAttribsARB is not available"
    var al = attribList
    let hglrc = wglCreateContextAttribsARB(hdc, 0, addr(al[0]))
    assert hglrc != 0
    discard wglMakeCurrent(hdc, hglrc)

  loadExtensions()

  when not defined(release):
    echo "Using Debug Context"
    glEnableSttc(GL_DEBUG_OUTPUT_SYNCHRONOUS)
    var ids: GLuint = 0
    glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, addr ids, GL_TRUE);
    glDebugMessageCallback(debugGLCallback, nil)
    #Draw call without Vertex array object being bound is error when using core opengl context.
    var vao: GLuint
    glCreateVertexArrays(1, addr vao)
    glBindVertexArray(vao)

  return hdc

proc createShader(source:cstring, shaderType: GLEnum): GLuint =
  result = glCreateShader(shaderType)
  assert result != 0
  glShaderSource(result, 1, cast[cstringArray](unsafeAddr source), nil)
  glCompileShader(result)
  when not defined(release):
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

  when not defined(release):
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

const triangleVSSrc = staticRead("../shaders/triangleAnim.vs").cstring
const triangleFSSrc = staticRead("../shaders/triangle.fs").cstring

var triangleProgObj: GLuint
var timeUniformLoc: GLint

proc initScene() =
  let vso = createShader(triangleVSSrc, GL_VERTEX_SHADER)
  let fso = createShader(triangleFSSrc, GL_FRAGMENT_SHADER)
  let progObj = glCreateProgram()
  glAttachShader(progObj, vso)
  glAttachShader(progObj, fso)
  progObj.linkProgramObj()
  glUseProgram(progObj)
  timeUniformLoc = glGetUniformLocation(progObj, "time")
  assert(timeUniformLoc != -1)
  triangleProgObj = progObj

type SampleType = float32

const
  soundSampleRate     = 44100
  soundLengthInSecond = 60
  soundNumChannels    = 2
  soundNumSamples     = soundSampleRate * soundLengthInSecond

const soundCSLocalSize = 32
const soundCSSrc = (staticRead("../shaders/sound.cs") % [
                                              "soundNumSamples", $soundNumSamples,
                                              "soundCSLocalSize", $soundCSLocalSize,
                                              "soundSampleRate", $soundSampleRate
                                              ]).cstring

proc genSoundC(): string =
  let outf = "sound.gen.c"
  when not defined(release):
    var text = readFile("sound.c")
    text = text % [
                   "SOUND_SAMPLE_RATE",      $soundSampleRate,
                   "SOUND_LENGTH_IN_SECOND", $soundLengthInSecond,
                   "SOUND_NUM_CHANNELS",     $soundNumChannels,
                   "SOUND_NUM_SAMPLES",      $soundNumSamples]
    writeFile(outf, text)
  return outf

const soundC = genSoundC()
{.compile: soundC.}

proc getSampleBuf(): pointer {.importc.}
proc playSound(hWnd: HWND) {.importc.}
proc getSoundPosition(): float32 {.importc.}

proc initSound() =
  let cso = createShader(soundCSSrc, GL_COMPUTE_SHADER)
  let progObj = glCreateProgram()
  glAttachShader(progObj, cso)
  progObj.linkProgramObj()

  const sampleSize = sizeof(array[soundNumSamples * soundNumChannels, SampleType])
  var ssbo: GLuint
  glCreateBuffers(1, addr ssbo)
  glNamedBufferData(ssbo, sampleSize, nil, GL_DYNAMIC_READ)
  glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, ssbo)

  glUseProgram(progObj)
  glDispatchCompute(
    GLuint(int(soundNumSamples + soundCSLocalSize - 1) div soundCSLocalSize), 1, 1)

  glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT)
  glGetNamedBufferSubData(ssbo, 0, sampleSize, getSampleBuf())

  playSound(hWnd)

proc render() =
  glClearSttc(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glUseProgram(triangleProgObj)
  let pos = getSoundPosition()
  glUniform1f(timeUniformLoc, pos)
  glDrawArraysSttc(GL_TRIANGLES, 0, 3)

proc WinMainCRTStartup() {.exportc.} =
  let hdc = initScreen()
  initScene()
  initSound()

  discard wglSwapIntervalEXT(1);

  var msg: MSG

  while true:
    discard PeekMessage(addr msg, 0, 0, 0, PM_REMOVE)
    render()
    discard SwapBuffers(hdc)
    if GetAsyncKeyState(VK_ESCAPE) != 0 or msg.message == MM_WOM_DONE:
      ExitProcess(0)

  # Process keep alive if ExitProcess API was not called.
  ExitProcess(0)

when not defined(release):
  WinMainCRTStartup()

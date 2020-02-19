import winlean4k, openGL4k2
import strutils

const
  ScreenWidth  {.intdefine.} = 640
  ScreenHeight {.intdefine.} = 480

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

when not defined(danger):
  const
    attribList = [
      WGL_CONTEXT_MAJOR_VERSION_ARB.cint,   4,
      WGL_CONTEXT_MINOR_VERSION_ARB.cint,   5,
      WGL_CONTEXT_FLAGS_ARB.cint,           cint(WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB or WGL_CONTEXT_DEBUG_BIT_ARB),
      WGL_CONTEXT_PROFILE_MASK_ARB.cint,    WGL_CONTEXT_CORE_PROFILE_BIT_ARB.cint,
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
    ScreenWidth, ScreenHeight, nil, nil, nil, nil)
  let hdc = GetDC(hWnd)

  discard SetPixelFormat(hdc, ChoosePixelFormat(hdc, unsafeAddr pfd), unsafeAddr pfd)
  discard wglMakeCurrent(hdc, wglCreateContext(hdc))

  when not defined(danger):
    #Create Debug context
    type
      PFNwglCreateContextAttribsARB = proc (hDC: HDC, hShareContext: HGLRC, attribList: ptr cint): HGLRC {.stdcall.}
    let wglCreateContextAttribsARB = cast[PFNwglCreateContextAttribsARB](wglGetProcAddress("wglCreateContextAttribsARB"))

    if wglCreateContextAttribsARB == nil:
      quit "wglCreateContextAttribsARB is not available"
    var al = attribList
    let hglrc = wglCreateContextAttribsARB(hdc, nil, addr(al[0]))
    assert hglrc != nil
    discard wglMakeCurrent(hdc, hglrc)

  loadExtensions()

  ShowCursor(0)

  when not defined(danger):
    echo "Using Debug Context"
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
    var ids: GLuint = 0
    glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, addr ids, GL_TRUE)
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

const shaderTimeLoc = 1
const triangleVSSrc = (staticRead("../shaders/triangleAnim.vs") % [
                                              "shaderTimeLoc", $shaderTimeLoc
                                                                  ]).cstring
const triangleFSSrc = staticRead("../shaders/triangle.fs").cstring

var triangleProgObj: GLuint

proc initScene() =
  let vso = createShader(triangleVSSrc, GL_VERTEX_SHADER)
  let fso = createShader(triangleFSSrc, GL_FRAGMENT_SHADER)
  let progObj = glCreateProgram()
  glAttachShader(progObj, vso)
  glAttachShader(progObj, fso)
  progObj.linkProgramObj()
#  glUseProgram(progObj)
  triangleProgObj = progObj

type SampleType = float32

const
  soundSampleRate     = 44100
  soundLengthInSecond = 60
  soundNumChannels    = 2
  soundNumSamples     = soundSampleRate * soundLengthInSecond

let
  waveFormat = WAVEFORMATEX(
    wFormatTag:       WAVE_FORMAT_IEEE_FLOAT,
    nChannels:        soundNumChannels,
    nSamplesPerSec:   soundSampleRate,
    nAvgBytesPerSec:  soundSampleRate*sizeof(SampleType)*soundNumChannels,
    nBlockAlign:      sizeof(SampleType)*soundNumChannels,
    wBitsPerSample:   sizeof(SampleType)*8,
    cbSize:           0
  )

var samples: array[soundNumSamples * soundNumChannels, SampleType]

#waveHdr can be modified by waveOutWrite when the buffer is finished.
var
  waveHdr = WAVEHDR(
    lpData:           nil,
    dwBufferLength:   sizeof(samples).uint32,
    dwBytesRecorded:  0,
    dwUser:           0,
    dwFlags:          0,
    dwLoops:          0,
    lpNext:           nil,
    reserved:         0
  )

const soundCSLocalSize = 32
const soundCSSrc = (staticRead("../shaders/sound.cs") % [
                                              "soundNumSamples", $soundNumSamples,
                                              "soundCSLocalSize", $soundCSLocalSize,
                                              "soundSampleRate", $soundSampleRate
                                              ]).cstring

template checkWaveOutCall(call: typed): untyped =
  when defined(danger):
    discard call
  else:
    let r = call
    if r != MMSYSERR_NOERROR:
      var text: array[MAXERRORLENGTH, Utf16Char]
      if waveOutGetErrorTextW(r, addr text[0], MAXERRORLENGTH.UINT) != MMSYSERR_NOERROR:
        echo cast[WideCString](addr text[0])
      else:
        quit "Failed to call waveOutGetErrorText"

var h_wave_out: HWAVEOUT

proc initSound() =
  let cso = createShader(soundCSSrc, GL_COMPUTE_SHADER)
  let progObj = glCreateProgram()
  glAttachShader(progObj, cso)
  progObj.linkProgramObj()

  var ssbo: GLuint
  glCreateBuffers(1, addr ssbo)
  glNamedBufferData(ssbo, sizeof(samples), nil, GL_DYNAMIC_READ)
  glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, ssbo)

  glUseProgram(progObj)
  glDispatchCompute(
    GLuint(int(soundNumSamples + soundCSLocalSize - 1) div soundCSLocalSize), 1, 1)

  glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT)
  glGetNamedBufferSubData(ssbo, 0, sizeof(samples), addr samples[0])

  checkWaveOutCall(waveOutOpen(addr h_wave_out, WAVE_MAPPER, unsafeAddr waveFormat, cast[DWORD_PTR](hWnd), 0.DWORD_PTR, CALLBACK_WINDOW.DWORD))
  waveHdr.lpData = cast[cstring](addr samples[0])
  checkWaveOutCall(waveOutPrepareHeader(h_wave_out, addr waveHdr, sizeof(waveHdr).UINT))
  checkWaveOutCall(waveOutWrite(h_wave_out, addr waveHdr, sizeof(waveHdr).UINT))

proc getSoundPosition(): float32 =
  var mmtime: MMTIME
  mmtime.wType = TIME_SAMPLES

  checkWaveOutCall(waveOutGetPosition(h_wave_out, addr mmtime, sizeof(mmtime).uint32))
  return float32(mmtime.u.sample) / float32(soundSampleRate)

proc WinMainCRTStartup() {.exportc.} =
  let hdc = initScreen()
  initScene()
  initSound()

  discard wglSwapIntervalEXT(1)

  var msg {.noinit.}: MSG

  while true:
    discard PeekMessageA(addr msg, nil, 0, 0, PM_REMOVE)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    glUseProgram(triangleProgObj)
    let pos = getSoundPosition()
    glUniform1f(shaderTimeLoc, pos)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    discard SwapBuffers(hdc)
    if GetAsyncKeyState(VK_ESCAPE) != 0 or msg.message == MM_WOM_DONE:
      ExitProcess(0)

  # Process keep alive if ExitProcess API was not called.
  ExitProcess(0)

when not defined(danger):
  WinMainCRTStartup()

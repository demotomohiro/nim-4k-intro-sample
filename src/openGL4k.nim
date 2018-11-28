{.pragma: ogl, dynlib: wglGetProcAddress("0").}
{.pragma: wgl, dynlib: wglGetProcAddress("0").}

proc nimLoadProcs0() {.importc.}

template loadExtensions*() =
  ## call this after your rendering context has been setup if you use
  ## extensions.
  bind nimLoadProcs0
  nimLoadProcs0()

include opengl/private/types,
    opengl/private/errors, opengl/private/procs, opengl/private/constants

const WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091i32
const WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092i32
const WGL_CONTEXT_FLAGS_ARB         = 0x2094i32
const WGL_CONTEXT_PROFILE_MASK_ARB  = 0x9126i32

const WGL_CONTEXT_DEBUG_BIT_ARB              = 0x0001i32
const WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x0002i32
const WGL_CONTEXT_CORE_PROFILE_BIT_ARB       = 0x00000001i32

proc glGetString4k*(name: GLenum):  ptr GLubyte {.
    stdcall, dynlib: "opengl32", importc: "glGetString".}
proc glClearSttc*(mask: GLbitfield) {.
    stdcall, dynlib: "opengl32", importc: "glClear".}
proc glDrawArraysSttc*(mode: GLenum, first: GLint, count: GLsizei) {.
    stdcall, dynlib: "opengl32", importc: "glDrawArrays".}

proc glEnableSttc*(cap: GLenum) {.
    stdcall, dynlib: "opengl32", importc: "glEnable".}

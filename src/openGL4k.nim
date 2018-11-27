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

proc glGetString4k*(name: GLenum):  ptr GLubyte {.
    stdcall, dynlib: "opengl32", importc: "glGetString".}
proc glClearSttc*(mask: GLbitfield) {.
    stdcall, dynlib: "opengl32", importc: "glClear".}
proc glDrawArraysSttc*(mode: GLenum, first: GLint, count: GLsizei) {.
    stdcall, dynlib: "opengl32", importc: "glDrawArrays".}

import winlean4k

{.pragma: ogl, stdcall, importc, header: "<GL/gl.h>"}
{.pragma: oglExt, stdcall, importc, dynlib: wglGetProcAddress("0").}

proc nimLoadProcs0() {.importc.}

template loadExtensions*() =
  ## call this after your rendering context has been setup if you use
  ## extensions.
  bind nimLoadProcs0
  nimLoadProcs0()

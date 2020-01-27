## Test openGL4kGen.nim
## Run `nim c -r test.nim`

import os, tables, strutils, strformat

var testSamples = [
  "proc glEnable*( cap: GLenum;) {.ogl.}",
  "proc glShaderSource*( shader: GLuint; count: GLsizei; string: cstringArray; length: ptr GLint;) {.oglExt.}",
  "proc glGetString*( name: GLenum;): ptr GLubyte {.ogl.}",
  "proc glMapBuffer*( target: GLenum; access: GLenum;): pointer {.oglExt.}",
  "proc glFlush*() {.ogl.}",
  "proc glCreateShader*( type0: GLenum;): GLuint {.oglExt.}",
  "proc glBufferData*( target: GLenum; size: GLsizeiptr; data: pointer; usage: GLenum;) {.oglExt.}"]

proc getProcName(x: string): string =
  let
    a = "proc ".len
    b = x.find({'*', '('})

  assert x.len > a
  assert b != -1
  assert a < b
  x[a..(b - 1)]

proc test() =
  var sampleTable: Table[string, tuple[expect: string, found: bool]]
  for i in testSamples:
    let key = getProcName(i)
    sampleTable.add(key, (expect: i, found: false))

  for l in lines("testout.nim"):
    if l.startsWith("proc "):
      let name = getProcName(l)
      if name in sampleTable:
        doAssert l == sampleTable[name].expect, &"Declaration of \"{name}\" is wrong!"
        sampleTable[name].found = true

  for s in sampleTable.values:
    doAssert s.found, s.expect
 
if execShellCmd("nim c -d:ssl openGL4kGen.nim") == 0:
  if execShellCmd("openGL4kGen > testout.nim") == 0:
    test()
    quit "Test success", QuitSuccess

quit "Test failed"
